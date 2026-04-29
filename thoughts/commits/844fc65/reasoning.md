# Commit 844fc65 — Refresh E2E + project docs to as-shipped state (task 9.11)

## Context

Task 9.11 of phase 9, the final task in the project. Goal per the
phase-9 plan: write `mobile/e2e/README.md` (install, run, add tests,
debug failures), update root `README.md`, update `CLAUDE.md`.

All three files already existed but were stale to varying degrees.
The only verification gate was `test -f mobile/e2e/README.md`, which
passed trivially before any edits — so the real work was making sure
the docs actually match shipped code.

## What was stale and how I caught it

Audited each doc against current code (grep for `E2E_MODE`,
`EXPO_PUBLIC_E2E_MODE`, ls of `mobile/e2e/`, inspection of
`backend/internal/payment/stub.go`). Found:

1. `EXPO_PUBLIC_E2E_MODE=true` build flag — does not exist anywhere
   in backend/ or mobile/. The README was telling users to set a
   variable that has no effect.
2. `E2E_MODE=true make dev` — backend doesn't read this. Payment
   stub auto-activates from `STRIPE_SECRET_KEY=sk_test_placeholder`.
3. `POST /api/v1/test/booking` endpoint — replaced by
   `mobile/e2e/seed/setup.sh` (real API + raw SQL) in task 9.5.
4. `mobile/e2e/fixtures/` directory — does not exist on disk.
5. `~12 min` suite duration figure — actual is ~18min per the
   3-run validation in task 9.9.
6. Root README roadmap showed Phase 5 as "Next" — heavily stale,
   missed phases 6, 7, 8, 9 entirely.

## What I added

- Maestro Cloud section in `mobile/e2e/README.md` with preflight-gate
  table mirroring the Makefile's behaviour
- Maestro execution-order quirk note (the gotcha from task 9.6)
- New "Mobile: E2E Tests (Maestro)" section in CLAUDE.md covering
  testID naming, SafeAreaView pitfall (RN 0.81.5 ScrollView bug),
  no-E2E_MODE clarification, seeding, execution order, build-time
  vs run-time `EXPO_PUBLIC_API_URL` gotcha
- Cloud workflow row in root README's CI/CD section

## What I deliberately did NOT do

- Did not rename or reorganize sections. CLAUDE.md guidance says keep
  doc diffs small; targeted edits over rewrites.
- Did not fix the stale `phase.status: "pending"` fields in
  `progress.json` for phases 2/3/4/6/7. Task-level statuses are correct
  and that's what the workflow consumes. Touching the phase-level
  field risks introducing drift if anything else reads it.
- Did not add an iOS section to the cloud workflow. Out of scope —
  9.10 deliberately deferred iOS pending Apple Dev credentials.

## Verification

`test -f mobile/e2e/README.md` ✓. Grep checks confirm
`test-mobile-e2e-cloud` referenced in all three docs (3, 1, 3 hits).
Local `make -n test-mobile-e2e` unchanged. `make test-mobile-e2e-cloud`
still gates correctly on missing env.
