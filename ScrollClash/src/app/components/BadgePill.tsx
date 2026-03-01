import React from 'react';

interface BadgePillProps {
  children: React.ReactNode;
  variant?: 'green' | 'purple' | 'cyan' | 'magenta' | 'default';
  className?: string;
}

export function BadgePill({ children, variant = 'default', className = '' }: BadgePillProps) {
  const variantClasses = {
    green: 'bg-[var(--neon-green)]/20 text-[var(--neon-green)] border-[var(--neon-green)]/40',
    purple: 'bg-[var(--neon-purple)]/20 text-[var(--neon-purple)] border-[var(--neon-purple)]/40',
    cyan: 'bg-[var(--neon-cyan)]/20 text-[var(--neon-cyan)] border-[var(--neon-cyan)]/40',
    magenta: 'bg-[var(--neon-magenta)]/20 text-[var(--neon-magenta)] border-[var(--neon-magenta)]/40',
    default: 'bg-[var(--neon-card)] text-[var(--neon-text-muted)] border-[var(--neon-card-border)]',
  };

  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${variantClasses[variant]} ${className}`}>
      {children}
    </span>
  );
}
