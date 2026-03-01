-- Scroll Royale canonical schema for Supabase/Postgres.
-- This schema supports deterministic match feeds, append-only telemetry,
-- rolling score snapshots, and server-authoritative match finalization.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'match_status') then
    create type public.match_status as enum ('waiting', 'in_progress', 'ended', 'cancelled');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'telemetry_event_type') then
    create type public.telemetry_event_type as enum ('view_start', 'view_end', 'scroll', 'like');
  end if;
end $$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 40),
  rating integer not null default 1000,
  created_at timestamptz not null default now()
);

create table if not exists public.reels (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null unique,
  duration_ms integer not null check (duration_ms > 0),
  active boolean not null default true,
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.reel_sets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.reel_set_items (
  reel_set_id uuid not null references public.reel_sets(id) on delete cascade,
  reel_id uuid not null references public.reels(id),
  weight integer not null default 1 check (weight > 0),
  primary key (reel_set_id, reel_id)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  match_code text unique check (match_code ~ '^[A-Z0-9]{6}$'),
  status public.match_status not null default 'waiting',
  duration_sec integer not null check (duration_sec in (90, 180, 300)),
  reel_set_id uuid references public.reel_sets(id),
  created_by uuid not null references public.users(id),
  winner_user_id uuid references public.users(id),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  ended_at timestamptz,
  idempotency_key text unique
);

create table if not exists public.match_players (
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.users(id),
  slot smallint not null check (slot in (1, 2)),
  joined_at timestamptz not null default now(),
  ready_state boolean not null default false,
  disconnected_at timestamptz,
  primary key (match_id, user_id),
  unique (match_id, slot)
);

create table if not exists public.match_feed_items (
  match_id uuid not null references public.matches(id) on delete cascade,
  ordinal integer not null check (ordinal >= 0),
  reel_id uuid not null references public.reels(id),
  primary key (match_id, ordinal),
  unique (match_id, reel_id, ordinal)
);

create index if not exists idx_match_feed_items_match on public.match_feed_items(match_id, ordinal);
create index if not exists idx_matches_status_created_at on public.matches(status, created_at desc);
create index if not exists idx_matches_match_code on public.matches(match_code);
create index if not exists idx_match_players_user_joined on public.match_players(user_id, joined_at desc);

create table if not exists public.telemetry_events (
  id bigint generated always as identity primary key,
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.users(id),
  reel_id uuid references public.reels(id),
  event_type public.telemetry_event_type not null,
  client_event_id text not null,
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb,
  unique (match_id, user_id, client_event_id)
);

create index if not exists idx_telemetry_events_match_user_time
  on public.telemetry_events(match_id, user_id, occurred_at);

create table if not exists public.score_snapshots (
  id bigint generated always as identity primary key,
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.users(id),
  score numeric(12, 3) not null default 0,
  metrics jsonb not null default '{}'::jsonb,
  snapshot_at timestamptz not null default now()
);

create index if not exists idx_score_snapshots_match_time
  on public.score_snapshots(match_id, snapshot_at desc);

create table if not exists public.match_summaries (
  match_id uuid primary key references public.matches(id) on delete cascade,
  summary jsonb not null,
  finalized_at timestamptz not null default now()
);
