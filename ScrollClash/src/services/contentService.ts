import { supabase } from '../lib/supabaseClient';
import {
  type ContentItem,
  type SupabaseFeedItemDTO,
  contentItemFromDTO,
} from '../lib/gameTypes';
import { ensureAuthenticated } from './authService';

/**
 * Fetches the ordered video feed for a match.
 * Mirrors SupabaseContentService.fetchContentFeed() from Swift.
 * Falls back to sample BigBuckBunny videos if the RPC returns nothing,
 * matching MockContentService behaviour.
 */
export async function fetchContentFeed(matchId: string): Promise<ContentItem[]> {
  await ensureAuthenticated();
  const { data, error } = await supabase.rpc('fetch_match_feed', {
    p_match_id: matchId,
  });
  if (error) throw new Error(error.message);

  const rows = (data ?? []) as SupabaseFeedItemDTO[];
  if (rows.length === 0) {
    // Mock fallback — identical to MockContentService
    return Array.from({ length: 6 }, (_, i) => ({
      id: `video-${i + 1}`,
      videoURL:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      duration: 60,
      order: i + 1,
    }));
  }

  return rows
    .map(contentItemFromDTO)
    .sort((a, b) => a.order - b.order);
}
