# Phase 2 — Discovery + Payments / Demand Side (Wk 5–8)

**Goal:** A renter can find listings nearby and pay for them. The checkout screen shows the tiered hold amount clearly.

**Blockers:** UserService, ListingService, MediaService (Phase 1)

---

## Tasks

### 2.1 — DiscoveryService (backend)
- **Feed endpoint:** "Available near you" — query PostGIS for listings within radius, ranked by availability + distance
- **Search endpoint:** Keyword search against `title`, `description`, `aiGeneratedTags` (fulltext search via Postgres `tsvector` for v1, semantic search in Phase 4)
- **Map endpoint:** Return listings with fuzzed locations (exact stored, ~500m jitter shown) within bounding box
- Drive-time estimation: integrate routing API (OSRM self-hosted or Google/Mapbox API)
- **Ranking algorithm v1 (all inputs normalized to [0,1] per PRD §13):**
  ```
  score = 0.35 * availabilityNow                                    // binary: 1 or 0
        + 0.30 * (1 - driveTimeMinutes / maxDriveTimeInRadius)       // proximity
        + 0.20 * (hostReputationScore / 1000)                        // reputation
        + 0.15 * ((responseRate + onTimeRate + acceptanceRate) / 3)   // reliability
  ```
  Weights are tunable config vars. Availability and proximity dominate because the product promise is "rent anything nearby, fast."
- **Filtering:** drive time range, price range, rental duration
- **Hide from results:** `PENDING`, `FLAGGED`, `SUSPENDED` listings; hosts with response rate < 30%
- **Done when:** Feed returns nearby listings sorted by rank. Search returns keyword matches. Map returns listings in bounding box with fuzzed coords. All three endpoints paginate

### 2.2 — PaymentService (backend)
- Stripe Connect integration: host onboarding (Connected Accounts)
- `PaymentAdapter` interface per PRD §7
- **Tiered hold logic:**
  ```
  func tieredHold(itemValue) holdAmount:
    if itemValue <= 500:     return itemValue
    if itemValue <= 2000:    return 500 + (itemValue - 500) * 0.25
    if itemValue <= 5000:    return 875 + (itemValue - 2000) * 0.15
    return 1325  // hard ceiling
  ```
- **HoldAllocation ledger:** on every hold authorization, create a HoldAllocation record tracking `totalAuthorized`, `damageReserve` (40% default), and `remaining`. All subsequent captures (late fees, damage) read and update this ledger atomically (SELECT FOR UPDATE)
- Pre-auth hold: `AuthorizeHold(amount, paymentMethod)`
- Charge rental fee: `ChargeRentalFee(amount, paymentMethod)`
- Escrow tracking: rental fee held until return confirmed
- Release hold: `ReleaseHold(holdID)`
- Capture from hold: `CaptureHold(holdID, amount)` — must check `holdAllocation.remaining` before capture
- Host payout: `PayoutHost(amount, hostAccount)`
- **Guarantee fund ledger:** `GuaranteeFundEntry` records for every contribution (% of platform fee) and claim. Double-entry with `balanceAfter` per entry. Reserve ratio calculation: `fundBalance / totalOutstandingGuaranteeGaps`
- **Payout rules:** new/high-risk hosts → 48h delay, established → same-day, first 3 transactions → 48h mandatory (implemented via River jobs)
- **Done when:** Can authorize a tiered hold with hold allocation ledger, charge a rental fee, release hold, capture from hold (respecting allocation), pay out host. Guarantee fund tracks balance with double-entry ledger and reserve ratio. All via test mode Stripe

### 2.3 — Feed screen (RN)
- "Available near you" scrollable list
- Listing card component: photo, title, price, drive time estimate, trust signals
- Pull-to-refresh, infinite scroll pagination
- **Done when:** Feed loads listings from DiscoveryService, scrolls, refreshes

### 2.4 — Search screen (RN)
- Search bar with keyword input
- Results list (same card component as feed)
- Filter sheet: drive time, price, duration
- **Done when:** Search returns results, filters apply

### 2.5 — Map screen (RN)
- Map view (react-native-maps) centered on user location
- Listing pins with fuzzed locations
- Tap pin → listing card preview
- Tap card → listing detail
- **Done when:** Map shows nearby listings, tap navigates to detail

### 2.6 — Listing detail screen (RN)
- Full photo gallery (swipeable)
- Title, description, host info, trust signals
- Price display (hourly/daily)
- Drive time estimate
- Hold amount display (calculated from tiered logic)
- Availability calendar
- "Rent Now" CTA button
- **Done when:** All listing info displays, hold amount matches tier table

### 2.7 — Checkout screen (RN)
- Rental fee breakdown: `hostPrice * duration`
- Hold amount (tiered, clearly labeled "temporary hold, released on return")
- Total card impact: `rentalFee + holdAmount`
- Duration selector
- Payment method selection (Stripe payment sheet)
- "Confirm Booking" CTA
- KYC gate: if user not verified, trigger KYC flow before booking (stubbed — full KYC in Phase 4)
- **Done when:** Renter can select duration, see total cost, add payment method, confirm booking (booking request created in DB)

---

## Exit Criteria

Renter can search/browse/map (normalized ranking), see tiered hold amount, check out with Stripe. Hold allocation ledger and guarantee fund tracking active. Phase 3 is unblocked.
