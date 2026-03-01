import React from 'react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import { TrophyIcon, TargetIcon, ZapIcon, StarIcon, SettingsIcon, FlameIcon, CrownIcon } from '../../shared/components/GameIcons';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

const badges = [
  { name: 'First Win', color: '#FFD60A' },
  { name: '7 Day', color: '#FF6B35' },
  { name: 'Speed', color: '#4CC9F0' },
  { name: 'Top 10', color: '#39FF14' },
  { name: 'Precision', color: '#F72585' },
  { name: 'Flawless', color: '#9D4EDD' },
  { name: 'Rising', color: '#FFD60A' },
  { name: 'Master', color: '#7B2CBF' },
];

const brainSkins = [
  { name: 'Classic', color: '#FFB3D1', owned: true },
  { name: 'Cyber', color: '#4CC9F0', owned: true },
  { name: 'Cosmic', color: '#9D4EDD', owned: true },
  { name: 'Inferno', color: '#FF6B35', owned: false },
  { name: 'Diamond', color: '#4895EF', owned: false },
  { name: 'Rainbow', color: '#FFD60A', owned: false },
];

export default function Profile() {
  const navigate = useNavigate();
  const { customization } = useBrainCustomization();

  return (
    <div className="h-screen relative text-white overflow-hidden flex flex-col">
      {/* Striped Background */}
      <div className="absolute inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-black/20" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col h-full">
        {/* iOS Status Bar */}
        <div className="h-12" />

        {/* Header */}
        <div className="px-5 mb-3 flex-shrink-0">
          <div className="flex justify-end mb-3">
            <motion.button
              whileTap={{ scale: 0.9 }}
              className="w-10 h-10 rounded-full bg-[#7B2CBF] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]"
            >
              <SettingsIcon size={18} className="text-white" />
            </motion.button>
          </div>

          {/* Profile Header */}
          <div className="text-center mb-4">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 200 }}
              className="relative inline-block mb-3"
            >
              <div className="w-28 h-28 rounded-full bg-gradient-to-br from-[#39FF14] to-[#4CC9F0] border-4 border-black shadow-[0_6px_0_rgba(0,0,0,0.8)] flex items-center justify-center overflow-hidden">
                <BrainCharacter rotLevel={15} size={100} showArms={false} customization={customization} />
              </div>
              {/* Level Badge */}
              <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 px-3 py-0.5 bg-[#FFD60A] border-2 border-black rounded-full font-black text-xs text-black shadow-[0_2px_0_rgba(0,0,0,0.6)]">
                LVL 12
              </div>
            </motion.div>

            <h1 className="text-2xl font-black mb-1 text-white" style={{ textShadow: '3px 3px 0 rgba(0,0,0,0.5)' }}>
              BrainMaster
            </h1>
            <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#39FF14] border-2 border-black rounded-full mb-3">
              <CrownIcon size={16} className="text-black" />
              <span className="text-xs font-black text-black">ALGORITHM OVERLORD</span>
            </div>

            {/* Customize Brain Button */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => navigate('/brain-lab')}
              className="px-4 py-2 bg-[#FF006E] border-3 border-black rounded-xl font-black text-sm text-white shadow-[0_4px_0_rgba(0,0,0,0.8)] hover:brightness-110 active:translate-y-1 transition-all"
            >
              CUSTOMIZE BRAIN
            </motion.button>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-3 gap-2 mb-4">
            <div className="rounded-xl bg-[#39FF14] border-3 border-black p-3 text-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
              <TrophyIcon size={20} className="text-black mx-auto mb-1" />
              <div className="text-xl font-black text-black">1,204</div>
              <div className="text-[9px] font-bold text-black">TROPHIES</div>
            </div>
            <div className="rounded-xl bg-[#FF006E] border-3 border-black p-3 text-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
              <TargetIcon size={20} className="text-white mx-auto mb-1" />
              <div className="text-xl font-black text-white">68%</div>
              <div className="text-[9px] font-bold text-white">WIN RATE</div>
            </div>
            <div className="rounded-xl bg-[#4CC9F0] border-3 border-black p-3 text-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
              <ZapIcon size={20} className="text-black mx-auto mb-1" />
              <div className="text-xl font-black text-black">127</div>
              <div className="text-[9px] font-bold text-black">DUELS</div>
            </div>
          </div>

          {/* Performance Stats */}
          <div className="rounded-2xl bg-[#7B2CBF] border-4 border-black p-4 mb-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <h3 className="font-black text-sm mb-3 text-white flex items-center gap-2">
              <StarIcon size={16} className="text-[#FFD60A]" />
              PERFORMANCE
            </h3>
            <div className="space-y-2">
              <StatLine label="Current Rank" value="#12 Global" />
              <StatLine label="Best Streak" value="12 days" />
              <StatLine label="Best Stability" value="98%" />
              <StatLine label="Avg Rot" value="39%" />
            </div>
          </div>
        </div>

        {/* Badges Carousel */}
        <div className="mb-4 flex-shrink-0">
          <div className="px-5 mb-2">
            <h2 className="text-base font-black text-white flex items-center gap-2">
              <AwardBadgeIcon size={20} className="text-[#FFD60A]" />
              BADGES
            </h2>
          </div>
          
          <div className="flex gap-2 overflow-x-auto pb-2 px-5 scrollbar-hide">
            {badges.map((badge, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: idx * 0.05 }}
                whileTap={{ scale: 0.95 }}
                className="flex-shrink-0"
              >
                <div 
                  className="w-20 rounded-xl border-3 border-black p-3 text-center shadow-[0_4px_0_rgba(0,0,0,0.8)]"
                  style={{ backgroundColor: badge.color }}
                >
                  <div className="mb-1 flex justify-center">
                    <TrophyIcon size={28} className="text-black" />
                  </div>
                  <div className="text-[9px] font-black text-black">{badge.name}</div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Brain Skins */}
        <div className="px-5 flex-shrink-0 pb-24">
          <h2 className="text-base font-black text-white mb-3 flex items-center gap-2">
            <PaletteIcon size={20} className="text-[#FF006E]" />
            BRAIN SKINS
          </h2>
          
          <div className="grid grid-cols-3 gap-2">
            {brainSkins.map((skin, idx) => (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <div className={`rounded-xl border-3 border-black p-3 text-center shadow-[0_4px_0_rgba(0,0,0,0.8)] ${!skin.owned && 'opacity-60'}`}
                  style={{ backgroundColor: skin.owned ? skin.color : '#5A5A7A' }}
                >
                  <div className="mb-1 flex justify-center h-10 items-center">
                    {skin.owned ? (
                      <BrainCharacter rotLevel={20} size={36} showArms={false} />
                    ) : (
                      <LockIcon size={24} className="text-black" />
                    )}
                  </div>
                  <div className="text-[9px] font-black text-black mb-1">{skin.name}</div>
                  <div className={`text-[8px] font-black px-2 py-0.5 rounded-full border border-black ${
                    skin.owned ? 'bg-[#39FF14] text-black' : 'bg-black/30 text-white'
                  }`}>
                    {skin.owned ? 'OWNED' : 'LOCKED'}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      <style>{`
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}

function StatLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-xs font-bold text-white/80">{label}</span>
      <span className="text-sm font-black text-white">{value}</span>
    </div>
  );
}

// Additional custom icons
function AwardBadgeIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="10" r="6" fill="currentColor" stroke="#000" strokeWidth="2"/>
      <path d="M8 14L7 22L12 19L17 22L16 14" stroke="#000" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="currentColor"/>
      <circle cx="12" cy="10" r="3" fill="white" opacity="0.4"/>
      <path d="M12 7L13 9L15 9L13.5 10.5L14 12.5L12 11L10 12.5L10.5 10.5L9 9L11 9L12 7Z" fill="#000"/>
    </svg>
  );
}

function PaletteIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 3C7 3 3 7 3 12C3 14 4 16 6 16C7 16 8 15 8 14C8 13 7 12 7 11C7 8 9 6 12 6C15 6 18 8 18 11C18 15 15 18 12 18C11 18 10 17 10 16" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
      <circle cx="9" cy="10" r="1.5" fill="currentColor"/>
      <circle cx="15" cy="9" r="1.5" fill="currentColor"/>
      <circle cx="17" cy="13" r="1.5" fill="currentColor"/>
    </svg>
  );
}

function LockIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <rect x="6" y="11" width="12" height="10" rx="2" stroke="currentColor" strokeWidth="2" fill="currentColor" opacity="0.3"/>
      <path d="M8 11V8C8 5.8 9.8 4 12 4C14.2 4 16 5.8 16 8V11" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
      <circle cx="12" cy="16" r="2" fill="currentColor"/>
    </svg>
  );
}