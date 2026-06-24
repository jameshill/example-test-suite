#!/bin/bash

set -euo pipefail

# Evaluation capture: persist predicted plans at chosen cutoffs as build
# artifacts so they can be diffed against the current plan offline.
# Follows docs/evaluating-test-prediction.md (sections 1 and 3).
#
# This runs in its OWN step, isolated from the real plan.sh run, so an
# evaluation plan can never collide with or alter the plan the tests
# actually run on. Capturing plans for already-planned commits has no
# effect on the data or the model.
#
# Auth: OIDC, mirroring backfill.sh. The full-plan REST fetch needs a
# suite-scoped token with read_test_plan, minted inline per request.

: "${BUILDKITE_ORGANIZATION_SLUG:?required}"
: "${BUILDKITE_TEST_ENGINE_SUITE_SLUG:?required}"

# Extract bktec from the official image — mirrors plan.sh / backfill.sh;
# avoids building the full app just to run the tool.
BKTEC_IMAGE=$(grep 'COPY --from=buildkite/test-engine-client' Dockerfile | sed 's/.*--from=\([^ ]*\).*/\1/')
BKTEC=$(mktemp)
docker create --name bktec-eval-extract "$BKTEC_IMAGE"
docker cp bktec-eval-extract:/usr/local/bin/bktec "$BKTEC"
docker rm bktec-eval-extract
chmod +x "$BKTEC"

# Capture at file granularity (section 1). Keep this unset so the plan
# stays at file paths rather than per-example selectors.
unset BUILDKITE_TEST_ENGINE_SPLIT_BY_EXAMPLE

OIDC_AUDIENCE="https://api.buildkite.com/v2/analytics/organizations/${BUILDKITE_ORGANIZATION_SLUG}/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"

# capture_plan SCORE_CUTOFF COUNT_CUTOFF SLUG
#
# Requests a plan at the given cutoffs, fetches the full file-level plan,
# and uploads both as artifacts. A distinct identifier per call (section 3)
# stops repeated requests in one step returning the first plan every time.
capture_plan() {
  local score_cutoff="$1"
  local count_cutoff="$2"
  local slug="$3"

  local plan_file="plan-${slug}.json"
  local full_file="full-plan-${slug}.json"

  echo "+++ Capture: score_cutoff=${score_cutoff} count_cutoff=${count_cutoff} (${slug})"

  # 1. Request the plan at --max-parallelism 1 so the whole selected set
  #    lands in tasks["0"], already in prediction-rank order.
  local plan_json
  plan_json=$(BUILDKITE_TEST_ENGINE_IDENTIFIER="${BUILDKITE_BUILD_ID}-${slug}" \
    BKTEC_PREVIEW_SELECTION=1 "$BKTEC" plan --json \
    --max-parallelism 1 \
    --selection-strategy xgboost \
    --selection-param "score_cutoff=${score_cutoff}" \
    --selection-param "count_cutoff=${count_cutoff}")

  echo "$plan_json" > "$plan_file"
  local identifier
  identifier=$(echo "$plan_json" | jq -r '.BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER')

  if [[ -z "$identifier" || "$identifier" == "null" ]]; then
    echo "No plan identifier (bktec fell back to local splitting); excluding ${slug}."
    return 0
  fi

  # Echo the server-returned identifier so distinct cutoffs can be
  # confirmed to produce distinct plans (not the same plan re-fetched).
  echo "Plan identifier (${slug}): ${identifier}"

  # 2. Mint a short-lived suite-scoped token for the REST fetch.
  local token
  token=$(buildkite-agent oidc request-token --audience "$OIDC_AUDIENCE" --lifetime 300)

  # 3. Fetch the full plan (the one with the file-level `tasks`).
  local http_status
  http_status=$(curl --get --write-out "%{http_code}" --output "$full_file" \
    --header "Authorization: Bearer ${token}" \
    --data-urlencode "identifier=${identifier}" \
    --data-urlencode "job_retry_count=0" \
    "${OIDC_AUDIENCE}/test_plan")

  # A 200 with an empty `tasks` object is a server-side error plan, not a
  # real selection — treat it the same as a non-200 and exclude the build.
  local task_count
  task_count=$(jq '.tasks | length' "$full_file" 2>/dev/null || echo 0)

  if [[ "$http_status" == "200" && "$task_count" -gt 0 ]]; then
    echo "Captured ${task_count} task node(s) for ${slug}."
    buildkite-agent artifact upload "$plan_file"
    buildkite-agent artifact upload "$full_file"
  else
    echo "No usable server plan for ${slug} (status ${http_status}, ${task_count} tasks); skipping."
  fi
}

# Reference + score-cutoff sweep (section 3). score_cutoff=0 keeps
# everything (the run-everything baseline); the rest are the trust axis
# with the count term neutralised.
capture_plan 0   0 "sc0"
capture_plan 0.5 0 "sc0.5"
capture_plan 0.8 0 "sc0.8"
capture_plan 0.9 0 "sc0.9"

# Count-cutoff sample (section 3): score_cutoff=1 so only the count term
# applies and the set is the top N by rank.
capture_plan 1 50 "cc50"

echo "Evaluation capture complete."
