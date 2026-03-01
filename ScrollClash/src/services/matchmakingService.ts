import { supabase } from '../lib/supabaseClient';
import {
  type Match,
  type SupabaseMatchDTO,
  matchFromDTO,
} from '../lib/gameTypes';
import { ensureAuthenticated } from './authService';

function randomUUID(): string {
  return crypto.randomUUID();
}

/**
 * Creates a new match and returns it.
 * Mirrors SupabaseMatchmakingService.createMatch() from Swift.
 */
export async function createMatch(durationSec: number = 90): Promise<Match> {
  await ensureAuthenticated();
  const { data, error } = await supabase.rpc('create_match_with_code', {
    p_duration_sec: durationSec,
    p_reel_set_id: null,
    p_idempotency_key: randomUUID(),
  });
  if (error) throw new Error(error.message);
  const dto = data as SupabaseMatchDTO;
  const match = matchFromDTO(dto);
  if (!match.matchCode || match.matchCode.trim().length !== 6) {
    throw new Error(
      'Match created but no valid code returned. Ensure SQL migrations 001/003 are applied.'
    );
  }
  return match;
}

/**
 * Joins an existing match by its 6-character code.
 * Mirrors SupabaseMatchmakingService.joinMatch() from Swift.
 */
export async function joinMatch(code: string): Promise<Match> {
  await ensureAuthenticated();
  const { data, error } = await supabase.rpc('join_match_by_code', {
    p_match_code: code.toUpperCase(),
  });
  if (error) throw new Error(error.message);
  return matchFromDTO(data as SupabaseMatchDTO);
}

/**
 * Fetches the current state of a match by ID.
 * Used for polling until an opponent joins.
 */
export async function getMatch(matchId: string): Promise<Match> {
  await ensureAuthenticated();
  const { data, error } = await supabase.rpc('get_match', {
    p_match_id: matchId,
  });
  if (error) throw new Error(error.message);
  const dto = data as SupabaseMatchDTO;
  const match = matchFromDTO(dto);
  // Derive isReady from the live data
  return {
    ...match,
    isReady: dto.status === 'in_progress',
  };
}

/**
 * Removes the current user from a match.
 * Call this when navigating away from DuelResult.
 */
export async function leaveMatch(matchId: string): Promise<void> {
  await ensureAuthenticated();
  const { error } = await supabase.rpc('leave_match', {
    p_match_id: matchId,
  });
  if (error) throw new Error(error.message);
}
