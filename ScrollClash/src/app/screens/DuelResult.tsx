import React, { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useNavigate } from 'react-router';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';
import { useMatch } from '../../contexts/MatchContext';
import { leaveMatch } from '../../services/matchmakingService';

export default function DuelResult() {
  const navigate = useNavigate();
  const { customization } = useBrainCustomization();
  const matchCtx = useMatch();
  const [showConfetti, setShowConfetti] = useState(false);
  const [animateNumbers, setAnimateNumbers] = useState(false);
  const leftMatchRef = useRef(false);

  // Derive results from real scores (fall back gracefully if context is empty)
  const myScore = matchCtx.latestScore?.score ?? 0;
  const oppScore = matchCtx.opponentScore?.score ?? 0;
  const isVictory = myScore >= oppScore;
  const yourHP = Math.max(0, 1000 - Math.floor(myScore));
  const opponentHP = Math.max(0, 1000 - Math.floor(oppScore));
  const trophyChange = isVictory ? 30 : -18;
  const xpGained = isVictory ? 185 : 95;
  const rankUp = isVictory && myScore > 500;

  // Match stats (derived where possible)
  const stats = {
    damageDealt: Math.floor(myScore),
    damageTaken: Math.floor(oppScore),
    highestCombo: 5,
    videosCompleted: matchCtx.contentFeed.length || 7,
    discoveryPayouts: 3,
    quizzesCorrect: 4,
    focusGained: 28,
    focusSpent: 24,
    boostsPlayed: 6,
    longestStreak: 4,
  };

  // Timeline events
  const timelineEvents = [
    { type: 'damage', time: '0:08' },
    { type: 'quiz-correct', time: '0:22' },
    { type: 'combo', time: '0:35' },
    { type: 'boost', time: '0:47' },
    { type: 'discovery', time: '1:05' },
    { type: 'damage', time: '1:18' },
    { type: 'quiz-wrong', time: '1:31' },
    { type: 'boost', time: '1:44' },
  ];

  // Opponent
  const opponent = {
    name: matchCtx.currentMatch?.player2Id?.slice(0, 12) ?? 'SkibidiSlayer99',
    customization: {
      skin: 'toxic',
      expression: 'focused',
    },
  };

  // On mount: leave match on backend, show result effects
  useEffect(() => {
    const matchId = matchCtx.currentMatch?.id;
    if (matchId && !leftMatchRef.current) {
      leftMatchRef.current = true;
      leaveMatch(matchId).catch(() => {/* best-effort */});
    }

    if (isVictory) {
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 3000);
    }
    setTimeout(() => setAnimateNumbers(true), 500);

    // Auto-redirect after 5 seconds through loading screen
    const redirectTimeout = setTimeout(() => {
      navigate('/loading', { state: { from: 'result' } });
    }, 5000);

    return () => clearTimeout(redirectTimeout);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleRematch = () => {
    matchCtx.clearMatch();
    navigate('/duel');
  };

  const handleHome = () => {
    matchCtx.clearMatch();
    navigate('/');
  };

  return (
    <div className="min-h-screen relative text-white overflow-y-auto">
      {/* Background */}
      <div className="fixed inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/40 to-black/60" />
      </div>

      {/* Confetti Effect */}
      {showConfetti && <ConfettiEffect />}

      {/* Defeat crack overlay */}
      {!isVictory && (
        <div className="fixed inset-0 pointer-events-none opacity-20">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <line x1="0" y1="0" x2="100%" y2="100%" stroke="#FF006E" strokeWidth="2" opacity="0.3"/>
            <line x1="100%" y1="0" x2="0" y2="100%" stroke="#FF006E" strokeWidth="2" opacity="0.3"/>
            <line x1="50%" y1="0" x2="20%" y2="100%" stroke="#FF006E" strokeWidth="1" opacity="0.2"/>
            <line x1="30%" y1="0" x2="70%" y2="100%" stroke="#FF006E" strokeWidth="1" opacity="0.2"/>
          </svg>
        </div>
      )}

      {/* Content */}
      <div className="relative z-10 px-5 py-12">
        {/* TOP SECTION - RESULT HEADER */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: 'spring', stiffness: 200, damping: 20 }}
          className="text-center mb-6"
        >
          {/* Result Text */}
          <motion.div
            initial={{ y: -50 }}
            animate={{ y: 0 }}
            className="relative inline-block mb-6"
          >
            <div
              className="absolute inset-0 blur-3xl"
              style={{
                background: isVictory
                  ? 'radial-gradient(circle, rgba(57,255,20,0.6), transparent)'
                  : 'radial-gradient(circle, rgba(255,0,110,0.6), transparent)',
              }}
            />
            <h1
              className={`relative text-7xl font-black ${
                isVictory ? 'text-[#39FF14]' : 'text-[#FF006E]'
              }`}
              style={{
                textShadow: isVictory
                  ? '0 0 40px rgba(57, 255, 20, 0.9), 3px 3px 0 rgba(0,0,0,0.5)'
                  : '0 0 40px rgba(255, 0, 110, 0.9), 3px 3px 0 rgba(0,0,0,0.5)',
              }}
            >
              {isVictory ? 'VICTORY' : 'DEFEAT'}
            </h1>
          </motion.div>

          {/* VS Section */}
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="flex items-center justify-center gap-4 mb-4"
          >
            {/* You */}
            <div className="flex flex-col items-center">
              <div className="w-20 h-20 bg-[#7B2CBF] border-4 border-black rounded-full flex items-center justify-center shadow-[0_6px_0_rgba(0,0,0,0.8)] overflow-hidden mb-2">
                <BrainCharacter customization={customization} size={60} rotLevel={25} showArms={false} />
              </div>
              <div className="text-sm font-black text-white">YOU</div>
            </div>

            {/* VS Badge */}
            <div className="w-12 h-12 bg-white border-4 border-black rounded-full flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
              <span className="text-xl font-black text-black">VS</span>
            </div>

            {/* Opponent */}
            <div className="flex flex-col items-center">
              <div className="w-20 h-20 bg-[#FF006E] border-4 border-black rounded-full flex items-center justify-center shadow-[0_6px_0_rgba(0,0,0,0.8)] overflow-hidden mb-2">
                <BrainCharacter customization={opponent.customization} size={60} rotLevel={65} showArms={false} />
              </div>
              <div className="text-sm font-black text-white">{opponent.name.toUpperCase()}</div>
            </div>
          </motion.div>
        </motion.div>

        {/* TOWER RESULTS */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="mb-6"
        >
          <div className="bg-black/60 border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="text-xs font-bold text-white/70 text-center mb-3">TOWER HP</div>
            <div className="flex justify-between gap-4 mb-2">
              <div className="flex-1 text-center">
                <div className="text-sm font-black text-[#7B2CBF] mb-1">YOUR TOWER</div>
                <AnimatedNumber value={yourHP} duration={1000} className="text-2xl font-black text-white" />
                <span className="text-sm text-white/50"> / 1000</span>
              </div>
              <div className="flex-1 text-center">
                <div className="text-sm font-black text-[#39FF14] mb-1">OPP TOWER</div>
                <AnimatedNumber value={opponentHP} duration={1000} className="text-2xl font-black text-white" />
                <span className="text-sm text-white/50"> / 1000</span>
              </div>
            </div>
            {/* HP Bars */}
            <div className="flex gap-2">
              <div className="flex-1 h-3 bg-black/60 rounded-full overflow-hidden border-2 border-black">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${(yourHP / 1000) * 100}%` }}
                  transition={{ delay: 0.5, duration: 1 }}
                  className="h-full bg-[#7B2CBF]"
                  style={{ boxShadow: 'inset 0 0 10px rgba(123,44,191,0.8)' }}
                />
              </div>
              <div className="flex-1 h-3 bg-black/60 rounded-full overflow-hidden border-2 border-black">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${(opponentHP / 1000) * 100}%` }}
                  transition={{ delay: 0.5, duration: 1 }}
                  className="h-full bg-[#39FF14]"
                  style={{ boxShadow: 'inset 0 0 10px rgba(57,255,20,0.8)' }}
                />
              </div>
            </div>
          </div>
        </motion.div>

        {/* MATCH SUMMARY STATS PANEL */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="mb-6"
        >
          <div className="bg-[#7B2CBF] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="text-sm font-black text-white text-center mb-4">MATCH STATS</div>
            <div className="grid grid-cols-2 gap-3">
              <StatItem icon={<DamageIcon size={20} />} label="Damage Dealt" value={stats.damageDealt} animate={animateNumbers} />
              <StatItem icon={<QuizIcon size={20} />} label="Quizzes" value={stats.quizzesCorrect} animate={animateNumbers} />
              <StatItem icon={<ShieldIcon size={20} />} label="Damage Taken" value={stats.damageTaken} animate={animateNumbers} />
              <StatItem icon={<FocusIconStat size={20} />} label="Focus Gained" value={stats.focusGained} animate={animateNumbers} />
              <StatItem icon={<ComboIcon size={20} />} label="Highest Combo" value={stats.highestCombo} animate={animateNumbers} />
              <StatItem icon={<FocusIconStat size={20} />} label="Focus Spent" value={stats.focusSpent} animate={animateNumbers} />
              <StatItem icon={<VideoIcon size={20} />} label="Videos Done" value={stats.videosCompleted} animate={animateNumbers} />
              <StatItem icon={<BoostIcon size={20} />} label="Boosts Used" value={stats.boostsPlayed} animate={animateNumbers} />
              <StatItem icon={<DiamondIcon size={20} />} label="Discovery" value={stats.discoveryPayouts} animate={animateNumbers} />
              <StatItem icon={<StreakIcon size={20} />} label="Best Streak" value={stats.longestStreak} animate={animateNumbers} />
            </div>
          </div>
        </motion.div>

        {/* MATCH TIMELINE */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="mb-6"
        >
          <div className="bg-black/60 border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="text-sm font-black text-white mb-3">BATTLE TIMELINE</div>
            <div className="relative overflow-x-auto pb-2">
              <div className="flex items-center gap-3 min-w-max">
                {/* Timeline line */}
                <div className="absolute top-1/2 left-0 right-0 h-1 bg-white/20 transform -translate-y-1/2" />
                
                {timelineEvents.map((event, i) => (
                  <motion.div
                    key={i}
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.6 + i * 0.1 }}
                    className="relative flex flex-col items-center z-10"
                  >
                    <div className={`w-10 h-10 rounded-full border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)] ${getEventColor(event.type)}`}>
                      {getEventIcon(event.type, 20)}
                    </div>
                    <div className="text-[10px] font-bold text-white/70 mt-1">{event.time}</div>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {/* REWARDS SECTION */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="mb-6"
        >
          <div className="text-sm font-black text-white text-center mb-3">REWARDS</div>
          <div className="space-y-3">
            {/* Trophy */}
            <motion.div
              whileHover={{ scale: 1.02 }}
              className="bg-[#FFD60A] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)] flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-white border-3 border-black rounded-full flex items-center justify-center">
                  <TrophyIcon size={28} className="text-[#FFD60A]" />
                </div>
                <span className="font-black text-black">TROPHIES</span>
              </div>
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.8, type: 'spring', stiffness: 300 }}
                className={`text-4xl font-black ${isVictory ? 'text-[#39FF14]' : 'text-[#FF006E]'}`}
                style={{
                  textShadow: '2px 2px 0 rgba(0,0,0,0.3)'
                }}
              >
                {trophyChange > 0 ? '+' : ''}{trophyChange}
              </motion.div>
            </motion.div>

            {/* XP Progress */}
            <div className="bg-[#4CC9F0] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
              <div className="flex items-center justify-between mb-2">
                <span className="font-black text-black">XP GAINED</span>
                <span className="text-2xl font-black text-white">+{xpGained}</span>
              </div>
              <div className="relative h-4 bg-black/40 border-2 border-black rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: '52%' }}
                  animate={{ width: '78%' }}
                  transition={{ delay: 0.9, duration: 1.2 }}
                  className="h-full bg-gradient-to-r from-[#39FF14] to-[#FFD60A]"
                  style={{ boxShadow: 'inset 0 0 10px rgba(57,255,20,0.8)' }}
                />
                <div className="absolute inset-0 flex items-center justify-center text-xs font-black text-white">
                  LEVEL 12
                </div>
              </div>
            </div>

            {/* Rank Up Banner */}
            {rankUp && (
              <motion.div
                initial={{ scale: 0, rotate: -10 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ delay: 1.1, type: 'spring', stiffness: 200 }}
                className="bg-gradient-to-r from-[#FF006E] to-[#7B2CBF] border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)] text-center relative overflow-hidden"
              >
                <motion.div
                  animate={{ x: ['-100%', '200%'] }}
                  transition={{ duration: 2, repeat: Infinity, ease: 'linear' }}
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent"
                  style={{ width: '50%' }}
                />
                <div className="text-3xl font-black text-white mb-1" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
                  RANK UP!
                </div>
                <div className="text-sm font-bold text-white/90">Diamond III → Diamond II</div>
              </motion.div>
            )}
          </div>
        </motion.div>

        {/* MVP BOOST HIGHLIGHT */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="mb-6"
        >
          <div className="bg-black/60 border-4 border-black rounded-2xl p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="text-xs font-bold text-white/70 text-center mb-3">MVP BOOST</div>
            <div className="flex items-center gap-3">
              {/* Mini boost card */}
              <div className="w-16 h-20 bg-[#F5F5DC] border-3 border-black rounded-xl overflow-hidden shadow-[0_3px_0_rgba(0,0,0,0.6)]">
                <div className="h-12 bg-white border-b-2 border-black flex items-center justify-center">
                  <RageBoostIcon size={24} />
                </div>
                <div className="px-1 py-1 bg-white">
                  <div className="text-[8px] font-black text-black text-center">RAGE</div>
                </div>
              </div>
              {/* Stats */}
              <div className="flex-1">
                <div className="text-sm font-black text-white mb-1">Rage</div>
                <div className="flex gap-3 text-xs">
                  <div>
                    <span className="text-white/70">Used:</span>
                    <span className="font-black text-[#FFD60A] ml-1">3x</span>
                  </div>
                  <div>
                    <span className="text-white/70">Damage:</span>
                    <span className="font-black text-[#FF006E] ml-1">+84</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* ACTION BUTTONS */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.8 }}
          className="space-y-3 pb-8"
        >
          {/* Rematch */}
          <motion.button
            whileTap={{ scale: 0.97 }}
            onClick={handleRematch}
            className="w-full py-5 bg-[#39FF14] border-4 border-black rounded-2xl font-black text-2xl text-black shadow-[0_6px_0_rgba(0,0,0,0.8)] active:translate-y-1 transition-all"
            style={{
              textShadow: '2px 2px 0 rgba(0,0,0,0.1)',
              boxShadow: '0 6px 0 rgba(0,0,0,0.8), 0 0 30px rgba(57,255,20,0.6)'
            }}
          >
            REMATCH
          </motion.button>

          {/* Secondary buttons */}
          <div className="flex gap-3">
            <motion.button
              whileTap={{ scale: 0.95 }}
              className="flex-1 py-4 bg-[#4CC9F0] border-4 border-black rounded-2xl font-black text-sm text-black shadow-[0_4px_0_rgba(0,0,0,0.8)] active:translate-y-1"
            >
              VIEW REPLAY
            </motion.button>
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={handleHome}
              className="flex-1 py-4 bg-white/20 border-4 border-black rounded-2xl font-black text-sm text-white shadow-[0_4px_0_rgba(0,0,0,0.8)] active:translate-y-1"
            >
              HOME
            </motion.button>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

// Animated Number Component
function AnimatedNumber({ value, duration = 1000, className = '' }: { value: number; duration?: number; className?: string }) {
  const [displayValue, setDisplayValue] = useState(0);

  useEffect(() => {
    let startTime: number | null = null;
    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      setDisplayValue(Math.floor(progress * value));
      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };
    requestAnimationFrame(animate);
  }, [value, duration]);

  return <span className={className}>{displayValue}</span>;
}

// Stat Item Component
function StatItem({ icon, label, value, animate }: { icon: React.ReactNode; label: string; value: number; animate: boolean }) {
  return (
    <div className="bg-black/40 border-2 border-black rounded-xl p-2">
      <div className="flex items-center gap-2 mb-1">
        <div className="text-white">{icon}</div>
        <div className="text-[10px] font-bold text-white/70 leading-tight">{label}</div>
      </div>
      {animate ? (
        <AnimatedNumber value={value} duration={1500} className="text-xl font-black text-white" />
      ) : (
        <div className="text-xl font-black text-white">{value}</div>
      )}
    </div>
  );
}

// Timeline Event Helpers
function getEventColor(type: string): string {
  switch (type) {
    case 'damage': return 'bg-[#FF006E]';
    case 'quiz-correct': return 'bg-[#39FF14]';
    case 'quiz-wrong': return 'bg-[#FF006E]';
    case 'combo': return 'bg-[#FFD60A]';
    case 'discovery': return 'bg-[#7B2CBF]';
    case 'boost': return 'bg-[#4CC9F0]';
    default: return 'bg-white';
  }
}

function getEventIcon(type: string, size: number): React.ReactNode {
  switch (type) {
    case 'damage': return <DamageIcon size={size} className="text-white" />;
    case 'quiz-correct': return <QuizIcon size={size} className="text-black" />;
    case 'quiz-wrong': return <CloseIcon size={size} className="text-white" />;
    case 'combo': return <ComboIcon size={size} className="text-black" />;
    case 'discovery': return <DiamondIcon size={size} className="text-white" />;
    case 'boost': return <BoostIcon size={size} className="text-black" />;
    default: return null;
  }
}

// Confetti Effect
function ConfettiEffect() {
  const confettiPieces = Array.from({ length: 80 });

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden z-50">
      {confettiPieces.map((_, i) => (
        <motion.div
          key={i}
          initial={{
            x: Math.random() * window.innerWidth,
            y: -20,
            rotate: 0,
            opacity: 1,
          }}
          animate={{
            y: window.innerHeight + 20,
            rotate: Math.random() * 720,
            opacity: 0,
          }}
          transition={{
            duration: Math.random() * 2 + 2,
            delay: Math.random() * 0.5,
            ease: 'linear',
          }}
          className="absolute w-3 h-3"
          style={{
            backgroundColor: ['#39FF14', '#FFD60A', '#4CC9F0', '#FF006E', '#7B2CBF'][Math.floor(Math.random() * 5)],
            borderRadius: Math.random() > 0.5 ? '50%' : '0',
          }}
        />
      ))}
    </div>
  );
}

// Icon Components
function DamageIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function ShieldIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L4 6V12C4 16.5 7 20.5 12 22C17 20.5 20 16.5 20 12V6L12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function ComboIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function VideoIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <rect x="2" y="6" width="20" height="12" rx="2" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
      <path d="M10 9L15 12L10 15V9Z" fill="white"/>
    </svg>
  );
}

function DiamondIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L2 9L12 22L22 9L12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function QuizIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
      <path d="M12 17H12.01M10.5 9.5C10.5 8.11929 11.6193 7 13 7C14.3807 7 15.5 8.11929 15.5 9.5C15.5 10.5 14 11 13 12V13" stroke="white" strokeWidth="2" strokeLinecap="round"/>
    </svg>
  );
}

function FocusIconStat({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
      <circle cx="12" cy="12" r="4" fill="white"/>
    </svg>
  );
}

function BoostIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function StreakIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2C12 2 5 8 5 14C5 18.4183 8.58172 22 13 22C17.4183 22 21 18.4183 21 14C21 8 12 2 12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor"/>
    </svg>
  );
}

function TrophyIcon({ size = 28, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M6 9H4C4 12 5 14 8 14M18 9H20C20 12 19 14 16 14M8 14C8 14 8 22 12 22C16 22 16 14 16 14M8 14H16M12 2C14.2091 2 16 3.79086 16 6V9H8V6C8 3.79086 9.79086 2 12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="currentColor"/>
    </svg>
  );
}

function CloseIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
    </svg>
  );
}

function RageBoostIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" stroke="#FF006E" strokeWidth="2" fill="#FF006E"/>
    </svg>
  );
}