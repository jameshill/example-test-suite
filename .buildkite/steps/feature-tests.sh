#!/bin/bash

set -e

SUITE_URL="https://buildkite.com/organizations/${BUILDKITE_ORGANIZATION_SLUG}/analytics/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"
export BUILDKITE_ANALYTICS_TOKEN=$(buildkite-agent oidc request-token --audience "$SUITE_URL" --lifetime 300)
if [[ -n "$BUILDKITE_ANALYTICS_TOKEN" ]]; then
  echo "OIDC token fetched successfully for audience: ${SUITE_URL}"
else
  echo "ERROR: Failed to fetch OIDC token for audience: ${SUITE_URL}" >&2
  exit 1
fi
export BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN=$(buildkite-agent secret get API_ACCESS_TOKEN)
export BUILDKITE_TEST_ENGINE_RETRY_COUNT=${RETRYCOUNT:-1}

DOCKERFILE=${DOCKERFILE:-Dockerfile}

# Check if the environment variable is provided
if [ "$DOCKERFILE" == "Dockerfile.v1.1" ]; then
    echo "Using v1.1"
else
    echo "Using default Dockerfile"
fi

docker build -f $DOCKERFILE -t app --load .

echo "+++ bktec"
docker run \
  --env BUILDKITE_TEST_ENGINE_DEBUG_ENABLED \
  --env BUILDKITE_TEST_ENGINE_TEST_CMD \
  --env BUILDKITE_ANALYTICS_TOKEN \
  --env BUILDKITE_ORGANIZATION_SLUG \
  --env BUILDKITE_TEST_ENGINE_SUITE_SLUG \
  --env BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN \
  --env BUILDKITE_TEST_ENGINE_RESULT_PATH \
  --env BUILDKITE_TEST_ENGINE_TEST_RUNNER \
  --env BUILDKITE_PIPELINE_SLUG \
  --env BUILDKITE_BUILD_ID \
  --env BUILDKITE_STEP_ID \
  --env BUILDKITE_BUILD_NUMBER \
  --env BUILDKITE_JOB_ID \
  --env BUILDKITE_BRANCH \
  --env BUILDKITE_COMMIT \
  --env BUILDKITE_MESSAGE \
  --env BUILDKITE_BUILD_URL \
  --env BUILDKITE_PARALLEL_JOB \
  --env BUILDKITE_PARALLEL_JOB_COUNT \
  --env BUILDKITE_TEST_ENGINE_TEST_FILE_PATTERN \
  --env BUILDKITE_TEST_ENGINE_TEST_FILE_EXCLUDE_PATTERN \
  --env BUILDKITE_TEST_ENGINE_SPLIT_BY_EXAMPLE \
  --env BUILDKITE_TEST_ENGINE_RETRY_COUNT \
  --env BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER \
  --env SPOOF_ARM_MODE \
  --env FLAKY_MODE \
  -it --rm app sh -c "bktec run"

