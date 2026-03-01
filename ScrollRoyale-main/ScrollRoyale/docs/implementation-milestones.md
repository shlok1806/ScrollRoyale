# Implementation Milestones

## Phase 1 - Supabase Foundation

Deliverables:
- Apply SQL migrations:
  - `supabase/sql/001_schema.sql`
  - `supabase/sql/002_rls.sql`
  - `supabase/sql/003_functions.sql`
- Create storage bucket and upload MP4 reels.
- Configure app `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

Validation:
- Can create/read users and reels with RLS constraints.
- Can run `create_match` and `join_match` RPCs from Supabase console.

## Phase 2 - Matchmaking and Lobby

Deliverables:
- `SupabaseMatchmakingService` used by app.
- Duration picker supports 90/180/300 seconds.
- Ready flow starts match and materializes deterministic feed.

Validation:
- Two users can join same lobby and reach `in_progress`.
- Match row contains `started_at` and `duration_sec`.

## Phase 3 - Feed + Telemetry Ingestion

Deliverables:
- `SupabaseContentService` fetches `match_feed_items`.
- `GameViewModel` batches telemetry every 400ms.
- Ingestion through `ingest_telemetry_batch`.

Validation:
- Telemetry rows appear in `telemetry_events`.
- Duplicate `client_event_id` batches do not double count.

## Phase 4 - Live Score Updates

Deliverables:
- Snapshot computation via `compute_score_snapshot`.
- iOS listens for score updates (poll fallback already wired).

Validation:
- `score_snapshots` updates every 1-2s during active match.
- UI score changes over time while scrolling/liking.

## Phase 5 - Finalization and Winner

Deliverables:
- Scheduler or edge trigger calls `finalize_match`.
- Winner persisted in `matches.winner_user_id`.
- `match_summaries` written for replay/analytics.

Validation:
- Match ends exactly at duration.
- Winner and summary are immutable after finalization.

## Phase 6 - Hardening

Deliverables:
- Realtime websocket channel implementation (replace polling fallback).
- Clock skew checks, rate limit checks, retry strategy.
- Add observability dashboard and retention policy.

Validation:
- Reconnects do not lose match state.
- End-to-end tests pass for all durations.
