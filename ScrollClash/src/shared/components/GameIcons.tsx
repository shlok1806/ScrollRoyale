import React from 'react';

// Custom Game Icons as SVG components

export const TrophyIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M7 6H5C4 6 3 7 3 8C3 10 4 11 6 11H7M17 6H19C20 6 21 7 21 8C21 10 20 11 18 11H17" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
    <path d="M7 6V11C7 14 9 16 12 16C15 16 17 14 17 11V6H7Z" fill="currentColor" stroke="currentColor" strokeWidth="2"/>
    <rect x="8" y="16" width="8" height="4" rx="1" fill="currentColor"/>
    <rect x="6" y="20" width="12" height="2" rx="1" fill="currentColor"/>
    <circle cx="12" cy="9" r="1.5" fill="white" opacity="0.5"/>
  </svg>
);

export const FlameIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M12 3C12 3 8 8 8 12C8 15 10 17 12 17C14 17 16 15 16 12C16 8 12 3 12 3Z" fill="currentColor" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round"/>
    <path d="M12 7C12 7 10 10 10 12C10 13.5 11 14.5 12 14.5C13 14.5 14 13.5 14 12C14 10 12 7 12 7Z" fill="white" opacity="0.5"/>
  </svg>
);

export const BrainShieldIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M12 3L4 6V11C4 16 7 20 12 21C17 20 20 16 20 11V6L12 3Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
    <circle cx="10" cy="11" r="1.5" fill="white"/>
    <circle cx="14" cy="11" r="1.5" fill="white"/>
    <path d="M8 13C8 13 9 15 12 15C15 15 16 13 16 13" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
  </svg>
);

export const RotWarningIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M12 4C7 4 4 7 4 12C4 17 7 20 12 20C17 20 20 17 20 12C20 7 17 4 12 4Z" fill="currentColor" stroke="currentColor" strokeWidth="2"/>
    <path d="M8 10L10 12M14 12L16 10M9 16C9 16 10 17 12 17C14 17 15 16 15 16" stroke="#000" strokeWidth="1.5" strokeLinecap="round"/>
    <path d="M7 8L9 6M15 6L17 8" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const CrownIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M4 16L6 8L12 12L18 8L20 16H4Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
    <circle cx="6" cy="8" r="2" fill="currentColor" stroke="currentColor" strokeWidth="1.5"/>
    <circle cx="12" cy="6" r="2" fill="currentColor" stroke="currentColor" strokeWidth="1.5"/>
    <circle cx="18" cy="8" r="2" fill="currentColor" stroke="currentColor" strokeWidth="1.5"/>
    <rect x="4" y="16" width="16" height="3" fill="currentColor"/>
  </svg>
);

export const BrainVSIcon = ({ size = 32, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 32 32" fill="none" className={className}>
    <circle cx="16" cy="16" r="14" fill="currentColor" stroke="#000" strokeWidth="3"/>
    <text x="16" y="20" textAnchor="middle" fontSize="14" fontWeight="900" fill="#000">VS</text>
    <path d="M8 12C8 12 10 10 12 11M20 11C20 11 22 10 24 12" stroke="#000" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const LightningIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M13 2L3 14H11L9 22L21 10H13L13 2Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
  </svg>
);

export const TargetIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" fill="none"/>
    <circle cx="12" cy="12" r="5" stroke="currentColor" strokeWidth="2" fill="none"/>
    <circle cx="12" cy="12" r="2" fill="currentColor"/>
  </svg>
);

export const ZapIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M13 3L4 14H12L11 21L20 10H12L13 3Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
    <circle cx="13" cy="8" r="1.5" fill="white" opacity="0.6"/>
  </svg>
);

export const StarIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M12 2L15 9L22 10L17 15L18 22L12 18L6 22L7 15L2 10L9 9L12 2Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
    <circle cx="12" cy="10" r="1.5" fill="white" opacity="0.5"/>
  </svg>
);

export const SettingsIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2"/>
    <path d="M12 2V5M12 19V22M22 12H19M5 12H2M19.07 4.93L16.95 7.05M7.05 16.95L4.93 19.07M19.07 19.07L16.95 16.95M7.05 7.05L4.93 4.93" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const CalendarIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <rect x="3" y="6" width="18" height="15" rx="2" stroke="currentColor" strokeWidth="2" fill="none"/>
    <path d="M3 10H21M8 3V7M16 3V7" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const ActivityIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M3 12H7L10 6L14 18L17 12H21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
  </svg>
);

export const TrendingUpIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M3 17L9 11L13 15L21 7M21 7V12M21 7H16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

export const AwardIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="12" cy="10" r="6" fill="currentColor" stroke="currentColor" strokeWidth="2"/>
    <path d="M8 14L7 22L12 19L17 22L16 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <circle cx="12" cy="10" r="3" fill="white" opacity="0.4"/>
  </svg>
);

export const UserGroupIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="9" cy="8" r="4" stroke="currentColor" strokeWidth="2" fill="none"/>
    <path d="M3 20C3 16 5 14 9 14C13 14 15 16 15 20" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
    <path d="M17 14C19 14 21 15 21 18M17 8C18.5 8 19.5 6.5 19.5 5C19.5 3.5 18.5 2 17 2" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const CloseIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M6 6L18 18M18 6L6 18" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
  </svg>
);

export const GlobeIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" fill="none"/>
    <path d="M3 12H21M12 3C14 6 14 18 12 21M12 3C10 6 10 18 12 21" stroke="currentColor" strokeWidth="2"/>
  </svg>
);

export const HomeIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M3 12L12 3L21 12M5 10V20H10V15H14V20H19V10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
  </svg>
);

export const GhostIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M12 3C7 3 4 6 4 11V20L7 18L10 20L12 18L14 20L17 18L20 20V11C20 6 17 3 12 3Z" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"/>
    <circle cx="9" cy="10" r="1.5" fill="#000"/>
    <circle cx="15" cy="10" r="1.5" fill="#000"/>
    <path d="M9 13C9 13 10 14 12 14C14 14 15 13 15 13" stroke="#000" strokeWidth="1.5" strokeLinecap="round"/>
  </svg>
);

export const UserIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="2" fill="none"/>
    <path d="M4 20C4 16 7 14 12 14C17 14 20 16 20 20" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export const SwordsIcon = ({ size = 24, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
    <path d="M5 5L10 10M19 5L14 10M10 10L5 15L9 19L14 14M14 10L19 15L15 19L10 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    <circle cx="12" cy="12" r="2" fill="currentColor"/>
  </svg>
);
