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
"$BKTEC" plan \
  --max-parallelism "${BKTEC_MAX_PARALLELISM}" \
  --target-time "${BKTEC_TARGET_TIME:-2m}" \
  --pipeline-upload .buildkite/dynamic-parallel-template.yml
