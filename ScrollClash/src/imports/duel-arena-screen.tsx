Refinement pass focused ONLY on the Duel Arena screen.

Do not redesign other screens.

This task is to properly structure and visually implement the Duel Arena gameplay screen with scrollable vertical video functionality and HUD overlay.

This must match the existing purple arena game vibe of the app.

STRUCTURE REQUIREMENTS

Create a full iPhone Duel Arena screen with:

Vertical scrollable feed of full-screen videos

Placeholder MP4 containers (use generic thumbnails labeled "VIDEO 1", "VIDEO 2", etc.)

Each video occupies full viewport height

Smooth vertical swipe behavior

Snap-to-video behavior (like reels / shorts)

The feed must:

Auto-advance at 10 seconds (label this visually but do not explain backend)

Feel like a vertical battle arena

Do NOT add heavy scrolling UI outside the videos.

TOP HUD – SCORE BAR

At the very top overlay:

Create a large competitive score bar.

Structure:

Top Left:

Player avatar (brain mascot mini version)

Rank badge

Top Right:

Opponent avatar

Rank badge

Center:

90-second match timer in circular glowing ring

Countdown animation

Under the timer:

Score comparison bar (tower HP vs tower HP)

Left side (You) in purple

Right side (Opponent) in neon green

HP displayed numerically under each side (e.g. 870 / 1000)

When damage happens:

Subtle flash on affected side

Small floating damage numbers appear near tower indicator

No emojis.

Use stylized custom icons.

VIDEO AREA

Each video page must include subtle HUD overlays:

Top-left corner of video:

Combo meter (5 glowing pips)

Multiplier text (e.g. x1.2)

Bottom-left:

Focus meter displayed as 10 small glowing orbs

Orbs fill as focus increases

Right side vertical stack:

Reaction button (glows active only after 2 seconds)

Quiz indicator (small icon if current video is quiz-enabled)

Discovery progress indicator (3 small nodes that fill)

Visual style:

Dark gradient overlay at top and bottom for readability

Maintain patterned purple arena background subtly behind UI areas

BANKED DAMAGE VISUALIZATION

While on a video:

Display a small horizontal meter labeled:
“Banked Damage”

Threshold markers at:

2s

5s

7s

As time crosses thresholds:

Marker glows

Banked damage number increases (10 → 30 → 50)

When player leaves video:

Banked damage locks

Multiplier applies

Projectile animation travels to opponent HP bar

HP reduces

This must feel responsive and satisfying.

BOOST DECK UI

At bottom of screen:

Add a horizontal row of 4 equipped boost cards.

Each card shows:

Custom card art

Boost name

Focus cost (with icon)

Cooldown indicator

Playable state (bright vs dimmed if insufficient Focus)

When tapped:

Card pulses

Glow effect

Small floating text shows boost name activation

Cards should feel like Clash Royale cards:

Slight depth

Border glow

Rarity outline

No emojis.

VISUAL STYLE REQUIREMENTS

Use purple patterned arena background

Subtle lighting gradient

Soft glow accents

Slight depth to panels

Animated micro-interactions

Do NOT flatten design.

Do NOT make it look minimal SaaS.

Maintain competitive energy.

PLACEHOLDER VIDEO INSTRUCTIONS

For each video page:

Show a placeholder block labeled:
“MP4 PLACEHOLDER – VIDEO 1”
“MP4 PLACEHOLDER – VIDEO 2”
etc.

Use a neutral thumbnail background for now.

No real media required.

ANIMATION NOTES

Add interaction annotations:

Swipe snap animation between videos

Combo pip fill animation

Focus orb fill animation

Damage projectile animation

Banked damage increment animation

Boost card cooldown overlay animation

IMPORTANT

Do NOT redesign other screens.

Only create or refine Duel Arena screen.

Keep consistent typography, color system, and design language from existing game UI.