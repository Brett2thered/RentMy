# Phase 0 — Foundation (Wk 1–2)

**Goal:** Every service has a place to live, a database to talk to, and a job queue to schedule work. Nothing else starts until this is solid.

**Blockers:** None — this is the starting line.

---

## Tasks

### 0.1 — Go project scaffold
- Init modular monolith repo structure: `/cmd/server`, `/internal/{service}/`, `/internal/{agent}/`, `/pkg/`
- Shared packages: `pkg/ulid`, `pkg/errors`, `pkg/config`, `pkg/middleware`
- HTTP router setup (chi or stdlib mux)
- Config management (env-based, 12-factor)
- Makefile: `build`, `test`, `migrate`, `dev`
- **Done when:** `make dev` starts a server that responds 200 on `/health`

### 0.2 — PostgreSQL + PostGIS
- Docker Compose for local dev (Postgres 16 + PostGIS 3.4)
- Migration tooling (golang-migrate or goose)
- Initial migration: `users`, `listings`, `transactions`, `messages`, `ratings`, `proximity_proofs`, `agent_decisions`, `guarantee_fund_entries`, `hold_allocations` tables per data model (PRD §6)
- PostGIS extension enabled, GeoPoint columns indexed
- **Done when:** All tables exist, `SELECT PostGIS_Version()` returns, migrations run idempotently

### 0.3 — Redis
- Redis 7 in Docker Compose
- Go Redis client (`go-redis/redis`)
- Connection pooling, health check on `/health`
- **Done when:** SET/GET works from Go, health check passes

### 0.4 — River (durable job queue)
- Install River (Go-native Postgres-backed queue)
- Job table migration
- Worker scaffold with graceful shutdown
- Test job: enqueue → process → complete
- **Done when:** A test job enqueues, executes, and logs completion. Worker survives `SIGTERM` without dropping jobs

### 0.5 — S3-compatible object storage
- MinIO in Docker Compose for local dev
- Go S3 client (aws-sdk-go-v2)
- Bucket creation: `media-originals`, `media-thumbnails`
- Upload/download helper functions
- **Done when:** Upload a test file, retrieve it, delete it

### 0.6 — Pusher (SSE)
- Pusher account + channel setup (or Soketi for local dev)
- Go Pusher client
- Test: trigger event from Go, receive in browser console
- **Done when:** Event fires from backend, lands in a browser tab

### 0.7 — React Native project scaffold
- Init RN project (Expo or bare)
- Navigation structure (React Navigation): auth stack, main tab bar (feed, search, map, messages, profile)
- Shared UI primitives: Button, Input, Card, Avatar, Badge
- API client scaffold (axios/fetch wrapper with auth headers)
- **Done when:** App boots on iOS simulator with tab navigation, all tabs render placeholder screens

---

## Exit Criteria

Server boots, DB migrated, S3/Redis/River/Pusher connected, RN app navigates. Phase 1 is unblocked.
