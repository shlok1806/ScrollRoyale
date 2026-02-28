-- Server-authoritative RPCs and helper functions.

create or replace function public.generate_match_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_exists boolean;
begin
  loop
    -- 6-char uppercase alphanumeric code.
    v_code := upper(substring(encode(gen_random_bytes(6), 'base64') from '[A-Za-z0-9]{6}'));
    v_code := regexp_replace(v_code, '[^A-Z0-9]', '', 'g');
    if char_length(v_code) < 6 then
      continue;
    end if;
    v_code := substring(v_code from 1 for 6);
    select exists(select 1 from public.matches where match_code = v_code) into v_exists;
    exit when not v_exists;
  end loop;
  return v_code;
end;
$$;

create or replace function public.ensure_user_profile(p_display_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_display_name text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  v_display_name := trim(coalesce(p_display_name, ''));
  if v_display_name = '' then
    v_display_name := 'Player-' || upper(substring(replace(v_user_id::text, '-', '') from 1 for 6));
  end if;

  insert into public.users (id, display_name)
  values (v_user_id, left(v_display_name, 40))
  on conflict (id) do update
  set display_name = excluded.display_name;

  return v_user_id;
end;
$$;

create or replace function public.create_match(
  p_duration_sec integer,
  p_reel_set_id uuid,
  p_idempotency_key text default null
)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
begin
  if p_duration_sec not in (90, 180, 300) then
    raise exception 'invalid duration_sec: %', p_duration_sec;
  end if;

  if p_idempotency_key is not null then
    select * into v_match
    from public.matches
    where created_by = auth.uid()
      and idempotency_key = p_idempotency_key
    limit 1;
    if found then
      return v_match;
    end if;
  end if;

  insert into public.matches (duration_sec, reel_set_id, created_by, idempotency_key)
  values (p_duration_sec, p_reel_set_id, auth.uid(), p_idempotency_key)
  returning * into v_match;

  insert into public.match_players (match_id, user_id, slot, ready_state)
  values (v_match.id, auth.uid(), 1, false);

  return v_match;
end;
$$;

create or replace function public.create_match_with_code(
  p_duration_sec integer,
  p_reel_set_id uuid,
  p_idempotency_key text default null
)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
begin
  if p_duration_sec not in (90, 180, 300) then
    raise exception 'invalid duration_sec: %', p_duration_sec;
  end if;

  if p_idempotency_key is not null then
    select * into v_match
    from public.matches
    where created_by = auth.uid()
      and idempotency_key = p_idempotency_key
    limit 1;
    if found then
      return v_match;
    end if;
  end if;

  insert into public.matches (duration_sec, reel_set_id, created_by, idempotency_key, match_code)
  values (p_duration_sec, p_reel_set_id, auth.uid(), p_idempotency_key, public.generate_match_code())
  returning * into v_match;

  insert into public.match_players (match_id, user_id, slot, ready_state)
  values (v_match.id, auth.uid(), 1, true)
  on conflict (match_id, user_id) do nothing;

  return v_match;
end;
$$;

create or replace function public.join_match(p_match_id uuid)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
  v_player_count integer;
begin
  select * into v_match
  from public.matches
  where id = p_match_id
    and status = 'waiting'
  for update;

  if not found then
    raise exception 'match not joinable';
  end if;

  select count(*) into v_player_count
  from public.match_players
  where match_id = p_match_id;

  if v_player_count >= 2 then
    raise exception 'match full';
  end if;

  insert into public.match_players (match_id, user_id, slot, ready_state)
  values (p_match_id, auth.uid(), 2, false)
  on conflict (match_id, user_id) do nothing;

  return v_match;
end;
$$;

create or replace function public.join_match_by_code(p_match_code text)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
  v_player_count integer;
begin
  select * into v_match
  from public.matches
  where match_code = upper(p_match_code)
    and status = 'waiting'
  for update;

  if not found then
    raise exception 'invalid or unavailable match code';
  end if;

  select count(*) into v_player_count
  from public.match_players
  where match_id = v_match.id;

  if v_player_count >= 2 then
    raise exception 'match full';
  end if;

  insert into public.match_players (match_id, user_id, slot, ready_state)
  values (v_match.id, auth.uid(), 2, true)
  on conflict (match_id, user_id) do update
  set ready_state = true;

  -- Auto-start once second player joins.
  update public.matches
  set status = 'in_progress',
      started_at = coalesce(started_at, now())
  where id = v_match.id
  returning * into v_match;

  perform public.materialize_match_feed(v_match.id);

  return v_match;
end;
$$;

create or replace function public.get_match(p_match_id uuid)
returns public.matches
language sql
security definer
set search_path = public
as $$
  select m.*
  from public.matches m
  where m.id = p_match_id
    and exists (
      select 1
      from public.match_players mp
      where mp.match_id = m.id
        and mp.user_id = auth.uid()
    )
  limit 1;
$$;

create or replace function public.leave_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status public.match_status;
begin
  select status into v_status
  from public.matches
  where id = p_match_id;

  if v_status = 'waiting' then
    -- Host/guest can leave a waiting match completely.
    delete from public.match_players
    where match_id = p_match_id
      and user_id = auth.uid();

    -- If no players remain in a waiting match, cancel it.
    if not exists (
      select 1
      from public.match_players mp
      where mp.match_id = p_match_id
    ) then
      update public.matches
      set status = 'cancelled',
          ended_at = coalesce(ended_at, now())
      where id = p_match_id;
    end if;
  elsif v_status = 'in_progress' then
    -- Mark disconnection for in-progress flows (future reconnect logic can use this).
    update public.match_players
    set disconnected_at = now()
    where match_id = p_match_id
      and user_id = auth.uid();
  end if;
end;
$$;

create or replace function public.set_ready(p_match_id uuid, p_ready boolean)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
  v_ready_count integer;
begin
  update public.match_players
  set ready_state = p_ready
  where match_id = p_match_id
    and user_id = auth.uid();

  select count(*) into v_ready_count
  from public.match_players
  where match_id = p_match_id
    and ready_state = true;

  if v_ready_count = 2 then
    update public.matches
    set status = 'in_progress',
        started_at = coalesce(started_at, now())
    where id = p_match_id
    returning * into v_match;

    perform public.materialize_match_feed(p_match_id);
    return v_match;
  end if;

  select * into v_match from public.matches where id = p_match_id;
  return v_match;
end;
$$;

create or replace function public.materialize_match_feed(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reel_set uuid;
begin
  if exists (select 1 from public.match_feed_items where match_id = p_match_id) then
    return;
  end if;

  select reel_set_id into v_reel_set
  from public.matches
  where id = p_match_id;

  with candidate_reels as (
    select r.id,
           row_number() over (order by random()) - 1 as ordinal
    from public.reels r
    where r.active = true
      and (
        v_reel_set is null
        or exists (
          select 1
          from public.reel_set_items rsi
          where rsi.reel_set_id = v_reel_set
            and rsi.reel_id = r.id
        )
      )
    limit 100
  )
  insert into public.match_feed_items (match_id, ordinal, reel_id)
  select p_match_id, ordinal, id
  from candidate_reels
  order by ordinal;
end;
$$;

create or replace function public.ingest_telemetry_batch(p_match_id uuid, p_events jsonb)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer := 0;
begin
  insert into public.telemetry_events (match_id, user_id, reel_id, event_type, client_event_id, occurred_at, payload)
  select
    p_match_id,
    auth.uid(),
    nullif((e->>'reel_id'), '')::uuid,
    (e->>'event_type')::public.telemetry_event_type,
    e->>'client_event_id',
    (e->>'occurred_at')::timestamptz,
    coalesce(e->'payload', '{}'::jsonb)
  from jsonb_array_elements(p_events) e
  on conflict (match_id, user_id, client_event_id) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

create or replace function public.fetch_match_feed(p_match_id uuid)
returns table (
  reel_id uuid,
  ordinal integer,
  duration_ms integer,
  signed_video_url text
)
language sql
security definer
set search_path = public
as $$
  select
    mfi.reel_id,
    mfi.ordinal,
    r.duration_ms,
    r.storage_path as signed_video_url
  from public.match_feed_items mfi
  join public.reels r on r.id = mfi.reel_id
  where mfi.match_id = p_match_id
  order by mfi.ordinal asc;
$$;

create or replace function public.latest_score_snapshot(p_match_id uuid, p_user_id uuid)
returns table (
  score numeric,
  metrics jsonb,
  snapshot_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    ss.score,
    ss.metrics,
    ss.snapshot_at
  from public.score_snapshots ss
  where ss.match_id = p_match_id
    and ss.user_id = p_user_id
  order by ss.snapshot_at desc
  limit 1;
$$;

create or replace function public.compute_score_snapshot(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.score_snapshots (match_id, user_id, score, metrics, snapshot_at)
  select
    p_match_id as match_id,
    te.user_id,
    (
      coalesce(sum(case when te.event_type = 'like' then 5 else 0 end), 0)
      + coalesce(sum(case when te.event_type = 'view_end' then 2 else 0 end), 0)
      + coalesce(avg(
          case
            when te.event_type = 'scroll'
            then greatest(0.0, 3.0 - least(3.0, abs((te.payload->>'velocity')::numeric)))
            else null
          end
        ), 0)
    )::numeric(12, 3) as score,
    jsonb_build_object(
      'likes', count(*) filter (where te.event_type = 'like'),
      'view_ends', count(*) filter (where te.event_type = 'view_end'),
      'avg_scroll_velocity', avg((te.payload->>'velocity')::numeric)
    ) as metrics,
    now() as snapshot_at
  from public.telemetry_events te
  where te.match_id = p_match_id
  group by te.user_id;
end;
$$;

create or replace function public.finalize_match(p_match_id uuid)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_match public.matches;
  v_winner uuid;
begin
  perform public.compute_score_snapshot(p_match_id);

  select ss.user_id into v_winner
  from public.score_snapshots ss
  where ss.match_id = p_match_id
  order by ss.snapshot_at desc, ss.score desc
  limit 1;

  update public.matches
  set status = 'ended',
      ended_at = now(),
      winner_user_id = v_winner
  where id = p_match_id
  returning * into v_match;

  insert into public.match_summaries (match_id, summary)
  values (
    p_match_id,
    jsonb_build_object(
      'winner_user_id', v_winner,
      'finalized_at', now(),
      'scores', (
        select jsonb_agg(
          jsonb_build_object(
            'user_id', ss.user_id,
            'score', ss.score,
            'snapshot_at', ss.snapshot_at
          )
          order by ss.snapshot_at desc
        )
        from public.score_snapshots ss
        where ss.match_id = p_match_id
      )
    )
  )
  on conflict (match_id) do update
  set summary = excluded.summary,
      finalized_at = now();

  return v_match;
end;
$$;

grant execute on function public.create_match(integer, uuid, text) to authenticated;
grant execute on function public.join_match(uuid) to authenticated;
grant execute on function public.set_ready(uuid, boolean) to authenticated;
grant execute on function public.ingest_telemetry_batch(uuid, jsonb) to authenticated;
grant execute on function public.fetch_match_feed(uuid) to authenticated;
grant execute on function public.latest_score_snapshot(uuid, uuid) to authenticated;
grant execute on function public.create_match_with_code(integer, uuid, text) to authenticated;
grant execute on function public.join_match_by_code(text) to authenticated;
grant execute on function public.get_match(uuid) to authenticated;
grant execute on function public.leave_match(uuid) to authenticated;
grant execute on function public.ensure_user_profile(text) to authenticated;
