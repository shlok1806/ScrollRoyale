# HackIllinois: Scroll Royale

# HackIllinois: Scroll Royale

**Demo video:**  
[![Scroll Royale Demo](https://img.youtube.com/vi/240xIn0RHH4/maxresdefault.jpg)](https://youtu.be/240xIn0RHH4)


`Scroll Royale` is a 1v1 competitive doomscrolling game prototype built primarily as a native iOS app with a Supabase backend.

This repository currently contains:
- `ScrollRoyale/` -> the native SwiftUI iOS app + Supabase SQL backend contracts
- `ScrollClash/` -> a React/Figma-style frontend reference used for design direction

---

## Project Overview

Two players join the same match, scroll through the same reel feed, and compete on engagement/telemetry-driven score updates in near real time.

Core experience:
- Create or join a match from the lobby
- Play through a vertically scrolling short-video feed
- Send gameplay telemetry to Supabase
- Poll live score snapshots and show winner state

---

## Tech Stack

- **Client (primary):** SwiftUI, Combine, AVKit
- **Backend:** Supabase (Postgres + RPC functions + Auth + Storage)
- **Build tooling:** Xcode, XcodeGen
- **Reference frontend:** React + Vite + Capacitor (in `ScrollClash/`)

---

## Repository Layout

```text
HackIllinois/
  README.md
  ScrollRoyale/
    project.yml
    ScrollRoyale.xcodeproj/
    ScrollRoyale/
      Components/
      DesignSystem/
      Models/
      Services/
        Cache/
      ViewModels/
      Views/
    supabase/sql/
    docs/
  ScrollClash/
    src/
    ios/
    package.json
```

---

## ScrollRoyale (Native App)

### Key app layers

- **Views** (`ScrollRoyale/ScrollRoyale/Views`)  
  Lobby, gameplay, video cells/feed, leaderboard/profile UI.

- **ViewModels** (`ScrollRoyale/ScrollRoyale/ViewModels`)  
  Match flow, content loading, telemetry batching, and UI state.

- **Services** (`ScrollRoyale/ScrollRoyale/Services`)  
  Supabase-backed matchmaking, auth, content, sync, leaderboard/profile services.

- **Cache layer** (`ScrollRoyale/ScrollRoyale/Services/Cache`)  
  TTL-based in-memory cache plus optional persisted feed snapshots for low-latency UX.

- **Design system** (`ScrollRoyale/ScrollRoyale/DesignSystem`)  
  Shared visual primitives and styles for consistent arcade UI.

### Supabase contracts

SQL files live in `ScrollRoyale/supabase/sql/` and define schema, RLS, and RPC functions:
- `001_schema.sql`
- `002_rls.sql`
- `003_functions.sql`
- `004_match_code_backfill.sql`
- `005_normalize_reel_storage_paths.sql`

---

## ScrollClash (React Reference)

`ScrollClash/` is used as a design/spec reference for visual direction and UX patterns.  
The production gameplay pipeline is currently implemented in native SwiftUI (`ScrollRoyale/`).

---

## Getting Started

### 1) Prerequisites

- Xcode 15+
- iOS Simulator runtime
- (Optional) XcodeGen (`brew install xcodegen`)
- Supabase project with anon key and URL

### 2) Open and run

```bash
cd ScrollRoyale
open ScrollRoyale.xcodeproj
```

Or regenerate project first:

```bash
cd ScrollRoyale
xcodegen generate
open ScrollRoyale.xcodeproj
```

### 3) Configure Supabase

Set in `ScrollRoyale/ScrollRoyale/Info.plist`:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Apply SQL migrations in order from `ScrollRoyale/supabase/sql/`.

Upload reel videos to Supabase Storage and ensure `reels.storage_path` values are valid (URL or `bucket/path`).

---

## Runtime Flow (High Level)

1. User authenticates (anonymous bootstrap + token refresh handling)
2. Lobby creates/joins a match
3. Feed loads via `fetch_match_feed`
4. Video URLs resolve (signed or public fallback)
5. Gameplay telemetry is ingested in batches
6. Score snapshots are polled and rendered live

---

## Low-Latency + Cache Strategy

Recent updates introduced automatic cache and resilience behavior:

- **Auth:** proactive foreground refresh + transient retry before full re-auth
- **Feed:** stale-while-revalidate + in-flight request deduplication
- **Score:** cached warm-start + adaptive polling + overlap coalescing
- **Client:** centralized read retry/backoff + request duration instrumentation

Primary tuning knobs:
- `feedTTL`, `scoreTTL`, `resolvedURLTTL` in `SupabaseCachePolicy`
- warm-up/steady polling in `SupabaseSyncService.connect`

---

## Build / Validation Commands

```bash
cd ScrollRoyale
xcodegen generate
xcodebuild -project "ScrollRoyale.xcodeproj" -scheme "ScrollRoyale" -sdk iphonesimulator -configuration Debug build
```

---

## Troubleshooting

- **JWT expired**  
  Ensure anonymous auth provider is enabled in Supabase and confirm app keys in `Info.plist` are correct.

- **No videos shown**  
  Verify `fetch_match_feed` returns rows for your match and `storage_path` values resolve to playable objects.

- **Simulator build issues after environment resets**  
  Re-run `xcodegen generate`, clean DerivedData, and retry build.

---

## Notes

- If Supabase config is missing, the app falls back to mock services for local UI development.
- `ScrollRoyale/README.md` contains app-specific implementation notes and cache tuning thresholds.
