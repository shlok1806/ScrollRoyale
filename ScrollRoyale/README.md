# Scroll Royale 🧠⚡

> **1v1 competitive doomscrolling — scroll faster, engage harder, rot your opponent's brain.**

---

## The Problem

Short-form video is engineered to be addictive. But what if that compulsion became a sport? Most social apps reward passive scrolling. We wanted to flip that — make engagement competitive, visible, and absurd in the best way.

---

## What We Built

**Scroll Royale** is a real-time 1v1 iOS game where two players scroll through the same video feed simultaneously and compete on engagement score. Your swipes, watch time, and reactions generate telemetry that feeds into a live scoring engine. The player with the higher score when the clock hits zero wins.

Built native in SwiftUI with a Supabase backend for matchmaking, telemetry ingestion, and score snapshots.

---

## Key Features

### ✅ Implemented (Demo-ready)
- **Lobby / Matchmaking** — Create a match with a shareable 6-character code; opponent joins on second device
- **Live Duel Arena** — Vertically scrollable video feed with real MP4s from Supabase Storage; swipe to advance reels
- **Real-time Score HUD** — Live score polling, HP bars, timer ring, combo multiplier, focus meter
- **Boost Deck** — 4 boost cards (Shield, Double, Freeze, Rage) with focus cost + cooldown system
- **Telemetry Pipeline** — Scroll events batched and sent to Supabase every 400ms
- **Leaderboard** — Global leaderboard pulled from Supabase RPC
- **Profile** — Player summary stats (matches, wins, best score) from Supabase
- **Demo Reel Mode** — One-tap access to reel scrolling screen with real videos (no match needed)
- **Mock fallback** — All features work offline with mock data if Supabase is not configured

### 🔜 Planned Next
- Authoritative server-side score formula (currently local simulation)
- Real opponent profile resolution in match HUD (rank, wins, rot level)
- Push notifications when opponent joins
- Persistent brain customization (UserDefaults / backend sync)
- Tournament bracket mode

---

## Demo Flow (for judges)

Run the app on **two simulators** (or one simulator + one device) and follow this path:

| Step | Device A | Device B |
|------|----------|----------|
| 1 | Launch app → tap ⚡ to enter matchmaking | Launch app → tap ⚡ |
| 2 | Tap **QUICK MATCH** → tap **GENERATE MATCH CODE** | Tap **JOIN CODE** |
| 3 | Share the 6-character code shown on screen | Enter the code → tap **JOIN MATCH** |
| 4 | Both devices advance to **OPPONENT FOUND** → tap **READY!** | Same |
| 5 | Duel Arena launches — swipe up/down to scroll reels | Same |
| 6 | Watch live score and HP bars update in real time | Same |
| 7 | Match ends at timer zero (or tap FORFEIT) → Result screen | Same |

**Quick single-device demo:** From matchmaking, tap **OPEN DEMO REEL MATCH** to jump straight into the reel scrolling screen with live videos loaded from Supabase.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | SwiftUI (iOS 16+), AVKit, Combine |
| Backend | Supabase (Postgres + RPC functions + Auth + Storage) |
| Matchmaking | Supabase RPCs: `create_match_with_code`, `join_match_by_code`, `get_match` |
| Video | Supabase Storage (`reels` bucket), signed + public URLs |
| Telemetry | `ingest_telemetry_batch` RPC, 400ms flush loop |
| Score | `latest_score_snapshot` RPC, 1s polling |
| Auth | Supabase anonymous auth (auto-bootstrap on launch) |
| Project gen | XcodeGen (`project.yml`) |
| Reference UI | React + Vite + Tailwind (`ScrollClash/` folder — design reference only) |

---

## How to Run

### Prerequisites

- Xcode 15+ with iOS 16+ simulator runtime installed
- (Optional) [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you want to regenerate the project

### 1. Clone the repo

```bash
git clone https://github.com/shlok1806/ScrollRoyale.git
cd ScrollRoyale
```

### 2. Open in Xcode

```bash
open ScrollRoyale/ScrollRoyale.xcodeproj
```

> **Note:** If `.xcodeproj` is missing or stale, regenerate it first:
> ```bash
> cd ScrollRoyale
> brew install xcodegen   # if not installed
> xcodegen generate
> open ScrollRoyale.xcodeproj
> ```

### 3. Configure Supabase keys (already set for this project)

`ScrollRoyale/Info.plist` already contains the project's `SUPABASE_URL` and `SUPABASE_ANON_KEY`.  
If you fork or want to use your own Supabase project, update those two keys in `Info.plist`.

### 4. Run the app

- In Xcode, choose **iPhone 16 Pro** (or any iOS 16+ simulator) from the device picker
- Press **Cmd + R** to build and run
- If you get a stale build error: **Cmd + Shift + K** (Clean Build Folder), then **Cmd + R** again

### 5. Two-device / two-simulator demo

Open a second simulator via **Xcode → Open Developer Tool → Simulator**, launch the same app, and follow the Demo Flow above.  
Both simulators share the same Supabase backend so matchmaking works cross-instance.

---

## Repository Layout

```
ScrollRoyale/
├── ScrollRoyale/
│   ├── ScrollRoyaleApp.swift       # App entry point
│   ├── ContentView.swift           # Root tab view
│   ├── Info.plist                  # Supabase config keys
│   ├── Views/
│   │   ├── LobbyView.swift         # Matchmaking UI
│   │   ├── GameView.swift          # Duel arena (live gameplay)
│   │   ├── VideoFeedView.swift     # Scrollable reel feed
│   │   ├── VideoCellView.swift     # Single reel player
│   │   ├── LeaderboardView.swift   # Global leaderboard
│   │   └── ProfileView.swift       # Player profile
│   ├── ViewModels/
│   │   ├── LobbyViewModel.swift    # Match create/join state
│   │   └── GameViewModel.swift     # Gameplay state + telemetry
│   ├── Services/
│   │   ├── MatchmakingService.swift
│   │   ├── ContentService.swift    # Feed fetching + cache
│   │   ├── SyncService.swift       # Score polling
│   │   ├── SupabaseAuthService.swift
│   │   ├── SupabaseClient.swift    # RPC + Storage client
│   │   ├── LeaderboardService.swift
│   │   └── ProfileService.swift
│   ├── Models/                     # Match, Reel, Player, Score types
│   ├── DesignSystem/               # Colors, typography, components
│   ├── Components/                 # VideoPlayerView (AVPlayer)
│   └── supabase/sql/               # 5 SQL migration files
├── docs/
│   ├── realtime-protocol.md
│   ├── scoring-pipeline.md
│   └── implementation-milestones.md
├── project.yml                     # XcodeGen spec
└── ScrollClash/                    # React/Vite design reference (not shipped)
```

---

## Challenges We Faced

- **Supabase RPC schema cache** — PostgREST caches function signatures; any schema change required `NOTIFY pgrst, 'reload schema'` to take effect, which caused "function not found" errors during live development
- **iOS nested fullScreenCover** — SwiftUI's orientation transaction system throws warnings with nested `fullScreenCover` presentations; we replaced them with `ZStack` overlays and custom transitions
- **Decode mismatches** — Supabase RPCs sometimes return an array, sometimes a single object; built `OneOrMany<T>` generic decoder to handle both shapes transparently
- **`p_reel_set_id: null` encoding** — Swift's default `Encodable` omits `nil` optionals, but Supabase's PostgREST uses parameter presence to disambiguate overloaded function signatures; had to implement custom `encode(to:)` to always emit explicit `null`
- **Anonymous auth in demo mode** — Demo reel browsing should work without any auth; decoupled the `select` REST client to accept optional Bearer token so public bucket reads work with anon key only

---

## What's Next

- **Server-authoritative scoring** — Move HP/damage formula from client simulation to Supabase RPC
- **Real opponent profile** — Resolve rank, wins, rot level from match payload
- **Spectator mode** — Watch live matches in read-only feed
- **Content moderation hooks** — Flag reels for review from within the game
- **Tournament brackets** — Automated bracket generation with match scheduling
- **Streak + badge system** — Daily engagement rewards tied to rot level

---

## AI Disclosure

We used AI coding assistants (Cursor / Claude) during this hackathon to:

- Accelerate SwiftUI boilerplate and layout iteration
- Debug Supabase RPC integration issues and JSON decode mismatches
- Generate test scaffolding and error-handling patterns

**The product concept, game mechanics design, UX decisions, and backend schema were entirely our own work.** AI was a productivity tool, not a replacement for engineering judgment — every AI suggestion was reviewed, tested, and often significantly modified before being accepted.

---

## Team

- **Pranay Karpuram** — iOS + product
- **Shlok** — Backend + Supabase schema

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Supabase is not configured in this build` when generating match code | Clean Build Folder (`Cmd+Shift+K`) and rebuild (`Cmd+R`) |
| `No such module` or missing framework errors | Close Xcode, run `xcodegen generate` from `ScrollRoyale/`, reopen |
| Videos show placeholder instead of real reels | Check that `reels` Supabase Storage bucket is public **or** RLS policy allows anon reads |
| Match code generates but opponent join fails | Run `NOTIFY pgrst, 'reload schema';` in Supabase SQL Editor to refresh RPC cache |
| Two simulators can't reach each other | Both simulators use the same shared Supabase project — verify both are using the same `SUPABASE_URL` in `Info.plist` |

---

*Built at HackIllinois 2026*
