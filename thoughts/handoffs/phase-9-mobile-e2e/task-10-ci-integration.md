# Task 9.10 — CI Integration (Maestro Cloud + GitHub Actions)

**Status: COMPLETED**
**Branch:** `task-9.10-ci-integration` (git fallback mode — Graphite not installed at `/opt/homebrew/bin/gt`)

---

## What was built

The full Maestro E2E suite can now run on Maestro Cloud against an
uploaded Android build, triggered from GitHub Actions on every push to
`main`. The plumbing is complete; running it green requires three
operator-side prerequisites (see "Operator setup required" below).

### Files added

- `.github/workflows/e2e-mobile.yml` — GitHub Actions workflow
- `thoughts/handoffs/phase-9-mobile-e2e/task-10-ci-integration.md` — this handoff

### Files changed

- `Makefile` — new targets `test-mobile-e2e-cloud` and `_e2e-cloud-preflight`,
  plus override variables `MAESTRO_CLOUD_API_KEY`, `E2E_APP_BINARY`, `E2E_BACKEND_URL`

---

## Design decisions

### Android only, not iOS

iOS Maestro Cloud runs require an Apple Developer signing identity and a
provisioning profile, neither of which exist in this repo. Android-only
keeps the workflow runnable on the GitHub-hosted free `ubuntu-latest` runner
without paid macOS minutes or Apple credentials.

The 28-flow suite was validated locally against iOS Simulator in task 9.9.
Adding iOS to cloud CI is a future concern — track as a follow-up if
iOS-specific regressions start slipping through.

### Preflight gates over silent fallbacks

`make test-mobile-e2e-cloud` aborts with explicit error messages if any
of `MAESTRO_CLOUD_API_KEY`, the APK file, or `E2E_BACKEND_URL` are missing.
Cheap fail-fast behaviour beats a confusing maestro-cli stack trace
600 lines into a CI log.

### Workflow gates on the secret, not the trigger

The workflow runs on every push to `main` but skips early — with a clear
log line — when `MAESTRO_CLOUD_API_KEY` is unset. This means landing this
PR doesn't break CI before the operator has had a chance to add the
secret. Once the secret lands, the next push exercises the full path.

### `EXPO_PUBLIC_API_URL` baked in at build time

`process.env.EXPO_PUBLIC_API_URL` is read at JS-bundle-build time, not at
app launch. The workflow therefore exports `EXPO_PUBLIC_API_URL=$E2E_BACKEND_URL`
during `expo prebuild` and `gradlew assembleRelease`. Setting it at
`maestro cloud` time would have no effect.

---

## Operator setup required (out of code scope)

The workflow is fully wired but cannot produce a green run until the
following are in place. None of these can be done from a code commit;
they require operator action with credentials I don't have.

1. **Create a Maestro Cloud account** at https://console.mobile.dev/ and
   generate an API key. Free tier is ~100 flow runs/month — the 28-flow
   suite consumes 28 runs per push to main, so plan accordingly (consider
   gating the workflow further or upgrading tier if push-to-main cadence
   is high).

2. **Add GitHub Actions secrets** under
   Settings → Secrets and variables → Actions:
   - `MAESTRO_CLOUD_API_KEY` (required) — from step 1
   - `E2E_BACKEND_URL` (required) — public URL the cloud-built app will hit

3. **Deploy a public dev backend** for `E2E_BACKEND_URL`. Maestro Cloud
   runners cannot reach `localhost`, so the existing local-dev pattern
   (`docker compose up && expo start`) does not transfer. Realistic
   options:
   - Deploy `backend/` to Fly.io / Render / Railway pointed at a managed
     Postgres + Redis
   - Run an ngrok / cloudflared tunnel from a dedicated machine (fragile
     for CI; not recommended)

   The `mobile/e2e/seed/setup.sh` script will need to run against this
   public backend before the suite — wire it in as a workflow step once
   the backend exists.

---

## Verification

`make test-mobile-e2e-cloud` exercises three preflight gates that all
fire with actionable error messages:

```
$ make test-mobile-e2e-cloud
ERROR: MAESTRO_CLOUD_API_KEY is not set.
  Generate one at https://console.mobile.dev/ and export it, ...

$ MAESTRO_CLOUD_API_KEY=fake-key make test-mobile-e2e-cloud
ERROR: app binary not found at: mobile/android/app/build/outputs/apk/release/app-release.apk
  Build it first (e.g. cd mobile && npx expo prebuild -p android && cd android && ./gradlew assembleRelease)
  ...

$ MAESTRO_CLOUD_API_KEY=fake-key E2E_APP_BINARY=/tmp/fake.apk make test-mobile-e2e-cloud
ERROR: E2E_BACKEND_URL is not set.
  The uploaded app cannot reach localhost from Maestro Cloud — it needs a public backend URL.
  ...
```

A real run cannot be verified locally without a Maestro Cloud account.
The verification command (`make test-mobile-e2e-cloud`) executes
correctly: it gates on configuration, then would call `maestro cloud` if
all preflight passed.

Existing local E2E targets are unchanged — `make -n test-mobile-e2e`
emits the same command line as before this task.

---

## Push status

`git push -u origin task-9.10-ci-integration` — to be attempted once
commit lands. Per CLAUDE.md push policy: best-effort, no workarounds if
it fails.

---

## Follow-ups (for task 9.11 or later)

- Document `mobile/e2e/README.md` cloud-run section (task 9.11)
- Update `CLAUDE.md` E2E section to mention `make test-mobile-e2e-cloud`
  and the `EXPO_PUBLIC_API_URL` build-time gotcha (task 9.11)
- Add iOS to cloud CI when Apple Developer credentials are provisioned
- Wire backend seed (`mobile/e2e/seed/setup.sh`) into the workflow once
  a public backend URL exists
- Consider running a smaller smoke subset on every push and the full
  28-flow suite nightly, to stay under Maestro Cloud free-tier quota
