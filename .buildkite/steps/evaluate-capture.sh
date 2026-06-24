#!/bin/bash

set -euo pipefail

# Evaluation capture: persist a predicted plan at one chosen cutoff as
# build artifacts so it can be diffed against the current plan offline.
# Follows docs/evaluating-test-prediction.md (sections 1 and 3).
#
# ONE CUTOFF PER STEP, BY DESIGN. bktec keys each plan by an identifier
# defaulting to ${BUILDKITE_BUILD_ID}/${BUILDKITE_STEP_ID}, and the
# ability to override it was removed (test-engine-client PR #102). The
# server returns the cached plan for a repeated identifier, so multiple
# plan requests in a single step all collapse to the same plan. Distinct
# plans therefore need distinct BUILDKITE_STEP_IDs — i.e. separate steps.
# The pipeline runs this script once per cutoff; each invocation reads its
# cutoff from the environment below.
#
# This also keeps the capture isolated from the real plan.sh run, so an
# evaluation plan can never collide with or alter the plan the tests
# actually run on. Capturing plans for already-planned commits has no
# effect on the data or the model.
#
# Auth: OIDC, mirroring backfill.sh. The full-plan REST fetch needs a
# suite-scoped token with read_test_plan, minted inline.

: "${BUILDKITE_ORGANIZATION_SLUG:?required}"
: "${BUILDKITE_TEST_ENGINE_SUITE_SLUG:?required}"
: "${EVAL_SCORE_CUTOFF:?required (set per step)}"
: "${EVAL_COUNT_CUTOFF:?required (set per step)}"
: "${EVAL_SLUG:?required (set per step, used for artifact names)}"

# Extract bktec from the official image — mirrors plan.sh / backfill.sh;
# avoids building the full app just to run the tool.
BKTEC_IMAGE=$(grep 'COPY --from=buildkite/test-engine-client' Dockerfile | sed 's/.*--from=\([^ ]*\).*/\1/')
BKTEC=$(mktemp)
docker create --name "bktec-eval-extract-${EVAL_SLUG}" "$BKTEC_IMAGE"
docker cp "bktec-eval-extract-${EVAL_SLUG}:/usr/local/bin/bktec" "$BKTEC"
docker rm "bktec-eval-extract-${EVAL_SLUG}"
chmod +x "$BKTEC"

# Capture at file granularity (section 1). Keep this unset so the plan
# stays at file paths rather than per-example selectors.
unset BUILDKITE_TEST_ENGINE_SPLIT_BY_EXAMPLE

OIDC_AUDIENCE="https://api.buildkite.com/v2/analytics/organizations/${BUILDKITE_ORGANIZATION_SLUG}/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"

PLAN_FILE="plan-${EVAL_SLUG}.json"
FULL_FILE="full-plan-${EVAL_SLUG}.json"

echo "+++ Capture: score_cutoff=${EVAL_SCORE_CUTOFF} count_cutoff=${EVAL_COUNT_CUTOFF} (${EVAL_SLUG})"

# 1. Request the plan at --max-parallelism 1 so the whole selected set
#    lands in tasks["0"], already in prediction-rank order. The identifier
#    is bktec's default (${BUILDKITE_BUILD_ID}/${BUILDKITE_STEP_ID}); it is
#    distinct from other cutoffs only because each runs in its own step.
PLAN_JSON=$(BKTEC_PREVIEW_SELECTION=1 "$BKTEC" plan --json \
  --max-parallelism 1 \
  --selection-strategy xgboost \
  --selection-param "score_cutoff=${EVAL_SCORE_CUTOFF}" \
  --selection-param "count_cutoff=${EVAL_COUNT_CUTOFF}")

echo "$PLAN_JSON" > "$PLAN_FILE"
IDENTIFIER=$(echo "$PLAN_JSON" | jq -r '.BUILDKITE_TEST_ENGINE_PLAN_IDENTIFIER')

if [[ -z "$IDENTIFIER" || "$IDENTIFIER" == "null" ]]; then
  echo "No plan identifier (bktec fell back to local splitting); excluding ${EVAL_SLUG}."
  exit 0
fi

# Echo the server-returned identifier so distinct cutoffs can be confirmed
# to produce distinct plans (compare across the per-cutoff step logs).
echo "Plan identifier (${EVAL_SLUG}): ${IDENTIFIER}"

# 2. Mint a short-lived suite-scoped token for the REST fetch.
TOKEN=$(buildkite-agent oidc request-token --audience "$OIDC_AUDIENCE" --lifetime 300)

# 3. Fetch the full plan (the one with the file-level `tasks`).
HTTP_STATUS=$(curl --get --write-out "%{http_code}" --output "$FULL_FILE" \
  --header "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "identifier=${IDENTIFIER}" \
  --data-urlencode "job_retry_count=0" \
  "${OIDC_AUDIENCE}/test_plan")

# A 200 with an empty `tasks` object is a server-side error plan, not a
# real selection — treat it the same as a non-200 and exclude the build.
TASK_COUNT=$(jq '.tasks | length' "$FULL_FILE" 2>/dev/null || echo 0)

if [[ "$HTTP_STATUS" == "200" && "$TASK_COUNT" -gt 0 ]]; then
  echo "Captured ${TASK_COUNT} task node(s) for ${EVAL_SLUG}."
  buildkite-agent artifact upload "$PLAN_FILE"
  buildkite-agent artifact upload "$FULL_FILE"
else
  echo "No usable server plan for ${EVAL_SLUG} (status ${HTTP_STATUS}, ${TASK_COUNT} tasks); skipping."
fi
