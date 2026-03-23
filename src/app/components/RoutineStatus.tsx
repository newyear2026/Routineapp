import { motion } from 'motion/react';
import { Check, Clock, X } from 'lucide-react';

interface RoutineStatusProps {
  onComplete: () => void;
  onLater: () => void;
  onSkip: () => void;
}

export function RoutineStatus({ onComplete, onLater, onSkip }: RoutineStatusProps) {
  return (
    <div className="flex gap-3">
      {/* Complete Button */}
      <motion.button
        className="flex-1 py-4 rounded-2xl flex items-center justify-center gap-2 shadow-lg"
        style={{
          background: 'linear-gradient(135deg, #D4E4FF 0%, #C5D5F0 100%)',
          color: '#6B8BC9'
        }}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={onComplete}
      >
        <Check className="w-5 h-5" />
        <span>완료</span>
      </motion.button>

      {/* Later Button */}
      <motion.button
        className="flex-1 py-4 rounded-2xl flex items-center justify-center gap-2 shadow-lg"
        style={{
          background: 'linear-gradient(135deg, #FFE9D4 0%, #FFDDC5 100%)',
          color: '#D9A57B'
        }}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={onLater}
      >
        <Clock className="w-5 h-5" />
        <span>나중에</span>
      </motion.button>

      {/* Skip Button */}
      <motion.button
        className="py-4 px-5 rounded-2xl flex items-center justify-center shadow-lg"
        style={{
          background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
          color: '#D99BB0'
        }}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={onSkip}
      >
        <X className="w-5 h-5" />
      </motion.button>
    </div>
  );
}
