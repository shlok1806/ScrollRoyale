import { supabase } from '../lib/supabaseClient';

// In-flight deduplication: if multiple calls fire before auth resolves, reuse the same promise.
let inFlightAuth: Promise<void> | null = null;

function generateDisplayName(): string {
  return 'Player-' + Math.random().toString(36).slice(2, 8).toUpperCase();
}

/**
 * Ensures the user has an active anonymous Supabase session.
 * Mirrors SupabaseAuthService.ensureAuthenticated() from the Swift app.
 * Safe to call multiple times — uses the persisted session on fast path.
 */
export async function ensureAuthenticated(): Promise<void> {
  // Fast path: existing valid session
  const { data: { session } } = await supabase.auth.getSession();
  if (session?.user?.id) {
    // Ensure the profile row exists (idempotent RPC)
    const displayName =
      (session.user.user_metadata?.display_name as string | undefined) ??
      generateDisplayName();
    await supabase.rpc('ensure_user_profile', { p_display_name: displayName });
    return;
  }

  // Deduplicate concurrent calls
  if (inFlightAuth) return inFlightAuth;

  inFlightAuth = (async () => {
    try {
      const displayName = generateDisplayName();
      const { error } = await supabase.auth.signInAnonymously({
        options: { data: { display_name: displayName } },
      });
      if (error) throw error;

      await supabase.rpc('ensure_user_profile', { p_display_name: displayName });
    } finally {
      inFlightAuth = null;
    }
  })();

  return inFlightAuth;
}

/** Returns the current authenticated user's ID, or null if not signed in. */
export async function getUserId(): Promise<string | null> {
  const { data: { session } } = await supabase.auth.getSession();
  return session?.user?.id ?? null;
}

/** Returns the current user's display name from session metadata. */
export async function getDisplayName(): Promise<string> {
  const { data: { session } } = await supabase.auth.getSession();
  return (
    (session?.user?.user_metadata?.display_name as string | undefined) ??
    'Player'
  );
}
