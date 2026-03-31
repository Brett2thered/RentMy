# Phase 4 — AI Agents / Intelligence Layer (Wk 9–12)

**Goal:** AI takes over verification, appraisal, risk scoring, and agreement generation. Listings get smart. Bookings get scored.

**Blockers:** Core transaction loop working (Phase 3). Model router needs to make API calls to Anthropic and cheap model endpoints.

---

## Tasks

### 4.1 — Model router
- Abstraction layer: `func Route(task AgentTask, input JSON) → (response JSON, model string)`
- Task → model mapping config:
  - Cheap model (e.g., Haiku or local): notifications, summaries, simple classification, search matching
  - Claude (Sonnet): disputes, value appraisal, fraud patterns, agreement generation, any decision touching money
- Retry logic, timeout handling, fallback (if Claude unavailable, queue for retry, don't fail silently)
- Cost tracking: log model, tokens, latency per call
- **Prompt version tracking:** every AgentDecision records the prompt version used, enabling per-version performance comparison (see §31)
- **Done when:** Router dispatches to correct model per task type. Cost logging works. Fallback queues work. Prompt versions recorded

### 4.2 — VerificationAgent
- KYC integration: Stripe Identity (or equivalent swappable provider)
- Flow: user submits ID photo + selfie → API validates → agent reviews result → sets `identityStatus`
- Auto-approve if API confidence is high
- Auto-reject if API flags fraud indicators
- Edge cases queued for human review (same escalation pattern as DisputeAgent)
- River job: timeout if verification API hasn't responded in 10 minutes → retry
- **Done when:** User submits ID + selfie, gets verified (or rejected) within 60 seconds. KYC only triggered once per user

### 4.3 — AppraisalAgent
- Input: listing photos (from MediaService)
- Output: item identification, estimated value, suggested pricing (hourly/daily), semantic tags, generated description
- Uses Claude (Sonnet) via model router
- Autofill: on listing creation, agent runs and populates AI fields
- **Value override flow:** if host declares value >100% of AI estimate → agent prompts for justification → evaluates autonomously → approve or reject
- **Done when:** Host captures photos → AI fills in title, description, value estimate, pricing, tags within 5 seconds. Override flow works with justification prompt

### 4.4 — RiskAgent
- **Dual-score implementation per PRD §8:**
  - `reputationScore` (User-level, 0–1000): starts at 0, builds with positive signals, decreases with negative events, negative decay at 180 days
  - `riskScore` (Transaction-level, 0–100): computed fresh per booking from base risk + transaction risk + counterparty risk + behavioral risk + fraud signals
- Reputation recalculated after every completed transaction + monthly for host-specific signals
- Risk score computed at booking time, stored on Transaction
- Controls: 0–30 fast payout, 31–70 standard escrow, 71+ block or require additional verification
- **Done when:** Every booking gets a per-transaction risk score. Reputation scores start at 0 and grow with good behavior. Decay applies to old negative signals. Risk score correctly factors in both parties' reputation

### 4.5 — AgreementAgent
- Base template: lawyer-reviewed, immutable (stored as versioned JSON)
- AI-customized section: item-specific condition notes, exclusions, handling instructions, damage thresholds
- Guardrails: cannot contradict base template, cannot remove liability/arbitration, cannot modify payment terms
- Output: complete agreement JSON snapshot stored immutably per transaction
- Both parties must accept before booking completes
- **Agreement as contract backbone:** the agreement snapshot is the binding reference for all disputes. Custom clauses should anticipate common damage scenarios for the item type (water damage for electronics, cosmetic damage for furniture, missing accessories for camera gear)
- **Done when:** Every booking generates a custom agreement. Agreement snapshot stored. Both parties see and accept before booking confirms

### 4.6 — Wire KYC into booking flow (RN)
- Update checkout: if user not verified, trigger KYC flow (ID capture + selfie) before booking proceeds
- KYC status screen: processing, verified, rejected
- Rejected: show reason, allow retry
- **Done when:** First-time renter hits "Rent Now" → KYC triggers → verified → booking proceeds. Never asked again

### 4.7 — Wire AI autofill into listing creation (RN)
- After photo capture, show loading state → AI fills fields
- All AI-filled fields are editable by host
- Value override: if host changes value >100%, show justification prompt
- **Done when:** Photos captured → fields auto-populate → host can edit and submit

### 4.8 — Backfill existing data
- River job: run AppraisalAgent on all existing listings that have empty `aiGeneratedTags` or `estimatedValue`. Populate AI fields retroactively
- River job: recalculate `reputationScore` for all existing users with transaction history (apply positive/negative signals from their complete history)
- River job: backfill `riskScore` on existing Transactions (re-run risk calculation with current rules for analytics, mark as `backfilled: true` to distinguish from real-time scores)
- **Done when:** All existing listings have AI-generated tags and value estimates. All existing users have accurate reputation scores. Backfilled records are distinguishable from live ones

---

## Exit Criteria

AI fills listings, dual-score system active (reputation 0–1000 + per-transaction risk 0–100), generates agreements, verifies identity. Existing data backfilled. Phase 5 is unblocked.
