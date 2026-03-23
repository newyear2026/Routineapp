import { motion } from 'motion/react';

export function CharacterReaction() {
  return (
    <div className="flex items-center gap-4 p-4 rounded-2xl" 
         style={{ 
           background: 'linear-gradient(135deg, rgba(255, 244, 235, 0.5) 0%, rgba(255, 239, 245, 0.5) 100%)'
         }}>
      {/* Character */}
      <motion.div
        className="relative"
        animate={{ 
          y: [0, -8, 0],
        }}
        transition={{ 
          duration: 2,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      >
        <div className="w-16 h-16 rounded-full flex items-center justify-center text-4xl"
             style={{ 
               background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
               boxShadow: '0 4px 12px rgba(255, 184, 198, 0.3)'
             }}>
          🐻
        </div>
        
        {/* Character Speech Bubble */}
        <motion.div
          className="absolute -top-8 -right-2 bg-white rounded-full px-2 py-1 text-xs shadow-lg"
          style={{ color: '#FFB8C6' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.5, type: 'spring' }}
        >
          💪
        </motion.div>
      </motion.div>

      {/* Message */}
      <div className="flex-1">
        <div className="text-sm mb-1" style={{ color: '#8B7B9E' }}>
          화이팅! 곧 끝나요
        </div>
        <div className="text-xs" style={{ color: '#B8A4C9' }}>
          조금만 더 힘내봐요 ✨
        </div>
      </div>
    </div>
  );
}
