-- Normalize reel storage paths to bucket/path convention.
-- If your bucket name is not "reels", replace it before running.
update public.reels
set storage_path = 'reels/' || trim(both '/' from storage_path)
where storage_path is not null
  and trim(storage_path) <> ''
  and storage_path !~* '^https?://'
  and position('/' in trim(both '/' from storage_path)) = 0;
