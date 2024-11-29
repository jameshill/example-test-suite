#!/bin/bash

set -e

export BUILDKITE_ANALYTICS_TOKEN=$(buildkite-agent secret get SUITE_TOKEN)
export BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN=$(buildkite-agent secret get API_ACCESS_TOKEN)

# Path to the metadata fetching script
METADATA_SCRIPT="./.buildkite/steps/fetch_metadata.sh"

# Call the metadata script and store the output in a variable
METADATA_JSON=$($METADATA_SCRIPT)

# Export the JSON as an environment variable
export INSTANCE_METADATA_JSON="$METADATA_JSON"

# Print the variable to verify
echo "Metadata JSON stored in environment variable:"
echo "$INSTANCE_METADATA_JSON"

export BUILDKITE_ORGANIZATION_SLUG="test-engine-sandbox"
export BUILDKITE_TEST_ENGINE_SUITE_SLUG="rspec-3"
export BUILDKITE_TEST_ENGINE_TEST_CMD="bundle exec rspec {{testExamples}} --format progress --format json --out tmp/result.json"
export BUILDKITE_TEST_ENGINE_DEBUG_ENABLED="false"
export BUILDKITE_TEST_ENGINE_RETRY_COUNT=1
export BUILDKITE_TEST_ENGINE_RESULT_PATH="tmp/result.json"
export BUILDKITE_TEST_ENGINE_TEST_RUNNER=rspec

docker build -t app --load .

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
  --env BUILDKITE_TEST_ENGINE_RETRY_COUNT \
  --env FLAKY_MODE \
  -it --rm app sh -c "bktec"
