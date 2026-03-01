Design a mobile iOS app UI called “Brainrot Arena” (competitive scrolling game). The visual style is dark, neon, high-contrast, inspired by modern mobile esports UI (think Clash-style polish but more minimal and premium). The UI should feel addictive, punchy, and responsive, with micro-animations, haptics, and reward feedback on key interactions.

1) Design Goals

Dopamine-inducing but clean: no clutter, no chaotic rainbow. Use a limited palette with glow accents.

Fast readability: big numbers, clear ranking, obvious CTA.

Gamified progression: trophies, badges, XP bars, streaks, “brain rot” progression.

SwiftUI-ready: Components should map cleanly to SwiftUI views, with consistent spacing and reusable components.

Hackathon MVP-friendly: Only requires MP4 feed for the duel arena.

2) Visual Style & Tokens
Color Palette (Dark Neon)

Background: near-black gradient (#07070B → #0A0A12)

Primary Purple: electric violet (#7C3AED / #8B5CF6)

Neon Green Accent: toxic neon (#39FF14)

Secondary Accent: cyber cyan (#22D3EE) used sparingly

Warning/Decay: hot magenta-red (#FF3D81) for “rot” alerts

Text: off-white (#F2F3F7), muted gray (#A7AAB5)

Glow effects: use outer glow on neon accents (subtle, not overpowering)

Typography

Use a bold geometric sans (SF Pro Display vibe).

Titles: 28–34px, heavy

Primary stat numbers: 40–56px (leaderboard ranks, trophies)

Buttons: 16–18px, semibold

Labels: 12–14px, medium

Layout & Spacing

8pt grid system

Card radius: 18–24

Buttons: 56px height primary CTA, 48px secondary

Always keep one dominant CTA per screen

3) App Navigation (Bottom Tab Bar)

Create a 5-item bottom tab bar with a center floating action button.

Tabs (left to right):

Home (dashboard)

Leaderboard

Duel (center floating primary action)

Graveyard (Brain Graveyard)

Profile

Tab bar style:

Matte black translucent

Subtle purple top border line

Active icon glows (purple/green)

Center Duel button is a floating circular neon button (green + purple gradient), with pulsing idle animation.

4) Key Screens to Design (Provide each as separate Figma frames)
A) Onboarding (3 screens)

Onboarding Screen 1: “Welcome to Brainrot Arena”

Full-screen background gradient with animated floating particles

Center: mascot brain icon (cute but slightly cursed)

Copy: “Turn scrolling into a sport.”

CTA: “Continue”

Secondary: “Skip”

Onboarding Screen 2: “How Duels Work”

A short animated infographic:

“Swipe → score”

“Stability + timing beats spam flicking”

Show a tiny duel HUD preview at top

Onboarding Screen 3: “Choose Your Vibe”

Select one of 3 starter brain skins (cosmetic)

CTA: “Enter Arena”

Animations:

Screen transitions: smooth push + fade

Brain icon floats gently (y-axis sine)

CTA button press: scale down 0.96 + haptic

B) Home Dashboard (Main Screen)

Top area:

Center: “Today’s Brain” (large, prominent)

A 3D-ish brain in a glass jar or floating platform

Under it: “Rot Level: 37%” with a progress ring

Progress ring changes color from green → purple → pink-red as rot increases

A small “streak flame” indicator (e.g., “Streak: 4 days”)

Top left:

Tiny “Daily Trophy Change” widget: +12 / -8 (mini stat)
Top right:

Profile avatar circle with glow; tap opens Profile

Main content cards (scrollable):

Quick Duel card (dominant)

Big button: “Start 1-Minute Duel”

Secondary: “Invite Friend”

Daily Challenge card

Example: “No Rage Flicks for 60s”

Reward: XP + badge icon

Rot Trend mini chart (7-day sparkline)

Rewards / Loot card

Shows “Badge unlocked!” with animated confetti on unlock

Interactions:

Tapping Today’s Brain opens a modal “Rot Breakdown”

Quick Duel button triggers Matchmaking modal

Daily Challenge completes triggers pop-up reward

C) Duel Matchmaking (Modal + Flow)

When user taps Duel:
Open a bottom sheet modal:

Title: “Find Opponent”

Options:

“Random Match” (big CTA)

“Challenge Friend” (secondary)

“Practice (Offline)” (small)

Add a countdown animation when match found:

“Opponent Found!”

Show opponent avatar + name + rank badge

“3…2…1…” large numbers with screen pulse + haptic each tick

D) Duel Arena (The Core Gameplay UI)

Full-screen vertical feed (MP4).
Layout:

Background: the video feed itself (full screen).

Overlay HUD (top):

Left: Your avatar + name + rank icon

Right: Opponent avatar + name + rank icon

Center: timer (60s) with a neon ring shrinking

Under timer: score comparison bar (you vs them)

Overlay bottom:

“Swipe Quality Meter” (thin bar) showing stability vs spam

Micro badges appearing: “STABLE +3”, “RAGE FLICK -5”

Add a live “brain decay” mini icon in the top center near the timer:

It visibly corrupts during duel if user spam-flicks.

End of duel:

Freeze frame overlay

Show “VICTORY” or “DEFEAT”

Trophy gain/loss big number (+18)

XP progress bar with level-up animation

Buttons: “Rematch”, “Share Result”, “Back to Home”

Animations:

Score increases: number tick-up + neon burst

Penalties: red/pink shake + glitch flash (brief)

Victory: confetti + glow expansion

Defeat: subtle desaturate + cracked glass overlay

E) Leaderboard Screen

Top:

Segmented control: “Friends” | “Global” | “Nearby”

Your rank card pinned near top: “You: #12, 1,204 trophies”
List:

Rows have avatar, name, trophy count, tiny badge icons

Top 3 have special podium cards
Interaction:

Tap a user opens “Player Card” modal:

stats, badges, last 7 days rot, duel history

F) Brain Graveyard Screen (Critical)

This is a collectible gallery of daily brains.
Layout:

Dark cemetery theme but neon-polite (not horror).

Grid of “Graves” each with a brain relic.

Each day tile shows:

date

rot %

small brain render (more rotten = more cracks/ooze)

Top: “Graveyard Streak: 4 days” and “Worst day: 89%”

Tap a grave → opens “Daily Brain Report” modal:

Time spent scrolling (total)

Rage flick bursts count

Stability score

Peak rot time

Earned badge that day

Animations:

Subtle fog particle layer

Hover/tap: grave glows purple, brain rises slightly

G) Profile Screen

Top:

Avatar large with neon frame

Username, rank title (e.g., “Algorithm Overlord”)

Trophy count, win rate, streak
Middle:

Badges carousel (scroll horizontally)

Brain skins collection
Settings:

Sound, haptics toggles

Privacy: allow friend duels / share stats

Account

5) Reusable Components (Design as a Component Library Page)

Create a “UI Kit” frame containing:

Primary CTA button (neon green glow)

Secondary button (purple outline)

Card containers (3 variants: normal, highlighted, danger)

Badge pill components

Rank emblem component

Trophy counter component

Progress ring component

Modal sheets (bottom sheet, center modal)

Toast notifications (“+3 Stable”, “-5 Rage Flick”)

Tab bar component with center FAB

6) Microinteractions & Feedback (Callouts)

Add explicit notes on frames for:

Haptic: selection on tab switches, impact on score events, heavy impact on victory

Glow pulse on CTA idle

Confetti burst when badge earned

“Glitch flash” on rage flick detection

Smooth 250–400ms easing animations, spring on button presses

7) Swift / SwiftUI Implementation Notes (for developer handoff)

Design should be implementable in SwiftUI using:

TabView for navigation

Custom center floating action button overlay

sheet and presentationDetents for modals/bottom sheets

Video feed view is a vertically paged container (one MP4 per page)

HUD overlays are separate ZStack layers

Deliver frames with constraints-friendly layouts and consistent naming.

8) Suggested iOS Project File Structure (Clear & Modular)

Provide a handoff-ready structure with these groupings:

App/

BrainrotArenaApp.swift

RootView.swift (Tab container + center FAB)

DesignSystem/

Colors.swift, Typography.swift, Spacing.swift

Components/ (Buttons, Cards, Badges, Rings, Toasts)

Features/

Home/ (HomeView, RotBreakdownModal)

Duel/ (MatchmakingSheet, DuelArenaView, DuelResultView)

Leaderboard/ (LeaderboardView, PlayerCardModal)

Graveyard/ (GraveyardView, DailyReportModal)

Profile/ (ProfileView, SettingsView)

Models/

User.swift, Duel.swift, BrainDay.swift, Badge.swift

Services/

VideoFeedService.swift (local MP4 list)

GameScoringService.swift (swipe metrics scoring)

Assets/

Videos/ (mp4 placeholders)

Icons/, BrainSkins/

Use consistent view naming that mirrors Figma frames.

9) Deliverables Required

High-fidelity mockups for all screens above

A UI kit / component library page

Prototype interactions wired:

Home → Duel modal → Duel countdown → Duel arena → Duel result

Home → Today’s Brain modal

Tab switching

Graveyard → Daily report modal

Leaderboard → Player card modal

Provide annotations for animations and haptics