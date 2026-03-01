import React from 'react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router';
import { ProgressRing } from '../../shared/components/ProgressRing';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import { TrophyIcon, FlameIcon, TargetIcon, ZapIcon, UserGroupIcon } from '../../shared/components/GameIcons';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

export default function HomeScreen() {
  const rotLevel = 37;
  const { customization } = useBrainCustomization();
  const navigate = useNavigate();

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
          <div className="flex items-center justify-between">
            {/* Trophy Pill */}
            <motion.div
              initial={{ x: -50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              whileHover={{ scale: 1.05 }}
              className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#2DD10F] border-4 border-black shadow-[0_4px_0_rgba(0,0,0,0.8)]"
            >
              <TrophyIcon size={16} className="text-black" />
              <span className="font-black text-black text-sm">+12</span>
            </motion.div>

            {/* Profile Avatar */}
            <motion.button
              initial={{ x: 50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              whileTap={{ scale: 0.9 }}
              className="w-12 h-12 rounded-full border-4 border-black shadow-[0_4px_0_rgba(0,0,0,0.8)] flex items-center justify-center overflow-hidden bg-gradient-to-br from-[#FFD700] to-[#FFA500]"
            >
              <BrainCharacter rotLevel={10} size={40} showArms={false} customization={customization} />
            </motion.button>
          </div>
        </div>

        {/* Today's Brain - Center */}
        <div className="px-5 mb-2 flex-shrink-0">
          <motion.h1
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="text-2xl font-black text-center text-white mb-2"
            style={{ textShadow: '4px 4px 0 rgba(0,0,0,0.5)' }}
          >
            TODAY'S BRAIN
          </motion.h1>
        </div>

        {/* Brain Mascot - Compact */}
        <div className="px-5 mb-3 flex-shrink-0">
          <motion.div
            initial={{ scale: 0.7, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
            className="relative flex justify-center"
          >
            <div className="relative">
              <ProgressRing 
                progress={rotLevel} 
                size={180} 
                strokeWidth={14}
                value=""
                label=""
              />
              
              {/* Brain Mascot Character */}
              <div className="absolute inset-0 flex items-center justify-center">
                <BrainCharacter rotLevel={rotLevel} size={120} />
              </div>
            </div>
          </motion.div>

          {/* Rot Level Display */}
          <motion.div
            initial={{ y: 10, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="text-center mt-2"
          >
            <div className="inline-block px-5 py-2 rounded-xl bg-[#FF1493] border-4 border-black shadow-[0_4px_0_rgba(0,0,0,0.8)]">
              <div className="text-3xl font-black text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
                {rotLevel}% ROT
              </div>
            </div>
          </motion.div>
        </div>

        {/* Stats Pills - Compact */}
        <div className="px-5 mb-3 flex-shrink-0">
          <div className="flex justify-center gap-3">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#FF6B35] border-3 border-black">
              <FlameIcon size={14} className="text-white" />
              <span className="text-xs font-black text-white">4 DAYS</span>
            </div>
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#FFD700] border-3 border-black">
              <TrophyIcon size={14} className="text-black" />
              <span className="text-xs font-black text-black">1,204</span>
            </div>
          </div>
        </div>

        {/* Game Panel - Battle Button */}
        <div className="px-5 mb-3 flex-shrink-0">
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.4 }}
            whileHover={{ y: -2 }}
            className="relative rounded-2xl bg-[#7B2CBF] border-4 border-black p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]"
          >            
            <h3 className="text-lg font-black text-center mb-3 text-white flex items-center justify-center gap-2" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" className="text-[#FFD60A]">
                <path d="M20 7L12 3L4 7M20 7L12 11M20 7V17L12 21M12 11L4 7M12 11V21M4 7V17L12 21" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
              </svg>
              READY FOR BATTLE?
            </h3>
            
            {/* Primary Battle Button */}
            <motion.button
              whileTap={{ scale: 0.95, y: 2 }}
              whileHover={{ scale: 1.02 }}
              animate={{
                boxShadow: [
                  '0 6px 0 rgba(0,0,0,0.8)',
                  '0 6px 0 rgba(0,0,0,0.8)',
                ]
              }}
              className="w-full h-14 bg-[#39FF14] border-4 border-black rounded-xl font-black text-lg text-black relative overflow-hidden shadow-[0_6px_0_rgba(0,0,0,0.8)] mb-2"
            >
              <motion.div
                animate={{ 
                  x: ['0%', '100%'],
                  opacity: [0.3, 0.7, 0.3]
                }}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                className="absolute top-0 left-0 w-8 h-full bg-white/50 skew-x-12"
              />
              <span className="relative" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.3)' }}>
                BATTLE NOW!
              </span>
            </motion.button>

            {/* Secondary Buttons */}
            <div className="grid grid-cols-2 gap-2">
              <button className="h-10 bg-[#4895EF] border-3 border-black rounded-lg font-bold text-xs text-white hover:brightness-110 active:translate-y-1 transition-all shadow-[0_4px_0_rgba(0,0,0,0.8)] flex items-center justify-center gap-1">
                <UserGroupIcon size={14} className="text-white" />
                INVITE
              </button>
              <button className="h-10 bg-[#F72585] border-3 border-black rounded-lg font-bold text-xs text-white hover:brightness-110 active:translate-y-1 transition-all shadow-[0_4px_0_rgba(0,0,0,0.8)] flex items-center justify-center gap-1">
                <TargetIcon size={14} className="text-white" />
                PRACTICE
              </button>
            </div>
          </motion.div>
        </div>

        {/* Boost Deck Button */}
        <div className="px-5 mb-3 flex-shrink-0">
          <motion.button
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.45 }}
            whileTap={{ scale: 0.97 }}
            whileHover={{ y: -2 }}
            onClick={() => navigate('/boosts')}
            className="w-full rounded-2xl bg-[#FF006E] border-4 border-black p-3 shadow-[0_6px_0_rgba(0,0,0,0.8)] flex items-center gap-3"
          >
            <div className="w-12 h-12 rounded-xl bg-[#FFD60A] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <rect x="4" y="6" width="6" height="8" rx="1" fill="#000" stroke="#000" strokeWidth="2"/>
                <rect x="14" y="6" width="6" height="8" rx="1" fill="#000" stroke="#000" strokeWidth="2"/>
                <rect x="9" y="10" width="6" height="8" rx="1" fill="#000" stroke="#000" strokeWidth="2"/>
              </svg>
            </div>
            <div className="flex-1 text-left">
              <div className="font-black text-sm text-white">BOOST DECK</div>
              <div className="text-xs text-white/80 font-bold">4/4 equipped • Manage cards</div>
            </div>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <path d="M7 15L12 10L7 5" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </motion.button>
        </div>

        {/* Daily Challenge Panel - Compact */}
        <div className="px-5 mb-3 flex-shrink-0">
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.5 }}
            whileHover={{ y: -2 }}
            className="rounded-2xl bg-[#4CC9F0] border-4 border-black p-3 shadow-[0_6px_0_rgba(0,0,0,0.8)]"
          >
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-[#FFD60A] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]">
                <TargetIcon size={24} className="text-black" />
              </div>
              <div className="flex-1">
                <div className="font-black text-sm text-black">DAILY CHALLENGE</div>
                <div className="text-xs text-black/80 font-bold">No Rage Flicks x60s</div>
              </div>
              <div className="px-2.5 py-1 rounded-full bg-[#FFD60A] border-2 border-black font-black text-xs text-black">
                +50
              </div>
            </div>
          </motion.div>
        </div>

        {/* Weekly Bar Chart - Compact */}
        <div className="px-5 flex-shrink-0">
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.6 }}
            whileHover={{ y: -2 }}
            className="rounded-2xl bg-[#9D4EDD] border-4 border-black p-3 shadow-[0_6px_0_rgba(0,0,0,0.8)]"
          >
            <div className="flex items-center gap-2 mb-3">
              <ZapIcon size={16} className="text-[#FFD60A]" />
              <h3 className="font-black text-sm text-white">7-DAY TREND</h3>
            </div>
            <div className="grid grid-cols-7 gap-1.5">
              {[45, 38, 42, 35, 40, 37, 37].map((value, idx) => {
                const height = (value / 100) * 40;
                const color = value < 35 ? '#39FF14' : value < 50 ? '#4CC9F0' : '#FF006E';
                return (
                  <div key={idx} className="flex flex-col items-center gap-1">
                    <div className="h-10 w-full bg-black/30 rounded border-2 border-black flex items-end overflow-hidden">
                      <motion.div
                        initial={{ height: 0 }}
                        animate={{ height: `${height}%` }}
                        transition={{ delay: 0.6 + idx * 0.1, duration: 0.4 }}
                        className="w-full"
                        style={{ backgroundColor: color }}
                      />
                    </div>
                    <span className="text-[9px] text-white font-black">
                      {['M', 'T', 'W', 'T', 'F', 'S', 'S'][idx]}
                    </span>
                  </div>
                );
              })}
            </div>
          </motion.div>
        </div>

        {/* Bottom padding for tab bar */}
        <div className="flex-grow" />
      </div>
    </div>
  );
}