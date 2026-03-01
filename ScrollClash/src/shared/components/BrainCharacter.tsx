import React from 'react';
import { motion } from 'motion/react';
import { BrainCustomization, renderHat, renderGlasses, renderEffect, getSkinColor, getRotLevelForExpression } from './BrainCustomizationUtils';

interface BrainCharacterProps {
  rotLevel: number;
  size?: number;
  showArms?: boolean;
  customization?: BrainCustomization;
}

export function BrainCharacter({ rotLevel, size = 80, showArms = true, customization }: BrainCharacterProps) {
  // Override rot level if expression is customized
  const effectiveRotLevel = customization?.expression 
    ? getRotLevelForExpression(customization.expression) ?? rotLevel
    : rotLevel;

  const getEyeState = () => {
    // If customization has expression, use it directly
    if (customization?.expression) {
      return customization.expression;
    }
    if (effectiveRotLevel < 30) return 'happy';
    if (effectiveRotLevel < 50) return 'neutral';
    if (effectiveRotLevel < 70) return 'tired';
    return 'dead';
  };

  const getBrainColor = () => {
    // Use custom skin color if provided
    if (customization?.skin) {
      return getSkinColor(customization.skin);
    }
    if (effectiveRotLevel < 30) return { main: '#FFB3D1', dark: '#FF8FB8', accent: '#FF6B9D' };
    if (effectiveRotLevel < 50) return { main: '#E0B3D1', dark: '#C88FB8', accent: '#B06B9D' };
    if (effectiveRotLevel < 70) return { main: '#C88FB8', dark: '#A0708F', accent: '#805070' };
    return { main: '#A569BD', dark: '#8B4AA0', accent: '#6B2B7D' };
  };

  const eyeState = getEyeState();
  const colors = getBrainColor();
  const showFlies = effectiveRotLevel >= 50;
  const showSecondFly = effectiveRotLevel >= 75;

  return (
    <motion.div
      animate={{ 
        y: [0, -6, 0],
      }}
      transition={{ 
        duration: 2, 
        repeat: Infinity,
        ease: "easeInOut"
      }}
      className="relative"
      style={{ width: size, height: size }}
    >
      {/* Effect Layer - Behind everything */}
      {customization?.effect && (
        <div className="absolute inset-0" style={{ transform: 'scale(1.4)' }}>
          {renderEffect(customization.effect)}
        </div>
      )}

      {/* Glow shadow */}
      <motion.div
        animate={{
          opacity: [0.3, 0.6, 0.3],
          scale: [0.9, 1, 0.9]
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
        }}
        className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-3/4 h-2 rounded-full bg-black/30 blur-md"
      />

      <svg width={size} height={size} viewBox="0 0 100 100" fill="none">
        {/* Left Arm with Spoon */}
        {showArms && (
          <g>
            <motion.g
              animate={{
                rotate: rotLevel > 60 ? [0, -5, 0] : [0, 10, 0],
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
              }}
              style={{ transformOrigin: '28px 55px' }}
            >
              {/* Arm */}
              <ellipse cx="18" cy="55" rx="8" ry="13" fill={colors.main} stroke="#4A1A2C" strokeWidth="3"/>
              {/* Hand */}
              <ellipse cx="14" cy="68" rx="5" ry="6" fill={colors.main} stroke="#4A1A2C" strokeWidth="2.5"/>
              {/* Spoon */}
              <ellipse cx="10" cy="76" rx="4" ry="5" fill="#E8E8E8" stroke="#4A1A2C" strokeWidth="2"/>
              <rect x="8" y="70" width="2" height="8" fill="#E8E8E8" stroke="#4A1A2C" strokeWidth="1.5"/>
            </motion.g>
          </g>
        )}

        {/* Right Arm with Lighter */}
        {showArms && (
          <g>
            <motion.g
              animate={{
                rotate: rotLevel > 60 ? [0, 5, 0] : [0, -10, 0],
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
              }}
              style={{ transformOrigin: '72px 55px' }}
            >
              {/* Arm */}
              <ellipse cx="82" cy="55" rx="8" ry="13" fill={colors.main} stroke="#4A1A2C" strokeWidth="3"/>
              {/* Hand */}
              <ellipse cx="86" cy="68" rx="5" ry="6" fill={colors.main} stroke="#4A1A2C" strokeWidth="2.5"/>
              {/* Lighter Body */}
              <rect x="84" y="72" width="8" height="12" rx="1" fill="#4CC9F0" stroke="#4A1A2C" strokeWidth="2"/>
              {/* Flame */}
              <motion.path
                d="M88 70 C87 68, 87 66, 88 64 C89 66, 89 68, 88 70 Z"
                fill="#FFD60A"
                stroke="#FF6B35"
                strokeWidth="1"
                animate={{
                  scaleY: [1, 1.1, 1],
                  y: [0, -1, 0]
                }}
                transition={{
                  duration: 0.5,
                  repeat: Infinity,
                }}
              />
            </motion.g>
          </g>
        )}

        {/* Brain Body */}
        <g>
          {/* Main brain shape with lobes */}
          <path
            d="M30 40 C30 28, 35 22, 45 22 C48 22, 50 23, 52 25 C54 23, 56 22, 60 22 C70 22, 75 28, 75 40 C75 45, 73 48, 70 50 C73 52, 75 55, 75 60 C75 70, 70 78, 50 78 C30 78, 25 70, 25 60 C25 55, 27 52, 30 50 C27 48, 25 45, 30 40 Z"
            fill={colors.main}
            stroke="#4A1A2C"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Brain squiggles/details */}
          <path d="M35 35 Q40 33, 45 35" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M55 35 Q60 33, 65 35" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M32 45 Q37 43, 42 45" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M58 45 Q63 43, 68 45" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M35 55 Q40 53, 45 55" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M55 55 Q60 53, 65 55" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          <path d="M38 65 Q45 63, 52 65" stroke={colors.dark} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          
          {/* Dots */}
          <circle cx="38" cy="50" r="1.5" fill={colors.dark}/>
          <circle cx="62" cy="48" r="1.5" fill={colors.dark}/>
          <circle cx="48" cy="60" r="1.5" fill={colors.dark}/>

          {/* Eyes */}
          {eyeState === 'happy' && (
            <g>
              <motion.g
                animate={{
                  scaleY: [1, 0.1, 1],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  repeatDelay: 2,
                }}
              >
                <circle cx="42" cy="48" r="4" fill="#4A1A2C"/>
                <circle cx="42" cy="47" r="1.5" fill="#FFF"/>
                <circle cx="58" cy="48" r="4" fill="#4A1A2C"/>
                <circle cx="58" cy="47" r="1.5" fill="#FFF"/>
              </motion.g>
            </g>
          )}

          {eyeState === 'neutral' && (
            <g>
              <circle cx="42" cy="48" r="3.5" fill="#4A1A2C"/>
              <circle cx="42" cy="47" r="1" fill="#FFF"/>
              <circle cx="58" cy="48" r="3.5" fill="#4A1A2C"/>
              <circle cx="58" cy="47" r="1" fill="#FFF"/>
            </g>
          )}

          {eyeState === 'tired' && (
            <g>
              <ellipse cx="42" cy="50" rx="3" ry="2" fill="#4A1A2C"/>
              <path d="M38 48 L46 48" stroke="#4A1A2C" strokeWidth="2" strokeLinecap="round"/>
              <ellipse cx="58" cy="50" rx="3" ry="2" fill="#4A1A2C"/>
              <path d="M54 48 L62 48" stroke="#4A1A2C" strokeWidth="2" strokeLinecap="round"/>
            </g>
          )}

          {eyeState === 'dead' && (
            <g>
              <path d="M38 46 L46 52 M46 46 L38 52" stroke="#4A1A2C" strokeWidth="2.5" strokeLinecap="round"/>
              <path d="M54 46 L62 52 M62 46 L54 52" stroke="#4A1A2C" strokeWidth="2.5" strokeLinecap="round"/>
            </g>
          )}

          {/* Mouth */}
          {eyeState === 'happy' && (
            <path d="M43 60 Q50 65, 57 60" stroke="#4A1A2C" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          )}
          {eyeState === 'neutral' && (
            <path d="M43 60 L57 60" stroke="#4A1A2C" strokeWidth="2.5" strokeLinecap="round"/>
          )}
          {(eyeState === 'tired' || eyeState === 'dead') && (
            <path d="M43 63 Q50 58, 57 63" stroke="#4A1A2C" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
          )}

          {/* Cheek blush at low rot */}
          {rotLevel < 30 && (
            <g>
              <ellipse cx="35" cy="56" rx="3" ry="2" fill="#FF8FB8" opacity="0.6"/>
              <ellipse cx="65" cy="56" rx="3" ry="2" fill="#FF8FB8" opacity="0.6"/>
            </g>
          )}

          {/* Cracks at high rot */}
          {rotLevel >= 70 && (
            <g>
              <path d="M35 35 L42 42" stroke="#4A1A2C" strokeWidth="2" strokeLinecap="round"/>
              <path d="M65 38 L58 45" stroke="#4A1A2C" strokeWidth="2" strokeLinecap="round"/>
              <path d="M45 70 L50 65" stroke="#4A1A2C" strokeWidth="2" strokeLinecap="round"/>
            </g>
          )}

          {/* Sparkle at low rot */}
          {rotLevel < 30 && (
            <motion.g
              animate={{
                opacity: [0, 1, 0],
                rotate: [0, 180, 360],
                scale: [0.8, 1, 0.8],
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
              }}
              style={{ transformOrigin: '75px 30px' }}
            >
              <path d="M75 28 L75 32 M73 30 L77 30" stroke="#FFD60A" strokeWidth="2" strokeLinecap="round"/>
              <path d="M73.5 28.5 L76.5 31.5 M76.5 28.5 L73.5 31.5" stroke="#FFD60A" strokeWidth="1.5" strokeLinecap="round"/>
            </motion.g>
          )}
        </g>

        {/* Flies */}
        {showFlies && (
          <g>
            <motion.g
              animate={{
                x: [15, -15, 15],
                y: [-5, -15, -5],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: "linear"
              }}
            >
              <ellipse cx="50" cy="15" rx="3" ry="4" fill="#4A1A2C"/>
              <path d="M47 13 L44 11 M53 13 L56 11" stroke="#4A1A2C" strokeWidth="1.5" strokeLinecap="round"/>
            </motion.g>
          </g>
        )}
        {showSecondFly && (
          <g>
            <motion.g
              animate={{
                x: [-15, 15, -15],
                y: [-8, -2, -8],
              }}
              transition={{
                duration: 2.5,
                repeat: Infinity,
                ease: "linear"
              }}
            >
              <ellipse cx="50" cy="12" rx="3" ry="4" fill="#4A1A2C"/>
              <path d="M47 10 L44 8 M53 10 L56 8" stroke="#4A1A2C" strokeWidth="1.5" strokeLinecap="round"/>
            </motion.g>
          </g>
        )}
      </svg>

      {/* Hat Layer - On Top */}
      {customization?.hat && (
        <div className="absolute -top-2 left-1/2 -translate-x-1/2 z-20" style={{ width: size * 0.8 }}>
          {renderHat(customization.hat, size * 0.6)}
        </div>
      )}

      {/* Glasses Layer */}
      {customization?.glasses && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-20" style={{ marginTop: size * -0.1, width: size * 0.8 }}>
          {renderGlasses(customization.glasses, size * 0.6)}
        </div>
      )}
    </motion.div>
  );
}