# ScrollClash — iOS Porting Inventory

Generated from web app analysis. All items below must be reproduced in the native iOS target at `/ios-native/ScrollClash`.

---

## 1. Routes → Screens

| Web Route | Web Component | iOS File | Notes |
|---|---|---|---|
| `/` | `Login.tsx` | `Features/Auth/Views/LoginView.swift` | Google Sign-In → mock tap-to-continue |
| `/loading` | `Loading.tsx` | `Features/Auth/Views/LoadingView.swift` | 3-second animated loading, cycling tips |
| `/home` | `HomeScreen.tsx` | `Features/Home/Views/HomeView.swift` | Brain mascot, rot ring, battle panel, 7-day chart |
| `/leaderboard` | `LeaderboardScreen.tsx` | `Features/Leaderboard/Views/LeaderboardView.swift` | Global/Friends toggle, podium, scrollable rows |
| `/graveyard` | `Graveyard.tsx` | `Features/Graveyard/Views/GraveyardView.swift` | Healthy/Graveyard scene toggle, day cards, modal |
| `/profile` | `Profile.tsx` | `Features/Profile/Views/ProfileView.swift` | Stats, badges carousel, brain skins grid |
| `/duel` | `PreDuel.tsx` | `Features/Duel/Views/PreDuelView.swift` | Host-code Quick Match flow + Join-by-code flow, both Supabase-backed |
| `/duel/arena` | `DuelArena.tsx` | `Features/Duel/Views/DuelArenaView.swift` | 90s timer, HP bars, combo/focus meters, boosts |
| `/duel/result` | `DuelResult.tsx` | `Features/Duel/Views/DuelResultView.swift` | Victory/Defeat, stats, timeline, rewards |
| `/brain-lab` | `BrainLab.tsx` | `Features/BrainLab/Views/BrainLabView.swift` | 6-category customizer, live preview, save/equip |
| `/boosts` | `BoostInventory.tsx` | `Features/Boosts/Views/BoostInventoryView.swift` | Card grid, filter tabs, detail modal |

---

## 2. Components → SwiftUI Views

### Shared / App-level

| Web Component | iOS File | Notes |
|---|---|---|
| `BrainCharacter.tsx` | `Shared/Components/BrainCharacterView.swift` | SVG brain → Path-drawn SwiftUI canvas with skin/expression/hat/glasses/accessories |
| `ProgressRing.tsx` | `Shared/Components/ProgressRingView.swift` | Circular progress ring (rot level indicator) |
| `GameIcons.tsx` | `Shared/Components/GameIcons.swift` | 20+ icon views: TrophyIcon, FlameIcon, CrownIcon, SwordsIcon, etc. |
| `Root.tsx` TabBar | `App/MainTabView.swift` | 5-tab bottom nav: Home, Leaderboard, Duel (center CTA), Graveyard, Profile |
| `BrainCustomizationContext` | `App/AppState.swift` | `@StateObject` / `ObservableObject` replacing Context API |

### Feature-specific

| Web Component | iOS File | Notes |
|---|---|---|
| `PodiumCard` (Leaderboard) | `Features/Leaderboard/Views/PodiumCardView.swift` | Inline in LeaderboardView |
| `LeaderboardRow` | `Features/Leaderboard/Views/LeaderboardRowView.swift` | Inline in LeaderboardView |
| `HealthyForestScene` | `Features/Graveyard/Views/HealthyForestSceneView.swift` | Animated forest with SVG trees/grass/mushrooms |
| `GraveyardScene` | `Features/Graveyard/Views/GraveyardSceneView.swift` | Night sky, stars, gravestones |
| `DailyReportModal` | `Features/Graveyard/Views/DailyReportModal.swift` | Sheet presentation |
| `ItemCard` (BrainLab) | `Features/BrainLab/Views/ItemCardView.swift` | Grid item for customization selector |
| `BoostCard` | `Features/Boosts/Views/BoostCardView.swift` | Trading card with rarity glow, stats |
| `BoostCardMini` (DuelArena) | `Features/Duel/Views/BoostCardMiniView.swift` | Compact in-duel deck card |
| `VideoPlaceholder` (DuelArena) | `Features/Duel/Views/VideoPlaceholderView.swift` | Uses `VideoPlayer` (`AVPlayer`) when reel URL resolves, otherwise fallback placeholder |
| `ConfettiEffect` (DuelResult) | `Features/Duel/Views/ConfettiView.swift` | 80-particle confetti for victory |
| `AnimatedNumber` (DuelResult) | `Shared/Components/AnimatedNumberView.swift` | Counting number animation |

---

## 3. APIs / Data

The web app has **no real backend**. iOS is still mock-first but now supports optional matchmaking API wiring.

| Data | Web Source | iOS Equivalent |
|---|---|---|
| Leaderboard (10 players) | `LeaderboardScreen.tsx` array | `Models/MockData.swift` `leaderboardData` |
| Graveyard (6 days) | `Graveyard.tsx` array | `Models/MockData.swift` `graveyardData` |
| Boost catalog (14 boosts) | `features/boosts/types.ts` `BOOSTS` | `Models/Boost.swift` + `MockData.swift` |
| User profile (hardcoded stats) | Multiple screens | `Models/MockData.swift` `currentUser` |
| Brain customization | `BrainCustomizationContext` | `App/AppState.swift` `BrainCustomization` |
| Duel opponent | `PreDuel.tsx`, `DuelArena.tsx` | `PreDuelView.swift` uses `AppState.matchmakingService` with mock fallback |
| Matchmaking API | N/A (web mock) | `App/AppState.swift` `SupabaseMatchmakingService` + `SupabaseAuthService` + `SupabaseClient` using RPCs: `create_match_with_code`, `join_match_by_code`, `get_match`, `leave_match`, `ensure_user_profile` (mock fallback retained) |
| Feed API | N/A (web mock) | `App/AppState.swift` RPC `fetch_match_feed` mapped to `MatchFeedItem[]` with read retries (empty-state fallback only) |
| Score API | N/A (web mock) | `App/AppState.swift` RPC `latest_score_snapshot` mapped to `ScoreSnapshot`, polled by `DuelArenaView` |
| Telemetry API | N/A (web mock) | `App/AppState.swift` RPC `ingest_telemetry_batch`; `DuelArenaView` queues and flushes events every ~400ms |
| Leaderboard API | N/A (web mock) | `App/AppState.swift` RPC `get_global_leaderboard`; consumed by `LeaderboardView` with fallback |
| Profile summary API | N/A (web mock) | `App/AppState.swift` RPC `get_profile_summary`; consumed by `ProfileView` with fallback |
| Authentication | Mock (navigate on tap) | Mock (tap to proceed) |

---

## 4. Assets

| Web Asset | iOS Equivalent | Notes |
|---|---|---|
| `d15f16af...png` (striped bg) | Stripe pattern drawn in SwiftUI | TODO: Could be added to `Assets.xcassets` if file available |
| `c4c1b03a...png` (graveyard bg) | SVG-drawn graveyard scene in SwiftUI | Not imported — recreated as SwiftUI canvas |
| Custom SVG icons (GameIcons.tsx) | SwiftUI `Path`/`Shape` views | All 20+ icons replicated |
| Brain character SVG | SwiftUI Canvas paths | Skin colors, expressions, hats, glasses all implemented |

---

## 5. Design Tokens

| Token | Web Value | iOS Equivalent |
|---|---|---|
| `--neon-bg-start` | `#07070B` | `Theme.bgStart` = `Color(hex: "07070B")` |
| `--neon-bg-end` | `#0A0A12` | `Theme.bgEnd` |
| `--neon-purple` | `#7C3AED` | `Theme.purple` |
| `--neon-purple-light` | `#8B5CF6` | `Theme.purpleLight` |
| `--neon-green` | `#39FF14` | `Theme.neonGreen` |
| `--neon-cyan` | `#22D3EE` | `Theme.cyan` |
| `--neon-magenta` | `#FF3D81` | `Theme.magenta` |
| `--neon-text` | `#F2F3F7` | `Theme.text` |
| `--neon-text-muted` | `#A7AAB5` | `Theme.textMuted` |
| Accent colors used per-screen | Various | Defined in `Shared/Theme/Theme.swift` |

---

## 6. Navigation Structure

```
App
├── LoginView  (not in tab bar)
│   └── LoadingView  (navigates to MainTabView)
└── MainTabView  (TabView)
    ├── HomeView
    ├── LeaderboardView
    ├── PreDuelView  (center tab CTA + matchmaking API call)
    │   └── DuelArenaView (uses matched opponent from PreDuelView)
    │       └── DuelResultView
    ├── GraveyardView
    └── ProfileView
        └── BrainLabView (presented as full-screen cover)
            (also navigable from HomeView → BoostInventoryView)
```

---

## 7. State Management

| Web State | iOS Equivalent |
|---|---|
| `BrainCustomizationContext` | `@StateObject AppState` shared via `.environmentObject()` |
| Screen-local `useState` | `@State` within each View |
| Timers (`setInterval`, `setTimeout`) | `Timer.publish` / `Task` + `try await Task.sleep` |
| Navigation (`useNavigate`) | `NavigationStack` path + `@State` navigation triggers |

---

## 8. Supabase Runtime Config (iOS)

Generated Info.plist keys are configured in Xcode build settings (`project.pbxproj`):

- `SUPABASE_URL` = `REPLACE_WITH_SUPABASE_URL`
- `SUPABASE_ANON_KEY` = `REPLACE_WITH_SUPABASE_ANON_KEY` (must be replaced locally)

Matchmaking will auto-select:

- Supabase mode when both keys are valid
- Mock mode when key is missing/placeholder
