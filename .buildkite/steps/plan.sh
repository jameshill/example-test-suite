#!/bin/bash

set -e

export BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN=$(buildkite-agent secret get API_ACCESS_TOKEN)

IMAGE="${DOCKER_IMAGE}:${BUILDKITE_COMMIT}"
docker pull "$IMAGE"
docker tag "$IMAGE" app

# Extract bktec from the Docker image to run natively for pipeline planning
BKTEC=$(mktemp)
docker create --name bktec-extract app
docker cp bktec-extract:/usr/local/bin/bktec "$BKTEC"
docker rm bktec-extract
chmod +x "$BKTEC"

echo "+++ bktec plan"
# Disable split-by-example for planning — file-level granularity is sufficient
# for calculating parallelism, and the filter_tests endpoint it requires is unreliable
unset BUILDKITE_TEST_ENGINE_SPLIT_BY_EXAMPLE
PLAN_JSON=$("$BKTEC" plan --debug --json \
  --max-parallelism "${BKTEC_MAX_PARALLELISM}" \
  --target-time "${BKTEC_TARGET_TIME:-2m}")

echo "Plan JSON: $PLAN_JSON"
echo "$PLAN_JSON" > plan.json
buildkite-agent artifact upload plan.json

# Export plan vars into the current shell so pipeline upload can substitute them
export BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER
export BUILDKITE_TEST_ENGINE_PARALLELISM
BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER=$(echo "$PLAN_JSON" | jq -r '.BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER')
BUILDKITE_TEST_ENGINE_PARALLELISM=$(echo "$PLAN_JSON" | jq -r '.BUILDKITE_TEST_ENGINE_PARALLELISM')

# Upload the pipeline now so the test steps can start running immediately
buildkite-agent pipeline upload .buildkite/dynamic-parallel-template.yml

# Fetch the full bin-packing plan and upload as an artifact.
# Only possible when bktec successfully created a server-side plan (not a fallback).
# A fallback plan has a locally-generated identifier that does not exist on the server.
if [[ -n "$BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER" ]]; then
  echo "+++ Fetching bin-packing plan"
  echo "Org: ${BUILDKITE_ORGANIZATION_SLUG}, Suite: ${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"
  echo "Identifier: ${BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER}"

  HTTP_STATUS=$(curl --get --write-out "%{http_code}" --output bin-packing-plan.json \
    --header "Authorization: Bearer ${BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN}" \
    --data-urlencode "identifier=${BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER}" \
    --data-urlencode "job_retry_count=0" \
    "https://api.buildkite.com/v2/analytics/organizations/${BUILDKITE_ORGANIZATION_SLUG}/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}/test_plan")

  echo "HTTP status: ${HTTP_STATUS}"
  cat bin-packing-plan.json

  if [[ "$HTTP_STATUS" == "200" ]]; then
    PLAN_PRETTY="bin-packing-plan-${BUILDKITE_TEST_ENGINE_SUITE_SLUG}.json"
    PLAN_CHART="bin-packing-plan-${BUILDKITE_TEST_ENGINE_SUITE_SLUG}.png"

    jq '.' bin-packing-plan.json > "$PLAN_PRETTY"
    buildkite-agent artifact upload "$PLAN_PRETTY"

    echo "+++ Generating bin-packing chart"
    python3 .buildkite/scripts/chart_plan.py "$PLAN_PRETTY" "$PLAN_CHART"
    buildkite-agent artifact upload "$PLAN_CHART"

    echo "+++ Annotating build with plan summary"

    # Build per-node stats table rows (markdown)
    TABLE_ROWS=$(jq -r '
      .tasks | to_entries | sort_by(.key | tonumber) | .[] |
      "| Node \(.value.node_number) | \(.value.tests | length) | \(.value.tests | map(.estimated_duration) | add // 0 | . / 1000000 * 100 | round / 100)s |"
    ' "$PLAN_PRETTY")

    # Compact plan summary for Claude prompt (avoids sending the full JSON verbatim)
    PLAN_SUMMARY=$(jq -c '{
      parallelism: .parallelism,
      settings: .settings,
      nodes: [
        .tasks | to_entries[] | {
          node: .value.node_number,
          total_duration_seconds: (.value.tests | map(.estimated_duration) | add // 0 | . / 1000000 * 100 | round / 100),
          files: [.value.tests[] | {path: .path, duration_seconds: (.estimated_duration / 1000000 * 100 | round / 100)}]
        }
      ] | sort_by(.node)
    }' "$PLAN_PRETTY")

    # Whether this runner supports split-by-example
    case "${BUILDKITE_TEST_ENGINE_TEST_RUNNER}" in
      rspec|pytest) SPLIT_BY_EXAMPLE_NOTE="The test runner is '${BUILDKITE_TEST_ENGINE_TEST_RUNNER}', which supports BUILDKITE_TEST_ENGINE_SPLIT_BY_EXAMPLE. If any individual test files are slow enough to be bottlenecks, suggest enabling this to allow bktec to split those files at the example level for finer-grained distribution." ;;
      *) SPLIT_BY_EXAMPLE_NOTE="" ;;
    esac

    PROMPT="You are analysing a bin-packing plan for a CI test suite split across parallel nodes.

Plan data (durations in seconds):
${PLAN_SUMMARY}

Configuration: max_parallelism=${BKTEC_MAX_PARALLELISM}, target_time=${BKTEC_TARGET_TIME:-2m}, suite=${BUILDKITE_TEST_ENGINE_SUITE_SLUG}, runner=${BUILDKITE_TEST_ENGINE_TEST_RUNNER}

Provide a concise analysis covering:
1. How well-balanced the distribution is across nodes, citing specific durations
2. Any bottleneck files that dominate a single node
3. Concrete suggestions for max_parallelism and target_time to improve the pack
${SPLIT_BY_EXAMPLE_NOTE}

Keep it to 2-3 short paragraphs. Be specific — use file names and durations."

    CLAUDE_RESPONSE=$(curl --silent --fail -X POST \
      "${BUILDKITE_AGENT_ENDPOINT}/ai/anthropic/v1/messages" \
      -H "Content-Type: application/json" \
      -H "x-api-key: ${BUILDKITE_AGENT_ACCESS_TOKEN}" \
      --data "$(jq -n \
        --arg prompt "$PROMPT" \
        '{model: "claude-sonnet-4-5", max_tokens: 600, messages: [{role: "user", content: $prompt}]}'
      )" | jq -r '.content[0].text // empty')

    cat > annotation.md <<EOF
![Bin packing chart](artifact://${PLAN_CHART})

| Node | Files | Duration |
|------|-------|----------|
${TABLE_ROWS}

### 🤖 AI Analysis

${CLAUDE_RESPONSE:-*Analysis unavailable*}
EOF

    echo "Agent version: $(buildkite-agent --version)"
    echo "Job ID: ${BUILDKITE_JOB_ID}"
    echo "Annotation body:"
    cat annotation.md
    echo "---"
    buildkite-agent annotate --scope=job --style "info" \
      --endpoint https://agent-edge.buildkite.com/v3 \
      < annotation.md
    echo "Annotate exit code: $?"
  else
    echo "Skipping bin-packing plan artifact: server returned ${HTTP_STATUS} (bktec may have used a fallback plan)"
  fi
else
  echo "Skipping bin-packing plan artifact: bktec fell back to non-intelligent splitting"
fi
