import React, { useState } from 'react';
import { motion } from 'motion/react';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import { FlameIcon, ActivityIcon, TrophyIcon, CloseIcon } from '../../shared/components/GameIcons';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';
import graveyardBg from 'figma:asset/c4c1b03ad69631025843daf744c7fdde421f013a.png';

const graveyardData = [
  { date: 'Today', rot: 28, streak: 4, flicks: 12, stability: 92 },
  { date: 'Yesterday', rot: 32, streak: 3, flicks: 18, stability: 88 },
  { date: 'Feb 26', rot: 35, streak: 2, flicks: 10, stability: 94 },
  { date: 'Feb 25', rot: 58, streak: 1, flicks: 22, stability: 85 },
  { date: 'Feb 24', rot: 62, streak: 0, flicks: 15, stability: 90 },
  { date: 'Feb 23', rot: 75, streak: 0, flicks: 28, stability: 78 },
];

export default function Graveyard() {
  const [selectedDay, setSelectedDay] = useState<typeof graveyardData[0] | null>(null);
  const [activeScene, setActiveScene] = useState<'healthy' | 'graveyard'>('healthy');

  // Split data by rot level
  const healthyDays = graveyardData.filter(day => day.rot < 50);
  const graveyardDays = graveyardData.filter(day => day.rot >= 50);

  return (
    <div className="h-screen relative text-white overflow-hidden flex flex-col">
      {/* Background Image */}
      <div className="absolute inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-black/40" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col h-full">
        {/* iOS Status Bar */}
        <div className="h-12" />

        {/* Header */}
        <div className="px-5 mb-3 flex-shrink-0">
          <motion.h1
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="text-3xl font-black text-center mb-3 text-white"
            style={{ textShadow: '4px 4px 0 rgba(0,0,0,0.5)' }}
          >
            BRAIN HISTORY
          </motion.h1>

          {/* Scene Toggle */}
          <div className="flex gap-2 p-1 bg-black/40 rounded-xl border-3 border-black mb-3">
            <button
              onClick={() => setActiveScene('healthy')}
              className={`flex-1 py-2.5 rounded-lg font-black text-sm transition-all border-2 border-black flex items-center justify-center gap-1.5 ${
                activeScene === 'healthy'
                  ? 'bg-[#39FF14] text-black shadow-[0_3px_0_rgba(0,0,0,0.8)]'
                  : 'bg-transparent text-white'
              }`}
            >
              <TreeIcon size={16} className={activeScene === 'healthy' ? 'text-black' : 'text-white'} />
              HEALTHY
            </button>
            <button
              onClick={() => setActiveScene('graveyard')}
              className={`flex-1 py-2.5 rounded-lg font-black text-sm transition-all border-2 border-black flex items-center justify-center gap-1.5 ${
                activeScene === 'graveyard'
                  ? 'bg-[#FF006E] text-white shadow-[0_3px_0_rgba(0,0,0,0.8)]'
                  : 'bg-transparent text-white'
              }`}
            >
              <SkullIcon size={16} className="text-white" />
              GRAVEYARD
            </button>
          </div>

          {/* Stats Banner */}
          <div className="rounded-2xl bg-[#7B2CBF] border-4 border-black p-3 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="grid grid-cols-2 gap-3 text-center">
              <div>
                <div className="flex items-center justify-center gap-1 mb-1">
                  <FlameIcon size={20} className="text-[#39FF14]" />
                </div>
                <div className="text-3xl font-black text-[#39FF14]" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>4</div>
                <div className="text-xs font-bold text-white">STREAK</div>
              </div>
              <div>
                <div className="flex items-center justify-center gap-1 mb-1">
                  <WarningIcon size={20} className="text-[#FF006E]" />
                </div>
                <div className="text-3xl font-black text-[#FF006E]" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>75%</div>
                <div className="text-xs font-bold text-white">WORST</div>
              </div>
            </div>
          </div>
        </div>

        {/* Scene Container */}
        <div className="flex-1 relative overflow-hidden">
          {activeScene === 'healthy' ? (
            <HealthyForestScene days={healthyDays} onSelectDay={setSelectedDay} />
          ) : (
            <GraveyardScene days={graveyardDays} onSelectDay={setSelectedDay} />
          )}
        </div>
      </div>

      {/* Daily Report Modal */}
      {selectedDay && (
        <DailyReportModal
          day={selectedDay}
          onClose={() => setSelectedDay(null)}
        />
      )}
    </div>
  );
}

function HealthyForestScene({ days, onSelectDay }: { days: typeof graveyardData; onSelectDay: (day: typeof graveyardData[0]) => void }) {
  return (
    <div className="absolute inset-0">
      {/* Forest Background Layers */}
      <div className="absolute inset-0">
        {/* Sky gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#4CC9F0]/30 via-[#3D9BBF]/40 to-[#2A6B7F]/50" />
        
        {/* Mountains/Trees silhouette */}
        <svg className="absolute bottom-0 w-full h-2/3" viewBox="0 0 400 300" preserveAspectRatio="none">
          {/* Dark purple trees background */}
          <path d="M0,150 L50,80 L100,150 L150,100 L200,150 L250,90 L300,150 L350,110 L400,150 L400,300 L0,300 Z" fill="#2A1A4A" opacity="0.6"/>
          {/* Green trees foreground */}
          <path d="M0,200 L40,130 L80,200 L120,150 L160,200 L200,140 L240,200 L280,160 L320,200 L360,170 L400,200 L400,300 L0,300 Z" fill="#2DD10F" opacity="0.8"/>
        </svg>

        {/* Ground */}
        <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-[#1A6B3A] to-transparent" />

        {/* Grass blades */}
        <div className="absolute bottom-0 left-0 right-0 flex justify-around px-4">
          {[...Array(25)].map((_, i) => (
            <motion.div
              key={i}
              animate={{
                rotate: [0, 3, 0],
                x: [0, 1, 0],
              }}
              transition={{
                duration: 2 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
              className="w-1 bg-[#2DD10F] rounded-t-full border-l border-black/50"
              style={{ height: `${Math.random() * 16 + 10}px` }}
            />
          ))}
        </div>

        {/* Mushrooms */}
        {[...Array(3)].map((_, i) => (
          <div
            key={i}
            className="absolute bottom-2"
            style={{ left: `${15 + i * 30}%` }}
          >
            <svg width="24" height="28" viewBox="0 0 24 28">
              <ellipse cx="12" cy="10" rx="10" ry="8" fill="#FF6B6B" stroke="#000" strokeWidth="2"/>
              <circle cx="8" cy="9" r="2" fill="#FFE5E5"/>
              <circle cx="15" cy="8" r="2" fill="#FFE5E5"/>
              <rect x="9" y="12" width="6" height="14" rx="2" fill="#F5E6D3" stroke="#000" strokeWidth="2"/>
            </svg>
          </div>
        ))}

        {/* Rocks */}
        {[...Array(4)].map((_, i) => (
          <div
            key={i}
            className="absolute bottom-4"
            style={{ left: `${20 + i * 25}%` }}
          >
            <svg width="30" height="20" viewBox="0 0 30 20">
              <ellipse cx="15" cy="15" rx="12" ry="8" fill="#8B7E74" stroke="#000" strokeWidth="2"/>
            </svg>
          </div>
        ))}
      </div>

      {/* Brain Characters on stumps/pedestals */}
      <div className="absolute bottom-20 left-0 right-0 px-4">
        <div className="flex justify-around max-w-sm mx-auto">
          {days.map((day, idx) => (
            <HealthyBrainCard
              key={idx}
              day={day}
              index={idx}
              onClick={() => onSelectDay(day)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function GraveyardScene({ days, onSelectDay }: { days: typeof graveyardData; onSelectDay: (day: typeof graveyardData[0]) => void }) {
  return (
    <div className="absolute inset-0">
      {/* Dark Graveyard Background */}
      <div className="absolute inset-0">
        {/* Night sky */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#1a0040]/90 via-[#2A0F3F]/80 to-[#0a0015]/95" />
        
        {/* Stars */}
        <div className="absolute inset-0">
          {Array.from({ length: 30 }).map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-1 h-1 bg-white rounded-full"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 50}%`,
              }}
              animate={{
                opacity: [0.2, 1, 0.2],
                scale: [0.8, 1.2, 0.8],
              }}
              transition={{
                duration: 2 + Math.random() * 3,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            />
          ))}
        </div>

        {/* Moon */}
        <motion.div
          animate={{ y: [0, -10, 0] }}
          transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-14 right-6 w-20 h-20 rounded-full bg-[#FFE8B6] border-4 border-[#FFD98C] shadow-[0_0_40px_rgba(255,232,182,0.5)]"
        >
          <div className="absolute top-4 right-5 w-3 h-3 rounded-full bg-[#FFD98C]" />
          <div className="absolute bottom-6 right-3 w-2 h-2 rounded-full bg-[#FFD98C]" />
        </motion.div>

        {/* Rocky mountains/cliffs */}
        <svg className="absolute bottom-0 w-full h-1/2" viewBox="0 0 400 200" preserveAspectRatio="none">
          <path d="M0,100 L80,40 L160,90 L240,30 L320,80 L400,50 L400,200 L0,200 Z" fill="#3A2A5A" opacity="0.8"/>
          <path d="M0,130 L60,80 L140,120 L220,70 L300,110 L380,80 L400,100 L400,200 L0,200 Z" fill="#2A1A4A"/>
        </svg>

        {/* Ground with dirt */}
        <svg className="absolute bottom-0 left-0 right-0" viewBox="0 0 400 80" preserveAspectRatio="none" style={{ height: '80px' }}>
          <path d="M0,40 Q100,25 200,40 T400,40 L400,80 L0,80 Z" fill="#4A3A5A" stroke="#2A1A3A" strokeWidth="2"/>
        </svg>

        {/* Bones scattered */}
        {[...Array(3)].map((_, i) => (
          <div
            key={i}
            className="absolute bottom-4"
            style={{ left: `${10 + i * 35}%`, transform: `rotate(${Math.random() * 60 - 30}deg)` }}
          >
            <svg width="30" height="12" viewBox="0 0 30 12">
              <circle cx="4" cy="6" r="4" fill="#E8E0D5" stroke="#000" strokeWidth="1.5"/>
              <rect x="4" y="4" width="18" height="4" fill="#E8E0D5" stroke="#000" strokeWidth="1.5"/>
              <circle cx="26" cy="6" r="4" fill="#E8E0D5" stroke="#000" strokeWidth="1.5"/>
            </svg>
          </div>
        ))}

        {/* Fog */}
        <motion.div
          animate={{ x: [0, 30, 0] }}
          transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
          className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-[#9D4EDD]/20 to-transparent blur-xl"
        />
      </div>

      {/* Gravestones */}
      <div className="absolute bottom-20 left-0 right-0 px-4">
        <div className="flex justify-around max-w-sm mx-auto">
          {days.map((day, idx) => (
            <GravestoneCard
              key={idx}
              day={day}
              index={idx}
              onClick={() => onSelectDay(day)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function HealthyBrainCard({ 
  day, 
  index, 
  onClick 
}: { 
  day: typeof graveyardData[0]; 
  index: number;
  onClick: () => void;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30, scale: 0.8 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ delay: index * 0.1, type: 'spring' }}
      whileHover={{ scale: 1.05, y: -5 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="cursor-pointer relative"
    >
      {/* Wood stump/pedestal */}
      <div className="relative">
        <svg width="70" height="90" viewBox="0 0 70 90">
          {/* Stump */}
          <ellipse cx="35" cy="75" rx="28" ry="8" fill="#6B4423" stroke="#000" strokeWidth="2"/>
          <rect x="10" y="50" width="50" height="25" fill="#8B5A3C" stroke="#000" strokeWidth="2"/>
          <ellipse cx="35" cy="50" rx="25" ry="8" fill="#A0673D" stroke="#000" strokeWidth="2"/>
          {/* Tree rings */}
          <ellipse cx="35" cy="50" rx="15" ry="5" fill="none" stroke="#6B4423" strokeWidth="1"/>
          <ellipse cx="35" cy="50" rx="8" ry="3" fill="none" stroke="#6B4423" strokeWidth="1"/>
        </svg>

        {/* Brain on top */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-2">
          <motion.div
            animate={{ y: [0, -4, 0] }}
            transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
          >
            <BrainCharacter rotLevel={day.rot} size={48} showArms={false} />
          </motion.div>
        </div>
      </div>

      {/* Date label */}
      <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 text-center">
        <div className="text-[9px] text-white/90 font-bold bg-black/40 px-2 py-1 rounded-full border border-[#39FF14]">
          {day.date}
        </div>
      </div>

      {/* Rot percentage badge */}
      <div className="absolute top-2 right-0">
        <div className="px-2 py-0.5 rounded-full bg-[#39FF14] border-2 border-black font-black text-[8px] text-black">
          {day.rot}%
        </div>
      </div>
    </motion.div>
  );
}

function GravestoneCard({ 
  day, 
  index, 
  onClick 
}: { 
  day: typeof graveyardData[0]; 
  index: number;
  onClick: () => void;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30, scale: 0.8 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ delay: index * 0.1, type: 'spring' }}
      whileHover={{ scale: 1.05, y: -5 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="cursor-pointer relative"
    >
      {/* Gravestone */}
      <div className="relative">
        <svg width="65" height="85" viewBox="0 0 65 85">
          {/* Stone base */}
          <rect x="8" y="68" width="49" height="12" rx="2" fill="#6A5A7A" stroke="#000" strokeWidth="2"/>
          {/* Main stone */}
          <rect x="12" y="20" width="41" height="50" rx="3" fill="#8B7A9A" stroke="#000" strokeWidth="3"/>
          {/* Rounded top */}
          <path d="M12,25 L12,20 C12,12 22,8 32.5,8 C43,8 53,12 53,20 L53,25" fill="#8B7A9A" stroke="#000" strokeWidth="3"/>
          {/* Cracks */}
          <path d="M25,30 L30,38 M40,35 L35,43" stroke="#5A4A6A" strokeWidth="2"/>
        </svg>

        {/* Brain Character - Dead */}
        <div className="absolute top-6 left-1/2 -translate-x-1/2">
          <BrainCharacter rotLevel={day.rot} size={42} showArms={false} />
        </div>

        {/* R.I.P. Text */}
        <div className="absolute top-14 left-1/2 -translate-x-1/2">
          <div className="text-[10px] font-black text-black">R.I.P.</div>
        </div>

        {/* Rot % */}
        <div className="absolute bottom-16 left-1/2 -translate-x-1/2">
          <div className="text-base font-black text-white" style={{ textShadow: '1px 1px 0 rgba(0,0,0,0.8)' }}>
            {day.rot}%
          </div>
        </div>
      </div>

      {/* Date label */}
      <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 text-center">
        <div className="text-[9px] text-white/90 font-bold bg-black/40 px-2 py-1 rounded-full border border-[#FF006E]">
          {day.date}
        </div>
      </div>

      {/* Shadow */}
      <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-14 h-2 rounded-full bg-black/40 blur-sm" />
    </motion.div>
  );
}

function DailyReportModal({ day, onClose }: { day: typeof graveyardData[0]; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/80 z-50 flex items-center justify-center px-5">
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="w-full max-w-sm relative"
      >
        <div className="rounded-3xl bg-[#7B2CBF] border-4 border-black p-5 shadow-[0_8px_0_rgba(0,0,0,0.8)]">
          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute -top-3 -right-3 w-10 h-10 rounded-full bg-[#FF006E] border-3 border-black flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)] hover:brightness-110 active:translate-y-1"
          >
            <CloseIcon size={20} className="text-white" />
          </button>

          {/* Header */}
          <div className="text-center mb-4">
            <div className="mb-2 flex justify-center">
              <ChartIcon size={40} className="text-[#4CC9F0]" />
            </div>
            <h2 className="text-xl font-black text-white mb-1" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
              DAILY REPORT
            </h2>
            <p className="text-sm font-bold text-white/80">{day.date}</p>
          </div>

          {/* Rot Display */}
          <div className="text-center mb-4">
            <div className="inline-block px-5 py-2 rounded-xl bg-[#FF006E] border-3 border-black shadow-[0_4px_0_rgba(0,0,0,0.6)]">
              <div className="text-xs font-bold text-white mb-1">ROT LEVEL</div>
              <div className="text-4xl font-black text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
                {day.rot}%
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="space-y-2 mb-4">
            <StatRow
              icon={<ActivityIcon size={20} className="text-[#4CC9F0]" />}
              label="Stability"
              value={`${day.stability}%`}
              color="#4CC9F0"
            />
            <StatRow
              icon={<BurstIcon size={20} className="text-[#FF006E]" />}
              label="Rage Flicks"
              value={day.flicks.toString()}
              color="#FF006E"
            />
            <StatRow
              icon={<FlameIcon size={20} className="text-[#FFD60A]" />}
              label="Streak"
              value={`${day.streak} days`}
              color="#FFD60A"
            />
            <StatRow
              icon={<ClockIcon size={20} className="text-[#9D4EDD]" />}
              label="Time"
              value="2h 34m"
              color="#9D4EDD"
            />
          </div>

          {/* Badge */}
          {day.rot < 50 && (
            <div className="rounded-xl bg-[#FFD60A] border-3 border-black p-3 mb-4 text-center shadow-[0_4px_0_rgba(0,0,0,0.6)]">
              <div className="text-xs font-black text-black mb-1">BADGE EARNED</div>
              <div className="mb-1 flex justify-center">
                <TrophyIcon size={32} className="text-black" />
              </div>
              <div className="font-black text-black">Stability Master</div>
            </div>
          )}

          {/* Close Button */}
          <button
            onClick={onClose}
            className="w-full h-11 bg-[#39FF14] border-3 border-black rounded-xl font-black text-black hover:brightness-110 active:translate-y-1 transition-all shadow-[0_4px_0_rgba(0,0,0,0.8)]"
          >
            CLOSE
          </button>
        </div>
      </motion.div>
    </div>
  );
}

function StatRow({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: string; color: string }) {
  return (
    <div className="flex items-center justify-between p-2.5 rounded-xl bg-black/30 border-2 border-black">
      <div className="flex items-center gap-2">
        {icon}
        <span className="font-bold text-sm text-white">{label}</span>
      </div>
      <span className="text-lg font-black text-white" style={{ color, textShadow: '1px 1px 0 rgba(0,0,0,0.5)' }}>
        {value}
      </span>
    </div>
  );
}

// Additional icons
function TreeIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L8 8H10L7 13H9L6 18H18L15 13H17L14 8H16L12 2Z" fill="currentColor" stroke="currentColor" strokeWidth="1.5"/>
      <rect x="11" y="18" width="2" height="4" fill="currentColor"/>
    </svg>
  );
}

function SkullIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 3C7 3 4 7 4 11C4 13 5 15 6 16L6 20L9 18L12 20L15 18L18 20L18 16C19 15 20 13 20 11C20 7 17 3 12 3Z" fill="currentColor" stroke="#000" strokeWidth="2"/>
      <circle cx="9" cy="10" r="1.5" fill="#000"/>
      <circle cx="15" cy="10" r="1.5" fill="#000"/>
      <path d="M10 14L12 15L14 14" stroke="#000" strokeWidth="1.5" strokeLinecap="round"/>
    </svg>
  );
}

function WarningIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L2 20H22L12 2Z" fill="currentColor" stroke="#000" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M12 9V13M12 16V17" stroke="#000" strokeWidth="2.5" strokeLinecap="round"/>
    </svg>
  );
}

function ChartIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <rect x="3" y="12" width="4" height="9" fill="currentColor" stroke="#000" strokeWidth="2"/>
      <rect x="10" y="8" width="4" height="13" fill="currentColor" stroke="#000" strokeWidth="2"/>
      <rect x="17" y="4" width="4" height="17" fill="currentColor" stroke="#000" strokeWidth="2"/>
    </svg>
  );
}

function BurstIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 2L14 10L22 12L14 14L12 22L10 14L2 12L10 10L12 2Z" fill="currentColor" stroke="#000" strokeWidth="2" strokeLinejoin="round"/>
    </svg>
  );
}

function ClockIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" fill="none"/>
      <path d="M12 7V12L15 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
    </svg>
  );
}