import { supabase } from '../lib/supabaseClient';
import {
  type GameState,
  type ScoreSnapshot,
  type TelemetryEvent,
  type SupabaseScoreSnapshotDTO,
  scoreSnapshotFromDTO,
} from '../lib/gameTypes';
import { ensureAuthenticated } from './authService';

type ScoreCallback = (snapshot: ScoreSnapshot) => void;

interface SyncSession {
  matchId: string;
  userId: string;
  scorePoller: ReturnType<typeof setInterval>;
  onScore: ScoreCallback;
}

let activeSession: SyncSession | null = null;

/**
 * Starts polling for score updates every second and calls onScore on each result.
 * Mirrors SupabaseSyncService.connect() from Swift.
 */
export function connect(
  matchId: string,
  userId: string,
  onScore: ScoreCallback
): void {
  disconnect(); // Cancel any previous session

  const scorePoller = setInterval(async () => {
    try {
      await ensureAuthenticated();
      const { data, error } = await supabase.rpc('latest_score_snapshot', {
        p_match_id: matchId,
        p_user_id: userId,
      });
      if (!error && data) {
        activeSession?.onScore(
          scoreSnapshotFromDTO(data as SupabaseScoreSnapshotDTO, matchId, userId)
        );
      }
    } catch {
      // Ignore transient poll failures
    }
  }, 1000);

  activeSession = { matchId, userId, scorePoller, onScore };
}

/** Stops the score poller. Call on DuelArena unmount. */
export function disconnect(): void {
  if (activeSession) {
    clearInterval(activeSession.scorePoller);
    activeSession = null;
  }
}

/**
 * Sends the current game state as a scroll telemetry event.
 * Mirrors SupabaseSyncService.sendGameState() from Swift.
 */
export async function sendGameState(
  state: GameState,
  reelId?: string,
  matchId?: string
): Promise<void> {
  const mid = matchId ?? activeSession?.matchId;
  if (!mid) return;

  const event: TelemetryEvent = {
    id: crypto.randomUUID(),
    reelId,
    eventType: 'scroll',
    occurredAt: new Date().toISOString(),
    payload: {
      offset: state.scrollOffset,
      video_index: state.currentVideoIndex,
      playback_time: state.videoPlaybackTime,
      velocity: state.scrollVelocity,
    },
  };

  await sendTelemetry([event], mid);
}

/**
 * Batches telemetry events and sends them to Supabase.
 * Mirrors SupabaseSyncService.sendTelemetry() from Swift.
 */
export async function sendTelemetry(
  events: TelemetryEvent[],
  matchId: string
): Promise<void> {
  try {
    await ensureAuthenticated();
    const payload = events.map((e) => ({
      client_event_id: e.id,
      event_type: e.eventType,
      occurred_at: e.occurredAt,
      payload: e.payload,
      ...(e.reelId ? { reel_id: e.reelId } : {}),
    }));
    await supabase.rpc('ingest_telemetry_batch', {
      p_match_id: matchId,
      p_events: payload,
    });
  } catch {
    // Best-effort: telemetry loss is acceptable
  }
}
