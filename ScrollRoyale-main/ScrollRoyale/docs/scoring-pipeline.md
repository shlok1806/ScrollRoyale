# Score Pipeline and Finalization

## Server Authority

- Clients submit raw telemetry only.
- Supabase SQL functions compute and persist rolling scores.
- Final winner is determined only by backend finalization (`finalize_match`).

## Inputs

- Telemetry events: `scroll`, `like`, `view_start`, `view_end`.
- Payload values used in scoring:
  - `velocity`
  - `dwell_ms` (optional, can be added by client)

## Rolling Snapshot Cadence

- Ingestion happens in batches every 200-500ms from iOS.
- Snapshot cadence should run every 1-2s:
  1. call `compute_score_snapshot(match_id)`,
  2. emit latest snapshot via realtime event `game.score_snapshot`.

## Baseline Score Formula (Current SQL)

- `like`: +5
- `view_end`: +2
- `scroll velocity`: bounded contribution rewarding smoother control

The formula is intentionally modular and can be replaced by editing
`supabase/sql/003_functions.sql` (`compute_score_snapshot`).

## End of Match

When timer reaches `duration_sec`:

1. Stop accepting new batches for the match.
2. Compute a final snapshot.
3. Select highest score as winner.
4. Persist:
   - `matches.status = ended`
   - `matches.winner_user_id`
   - `match_summaries.summary` immutable payload
5. Broadcast `system.match_final`.

## Integrity Controls

- Idempotency: `(match_id, user_id, client_event_id)` unique in `telemetry_events`.
- Client writes are append-only.
- RLS prevents a user from writing telemetry into other matches.
- Server may reject out-of-window timestamps and over-rate batches.
