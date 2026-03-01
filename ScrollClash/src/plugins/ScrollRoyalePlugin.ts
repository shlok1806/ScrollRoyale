import { registerPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';

// ---------------------------------------------------------------------------
// Shared data types (mirror of Swift models)
// ---------------------------------------------------------------------------

export interface Match {
  id: string;
  matchCode: string | null;
  /** "waiting" | "in_progress" | "ended" */
  status: string;
  durationSec: number;
  player1Id: string;
  player2Id: string | null;
  isReady: boolean;
  createdAt: string;
  startedAt: string | null;
  endedAt: string | null;
  contentFeedIds: string[];
}

export interface GameState {
  scrollOffset: number;
  scrollVelocity: number;
  currentVideoIndex: number;
  videoPlaybackTime: number;
  lastUpdated: string;
  player1Score?: number;
  player2Score?: number;
}

export interface ContentItem {
  id: string;
  /** Absolute URL string */
  videoURL: string;
  duration: number;
  order: number;
  thumbnailURL?: string;
}

export interface ScoreSnapshot {
  matchId: string;
  userId: string;
  score: number;
  metrics: Record<string, number>;
  snapshotAt: string;
}

export interface TelemetryEventPayload {
  client_event_id: string;
  event_type: 'view_start' | 'view_end' | 'scroll' | 'like';
  reel_id?: string;
  occurred_at: string;
  payload: Record<string, number>;
}

// ---------------------------------------------------------------------------
// Plugin interface
// ---------------------------------------------------------------------------

export interface ScrollRoyalePluginInterface {
  // Matchmaking
  createMatch(options: { durationSec: number }): Promise<Match>;
  joinMatch(options: { code: string }): Promise<Match>;
  getMatch(options: { matchId: string }): Promise<Match>;
  leaveMatch(options: { matchId: string }): Promise<void>;

  // Content
  fetchContentFeed(options: { matchId: string }): Promise<{ items: ContentItem[] }>;

  // Sync / realtime
  connect(options: { matchId: string; userId: string }): Promise<void>;
  disconnect(): Promise<void>;
  sendGameState(options: { state: GameState; reelId?: string }): Promise<void>;
  sendTelemetry(options: { matchId: string; events: TelemetryEventPayload[] }): Promise<void>;

  // Event listeners (fired by native notifyListeners)
  addListener(
    eventName: 'gameStateUpdate',
    listenerFunc: (state: GameState) => void
  ): Promise<PluginListenerHandle>;
  addListener(
    eventName: 'scoreUpdate',
    listenerFunc: (snapshot: ScoreSnapshot) => void
  ): Promise<PluginListenerHandle>;
  removeAllListeners(): Promise<void>;
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/**
 * Native Capacitor plugin that bridges the React UI to the Swift backend
 * services (MatchmakingService, ContentService, SyncService, SupabaseClient).
 *
 * Usage:
 *   import { ScrollRoyaleNative } from '@/plugins/ScrollRoyalePlugin';
 *   const match = await ScrollRoyaleNative.createMatch({ durationSec: 90 });
 */
export const ScrollRoyaleNative = registerPlugin<ScrollRoyalePluginInterface>('ScrollRoyale');
