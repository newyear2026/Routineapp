import { motion } from 'motion/react';

interface ProgressCardProps {
  completed: number;
  total: number;
}

export function ProgressCard({ completed, total }: ProgressCardProps) {
  const percentage = Math.round((completed / total) * 100);

  return (
    <motion.div
      className="rounded-3xl p-5 shadow-lg"
      style={{
        background: 'linear-gradient(135deg, #FFFFFF 0%, #F5F0FF 100%)',
        border: '2px solid rgba(196, 181, 230, 0.2)'
      }}
      initial={{ y: 20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.5, delay: 0.6 }}
    >
      <div className="flex items-center justify-between mb-4">
        <h4 className="text-lg" style={{ color: '#8B7B9E' }}>오늘의 진행률</h4>
        <span className="text-sm" style={{ color: '#B8A4C9' }}>
          {completed}/{total}
        </span>
      </div>

      {/* Circular Progress */}
      <div className="flex items-center gap-6">
        <div className="relative w-28 h-28">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
            {/* Background Circle */}
            <circle
              cx="50"
              cy="50"
              r="42"
              fill="none"
              stroke="rgba(184, 164, 201, 0.2)"
              strokeWidth="8"
            />
            
            {/* Progress Circle */}
            <motion.circle
              cx="50"
              cy="50"
              r="42"
              fill="none"
              stroke="url(#progressGradient)"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${2 * Math.PI * 42}`}
              initial={{ strokeDashoffset: 2 * Math.PI * 42 }}
              animate={{ 
                strokeDashoffset: 2 * Math.PI * 42 * (1 - percentage / 100)
              }}
              transition={{ duration: 1, delay: 0.8, ease: "easeOut" }}
            />
            
            <defs>
              <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#D4C5F0', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#B8A4C9', stopOpacity: 1 }} />
              </linearGradient>
            </defs>
          </svg>
          
          {/* Percentage Text */}
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-center">
            <motion.div
              className="text-2xl"
              style={{ color: '#8B7B9E' }}
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', duration: 0.6, delay: 1 }}
            >
              {percentage}%
            </motion.div>
          </div>
        </div>

        {/* Stats */}
        <div className="flex-1 space-y-3">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 rounded-full" style={{ background: '#D4C5F0' }}></div>
            <div className="flex-1">
              <div className="text-xs mb-1" style={{ color: '#B8A4C9' }}>완료한 루틴</div>
              <div className="text-sm" style={{ color: '#8B7B9E' }}>{completed}개</div>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 rounded-full" style={{ background: 'rgba(184, 164, 201, 0.3)' }}></div>
            <div className="flex-1">
              <div className="text-xs mb-1" style={{ color: '#B8A4C9' }}>남은 루틴</div>
              <div className="text-sm" style={{ color: '#8B7B9E' }}>{total - completed}개</div>
            </div>
          </div>
        </div>
      </div>

      {/* Encouragement Message */}
      <motion.div
        className="mt-4 p-3 rounded-xl text-center text-sm"
        style={{
          background: 'linear-gradient(135deg, rgba(255, 244, 235, 0.5) 0%, rgba(255, 239, 245, 0.5) 100%)',
          color: '#8B7B9E'
        }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2 }}
      >
        {percentage >= 80 ? '🎉 거의 다 왔어요!' : 
         percentage >= 50 ? '💪 잘하고 있어요!' : 
         '🌟 오늘도 화이팅!'}
      </motion.div>
    </motion.div>
  );
}
