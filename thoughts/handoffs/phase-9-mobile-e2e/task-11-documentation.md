# Task 9.11 — Documentation & CLAUDE.md update

**Status: COMPLETED**
**Branch:** `task-9.11-docs` (git fallback — Graphite not installed)

---

## What changed

| File | Change |
|------|--------|
| `mobile/e2e/README.md` | Refreshed: removed stale `E2E_MODE` instructions, added seed-script step, added Maestro Cloud section, fixed directory listing (no `fixtures/`, has `seed/`), updated debugging table, updated pass-rate to actual 18min durations from task 9.9, added Maestro execution-order note |
| `README.md` (root) | Updated roadmap (phases 0–9 all Complete), added E2E rows to test hierarchy table, added `test-mobile-e2e-cloud` to test commands, expanded CI/CD section with the new `e2e-mobile.yml` workflow |
| `CLAUDE.md` | Updated current-state line (phases 0-9 complete), added `test-mobile-e2e-cloud` quick-start command, added new "Mobile: E2E Tests (Maestro)" section with conventions (testID naming, SafeAreaView pitfall, no E2E_MODE, seeding, execution order, cloud usage), expanded "What Done Means" with E2E suite as BLOCKING + Maestro Cloud preservation |

---

## Stale content removed

The previous `mobile/e2e/README.md` predated several phase-9 implementation
choices. Specifically purged:

1. `EXPO_PUBLIC_E2E_MODE=true` build flag references — never existed
   in the actual codebase (no grep hits in backend/ or mobile/)
2. `E2E_MODE=true make dev` — backend doesn't read this env var; payment
   stub auto-activates from `STRIPE_SECRET_KEY=sk_test_placeholder`
3. `POST /api/v1/test/booking` endpoint — replaced by
   `mobile/e2e/seed/setup.sh` (real API + raw SQL) in task 9.5
4. `mobile/e2e/fixtures/` directory — does not exist
5. ~12 min suite duration figure — actual is ~18min (from task 9.9 runs)

The root README's roadmap was the most stale — it showed Phase 5 as
"Next" and didn't mention phases 8 or 9.

---

## Stale phase-status fields in progress.json (left alone)

Phases 2, 3, 4, 6, 7 still have `phase.status: "pending"` despite all
tasks within them being completed. The task-level data is correct
(used by the workflow). Fixing these phase-level fields is out of
scope for a documentation task and would risk introducing drift if
the schema is consumed elsewhere.

---

## Verification

```
$ test -f mobile/e2e/README.md && echo PASS
PASS

$ grep -c "test-mobile-e2e-cloud" mobile/e2e/README.md README.md CLAUDE.md
mobile/e2e/README.md:3
README.md:1
CLAUDE.md:3

$ grep -n "E2E_MODE" mobile/e2e/README.md
39:sheet on mobile. There is no `E2E_MODE` env var.    # explicit disclaimer, kept on purpose

$ make -n test-mobile-e2e          # unchanged from before
$ make test-mobile-e2e-cloud       # preflight still gates correctly
ERROR: MAESTRO_CLOUD_API_KEY is not set. ...
```

---

## Push status

Will attempt `git push -u origin task-9.11-docs` after commit. Per
CLAUDE.md push policy: best-effort, no workarounds if it fails.

---

## What this completes

Task 9.11 is the last pending task in the project. With this commit
all 12 phase-9 tasks are completed, and per `.claude/progress.json`
(post-update) every task in every phase has `status: "completed"`.
The repo's documentation now reflects the as-shipped state.
