-- Row-level security policies for Scroll Royale.
-- Keep score computation and match finalization server-authoritative.

alter table public.users enable row level security;
alter table public.reels enable row level security;
alter table public.reel_sets enable row level security;
alter table public.reel_set_items enable row level security;
alter table public.matches enable row level security;
alter table public.match_players enable row level security;
alter table public.match_feed_items enable row level security;
alter table public.telemetry_events enable row level security;
alter table public.score_snapshots enable row level security;
alter table public.match_summaries enable row level security;

-- Users
drop policy if exists users_self_select on public.users;
create policy users_self_select on public.users
  for select using (auth.uid() = id);

drop policy if exists users_self_update on public.users;
create policy users_self_update on public.users
  for update using (auth.uid() = id);

-- Public read-only content library
drop policy if exists reels_public_read on public.reels;
create policy reels_public_read on public.reels
  for select using (active = true);

drop policy if exists reel_sets_public_read on public.reel_sets;
create policy reel_sets_public_read on public.reel_sets
  for select using (active = true);

drop policy if exists reel_set_items_public_read on public.reel_set_items;
create policy reel_set_items_public_read on public.reel_set_items
  for select using (true);

-- Match visibility: only players in that match
drop policy if exists matches_player_read on public.matches;
create policy matches_player_read on public.matches
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = matches.id
        and mp.user_id = auth.uid()
    )
  );

drop policy if exists match_players_player_read on public.match_players;
create policy match_players_player_read on public.match_players
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = match_players.match_id
        and mp.user_id = auth.uid()
    )
  );

drop policy if exists match_feed_items_player_read on public.match_feed_items;
create policy match_feed_items_player_read on public.match_feed_items
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = match_feed_items.match_id
        and mp.user_id = auth.uid()
    )
  );

drop policy if exists score_snapshots_player_read on public.score_snapshots;
create policy score_snapshots_player_read on public.score_snapshots
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = score_snapshots.match_id
        and mp.user_id = auth.uid()
    )
  );

drop policy if exists match_summaries_player_read on public.match_summaries;
create policy match_summaries_player_read on public.match_summaries
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = match_summaries.match_id
        and mp.user_id = auth.uid()
    )
  );

-- Telemetry is append-only by participants.
drop policy if exists telemetry_player_insert on public.telemetry_events;
create policy telemetry_player_insert on public.telemetry_events
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.match_players mp
      where mp.match_id = telemetry_events.match_id
        and mp.user_id = auth.uid()
    )
  );

drop policy if exists telemetry_player_read on public.telemetry_events;
create policy telemetry_player_read on public.telemetry_events
  for select using (
    exists (
      select 1
      from public.match_players mp
      where mp.match_id = telemetry_events.match_id
        and mp.user_id = auth.uid()
    )
  );

revoke update, delete on public.telemetry_events from authenticated;
revoke insert, update, delete on public.score_snapshots from authenticated;
revoke insert, update, delete on public.match_summaries from authenticated;
