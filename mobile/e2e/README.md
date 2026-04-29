# RentMy Mobile E2E Tests

Maestro-based end-to-end test suite covering all core user flows in the RentMy iOS app.

---

## Quick Start

### Prerequisites

| Requirement | Version | Check |
|-------------|---------|-------|
| Maestro CLI | ≥ 2.4 | `~/.maestro/bin/maestro --version` |
| iOS Simulator | Booted | `xcrun simctl list devices \| grep Booted` |
| Docker services | Running | `docker compose ps` |
| Go backend | Running | `curl localhost:8080/health` |
| Seed data | Applied | `bash mobile/e2e/seed/setup.sh` |
| App build | Installed on simulator | `xcrun simctl listapps <device-id> \| grep rentmy` |

### Install Maestro

```bash
curl -Ls https://get.maestro.mobile.dev | bash
```

### Start services

```bash
# From repo root
docker compose up -d

# From backend/
make dev
```

The backend automatically activates E2E-friendly behaviour based on `STRIPE_SECRET_KEY`:
when it equals `sk_test_placeholder` (the default in `.env.example`) the payment service
swaps in a stub adapter that returns fake Stripe IDs — no real Stripe calls, no Stripe
sheet on mobile. There is no `E2E_MODE` env var.

### Seed test data

```bash
bash mobile/e2e/seed/setup.sh
```

Creates the two seeded accounts (alice host, bob renter), 5+ listings near LA matching
discovery search keywords, and any booking states required by handoff/dispute/rating
flows. Idempotent — safe to re-run between suite runs to reset state.

### Build and install the app

```bash
# First time (full build, ~5-10 min)
cd mobile && npx expo run:ios

# Subsequent runs (incremental, ~30 s)
cd mobile && npx expo run:ios
```

The simulator must be **booted** before running this command. Camera bypass triggers
automatically when `__DEV__ === true && device == null` in `AngleEnforcedCamera.native.tsx` —
the dev build writes a real JPEG from a fixture and pushes it through the normal
media-upload pipeline, so flows go through real S3 + listing create code paths.

### Run the full suite

```bash
# All 28 flows
make test-mobile-e2e

# Individual categories
make test-mobile-e2e-auth
make test-mobile-e2e-discovery
make test-mobile-e2e-listing
make test-mobile-e2e-booking
make test-mobile-e2e-handoff
make test-mobile-e2e-messaging
make test-mobile-e2e-profile
make test-mobile-e2e-disputes
make test-mobile-e2e-ratings
```

### Run on Maestro Cloud (CI)

The same suite runs on [Maestro Cloud](https://console.mobile.dev/) against an uploaded
Android APK. This is what `.github/workflows/e2e-mobile.yml` triggers on every push to
`main`.

```bash
# Locally (requires a Maestro Cloud account + a built APK + a public backend URL):
export MAESTRO_CLOUD_API_KEY=<from console.mobile.dev>
export E2E_BACKEND_URL=https://your-public-backend.example.com

# Build the APK (only needed if you don't already have one)
cd mobile && EXPO_PUBLIC_API_URL="$E2E_BACKEND_URL" npx expo prebuild --platform android --no-install --clean
cd android && EXPO_PUBLIC_API_URL="$E2E_BACKEND_URL" ./gradlew assembleRelease

# From repo root
make test-mobile-e2e-cloud
```

`make test-mobile-e2e-cloud` runs three preflight checks before invoking
`maestro cloud`:

| Gate | Failure message |
|------|-----------------|
| `MAESTRO_CLOUD_API_KEY` set? | "Generate one at https://console.mobile.dev/ ..." |
| APK exists at `E2E_APP_BINARY`? | "Build it first (e.g. cd mobile && ...)" |
| `E2E_BACKEND_URL` set? | "The uploaded app cannot reach localhost from Maestro Cloud" |

**Why a public backend URL is required.** `process.env.EXPO_PUBLIC_API_URL` is read at
JS-bundle-build time (Metro inlines it), not at app-launch time. Setting `E2E_BACKEND_URL`
when running `maestro cloud` does nothing — the URL must be in the environment when the
APK is built. Cloud-runner devices cannot reach `localhost`.

**CI workflow behaviour.** `.github/workflows/e2e-mobile.yml` skips early with a clear
log line when `MAESTRO_CLOUD_API_KEY` is unset, so the first push to `main` after merging
the workflow does not fail before the operator adds the secret. Required GitHub Actions
secrets:

- `MAESTRO_CLOUD_API_KEY` — from https://console.mobile.dev/
- `E2E_BACKEND_URL` — public URL of the dev backend the Android build will hit

iOS is **not** in the cloud workflow yet — Maestro Cloud iOS runs require an Apple
Developer signing identity that this repo does not have. iOS coverage today is
local-simulator-only (validated in task 9.9).

---

## Test Coverage

| Category | Flows | Happy path | Error path | Notes |
|----------|-------|------------|------------|-------|
| Auth | 6 | login, register, logout | wrong password, duplicate email, empty fields | |
| Discovery | 3 | browse feed, search, map | — | Map marker tap requires manual verification (native maps) |
| Listing | 2 | view detail, create | — | Create uses camera bypass |
| Booking | 5 | create request, view status, host accept, host decline, cancel | — | |
| Handoff | 4 | check-in, active rental, check-out, return confirmation | — | GPS bypass via `setLocation` |
| Messaging | 2 | view conversations, send message | — | |
| Profile | 3 | view profile, referrals, sign out | — | |
| Disputes | 2 | file dispute, view dispute status | — | |
| Ratings | 1 | rate counterparty | — | |
| **Total** | **28** | | | |

---

## Directory Structure

```
mobile/e2e/
  flows/
    auth/             6 flows (login, register x3, logout, login-wrong-password)
    discovery/        3 flows (browse-feed, search-listings, map-view)
    listing/          2 flows (view-listing-detail, create-listing)
    booking/          5 flows (create-request, view-status, host-accept, host-decline, cancel)
    handoff/          4 flows (check-in, active-rental, check-out, return-confirmation)
    messaging/        2 flows (view-conversations, send-message)
    profile/          3 flows (view-profile, referrals, sign-out)
    disputes/         2 flows (file-dispute, view-dispute-status)
    ratings/          1 flow  (rate-counterparty)
  helpers/
    login-as-renter.yaml    clearState → launchApp → login as bob@test.com
    login-as-host.yaml      clearState → launchApp → login as alice@test.com
    seed-booking.yaml       Seed a REQUESTED booking via API
    seed-booking-accepted.yaml   Seed an ACCEPTED booking
    seed-booking-active.yaml     Seed an ACTIVE booking
    seed-booking-completed.yaml  Seed a COMPLETED booking
    seed-conversation.yaml  Seed a conversation with messages
    seed-dispute.yaml       Seed a DISPUTED booking
    navigate-to-tab.yaml    Tap a tab bar item by label text
  scripts/
    seed-booking.js         HTTP helper: POST /api/v1/test/booking
    seed-conversation.js    HTTP helper: POST /api/v1/test/conversation
    seed-dispute.js         HTTP helper: POST /api/v1/test/dispute
    gen-unique-email.js     Generates a unique email for registration flows
  config/
    dev.env                 Environment variables for local runs (APP_ID, API_URL, accounts, GPS)
  seed/
    setup.sh                Seeds accounts, listings, and booking states via API + SQL
```

---

## Test Data

Tests run against real backend services using two seeded accounts:

| Account | Email | Role | Notes |
|---------|-------|------|-------|
| Renter | `bob@test.com` | Renter | No listings, can book |
| Host | `alice@test.com` | Host | 5 active listings |

Seeded data is created by `mobile/e2e/seed/setup.sh`, which combines real API calls
(register, login, create listing) with raw SQL (booking-state pre-population, GPS
normalization, deterministic ULIDs for stable testID matching). The script is
idempotent — re-run it any time test data drifts.

```bash
bash mobile/e2e/seed/setup.sh
```

### Idempotency

The seed script cascades through 10 child FK tables before deleting transactions, so
re-running it gives a clean baseline. Booking-state seeding uses fixed scheduling
offsets (`scheduledStart = NOW()` for ACTIVE, `NOW() - 3 hours` for ACCEPTED) so
deterministic ordering survives Maestro's non-alphabetical flow execution.

If state becomes truly wedged, fully reset:

```bash
cd backend && make migrate-down && make migrate-up
bash mobile/e2e/seed/setup.sh
```

---

## Adding New Tests

### 1. Pick the right template

- **Happy path flow:** Use `login-as-renter.yaml` or `login-as-host.yaml` as the first step, then navigate and assert.
- **Flow that needs a booking in state X:** Use the matching `seed-booking-*.yaml` helper, then `login-as-renter.yaml`.
- **Error path:** Use `clearState` + `launchApp` directly, skip the login helper.

### 2. Add testIDs to the app

All Maestro element selectors use `testID` props. Add them in the component:

```tsx
<Pressable testID="btn-my-action" onPress={...}>
```

Naming conventions:
- Screens: `screen-{route-name}` (e.g. `screen-feed`, `screen-checkout`)
- Buttons: `btn-{action}` (e.g. `btn-confirm-booking`, `btn-sign-out`)
- Inputs: `input-{field}` (e.g. `input-email`, `input-dispute-description`)
- Lists: `{noun}-list`, rows: `{noun}-row` (e.g. `conversation-list`, `rental-row`)
- Labels: `{noun}-label` (e.g. `booking-status-label`)

### 3. Write the flow YAML

```yaml
appId: ${APP_ID}
name: "Category - Action description"
env:
  APP_ID: com.rentmy.app
---
# Step comments explain WHY, not just what the YAML does.

- runFlow: e2e/helpers/login-as-renter.yaml

- tapOn: "Rentals"

- assertVisible:
    id: "screen-rentals"
    timeout: 5000
```

Timeout guidelines:
- Tab navigation / screen transitions: `4000`–`6000`
- API responses (local backend): `6000`–`8000`
- Complex state transitions (booking confirm, AI appraisal): `10000`–`20000`

### 4. Place the file

```
mobile/e2e/flows/{category}/{action}.yaml
```

Maestro discovers all YAML files under `e2e/flows/` automatically.

---

## Debugging Failures

### View screenshots

Maestro writes screenshots on failure to `~/.maestro/tests/<timestamp>/`. Run:

```bash
open ~/.maestro/tests/
```

### Run a single flow

```bash
cd mobile && ~/.maestro/bin/maestro test e2e/flows/auth/login.yaml --env-file e2e/config/dev.env
```

### Verbose output

```bash
cd mobile && ~/.maestro/bin/maestro test e2e/flows/ --env-file e2e/config/dev.env --debug-output /tmp/maestro-debug
```

### Common failure patterns

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Element not found: id=screen-X` | Screen not loaded yet | Increase `timeout` on the assertion |
| `Element not found: id=btn-Y` | TestID missing in app | Add `testID="btn-Y"` to the component |
| Test taps wrong `rental-row` | Stale DB state | Re-run `bash mobile/e2e/seed/setup.sh` |
| Stripe sheet appears in checkout | `STRIPE_SECRET_KEY` is a real key | Set it to `sk_test_placeholder` in `.env` to activate the stub adapter |
| Login flow fails after ~15 cycles | iOS simulator XPC handle leak | Already fixed in helpers (`stopApp` before `clearState`); recreate simulator if it returns |
| `port 7001 already in use` | Stale `maestro-driver` process | `make _e2e-clean-drivers` (also runs as `test-mobile-e2e` prereq) |
| Map markers not visible | Simulator location not set | `setLocation` before asserting map |

---

## Known Limitations

| Limitation | Reason | Workaround |
|-----------|--------|------------|
| Map marker / callout tap | React Native Maps renders markers in native MapKit outside the accessibility tree; Maestro cannot interact with them | Manual verification only |
| Native camera | Vision Camera uses native capture; no JS bridge for Maestro to hook | `__DEV__ && !device` activates fixture-photo bypass in `AngleEnforcedCamera.native.tsx` |
| Stripe sheet | Native Stripe SDK; cannot be automated | `STRIPE_SECRET_KEY=sk_test_placeholder` activates stub payment adapter (`backend/internal/payment/stub.go`) |
| Real-time Pusher events | Tests don't assert on push-triggered UI updates | Soketi (local Pusher) runs via Docker; manual verification if flaky |
| Shared test accounts | `bob@test.com` accumulates bookings across runs | Tests rely on backend's `ORDER BY created_at DESC` sort |

---

## Pass Rate (Task 9.9 Validation)

Three consecutive full suite runs:

| Run | Result | Duration |
|-----|--------|----------|
| 1 | 28/28 passed | 18m 25s |
| 2 | 28/28 passed | 18m 24s |
| 3 | 28/28 passed | 18m 57s |

Zero flaky tests detected across all three runs. See
`thoughts/handoffs/phase-9-mobile-e2e/task-09-regression-reliability.md` for
the full bug fix list and per-flow timings.

## Maestro execution-order quirk

`maestro test <dir>` does **not** execute flows alphabetically by filename — it uses
its own ordering. This matters when flows mutate shared DB state. Two patterns work
around this:

1. **Make each flow self-sufficient.** Don't rely on a previous flow having created
   state — call `seed/setup.sh` or run a `seed-*.yaml` helper at the top.
2. **Use deterministic timestamps.** When tests must target a specific row in a list,
   give the seeded data fixed `created_at` / `scheduledStart` offsets so the row
   sorts predictably regardless of execution order.

## CI workflow

| File | Trigger | What it does |
|------|---------|--------------|
| `.github/workflows/ci.yml` | every PR + push to main | Backend lint/build/unit/integration, mobile TS/lint/jest |
| `.github/workflows/e2e-mobile.yml` | push to main, `workflow_dispatch` | Build Android APK → upload to Maestro Cloud → run all 28 flows |

Both workflows use the same `make test-mobile-e2e-cloud` target locally and in CI.

