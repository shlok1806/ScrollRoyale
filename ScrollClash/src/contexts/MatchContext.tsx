import React, { createContext, useContext, useState, useCallback } from 'react';
import type { Match, ContentItem, ScoreSnapshot } from '../lib/gameTypes';

interface MatchContextValue {
  userId: string | null;
  displayName: string | null;
  currentMatch: Match | null;
  contentFeed: ContentItem[];
  latestScore: ScoreSnapshot | null;
  opponentScore: ScoreSnapshot | null;
  setUserId: (id: string) => void;
  setDisplayName: (name: string) => void;
  setMatch: (m: Match) => void;
  setContentFeed: (items: ContentItem[]) => void;
  setLatestScore: (s: ScoreSnapshot) => void;
  setOpponentScore: (s: ScoreSnapshot) => void;
  clearMatch: () => void;
}

const MatchContext = createContext<MatchContextValue | null>(null);

export function MatchProvider({ children }: { children: React.ReactNode }) {
  const [userId, setUserId] = useState<string | null>(null);
  const [displayName, setDisplayName] = useState<string | null>(null);
  const [currentMatch, setCurrentMatch] = useState<Match | null>(null);
  const [contentFeed, setContentFeed] = useState<ContentItem[]>([]);
  const [latestScore, setLatestScore] = useState<ScoreSnapshot | null>(null);
  const [opponentScore, setOpponentScore] = useState<ScoreSnapshot | null>(null);

  const setMatch = useCallback((m: Match) => setCurrentMatch(m), []);

  const clearMatch = useCallback(() => {
    setCurrentMatch(null);
    setContentFeed([]);
    setLatestScore(null);
    setOpponentScore(null);
  }, []);

  return (
    <MatchContext.Provider
      value={{
        userId,
        displayName,
        currentMatch,
        contentFeed,
        latestScore,
        opponentScore,
        setUserId,
        setDisplayName,
        setMatch,
        setContentFeed,
        setLatestScore,
        setOpponentScore,
        clearMatch,
      }}
    >
      {children}
    </MatchContext.Provider>
  );
}

export function useMatch(): MatchContextValue {
  const ctx = useContext(MatchContext);
  if (!ctx) throw new Error('useMatch must be used inside <MatchProvider>');
  return ctx;
}
