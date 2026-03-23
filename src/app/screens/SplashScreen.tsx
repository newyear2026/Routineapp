import { useEffect } from 'react';
import { useNavigate } from 'react-router';
import { motion } from 'motion/react';

export function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate('/onboarding');
    }, 3000);

    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center p-4" 
         style={{ 
           background: 'linear-gradient(135deg, #FFF5F5 0%, #FFF9E6 50%, #F0F4FF 100%)'
         }}>
      {/* Mobile Container */}
      <div className="w-full max-w-[390px] h-[844px] rounded-[40px] shadow-2xl overflow-hidden relative"
           style={{
             background: 'linear-gradient(180deg, #FFF8F3 0%, #FFF5F8 50%, #F0F4FF 100%)'
           }}>
        
        {/* Decorative Elements */}
        <motion.div
          className="absolute top-[15%] left-[10%] text-3xl"
          animate={{ 
            rotate: [0, 15, 0],
            scale: [1, 1.2, 1],
            opacity: [0.6, 1, 0.6]
          }}
          transition={{ 
            duration: 3,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        >
          ✨
        </motion.div>

        <motion.div
          className="absolute top-[20%] right-[15%] text-2xl"
          animate={{ 
            rotate: [0, -20, 0],
            scale: [1, 1.3, 1],
            opacity: [0.5, 1, 0.5]
          }}
          transition={{ 
            duration: 2.5,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 0.5
          }}
        >
          ⭐
        </motion.div>

        <motion.div
          className="absolute bottom-[40%] left-[15%] text-2xl"
          animate={{ 
            rotate: [0, 10, 0],
            scale: [1, 1.15, 1],
            opacity: [0.4, 0.8, 0.4]
          }}
          transition={{ 
            duration: 2.8,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 1
          }}
        >
          🌸
        </motion.div>

        <motion.div
          className="absolute bottom-[35%] right-[12%] text-2xl"
          animate={{ 
            rotate: [0, -15, 0],
            scale: [1, 1.2, 1],
            opacity: [0.5, 0.9, 0.5]
          }}
          transition={{ 
            duration: 2.6,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 0.7
          }}
        >
          💫
        </motion.div>

        {/* Main Content */}
        <div className="flex flex-col items-center justify-center h-full px-8">
          
          {/* Logo - Circular Clock Icon */}
          <motion.div
            className="relative mb-8"
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ 
              type: 'spring',
              duration: 1.2,
              delay: 0.2
            }}
          >
            {/* Outer Ring */}
            <div className="relative w-48 h-48">
              <svg className="w-full h-full" viewBox="0 0 200 200">
                <defs>
                  <linearGradient id="logoGradient1" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style={{ stopColor: '#FFE4E9', stopOpacity: 1 }} />
                    <stop offset="50%" style={{ stopColor: '#FFB8C6', stopOpacity: 1 }} />
                    <stop offset="100%" style={{ stopColor: '#E8DDFA', stopOpacity: 1 }} />
                  </linearGradient>
                  <linearGradient id="logoGradient2" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style={{ stopColor: '#D4C5F0', stopOpacity: 1 }} />
                    <stop offset="100%" style={{ stopColor: '#B8A4C9', stopOpacity: 1 }} />
                  </linearGradient>
                </defs>
                
                {/* Background Circle */}
                <circle
                  cx="100"
                  cy="100"
                  r="90"
                  fill="white"
                  style={{ filter: 'drop-shadow(0 8px 32px rgba(184, 164, 201, 0.3))' }}
                />
                
                {/* Colored Segments */}
                {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
                  const startAngle = i * 45 - 90;
                  const endAngle = (i + 1) * 45 - 90;
                  const radius = 85;
                  const innerRadius = 65;
                  
                  const x1 = 100 + innerRadius * Math.cos(startAngle * Math.PI / 180);
                  const y1 = 100 + innerRadius * Math.sin(startAngle * Math.PI / 180);
                  const x2 = 100 + radius * Math.cos(startAngle * Math.PI / 180);
                  const y2 = 100 + radius * Math.sin(startAngle * Math.PI / 180);
                  const x3 = 100 + radius * Math.cos(endAngle * Math.PI / 180);
                  const y3 = 100 + radius * Math.sin(endAngle * Math.PI / 180);
                  const x4 = 100 + innerRadius * Math.cos(endAngle * Math.PI / 180);
                  const y4 = 100 + innerRadius * Math.sin(endAngle * Math.PI / 180);
                  
                  return (
                    <motion.path
                      key={i}
                      d={`M ${x1} ${y1} L ${x2} ${y2} A ${radius} ${radius} 0 0 1 ${x3} ${y3} L ${x4} ${y4} A ${innerRadius} ${innerRadius} 0 0 0 ${x1} ${y1} Z`}
                      fill={i % 2 === 0 ? 'url(#logoGradient1)' : 'url(#logoGradient2)'}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: [0, 1, 0.8] }}
                      transition={{ 
                        duration: 0.5,
                        delay: 0.5 + i * 0.1
                      }}
                    />
                  );
                })}
                
                {/* Center Circle */}
                <circle
                  cx="100"
                  cy="100"
                  r="55"
                  fill="white"
                  style={{ filter: 'drop-shadow(0 4px 16px rgba(184, 164, 201, 0.2))' }}
                />
              </svg>

              {/* Clock Hands */}
              <motion.div
                className="absolute top-1/2 left-1/2 origin-left"
                style={{
                  width: '40px',
                  height: '3px',
                  background: 'linear-gradient(90deg, #FFB8C6 0%, #FF8CA8 100%)',
                  borderRadius: '999px',
                  transform: 'translate(-8px, -1.5px) rotate(45deg)',
                }}
                animate={{ rotate: 405 }}
                transition={{ 
                  duration: 2,
                  ease: "easeInOut",
                  delay: 0.8
                }}
              />

              <motion.div
                className="absolute top-1/2 left-1/2 origin-left"
                style={{
                  width: '30px',
                  height: '3px',
                  background: 'linear-gradient(90deg, #D4C5F0 0%, #B8A4C9 100%)',
                  borderRadius: '999px',
                  transform: 'translate(-8px, -1.5px) rotate(90deg)',
                }}
                animate={{ rotate: 450 }}
                transition={{ 
                  duration: 1.5,
                  ease: "easeInOut",
                  delay: 1
                }}
              />

              {/* Center Dot */}
              <div
                className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 rounded-full"
                style={{
                  background: 'linear-gradient(135deg, #FFB8C6 0%, #D4C5F0 100%)',
                  boxShadow: '0 2px 8px rgba(255, 140, 168, 0.4)'
                }}
              />
            </div>
          </motion.div>

          {/* App Name */}
          <motion.div
            className="text-center mb-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 1 }}
          >
            <h1 className="text-4xl mb-2" style={{ color: '#8B7B9E', letterSpacing: '-0.5px' }}>
              하루
            </h1>
            <p className="text-sm" style={{ color: '#B8A4C9', letterSpacing: '0.5px' }}>
              Routine Timer
            </p>
          </motion.div>

          {/* Tagline */}
          <motion.div
            className="text-center mb-12"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 1.3 }}
          >
            <p className="text-sm" style={{ color: '#C4B5E6' }}>
              원형 시간표로 만드는 나만의 루틴
            </p>
          </motion.div>

          {/* Character at Bottom */}
          <motion.div
            className="absolute bottom-[15%] left-1/2 transform -translate-x-1/2"
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ 
              type: 'spring',
              duration: 1,
              delay: 1.5
            }}
          >
            <motion.div
              animate={{ 
                y: [0, -10, 0],
              }}
              transition={{ 
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 2
              }}
            >
              <div className="relative">
                {/* Character */}
                <div className="text-7xl mb-2">
                  🐻
                </div>
                
                {/* Character Speech Bubble */}
                <motion.div
                  className="absolute -top-4 -right-8 bg-white rounded-2xl px-3 py-2 shadow-lg"
                  style={{ 
                    border: '2px solid rgba(255, 184, 198, 0.3)'
                  }}
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ 
                    type: 'spring',
                    duration: 0.6,
                    delay: 2.2
                  }}
                >
                  <div className="text-sm" style={{ color: '#FFB8C6' }}>
                    반가워요! 🌟
                  </div>
                  {/* Speech bubble tail */}
                  <div 
                    className="absolute bottom-0 left-4 transform translate-y-1/2 rotate-45 w-3 h-3 bg-white"
                    style={{ 
                      borderRight: '2px solid rgba(255, 184, 198, 0.3)',
                      borderBottom: '2px solid rgba(255, 184, 198, 0.3)'
                    }}
                  />
                </motion.div>
              </div>
            </motion.div>
          </motion.div>

          {/* Loading Indicator */}
          <motion.div
            className="absolute bottom-[8%] left-1/2 transform -translate-x-1/2"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 2 }}
          >
            <div className="flex gap-2">
              {[0, 1, 2].map((i) => (
                <motion.div
                  key={i}
                  className="w-2 h-2 rounded-full"
                  style={{ background: '#D4C5F0' }}
                  animate={{ 
                    scale: [1, 1.3, 1],
                    opacity: [0.4, 1, 0.4]
                  }}
                  transition={{ 
                    duration: 1,
                    repeat: Infinity,
                    delay: i * 0.2
                  }}
                />
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}