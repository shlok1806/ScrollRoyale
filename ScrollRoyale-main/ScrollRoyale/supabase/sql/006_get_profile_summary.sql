-- Missing RPCs: the app calls these but they were never in 003_functions.sql.
-- Run this after 001_schema, 002_rls, and 003_functions.

-- Profile tab
create or replace function public.get_profile_summary()
returns table (
  "userId" uuid,
  "displayName" text,
  "matchesPlayed" bigint,
  "wins" bigint,
  "bestScore" numeric
)
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Ensure the user has a profile row (idempotent).
  perform public.ensure_user_profile(null);

  return query
  select
    u.id as "userId",
    u.display_name as "displayName",
    (select count(*)::bigint
     from public.match_players mp
     join public.matches m on m.id = mp.match_id
     where mp.user_id = u.id
       and m.status = 'ended') as "matchesPlayed",
    (select count(*)::bigint
     from public.matches m
     where m.winner_user_id = u.id) as "wins",
    coalesce(
      (select max(ss.score)
       from public.score_snapshots ss
       where ss.user_id = u.id),
      0::numeric
    ) as "bestScore"
  from public.users u
  where u.id = auth.uid()
  limit 1;
end;
$$;

grant execute on function public.get_profile_summary() to authenticated;
grant execute on function public.get_profile_summary() to anon;

-- Leaderboard tab
create or replace function public.get_global_leaderboard(p_limit integer default 50)
returns table (
  "userId" uuid,
  "displayName" text,
  "wins" bigint,
  "averageScore" numeric
)
language sql
security definer
set search_path = public
as $$
  with user_stats as (
    select
      u.id,
      u.display_name,
      (select count(*)::bigint from public.matches m where m.winner_user_id = u.id) as wins,
      (select coalesce(avg(final.score), 0)::numeric
       from (
         select distinct on (ss.match_id) ss.score
         from public.score_snapshots ss
         where ss.user_id = u.id
         order by ss.match_id, ss.snapshot_at desc
       ) final) as average_score
    from public.users u
  )
  select
    id as "userId",
    display_name as "displayName",
    wins,
    coalesce(average_score, 0) as "averageScore"
  from user_stats
  order by wins desc, average_score desc
  limit least(greatest(coalesce(p_limit, 50), 1), 500);
$$;

grant execute on function public.get_global_leaderboard(integer) to authenticated;
grant execute on function public.get_global_leaderboard(integer) to anon;
