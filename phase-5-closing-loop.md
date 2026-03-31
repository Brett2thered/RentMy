# Phase 5 — Returns, Disputes, Trust (Wk 11–14)

**Goal:** The loop closes. Returns are verified, damage is detected, disputes resolve, reputation scores update, payouts land. The platform can run.

**Blockers:** All core services + AI agents (Phases 1–4)

---

## Tasks

### 5.1 — Photo diff pipeline (backend)
- **Stage 1 — CV preprocessing (no LLM):**
  - Normalization: resize to standard resolution, OpenCV histogram equalization for lighting/white-balance
  - Object isolation: SAM 2 (or equivalent segmentation model) to isolate item from background. Output: cropped item on transparent background
  - Angle matching: pair check-in and return photos by closest gyroscope orientation match
- **Stage 2 — LLM reasoning (Claude via model router):**
  - Structural comparison on preprocessed, paired item crops
  - Damage classification: `NO_CHANGE | COSMETIC_DAMAGE | FUNCTIONAL_DAMAGE | MISSING_ITEM | INCONCLUSIVE`
  - Confidence scoring (0–1.0)
- Photo quality gate: blur detection, minimum resolution, item-in-frame check, angle diversity enforcement (≥30° gyroscope delta between shots — soft-block shutter if too close to existing angle, green indicator when rotation sufficient)
- Store results on Transaction: `photoDiffResult`, `photoDiffConfidence`
- **Done when:** CV preprocessing produces clean paired item crops. LLM classifies damage with confidence scores. Quality gate rejects blurry/off-target/same-angle photos. Pipeline cost is ~60% lower than full-LLM approach

### 5.2 — DisputeAgent with escalation gate (backend)
- Implement per PRD §20:
  - Evidence gathering: agreement snapshot (primary reference), photos, messages, proximity proofs, transaction data
  - Photo diff pipeline integration
  - Decision + confidence score
  - **Escalation gate routing:**
    - ≥0.85 confidence AND ≤$200 → auto-resolve
    - ≥0.85 confidence AND $201–$1,000 → auto-resolve, flag for async audit
    - ≥0.85 confidence AND >$1,000 → human review queue
    - <0.85 confidence (any amount) → human review queue
    - INCONCLUSIVE photo diff → human review queue
    - Active fraud flags → human review queue
  - Execute via HoldAllocation ledger: read `remaining` before any capture, atomic capture operations
  - If damage exceeds hold remaining: capture full remaining + charge card for difference + guarantee fund covers shortfall
- **INCONCLUSIVE handling:** prompt both parties for additional photos (2-hour window), re-run diff, escalate if still inconclusive
- Human review queue: internal API for ops team to approve/override/request evidence
- `HUMAN_OVERRIDE` AgentDecision records with `overrideOf` linking
- SLA enforcement via River jobs: alert if approaching SLA deadline
- **Done when:** Dispute filed → evidence gathered → agreement referenced → decision made → routed through gate → executed via hold allocation or queued. Escalation thresholds work. Human override records link correctly

### 5.3 — LateReturnAgent (backend)
- River job scheduled at `scheduledEnd` for every active rental
- On fire: check if rental is still `ACTIVE`
- Auto-charging via HoldAllocation ledger: continue at hourly rate (minimum), double rate if conflict with next booking
- **Late fee capture cap:** cannot capture more than `holdAmount * (1 - damageReserveRate)` (default 60% of hold). The remaining 40% is protected as damage reserve for potential damage claims on return
- Escalation decision (per PRD §19): evaluate duration overdue, renter responsiveness, reputation score, item value, time of day
- If escalated: DisputeAgent takes over, remaining hold captured, host notified
- Extreme cases: flag for review, provide host with law enforcement guidance
- **Done when:** Rental expires → LateReturnAgent charges late fees via hold allocation → damage reserve preserved → escalates if renter unresponsive

### 5.4 — Rating system (backend + RN)
- Post-rental rating prompt (both parties)
- Structured bubbles per PRD §15 (no freeform)
- Ratings stored, feed into reputation score calculation
- Rating display on user profiles and listing pages
- **Done when:** Both parties rate after rental. Bubbles display on profiles. Ratings contribute to reputation score

### 5.5 — Reputation score recalculation
- On every completed transaction: recalculate both parties' reputation scores (per PRD §8)
- Positive signals add reputation (completed rental, bubbles, on-time, milestones)
- Negative signals subtract reputation (disputes, cancellations, late returns, fraud flags)
- Milestone bonuses (5+, 15+, 50+ rentals; account age thresholds)
- Negative signal decay at 180 days
- Host-specific signals recalculated monthly (response rate, acceptance rate, cancellation history)
- **Done when:** Reputation scores build from 0 with good behavior, decrease with bad behavior, and old negatives decay. Milestones fire at correct thresholds. Users with 5 vs 50 clean rentals have meaningfully different scores

### 5.6 — Guarantee fund accounting
- `GuaranteeFundEntry` ledger table: contributions (% of each platform fee), claims (damage payouts exceeding hold), card recoveries, collections referrals
- Double-entry tracking: every entry records `balanceAfter` for running balance
- On claim: debit guarantee fund, attempt to charge renter's card for difference, record card recovery or collections referral
- **Reserve ratio enforcement per PRD §7:** fund must maintain balance ≥ 15% of total outstanding guarantee gaps. OpsAgent alerts at 15%, restricts high-value at 10%, restricts all gap bookings at 5%
- **Loss ratio tracking:** rolling 90-day `totalClaims / totalContributions`. Target < 0.6. OpsAgent alerts if trending above for 30+ days
- **Done when:** Fund balance tracks correctly with double-entry ledger. Claims debit fund. Card recovery attempts logged. Reserve ratio monitored. Loss ratio tracked. Alerts fire at thresholds

### 5.7 — Outcome linking (Agent Learning Framework §31)
- River job: `link_outcome` fires 48h after every transaction close
- For each AgentDecision on the transaction: evaluate outcome correctness per agent-specific rules (PRD §31 outcome table)
- Set `outcomeId` and `outcomeCorrect` on each AgentDecision
- Update rolling confidence calibration metrics per agent (expected vs actual accuracy per confidence bucket)
- Store calibration data for OpsAgent dashboard
- **Done when:** Completed transactions trigger outcome linking. AgentDecisions get `outcomeCorrect` flags. Confidence calibration metrics update. Data is available for quarterly prompt evolution

### 5.8 — Post-rental flow (RN)
- Return confirmation screen
- Rating prompt (bubble selection)
- Dispute filing screen (if issue reported)
- Dispute status tracking screen
- Hold release confirmation / damage charge notification
- **Done when:** Full post-rental UX: return → rate → hold released (or dispute filed → tracked → resolved)

---

## Exit Criteria

CV+LLM photo diff detects damage, disputes resolve via hold allocation with damage reserve, reputation scores update, guarantee fund tracks reserve ratio, outcome linking feeds learning framework. Phase 6 is unblocked.
