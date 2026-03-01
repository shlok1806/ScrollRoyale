import React from 'react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';
import { BrainCharacter } from '../../shared/components/BrainCharacter';

export default function Login() {
  const navigate = useNavigate();

  const handleGoogleLogin = () => {
    // Navigate to loading screen, which will then redirect to home
    navigate('/loading');
  };

  return (
    <div className="h-screen relative text-white overflow-hidden flex items-center justify-center">
      {/* Background */}
      <div className="fixed inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-b from-[#1a0a2e]/80 via-[#0f0520]/60 to-[#050509]/80" />
      </div>

      {/* Floating brains background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          animate={{ y: [0, -20, 0], rotate: [0, 5, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute top-20 left-10 w-24 h-24"
        >
          <BrainCharacter 
            customization={{ skin: 'default', expression: 'happy' }} 
            size={80} 
            rotLevel={20} 
            showArms={false}
          />
        </motion.div>
        <motion.div
          animate={{ y: [0, 20, 0], rotate: [0, -5, 0] }}
          transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut', delay: 0.5 }}
          className="absolute top-40 right-10 w-24 h-24"
        >
          <BrainCharacter 
            customization={{ skin: 'toxic', expression: 'focused' }} 
            size={80} 
            rotLevel={60} 
            showArms={false}
          />
        </motion.div>
        <motion.div
          animate={{ y: [0, -15, 0], rotate: [0, 3, 0] }}
          transition={{ duration: 4.5, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
          className="absolute bottom-32 left-16 w-24 h-24"
        >
          <BrainCharacter 
            customization={{ skin: 'retro', expression: 'smirk' }} 
            size={80} 
            rotLevel={40} 
            showArms={false}
          />
        </motion.div>
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-md w-full px-6">
        {/* Logo/Title */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: 'spring', stiffness: 200, damping: 20 }}
          className="text-center mb-12"
        >
          <motion.h1 
            className="text-6xl font-black mb-3 text-[#39FF14]"
            style={{
              textShadow: '0 0 40px rgba(57, 255, 20, 0.8), 4px 4px 0 rgba(0,0,0,0.5)'
            }}
          >
            BRAINROT
          </motion.h1>
          <motion.h2 
            className="text-4xl font-black text-[#7B2CBF]"
            style={{
              textShadow: '0 0 30px rgba(123, 44, 191, 0.6), 3px 3px 0 rgba(0,0,0,0.5)'
            }}
          >
            ARENA
          </motion.h2>
          <p className="text-sm text-white/70 mt-4 font-bold">
            Battle. Customize. Dominate.
          </p>
        </motion.div>

        {/* Login Card */}
        <motion.div
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-black/60 border-4 border-black rounded-2xl p-8 shadow-[0_8px_0_rgba(0,0,0,0.8)] mb-6"
        >
          <div className="text-center mb-6">
            <h3 className="text-xl font-black text-white mb-2">GET STARTED</h3>
            <p className="text-sm text-white/60">Sign in to start your journey</p>
          </div>

          {/* Google Sign In Button */}
          <motion.button
            whileTap={{ scale: 0.97 }}
            onClick={handleGoogleLogin}
            className="w-full py-4 bg-white border-4 border-black rounded-2xl font-black text-lg text-black shadow-[0_6px_0_rgba(0,0,0,0.8)] active:translate-y-1 transition-all flex items-center justify-center gap-3"
          >
            <GoogleIcon size={24} />
            Continue with Google
          </motion.button>
        </motion.div>

        {/* Footer */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="text-center text-xs text-white/50"
        >
          <p>By continuing, you agree to our Terms & Privacy Policy</p>
        </motion.div>
      </div>
    </div>
  );
}

function GoogleIcon({ size = 24 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
    </svg>
  );
}
