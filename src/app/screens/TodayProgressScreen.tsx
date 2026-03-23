import { motion } from 'motion/react';
import { ArrowLeft, CheckCircle2, Clock, SkipForward, Circle, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router';

interface RoutineItem {
  id: string;
  name: string;
  emoji: string;
  time: string;
  status: 'completed' | 'later' | 'skipped' | 'pending';
}

export function TodayProgressScreen() {
  const navigate = useNavigate();

  const routines: RoutineItem[] = [
    { id: '1', name: '기상', emoji: '🌅', time: '07:00', status: 'completed' },
    { id: '2', name: '운동', emoji: '💪', time: '07:30', status: 'completed' },
    { id: '3', name: '아침식사', emoji: '🍳', time: '09:00', status: 'completed' },
    { id: '4', name: '공부', emoji: '📚', time: '14:00', status: 'later' },
    { id: '5', name: '점심식사', emoji: '🍱', time: '12:00', status: 'completed' },
    { id: '6', name: '휴식', emoji: '☕', time: '15:00', status: 'pending' },
    { id: '7', name: '저녁식사', emoji: '🍽️', time: '18:00', status: 'pending' },
    { id: '8', name: '취침', emoji: '🌙', time: '23:00', status: 'skipped' },
  ];

  const completedCount = routines.filter(r => r.status === 'completed').length;
  const laterCount = routines.filter(r => r.status === 'later').length;
  const skippedCount = routines.filter(r => r.status === 'skipped').length;
  const pendingCount = routines.filter(r => r.status === 'pending').length;
  const totalCount = routines.length;
  const progressPercent = Math.round((completedCount / totalCount) * 100);

  const getEncouragementMessage = () => {
    if (progressPercent >= 80) return {
      message: '정말 대단해요!\n오늘도 멋지게 해냈어요!',
      emoji: '🎉',
      subtext: '거의 모든 루틴을 완료했어요'
    };
    if (progressPercent >= 50) return {
      message: '잘하고 있어요!\n벌써 절반이나 했어요!',
      emoji: '💪',
      subtext: '이 기세로 계속 가봐요'
    };
    if (progressPercent >= 30) return {
      message: '좋은 시작이에요!\n차근차근 해나가요',
      emoji: '🌟',
      subtext: '조금씩 꾸준히가 중요해요'
    };
    return {
      message: '괜찮아요!\n천천히 시작해봐요',
      emoji: '🌱',
      subtext: '작은 시작이 큰 변화를 만들어요'
    };
  };

  const encouragement = getEncouragementMessage();

  const statusConfig = {
    completed: {
      label: '완료',
      icon: <CheckCircle2 className="w-5 h-5" />,
      color: '#D4E4FF',
      textColor: '#6B8BC9',
      borderColor: 'rgba(107, 139, 201, 0.3)'
    },
    later: {
      label: '나중에',
      icon: <Clock className="w-5 h-5" />,
      color: '#FFE9D4',
      textColor: '#D9A57B',
      borderColor: 'rgba(217, 165, 123, 0.3)'
    },
    skipped: {
      label: '스킵',
      icon: <SkipForward className="w-5 h-5" />,
      color: '#FFE4E9',
      textColor: '#D99BB0',
      borderColor: 'rgba(217, 155, 176, 0.3)'
    },
    pending: {
      label: '대기',
      icon: <Circle className="w-5 h-5" />,
      color: '#F5F0FF',
      textColor: '#B8A4C9',
      borderColor: 'rgba(184, 164, 201, 0.3)'
    }
  };

  const today = new Date();
  const dateString = `${today.getMonth() + 1}월 ${today.getDate()}일`;
  const dayOfWeek = ['일', '월', '화', '수', '목', '금', '토'][today.getDay()];

  return (
    <div className="min-h-screen flex items-center justify-center p-4" 
         style={{ 
           background: 'linear-gradient(135deg, #FFF5F5 0%, #FFF9E6 50%, #F0F4FF 100%)'
         }}>
      {/* Mobile Container */}
      <div className="w-full max-w-[390px] h-[844px] rounded-[40px] shadow-2xl overflow-hidden relative"
           style={{
             background: 'linear-gradient(180deg, #FFF8F3 0%, #FFF5F8 100%)'
           }}>
        
        {/* Decorative Background Elements */}
        <DecorativeElements />

        {/* Header */}
        <div className="px-6 pt-12 pb-6 relative z-10">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              className="w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-sm"
              style={{ background: 'rgba(184, 164, 201, 0.2)' }}
              onClick={() => navigate('/home')}
              whileTap={{ scale: 0.9 }}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
            >
              <ArrowLeft className="w-5 h-5" style={{ color: '#8B7B9E' }} />
            </motion.button>

            <motion.div
              className="text-center"
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
            >
              <h1 className="text-xl mb-0.5" style={{ color: '#8B7B9E' }}>오늘의 루틴</h1>
              <p className="text-xs" style={{ color: '#B8A4C9' }}>
                {dateString} {dayOfWeek}요일
              </p>
            </motion.div>

            <div className="w-10" /> {/* Spacer */}
          </div>
        </div>

        {/* Content */}
        <div className="px-6 pb-6 overflow-y-auto relative z-10" style={{ height: 'calc(100% - 140px)' }}>
          
          {/* Big Progress Card */}
          <motion.div
            className="rounded-3xl p-6 mb-6 relative overflow-hidden"
            style={{
              background: 'linear-gradient(135deg, #FFFFFF 0%, #FFF9F5 100%)',
              boxShadow: '0 12px 40px rgba(184, 164, 201, 0.2)',
              border: '2px solid rgba(232, 221, 250, 0.3)'
            }}
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            {/* Decorative gradient overlay */}
            <div 
              className="absolute inset-0 opacity-10"
              style={{
                background: 'radial-gradient(circle at top right, #FFB8C6 0%, transparent 50%)'
              }}
            />

            <div className="relative z-10">
              {/* Main Progress Circle */}
              <div className="flex items-center justify-center mb-6">
                <div className="relative w-40 h-40">
                  <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                    {/* Background Circle */}
                    <circle
                      cx="50"
                      cy="50"
                      r="42"
                      fill="none"
                      stroke="rgba(184, 164, 201, 0.15)"
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
                        strokeDashoffset: 2 * Math.PI * 42 * (1 - progressPercent / 100)
                      }}
                      transition={{ duration: 1.5, delay: 0.5, ease: "easeOut" }}
                    />
                    
                    <defs>
                      <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" style={{ stopColor: '#FFB8C6', stopOpacity: 1 }} />
                        <stop offset="100%" style={{ stopColor: '#D4C5F0', stopOpacity: 1 }} />
                      </linearGradient>
                    </defs>
                  </svg>
                  
                  {/* Percentage Text */}
                  <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-center">
                    <motion.div
                      className="text-5xl mb-1"
                      style={{ color: '#8B7B9E', fontWeight: 600 }}
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: 'spring', duration: 0.8, delay: 0.7 }}
                    >
                      {progressPercent}%
                    </motion.div>
                    <div className="text-xs" style={{ color: '#B8A4C9' }}>완료</div>
                  </div>
                </div>
              </div>

              {/* Stats Grid */}
              <div className="grid grid-cols-3 gap-3">
                <motion.div
                  className="text-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.8 }}
                >
                  <div className="text-2xl mb-1" style={{ color: '#6B8BC9', fontWeight: 600 }}>
                    {completedCount}
                  </div>
                  <div className="text-xs" style={{ color: '#B8A4C9' }}>완료</div>
                </motion.div>

                <motion.div
                  className="text-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.9 }}
                >
                  <div className="text-2xl mb-1" style={{ color: '#D9A57B', fontWeight: 600 }}>
                    {laterCount + pendingCount}
                  </div>
                  <div className="text-xs" style={{ color: '#B8A4C9' }}>남은 루틴</div>
                </motion.div>

                <motion.div
                  className="text-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 1.0 }}
                >
                  <div className="text-2xl mb-1" style={{ color: '#8B7B9E', fontWeight: 600 }}>
                    {totalCount}
                  </div>
                  <div className="text-xs" style={{ color: '#B8A4C9' }}>전체</div>
                </motion.div>
              </div>
            </div>
          </motion.div>

          {/* Status Breakdown */}
          <motion.div
            className="mb-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.1 }}
          >
            <h3 className="text-sm mb-3 px-1" style={{ color: '#8B7B9E', fontWeight: 500 }}>
              상태별 루틴
            </h3>
            
            <div className="space-y-2">
              {Object.entries(statusConfig).map(([status, config], index) => {
                const routinesForStatus = routines.filter(r => r.status === status);
                if (routinesForStatus.length === 0) return null;

                return (
                  <motion.div
                    key={status}
                    className="rounded-2xl p-4"
                    style={{
                      background: config.color,
                      border: `1px solid ${config.borderColor}`
                    }}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 1.2 + index * 0.1 }}
                  >
                    <div className="flex items-center gap-3 mb-3">
                      <div className="flex items-center gap-2">
                        <div style={{ color: config.textColor }}>
                          {config.icon}
                        </div>
                        <span className="text-sm" style={{ color: config.textColor, fontWeight: 500 }}>
                          {config.label}
                        </span>
                      </div>
                      <span className="text-xs px-2 py-1 rounded-full" 
                            style={{ 
                              background: 'rgba(255, 255, 255, 0.5)',
                              color: config.textColor
                            }}>
                        {routinesForStatus.length}개
                      </span>
                    </div>

                    <div className="flex flex-wrap gap-2">
                      {routinesForStatus.map((routine) => (
                        <motion.div
                          key={routine.id}
                          className="flex items-center gap-2 px-3 py-2 rounded-xl"
                          style={{
                            background: 'rgba(255, 255, 255, 0.6)',
                            border: '1px solid rgba(255, 255, 255, 0.8)'
                          }}
                          whileHover={{ scale: 1.05 }}
                        >
                          <span className="text-base">{routine.emoji}</span>
                          <span className="text-xs" style={{ color: '#8B7B9E' }}>
                            {routine.name}
                          </span>
                          <span className="text-xs" style={{ color: '#B8A4C9' }}>
                            {routine.time}
                          </span>
                        </motion.div>
                      ))}
                    </div>
                  </motion.div>
                );
              })}
            </div>
          </motion.div>

          {/* Character Encouragement */}
          <motion.div
            className="rounded-3xl p-6 mb-6"
            style={{
              background: 'linear-gradient(135deg, rgba(255, 244, 235, 0.6) 0%, rgba(255, 239, 245, 0.6) 100%)',
              border: '2px solid rgba(255, 184, 198, 0.3)'
            }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.5 }}
          >
            <div className="flex items-start gap-4">
              <motion.div
                animate={{ 
                  y: [0, -8, 0],
                }}
                transition={{ 
                  duration: 2.5,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl"
                     style={{ 
                       background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
                       boxShadow: '0 4px 16px rgba(255, 184, 198, 0.3)'
                     }}>
                  🐻
                </div>
              </motion.div>

              <div className="flex-1">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-2xl">{encouragement.emoji}</span>
                  <h4 className="text-sm" style={{ color: '#8B7B9E', fontWeight: 500 }}>
                    오늘 하루 피드백
                  </h4>
                </div>
                <p className="text-base mb-2 leading-relaxed whitespace-pre-line" 
                   style={{ color: '#8B7B9E' }}>
                  {encouragement.message}
                </p>
                <p className="text-xs" style={{ color: '#B8A4C9' }}>
                  {encouragement.subtext}
                </p>
              </div>
            </div>
          </motion.div>

          {/* Quick Stats */}
          <motion.div
            className="grid grid-cols-2 gap-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.6 }}
          >
            <div className="rounded-2xl p-4 text-center backdrop-blur-sm"
                 style={{
                   background: 'rgba(255, 255, 255, 0.5)',
                   border: '1px solid rgba(232, 221, 250, 0.3)'
                 }}>
              <div className="text-2xl mb-1">🔥</div>
              <div className="text-xs mb-1" style={{ color: '#B8A4C9' }}>연속 달성</div>
              <div className="text-lg" style={{ color: '#8B7B9E', fontWeight: 600 }}>3일</div>
            </div>

            <div className="rounded-2xl p-4 text-center backdrop-blur-sm"
                 style={{
                   background: 'rgba(255, 255, 255, 0.5)',
                   border: '1px solid rgba(232, 221, 250, 0.3)'
                 }}>
              <div className="text-2xl mb-1">⭐</div>
              <div className="text-xs mb-1" style={{ color: '#B8A4C9' }}>평균 달성률</div>
              <div className="text-lg" style={{ color: '#8B7B9E', fontWeight: 600 }}>67%</div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}

// Decorative Elements Component
function DecorativeElements() {
  return (
    <>
      {/* Sparkles */}
      {[...Array(8)].map((_, i) => (
        <motion.div
          key={`sparkle-${i}`}
          className="absolute"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 10 + 12}px`,
          }}
          animate={{
            opacity: [0.2, 0.8, 0.2],
            scale: [0.5, 1.3, 0.5],
            rotate: [0, 15, -15, 0],
          }}
          transition={{
            duration: 2 + Math.random() * 1.5,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: "easeInOut"
          }}
        >
          ✨
        </motion.div>
      ))}

      {/* Stars */}
      {[...Array(6)].map((_, i) => (
        <motion.div
          key={`star-${i}`}
          className="absolute"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 8 + 10}px`,
            opacity: 0.4,
          }}
          animate={{
            opacity: [0.2, 0.6, 0.2],
            scale: [0.8, 1.2, 0.8],
            rotate: [0, 180, 360],
          }}
          transition={{
            duration: 3 + Math.random() * 2,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: "easeInOut"
          }}
        >
          ⭐
        </motion.div>
      ))}

      {/* Hearts */}
      {[...Array(4)].map((_, i) => (
        <motion.div
          key={`heart-${i}`}
          className="absolute"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 8 + 10}px`,
            color: '#FFB8C6',
            opacity: 0.3,
          }}
          animate={{
            y: [0, -20, 0],
            opacity: [0.2, 0.5, 0.2],
            scale: [0.8, 1.1, 0.8],
          }}
          transition={{
            duration: 3 + Math.random() * 2,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: "easeInOut"
          }}
        >
          💕
        </motion.div>
      ))}
    </>
  );
}
