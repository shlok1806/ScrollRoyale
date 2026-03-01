import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';

interface DuelMatchmakingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onStartDuel: () => void;
}

export function DuelMatchmakingModal({ isOpen, onClose, onStartDuel }: DuelMatchmakingModalProps) {
  const [stage, setStage] = useState<'options' | 'finding' | 'countdown'>('options');
  const [countdown, setCountdown] = useState(3);

  useEffect(() => {
    if (!isOpen) {
      setStage('options');
      setCountdown(3);
    }
  }, [isOpen]);

  useEffect(() => {
    if (stage === 'countdown') {
      if (countdown > 0) {
        const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
        return () => clearTimeout(timer);
      } else {
        onStartDuel();
      }
    }
  }, [stage, countdown, onStartDuel]);

  const handleFindMatch = () => {
    setStage('finding');
    setTimeout(() => setStage('countdown'), 1500);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50"
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 z-50 bg-[#7B2CBF] border-t-4 border-black rounded-t-3xl shadow-[0_-8px_0_rgba(0,0,0,0.8)]"
          >
            <div className="max-w-md mx-auto">
              {/* Handle */}
              <div className="flex justify-center pt-3 pb-2">
                <div className="w-12 h-1.5 bg-black/30 rounded-full" />
              </div>

              {stage === 'options' && (
                <div className="px-6 pb-8">
                  <h2 className="text-3xl font-black text-center mb-6 mt-2 text-white" style={{ textShadow: '3px 3px 0 rgba(0,0,0,0.5)' }}>
                    FIND OPPONENT
                  </h2>
                  
                  <div className="space-y-3">
                    <button
                      onClick={handleFindMatch}
                      className="w-full h-14 bg-[#39FF14] border-4 border-black rounded-xl font-black text-lg text-black shadow-[0_6px_0_rgba(0,0,0,0.8)] hover:brightness-110 active:translate-y-1 transition-all"
                      style={{ textShadow: '1px 1px 0 rgba(0,0,0,0.2)' }}
                    >
                      ⚡ RANDOM MATCH
                    </button>

                    <button className="w-full h-12 bg-[#4CC9F0] border-3 border-black rounded-xl font-bold text-black shadow-[0_4px_0_rgba(0,0,0,0.8)] hover:brightness-110 active:translate-y-1 transition-all">
                      👥 CHALLENGE FRIEND
                    </button>

                    <button className="w-full h-12 bg-[#9D4EDD] border-3 border-black rounded-xl font-bold text-white shadow-[0_4px_0_rgba(0,0,0,0.8)] hover:brightness-110 active:translate-y-1 transition-all">
                      🎯 PRACTICE MODE
                    </button>
                  </div>
                </div>
              )}

              {stage === 'finding' && (
                <div className="px-6 pb-8 py-8">
                  <div className="text-center">
                    <div className="relative w-20 h-20 mx-auto mb-5">
                      <motion.div
                        animate={{ rotate: 360 }}
                        transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                        className="absolute inset-0 rounded-full border-4 border-transparent border-t-[#39FF14] border-r-[#4CC9F0]"
                      />
                    </div>
                    <h3 className="text-2xl font-black mb-2 text-white" style={{ textShadow: '2px 2px 0 rgba(0,0,0,0.5)' }}>
                      FINDING...
                    </h3>
                    <p className="text-sm font-bold text-white/80">Searching for challenger</p>
                  </div>
                </div>
              )}

              {stage === 'countdown' && (
                <div className="px-6 pb-8 py-8">
                  <div className="text-center">
                    <div className="mb-5">
                      <div className="flex justify-center items-center gap-3 mb-4">
                        <div className="w-14 h-14 rounded-full bg-[#39FF14] border-3 border-black flex items-center justify-center text-3xl shadow-[0_4px_0_rgba(0,0,0,0.8)]">
                          🧠
                        </div>
                        <div className="text-[#FF006E] text-2xl font-black">VS</div>
                        <div className="w-14 h-14 rounded-full bg-[#FF006E] border-3 border-black flex items-center justify-center text-3xl shadow-[0_4px_0_rgba(0,0,0,0.8)]">
                          👾
                        </div>
                      </div>
                      <div className="text-xs font-bold text-white/70 mb-1">OPPONENT FOUND!</div>
                      <div className="font-black text-lg text-white">CyberNinja</div>
                      <div className="text-xs font-bold text-[#4CC9F0]">Rank #47 • 2,340 Trophies</div>
                    </div>

                    <motion.div
                      key={countdown}
                      initial={{ scale: 0.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      className="text-8xl font-black text-[#FFD60A] mb-3"
                      style={{
                        textShadow: '4px 4px 0 rgba(0,0,0,0.5)',
                      }}
                    >
                      {countdown}
                    </motion.div>
                    <p className="text-sm font-bold text-white/80">Get ready to scroll...</p>
                  </div>
                </div>
              )}

              {/* iOS Safe Area */}
              <div className="h-6" />
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}