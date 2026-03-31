# Phase 6 — Operations + Growth (Wk 13–16)

**Goal:** The team can see what's happening, catch fraud, and start growing. The platform is launch-ready.

**Blockers:** Full transaction lifecycle working (Phases 1–5)

---

## Tasks

### 6.1 — OpsAgent (backend)
- Platform health monitoring: active listings, active users, booking conversion, revenue, fraud rate
- Anomaly detection: fraud spikes, supply drops, booking failure clusters, payout failures
- Host churn signals: declining response rates, listing pauses
- Supply gap analysis by geography
- Agent performance monitoring: confidence score trends, escalation rates
- Alert rules: configurable thresholds, fires notifications to ops team (Slack webhook or push)
- **Done when:** OpsAgent runs on a schedule (River cron job), generates health reports, fires alerts on threshold breaches

### 6.2 — FraudAgent (backend)
- Signal detection per PRD §9: shared device fingerprints, linked payment instruments, carrier batch phone numbers, simultaneous account creation, exclusive transaction pairs
- **WiFi as compound-only signal:** same-network detection is recorded but only contributes to risk score when combined with at least one other fraud signal
- **Behavioral velocity:** enforcement rules already active in BookingService middleware (Phase 3). FraudAgent adds pattern analysis on top: exclusive transaction pairs, damage claims at exactly hold amount, items damaged every rental, high-value listing spikes from new accounts
- Flag accounts, alert OpsAgent
- **Done when:** FraudAgent runs per-transaction and on schedule. Collusion patterns detected and flagged. WiFi signal only fires in combination

### 6.3 — Ops dashboard (web)
- Simple React web app (separate from RN app) — internal only
- Real-time metrics per PRD §25: business, trust & safety, supply health, demand health
- Human review queue UI: pending disputes, evidence viewer, approve/override/request-more controls
- Agent decision log viewer: filter by type, confidence, escalation status
- **Agent learning dashboard (§31):** per-agent confidence calibration charts (expected vs actual accuracy per bucket), outcome correctness rates, override rates, loss ratio trend, guarantee fund health
- Alert feed: recent OpsAgent alerts
- **Done when:** Ops team can view platform health, process review queue, see agent decisions, and monitor agent learning metrics in real time

### 6.4 — Referral system (backend + RN)
- Host-refers-host: referral code generation, tracking, payout ($20 each on first completed rental)
- Fraud prevention: shared device detection, same network detection, velocity limits on payouts, referral abuse flagging
- RN: share sheet with referral link, referral status screen
- Renter referrals: stubbed for future activation
- **Done when:** Host can generate referral link, referred host signs up and completes rental, both get $20 payout. Fraud signals block abuse

---

## Exit Criteria

Ops team has dashboard with agent calibration metrics, fraud detection active (WiFi compound-only), referrals work, alerts fire. Platform is launch-ready.
