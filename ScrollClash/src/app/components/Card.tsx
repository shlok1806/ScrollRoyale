import React from 'react';

interface CardProps {
  variant?: 'normal' | 'highlighted' | 'danger';
  children: React.ReactNode;
  className?: string;
}

export function Card({ variant = 'normal', children, className = '' }: CardProps) {
  const baseClasses = 'rounded-[20px] p-6 backdrop-blur-sm transition-all duration-200';
  
  const variantClasses = {
    normal: 'bg-[var(--neon-card)] border border-[var(--neon-card-border)]',
    highlighted: 'bg-gradient-to-br from-[var(--neon-purple)]/20 to-[var(--neon-cyan)]/10 border border-[var(--neon-purple)]/40 shadow-[0_0_20px_rgba(124,58,237,0.2)]',
    danger: 'bg-[var(--neon-magenta)]/10 border border-[var(--neon-magenta)]/40 shadow-[0_0_20px_rgba(255,61,129,0.2)]',
  };

  return (
    <div className={`${baseClasses} ${variantClasses[variant]} ${className}`}>
      {children}
    </div>
  );
}
