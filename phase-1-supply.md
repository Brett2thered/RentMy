# Phase 1 — Users + Listings / Supply Side (Wk 3–5)

**Goal:** A host can sign up, create a listing with camera-captured photos, and see it in their profile. No discovery yet — supply before demand.

**Blockers:** Phase 0 complete (DB, S3, project scaffolds)

---

## Tasks

### 1.1 — UserService (backend)
- Registration endpoint (email/phone + password or magic link)
- Auth: JWT issuance + refresh tokens
- Profile CRUD: name, avatar, notification preferences
- Identity status field (`VERIFIED | PENDING | REJECTED`) — not wired to KYC yet, defaults to `PENDING`
- Reputation score field initialized at 0 (no reputation — earned over time)
- Device fingerprint capture on registration
- **Done when:** Register, login, get profile, update profile all work via API. JWT auth middleware rejects unauthorized requests

### 1.2 — MediaService (backend)
- Upload endpoint: accepts image bytes, stores original in S3
- Thumbnail generation on upload (sharp or libvips via cgo, or a sidecar)
- Metadata extraction: timestamp, GPS (from EXIF if present), device ID
- Orientation metadata storage: roll, pitch, yaw from device gyroscope (sent by client alongside image bytes)
- Serve endpoint: returns thumbnail URL (signed or public)
- **Done when:** Upload a photo with orientation metadata, get back a thumbnail URL, original preserved in S3

### 1.3 — ListingService (backend)
- Create listing endpoint: title, description, price (hourly/daily), min/max duration, location (GeoPoint), availability windows
- **7-day max duration ceiling enforced at creation** (Stripe hold expiry — PRD §7)
- Attach media to listing (references MediaService uploads)
- Status management: `ACTIVE | PENDING | FLAGGED | SUSPENDED`
- AI fields stubbed: `aiGeneratedTags`, `estimatedValue`, `hostDeclaredValue` — populated manually for now, AI fills these in Phase 4
- Get listing by ID, get listings by host ID
- **Done when:** Create a listing with 3+ photos, retrieve it with media URLs, update it, list all listings for a host. Duration > 7 days rejected

### 1.4 — Auth screens (RN)
- Sign up screen (email/phone + password)
- Login screen
- Secure token storage (expo-secure-store or Keychain)
- Auth state management (context or Zustand)
- **Done when:** User can register, login, and stay logged in across app restarts

### 1.5 — Listing creation flow (RN)
- FAB button → "List Item" entry point
- Camera capture screen (in-app only, no gallery picker)
- 3–5 photo capture with preview
- **Angle diversity enforcement:** after first capture, circular indicator on viewfinder shows rotation delta from all previous shots. Soft-blocks shutter if < 30° rotation from any existing photo (indicator turns green when sufficient rotation reached). Reads device gyroscope/accelerometer in real time. Stores orientation metadata (roll, pitch, yaw) per photo
- Proof frame overlay (hand-in-shot guide or verification code)
- Manual form: title, description, price, duration, availability
- Location picker (map pin drop)
- Submit → calls ListingService API
- **Done when:** Host can capture photos from enforced different angles, fill form, submit listing, see it in their profile. Shutter blocks same-angle captures

### 1.6 — Profile screen (RN)
- Display user info, avatar
- "My Listings" tab showing host's listings
- Listing detail view (own listings)
- **Done when:** Host sees their listings after creation

---

## Exit Criteria

Host can sign up, capture angle-enforced photos, create listing, see it in profile. Phase 2 is unblocked.
