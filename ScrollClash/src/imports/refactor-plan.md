Goal: Refactor file structure only. Keep visuals + logic identical.

PROMPT:

Refactor request: restructure this codebase for scalability without changing UI, styling, or logic.

Hard rules

Do NOT change any component behavior, UI layout, styling, animations, or text.

Do NOT rename exported component names unless strictly necessary for the move.

Do NOT rewrite logic. Only move files, update imports, and adjust routing as needed.

You may only make “route stuff” changes (route file organization, route map, navigation wiring) if required by the refactor.

The app must render identically after refactor.

Current structure (context)

Right now we have folders like:

src/app/components/figma/*

src/app/components/ui/* (shadcn-style primitives)

src/contexts/*

src/screens/* (Home, Leaderboard, Graveyard, DuelArena, DuelResult, BrainLab, Profile)

src/routes.ts

src/Root.tsx, src/App.tsx

Target structure (feature-based)

Restructure into a feature-first architecture:

src/
  app/
    App.tsx
    Root.tsx
    routes/
      index.ts
      routeConfig.ts
    providers/
      AppProviders.tsx
  features/
    home/
      HomeScreen.tsx
      components/
    duel/
      DuelArenaScreen.tsx
      DuelResultScreen.tsx
      components/
      hooks/
    graveyard/
      GraveyardScreen.tsx
      components/
    leaderboard/
      LeaderboardScreen.tsx
      components/
    profile/
      ProfileScreen.tsx
      components/
    brainLab/
      BrainLabScreen.tsx
      components/
      context/ (if customization state is feature-specific)
  shared/
    ui/          (reusable primitives: button, card, dialog, etc.)
    components/  (shared non-primitive components: ProgressRing, RankIcon, TabBar, Toast)
    hooks/
    utils/
    types/
    styles/
      tokens.ts  (colors, spacing, radii, shadows)
      globals.css (if applicable)
  assets/
Move rules

Move each file from src/screens/* into its corresponding features/<feature>/.

Split components into:

shared/ui/ = primitive reusable components (current components/ui/* goes here)

shared/components/ = cross-feature components like TabBar, ProgressRing, RankIcon, Toast, ImageWithFallback

features/<feature>/components/ = components only used by one feature

Routing

Keep navigation behavior identical.

Create src/app/routes/routeConfig.ts that defines route paths + screen components.

Create src/app/routes/index.ts that exports routes.

Update Root.tsx / App.tsx to import routes from the new location.

Ensure the bottom navbar/tabbar still appears on the same screens exactly as before.

Context/state

If a context is app-wide (auth, global user, global toast), move to src/app/providers/ or src/shared/.

If a context is feature-specific (e.g., brain customization), move into that feature (features/brainLab/context/).

Do not change context behavior—only relocate and update imports.

Output required

Perform the refactor by moving files, updating imports, and ensuring everything builds.

Provide a final tree view of the new structure.

Ensure no circular dependencies and no broken imports.

Keep file names stable where possible; only add “Screen” suffix if needed to avoid collisions.

Again: NO UI changes, NO logic changes. Only structure + route wiring + import paths.