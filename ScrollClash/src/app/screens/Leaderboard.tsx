import React from 'react';
import { motion } from 'motion/react';
import { BrainCharacter } from '../components/BrainCharacter';
import { TrophyIcon, CrownIcon, GlobeIcon, UserGroupIcon } from '../components/GameIcons';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

const leaderboardData = [
  { rank: 1, name: 'NeonKing', score: 10240, badge: 'Legend', rotLevel: 15 },
  { rank: 2, name: 'PixelWiz', score: 9875, badge: 'Master', rotLevel: 18 },
  { rank: 3, name: 'CyberNinja', score: 9120, badge: 'Expert', rotLevel: 22 },
  { rank: 4, name: 'QuantumGamer', score: 8450, badge: 'Pro', rotLevel: 25 },
  { rank: 5, name: 'NeonDreamer', score: 7980, badge: 'Pro', rotLevel: 28 },
  { rank: 6, name: 'DataSurfer', score: 7640, badge: 'Advanced', rotLevel: 32 },
  { rank: 7, name: 'CodeMaster', score: 7320, badge: 'Advanced', rotLevel: 35 },
  { rank: 8, name: 'FlowState', score: 6890, badge: 'Advanced', rotLevel: 38 },
  { rank: 9, name: 'BrainBoss', score: 6540, badge: 'Skilled', rotLevel: 42 },
  { rank: 10, name: 'ScrollLord', score: 6210, badge: 'Skilled', rotLevel: 45 },
];

export default function Leaderboard() {
  const [activeTab, setActiveTab] = React.useState<'global' | 'friends'>('global');

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
        <div className="px-5 mb-4 flex-shrink-0">
          <motion.div
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="flex items-center justify-center gap-2 mb-4"
          >
            <TrophyIcon size={32} className="text-[#FFD60A]" />
            <h1 className="text-3xl font-black text-center text-white" style={{ textShadow: '4px 4px 0 rgba(0,0,0,0.5)' }}>
              LEADERBOARD
            </h1>
          </motion.div>

          {/* Segmented Control */}
          <div className="flex gap-2 p-1 bg-black/40 rounded-xl border-3 border-black">
            <button
              onClick={() => setActiveTab('global')}
              className={`flex-1 py-2.5 rounded-lg font-black text-sm transition-all border-2 border-black flex items-center justify-center gap-1.5 ${
                activeTab === 'global'
                  ? 'bg-[#FFD60A] text-black shadow-[0_3px_0_rgba(0,0,0,0.8)]'
                  : 'bg-transparent text-white'
              }`}
            >
              <GlobeIcon size={16} className={activeTab === 'global' ? 'text-black' : 'text-white'} />
              GLOBAL
            </button>
            <button
              onClick={() => setActiveTab('friends')}
              className={`flex-1 py-2.5 rounded-lg font-black text-sm transition-all border-2 border-black flex items-center justify-center gap-1.5 ${
                activeTab === 'friends'
                  ? 'bg-[#FFD60A] text-black shadow-[0_3px_0_rgba(0,0,0,0.8)]'
                  : 'bg-transparent text-white'
              }`}
            >
              <UserGroupIcon size={16} className={activeTab === 'friends' ? 'text-black' : 'text-white'} />
              FRIENDS
            </button>
          </div>
        </div>

        {/* Your Rank Card */}
        <div className="px-5 mb-4 flex-shrink-0">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            whileHover={{ y: -2 }}
            className="rounded-2xl bg-[#39FF14] border-4 border-black p-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]"
          >
            <div className="flex items-center gap-3">
              <div className="w-14 h-14 rounded-full bg-[#FFD60A] border-3 border-black flex items-center justify-center overflow-hidden shadow-[0_3px_0_rgba(0,0,0,0.6)]">
                <BrainCharacter rotLevel={20} size={48} showArms={false} />
              </div>
              <div className="flex-1">
                <div className="font-black text-base text-black">YOU</div>
                <div className="text-sm font-bold text-black/70">Rank #12</div>
              </div>
              <div className="text-right">
                <div className="text-3xl font-black text-black" style={{ textShadow: '2px 2px 0 rgba(255,255,255,0.3)' }}>1,204</div>
                <div className="text-xs font-bold text-black/70">trophies</div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Top 3 Podium */}
        <div className="px-5 mb-4 flex-shrink-0">
          <div className="grid grid-cols-3 gap-2 items-end">
            {/* 2nd Place */}
            <motion.div
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-center"
            >
              <PodiumCard player={leaderboardData[1]} />
            </motion.div>

            {/* 1st Place */}
            <motion.div
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0 }}
              className="text-center"
            >
              <PodiumCard player={leaderboardData[0]} isFirst />
            </motion.div>

            {/* 3rd Place */}
            <motion.div
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="text-center"
            >
              <PodiumCard player={leaderboardData[2]} />
            </motion.div>
          </div>
        </div>

        {/* Scrollable Leaderboard */}
        <div className="px-5 flex-1 overflow-y-auto pb-24">
          <div className="space-y-2">
            {leaderboardData.slice(3).map((player, idx) => (
              <motion.div
                key={player.rank}
                initial={{ x: -30, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: 0.3 + idx * 0.05 }}
              >
                <LeaderboardRow player={player} />
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function PodiumCard({ player, isFirst = false }: { player: typeof leaderboardData[0]; isFirst?: boolean }) {
  const getRankStyle = () => {
    if (player.rank === 1) return { bg: '#FFD700', shadow: '0 4px 0 #B8860B' };
    if (player.rank === 2) return { bg: '#C0C0C0', shadow: '0 4px 0 #808080' };
    return { bg: '#CD7F32', shadow: '0 4px 0 #8B4513' };
  };

  const style = getRankStyle();

  return (
    <motion.div
      whileHover={{ y: -3, scale: 1.05 }}
      className={`rounded-2xl ${isFirst ? 'bg-[#FFD700] border-4' : 'bg-[#7B2CBF] border-3'} border-black p-3 shadow-[0_6px_0_rgba(0,0,0,0.8)]`}
    >
      {/* Crown for first */}
      {isFirst && (
        <motion.div
          animate={{ y: [-3, 0, -3] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="mb-1 flex justify-center"
        >
          <CrownIcon size={32} className="text-[#FFD60A]" style={{ filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.3))' }} />
        </motion.div>
      )}
      
      <div 
        className={`${isFirst ? 'w-20 h-20' : 'w-14 h-14'} mx-auto rounded-full border-3 border-black flex items-center justify-center mb-2 shadow-lg overflow-hidden`}
        style={{ backgroundColor: style.bg, boxShadow: style.shadow }}
      >
        <BrainCharacter rotLevel={player.rotLevel} size={isFirst ? 70 : 50} showArms={false} />
      </div>
      
      <div className={`${isFirst ? 'text-sm' : 'text-xs'} font-black mb-1 text-white`} style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
        {player.name}
      </div>
      <div className={`${isFirst ? 'text-xl' : 'text-base'} font-black text-white`} style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
        {player.score.toLocaleString()}
      </div>
    </motion.div>
  );
}

function LeaderboardRow({ player }: { player: typeof leaderboardData[0] }) {
  return (
    <motion.div
      whileHover={{ x: 3, scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="rounded-xl bg-[#9D4EDD] border-3 border-black p-3 shadow-[0_4px_0_rgba(0,0,0,0.8)] cursor-pointer"
    >
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-full bg-[#4CC9F0] border-2 border-black flex items-center justify-center font-black text-base text-black shadow-[0_2px_0_rgba(0,0,0,0.6)]">
          {player.rank}
        </div>
        <div className="w-10 h-10 rounded-full bg-[#FFD60A] border-2 border-black flex items-center justify-center shadow-[0_2px_0_rgba(0,0,0,0.6)] overflow-hidden">
          <BrainCharacter rotLevel={player.rotLevel} size={36} showArms={false} />
        </div>
        <div className="flex-1">
          <div className="font-black text-sm text-white" style={{ textShadow: '1px 1px 0 rgba(0,0,0,0.5)' }}>
            {player.name}
          </div>
          <div className="text-[10px] font-bold text-white/80">{player.badge}</div>
        </div>
        <div className="text-right">
          <div className="font-black text-lg text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
            {player.score.toLocaleString()}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
