import { useState } from 'react';
import { useNavigate } from 'react-router';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight } from 'lucide-react';

export function OnboardingScreen() {
  const navigate = useNavigate();
  const [currentPage, setCurrentPage] = useState(0);
  const totalPages = 3;

  const handleNext = () => {
    if (currentPage < totalPages - 1) {
      setCurrentPage(currentPage + 1);
    } else {
      navigate('/notification-permission');
    }
  };

  const handleSkip = () => {
    navigate('/notification-permission');
  };

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
        
        {/* Skip Button */}
        <motion.button
          className="absolute top-8 right-6 px-4 py-2 rounded-full text-sm z-10"
          style={{ color: '#B8A4C9' }}
          onClick={handleSkip}
          whileTap={{ scale: 0.95 }}
        >
          건너뛰기
        </motion.button>

        {/* Content */}
        <div className="h-full flex flex-col items-center justify-between px-8 py-16">
          
          {/* Onboarding Pages */}
          <AnimatePresence mode="wait">
            {currentPage === 0 && (
              <OnboardingPage1 key="page1" />
            )}
            {currentPage === 1 && (
              <OnboardingPage2 key="page2" />
            )}
            {currentPage === 2 && (
              <OnboardingPage3 key="page3" />
            )}
          </AnimatePresence>

          {/* Bottom Section */}
          <div className="w-full space-y-6">
            {/* Page Indicators */}
            <div className="flex justify-center gap-2">
              {[0, 1, 2].map((index) => (
                <motion.div
                  key={index}
                  className="h-2 rounded-full transition-all duration-300"
                  style={{
                    width: currentPage === index ? '32px' : '8px',
                    background: currentPage === index 
                      ? 'linear-gradient(90deg, #FFB8C6 0%, #D4C5F0 100%)'
                      : 'rgba(184, 164, 201, 0.3)'
                  }}
                  animate={{
                    scale: currentPage === index ? 1 : 0.8
                  }}
                />
              ))}
            </div>

            {/* Next Button */}
            <motion.button
              className="w-full py-4 rounded-3xl flex items-center justify-center gap-2 shadow-lg text-white"
              style={{
                background: 'linear-gradient(135deg, #FFB8C6 0%, #D4C5F0 100%)'
              }}
              onClick={handleNext}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <span className="text-lg">
                {currentPage === totalPages - 1 ? '시작하기' : '다음'}
              </span>
              {currentPage !== totalPages - 1 && <ChevronRight className="w-5 h-5" />}
            </motion.button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Page 1: 원형 시간표 소개
function OnboardingPage1() {
  return (
    <motion.div
      className="flex-1 flex flex-col items-center justify-center text-center"
      initial={{ opacity: 0, x: 50 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -50 }}
      transition={{ duration: 0.4 }}
    >
      {/* Illustration */}
      <motion.div
        className="mb-12 relative"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <div className="relative w-72 h-72">
          {/* Circular Clock Illustration */}
          <svg className="w-full h-full" viewBox="0 0 200 200">
            <defs>
              <linearGradient id="onboard1-grad1" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#FFE4E9', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#FFB8C6', stopOpacity: 1 }} />
              </linearGradient>
              <linearGradient id="onboard1-grad2" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#E8DDFA', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#D4C5F0', stopOpacity: 1 }} />
              </linearGradient>
              <linearGradient id="onboard1-grad3" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#FFE9D4', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#FFDDC5', stopOpacity: 1 }} />
              </linearGradient>
            </defs>

            {/* Background */}
            <circle cx="100" cy="100" r="85" fill="white" 
                    style={{ filter: 'drop-shadow(0 8px 32px rgba(184, 164, 201, 0.2))' }} />

            {/* Time Segments */}
            {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
              const startAngle = i * 45 - 90;
              const endAngle = (i + 1) * 45 - 90;
              const radius = 80;
              const innerRadius = 55;
              
              const x1 = 100 + innerRadius * Math.cos(startAngle * Math.PI / 180);
              const y1 = 100 + innerRadius * Math.sin(startAngle * Math.PI / 180);
              const x2 = 100 + radius * Math.cos(startAngle * Math.PI / 180);
              const y2 = 100 + radius * Math.sin(startAngle * Math.PI / 180);
              const x3 = 100 + radius * Math.cos(endAngle * Math.PI / 180);
              const y3 = 100 + radius * Math.sin(endAngle * Math.PI / 180);
              const x4 = 100 + innerRadius * Math.cos(endAngle * Math.PI / 180);
              const y4 = 100 + innerRadius * Math.sin(endAngle * Math.PI / 180);
              
              const gradients = ['url(#onboard1-grad1)', 'url(#onboard1-grad2)', 'url(#onboard1-grad3)'];
              
              return (
                <motion.path
                  key={i}
                  d={`M ${x1} ${y1} L ${x2} ${y2} A ${radius} ${radius} 0 0 1 ${x3} ${y3} L ${x4} ${y4} A ${innerRadius} ${innerRadius} 0 0 0 ${x1} ${y1} Z`}
                  fill={gradients[i % 3]}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.3 + i * 0.1 }}
                />
              );
            })}

            {/* Center */}
            <circle cx="100" cy="100" r="45" fill="white" 
                    style={{ filter: 'drop-shadow(0 4px 16px rgba(184, 164, 201, 0.15))' }} />
            
            {/* Clock Icon */}
            <text x="100" y="110" textAnchor="middle" fontSize="40">⏰</text>
          </svg>

          {/* Floating Elements */}
          <motion.div
            className="absolute top-4 right-8 text-3xl"
            animate={{ y: [0, -10, 0], rotate: [0, 15, 0] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          >
            ✨
          </motion.div>
          
          <motion.div
            className="absolute bottom-8 left-4 text-2xl"
            animate={{ y: [0, -8, 0], rotate: [0, -15, 0] }}
            transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
          >
            🌟
          </motion.div>
        </div>
      </motion.div>

      {/* Title */}
      <motion.h2
        className="text-3xl mb-4"
        style={{ color: '#8B7B9E' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        24시간을 한눈에
      </motion.h2>

      {/* Description */}
      <motion.p
        className="text-base leading-relaxed"
        style={{ color: '#B8A4C9' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        원형 시간표로 하루 전체를<br />
        직관적으로 확인하세요
      </motion.p>
    </motion.div>
  );
}

// Page 2: 알림 기능 소개
function OnboardingPage2() {
  return (
    <motion.div
      className="flex-1 flex flex-col items-center justify-center text-center"
      initial={{ opacity: 0, x: 50 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -50 }}
      transition={{ duration: 0.4 }}
    >
      {/* Illustration */}
      <motion.div
        className="mb-12 relative"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <div className="relative w-72 h-72 flex items-center justify-center">
          {/* Phone Mockup */}
          <div className="w-48 h-64 rounded-3xl p-4 shadow-2xl relative"
               style={{
                 background: 'linear-gradient(135deg, #FFFFFF 0%, #FFF9F5 100%)',
                 border: '3px solid rgba(184, 164, 201, 0.2)'
               }}>
            
            {/* Notification Card */}
            <motion.div
              className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-56 rounded-2xl p-4 shadow-xl"
              style={{
                background: 'linear-gradient(135deg, #FFB8C6 0%, #FF8CA8 100%)'
              }}
              initial={{ y: -20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.6, type: 'spring' }}
            >
              <div className="flex items-center gap-3">
                <div className="text-3xl">🔔</div>
                <div className="flex-1 text-left">
                  <div className="text-sm text-white/90 mb-1">지금 할 일</div>
                  <div className="text-base text-white">아침 루틴 시작!</div>
                </div>
              </div>
            </motion.div>

            {/* Screen Content */}
            <div className="h-full flex flex-col items-center justify-center gap-3">
              <div className="text-5xl">⏰</div>
              <div className="text-xl" style={{ color: '#8B7B9E' }}>9:00</div>
              <div className="text-xs" style={{ color: '#B8A4C9' }}>아침 루틴</div>
            </div>

            {/* Floating Bell Icons */}
            <motion.div
              className="absolute top-1/2 right-0 transform translate-x-1/2 text-2xl"
              animate={{ 
                scale: [1, 1.2, 1],
                rotate: [0, 15, -15, 0]
              }}
              transition={{ duration: 1.5, repeat: Infinity }}
            >
              🔔
            </motion.div>
          </div>

          {/* Decorative Elements */}
          <motion.div
            className="absolute top-8 left-4 text-2xl"
            animate={{ scale: [1, 1.3, 1] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          >
            💫
          </motion.div>
          
          <motion.div
            className="absolute bottom-12 right-8 text-2xl"
            animate={{ scale: [1, 1.2, 1] }}
            transition={{ duration: 2.2, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
          >
            ✨
          </motion.div>
        </div>
      </motion.div>

      {/* Title */}
      <motion.h2
        className="text-3xl mb-4"
        style={{ color: '#8B7B9E' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        시간마다 알림
      </motion.h2>

      {/* Description */}
      <motion.p
        className="text-base leading-relaxed"
        style={{ color: '#B8A4C9' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        지금 해야 할 일을<br />
        놓치지 않고 바로 확인해요
      </motion.p>
    </motion.div>
  );
}

// Page 3: 캐릭터 소개
function OnboardingPage3() {
  return (
    <motion.div
      className="flex-1 flex flex-col items-center justify-center text-center"
      initial={{ opacity: 0, x: 50 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -50 }}
      transition={{ duration: 0.4 }}
    >
      {/* Illustration */}
      <motion.div
        className="mb-12 relative"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <div className="relative w-72 h-72 flex items-center justify-center">
          {/* Character */}
          <motion.div
            className="relative"
            animate={{ 
              y: [0, -15, 0],
            }}
            transition={{ 
              duration: 2.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          >
            <div className="w-44 h-44 rounded-full flex items-center justify-center text-9xl relative"
                 style={{ 
                   background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
                   boxShadow: '0 12px 40px rgba(255, 184, 198, 0.4)'
                 }}>
              🐻
            </div>

            {/* Speech Bubbles */}
            <motion.div
              className="absolute -top-8 -right-4 bg-white rounded-2xl px-4 py-3 shadow-xl"
              style={{ border: '2px solid rgba(255, 184, 198, 0.3)' }}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.8, type: 'spring' }}
            >
              <div className="text-sm" style={{ color: '#FFB8C6' }}>화이팅! 💪</div>
              <div 
                className="absolute bottom-0 left-6 transform translate-y-1/2 rotate-45 w-3 h-3 bg-white"
                style={{ 
                  borderRight: '2px solid rgba(255, 184, 198, 0.3)',
                  borderBottom: '2px solid rgba(255, 184, 198, 0.3)'
                }}
              />
            </motion.div>

            <motion.div
              className="absolute -bottom-6 -left-8 bg-white rounded-2xl px-4 py-3 shadow-xl"
              style={{ border: '2px solid rgba(212, 197, 240, 0.3)' }}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 1.2, type: 'spring' }}
            >
              <div className="text-sm" style={{ color: '#D4C5F0' }}>잘하고 있어요! ✨</div>
              <div 
                className="absolute top-0 right-4 transform -translate-y-1/2 rotate-45 w-3 h-3 bg-white"
                style={{ 
                  borderLeft: '2px solid rgba(212, 197, 240, 0.3)',
                  borderTop: '2px solid rgba(212, 197, 240, 0.3)'
                }}
              />
            </motion.div>
          </motion.div>

          {/* Hearts */}
          <motion.div
            className="absolute top-8 left-12 text-3xl"
            animate={{ 
              y: [0, -20, 0],
              opacity: [0.7, 1, 0.7]
            }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            💕
          </motion.div>
          
          <motion.div
            className="absolute top-12 right-8 text-2xl"
            animate={{ 
              y: [0, -15, 0],
              opacity: [0.6, 1, 0.6]
            }}
            transition={{ duration: 2.3, repeat: Infinity, delay: 0.5 }}
          >
            💖
          </motion.div>

          <motion.div
            className="absolute bottom-16 left-8 text-2xl"
            animate={{ 
              scale: [1, 1.3, 1],
              rotate: [0, 15, 0]
            }}
            transition={{ duration: 2.5, repeat: Infinity, delay: 1 }}
          >
            ⭐
          </motion.div>
        </div>
      </motion.div>

      {/* Title */}
      <motion.h2
        className="text-3xl mb-4"
        style={{ color: '#8B7B9E' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        귀여운 친구와 함께
      </motion.h2>

      {/* Description */}
      <motion.p
        className="text-base leading-relaxed"
        style={{ color: '#B8A4C9' }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        응원하고 격려해주는<br />
        캐릭터와 함께 루틴을 완성해요
      </motion.p>
    </motion.div>
  );
}