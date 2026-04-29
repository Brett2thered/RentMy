# Commit 59eac55 — Maestro Cloud CI workflow (task 9.10)

## Context

Task 9.10 of phase 9 (Mobile E2E Test Suite). The phase-9 plan asked
for: free Maestro Cloud setup, `.github/workflows/e2e-mobile.yml`
triggered on push to main, `make test-mobile-e2e-cloud` target, and
"test the workflow."

The plan was thin and skipped over real architectural questions
(platform choice, build artifact strategy, backend reachability from
cloud runners, free-tier capacity). I considered each before writing
code rather than guessing at one and shipping it half-cooked.

## Why Android-only

iOS Maestro Cloud needs Apple Developer signing identity and
provisioning profile. Neither exists in this repo. Adding iOS would
require obtaining Apple credentials and adding them as secrets — this
is operator-side work outside what a code commit can deliver. Android
runs on free `ubuntu-latest` runners with no extra credentials.

The 28-flow suite was validated locally on iOS Simulator in task 9.9,
so cloud iOS coverage is a future concern, not a regression.

## Why preflight gates

Maestro CLI's failure modes are noisy. A missing API key, a missing
APK, or a missing backend URL each produce different opaque errors deep
in the maestro-cli log. The preflight target (`_e2e-cloud-preflight`)
checks all three explicitly and prints actionable error messages with
the fix command. Cheap fail-fast beats spelunking through CLI logs.

## Why the workflow gates on the secret being set

Adding a workflow that hard-fails on every push to main until the
operator manually sets a secret is hostile. The workflow runs on every
push but skips early — with a clear log line — when
`MAESTRO_CLOUD_API_KEY` is unset. First push after merge: green skip.
First push after the operator sets the secret: real run.

## Why `EXPO_PUBLIC_API_URL` exported during build

`process.env.EXPO_PUBLIC_API_URL` is read at JS-bundle-build time
(metro inlines it into the bundle), not at runtime. The workflow
exports it during `expo prebuild` and `gradlew assembleRelease`.
Setting it at `maestro cloud` invocation time would have no effect on
the already-built bundle. Documenting this in the handoff to save the
next person the debugging.

## What was tried and discarded

- Considered using a self-hosted macOS runner instead of Maestro Cloud.
  Rejected because the plan explicitly says Maestro Cloud, and
  self-hosting moves cost from the cloud quota to runner uptime.
- Considered tunneling localhost via ngrok in CI for the backend URL.
  Rejected as too fragile (free-tier ngrok rate limits, URL rotation,
  flow timing). Documented as an unviable option in the handoff.
- Considered hard-failing the workflow when the secret is missing.
  Rejected because the first push to main would be the very push that
  introduces the workflow, before any secret can be configured.

## What this does NOT do (operator follow-up)

- Create a Maestro Cloud account
- Add the GitHub Actions secrets (`MAESTRO_CLOUD_API_KEY`,
  `E2E_BACKEND_URL`)
- Deploy a public dev backend so the cloud-built APK can reach an API
- Wire the seed script (`mobile/e2e/seed/setup.sh`) into the workflow
  once the public backend exists

These are documented in the handoff and are gating real green runs.
