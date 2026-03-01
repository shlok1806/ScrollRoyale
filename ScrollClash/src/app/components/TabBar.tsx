import React from 'motion/react';
import { motion } from 'motion/react';
import { Home, Trophy, Skull, User } from 'lucide-react';

interface TabBarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  onDuelClick: () => void;
}

export function TabBar({ activeTab, onTabChange, onDuelClick }: TabBarProps) {
  const tabs = [
    { id: 'home', label: 'Home', icon: Home },
    { id: 'leaderboard', label: 'Leaderboard', icon: Trophy },
    { id: 'duel', label: 'Duel', icon: null }, // Center floating button
    { id: 'graveyard', label: 'Graveyard', icon: Skull },
    { id: 'profile', label: 'Profile', icon: User },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50">      
      <div className="relative bg-[#7B2CBF] border-t-4 border-black">
        <div className="max-w-md mx-auto px-4 h-16 flex items-center justify-around relative">
          {tabs.map((tab) => {
            if (tab.id === 'duel') {
              return (
                <div key={tab.id} className="relative -mt-8">
                  <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={onDuelClick}
                    animate={{
                      boxShadow: [
                        '0 0 20px rgba(57,255,20,0.6), 0 6px 0 rgba(0,0,0,0.8)',
                        '0 0 30px rgba(57,255,20,0.8), 0 6px 0 rgba(0,0,0,0.8)',
                        '0 0 20px rgba(57,255,20,0.6), 0 6px 0 rgba(0,0,0,0.8)',
                      ],
                      scale: [1, 1.05, 1],
                    }}
                    transition={{ 
                      duration: 2, 
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                    className="w-16 h-16 rounded-full bg-[#39FF14] border-4 border-black flex items-center justify-center relative overflow-hidden"
                  >
                    {/* Glowing brain VS icon */}
                    <svg width="36" height="36" viewBox="0 0 36 36" fill="none" className="relative z-10">
                      {/* Brain left side */}
                      <path d="M12 18 C10 16, 8 14, 8 12 C8 10, 9 8, 11 8 C12 8, 13 9, 13 10" stroke="black" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
                      <path d="M13 10 C13 8, 14 6, 16 6 C18 6, 19 8, 19 10" stroke="black" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
                      {/* Brain right side */}
                      <path d="M24 18 C26 16, 28 14, 28 12 C28 10, 27 8, 25 8 C24 8, 23 9, 23 10" stroke="black" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
                      <path d="M23 10 C23 8, 22 6, 20 6 C18 6, 17 8, 17 10" stroke="black" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
                      {/* VS Text */}
                      <text x="18" y="24" textAnchor="middle" fontSize="10" fontWeight="900" fill="black">VS</text>
                    </svg>
                  </motion.button>
                </div>
              );
            }

            const Icon = tab.icon!;
            const isActive = activeTab === tab.id;

            return (
              <button
                key={tab.id}
                onClick={() => onTabChange(tab.id)}
                className="flex flex-col items-center gap-1 py-2 transition-colors relative"
              >
                <Icon 
                  size={24} 
                  className={`transition-colors ${isActive ? 'text-[#39FF14]' : 'text-white/60'}`}
                  strokeWidth={3}
                />
                <span className={`text-[10px] font-black ${isActive ? 'text-[#39FF14]' : 'text-white/60'}`}>
                  {tab.label.toUpperCase()}
                </span>
                {isActive && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-[#39FF14]"
                    style={{
                      boxShadow: '0 0 8px rgba(57,255,20,0.8)'
                    }}
                  />
                )}
              </button>
            );
          })}
        </div>
        {/* iOS safe area bottom padding */}
        <div className="h-6 bg-[#7B2CBF]" />
      </div>
    </div>
  );
}