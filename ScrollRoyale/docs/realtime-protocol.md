# Scroll Royale Realtime Protocol

This protocol defines channels and payloads for Supabase Realtime.

## Channels

- `match:<match_id>:lobby`
  - Presence and ready-state events.
- `match:<match_id>:gameplay`
  - Telemetry batch ingest acknowledgements and score updates.
- `match:<match_id>:system`
  - Countdown, match start/end, and integrity alerts.

## Event Envelope

All client-originated events use this envelope:

```json
{
  "event_id": "uuid",
  "match_id": "uuid",
  "user_id": "uuid",
  "sent_at": "2026-02-28T15:00:00Z",
  "type": "lobby.ready_set",
  "payload": {}
}
```

## Lobby Events

- `lobby.joined`
  - Payload: `{ "slot": 1 | 2, "display_name": "..." }`
- `lobby.code_created`
  - Payload: `{ "match_code": "A7K2P9" }`
- `lobby.join_by_code`
  - Payload: `{ "match_code": "A7K2P9" }`
- `lobby.countdown`
  - Payload: `{ "seconds_remaining": 3 }`
- `lobby.match_started`
  - Payload: `{ "started_at": "ISO8601", "duration_sec": 90, "match_code": "A7K2P9" }`

## Gameplay Events

- `game.telemetry_batch`
  - Payload:
    ```json
    {
      "batch_id": "uuid",
      "events": [
        {
          "client_event_id": "uuid",
          "event_type": "scroll|like|view_start|view_end",
          "occurred_at": "ISO8601",
          "reel_id": "uuid",
          "payload": { "velocity": 1.2, "dwell_ms": 530 }
        }
      ]
    }
    ```
- `game.telemetry_ack`
  - Payload: `{ "batch_id": "uuid", "accepted_count": 8 }`
- `game.score_snapshot`
  - Payload:
    ```json
    {
      "snapshot_at": "ISO8601",
      "players": [
        { "user_id": "uuid", "score": 31.2, "metrics": { "likes": 3 } }
      ]
    }
    ```
- `game.integrity_warning`
  - Payload: `{ "code": "clock_skew|rate_limit", "detail": "..." }`

## Match End Events

- `system.match_finalizing`
  - Payload: `{ "reason": "timer_elapsed" }`
- `system.match_final`
  - Payload:
    ```json
    {
      "winner_user_id": "uuid",
      "ended_at": "ISO8601",
      "scores": [
        { "user_id": "uuid", "score": 63.4 }
      ]
    }
    ```

## Reliability Rules

- Clients send telemetry in 200-500ms batches.
- Every batch has a unique `batch_id` for idempotent retries.
- Server remains authoritative for score and winner.
- If realtime disconnects, client falls back to REST polling for score snapshots.
