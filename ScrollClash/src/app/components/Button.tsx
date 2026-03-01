import React from 'react';
import { motion } from 'motion/react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'tertiary' | 'danger';
  children: React.ReactNode;
}

export function Button({ variant = 'primary', children, className = '', ...props }: ButtonProps) {
  const baseClasses = 'px-6 rounded-[20px] transition-all duration-200 active:scale-[0.96] disabled:opacity-50 disabled:cursor-not-allowed';
  
  const variantClasses = {
    primary: 'h-14 bg-[var(--neon-green)] text-[#000] font-bold shadow-[0_0_20px_rgba(57,255,20,0.4)] hover:shadow-[0_0_30px_rgba(57,255,20,0.6)]',
    secondary: 'h-12 bg-transparent border-2 border-[var(--neon-purple)] text-[var(--neon-purple)] font-semibold hover:bg-[var(--neon-purple)]/10',
    tertiary: 'h-12 bg-[var(--neon-card)] text-[var(--neon-text)] font-semibold border border-[var(--neon-card-border)] hover:bg-[var(--neon-card-border)]',
    danger: 'h-12 bg-transparent border-2 border-[var(--neon-magenta)] text-[var(--neon-magenta)] font-semibold hover:bg-[var(--neon-magenta)]/10',
  };

  return (
    <motion.button
      whileTap={{ scale: 0.96 }}
      className={`${baseClasses} ${variantClasses[variant]} ${className}`}
      {...props}
    >
      {children}
    </motion.button>
  );
}
