-- Backfill migration for existing environments that already applied 001_schema.sql.
alter table public.matches
  add column if not exists match_code text;

update public.matches
set match_code = upper(substring(encode(gen_random_bytes(6), 'base64') from '[A-Za-z0-9]{6}'))
where match_code is null;

alter table public.matches
  alter column match_code set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'matches_match_code_format'
  ) then
    alter table public.matches
      add constraint matches_match_code_format
      check (match_code ~ '^[A-Z0-9]{6}$');
  end if;
end $$;

create unique index if not exists idx_matches_match_code_unique on public.matches(match_code);
