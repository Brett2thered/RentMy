# Phase 3 — Core Transaction Loop (Wk 7–10)

**Goal:** A renter can book, pick up, use, and return an item. The full handoff ceremony works. This is the minimum viable transaction.

**Blockers:** DiscoveryService, PaymentService (Phase 2)

---

## Tasks

### 3.1 — BookingService (backend)
- Create booking request: `REQUESTED` status, links renter + host + listing
- Host accept/decline endpoints
- **Complete state machine:** enforce all valid transitions per PRD §17 — `REQUESTED → ACCEPTED/DECLINED/AUTO_DECLINED/CANCELLED`, `ACCEPTED → ACTIVE/CANCELLED`, `ACTIVE → COMPLETED/DISPUTED`, `DISPUTED → COMPLETED`. Reject all invalid transitions at the service layer
- **Auto-decline timer:** River job scheduled on booking creation, fires after configurable timeout (default: 2 hours). If host hasn't responded → status = `AUTO_DECLINED`, renter notified
- Duration management: `scheduledStart`, `scheduledEnd`, `actualStart`, `actualEnd`
- **7-day rental ceiling enforcement:** reject any booking where duration exceeds 7 days (Stripe hold expiry limit)
- Cancel endpoint with fee calculation per cancellation policy (PRD §18)
- On accept: trigger PaymentService to authorize hold + charge rental fee
- **Fraud velocity middleware (from §9, moved here from Phase 6):** before booking confirmation, enforce: new-to-new 30-day lockout (both users < 30 days old), first-3-transaction 48h payout delay, per-account damage claim cap within first 60 days. These are rule checks on BookingService, not agent intelligence
- **Done when:** Full booking lifecycle works with complete state machine. Invalid transitions rejected. Auto-decline fires on timeout. Cancellation charges correct fees. 7-day ceiling enforced. Fraud velocity rules block violating bookings

### 3.2 — ProximityService (backend)
- PIN generation: 4-digit code, generated when host accepts booking, valid for 1 hour
- GPS verification endpoint: accepts lat/lng from both parties, calculates distance, returns verified/not (threshold: ≤100m)
- `ProximityProof` record creation with GPS distance, PIN, method, device ID
- **Check-in flow:** Both parties must: verify GPS proximity + enter correct PIN + submit check-in photos → rental status changes to `ACTIVE`, `actualStart` set
- **Check-out flow:** Both parties must: verify GPS proximity + submit return photos → rental status changes to `COMPLETED`, `actualEnd` set
- **Hard rule enforcement:** Rental cannot start without proximity proof + check-in photos from BOTH parties. Rental cannot close without proximity proof + return photos from BOTH parties
- SMS fallback: if app unreachable, PIN exchanged via SMS (Twilio integration)
- **Done when:** Full handoff ceremony works: GPS verified, PIN accepted, photos captured, rental starts/ends. SMS fallback delivers PIN

### 3.3 — NotificationService (backend)
- Push notification integration (Expo push or FCM/APNs)
- Notification types per PRD §16 table (booking request, accepted, auto-declined, cancellation, pickup approaching, etc.)
- In-app notification storage (Postgres) + read/unread state
- User notification preferences: per-type toggle, quiet hours
- **Booking notifications cannot be disabled** (safety requirement)
- River jobs for scheduled notifications (pickup approaching, return approaching)
- **Done when:** Push notifications fire for all booking lifecycle events. Quiet hours respected. Preferences toggle works

### 3.4 — MessagingService (backend)
- Create message endpoint (scoped to transaction — messages only between booking parties)
- Get messages by transaction ID (paginated, chronological)
- Real-time: Pusher event on new message
- Messages stored in Postgres, queryable by DisputeAgent (Phase 5)
- **Done when:** Renter and host can exchange messages within a booking. Messages persist and trigger push notifications

### 3.5 — Booking flow (RN)
- Booking request confirmation screen
- Host: incoming booking request notification → accept/decline screen
- Auto-decline countdown visible to host
- Booking status screen: shows current state, next steps
- **Done when:** Host receives request, can accept/decline, renter sees status updates in real time

### 3.6 — Handoff screens (RN)
- Navigate to pickup (deep link to Maps app with host's exact location — revealed only after booking accepted)
- Check-in screen: GPS status indicator, PIN entry, camera capture (check-in photos) with angle diversity enforcement (same gyroscope UI as listing capture — ≥30° between shots, green indicator, soft-block)
- Active rental screen: timer showing time remaining, return countdown
- Check-out screen: GPS status indicator, camera capture (return photos) with same angle enforcement
- Rental complete confirmation
- **Done when:** Full handoff UX works end to end on both renter and host devices. Photo capture enforces angle diversity at both check-in and check-out

### 3.7 — Messaging screen (RN)
- Chat UI (FlatList, message bubbles, input bar)
- Real-time message updates via Pusher
- Push notification tap → opens conversation
- **Done when:** Renter and host can chat in real time within a booking

---

## Exit Criteria

Full loop: book → handoff → return. Complete state machine enforced. Fraud velocity rules block bad bookings. 7-day ceiling enforced. Angle-enforced photos at check-in/check-out. Phase 4 is unblocked.
