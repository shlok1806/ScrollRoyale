import { Outlet, useNavigate, useLocation } from 'react-router';
import { motion } from 'motion/react';
import { BrainCustomizationProvider } from '../features/brainLab/context/BrainCustomizationContext';
import { MatchProvider } from '../contexts/MatchContext';
import { HomeIcon, TrophyIcon, GhostIcon, UserIcon, SwordsIcon } from '../shared/components/GameIcons';

export default function Root() {
  const navigate = useNavigate();
  const location = useLocation();

  const getActiveTab = () => {
    const path = location.pathname;
    if (path === '/') return 'home';
    if (path.startsWith('/leaderboard')) return 'leaderboard';
    if (path.startsWith('/graveyard')) return 'graveyard';
    if (path.startsWith('/profile')) return 'profile';
    return 'home';
  };

  const handleTabChange = (tab: string) => {
    const routes: Record<string, string> = {
      home: '/',
      leaderboard: '/leaderboard',
      graveyard: '/graveyard',
      profile: '/profile',
    };
    navigate(routes[tab]);
  };

  const handleDuelClick = () => {
    navigate('/duel');
  };

  // Hide tab bar on duel screens and brain lab
  const hideTabBarPaths = ['/duel', '/duel/arena', '/duel/result', '/brain-lab', '/boosts'];
  const hideTabBar = hideTabBarPaths.some(path => location.pathname.startsWith(path));

  return (
    <MatchProvider>
    <BrainCustomizationProvider>
      <div className="relative h-screen overflow-hidden bg-black">
        <Outlet />
        
        {/* Bottom Tab Bar - Only show on main screens */}
        {!hideTabBar && (
          <motion.div
            className="absolute bottom-0 left-0 right-0 z-50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <TabBar 
              activeTab={getActiveTab()}
              onTabChange={handleTabChange}
              onDuelClick={handleDuelClick}
            />
          </motion.div>
        )}
      </div>
    </BrainCustomizationProvider>
    </MatchProvider>
  );
}

function TabBar({ activeTab, onTabChange, onDuelClick }: { activeTab: string, onTabChange: (tab: string) => void, onDuelClick: () => void }) {
  return (
    <div className="flex justify-around items-center bg-[#050509] border-t-4 border-black text-white py-3 px-2 shadow-[0_-4px_0_rgba(0,0,0,0.5)]">
      <button 
        onClick={() => onTabChange('home')} 
        className={`flex flex-col items-center gap-1 transition-all ${activeTab === 'home' ? 'text-[#39FF14]' : 'text-white/60'}`}
      >
        <HomeIcon size={24} />
      </button>
      <button 
        onClick={() => onTabChange('leaderboard')} 
        className={`flex flex-col items-center gap-1 transition-all ${activeTab === 'leaderboard' ? 'text-[#39FF14]' : 'text-white/60'}`}
      >
        <TrophyIcon size={24} />
      </button>
      <button 
        onClick={onDuelClick} 
        className="flex flex-col items-center gap-1 transition-all text-[#FF006E]"
      >
        <div className="w-14 h-14 -mt-6 rounded-full bg-[#FF006E] border-4 border-black flex items-center justify-center shadow-[0_4px_0_rgba(0,0,0,0.8)]">
          <SwordsIcon size={28} className="text-white" />
        </div>
      </button>
      <button 
        onClick={() => onTabChange('graveyard')} 
        className={`flex flex-col items-center gap-1 transition-all ${activeTab === 'graveyard' ? 'text-[#39FF14]' : 'text-white/60'}`}
      >
        <GhostIcon size={24} />
      </button>
      <button 
        onClick={() => onTabChange('profile')} 
        className={`flex flex-col items-center gap-1 transition-all ${activeTab === 'profile' ? 'text-[#39FF14]' : 'text-white/60'}`}
      >
        <UserIcon size={24} />
      </button>
    </div>
  );
}