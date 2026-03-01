import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, CheckCircle, AlertCircle, Info, TrendingUp, TrendingDown } from 'lucide-react';

interface ToastProps {
  type?: 'success' | 'error' | 'info' | 'positive' | 'negative';
  message: string;
  isVisible: boolean;
  onClose: () => void;
}

export function Toast({ type = 'info', message, isVisible, onClose }: ToastProps) {
  const icons = {
    success: <CheckCircle size={20} />,
    error: <AlertCircle size={20} />,
    info: <Info size={20} />,
    positive: <TrendingUp size={20} />,
    negative: <TrendingDown size={20} />,
  };

  const colors = {
    success: 'bg-[var(--neon-green)]/20 border-[var(--neon-green)]/40 text-[var(--neon-green)]',
    error: 'bg-[var(--neon-magenta)]/20 border-[var(--neon-magenta)]/40 text-[var(--neon-magenta)]',
    info: 'bg-[var(--neon-cyan)]/20 border-[var(--neon-cyan)]/40 text-[var(--neon-cyan)]',
    positive: 'bg-[var(--neon-green)]/20 border-[var(--neon-green)]/40 text-[var(--neon-green)]',
    negative: 'bg-[var(--neon-magenta)]/20 border-[var(--neon-magenta)]/40 text-[var(--neon-magenta)]',
  };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 0, y: -50, scale: 0.9 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -50, scale: 0.9 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className={`fixed top-20 left-1/2 -translate-x-1/2 z-50 px-4 py-3 rounded-2xl border backdrop-blur-md shadow-lg flex items-center gap-3 min-w-[280px] ${colors[type]}`}
        >
          {icons[type]}
          <span className="flex-1 font-semibold text-sm">{message}</span>
          <button 
            onClick={onClose}
            className="p-1 hover:opacity-70 transition-opacity"
          >
            <X size={16} />
          </button>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

// Example usage component
export function ToastDemo() {
  const [toast, setToast] = React.useState<{ type: ToastProps['type']; message: string; visible: boolean }>({
    type: 'info',
    message: '',
    visible: false,
  });

  const showToast = (type: ToastProps['type'], message: string) => {
    setToast({ type, message, visible: true });
    setTimeout(() => setToast(prev => ({ ...prev, visible: false })), 3000);
  };

  return (
    <>
      <Toast 
        type={toast.type} 
        message={toast.message} 
        isVisible={toast.visible}
        onClose={() => setToast(prev => ({ ...prev, visible: false }))}
      />
      <div className="flex flex-wrap gap-2">
        <button onClick={() => showToast('success', 'Quest completed!')} className="px-3 py-1 bg-green-500/20 text-green-500 rounded text-xs">Success</button>
        <button onClick={() => showToast('positive', 'STABLE +3')} className="px-3 py-1 bg-green-500/20 text-green-500 rounded text-xs">Positive</button>
        <button onClick={() => showToast('negative', 'RAGE FLICK -5')} className="px-3 py-1 bg-pink-500/20 text-pink-500 rounded text-xs">Negative</button>
        <button onClick={() => showToast('info', 'Opponent found!')} className="px-3 py-1 bg-cyan-500/20 text-cyan-500 rounded text-xs">Info</button>
        <button onClick={() => showToast('error', 'Connection lost')} className="px-3 py-1 bg-pink-500/20 text-pink-500 rounded text-xs">Error</button>
      </div>
    </>
  );
}
