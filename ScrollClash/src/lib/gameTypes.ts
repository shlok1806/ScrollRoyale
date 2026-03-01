// ---------------------------------------------------------------------------
// Game types — mirrors the Swift models in ScrollRoyale/Models/
// ---------------------------------------------------------------------------

export type MatchStatus = 'waiting' | 'in_progress' | 'ended';

export interface Match {
  id: string;
  matchCode: string | null;
  player1Id: string;
  player2Id: string | null;
  status: MatchStatus;
  createdAt: string;
  startedAt: string | null;
  endedAt: string | null;
  durationSec: number;
  contentFeedIds: string[];
  isReady: boolean;
}

export interface ContentItem {
  id: string;
  videoURL: string;
  duration: number;
  order: number;
  thumbnailURL?: string;
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

export interface ScoreSnapshot {
  matchId: string;
  userId: string;
  score: number;
  metrics: Record<string, number>;
  snapshotAt: string;
}

export type TelemetryEventType = 'view_start' | 'view_end' | 'scroll' | 'like';

export interface TelemetryEvent {
  id: string;
  reelId?: string;
  eventType: TelemetryEventType;
  occurredAt: string;
  payload: Record<string, number>;
}

// ---------------------------------------------------------------------------
// Supabase RPC response shapes (snake_case from the wire)
// ---------------------------------------------------------------------------

export interface SupabaseMatchDTO {
  id: string;
  match_code: string | null;
  status: string;
  created_at: string;
  started_at: string | null;
  ended_at: string | null;
  duration_sec: number;
  created_by: string;
}

export interface SupabaseFeedItemDTO {
  reel_id: string;
  ordinal: number;
  duration_ms: number;
  signed_video_url: string;
}

export interface SupabaseScoreSnapshotDTO {
  score: number;
  metrics: Record<string, number>;
  snapshot_at: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

export function matchFromDTO(dto: SupabaseMatchDTO): Match {
  let status: MatchStatus;
  switch (dto.status) {
    case 'in_progress': status = 'in_progress'; break;
    case 'ended': status = 'ended'; break;
    default: status = 'waiting';
  }
  return {
    id: dto.id,
    matchCode: dto.match_code,
    player1Id: dto.created_by,
    player2Id: null,
    status,
    createdAt: dto.created_at,
    startedAt: dto.started_at,
    endedAt: dto.ended_at,
    durationSec: dto.duration_sec,
    contentFeedIds: [],
    isReady: false,
  };
}

export function contentItemFromDTO(dto: SupabaseFeedItemDTO): ContentItem {
  return {
    id: dto.reel_id,
    videoURL: dto.signed_video_url,
    duration: dto.duration_ms / 1000,
    order: dto.ordinal,
  };
}

export function scoreSnapshotFromDTO(
  dto: SupabaseScoreSnapshotDTO,
  matchId: string,
  userId: string
): ScoreSnapshot {
  return {
    matchId,
    userId,
    score: dto.score,
    metrics: dto.metrics ?? {},
    snapshotAt: dto.snapshot_at,
  };
}
