# Example Test Suite for Buildkite Test Engine

This is an internal Buildkite demo repository used for showcasing and testing [Buildkite Test Engine](https://buildkite.com/test-engine) features. It contains a fake RSpec test suite where each spec uses `sleep` calls to simulate realistic test durations — there is no real application under test.

## Purpose

The repo is used to demonstrate:

- **Intelligent test splitting** via [`bktec`](https://github.com/buildkite/test-engine-client) — splits tests across parallel nodes using historical timing data (bin-packing) rather than naive round-robin
- **Dynamic parallelism** — plan steps calculate optimal node count then upload a generated pipeline
- **OIDC authentication** — tests ingest results using short-lived OIDC tokens instead of long-lived static suite tokens
- **Test ownership** — flaky tests are automatically assigned to owning teams via `TESTOWNERS`
- **Bin-packing plan visualisation** — after planning, a chart and Claude-generated analysis annotation are added to the build

## Pipelines

### `pipeline.yml` — Optimised (with Test Engine)

Demonstrates the full Test Engine feature set:

1. **Linting / Coverage / Build** groups run in parallel (fake `echo` steps)
2. After a `wait`, two plan steps run in parallel — one for unit tests (`rspec` suite) and one for feature specs (`feature-tests` suite). Each plan step:
   - Extracts `bktec` from the official `buildkite/test-engine-client` image
   - Runs `bktec plan` to generate an intelligent split from historical timing data
   - Uploads `.buildkite/dynamic-parallel-template.yml` with the calculated parallelism
   - Fetches the full bin-packing plan from the Test Engine API, generates a chart, and posts an AI analysis annotation
3. After another `wait`, the dynamically generated test steps run with optimal distribution

### `pipeline-not-optimised.yml` — Unoptimised (baseline comparison)

The same suite without intelligent splitting — static parallelism, no dynamic planning, three separate redundant feature spec steps. Intended to show what the pipeline looks like without Test Engine optimisation so the improvement is visible by comparison.

## Authentication

### OIDC (analytics ingestion)

`test.sh` and `feature-tests.sh` request a short-lived OIDC token from the Buildkite agent and export it as `BUILDKITE_ANALYTICS_TOKEN`:

```bash
SUITE_URL="https://buildkite.com/organizations/${BUILDKITE_ORGANIZATION_SLUG}/analytics/suites/${BUILDKITE_TEST_ENGINE_SUITE_SLUG}"
export BUILDKITE_ANALYTICS_TOKEN=$(buildkite-agent oidc request-token --audience "$SUITE_URL" --lifetime 300)
```

This requires an **OIDC policy** to be configured in each suite's Test Engine settings:

```yaml
- iss: "https://agent.buildkite.com"
  claims:
    organization_slug: "your-org"
    pipeline_slug:
      in:
        - "your-pipeline"
  scopes:
    - "read_suites"
    - "write_uploads"
```

The token lifetime should exceed the longest expected duration of the Docker build + test run for that step.

### Test Engine API (planning and plan retrieval)

`plan.sh` uses `BUILDKITE_TEST_ENGINE_API_ACCESS_TOKEN` (stored as a Buildkite secret named `API_ACCESS_TOKEN`) for `bktec plan` and for fetching the bin-packing plan from the REST API.

## Secrets required

| Secret name | Used for |
|---|---|
| `API_ACCESS_TOKEN` | Test Engine API — planning and fetching bin-packing plans |

No static suite token secrets are needed — ingestion uses OIDC.

## Fake test durations

`spec/spec_helper.rb` defines `spoof_duration` which each spec calls to simulate realistic timing:

| Type | Duration |
|---|---|
| Unit | 0.1–0.3s |
| Feature | 1–3s |
| Slow feature | 5–10s |
| Really slow feature | 10–30s |
| E2E | 45–55s |

An `SPOOF_ARM_MODE=true` env var applies a 0.85× duration multiplier and reduces flakiness, simulating a faster ARM architecture for demo comparisons.

## Test Ownership

The `TESTOWNERS` file maps glob patterns to team slugs. Flaky tests detected by Test Engine are automatically assigned to their owner:

| Team | Files |
|---|---|
| `iam` | login, logout, password, team, user, org, workspace, flaky specs |
| `growth` | cart, checkout, order, product, user signup specs |
| `platform` | admin dashboard, e2e, smoke specs |

## Docker

`Dockerfile` builds a Ruby 3.3 Alpine image that bundles `bktec` (from `buildkite/test-engine-client:v2.4.0`) and the `buildkite-test-collector` gem. `Dockerfile.v1.1` is an alternative version for testing upgrades; set `DOCKERFILE=Dockerfile.v1.1` on a step to use it.

The plan steps do **not** build the full app image — they pull just the `buildkite/test-engine-client` image to extract `bktec`, which is significantly faster.
