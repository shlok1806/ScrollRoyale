import React from 'react';
import { motion } from 'motion/react';

export interface BrainCustomization {
  hat?: string;
  glasses?: string;
  expression?: string;
  skin?: string;
  effect?: string;
  accessory?: string;
}

export function renderHat(hatId: string, size = 60) {
  if (!hatId || hatId === 'none') return null;

  switch (hatId) {
    case 'crown':
      return (
        <svg width={size} height={size * 0.6} viewBox="0 0 60 36" fill="none">
          <path d="M5 20L10 8L20 16L30 8L40 16L50 8L55 20H5Z" fill="#FFD700" stroke="#000" strokeWidth="3"/>
          <circle cx="10" cy="8" r="4" fill="#FFD700" stroke="#000" strokeWidth="2"/>
          <circle cx="30" cy="4" r="4" fill="#FFD700" stroke="#000" strokeWidth="2"/>
          <circle cx="50" cy="8" r="4" fill="#FFD700" stroke="#000" strokeWidth="2"/>
          <rect x="5" y="20" width="50" height="6" fill="#FFD700" stroke="#000" strokeWidth="3"/>
        </svg>
      );
    case 'beanie':
      return (
        <svg width={size} height={size * 0.7} viewBox="0 0 60 42" fill="none">
          <ellipse cx="30" cy="28" rx="25" ry="14" fill="#FF6B35" stroke="#000" strokeWidth="3"/>
          <path d="M10 28C10 18 18 10 30 10C42 10 50 18 50 28" fill="#FF6B35" stroke="#000" strokeWidth="3"/>
          <circle cx="30" cy="8" r="5" fill="#FF6B35" stroke="#000" strokeWidth="2"/>
        </svg>
      );
    case 'wizard':
      return (
        <svg width={size} height={size} viewBox="0 0 60 60" fill="none">
          <path d="M30 5L20 50H40L30 5Z" fill="#9D4EDD" stroke="#000" strokeWidth="3"/>
          <ellipse cx="30" cy="50" rx="12" ry="4" fill="#9D4EDD" stroke="#000" strokeWidth="2"/>
          <path d="M25 20L35 20L33 30L27 30L25 20Z" fill="#FFD60A" stroke="#000" strokeWidth="2"/>
        </svg>
      );
    case 'headset':
      return (
        <svg width={size} height={size * 0.8} viewBox="0 0 60 48" fill="none">
          <path d="M10 24C10 14 18 6 30 6C42 6 50 14 50 24" stroke="#4CC9F0" strokeWidth="4" strokeLinecap="round"/>
          <rect x="5" y="24" width="10" height="16" rx="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
          <rect x="45" y="24" width="10" height="16" rx="3" fill="#4CC9F0" stroke="#000" strokeWidth="2"/>
          <circle cx="30" cy="8" r="3" fill="#FF006E"/>
        </svg>
      );
    case 'tophat':
      return (
        <svg width={size} height={size * 0.9} viewBox="0 0 60 54" fill="none">
          <rect x="15" y="10" width="30" height="25" rx="2" fill="#000" stroke="#000" strokeWidth="2"/>
          <ellipse cx="30" cy="35" rx="22" ry="5" fill="#000" stroke="#000" strokeWidth="2"/>
          <rect x="20" y="8" width="20" height="4" fill="#FF006E"/>
        </svg>
      );
    case 'helmet':
      return (
        <svg width={size} height={size * 0.7} viewBox="0 0 60 42" fill="none">
          <path d="M10 28C10 18 18 10 30 10C42 10 50 18 50 28L45 32H15L10 28Z" fill="#C0C0C0" stroke="#000" strokeWidth="3"/>
          <rect x="25" y="18" width="10" height="8" fill="#4A1A2C"/>
          <path d="M15 32L12 38H48L45 32" fill="#C0C0C0" stroke="#000" strokeWidth="2"/>
        </svg>
      );
    default:
      return null;
  }
}

export function renderGlasses(glassesId: string, size = 60) {
  if (!glassesId || glassesId === 'none') return null;

  switch (glassesId) {
    case 'sunglasses':
      return (
        <svg width={size} height={size * 0.4} viewBox="0 0 60 24" fill="none">
          <rect x="5" y="6" width="20" height="14" rx="7" fill="#000" stroke="#000" strokeWidth="2"/>
          <rect x="35" y="6" width="20" height="14" rx="7" fill="#000" stroke="#000" strokeWidth="2"/>
          <path d="M25 13H35" stroke="#000" strokeWidth="3"/>
          <path d="M3 10L0 8M57 10L60 8" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      );
    case 'pixel':
      return (
        <svg width={size} height={size * 0.35} viewBox="0 0 60 21" fill="none">
          <rect x="6" y="6" width="18" height="12" fill="#4CC9F0" stroke="#000" strokeWidth="3"/>
          <rect x="36" y="6" width="18" height="12" fill="#4CC9F0" stroke="#000" strokeWidth="3"/>
          <path d="M24 12H36" stroke="#000" strokeWidth="3"/>
        </svg>
      );
    case 'nerd':
      return (
        <svg width={size} height={size * 0.4} viewBox="0 0 60 24" fill="none">
          <circle cx="15" cy="12" r="10" fill="none" stroke="#000" strokeWidth="3"/>
          <circle cx="45" cy="12" r="10" fill="none" stroke="#000" strokeWidth="3"/>
          <path d="M25 12H35" stroke="#000" strokeWidth="3"/>
          <path d="M20 22L25 18" stroke="#000" strokeWidth="2"/>
        </svg>
      );
    case 'visor':
      return (
        <svg width={size} height={size * 0.3} viewBox="0 0 60 18" fill="none">
          <path d="M8 9C8 9 15 6 30 6C45 6 52 9 52 9L50 14H10L8 9Z" fill="#FF006E" stroke="#000" strokeWidth="2"/>
          <path d="M5 9L3 7M55 9L57 7" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      );
    default:
      return null;
  }
}

export function renderEffect(effectId: string) {
  if (!effectId || effectId === 'none') return null;

  switch (effectId) {
    case 'purple-aura':
      return (
        <motion.div
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.4, 0.7, 0.4],
          }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute inset-0 -m-8 rounded-full bg-[#9D4EDD] blur-2xl pointer-events-none"
        />
      );
    case 'green-flame':
      return (
        <motion.div className="absolute -top-4 left-1/2 -translate-x-1/2 pointer-events-none">
          <motion.svg
            width="80"
            height="60"
            viewBox="0 0 80 60"
            animate={{
              y: [0, -5, 0],
            }}
            transition={{ duration: 0.8, repeat: Infinity }}
          >
            <path d="M40 10C40 10 30 25 30 35C30 45 35 50 40 50C45 50 50 45 50 35C50 25 40 10 40 10Z" fill="#39FF14" opacity="0.6" />
          </motion.svg>
        </motion.div>
      );
    case 'electric':
      return (
        <motion.div
          animate={{
            rotate: [0, 360],
          }}
          transition={{ duration: 4, repeat: Infinity, ease: 'linear' }}
          className="absolute inset-0 pointer-events-none"
        >
          {[...Array(8)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute top-1/2 left-1/2 w-1 h-8 bg-[#4CC9F0]"
              style={{
                rotate: `${i * 45}deg`,
                transformOrigin: 'center -40px',
              }}
              animate={{
                opacity: [0.3, 1, 0.3],
              }}
              transition={{
                duration: 0.5,
                repeat: Infinity,
                delay: i * 0.1,
              }}
            />
          ))}
        </motion.div>
      );
    case 'particles':
      return (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(12)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-2 h-2 rounded-full bg-[#FFD60A]"
              style={{
                left: '50%',
                top: '50%',
              }}
              animate={{
                x: [0, Math.cos(i * 30 * Math.PI / 180) * 60],
                y: [0, Math.sin(i * 30 * Math.PI / 180) * 60],
                opacity: [1, 0],
                scale: [1, 0],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                delay: i * 0.1,
              }}
            />
          ))}
        </div>
      );
    case 'glitch':
      return (
        <motion.div
          animate={{
            x: [0, -2, 2, 0],
            opacity: [0.8, 0.5, 0.8],
          }}
          transition={{
            duration: 0.2,
            repeat: Infinity,
            repeatDelay: 2,
          }}
          className="absolute inset-0 bg-[#FF006E] opacity-30 mix-blend-screen pointer-events-none"
        />
      );
    default:
      return null;
  }
}

export function getSkinColor(skinId?: string): { main: string; dark: string; accent: string } {
  if (!skinId || skinId === 'classic') {
    return { main: '#FFB3D1', dark: '#FF8FB8', accent: '#FF6B9D' };
  }

  const colors: Record<string, { main: string; dark: string; accent: string }> = {
    toxic: { main: '#39FF14', dark: '#2DD10F', accent: '#20A00C' },
    purple: { main: '#9D4EDD', dark: '#7B2CBF', accent: '#5A1E99' },
    cyber: { main: '#4CC9F0', dark: '#3AA8CC', accent: '#2887A8' },
    lava: { main: '#FF6B35', dark: '#E65528', accent: '#CC3F1A' },
    frozen: { main: '#B8E0F6', dark: '#95CAE6', accent: '#72B4D6' },
    chrome: { main: '#E8E8E8', dark: '#C0C0C0', accent: '#A0A0A0' },
  };

  return colors[skinId] || { main: '#FFB3D1', dark: '#FF8FB8', accent: '#FF6B9D' };
}

export function getRotLevelForExpression(expression?: string): number | null {
  if (!expression) return null;

  const rotLevels: Record<string, number> = {
    happy: 15,
    determined: 25,
    sleepy: 55,
    angry: 45,
    hypnotized: 50,
    confident: 20,
  };
  return rotLevels[expression] ?? null;
}
