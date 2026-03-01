import React from 'react';
import { motion } from 'motion/react';
import { Boost, BoostRarity } from '../types';

interface BoostCardProps {
  boost: Boost;
  onClick?: () => void;
  size?: 'small' | 'medium' | 'large';
  showCooldown?: boolean;
}

export function BoostCard({ boost, onClick, size = 'medium', showCooldown = false }: BoostCardProps) {
  const getRarityColor = (rarity: BoostRarity) => {
    switch (rarity) {
      case 'common': return '#C0C0C0';
      case 'rare': return '#4CC9F0';
      case 'epic': return '#9D4EDD';
      case 'legendary': return '#FFD60A';
    }
  };

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'control': return '#4CC9F0';
      case 'damage': return '#FF006E';
      case 'utility': return '#39FF14';
      case 'defense': return '#FFD60A';
      default: return '#7B2CBF';
    }
  };

  const sizeClasses = {
    small: 'w-32',
    medium: 'w-40',
    large: 'w-48',
  };

  const rarityColor = getRarityColor(boost.rarity);
  const categoryColor = getCategoryColor(boost.category);

  return (
    <motion.div
      whileHover={onClick ? { y: -4, scale: 1.02 } : {}}
      whileTap={onClick ? { scale: 0.97 } : {}}
      onClick={onClick}
      className={`${sizeClasses[size]} ${onClick ? 'cursor-pointer' : ''}`}
    >
      <div className="relative bg-[#F5F5DC] border-[5px] border-black rounded-2xl shadow-[0_6px_0_rgba(0,0,0,0.8)] overflow-hidden">
        {/* Rarity glow */}
        <motion.div
          animate={{ opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute inset-0 pointer-events-none"
          style={{ 
            background: `radial-gradient(circle at top, ${rarityColor}40, transparent 60%)`,
          }}
        />

        {/* Card Header */}
        <div className="relative px-2 pt-2 pb-1">
          <div className="bg-white border-3 border-black px-2 py-1 text-center">
            <div className="text-[10px] font-black text-black tracking-wide">{boost.name}</div>
          </div>
        </div>

        {/* Icon Area */}
        <div className="relative px-2">
          <div className="aspect-square bg-white border-3 border-black rounded-lg flex items-center justify-center mb-1 relative overflow-hidden">
            {/* Icon background gradient based on category */}
            <div 
              className="absolute inset-0 opacity-20"
              style={{ background: `linear-gradient(135deg, ${categoryColor}, transparent)` }}
            />
            
            {/* Icon */}
            <div className="relative z-10">
              {renderBoostIcon(boost.iconType, 48)}
            </div>

            {/* Cost badges - top right */}
            <div className="absolute top-1 right-1 flex flex-col gap-0.5">
              <div className="flex items-center gap-0.5 bg-[#4CC9F0] border-2 border-black rounded px-1 py-0.5">
                <FocusIcon size={10} />
                <span className="text-[10px] font-black text-black">{boost.focusCost}</span>
              </div>
            </div>

            {/* Locked overlay */}
            {!boost.owned && (
              <div className="absolute inset-0 bg-black/60 flex items-center justify-center backdrop-blur-sm">
                <LockIcon size={32} className="text-white" />
              </div>
            )}
          </div>

          {/* Category and Rarity bar */}
          <div className="flex items-center gap-1 mb-2">
            <div 
              className="flex-1 border-2 border-black px-1.5 py-0.5 text-center"
              style={{ backgroundColor: categoryColor }}
            >
              <span className="text-[8px] font-black text-black uppercase">{boost.category}</span>
            </div>
            <div 
              className="flex-1 border-2 border-black px-1.5 py-0.5 text-center"
              style={{ backgroundColor: rarityColor }}
            >
              <span className="text-[8px] font-black text-black uppercase">{boost.rarity}</span>
            </div>
          </div>
        </div>

        {/* Stats Section */}
        <div className="px-2 pb-2">
          <div className="grid grid-cols-3 gap-1 mb-2">
            <StatBox icon={<ClockIcon size={12} />} value={`${boost.cooldown}s`} label="CD" />
            <StatBox icon={<FocusIcon size={12} />} value={boost.focusCost} label="COST" />
            <StatBox icon={<StarIcon size={12} />} value={boost.rarity[0].toUpperCase()} label="RARE" />
          </div>

          {/* Description */}
          <div className="bg-white border-3 border-black rounded-lg p-2 min-h-[60px]">
            <p className="text-[9px] font-bold text-black leading-tight">{boost.description}</p>
          </div>
        </div>

        {/* Equipped badge */}
        {boost.equipped && (
          <div className="absolute top-2 left-2 bg-[#39FF14] border-2 border-black px-2 py-0.5 rounded-full">
            <span className="text-[8px] font-black text-black">EQUIPPED</span>
          </div>
        )}

        {/* Cooldown overlay */}
        {showCooldown && (
          <div className="absolute inset-0 bg-black/40 flex items-center justify-center backdrop-blur-sm">
            <div className="text-3xl font-black text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.8)' }}>
              5s
            </div>
          </div>
        )}
      </div>
    </motion.div>
  );
}

function StatBox({ icon, value, label }: { icon: React.ReactNode; value: string | number; label: string }) {
  return (
    <div className="bg-white border-2 border-black rounded px-1 py-1 text-center">
      <div className="flex items-center justify-center mb-0.5">
        {icon}
      </div>
      <div className="text-[10px] font-black text-black leading-none mb-0.5">{value}</div>
      <div className="text-[7px] font-bold text-black/60 leading-none">{label}</div>
    </div>
  );
}

function renderBoostIcon(iconType: string, size: number) {
  const s = size;
  const strokeWidth = 3;

  switch (iconType) {
    case 'anchor':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="12" r="4" stroke="#000" strokeWidth={strokeWidth} fill="#4CC9F0"/>
          <path d="M24 16V38M24 38L18 32M24 38L30 32M16 28C16 28 16 38 24 38C32 38 32 28 32 28" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'zen':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="16" stroke="#000" strokeWidth={strokeWidth} fill="#9D4EDD" opacity="0.3"/>
          <path d="M16 24C16 24 20 20 24 20C28 20 32 24 32 24" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round"/>
          <circle cx="18" cy="20" r="2" fill="#000"/>
          <circle cx="30" cy="20" r="2" fill="#000"/>
          <path d="M12 24C12 24 12 32 24 32C36 32 36 24 36 24" stroke="#000" strokeWidth={strokeWidth-1} strokeLinecap="round"/>
        </svg>
      );
    case 'blast':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="10" fill="#FF006E" stroke="#000" strokeWidth={strokeWidth}/>
          <path d="M24 8L26 16M24 40L26 32M8 24L16 26M40 24L32 26" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round"/>
          <path d="M13 13L19 19M35 13L29 19M13 35L19 29M35 35L29 29" stroke="#000" strokeWidth={strokeWidth-1} strokeLinecap="round"/>
        </svg>
      );
    case 'clock':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="16" stroke="#000" strokeWidth={strokeWidth} fill="#FFD60A"/>
          <path d="M24 12V24L32 28" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M36 20L40 16L44 20" stroke="#000" strokeWidth={strokeWidth-1} strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'shield':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M24 6L10 12V24C10 32 16 38 24 42C32 38 38 32 38 24V12L24 6Z" fill="#4CC9F0" stroke="#000" strokeWidth={strokeWidth} strokeLinejoin="round"/>
          <path d="M18 24L22 28L30 18" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'eye':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <ellipse cx="24" cy="24" rx="18" ry="12" stroke="#000" strokeWidth={strokeWidth} fill="#39FF14" opacity="0.3"/>
          <circle cx="24" cy="24" r="6" fill="#000" stroke="#000" strokeWidth={strokeWidth-1}/>
          <circle cx="26" cy="22" r="2" fill="#fff"/>
        </svg>
      );
    case 'chain':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <rect x="14" y="10" width="10" height="16" rx="5" stroke="#000" strokeWidth={strokeWidth} fill="#FF006E"/>
          <rect x="24" y="22" width="10" height="16" rx="5" stroke="#000" strokeWidth={strokeWidth} fill="#FF006E"/>
          <path d="M24 18L28 22" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round"/>
        </svg>
      );
    case 'reset':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M38 24C38 31.7 31.7 38 24 38C16.3 38 10 31.7 10 24C10 16.3 16.3 10 24 10C28 10 31.5 11.8 34 14.5" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" fill="none"/>
          <path d="M34 8L34 16L26 16" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" fill="#FFD60A"/>
        </svg>
      );
    case 'energy':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M28 6L16 24H24L20 42L32 24H24L28 6Z" fill="#39FF14" stroke="#000" strokeWidth={strokeWidth} strokeLinejoin="round"/>
        </svg>
      );
    case 'freeze':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M24 8V40M12 24H36M16 12L32 36M32 12L16 36" stroke="#4CC9F0" strokeWidth={strokeWidth} strokeLinecap="round"/>
          <circle cx="24" cy="8" r="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
          <circle cx="24" cy="40" r="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
          <circle cx="12" cy="24" r="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
          <circle cx="36" cy="24" r="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
        </svg>
      );
    case 'mirror':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <rect x="20" y="8" width="8" height="32" fill="#9D4EDD" stroke="#000" strokeWidth={strokeWidth}/>
          <path d="M12 16L20 24L12 32" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M36 16L28 24L36 32" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    case 'fire':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M24 6C24 6 16 16 16 24C16 30 19 36 24 36C29 36 32 30 32 24C32 16 24 6 24 6Z" fill="#FF006E" stroke="#000" strokeWidth={strokeWidth} strokeLinejoin="round"/>
          <path d="M24 16C24 16 20 20 20 24C20 26 21 28 24 28C27 28 28 26 28 24C28 20 24 16 24 16Z" fill="#FFD60A"/>
        </svg>
      );
    case 'pulse':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M6 24H14L18 12L24 36L30 18L34 24H42" stroke="#39FF14" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" fill="none"/>
          <circle cx="24" cy="24" r="16" stroke="#39FF14" strokeWidth="2" fill="none" opacity="0.3"/>
        </svg>
      );
    case 'fortress':
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <path d="M8 24L24 8L40 24V40H8V24Z" fill="#FFD60A" stroke="#000" strokeWidth={strokeWidth} strokeLinejoin="round"/>
          <rect x="20" y="28" width="8" height="12" fill="#000" stroke="#000" strokeWidth="2"/>
          <rect x="14" y="20" width="6" height="6" fill="#000"/>
          <rect x="28" y="20" width="6" height="6" fill="#000"/>
        </svg>
      );
    default:
      return (
        <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="16" stroke="#000" strokeWidth={strokeWidth} fill="#C0C0C0"/>
        </svg>
      );
  }
}

// Icon components
function FocusIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
      <circle cx="8" cy="8" r="6" stroke="#000" strokeWidth="2" fill="#4CC9F0"/>
      <circle cx="8" cy="8" r="3" fill="#000"/>
    </svg>
  );
}

function ClockIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
      <circle cx="8" cy="8" r="6" stroke="#000" strokeWidth="2" fill="none"/>
      <path d="M8 4V8L11 10" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
    </svg>
  );
}

function StarIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
      <path d="M8 2L9.5 6.5L14 8L9.5 9.5L8 14L6.5 9.5L2 8L6.5 6.5L8 2Z" fill="#FFD60A" stroke="#000" strokeWidth="1.5"/>
    </svg>
  );
}

function LockIcon({ size = 16, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <rect x="6" y="11" width="12" height="10" rx="2" stroke="currentColor" strokeWidth="2" fill="currentColor" opacity="0.3"/>
      <path d="M8 11V8C8 5.8 9.8 4 12 4C14.2 4 16 5.8 16 8V11" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
      <circle cx="12" cy="16" r="2" fill="currentColor"/>
    </svg>
  );
}
