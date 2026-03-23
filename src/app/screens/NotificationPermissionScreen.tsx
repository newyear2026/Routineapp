import { useNavigate } from 'react-router';
import { motion } from 'motion/react';
import { Bell } from 'lucide-react';

export function NotificationPermissionScreen() {
  const navigate = useNavigate();

  const handleAllow = () => {
    // In a real app, this would request notification permission
    // if ('Notification' in window) {
    //   Notification.requestPermission().then(permission => {
    //     navigate('/routine-setup');
    //   });
    // }
    navigate('/routine-setup');
  };

  const handleLater = () => {
    navigate('/routine-setup');
  };

  const notificationExamples = [
    {
      time: '7:00',
      title: '운동 시작 시간이에요',
      emoji: '💪',
      color: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
      delay: 0.3
    },
    {
      time: '9:00',
      title: '지금은 공부 루틴 시간이에요',
      emoji: '📚',
      color: 'linear-gradient(135deg, #E8DDFA 0%, #D4C5F0 100%)',
      delay: 0.5
    },
    {
      time: '12:00',
      title: '점심 식사 시간이에요',
      emoji: '🍱',
      color: 'linear-gradient(135deg, #FFE9D4 0%, #FFDDC5 100%)',
      delay: 0.7
    }
  ];

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
        
        {/* Decorative Elements */}
        <motion.div
          className="absolute top-[10%] right-[12%] text-2xl"
          animate={{ 
            rotate: [0, 15, 0],
            scale: [1, 1.2, 1],
          }}
          transition={{ 
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        >
          ✨
        </motion.div>

        <motion.div
          className="absolute top-[15%] left-[10%] text-2xl"
          animate={{ 
            rotate: [0, -15, 0],
            scale: [1, 1.15, 1],
          }}
          transition={{ 
            duration: 2.3,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 0.5
          }}
        >
          🔔
        </motion.div>

        {/* Content */}
        <div className="h-full flex flex-col px-8 py-16">
          
          {/* Header */}
          <motion.div
            className="text-center mb-8"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-3xl mb-3" style={{ color: '#8B7B9E' }}>
              알림을 켜볼까요?
            </h2>
            <p className="text-base leading-relaxed" style={{ color: '#B8A4C9' }}>
              지금 해야 할 루틴을<br />
              제때 알려드릴게요
            </p>
          </motion.div>

          {/* Main Illustration */}
          <div className="flex-1 flex items-center justify-center relative">
            
            {/* Character with Bell */}
            <motion.div
              className="relative z-10"
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              <motion.div
                animate={{ 
                  y: [0, -12, 0],
                }}
                transition={{ 
                  duration: 2.5,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                <div className="w-36 h-36 rounded-full flex items-center justify-center text-8xl relative"
                     style={{ 
                       background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
                       boxShadow: '0 12px 40px rgba(255, 184, 198, 0.3)'
                     }}>
                  🐻
                </div>

                {/* Bell Icon Above Character */}
                <motion.div
                  className="absolute -top-4 left-1/2 transform -translate-x-1/2"
                  animate={{ 
                    rotate: [0, -15, 15, -15, 15, 0],
                    scale: [1, 1.1, 1]
                  }}
                  transition={{ 
                    duration: 1.5,
                    repeat: Infinity,
                    repeatDelay: 1
                  }}
                >
                  <div className="w-14 h-14 rounded-full flex items-center justify-center"
                       style={{
                         background: 'linear-gradient(135deg, #FFB8C6 0%, #FF8CA8 100%)',
                         boxShadow: '0 4px 16px rgba(255, 140, 168, 0.4)'
                       }}>
                    <Bell className="w-7 h-7 text-white" />
                  </div>
                </motion.div>
              </motion.div>
            </motion.div>

            {/* Notification Cards */}
            {notificationExamples.map((notification, index) => {
              const positions = [
                { top: '5%', left: '5%', rotate: -8 },
                { top: '25%', right: '0%', rotate: 5 },
                { top: '50%', left: '0%', rotate: -5 }
              ];

              return (
                <motion.div
                  key={index}
                  className="absolute w-[200px]"
                  style={{
                    ...positions[index],
                  }}
                  initial={{ opacity: 0, scale: 0.8, y: 20 }}
                  animate={{ 
                    opacity: 1, 
                    scale: 1, 
                    y: 0,
                  }}
                  transition={{ 
                    duration: 0.5, 
                    delay: notification.delay,
                    type: 'spring'
                  }}
                >
                  <motion.div
                    className="rounded-2xl p-4 shadow-lg"
                    style={{
                      background: notification.color,
                      transform: `rotate(${positions[index].rotate}deg)`
                    }}
                    animate={{ 
                      y: [0, -8, 0],
                    }}
                    transition={{ 
                      duration: 2 + index * 0.3,
                      repeat: Infinity,
                      ease: "easeInOut",
                      delay: index * 0.2
                    }}
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <div className="text-2xl">{notification.emoji}</div>
                      <div className="text-xs px-2 py-1 rounded-full bg-white/50" 
                           style={{ color: '#8B7B9E' }}>
                        {notification.time}
                      </div>
                    </div>
                    <div className="text-sm" style={{ color: '#8B7B9E' }}>
                      {notification.title}
                    </div>
                  </motion.div>
                </motion.div>
              );
            })}

            {/* Sparkle Effects */}
            <motion.div
              className="absolute top-[10%] right-[15%] text-xl"
              animate={{ 
                scale: [1, 1.4, 1],
                opacity: [0.4, 1, 0.4]
              }}
              transition={{ 
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut"
              }}
            >
              ✨
            </motion.div>

            <motion.div
              className="absolute bottom-[15%] right-[10%] text-xl"
              animate={{ 
                scale: [1, 1.3, 1],
                opacity: [0.5, 1, 0.5]
              }}
              transition={{ 
                duration: 2.2,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 0.5
              }}
            >
              💫
            </motion.div>
          </div>

          {/* Benefits */}
          <motion.div
            className="mb-6 space-y-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.9 }}
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                   style={{ background: 'rgba(255, 184, 198, 0.2)' }}>
                <span className="text-lg">⏰</span>
              </div>
              <p className="text-sm" style={{ color: '#B8A4C9' }}>
                루틴 시간을 놓치지 않아요
              </p>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                   style={{ background: 'rgba(212, 197, 240, 0.2)' }}>
                <span className="text-lg">✨</span>
              </div>
              <p className="text-sm" style={{ color: '#B8A4C9' }}>
                귀여운 캐릭터가 응원해줘요
              </p>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                   style={{ background: 'rgba(255, 233, 212, 0.2)' }}>
                <span className="text-lg">💪</span>
              </div>
              <p className="text-sm" style={{ color: '#B8A4C9' }}>
                꾸준한 루틴 습관을 만들어요
              </p>
            </div>
          </motion.div>

          {/* Buttons */}
          <motion.div
            className="space-y-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 1.1 }}
          >
            {/* Allow Button */}
            <motion.button
              className="w-full py-4 rounded-3xl flex items-center justify-center gap-2 shadow-lg text-white"
              style={{
                background: 'linear-gradient(135deg, #FFB8C6 0%, #D4C5F0 100%)'
              }}
              onClick={handleAllow}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Bell className="w-5 h-5" />
              <span className="text-lg">알림 허용하기</span>
            </motion.button>

            {/* Later Button */}
            <motion.button
              className="w-full py-4 rounded-3xl text-center"
              style={{ color: '#B8A4C9' }}
              onClick={handleLater}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <span className="text-base">나중에 할게요</span>
            </motion.button>
          </motion.div>
        </div>
      </div>
    </div>
  );
}