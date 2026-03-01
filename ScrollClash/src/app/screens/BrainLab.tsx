import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useNavigate } from 'react-router';
import { useBrainCustomization } from '../../features/brainLab/context/BrainCustomizationContext';
import { BrainCharacter } from '../../shared/components/BrainCharacter';
import bgStripes from 'figma:asset/d15f16afd73490c81f62b0e3a817dd8607561ada.png';

type Category = 'hats' | 'glasses' | 'expressions' | 'skins' | 'effects' | 'accessories';

interface CustomizationItem {
  id: string;
  name: string;
}

const customizationData = {
  hats: [
    { id: 'none', name: 'None' },
    { id: 'crown', name: 'Crown' },
    { id: 'beanie', name: 'Beanie' },
    { id: 'wizard', name: 'Wizard Hat' },
    { id: 'headset', name: 'Headset' },
    { id: 'tophat', name: 'Top Hat' },
    { id: 'helmet', name: 'Helmet' },
  ],
  glasses: [
    { id: 'none', name: 'None' },
    { id: 'sunglasses', name: 'Sunglasses' },
    { id: 'pixel', name: 'Pixel Shades' },
    { id: 'nerd', name: 'Nerd Glasses' },
    { id: 'visor', name: 'Visor' },
  ],
  expressions: [
    { id: 'happy', name: 'Happy' },
    { id: 'determined', name: 'Determined' },
    { id: 'sleepy', name: 'Sleepy' },
    { id: 'angry', name: 'Angry' },
    { id: 'hypnotized', name: 'Hypnotized' },
    { id: 'confident', name: 'Confident' },
  ],
  skins: [
    { id: 'classic', name: 'Classic Pink' },
    { id: 'toxic', name: 'Toxic Green' },
    { id: 'purple', name: 'Royal Purple' },
    { id: 'cyber', name: 'Neon Cyber' },
    { id: 'lava', name: 'Lava Cracked' },
    { id: 'frozen', name: 'Frozen' },
    { id: 'chrome', name: 'Chrome' },
  ],
  effects: [
    { id: 'none', name: 'None' },
    { id: 'purple-aura', name: 'Purple Aura' },
    { id: 'green-flame', name: 'Green Flame' },
    { id: 'electric', name: 'Electric' },
    { id: 'particles', name: 'Particles' },
    { id: 'glitch', name: 'Glitch' },
  ],
  accessories: [
    { id: 'none', name: 'None' },
    { id: 'spoon', name: 'Spoon' },
    { id: 'lighter', name: 'Lighter' },
    { id: 'sword', name: 'Sword' },
    { id: 'shield', name: 'Shield' },
  ],
};

export default function BrainLab() {
  const navigate = useNavigate();
  const { customization, updateCustomization } = useBrainCustomization();
  const [activeCategory, setActiveCategory] = useState<Category>('hats');
  const [selectedItems, setSelectedItems] = useState({
    hat: customization.hat,
    glasses: customization.glasses,
    expression: customization.expression,
    skin: customization.skin,
    effect: customization.effect,
    accessory: customization.accessory,
  });

  const handleItemSelect = (category: Category, itemId: string) => {
    const key = category === 'hats' ? 'hat' : category === 'expressions' ? 'expression' : category === 'accessories' ? 'accessory' : category.slice(0, -1);
    setSelectedItems({ ...selectedItems, [key]: itemId });
  };

  const handleSave = () => {
    updateCustomization({
      hat: selectedItems.hat,
      glasses: selectedItems.glasses,
      expression: selectedItems.expression,
      skin: selectedItems.skin,
      effect: selectedItems.effect,
      accessory: selectedItems.accessory,
    });
    navigate('/profile');
  };

  const getCurrentSelection = (category: Category) => {
    if (category === 'hats') return selectedItems.hat;
    if (category === 'glasses') return selectedItems.glasses;
    if (category === 'expressions') return selectedItems.expression;
    if (category === 'skins') return selectedItems.skin;
    if (category === 'effects') return selectedItems.effect;
    if (category === 'accessories') return selectedItems.accessory;
    return 'none';
  };

  const categories: { id: Category; label: string }[] = [
    { id: 'hats', label: 'Hats' },
    { id: 'glasses', label: 'Glasses' },
    { id: 'expressions', label: 'Face' },
    { id: 'skins', label: 'Skins' },
    { id: 'effects', label: 'Effects' },
    { id: 'accessories', label: 'Items' },
  ];

  return (
    <div className="h-screen relative text-white overflow-hidden flex flex-col">
      {/* Striped Background */}
      <div className="absolute inset-0">
        <img src={bgStripes} alt="" className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-black/30" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col h-full">
        {/* iOS Status Bar */}
        <div className="h-12" />

        {/* Header */}
        <div className="px-5 mb-3 flex-shrink-0">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              {/* Back Button */}
              <motion.button
                whileTap={{ scale: 0.9 }}
                onClick={() => navigate('/profile')}
                className="w-10 h-10 rounded-full bg-[#7B2CBF] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path d="M15 18L9 12L15 6" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </motion.button>
              
              <div className="w-10 h-10 rounded-full bg-[#FFD60A] border-3 border-black flex items-center justify-center shadow-[0_3px_0_rgba(0,0,0,0.8)]">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M12 3C7 3 3 7 3 12C3 14 4 16 6 16C7 16 8 15 8 14C8 13 7 12 7 11C7 8 9 6 12 6C15 6 18 8 18 11C18 15 15 18 12 18C11 18 10 17 10 16" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
                  <circle cx="9" cy="10" r="1.5" fill="#000"/>
                  <circle cx="15" cy="9" r="1.5" fill="#000"/>
                </svg>
              </div>
              <div>
                <h1 className="text-2xl font-black text-white" style={{ textShadow: '3px 3px 0 rgba(0,0,0,0.5)' }}>
                  BRAIN LAB
                </h1>
                <p className="text-xs font-bold text-white/80">Customize your brain</p>
              </div>
            </div>

            {/* Trophies Balance */}
            <div className="px-3 py-1.5 rounded-full bg-[#FFD60A] border-3 border-black shadow-[0_3px_0_rgba(0,0,0,0.8)]">
              <span className="text-sm font-black text-black">1,204</span>
            </div>
          </div>
        </div>

        {/* Brain Preview - Center Stage */}
        <div className="px-5 mb-4 flex-shrink-0">
          <motion.div
            className="rounded-3xl bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] border-4 border-black p-6 shadow-[0_8px_0_rgba(0,0,0,0.8)] relative overflow-hidden"
          >
            {/* Background pattern */}
            <div className="absolute inset-0 opacity-10">
              <div className="absolute inset-0" style={{ 
                backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(255,255,255,0.1) 10px, rgba(255,255,255,0.1) 20px)'
              }} />
            </div>

            {/* Brain with Effects */}
            <div className="relative flex justify-center">
              <AnimatePresence mode="wait">
                <motion.div
                  key={`${selectedItems.hat}-${selectedItems.glasses}-${selectedItems.effect}`}
                  initial={{ scale: 0.8, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ type: 'spring', stiffness: 300 }}
                  className="relative"
                >
                  {/* Effect Layer - Behind */}
                  {renderEffect(selectedItems.effect)}

                  {/* Brain Character */}
                  <div className="relative z-10">
                    <BrainCharacter 
                      customization={{
                        skin: selectedItems.skin,
                        expression: selectedItems.expression,
                        hat: selectedItems.hat,
                        glasses: selectedItems.glasses,
                        accessory: selectedItems.accessory,
                        effect: selectedItems.effect,
                      }}
                      rotLevel={20} 
                      size={140} 
                      showArms={true} 
                    />
                  </div>

                  {/* Hat Layer - On Top */}
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 z-20">
                    {renderHat(selectedItems.hat)}
                  </div>

                  {/* Glasses Layer */}
                  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-20">
                    {renderGlasses(selectedItems.glasses)}
                  </div>
                </motion.div>
              </AnimatePresence>
            </div>
          </motion.div>
        </div>

        {/* Category Tabs */}
        <div className="px-5 mb-3 flex-shrink-0">
          <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-2">
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
                className={`flex-shrink-0 px-4 py-2 rounded-xl font-black text-xs transition-all border-3 border-black ${
                  activeCategory === cat.id
                    ? 'bg-[#39FF14] text-black shadow-[0_4px_0_rgba(0,0,0,0.8)]'
                    : 'bg-[#7B2CBF] text-white shadow-[0_3px_0_rgba(0,0,0,0.8)]'
                }`}
              >
                {cat.label.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Items Grid */}
        <div className="flex-1 px-5 overflow-y-auto pb-32">
          <div className="grid grid-cols-3 gap-3">
            {customizationData[activeCategory].map((item) => (
              <ItemCard
                key={item.id}
                item={item}
                isSelected={getCurrentSelection(activeCategory) === item.id}
                onSelect={() => handleItemSelect(activeCategory, item.id)}
                category={activeCategory}
              />
            ))}
          </div>
        </div>

        {/* Save Button - Fixed Bottom */}
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-[#1a0040] to-transparent px-5 pt-4 pb-8">
          <motion.button
            whileTap={{ scale: 0.95, y: 2 }}
            onClick={handleSave}
            className="w-full h-14 bg-[#39FF14] border-4 border-black rounded-xl font-black text-lg text-black shadow-[0_6px_0_rgba(0,0,0,0.8)] relative overflow-hidden"
          >
            <motion.div
              animate={{ 
                x: ['0%', '100%'],
              }}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'linear' }}
              className="absolute top-0 left-0 w-8 h-full bg-white/40 skew-x-12"
            />
            <span className="relative">SAVE & EQUIP</span>
          </motion.button>
        </div>
      </div>

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

function ItemCard({ 
  item, 
  isSelected, 
  onSelect,
  category 
}: { 
  item: CustomizationItem; 
  isSelected: boolean;
  onSelect: () => void;
  category: Category;
}) {
  return (
    <motion.button
      whileTap={{ scale: 0.95 }}
      onClick={onSelect}
      className={`relative rounded-xl border-3 border-black p-3 text-center transition-all ${
        isSelected 
          ? 'bg-[#39FF14] shadow-[0_4px_0_rgba(0,0,0,0.8)]' 
          : 'bg-[#9D4EDD] shadow-[0_4px_0_rgba(0,0,0,0.8)]'
      }`}
    >
      {/* Selection Glow */}
      {isSelected && (
        <motion.div
          animate={{
            opacity: [0.5, 1, 0.5],
          }}
          transition={{ duration: 1.5, repeat: Infinity }}
          className="absolute -inset-1 bg-[#39FF14] rounded-xl blur-md -z-10"
        />
      )}

      {/* Preview Icon */}
      <div className="h-12 flex items-center justify-center mb-2">
        {renderItemPreview(category, item.id)}
      </div>

      {/* Name */}
      <div className={`text-[10px] font-black mb-1 ${isSelected ? 'text-black' : 'text-white'}`}>
        {item.name.toUpperCase()}
      </div>

      {/* Status */}
      {isSelected ? (
        <div className="text-[8px] font-black text-black">EQUIPPED</div>
      ) : (
        <div className="text-[8px] font-black text-white/60">TAP TO USE</div>
      )}
    </motion.button>
  );
}

// Rest of the render functions...
function renderItemPreview(category: Category, itemId: string) {
  if (itemId === 'none') return <div className="text-2xl">—</div>;

  const size = 40;
  
  switch (category) {
    case 'hats':
      return renderHat(itemId, size);
    case 'glasses':
      return renderGlasses(itemId, size);
    case 'expressions':
      return <BrainCharacter rotLevel={getRotForExpression(itemId)} size={size} showArms={false} />;
    case 'skins':
      return <div className="w-8 h-8 rounded-full border-2 border-black" style={{ backgroundColor: getSkinColor(itemId) }} />;
    case 'effects':
      return <div className="text-2xl">{getEffectEmoji(itemId)}</div>;
    case 'accessories':
      return <div className="text-2xl">{getAccessoryEmoji(itemId)}</div>;
    default:
      return null;
  }
}

function getRotForExpression(expression: string): number {
  const rotLevels: Record<string, number> = {
    happy: 15,
    determined: 25,
    sleepy: 55,
    angry: 45,
    hypnotized: 50,
    confident: 20,
  };
  return rotLevels[expression] || 20;
}

// Import all the render functions from the previous implementation
function renderHat(hatId: string, size = 60) {
  if (hatId === 'none') return null;

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

function renderGlasses(glassesId: string, size = 60) {
  if (glassesId === 'none') return null;

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

function renderEffect(effectId: string) {
  switch (effectId) {
    case 'purple-aura':
      return (
        <motion.div
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.4, 0.7, 0.4],
          }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute inset-0 -m-8 rounded-full bg-[#9D4EDD] blur-2xl"
        />
      );
    case 'green-flame':
      return (
        <motion.div className="absolute -top-4 left-1/2 -translate-x-1/2">
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
          className="absolute inset-0"
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
          ))};
        </motion.div>
      );
    case 'particles':
      return (
        <div className="absolute inset-0">
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
          className="absolute inset-0 bg-[#FF006E] opacity-30 mix-blend-screen"
        />
      );
    default:
      return null;
  }
}

function getSkinColor(skinId: string): string {
  const colors: Record<string, string> = {
    classic: '#FFB3D1',
    toxic: '#39FF14',
    purple: '#9D4EDD',
    cyber: '#4CC9F0',
    lava: '#FF6B35',
    frozen: '#B8E0F6',
    chrome: '#C0C0C0',
  };
  return colors[skinId] || '#FFB3D1';
}

function getEffectEmoji(effectId: string): string {
  const emojis: Record<string, string> = {
    'purple-aura': '💜',
    'green-flame': '🔥',
    'electric': '⚡',
    'particles': '✨',
    'glitch': '📺',
  };
  return emojis[effectId] || '';
}

function getAccessoryEmoji(accessoryId: string): string {
  const emojis: Record<string, string> = {
    spoon: '🥄',
    lighter: '🔥',
    sword: '⚔️',
    shield: '🛡️',
  };
  return emojis[accessoryId] || '';
}