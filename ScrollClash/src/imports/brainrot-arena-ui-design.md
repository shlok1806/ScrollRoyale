PROJECT: Brainrot Arena – iOS Competitive Scrolling Game

Scrap all existing layouts and generate a completely new design.

This is NOT a SaaS dashboard.
This is NOT a documentation-style UI.
This is NOT a website.

This is a high-energy iOS mobile game interface.

OVERALL VISION

Design a premium, high-energy competitive mobile game UI inspired by:

Clash Royale (stat hierarchy & energy)

Esports overlays (duel HUD layout)

iOS polish (safe areas, gestures, spacing)

The UI must feel:

Slightly dramatic

Slightly gamified

Eye-catching

Glossy

Glowy

Energetic

But not childish.
Not cartoon overload.
Not messy cyberpunk.

STYLE DIRECTION

Color System:

Deep black background (#050509)

Purple neon gradient accents (#7C3AED / #9333EA)

Neon electric green CTA (#39FF14)

Magenta/pink for penalties (#FF3D81)

Subtle blue/cyan for secondary UI (#22D3EE)

Use glow effects around:

Primary buttons

Active tab

Victory highlights

Progress rings

Use subtle particle effects in backgrounds (very light).

DO NOT:

Create a long scrollable design system page

Create separate “Buttons” or “Cards” documentation sections

Create literal web-style content blocks

Make it minimal SaaS

Make it over-flat

STRUCTURE

Design full iPhone screens with fixed layout (no heavy scrolling except leaderboard).

SCREEN 1 – HOME DASHBOARD

Full iPhone frame.

Top Section:

CENTER:
Large animated “Today’s Brain”

Floating brain on dark platform

Glowing progress ring around it

Shows “Rot Level: 37%”

Ring changes from green → purple → pink-red based on rot

Top Left:
Mini stat pill showing:
“+12 Trophies Today” (small green glow)

Top Right:
Profile avatar circle with neon border

Middle Section:

Primary Card:
“START DUEL” button
Large neon green glowing button
Rounded corners
Subtle animated pulse

Secondary Buttons under it:

Invite Friend

Practice Mode

Below that:
Daily Challenge card (slightly dramatic card style)
Example:
“No Rage Flicks for 60s”
Reward icon on right

NO giant scrolling.
Content must fit comfortably within iPhone viewport.

SCREEN 2 – DUEL MATCHMAKING

Modal bottom sheet style.

Dark background.
Opponent avatar preview.
Animated countdown 3…2…1…
Glow pulse each number.

Energetic but clean.

SCREEN 3 – DUEL ARENA

Full screen vertical video feed (MP4).

Overlay HUD:

Top Left:
Your avatar + rank badge

Top Right:
Opponent avatar + badge

Center Top:
Timer ring counting down
Neon animated

Below timer:
Score comparison bar (left = you, right = opponent)

Bottom:
Swipe Quality Bar
Small micro pop-ups appear:
“+3 Stability”
“-5 Rage Flick”

Slight score animations.
Subtle glitch effect for penalties.

This screen should feel intense and competitive.

SCREEN 4 – DUEL RESULT

Big bold typography:

VICTORY or DEFEAT

Huge trophy gain number (+18)

XP bar animating up

Buttons:
Rematch (primary)
Back to Home (secondary)

Confetti particles for victory.
Subtle cracked glass overlay for defeat.

SCREEN 5 – LEADERBOARD

Minimal scrolling list.

Segmented control at top:
Global | Friends

Top 3 players in elevated glowing cards.

Your rank pinned near top.

Bold numbers.
Clear spacing.
No SaaS-style white table.

SCREEN 6 – BRAIN GRAVEYARD

Grid layout.

Each tile = “Daily Brain”
Shows:
Date
Rot %
Small brain render

More rotten brains look cracked/glitched.

Tap → opens modal with:

Scroll time

Rage bursts

Stability score

Earned badge

Very light fog/particle effect in background.
Not horror themed.

SCREEN 7 – PROFILE

Large avatar
Rank title (e.g., Algorithm Overlord)
Win rate
Trophies

Horizontal badge carousel

Settings button subtle

NAVIGATION

Bottom Tab Bar:

Home
Leaderboard
Center Duel Button (floating neon circular)
Graveyard
Profile

Active tab glows purple.
Center Duel button glows neon green.

Must respect iPhone safe area.
No Android floating styles.

INTERACTIONS & ANIMATIONS

Include animation notes:

Button press scale 0.96

Neon glow pulse idle

Haptic heavy impact for duel start

Score pop-ups fade up 200ms

Progress ring smooth easing

Confetti burst for rewards

IMPORTANT STYLE NOTES

Use depth (soft shadows)

Use gradient backgrounds subtly

Use glowing borders

Emphasize big numbers

Make it feel like a game, not a fintech app

DO NOT CREATE A COMPONENT DOCUMENTATION PAGE

Instead, design screens first.

At the end, create ONE clean reusable component sheet containing:

Primary button

Secondary button

Card container

Progress ring

Rank badge

Toast popup

Tab bar

Keep it concise.

FILE STRUCTURE FOR HANDOFF

Organize Figma pages as:

Screens

Components

Assets

Interaction Flow

Naming must mirror a modular SwiftUI app structure:

Features:

Home

Duel

Leaderboard

Graveyard

Profile

Keep naming consistent for dev handoff.

FINAL DIRECTIVE

The final UI must feel:

Premium
Game-like
Slightly dramatic
Neon-dark
iOS polished
Not SaaS
Not flat minimal
Not cluttered

Focus on energy, hierarchy, and competitive intensity.