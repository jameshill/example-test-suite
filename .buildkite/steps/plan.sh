#!/bin/bash

set -e

export BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN=$(buildkite-agent secret get API_ACCESS_TOKEN)

DOCKERFILE=${DOCKERFILE:-Dockerfile}
docker build -f $DOCKERFILE -t app --load .

# Extract bktec from the Docker image to run natively for pipeline planning
BKTEC=$(mktemp)
docker create --name bktec-extract app
docker cp bktec-extract:/usr/local/bin/bktec "$BKTEC"
docker rm bktec-extract
chmod +x "$BKTEC"

echo "+++ bktec plan"
PLAN_JSON=$("$BKTEC" plan --json \
  --max-parallelism "${BKTEC_MAX_PARALLELISM}" \
  --target-time "${BKTEC_TARGET_TIME:-2m}")

# Export plan vars into the current shell so pipeline upload can substitute them
export BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER
export BUILDKITE_TEST_ENGINE_PARALLELISM
BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER=$(echo "$PLAN_JSON" | jq -r '.BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER')
BUILDKITE_TEST_ENGINE_PARALLELISM=$(echo "$PLAN_JSON" | jq -r '.BUILDKITE_TEST_ENGINE_PARALLELISM')

# Fetch the full bin-packing plan and upload as an artifact
# Only possible when bktec successfully created a server-side plan (not a fallback)
if [[ -n "$BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER" ]]; then
  curl --silent --fail \
    --header "Authorization: Bearer ${BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN}" \
    "https://api.buildkite.com/v2/analytics/organizations/${BUILDKITE_ORGANIZATION_SLUG}/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}/test_plan?identifier=${BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER}&job_retry_count=0" \
    | jq '.' > bin-packing-plan.json
  buildkite-agent artifact upload bin-packing-plan.json
else
  echo "Skipping bin-packing plan artifact: bktec fell back to non-intelligent splitting"
fi

buildkite-agent pipeline upload .buildkite/dynamic-parallel-template.yml
