import React, { useEffect, useState } from 'react';
import { motion } from 'motion/react';
import { useNavigate, useLocation } from 'react-router';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

export default function Loading() {
  const navigate = useNavigate();
  const location = useLocation();
  const { customization } = useBrainCustomization();
  const [progress, setProgress] = useState(0);

  // Get the source to determine where we came from
  const from = (location.state as { from?: string })?.from || 'login';

  useEffect(() => {
    // Simulate loading progress
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          return 100;
        }
        return prev + 2;
      });
    }, 20);

    // Navigate to home after 1 second
    const timeout = setTimeout(() => {
      navigate('/', { replace: true });
    }, 1000);

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [navigate]);

  // Generate multiple brain characters with different customizations
  const brainCharacters = [
    { skin: 'default', expression: 'happy', rotLevel: 15, delay: 0, x: -30, y: -20 },
    { skin: 'toxic', expression: 'focused', rotLevel: 45, delay: 0.2, x: 30, y: 10 },
    { skin: 'retro', expression: 'smirk', rotLevel: 70, delay: 0.4, x: -20, y: 30 },
    { skin: 'shadow', expression: 'angry', rotLevel: 90, delay: 0.6, x: 40, y: -10 },
    { skin: 'galaxy', expression: 'happy', rotLevel: 25, delay: 0.8, x: 0, y: -40 },
  ];

  return (
    <div className="h-screen relative text-white overflow-hidden flex flex-col items-center justify-center">
      {/* Background */}
      <div className="fixed inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-b from-[#1a0a2e]/90 via-[#0f0520]/80 to-[#050509]/90" />
      </div>

      {/* Animated gradient background */}
      <motion.div
        animate={{
          background: [
            'radial-gradient(circle at 20% 50%, rgba(123, 44, 191, 0.3) 0%, transparent 50%)',
            'radial-gradient(circle at 80% 50%, rgba(57, 255, 20, 0.3) 0%, transparent 50%)',
            'radial-gradient(circle at 50% 80%, rgba(76, 201, 240, 0.3) 0%, transparent 50%)',
            'radial-gradient(circle at 20% 50%, rgba(123, 44, 191, 0.3) 0%, transparent 50%)',
          ],
        }}
        transition={{ duration: 4, repeat: Infinity, ease: 'linear' }}
        className="fixed inset-0"
      />

      {/* Flying Brain Characters */}
      <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
        {brainCharacters.map((brain, i) => (
          <motion.div
            key={i}
            initial={{ 
              x: brain.x * 3, 
              y: brain.y * 3, 
              scale: 0, 
              rotate: 0,
              opacity: 0 
            }}
            animate={{ 
              x: [brain.x * 3, brain.x, brain.x * 2, brain.x],
              y: [brain.y * 3, brain.y, brain.y * 1.5, brain.y],
              scale: [0, 1.2, 0.9, 1],
              rotate: [0, 360],
              opacity: [0, 1, 1, 0.8]
            }}
            transition={{ 
              duration: 3,
              delay: brain.delay,
              repeat: Infinity,
              ease: 'easeInOut'
            }}
            className="absolute w-32 h-32"
            style={{
              filter: 'drop-shadow(0 0 20px rgba(57, 255, 20, 0.4))'
            }}
          >
            <BrainCharacter 
              customization={brain as any} 
              size={100} 
              rotLevel={brain.rotLevel} 
              showArms={false}
            />
          </motion.div>
        ))}

        {/* Center Hero Brain - User's customization */}
        <motion.div
          initial={{ scale: 0, rotate: -180 }}
          animate={{ scale: 1, rotate: 0 }}
          transition={{ type: 'spring', stiffness: 200, damping: 15, delay: 0.2 }}
          className="relative z-10 w-48 h-48"
          style={{
            filter: 'drop-shadow(0 0 40px rgba(123, 44, 191, 0.8))'
          }}
        >
          <motion.div
            animate={{ 
              y: [0, -10, 0],
              scale: [1, 1.05, 1]
            }}
            transition={{ 
              duration: 2,
              repeat: Infinity,
              ease: 'easeInOut'
            }}
          >
            <BrainCharacter 
              customization={customization} 
              size={160} 
              rotLevel={35} 
              showArms={true}
            />
          </motion.div>
        </motion.div>
      </div>

      {/* Loading Text & Progress */}
      <div className="relative z-20 mt-auto mb-24 w-full max-w-xs px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="text-center mb-6"
        >
          <h2 className="text-2xl font-black text-white mb-2" style={{
            textShadow: '2px 2px 0 rgba(0,0,0,0.5)'
          }}>
            {from === 'result' ? 'RETURNING HOME...' : 'LOADING...'}
          </h2>
          <p className="text-sm text-white/70 font-bold">
            {from === 'result' ? 'Calculating stats' : 'Preparing your arena'}
          </p>
        </motion.div>

        {/* Progress Bar */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.5 }}
          className="w-full"
        >
          <div className="bg-black/60 border-4 border-black rounded-full h-8 overflow-hidden shadow-[0_4px_0_rgba(0,0,0,0.8)] relative">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              className="h-full bg-gradient-to-r from-[#7B2CBF] via-[#4CC9F0] to-[#39FF14] relative"
              style={{
                boxShadow: 'inset 0 0 20px rgba(255,255,255,0.3)'
              }}
            >
              {/* Shine effect */}
              <motion.div
                animate={{ x: ['-100%', '200%'] }}
                transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
                className="absolute inset-0 bg-gradient-to-r from-transparent via-white/40 to-transparent"
                style={{ width: '50%' }}
              />
            </motion.div>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-sm font-black text-white" style={{
                textShadow: '1px 1px 2px rgba(0,0,0,0.8)'
              }}>
                {Math.floor(progress)}%
              </span>
            </div>
          </div>
        </motion.div>

        {/* Loading tips */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="mt-4 text-center"
        >
          <p className="text-xs text-white/50 font-bold">
            💡 Tip: Boost your combo to deal massive damage!
          </p>
        </motion.div>
      </div>
    </div>
  );
}
