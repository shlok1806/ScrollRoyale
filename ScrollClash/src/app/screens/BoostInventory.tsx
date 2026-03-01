import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useNavigate } from 'react-router';
import { BOOSTS, Boost } from '../../features/boosts/types';
import { BoostCard } from '../../features/boosts/components/BoostCard';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

type FilterTab = 'all' | 'equipped' | 'control' | 'damage' | 'utility' | 'defense';

export default function BoostInventory() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = React.useState<FilterTab>('all');
  const [selectedBoost, setSelectedBoost] = React.useState<Boost | null>(null);

  const equippedBoosts = BOOSTS.filter(b => b.equipped);

  const filteredBoosts = BOOSTS.filter(boost => {
    if (activeTab === 'all') return true;
    if (activeTab === 'equipped') return boost.equipped;
    return boost.category === activeTab;
  });

  return (
    <div className="h-screen relative text-white overflow-hidden flex flex-col">
      {/* Background */}
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
          <div className="flex items-center justify-between mb-4">
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={() => navigate(-1)}
              className="w-10 h-10 rounded-full bg-[#7B2CBF] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]"
            >
              <BackIcon size={18} className="text-white" />
            </motion.button>

            <h1 className="text-2xl font-black text-white" style={{ textShadow: '3px 3px 0 rgba(0,0,0,0.5)' }}>
              BOOST DECK
            </h1>

            <div className="w-10" />
          </div>

          {/* Equipped Deck Preview */}
          <div className="rounded-2xl bg-[#7B2CBF] border-4 border-black p-3 mb-4 shadow-[0_6px_0_rgba(0,0,0,0.8)]">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-black text-sm text-white">ACTIVE DECK</h3>
              <div className="text-xs font-bold text-white/70">{equippedBoosts.length}/4</div>
            </div>
            <div className="flex gap-2 overflow-x-auto scrollbar-hide">
              {equippedBoosts.map((boost, idx) => (
                <motion.div
                  key={boost.id}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: idx * 0.1 }}
                >
                  <BoostCard boost={boost} size="small" onClick={() => setSelectedBoost(boost)} />
                </motion.div>
              ))}
              {[...Array(4 - equippedBoosts.length)].map((_, idx) => (
                <div
                  key={`empty-${idx}`}
                  className="w-32 aspect-[2/3] rounded-2xl border-4 border-dashed border-white/30 flex items-center justify-center"
                >
                  <PlusIcon size={32} className="text-white/30" />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="px-5 mb-3 flex-shrink-0">
          <div className="flex gap-2 overflow-x-auto scrollbar-hide">
            {(['all', 'equipped', 'control', 'damage', 'utility', 'defense'] as FilterTab[]).map((tab) => (
              <motion.button
                key={tab}
                whileTap={{ scale: 0.95 }}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-xl border-3 border-black font-black text-xs whitespace-nowrap shadow-[0_3px_0_rgba(0,0,0,0.8)] transition-all ${
                  activeTab === tab
                    ? 'bg-[#39FF14] text-black'
                    : 'bg-[#5A5A7A] text-white'
                }`}
              >
                {tab.toUpperCase()}
              </motion.button>
            ))}
          </div>
        </div>

        {/* Boost Grid */}
        <div className="flex-1 overflow-y-auto px-5 pb-24">
          <div className="grid grid-cols-2 gap-3">
            {filteredBoosts.map((boost, idx) => (
              <motion.div
                key={boost.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.05 }}
              >
                <BoostCard boost={boost} onClick={() => setSelectedBoost(boost)} />
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Boost Detail Modal */}
      <AnimatePresence>
        {selectedBoost && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/80 z-50 flex items-center justify-center p-5"
            onClick={() => setSelectedBoost(null)}
          >
            <motion.div
              initial={{ scale: 0.8, y: 50 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.8, y: 50 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-sm"
            >
              <div className="bg-[#F5F5DC] border-[6px] border-black rounded-3xl p-5 shadow-[0_8px_0_rgba(0,0,0,0.8)]">
                {/* Close Button */}
                <button
                  onClick={() => setSelectedBoost(null)}
                  className="absolute top-3 right-3 w-8 h-8 bg-black rounded-full flex items-center justify-center"
                >
                  <CloseIcon size={16} className="text-white" />
                </button>

                {/* Boost Card Large */}
                <div className="flex justify-center mb-4">
                  <BoostCard boost={selectedBoost} size="large" />
                </div>

                {/* Details */}
                <div className="space-y-3">
                  <div className="bg-white border-3 border-black rounded-xl p-3">
                    <h4 className="font-black text-xs text-black mb-2">EFFECT</h4>
                    <p className="text-sm font-bold text-black">{selectedBoost.effect}</p>
                  </div>

                  <div className="bg-white border-3 border-black rounded-xl p-3">
                    <h4 className="font-black text-xs text-black mb-2">DESCRIPTION</h4>
                    <p className="text-xs font-bold text-black leading-relaxed">{selectedBoost.description}</p>
                  </div>

                  <div className="bg-[#7B2CBF] border-3 border-black rounded-xl p-3">
                    <p className="text-xs font-bold text-white italic text-center">"{selectedBoost.flavorText}"</p>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2">
                    {selectedBoost.owned ? (
                      <motion.button
                        whileTap={{ scale: 0.95 }}
                        className={`flex-1 py-3 rounded-xl border-3 border-black font-black text-sm shadow-[0_4px_0_rgba(0,0,0,0.8)] active:translate-y-1 transition-all ${
                          selectedBoost.equipped
                            ? 'bg-[#FF006E] text-white'
                            : 'bg-[#39FF14] text-black'
                        }`}
                      >
                        {selectedBoost.equipped ? 'UNEQUIP' : 'EQUIP'}
                      </motion.button>
                    ) : (
                      <motion.button
                        whileTap={{ scale: 0.95 }}
                        className="flex-1 py-3 bg-[#FFD60A] border-3 border-black rounded-xl font-black text-sm text-black shadow-[0_4px_0_rgba(0,0,0,0.8)] active:translate-y-1 transition-all"
                      >
                        UNLOCK (500 🏆)
                      </motion.button>
                    )}
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <style>{`
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}

function BackIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M15 18L9 12L15 6" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

function PlusIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M12 5V19M5 12H19" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
    </svg>
  );
}

function CloseIcon({ size = 24, className = '' }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
    </svg>
  );
}
