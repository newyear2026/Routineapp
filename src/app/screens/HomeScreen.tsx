import { useState } from 'react';
import { motion } from 'motion/react';
import { Settings, TrendingUp, CheckCircle2, Clock, SkipForward } from 'lucide-react';
import { RoutineDetailSheet } from '../components/RoutineDetailSheet';
import { useNavigate } from 'react-router';

export function HomeScreen() {
  const navigate = useNavigate();
  const [completedRoutines, setCompletedRoutines] = useState(3);
  const [showRoutineDetail, setShowRoutineDetail] = useState(false);
  const totalRoutines = 8;

  // Current time simulation
  const currentHour = 14;
  const currentMinute = 30;
  const currentRoutine = {
    name: '공부',
    emoji: '📚',
    startTime: '14:00',
    endTime: '16:00',
    color: '#E8DDFA',
    progress: 25,
    repeatDays: ['월', '화', '수', '목', '금'],
    memo: '집중해서 공부하는 시간이에요. 휴대폰은 멀리 두고 온전히 학습에 몰입해봐요.',
    todayStatus: 'pending' as const
  };

  const nextRoutine = {
    name: '휴식',
    emoji: '☕',
    time: '16:00'
  };

  const handleComplete = () => {
    setCompletedRoutines((prev) => Math.min(prev + 1, totalRoutines));
  };

  const handleLater = () => {
    console.log('나중에 하기');
  };

  const handleSkip = () => {
    console.log('스킵하기');
  };

  const handleEdit = () => {
    console.log('수정하기');
    setShowRoutineDetail(false);
  };

  const handleDelete = () => {
    console.log('삭제하기');
    setShowRoutineDetail(false);
  };

  // Get greeting based on time
  const getGreeting = () => {
    if (currentHour < 12) return '좋은 아침이에요';
    if (currentHour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  };

  // Get current date
  const today = new Date();
  const dateString = `${today.getMonth() + 1}월 ${today.getDate()}일`;
  const dayOfWeek = ['일', '월', '화', '수', '목', '금', '토'][today.getDay()];

  return (
    <>
    <div className="min-h-screen flex items-center justify-center p-4" 
         style={{ 
           background: 'linear-gradient(135deg, #FFF5F5 0%, #FFF9E6 50%, #F0F4FF 100%)'
         }}>
      {/* Mobile Container */}
      <div className="w-full max-w-[390px] h-[844px] rounded-[40px] shadow-2xl overflow-hidden relative"
           style={{
             background: 'linear-gradient(180deg, #FFF8F3 0%, #FFF5F8 50%, #F5F0FF 100%)'
           }}>
        
        {/* Decorative Background Elements */}
        <DecorativeBackground />

        {/* Main Content */}
        <div className="h-full flex flex-col relative z-10">
          
          {/* Header */}
          <div className="px-6 pt-12 pb-3">
            <div className="flex items-start justify-between mb-3">
              {/* Date & Greeting */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5 }}
              >
                <div className="text-sm mb-1" style={{ color: '#B8A4C9' }}>
                  {dateString} {dayOfWeek}요일
                </div>
                <h1 className="text-2xl" style={{ color: '#8B7B9E' }}>
                  {getGreeting()} 👋
                </h1>
              </motion.div>

              {/* Action Buttons */}
              <div className="flex gap-2">
                <motion.button
                  className="w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-sm"
                  style={{ background: 'rgba(255, 184, 198, 0.2)' }}
                  onClick={() => navigate('/progress')}
                  whileTap={{ scale: 0.9 }}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.2 }}
                >
                  <TrendingUp className="w-5 h-5" style={{ color: '#FFB8C6' }} />
                </motion.button>
                <motion.button
                  className="w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-sm"
                  style={{ background: 'rgba(212, 197, 240, 0.2)' }}
                  onClick={() => navigate('/settings')}
                  whileTap={{ scale: 0.9 }}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.3 }}
                >
                  <Settings className="w-5 h-5" style={{ color: '#D4C5F0' }} />
                </motion.button>
              </div>
            </div>

            {/* Progress Bar */}
            <motion.div
              className="mb-2"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs" style={{ color: '#B8A4C9' }}>
                  오늘의 진행
                </span>
                <span className="text-xs" style={{ color: '#8B7B9E' }}>
                  {completedRoutines}/{totalRoutines}
                </span>
              </div>
              <div className="h-2 rounded-full overflow-hidden backdrop-blur-sm" 
                   style={{ background: 'rgba(184, 164, 201, 0.15)' }}>
                <motion.div
                  className="h-full rounded-full"
                  style={{
                    background: 'linear-gradient(90deg, #FFB8C6 0%, #D4C5F0 100%)'
                  }}
                  initial={{ width: 0 }}
                  animate={{ width: `${(completedRoutines / totalRoutines) * 100}%` }}
                  transition={{ duration: 1, delay: 0.6 }}
                />
              </div>
            </motion.div>
          </div>

          {/* Main Content Area */}
          <div className="flex-1 flex flex-col items-center px-6 pb-6 overflow-y-auto">
            
            {/* Character with Speech Bubble */}
            <motion.div
              className="mb-4 relative"
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              <motion.div
                animate={{ 
                  y: [0, -10, 0],
                }}
                transition={{ 
                  duration: 2.5,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                <div className="w-20 h-20 rounded-full flex items-center justify-center text-5xl relative"
                     style={{ 
                       background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
                       boxShadow: '0 8px 24px rgba(255, 184, 198, 0.4)'
                     }}>
                  🐻
                </div>
              </motion.div>

              {/* Speech Bubble */}
              <motion.div
                className="absolute -bottom-4 left-1/2 transform -translate-x-1/2 whitespace-nowrap"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.8, type: 'spring' }}
              >
                <div className="bg-white rounded-2xl px-4 py-2 shadow-lg"
                     style={{ border: '2px solid rgba(255, 184, 198, 0.3)' }}>
                  <div className="text-xs" style={{ color: '#8B7B9E' }}>
                    지금은 <span style={{ color: '#FFB8C6', fontWeight: 500 }}>{currentRoutine.emoji} {currentRoutine.name}</span> 시간!
                  </div>
                  <div 
                    className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2 rotate-45 w-3 h-3 bg-white"
                    style={{ 
                      borderLeft: '2px solid rgba(255, 184, 198, 0.3)',
                      borderTop: '2px solid rgba(255, 184, 198, 0.3)'
                    }}
                  />
                </div>
              </motion.div>
            </motion.div>

            {/* Enhanced Circular Clock - Bigger and More Decorative */}
            <motion.div
              className="my-8 relative"
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.3 }}
            >
              <EnhancedCircularClock 
                currentHour={currentHour}
                currentMinute={currentMinute}
                currentRoutine={currentRoutine}
              />
            </motion.div>

            {/* Big Complete Button */}
            <motion.button
              className="w-full py-5 rounded-3xl flex items-center justify-center gap-3 shadow-xl mb-3 relative overflow-hidden"
              style={{
                background: 'linear-gradient(135deg, #D4E4FF 0%, #C5D5F0 100%)',
              }}
              onClick={handleComplete}
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.7 }}
            >
              {/* Animated background shimmer */}
              <motion.div
                className="absolute inset-0 opacity-30"
                style={{
                  background: 'linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.5), transparent)'
                }}
                animate={{
                  x: ['-100%', '200%']
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  ease: "linear"
                }}
              />
              
              <CheckCircle2 className="w-6 h-6 relative z-10" style={{ color: '#6B8BC9' }} />
              <span className="text-lg relative z-10" style={{ color: '#6B8BC9', fontWeight: 500 }}>
                {currentRoutine.name} 완료하기
              </span>
            </motion.button>

            {/* Secondary Action Buttons */}
            <motion.div
              className="w-full flex gap-2 mb-4"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.8 }}
            >
              <motion.button
                className="flex-1 py-3 rounded-2xl flex items-center justify-center gap-2 shadow-md"
                style={{
                  background: 'linear-gradient(135deg, #FFE9D4 0%, #FFDDC5 100%)'
                }}
                onClick={handleLater}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Clock className="w-5 h-5" style={{ color: '#D9A57B' }} />
                <span className="text-sm" style={{ color: '#D9A57B', fontWeight: 500 }}>나중에</span>
              </motion.button>

              <motion.button
                className="py-3 px-5 rounded-2xl flex items-center justify-center shadow-md"
                style={{
                  background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)'
                }}
                onClick={handleSkip}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <SkipForward className="w-5 h-5" style={{ color: '#D99BB0' }} />
              </motion.button>
            </motion.div>

            {/* Next Routine Card */}
            <motion.div
              className="w-full rounded-2xl p-4 backdrop-blur-sm"
              style={{
                background: 'rgba(255, 255, 255, 0.5)',
                border: '1px solid rgba(232, 221, 250, 0.4)'
              }}
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.9 }}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-xs" style={{ color: '#B8A4C9' }}>다음 루틴</span>
                  <span className="text-xl">{nextRoutine.emoji}</span>
                  <span className="text-sm" style={{ color: '#8B7B9E', fontWeight: 500 }}>
                    {nextRoutine.name}
                  </span>
                </div>
                <span className="text-xs px-3 py-1 rounded-full"
                      style={{ 
                        background: 'rgba(232, 221, 250, 0.4)',
                        color: '#B8A4C9'
                      }}>
                  {nextRoutine.time}
                </span>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>

    {/* Routine Detail Sheet */}
    <RoutineDetailSheet
      isOpen={showRoutineDetail}
      onClose={() => setShowRoutineDetail(false)}
      routine={currentRoutine}
      onEdit={handleEdit}
      onDelete={handleDelete}
    />
    </>
  );
}

// Decorative Background Component
function DecorativeBackground() {
  return (
    <>
      {/* Stars */}
      {[...Array(12)].map((_, i) => (
        <motion.div
          key={`star-${i}`}
          className="absolute text-yellow-300/60"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 12 + 8}px`,
          }}
          animate={{
            opacity: [0.3, 1, 0.3],
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

      {/* Clouds */}
      {[...Array(4)].map((_, i) => (
        <motion.div
          key={`cloud-${i}`}
          className="absolute text-4xl opacity-20"
          style={{
            top: `${15 + i * 20}%`,
            left: '-10%',
          }}
          animate={{
            x: ['0vw', '110vw'],
            y: [0, -10, 0],
          }}
          transition={{
            x: {
              duration: 30 + i * 10,
              repeat: Infinity,
              ease: "linear"
            },
            y: {
              duration: 4 + i,
              repeat: Infinity,
              ease: "easeInOut"
            }
          }}
        >
          ☁️
        </motion.div>
      ))}

      {/* Hearts */}
      {[...Array(6)].map((_, i) => (
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
            y: [0, -30, 0],
            opacity: [0.2, 0.6, 0.2],
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

      {/* Bubbles */}
      {[...Array(5)].map((_, i) => (
        <motion.div
          key={`bubble-${i}`}
          className="absolute rounded-full"
          style={{
            width: `${Math.random() * 40 + 20}px`,
            height: `${Math.random() * 40 + 20}px`,
            background: 'radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.8), rgba(232, 221, 250, 0.3))',
            border: '1px solid rgba(255, 255, 255, 0.5)',
            bottom: '-10%',
            left: `${Math.random() * 100}%`,
          }}
          animate={{
            y: [0, -900],
            x: [0, Math.random() * 50 - 25],
            opacity: [0, 0.6, 0],
          }}
          transition={{
            duration: 8 + Math.random() * 4,
            repeat: Infinity,
            delay: Math.random() * 3,
            ease: "easeOut"
          }}
        />
      ))}
    </>
  );
}

// Enhanced Circular Clock Component
interface EnhancedCircularClockProps {
  currentHour: number;
  currentMinute: number;
  currentRoutine: {
    name: string;
    emoji: string;
    startTime: string;
    endTime: string;
    color: string;
    progress: number;
  };
}

function EnhancedCircularClock({ currentHour, currentMinute, currentRoutine }: EnhancedCircularClockProps) {
  const routines = [
    { time: 6, label: '기상', emoji: '🌅', color: '#FFE4E9', gradient: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)' },
    { time: 7, label: '운동', emoji: '💪', color: '#FFD4E0', gradient: 'linear-gradient(135deg, #FFD4E0 0%, #FFC9DA 100%)' },
    { time: 9, label: '아침', emoji: '🍳', color: '#FFE9D4', gradient: 'linear-gradient(135deg, #FFE9D4 0%, #FFDDC5 100%)' },
    { time: 10, label: '공부', emoji: '📚', color: '#E8DDFA', gradient: 'linear-gradient(135deg, #E8DDFA 0%, #D4C5F0 100%)' },
    { time: 12, label: '점심', emoji: '🍱', color: '#FFDDC5', gradient: 'linear-gradient(135deg, #FFDDC5 0%, #FFD0B8 100%)' },
    { time: 15, label: '휴식', emoji: '☕', color: '#D4E4FF', gradient: 'linear-gradient(135deg, #D4E4FF 0%, #C5D5F0 100%)' },
    { time: 18, label: '저녁', emoji: '🍽️', color: '#FFE4E9', gradient: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)' },
    { time: 23, label: '취침', emoji: '🌙', color: '#D4C5F0', gradient: 'linear-gradient(135deg, #D4C5F0 0%, #C4B5E6 100%)' },
  ];

  const hourAngle = ((currentHour % 12) * 30 + currentMinute * 0.5) - 90;

  return (
    <div className="relative w-[320px] h-[320px]">
      {/* Outer Glow Ring */}
      <motion.div
        className="absolute inset-0 rounded-full"
        style={{
          background: 'radial-gradient(circle, rgba(232, 221, 250, 0.3) 0%, transparent 70%)',
          filter: 'blur(20px)',
        }}
        animate={{
          scale: [1, 1.05, 1],
          opacity: [0.5, 0.8, 0.5],
        }}
        transition={{
          duration: 3,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      />

      {/* Main Clock Circle */}
      <svg className="w-full h-full relative z-10" viewBox="0 0 200 200">
        <defs>
          {routines.map((routine, index) => (
            <linearGradient key={index} id={`grad-${index}`} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style={{ stopColor: routine.color, stopOpacity: 1 }} />
              <stop offset="100%" style={{ stopColor: routine.color, stopOpacity: 0.7 }} />
            </linearGradient>
          ))}
          
          {/* Glow effect for current routine */}
          <filter id="glow">
            <feGaussianBlur stdDeviation="4" result="coloredBlur"/>
            <feMerge>
              <feMergeNode in="coloredBlur"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>

          {/* Shimmer effect */}
          <linearGradient id="shimmer" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style={{ stopColor: 'rgba(255, 255, 255, 0)', stopOpacity: 0 }} />
            <stop offset="50%" style={{ stopColor: 'rgba(255, 255, 255, 0.8)', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: 'rgba(255, 255, 255, 0)', stopOpacity: 0 }} />
          </linearGradient>
        </defs>

        {/* Background Circle with gradient */}
        <circle cx="100" cy="100" r="92" fill="url(#bgGradient)" 
                style={{ filter: 'drop-shadow(0 12px 32px rgba(184, 164, 201, 0.3))' }} />
        
        <defs>
          <radialGradient id="bgGradient">
            <stop offset="0%" style={{ stopColor: '#FFFFFF', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#FFF9F5', stopOpacity: 1 }} />
          </radialGradient>
        </defs>

        {/* Time Segments */}
        {routines.map((routine, index) => {
          const nextTime = routines[(index + 1) % routines.length].time;
          const startAngle = (routine.time / 24) * 360 - 90;
          const endAngle = (nextTime / 24) * 360 - 90;
          const innerRadius = 58;
          const outerRadius = 87;
          
          const startRad = startAngle * (Math.PI / 180);
          const endRad = endAngle * (Math.PI / 180);
          
          const x1 = 100 + innerRadius * Math.cos(startRad);
          const y1 = 100 + innerRadius * Math.sin(startRad);
          const x2 = 100 + outerRadius * Math.cos(startRad);
          const y2 = 100 + outerRadius * Math.sin(startRad);
          const x3 = 100 + outerRadius * Math.cos(endRad);
          const y3 = 100 + outerRadius * Math.sin(endRad);
          const x4 = 100 + innerRadius * Math.cos(endRad);
          const y4 = 100 + innerRadius * Math.sin(endRad);
          
          const largeArc = Math.abs(endAngle - startAngle) > 180 ? 1 : 0;
          
          const isCurrentRoutine = routine.label === '공부';
          
          return (
            <g key={index}>
              <motion.path
                d={`M ${x1} ${y1} L ${x2} ${y2} A ${outerRadius} ${outerRadius} 0 ${largeArc} 1 ${x3} ${y3} L ${x4} ${y4} A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${x1} ${y1} Z`}
                fill={`url(#grad-${index})`}
                stroke={isCurrentRoutine ? '#FFFFFF' : 'rgba(255, 255, 255, 0.5)'}
                strokeWidth={isCurrentRoutine ? 3 : 1}
                style={{ filter: isCurrentRoutine ? 'url(#glow)' : 'none' }}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ 
                  opacity: 1, 
                  scale: isCurrentRoutine ? 1.02 : 1
                }}
                transition={{ 
                  duration: 0.5, 
                  delay: index * 0.05,
                  scale: { duration: 0.3 }
                }}
              />
              
              {/* Shimmer effect on current routine */}
              {isCurrentRoutine && (
                <motion.path
                  d={`M ${x1} ${y1} L ${x2} ${y2} A ${outerRadius} ${outerRadius} 0 ${largeArc} 1 ${x3} ${y3} L ${x4} ${y4} A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${x1} ${y1} Z`}
                  fill="url(#shimmer)"
                  opacity={0.6}
                  animate={{
                    opacity: [0, 0.6, 0],
                  }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    ease: "easeInOut"
                  }}
                />
              )}
            </g>
          );
        })}

        {/* Center Circle */}
        <circle cx="100" cy="100" r="50" fill="url(#centerGradient)" 
                style={{ filter: 'drop-shadow(0 6px 16px rgba(184, 164, 201, 0.2))' }} />
        
        <defs>
          <radialGradient id="centerGradient">
            <stop offset="0%" style={{ stopColor: '#FFFFFF', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#FFF5F8', stopOpacity: 1 }} />
          </radialGradient>
        </defs>
      </svg>

      {/* Routine Labels with Icons */}
      {routines.map((routine, index) => {
        const angle = (routine.time / 24) * 360 - 90;
        const radius = 102;
        const angleRad = angle * (Math.PI / 180);
        const x = 50 + (radius / 2) * Math.cos(angleRad);
        const y = 50 + (radius / 2) * Math.sin(angleRad);
        
        const isCurrentRoutine = routine.label === '공부';
        
        return (
          <motion.div
            key={index}
            className="absolute text-center"
            style={{
              left: `${x}%`,
              top: `${y}%`,
              transform: 'translate(-50%, -50%)',
            }}
            initial={{ opacity: 0, scale: 0 }}
            animate={{ 
              opacity: 1, 
              scale: isCurrentRoutine ? 1.2 : 1
            }}
            transition={{ duration: 0.3, delay: 0.3 + index * 0.05 }}
          >
            <motion.div
              animate={isCurrentRoutine ? {
                y: [0, -5, 0],
              } : {}}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                ease: "easeInOut"
              }}
            >
              <div className={`${isCurrentRoutine ? 'text-2xl' : 'text-xl'} mb-0.5`}>
                {routine.emoji}
              </div>
              <div className={`${isCurrentRoutine ? 'text-xs' : 'text-[10px]'}`} 
                   style={{ 
                     color: isCurrentRoutine ? '#8B7B9E' : '#B8A4C9', 
                     fontWeight: isCurrentRoutine ? 600 : 500
                   }}>
                {routine.label}
              </div>
            </motion.div>
          </motion.div>
        );
      })}

      {/* Center Content - Current Time */}
      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-center">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', duration: 0.6, delay: 0.5 }}
        >
          <div className="text-3xl mb-1" style={{ color: '#8B7B9E', fontWeight: 600 }}>
            {String(currentHour).padStart(2, '0')}:{String(currentMinute).padStart(2, '0')}
          </div>
          <div className="text-xs" style={{ color: '#B8A4C9' }}>현재 시간</div>
        </motion.div>
      </div>

      {/* Clock Hand with gradient */}
      <motion.div
        className="absolute top-1/2 left-1/2 origin-left"
        style={{
          width: '55px',
          height: '4px',
          background: 'linear-gradient(90deg, #FFB8C6 0%, #FF8CA8 100%)',
          borderRadius: '999px',
          transform: `translate(-10px, -2px) rotate(${hourAngle}deg)`,
          boxShadow: '0 2px 12px rgba(255, 140, 168, 0.5)'
        }}
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: 'spring', duration: 0.8, delay: 0.7 }}
      />
      
      {/* Clock Hand Center Dot with pulse */}
      <motion.div
        className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-4 h-4 rounded-full"
        style={{
          background: 'linear-gradient(135deg, #FFB8C6 0%, #FF8CA8 100%)',
          boxShadow: '0 3px 12px rgba(255, 140, 168, 0.5)'
        }}
        initial={{ scale: 0 }}
        animate={{ 
          scale: [1, 1.1, 1],
        }}
        transition={{ 
          scale: {
            duration: 1.5,
            repeat: Infinity,
            ease: "easeInOut"
          },
          initial: {
            type: 'spring',
            duration: 0.6,
            delay: 0.8
          }
        }}
      />

      {/* Floating Decorations around Clock */}
      <motion.div
        className="absolute top-[8%] right-[8%] text-2xl"
        animate={{ 
          y: [0, -10, 0],
          rotate: [0, 20, 0],
          opacity: [0.6, 1, 0.6]
        }}
        transition={{ 
          duration: 2.5,
          repeat: Infinity,
          ease: "easeInOut"
        }}
      >
        ✨
      </motion.div>

      <motion.div
        className="absolute bottom-[8%] left-[8%] text-2xl"
        animate={{ 
          y: [0, -8, 0],
          rotate: [0, -15, 0],
          opacity: [0.5, 1, 0.5]
        }}
        transition={{ 
          duration: 2.8,
          repeat: Infinity,
          ease: "easeInOut",
          delay: 0.5
        }}
      >
        💫
      </motion.div>

      <motion.div
        className="absolute top-[50%] right-[2%] text-xl"
        animate={{ 
          scale: [1, 1.3, 1],
          opacity: [0.4, 0.9, 0.4]
        }}
        transition={{ 
          duration: 2,
          repeat: Infinity,
          ease: "easeInOut",
          delay: 1
        }}
      >
        🌟
      </motion.div>
    </div>
  );
}