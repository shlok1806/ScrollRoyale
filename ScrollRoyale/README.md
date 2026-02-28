# Scroll Royale

1v1 competitive doomscrolling — two players face off scrolling through MP4 content.

## Setup

### 1. Open in Xcode (fastest path)

After cloning, open:

- `ScrollRoyale/ScrollRoyale.xcodeproj`

Then choose a simulator and run.

### 2. (Optional) Regenerate project with XcodeGen

If you don't have [XcodeGen](https://github.com/yonaskolb/XcodeGen) yet, install it via Homebrew:

```bash
# Install Homebrew first if needed: https://brew.sh
brew install xcodegen
```

If you want to regenerate the project from `project.yml`:

```bash
cd ScrollRoyale
xcodegen generate
```

This rewrites `ScrollRoyale.xcodeproj`.

## Project Structure

- **Models** — Match, ContentItem, GameState
- **Views** — LobbyView, GameView, VideoFeedView, VideoCellView
- **ViewModels** — LobbyViewModel, GameViewModel
- **Services** — MatchmakingService, SyncService, ContentService (mock + Supabase implementations)
- **Components** — VideoPlayerView (AVPlayer wrapper)
- **Supabase SQL** — `supabase/sql/001_schema.sql`, `002_rls.sql`, `003_functions.sql`
- **Architecture Docs** — `docs/realtime-protocol.md`, `docs/scoring-pipeline.md`, `docs/implementation-milestones.md`

## Supabase Setup

1. Apply SQL files in order from `supabase/sql`.
2. Add values to `ScrollRoyale/Info.plist`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Upload your MP4s and make sure reel `storage_path` values point to playable URLs/signed URLs.

## Current Status

- App architecture is wired for Supabase-backed matchmaking, feed fetching, telemetry ingestion, and score snapshots.
- If Supabase keys are missing, the app safely falls back to mock services for local development.
