import React from 'react';
import { Trophy, Award, Medal } from 'lucide-react';

interface RankIconProps {
  rank: number;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function RankIcon({ rank, size = 'md', className = '' }: RankIconProps) {
  const sizes = {
    sm: 'w-8 h-8',
    md: 'w-12 h-12',
    lg: 'w-16 h-16',
  };

  const iconSizes = {
    sm: 16,
    md: 20,
    lg: 28,
  };

  const getRankColor = () => {
    if (rank === 1) return 'from-yellow-400 to-yellow-600';
    if (rank === 2) return 'from-gray-300 to-gray-500';
    if (rank === 3) return 'from-orange-400 to-orange-600';
    return 'from-[var(--neon-purple)] to-[var(--neon-purple-light)]';
  };

  const getRankIcon = () => {
    if (rank <= 3) return <Trophy size={iconSizes[size]} />;
    if (rank <= 10) return <Award size={iconSizes[size]} />;
    return <Medal size={iconSizes[size]} />;
  };

  return (
    <div className={`${sizes[size]} rounded-full bg-gradient-to-br ${getRankColor()} flex items-center justify-center shadow-lg ${className}`}>
      <div className="text-white">
        {getRankIcon()}
      </div>
    </div>
  );
}
