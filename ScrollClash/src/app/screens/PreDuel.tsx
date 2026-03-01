import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useNavigate } from 'react-router';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';
import { useMatch } from '../../contexts/MatchContext';
import { ensureAuthenticated, getUserId, getDisplayName } from '../../services/authService';
import { createMatch, getMatch } from '../../services/matchmakingService';

type MatchmakingPhase = 'searching' | 'found' | 'countdown';

export default function PreDuel() {
  const navigate = useNavigate();
  const { customization } = useBrainCustomization();
  const matchCtx = useMatch();
  const [phase, setPhase] = useState<MatchmakingPhase>('searching');
  const [countdown, setCountdown] = useState(3);
  const [dots, setDots] = useState('');
  const [matchCode, setMatchCode] = useState<string | null>(null);
  const [matchError, setMatchError] = useState<string | null>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Opponent display data (real name shown once found)
  const [opponentName, setOpponentName] = useState('WAITING...');
  const opponentVisuals = {
    rotLevel: Math.floor(Math.random() * 30) + 40,
    rank: Math.floor(Math.random() * 500) + 100,
    wins: Math.floor(Math.random() * 50) + 20,
    customization: {
      baseColor: '#FF006E',
      pattern: 'dots',
      eyes: 'focused',
      accessory: 'headband',
    },
  };

  // On mount: authenticate → create match → poll for opponent
  useEffect(() => {
    let cancelled = false;

    const dotsInterval = setInterval(() => {
      setDots(prev => (prev.length >= 3 ? '' : prev + '.'));
    }, 500);

    const startMatchmaking = async () => {
      try {
        await ensureAuthenticated();
        const uid = await getUserId();
        const dname = await getDisplayName();
        if (uid) matchCtx.setUserId(uid);
        if (dname) matchCtx.setDisplayName(dname);

        const match = await createMatch(90);
        if (cancelled) return;

        setMatchCode(match.matchCode);
        matchCtx.setMatch(match);

        // Poll every 2s until an opponent joins (match goes in_progress)
        pollRef.current = setInterval(async () => {
          try {
            const updated = await getMatch(match.id);
            if (updated.isReady && !cancelled) {
              clearInterval(pollRef.current!);
              setOpponentName(updated.player2Id?.slice(0, 8) ?? 'OPPONENT');
              matchCtx.setMatch(updated);
              setPhase('found');
            }
          } catch {
            // ignore transient poll errors
          }
        }, 2000);
      } catch (err) {
        if (!cancelled) {
          setMatchError(err instanceof Error ? err.message : 'Failed to create match');
        }
      }
    };

    startMatchmaking();

    return () => {
      cancelled = true;
      clearInterval(dotsInterval);
      if (pollRef.current) clearInterval(pollRef.current);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Countdown
  useEffect(() => {
    if (phase === 'countdown' && countdown > 0) {
      const countdownInterval = setInterval(() => {
        setCountdown(prev => {
          if (prev <= 1) {
            clearInterval(countdownInterval);
            setTimeout(() => navigate('/duel/arena'), 300);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      return () => clearInterval(countdownInterval);
    }
  }, [phase, countdown, navigate]);

  const handleReady = () => {
    setPhase('countdown');
  };

  const handleCancel = () => {
    if (pollRef.current) clearInterval(pollRef.current);
    matchCtx.clearMatch();
    navigate(-1);
  };

  return (
    <div className="h-screen relative text-white overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-transparent to-black/60" />
      </div>

      {/* Content */}
      <div className="relative z-10 h-full flex flex-col">
        {/* iOS Status Bar */}
        <div className="h-12" />

        {/* Header */}
        <div className="px-5 mb-4">
          <div className="flex items-center justify-between">
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={handleCancel}
              className="w-10 h-10 rounded-full bg-[#FF006E] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]"
            >
              <BackIcon size={18} className="text-white" />
            </motion.button>

            <h1 className="text-2xl font-black text-white" style={{ textShadow: '3px 3px 0 rgba(0,0,0,0.5)' }}>
              {phase === 'searching' && 'FINDING OPPONENT'}
              {phase === 'found' && 'OPPONENT FOUND'}
              {phase === 'countdown' && 'GET READY!'}
            </h1>

            <div className="w-10" />
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 flex flex-col items-center justify-center px-5">
          <AnimatePresence mode="wait">
            {/* Searching Phase */}
            {phase === 'searching' && (
              <motion.div
                key="searching"
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="text-center"
              >
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 2, repeat: Infinity, ease: 'linear' }}
                  className="w-24 h-24 mx-auto mb-6"
                >
                  <SwordsIcon size={96} className="text-[#39FF14]" />
                </motion.div>
                <h2 className="text-3xl font-black mb-2" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
                  {matchCode ? `WAITING${dots}` : `SEARCHING${dots}`}
                </h2>
                <p className="text-white/70 font-bold">
                  {matchCode ? 'Share code with a friend' : 'Creating match...'}
                </p>
                {matchCode && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: 'spring', stiffness: 200 }}
                    className="mt-6 bg-black/60 border-4 border-[#39FF14] rounded-2xl px-8 py-4 shadow-[0_6px_0_rgba(57,255,20,0.3)]"
                  >
                    <p className="text-xs font-black text-white/60 mb-1">MATCH CODE</p>
                    <p className="text-4xl font-black text-[#39FF14] tracking-[0.3em]">{matchCode}</p>
                  </motion.div>
                )}
                {matchError && (
                  <p className="mt-4 text-red-400 font-bold text-sm">{matchError}</p>
                )}
              </motion.div>
            )}

            {/* Found & Countdown Phase */}
            {(phase === 'found' || phase === 'countdown') && (
              <motion.div
                key="found"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="w-full max-w-md"
              >
                {/* VS Section */}
                <div className="relative mb-8">
                  <div className="flex items-center justify-between gap-4">
                    {/* You */}
                    <motion.div
                      initial={{ x: -100, opacity: 0 }}
                      animate={{ x: 0, opacity: 1 }}
                      transition={{ delay: 0.2 }}
                      className="flex-1"
                    >
                      <div className="bg-[#7B2CBF] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
                        <div className="flex items-center gap-3 mb-3">
                          <div className="w-16 h-16 bg-black/20 rounded-xl border-2 border-black flex items-center justify-center overflow-hidden">
                            <BrainCharacter customization={customization} size={48} rotLevel={25} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <h3 className="font-black text-sm text-white truncate">YOU</h3>
                            <p className="text-xs text-white/70 font-bold">Rank #42</p>
                          </div>
                        </div>
                        <div className="space-y-1">
                          <StatRow label="ROT" value="25%" color="text-[#39FF14]" />
                          <StatRow label="WINS" value="37" color="text-white" />
                        </div>
                      </div>
                    </motion.div>

                    {/* VS Badge */}
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ delay: 0.4, type: 'spring', stiffness: 200 }}
                      className="relative z-10"
                    >
                      <div className="w-14 h-14 bg-[#FF006E] border-4 border-black rounded-full flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
                        <span className="text-xl font-black text-white">VS</span>
                      </div>
                    </motion.div>

                    {/* Opponent */}
                    <motion.div
                      initial={{ x: 100, opacity: 0 }}
                      animate={{ x: 0, opacity: 1 }}
                      transition={{ delay: 0.2 }}
                      className="flex-1"
                    >
                      <div className="bg-[#FF006E] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
                        <div className="flex items-center gap-3 mb-3">
                          <div className="w-16 h-16 bg-black/20 rounded-xl border-2 border-black flex items-center justify-center overflow-hidden">
                            <BrainCharacter customization={opponentVisuals.customization} size={48} rotLevel={opponentVisuals.rotLevel} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <h3 className="font-black text-sm text-white truncate">{opponentName}</h3>
                            <p className="text-xs text-white/70 font-bold">Rank #{opponentVisuals.rank}</p>
                          </div>
                        </div>
                        <div className="space-y-1">
                          <StatRow label="ROT" value={`${opponentVisuals.rotLevel}%`} color="text-[#FFD60A]" />
                          <StatRow label="WINS" value={opponentVisuals.wins.toString()} color="text-white" />
                        </div>
                      </div>
                    </motion.div>
                  </div>
                </div>

                {/* Battle Info */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 }}
                  className="bg-black/40 border-3 border-white/20 rounded-xl p-4 mb-6"
                >
                  <div className="grid grid-cols-3 gap-3 text-center">
                    <div>
                      <div className="text-2xl font-black text-[#39FF14]">{matchCtx.currentMatch?.durationSec ?? 90}s</div>
                      <div className="text-xs font-bold text-white/60">DURATION</div>
                    </div>
                    <div>
                      <div className="text-2xl font-black text-[#FFD60A]">+25</div>
                      <div className="text-xs font-bold text-white/60">TROPHY</div>
                    </div>
                    <div>
                      <div className="text-2xl font-black text-[#FF006E]">4</div>
                      <div className="text-xs font-bold text-white/60">BOOSTS</div>
                    </div>
                  </div>
                </motion.div>

                {/* Countdown or Ready Button */}
                <AnimatePresence mode="wait">
                  {phase === 'countdown' ? (
                    <motion.div
                      key="countdown"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      exit={{ scale: 0 }}
                      className="flex items-center justify-center"
                    >
                      <motion.div
                        animate={{ scale: [1, 1.2, 1] }}
                        transition={{ duration: 1, repeat: Infinity }}
                        className="w-32 h-32 bg-[#39FF14] border-6 border-black rounded-full flex items-center justify-center shadow-[0_8px_0_rgba(0,0,0,0.8)]"
                      >
                        <span className="text-7xl font-black text-black">{countdown}</span>
                      </motion.div>
                    </motion.div>
                  ) : (
                    <motion.button
                      key="ready"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={handleReady}
                      className="w-full py-5 bg-[#39FF14] border-4 border-black rounded-2xl font-black text-2xl text-black shadow-[0_6px_0_rgba(0,0,0,0.8)] active:translate-y-1 transition-all"
                      style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.1)' }}
                    >
                      READY!
                    </motion.button>
                  )}
                </AnimatePresence>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Bottom Safe Area */}
        <div className="h-8" />
      </div>
    </div>
  );
}

function StatRow({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="flex justify-between items-center">
      <span className="text-xs font-bold text-white/70">{label}</span>
      <span className={`text-sm font-black ${color}`}>{value}</span>
    </div>
  );
}

function BackIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M15 18L9 12L15 6" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function SwordsIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M14.5 6.5L17.5 3.5L20.5 6.5L17.5 9.5L14.5 6.5Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="currentColor"/>
      <path d="M4 20L9 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M14.5 6.5L9 12L12 15L17.5 9.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M3 21L6 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M6.5 17.5L3.5 20.5L6.5 20.5L6.5 17.5Z" fill="currentColor"/>
      <path d="M18 6L15 9" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}