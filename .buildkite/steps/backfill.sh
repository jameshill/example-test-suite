#!/bin/bash

set -euo pipefail

# Upload historical git commit metadata for the suite so test selection
# has training signal for commits that pre-date bktec on this repo.
#
# Operates on the current checkout's .git (bktec has no clone/path flag);
# the Buildkite agent has already checked out the branch, and the backfill
# walks the configured remote's default branch. The repo is small, so a
# shallow checkout is fine.
#
# Auth: OIDC. Leaving BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN unset makes
# bktec mint a token via `buildkite-agent oidc request-token`
# (audience <base>/v2/analytics/organizations/<org>/suites/<suite>).
# Requires the suite oidc_policy to grant write_suites.

: "${BUILDKITE_ORGANIZATION_SLUG:?required}"
: "${BUILDKITE_TEST_ENGINE_SUITE_SLUG:?required}"

# Extract bktec from the official image — mirrors plan.sh; avoids building
# the full app just to run the tool.
BKTEC_IMAGE=$(grep 'COPY --from=buildkite/test-engine-client' Dockerfile | sed 's/.*--from=\([^ ]*\).*/\1/')
BKTEC=$(mktemp)
docker create --name bktec-backfill-extract "$BKTEC_IMAGE"
docker cp bktec-backfill-extract:/usr/local/bin/bktec "$BKTEC"
docker rm bktec-backfill-extract
chmod +x "$BKTEC"

echo "+++ :test_tube: bktec backfill-commit-metadata (upload)"
echo "Org: ${BUILDKITE_ORGANIZATION_SLUG}, Suite: ${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"

# tools is a preview subcommand gated behind BKTEC_PREVIEW_SELECTION.
# Default behaviour collects fresh metadata and uploads it; --upload is
# only for re-uploading a pre-built tarball, and --output writes locally
# instead of uploading. We want neither.
BKTEC_PREVIEW_SELECTION=1 "$BKTEC" tools backfill-commit-metadata \
  --days "${BACKFILL_DAYS:-90}"

echo "Backfill upload complete."
