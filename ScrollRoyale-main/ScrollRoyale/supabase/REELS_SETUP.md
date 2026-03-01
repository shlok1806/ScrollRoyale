# Adding Your Reels So the Game Plays Your Videos

The game uses the `reels` table. When a match starts, `materialize_match_feed` fills `match_feed_items` from **active** reels (optionally filtered by the match’s reel set). If there are no reels, the feed is empty and you’ll see “No playable videos”.

---

## 1. Add rows to `reels`

Each reel needs at least:

- **storage_path** – either a **full URL** to the video, or a **Supabase Storage path** (see below).
- **duration_ms** – length of the video in milliseconds.
- **active** – `true` so it can be used in matches.

### Option A: Use a public URL (easiest)

If the video is already hosted somewhere (e.g. your CDN, S3 public link):

```sql
insert into public.reels (storage_path, duration_ms, active, tags)
values
  ('https://example.com/path/to/your-video-1.mp4', 15000, true, '{}'),
  ('https://example.com/path/to/your-video-2.mp4', 20000, true, '{}');
```

- Use real URLs that return the video file (e.g. `.mp4`).
- `duration_ms`: 15000 = 15 seconds, 20000 = 20 seconds, etc.

### Option B: Use Supabase Storage

1. In Supabase: **Storage** → create a bucket (e.g. `reels`) and set it to **Public** if you want public access, or keep it private and the app will use signed URLs.
2. Upload your video files (e.g. `clip1.mp4`, `clip2.mp4`).
3. Insert reels with **storage_path** = `bucket_name/file_path` (no leading slash):

```sql
insert into public.reels (storage_path, duration_ms, active, tags)
values
  ('reels/clip1.mp4', 15000, true, '{}'),
  ('reels/clip2.mp4', 20000, true, '{}');
```

- Bucket name is `reels`, path is the file path inside the bucket.
- The app uses the default bucket `reels` when you use a path without a slash; for other buckets use `bucketname/path/to/file.mp4`.

---

## 2. (Optional) Use a reel set

- **reel_sets** – group of reels (e.g. “Season 1”).
- **reel_set_items** – which reels are in that set.

If you **don’t** use a reel set, matches with `reel_set_id = null` will use **all active reels**. So you can skip this and just add rows to `reels`.

If you want to limit a match to a specific set:

```sql
-- Create a set
insert into public.reel_sets (name, active)
values ('Default set', true)
returning id;
-- Use the returned id as reel_set_id below.

-- Add reels to the set (use real reel ids from public.reels)
insert into public.reel_set_items (reel_set_id, reel_id, weight)
select 'YOUR_REEL_SET_UUID'::uuid, id, 1 from public.reels where active = true;
```

When creating a match, set its `reel_set_id` to that UUID so only those reels are used.

---

## 3. Run the SQL in Supabase

1. Open your project in the Supabase dashboard.
2. Go to **SQL Editor**.
3. Paste one of the `insert into public.reels ...` snippets above (with your URLs or storage paths and correct `duration_ms`).
4. Run the query.

After that, new matches will get a feed from your reels and your videos will play instead of the app showing “No playable videos”.

---

## Quick check

- **Reels in DB:**  
  `select id, storage_path, duration_ms, active from public.reels where active = true;`
- **Match feed (after a match started):**  
  `select * from public.match_feed_items where match_id = 'YOUR_MATCH_ID';`

If `reels` has rows and the match has started, `match_feed_items` should have rows and the app will load those videos.
