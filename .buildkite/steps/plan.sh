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

# Upload plan as artifact for inspection
echo "$PLAN_JSON" > plan.json
buildkite-agent artifact upload plan.json

# Set BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER and BUILDKITE_TEST_ENGINE_PARALLELISM
# in the job environment, then upload the pipeline template with those vars substituted
echo "$PLAN_JSON" | buildkite-agent env set --input-format=json -
buildkite-agent pipeline upload .buildkite/dynamic-parallel-template.yml
