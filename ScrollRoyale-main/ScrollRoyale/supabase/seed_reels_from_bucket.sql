-- Add reels that point to files in your Supabase Storage bucket "reels"
-- Run this in Supabase → SQL Editor.
--
-- 1. In Storage, open your "reels" bucket and note each file path (e.g. "intro.mp4", "clip1.mp4", "videos/game.mp4").
-- 2. Replace the values below with your actual file paths and durations (duration_ms = length in milliseconds, e.g. 15000 = 15 sec).
-- 3. Run the script.

insert into public.reels (storage_path, duration_ms, active, tags)
values
  ('reels/intro.mp4', 15000, true, '{}'),
  ('reels/clip1.mp4', 20000, true, '{}'),
  ('reels/clip2.mp4', 18000, true, '{}')
on conflict (storage_path) do nothing;

-- If your files are in a folder inside the bucket, use: 'reels/folder/filename.mp4'
-- Example:
-- insert into public.reels (storage_path, duration_ms, active, tags)
-- values ('reels/shorts/video1.mp4', 10000, true, '{}');
