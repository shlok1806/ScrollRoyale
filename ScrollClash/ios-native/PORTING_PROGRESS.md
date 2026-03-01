# ScrollClash — iOS Porting Progress

Status key: ✅ Done | 🚧 In Progress | ⬜ Not Started | ⚠️ Partial/TODO

---

## Foundation

- [x] Create `/ios-native` directory
- [x] `PORTING_INVENTORY.md`
- [x] `PORTING_PROGRESS.md`
- [x] Xcode project scaffold (`ScrollClash.xcodeproj`)
- [x] `Theme.swift` — neon design tokens
- [x] `AppState.swift` — `ObservableObject` for brain customization
- [x] `Models/` — data types and mock data

---

## Shared Components

- [x] `BrainCharacterView.swift` — animated SVG brain with skin/expression/hat/glasses/accessories
- [x] `ProgressRingView.swift` — circular rot-level indicator
- [x] `GameIcons.swift` — 20+ custom icon views
- [x] `AnimatedNumberView.swift` — counting animation

---

## Navigation Shell

- [x] `ScrollClashApp.swift` — app entry point
- [x] `MainTabView.swift` — 5-tab bottom nav (Home, Leaderboard, Duel, Graveyard, Profile)

---

## Screens

### Auth Flow
- [x] `LoginView.swift` — hero title, floating brains, "Continue with Google" button (mock)
- [x] `LoadingView.swift` — progress bar, brain parade, cycling tips, 3s auto-nav

### Main Tabs
- [x] `HomeView.swift` — rot ring + brain, battle panel, boost deck row, daily challenge, 7-day chart
- [x] `LeaderboardView.swift` — Global/Friends toggle, your rank card, top-3 podium, scrollable rows 4-10
- [x] `GraveyardView.swift` — Healthy/Graveyard scene toggle, animated scenes, day cards, daily report modal
- [x] `ProfileView.swift` — stats cards, performance panel, badges carousel, brain skins grid

### Duel Flow
- [x] `PreDuelView.swift` — Searching → Found → Countdown phases
- [x] `DuelArenaView.swift` — 90s timer ring, HP bars, combo/focus meters, video placeholder, boost deck, swipe gesture
- [x] `DuelResultView.swift` — Victory/Defeat, VS section, HP bars, match stats, timeline, rewards, confetti
- [x] Matchmaking integration pass — `AppState.matchmakingService` (API-first via `SCROLLCLASH_API_BASE_URL`, mock fallback), opponent threaded PreDuel → Arena → Result
- [x] Supabase contract wiring pass — anonymous auth (`/auth/v1/signup`), profile bootstrap (`ensure_user_profile`), matchmaking RPCs (`create_match_with_code`, `get_match`) with fallback to mock mode
- [x] Full Supabase gameplay data pass — implemented `join_match_by_code`, `leave_match`, `fetch_match_feed`, `ingest_telemetry_batch`, `latest_score_snapshot`, `get_global_leaderboard`, `get_profile_summary` with UI wiring + graceful fallbacks

### Full-screen Overlays
- [x] `BrainLabView.swift` — 6-category tabs, live brain preview, 3-col item grid, save/equip
- [x] `BoostInventoryView.swift` — active deck, filter tabs, 2-col card grid, detail sheet

---

## Build Status

- [x] **Clean build verified** — `xcodebuild` exits 0 with `BUILD SUCCEEDED` (Xcode 15 / iOS Simulator SDK 17.5, Feb 28 2026)
- [x] `skinColor` name collision in `BrainCharacterView.swift` resolved via `ScrollClash.skinColor(for:)` disambiguation
- [x] Duel presentation stack hardened — nested full-screen transitions removed to avoid orientation transaction warnings
- [x] `Info.plist` runtime keys added via build settings (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) for Supabase selection at app startup

---

## Known Limitations / TODOs

| Area | Limitation | Rationale |
|---|---|---|
| Background texture | Striped PNG imported via `figma:asset/` URI not available in iOS. Replaced with diagonal SwiftUI-drawn stripes. | Asset file not extractable from web bundle |
| Google Sign-In | Web app calls `navigate('/loading')` on tap. iOS uses `ASAuthorizationController` for real Google Sign-In; mocked as button tap for now. | TODO: Integrate GoogleSignIn SDK when backend exists |
| Real video feed | DuelArena now uses `AVPlayer`/`VideoPlayer` when `fetch_match_feed` returns resolvable URLs; keeps placeholder fallback when URL is missing/invalid. | Playback quality still depends on valid storage paths and codecs in backend media |
| View Replay button | DuelResult has non-functional "View Replay" button. iOS: same — button present but shows TODO toast. | No replay data source exists |
| DnD boost equip | Equip/Unequip button toggles `equipped` on local copy only (no persistence). Web app same. | TODO: Add persistence (UserDefaults or backend) |
| Matchmaking endpoint contract | iOS now uses Supabase contracts (`/auth/v1/signup`, `/rest/v1/rpc/create_match_with_code`, `/rest/v1/rpc/join_match_by_code`, `/rest/v1/rpc/get_match`, `/rest/v1/rpc/leave_match`, `/rest/v1/rpc/ensure_user_profile`). | Join-by-code UI implemented in PreDuel; match host/join coordination still backend-dependent |
| Gameplay data contracts | `fetch_match_feed`, `ingest_telemetry_batch`, `latest_score_snapshot` integrated and called from Duel Arena. | TODO: map real score/HP formula server-authoritatively instead of local duel simulation |
| Secondary tabs contracts | `get_global_leaderboard`, `get_profile_summary` integrated with fallback behavior if RPCs unavailable. | TODO enforce RPC availability in SQL migrations for production |
| Supabase anon key | Build settings now contain configured anon key and app boots in Supabase mode when URL/key are valid. | TODO: rotate/revoke key immediately if this repository is ever shared publicly |
| Match readiness | Quick Match now creates a host code and waits for a second player via `get_match`; Join Code path uses `join_match_by_code`. | TODO: map richer opponent profile fields (rank/wins/rot) from backend payload instead of placeholder stats |
| Brain customization persistence | Stored in `AppState` (in-memory `@StateObject`). Not persisted across cold launches. | TODO: Serialize to UserDefaults |
| `smirk` expression | Web BrainCharacter supports `smirk`; mapped to `happy` on iOS as closest equivalent. | SVG path not distinct enough to warrant separate implementation |
| `default` skin | Web uses `default` skin ID; iOS maps this to `classic` color. | Synonym |
| Graveyard background PNG | `c4c1b03a...png` asset not available. Replaced with procedural SwiftUI drawing. | Asset file not extractable |
| Motion/Framer animations | Some entrance animations simplified (spring → easeInOut). Complex `AnimatePresence` transitions use SwiftUI `.transition()`. | SwiftUI animation system differs |
