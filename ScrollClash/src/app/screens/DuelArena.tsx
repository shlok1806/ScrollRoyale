import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useNavigate } from 'react-router';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';
import { useMatch } from '../../contexts/MatchContext';
import { fetchContentFeed } from '../../services/contentService';
import * as syncService from '../../services/syncService';
import type { ScoreSnapshot } from '../../lib/gameTypes';

const VIDEO_DURATION = 10; // 10 seconds per video

export default function DuelArena() {
  const navigate = useNavigate();
  const { customization } = useBrainCustomization();
  const matchCtx = useMatch();
  const match = matchCtx.currentMatch;
  const matchDuration = match?.durationSec ?? 90;

  const [timeLeft, setTimeLeft] = useState(matchDuration);
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0);
  const [videoTimeLeft, setVideoTimeLeft] = useState(VIDEO_DURATION);
  const [yourHP, setYourHP] = useState(1000);
  const [opponentHP, setOpponentHP] = useState(1000);
  const [bankedDamage, setBankedDamage] = useState(0);
  const [comboMeter, setComboMeter] = useState(2);
  const [multiplier, setMultiplier] = useState(1.0);
  const [focusMeter, setFocusMeter] = useState(6);
  const [reactionActive, setReactionActive] = useState(false);
  const [damagePopups, setDamagePopups] = useState<Array<{ id: number; damage: number; isYou: boolean }>>([]);
  const containerRef = useRef<HTMLDivElement>(null);
  const touchStartY = useRef(0);
  const totalVideos = Math.max(matchCtx.contentFeed.length, 1);

  // Opponent data
  const opponent = {
    name: match?.player2Id?.slice(0, 10) ?? 'SkibidiSlayer99',
    rank: 217,
    customization: {
      skin: 'toxic',
      expression: 'focused',
    },
  };

  // Boost deck
  const boostDeck = [
    { id: 1, name: 'Shield', focusCost: 3, cooldown: 0, available: true },
    { id: 2, name: 'Double', focusCost: 5, cooldown: 3, available: false },
    { id: 3, name: 'Freeze', focusCost: 4, cooldown: 0, available: true },
    { id: 4, name: 'Rage', focusCost: 6, cooldown: 5, available: false },
  ];

  // On mount: fetch content feed + connect sync service
  useEffect(() => {
    if (!match) return;

    fetchContentFeed(match.id)
      .then((items) => matchCtx.setContentFeed(items))
      .catch(() => {/* use empty feed fallback */});

    const onScore = (snapshot: ScoreSnapshot) => {
      matchCtx.setLatestScore(snapshot);
      // Derive HP from score: score maps to remaining HP (max 1000)
      const hp = Math.max(0, 1000 - Math.floor(snapshot.score));
      setYourHP(hp);
    };

    syncService.connect(match.id, matchCtx.userId ?? 'anonymous', onScore);

    return () => {
      syncService.disconnect();
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [match?.id]);

  // Match timer
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          setTimeout(() => navigate('/duel/result'), 500);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [navigate]);

  // Video timer and auto-advance
  useEffect(() => {
    const videoTimer = setInterval(() => {
      setVideoTimeLeft((prev) => {
        if (prev <= 1) {
          if (currentVideoIndex < totalVideos - 1) {
            setCurrentVideoIndex(currentVideoIndex + 1);
            applyBankedDamage();
          }
          return VIDEO_DURATION;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(videoTimer);
  }, [currentVideoIndex, totalVideos]);

  // Banked damage calculation
  useEffect(() => {
    const watchTime = VIDEO_DURATION - videoTimeLeft;
    if (watchTime >= 7) {
      setBankedDamage(50);
    } else if (watchTime >= 5) {
      setBankedDamage(30);
    } else if (watchTime >= 2) {
      setBankedDamage(10);
    } else {
      setBankedDamage(0);
    }
  }, [videoTimeLeft]);

  // Reaction button activation
  useEffect(() => {
    const watchTime = VIDEO_DURATION - videoTimeLeft;
    setReactionActive(watchTime >= 2);
  }, [videoTimeLeft]);

  // Increase focus over time
  useEffect(() => {
    const interval = setInterval(() => {
      setFocusMeter(prev => Math.min(10, prev + 1));
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  // Sync opponentHP from opponent score when latestScore updates
  useEffect(() => {
    if (matchCtx.opponentScore) {
      const hp = Math.max(0, 1000 - Math.floor(matchCtx.opponentScore.score));
      setOpponentHP(hp);
    }
  }, [matchCtx.opponentScore]);

  const applyBankedDamage = () => {
    const finalDamage = Math.floor(bankedDamage * multiplier);
    if (finalDamage > 0) {
      setOpponentHP(prev => Math.max(0, prev - finalDamage));
      addDamagePopup(finalDamage, false);
      // Increase combo
      setComboMeter(prev => Math.min(5, prev + 1));
      setMultiplier(prev => Math.min(3.0, prev + 0.2));
    }
    setBankedDamage(0);
  };

  const addDamagePopup = (damage: number, isYou: boolean) => {
    const id = Date.now();
    setDamagePopups(prev => [...prev, { id, damage, isYou }]);
    setTimeout(() => {
      setDamagePopups(prev => prev.filter(p => p.id !== id));
    }, 1500);
  };

  const handleSwipe = (direction: 'up' | 'down') => {
    if (direction === 'up' && currentVideoIndex < totalVideos - 1) {
      const nextIndex = currentVideoIndex + 1;
      setCurrentVideoIndex(nextIndex);
      setVideoTimeLeft(VIDEO_DURATION);
      applyBankedDamage();
      // Send game state telemetry
      const reelId = matchCtx.contentFeed[nextIndex]?.id;
      syncService.sendGameState(
        {
          scrollOffset: nextIndex * 100,
          scrollVelocity: 1,
          currentVideoIndex: nextIndex,
          videoPlaybackTime: 0,
          lastUpdated: new Date().toISOString(),
        },
        reelId,
        match?.id
      );
    } else if (direction === 'down' && currentVideoIndex > 0) {
      const prevIndex = currentVideoIndex - 1;
      setCurrentVideoIndex(prevIndex);
      setVideoTimeLeft(VIDEO_DURATION);
      setBankedDamage(0);
      const reelId = matchCtx.contentFeed[prevIndex]?.id;
      syncService.sendGameState(
        {
          scrollOffset: prevIndex * 100,
          scrollVelocity: -1,
          currentVideoIndex: prevIndex,
          videoPlaybackTime: 0,
          lastUpdated: new Date().toISOString(),
        },
        reelId,
        match?.id
      );
    }
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndY = e.changedTouches[0].clientY;
    const diff = touchStartY.current - touchEndY;
    
    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        handleSwipe('up');
      } else {
        handleSwipe('down');
      }
    }
  };

  const handleBoostClick = (boost: typeof boostDeck[0]) => {
    if (boost.available && focusMeter >= boost.focusCost) {
      setFocusMeter(prev => prev - boost.focusCost);
      // Apply boost effect (placeholder)
      console.log('Activated boost:', boost.name);
    }
  };

  const timerProgress = (timeLeft / matchDuration) * 100;
  const yourHPPercent = (yourHP / 1000) * 100;
  const opponentHPPercent = (opponentHP / 1000) * 100;

  return (
    <div className="h-screen relative text-white overflow-hidden" ref={containerRef}>
      {/* Video Feed Container */}
      <div 
        className="absolute inset-0"
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={currentVideoIndex}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '-100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="h-full w-full"
          >
            <VideoPlaceholder
              videoNumber={currentVideoIndex + 1}
              videoURL={matchCtx.contentFeed[currentVideoIndex]?.videoURL}
            />
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Top gradient overlay for readability */}
      <div className="absolute top-0 left-0 right-0 h-64 bg-gradient-to-b from-black/80 via-black/40 to-transparent pointer-events-none z-10" />
      
      {/* Bottom gradient overlay for readability */}
      <div className="absolute bottom-0 left-0 right-0 h-64 bg-gradient-to-t from-black/80 via-black/40 to-transparent pointer-events-none z-10" />

      {/* TOP HUD - Score Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 pt-12 px-4">
        {/* Forfeit Button - Top Right */}
        <motion.button
          whileTap={{ scale: 0.9 }}
          onClick={() => navigate('/duel/result')}
          className="absolute top-12 right-4 px-4 py-2 bg-[#FF006E] border-3 border-black rounded-xl font-black text-xs text-white shadow-[0_3px_0_rgba(0,0,0,0.8)] active:translate-y-1 z-30"
        >
          FORFEIT
        </motion.button>

        {/* Player Avatars */}
        <div className="flex items-start justify-between mb-3">
          {/* You - Left */}
          <div className="flex items-center gap-2">
            <div className="w-14 h-14 bg-[#7B2CBF] border-3 border-black rounded-full flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)] overflow-hidden">
              <BrainCharacter customization={customization} size={44} rotLevel={25} showArms={false} />
            </div>
            <div>
              <div className="font-black text-sm text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.8)' }}>YOU</div>
              <div className="text-xs font-bold text-[#39FF14]">#{42}</div>
            </div>
          </div>

          {/* Opponent - Right */}
          <div className="flex items-center gap-2">
            <div>
              <div className="font-black text-sm text-white text-right" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.8)' }}>{opponent.name}</div>
              <div className="text-xs font-bold text-[#FF006E] text-right">#{opponent.rank}</div>
            </div>
            <div className="w-14 h-14 bg-[#FF006E] border-3 border-black rounded-full flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)] overflow-hidden">
              <BrainCharacter customization={opponent.customization} size={44} rotLevel={65} showArms={false} />
            </div>
          </div>
        </div>

        {/* Timer Ring - Center */}
        <div className="flex flex-col items-center mb-3">
          <div className="relative w-20 h-20 mb-2">
            <svg className="transform -rotate-90 w-20 h-20">
              <circle
                cx="40"
                cy="40"
                r="35"
                stroke="rgba(255, 255, 255, 0.1)"
                strokeWidth="6"
                fill="none"
              />
              <motion.circle
                cx="40"
                cy="40"
                r="35"
                stroke="#39FF14"
                strokeWidth="6"
                fill="none"
                strokeLinecap="round"
                strokeDasharray={`${2 * Math.PI * 35}`}
                strokeDashoffset={`${2 * Math.PI * 35 * (1 - timerProgress / 100)}`}
                style={{
                  filter: 'drop-shadow(0 0 10px rgba(57, 255, 20, 0.8))'
                }}
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-2xl font-black text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.8)' }}>{timeLeft}</span>
            </div>
          </div>

          {/* HP Comparison Bar */}
          <div className="w-full max-w-sm">
            <div className="flex justify-between text-xs mb-1">
              <span className="font-black text-[#7B2CBF]">{yourHP}</span>
              <span className="font-black text-[#39FF14]">{opponentHP}</span>
            </div>
            <div className="h-4 bg-black/60 border-3 border-black rounded-full overflow-hidden flex shadow-[0_3px_0_rgba(0,0,0,0.8)]">
              <motion.div
                animate={{ width: `${yourHPPercent}%` }}
                className="h-full bg-[#7B2CBF]"
                style={{
                  boxShadow: 'inset 0 0 10px rgba(123, 44, 191, 0.6)'
                }}
              />
              <motion.div
                animate={{ width: `${opponentHPPercent}%` }}
                className="h-full bg-[#39FF14]"
                style={{
                  boxShadow: 'inset 0 0 10px rgba(57, 255, 20, 0.6)'
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Damage Popups */}
      <AnimatePresence>
        {damagePopups.map(popup => (
          <motion.div
            key={popup.id}
            initial={{ y: 0, opacity: 0, scale: 0.5 }}
            animate={{ y: -80, opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 1 }}
            className={`absolute z-30 ${popup.isYou ? 'left-20 top-32' : 'right-20 top-32'}`}
          >
            <div className={`px-3 py-1 border-3 border-black rounded-lg font-black text-lg shadow-[0_3px_0_rgba(0,0,0,0.8)] ${
              popup.isYou ? 'bg-[#FF006E] text-white' : 'bg-[#39FF14] text-black'
            }`}>
              -{popup.damage}
            </div>
          </motion.div>
        ))}
      </AnimatePresence>

      {/* VIDEO OVERLAYS */}
      <div className="absolute inset-0 z-15 pointer-events-none">
        {/* Top-left: Combo Meter + Multiplier */}
        <div className="absolute top-44 left-4">
          <div className="bg-black/60 border-3 border-black rounded-xl p-2 shadow-[0_3px_0_rgba(0,0,0,0.8)]">
            <div className="text-xs font-bold text-white/70 mb-1">COMBO</div>
            <div className="flex gap-1 mb-2">
              {[...Array(5)].map((_, i) => (
                <div
                  key={i}
                  className={`w-3 h-3 rounded-full border-2 border-black ${
                    i < comboMeter ? 'bg-[#FFD60A] shadow-[0_0_8px_rgba(255,214,10,0.8)]' : 'bg-white/20'
                  }`}
                />
              ))}
            </div>
            <div className="text-xl font-black text-[#FFD60A]">x{multiplier.toFixed(1)}</div>
          </div>
        </div>

        {/* Bottom-left: Focus Meter */}
        <div className="absolute bottom-48 left-4">
          <div className="bg-black/60 border-3 border-black rounded-xl p-2 shadow-[0_3px_0_rgba(0,0,0,0.8)]">
            <div className="text-xs font-bold text-white/70 mb-1">FOCUS</div>
            <div className="grid grid-cols-5 gap-1">
              {[...Array(10)].map((_, i) => (
                <div
                  key={i}
                  className={`w-3 h-3 rounded-full border-2 border-black ${
                    i < focusMeter ? 'bg-[#4CC9F0] shadow-[0_0_8px_rgba(76,201,240,0.8)]' : 'bg-white/20'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Right side: Reaction + Indicators */}
        <div className="absolute right-4 top-1/2 transform -translate-y-1/2 flex flex-col gap-3 pointer-events-auto">
          {/* Reaction Button */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            disabled={!reactionActive}
            className={`w-14 h-14 rounded-full border-4 border-black flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)] ${
              reactionActive ? 'bg-[#FF006E] cursor-pointer' : 'bg-white/20 cursor-not-allowed'
            }`}
            style={{
              boxShadow: reactionActive ? '0 4px 0 rgba(0,0,0,0.8), 0 0 20px rgba(255,0,110,0.8)' : '0 4px 0 rgba(0,0,0,0.8)'
            }}
          >
            <ThumbsUpIcon size={24} className="text-white" />
          </motion.button>

          {/* Quiz Indicator */}
          <div className="w-14 h-14 bg-[#FFD60A]/80 border-4 border-black rounded-full flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
            <QuizIcon size={24} className="text-black" />
          </div>

          {/* Discovery Progress */}
          <div className="bg-black/60 border-3 border-black rounded-xl p-2 shadow-[0_3px_0_rgba(0,0,0,0.8)]">
            <div className="flex flex-col gap-1">
              {[...Array(3)].map((_, i) => (
                <div
                  key={i}
                  className={`w-2 h-2 rounded-full border border-black ${
                    i < 2 ? 'bg-[#39FF14]' : 'bg-white/20'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Banked Damage Visualization - Center Bottom */}
        <div className="absolute bottom-44 left-1/2 transform -translate-x-1/2 w-64">
          <div className="bg-black/70 border-3 border-black rounded-xl p-3 shadow-[0_4px_0_rgba(0,0,0,0.8)]">
            <div className="flex justify-between items-center mb-2">
              <span className="text-xs font-bold text-white/70">BANKED DAMAGE</span>
              <motion.span 
                key={bankedDamage}
                initial={{ scale: 1.5 }}
                animate={{ scale: 1 }}
                className="text-lg font-black text-[#FF006E]"
              >
                {bankedDamage}
              </motion.span>
            </div>
            {/* Threshold bar */}
            <div className="relative h-2 bg-white/20 rounded-full overflow-hidden">
              <motion.div
                animate={{ width: `${((VIDEO_DURATION - videoTimeLeft) / VIDEO_DURATION) * 100}%` }}
                className="h-full bg-gradient-to-r from-[#39FF14] via-[#FFD60A] to-[#FF006E]"
              />
              {/* Threshold markers */}
              <div className="absolute top-0 h-full w-full flex justify-between px-1">
                <ThresholdMarker active={videoTimeLeft <= 8} position={20} />
                <ThresholdMarker active={videoTimeLeft <= 5} position={50} />
                <ThresholdMarker active={videoTimeLeft <= 3} position={70} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* BOOST DECK - Bottom */}
      <div className="absolute bottom-4 left-0 right-0 z-20 px-4 pointer-events-auto">
        <div className="flex justify-center gap-2">
          {boostDeck.map(boost => (
            <BoostCardMini
              key={boost.id}
              boost={boost}
              onClick={() => handleBoostClick(boost)}
              canAfford={focusMeter >= boost.focusCost}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function VideoPlaceholder({ videoNumber, videoURL }: { videoNumber: number; videoURL?: string }) {
  return (
    <div className="relative w-full h-full bg-black">
      {videoURL ? (
        <video
          src={videoURL}
          className="w-full h-full object-cover"
          autoPlay
          muted
          loop
          playsInline
        />
      ) : (
        <>
          <img src={bgStripes} alt="" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-b from-[#1a0a2e]/60 via-[#0f0520]/40 to-[#050509]/60" />
        </>
      )}
      {/* Placeholder label (shown when no video URL yet) */}
      {!videoURL && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="bg-black/80 border-4 border-white/20 rounded-2xl px-8 py-6 text-center">
            <div className="text-xs font-bold text-white/50 mb-2">MP4 PLACEHOLDER</div>
            <div className="text-4xl font-black text-white">VIDEO {videoNumber}</div>
          </div>
        </div>
      )}
    </div>
  );
}

function ThresholdMarker({ active, position }: { active: boolean; position: number }) {
  return (
    <motion.div
      animate={{ 
        scale: active ? [1, 1.5, 1] : 1,
        opacity: active ? 1 : 0.3
      }}
      transition={{ duration: 0.5 }}
      className={`w-1 h-full rounded-full ${active ? 'bg-white' : 'bg-white/40'}`}
      style={{ 
        position: 'absolute', 
        left: `${position}%`,
        boxShadow: active ? '0 0 10px rgba(255,255,255,0.8)' : 'none'
      }}
    />
  );
}

function BoostCardMini({ 
  boost, 
  onClick, 
  canAfford 
}: { 
  boost: { id: number; name: string; focusCost: number; cooldown: number; available: boolean }; 
  onClick: () => void;
  canAfford: boolean;
}) {
  const isUsable = boost.available && canAfford;
  
  return (
    <motion.button
      whileTap={isUsable ? { scale: 0.95 } : {}}
      onClick={isUsable ? onClick : undefined}
      disabled={!isUsable}
      className={`w-20 h-28 relative ${isUsable ? 'cursor-pointer' : 'cursor-not-allowed'}`}
    >
      <div className={`h-full bg-[#F5F5DC] border-4 border-black rounded-xl shadow-[0_4px_0_rgba(0,0,0,0.8)] overflow-hidden ${
        !isUsable ? 'opacity-50' : ''
      }`}>
        {/* Icon area */}
        <div className="h-16 bg-white border-b-2 border-black flex items-center justify-center relative">
          <BoostIcon name={boost.name} size={32} />
          
          {/* Focus cost badge */}
          <div className="absolute top-1 right-1 flex items-center gap-0.5 bg-[#4CC9F0] border-2 border-black rounded px-1">
            <FocusIcon size={8} />
            <span className="text-[10px] font-black text-black">{boost.focusCost}</span>
          </div>
        </div>
        
        {/* Name */}
        <div className="px-1 py-1 bg-white border-t-2 border-black">
          <div className="text-[10px] font-black text-black text-center">{boost.name}</div>
        </div>

        {/* Cooldown overlay */}
        {boost.cooldown > 0 && (
          <div className="absolute inset-0 bg-black/70 flex items-center justify-center backdrop-blur-sm">
            <div className="text-2xl font-black text-white">{boost.cooldown}s</div>
          </div>
        )}

        {/* Active glow */}
        {isUsable && (
          <motion.div
            animate={{ opacity: [0.3, 0.6, 0.3] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="absolute inset-0 pointer-events-none"
            style={{ 
              background: 'radial-gradient(circle at center, rgba(57,255,20,0.3), transparent 70%)',
            }}
          />
        )}
      </div>
    </motion.button>
  );
}

function BoostIcon({ name, size = 32 }: { name: string; size?: number }) {
  switch (name) {
    case 'Shield':
      return <ShieldIcon size={size} className="text-[#4CC9F0]" />;
    case 'Double':
      return <DoubleIcon size={size} className="text-[#FFD60A]" />;
    case 'Freeze':
      return <FreezeIcon size={size} className="text-[#4CC9F0]" />;
    case 'Rage':
      return <RageIcon size={size} className="text-[#FF006E]" />;
    default:
      return <div style={{ width: size, height: size }} />;
  }
}

// Icon Components
function ThumbsUpIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M7 22V11M2 13V20C2 21.1046 2.89543 22 4 22H17.4262C18.907 22 20.1662 20.9197 20.3914 19.4562L21.4683 12.4562C21.7479 10.6389 20.3418 9 18.5032 9H15V4C15 2.89543 14.1046 2 13 2C12.4477 2 12 2.44772 12 3V3.93137C12 4.59693 11.7239 5.23008 11.2361 5.68377L7.5 9" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function QuizIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2.5" fill="currentColor" opacity="0.2"/>
      <path d="M12 17H12.01M10.5 9.5C10.5 8.11929 11.6193 7 13 7C14.3807 7 15.5 8.11929 15.5 9.5C15.5 10.3906 15.0269 11.1668 14.3065 11.5877C13.5941 12.0043 13 12.6715 13 13.5V14" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function FocusIcon({ size = 10, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="10" fill="currentColor"/>
    </svg>
  );
}

function ShieldIcon({ size = 32, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L4 6V12C4 16.5 7 20.5 12 22C17 20.5 20 16.5 20 12V6L12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="currentColor" opacity="0.3"/>
      <path d="M12 8V12L14 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function DoubleIcon({ size = 32, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="currentColor" strokeWidth="2" fill="currentColor" opacity="0.3"/>
      <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function FreezeIcon({ size = 32, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2V22M17 7L7 17M7 7L17 17M22 12H2M19.5 5.5L4.5 18.5M4.5 5.5L19.5 18.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function RageIcon({ size = 32, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="currentColor" opacity="0.3"/>
    </svg>
  );
}