import { motion } from 'motion/react';
import { 
  ArrowLeft, 
  Bell, 
  Watch, 
  Palette, 
  Smile, 
  ChevronRight, 
  Mail, 
  Info,
  Moon,
  Sun,
  Volume2
} from 'lucide-react';
import { useNavigate } from 'react-router';
import { useState } from 'react';

export function SettingsScreen() {
  const navigate = useNavigate();
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [watchEnabled, setWatchEnabled] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [selectedTheme, setSelectedTheme] = useState<'light' | 'dark' | 'auto'>('light');

  const settingsSections = [
    {
      title: '알림 및 소리',
      items: [
        {
          icon: <Bell className="w-5 h-5" />,
          label: '푸시 알림',
          type: 'toggle' as const,
          value: notificationsEnabled,
          onChange: setNotificationsEnabled,
          color: '#FFB8C6'
        },
        {
          icon: <Volume2 className="w-5 h-5" />,
          label: '알림 소리',
          type: 'toggle' as const,
          value: soundEnabled,
          onChange: setSoundEnabled,
          color: '#FFDDC5'
        },
      ]
    },
    {
      title: '기기 연동',
      items: [
        {
          icon: <Watch className="w-5 h-5" />,
          label: 'Apple Watch 연동',
          type: 'toggle' as const,
          value: watchEnabled,
          onChange: setWatchEnabled,
          color: '#D4E4FF'
        },
      ]
    },
    {
      title: '개인화',
      items: [
        {
          icon: <Smile className="w-5 h-5" />,
          label: '캐릭터 설정',
          type: 'navigation' as const,
          color: '#FFE4E9',
          onClick: () => console.log('캐릭터 설정')
        },
        {
          icon: <Palette className="w-5 h-5" />,
          label: '테마 설정',
          type: 'navigation' as const,
          color: '#E8DDFA',
          onClick: () => console.log('테마 설정')
        },
      ]
    },
    {
      title: '지원',
      items: [
        {
          icon: <Mail className="w-5 h-5" />,
          label: '문의하기',
          type: 'navigation' as const,
          color: '#D4C5F0',
          onClick: () => console.log('문의하기')
        },
        {
          icon: <Info className="w-5 h-5" />,
          label: '버전 정보',
          type: 'info' as const,
          value: 'v1.0.0',
          color: '#B8A4C9'
        },
      ]
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
        
        {/* Subtle Background Decorations */}
        <SubtleDecorations />

        {/* Header */}
        <div className="px-6 pt-12 pb-6 relative z-10">
          <div className="flex items-center justify-between mb-6">
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

            <motion.h1
              className="text-xl"
              style={{ color: '#8B7B9E' }}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
            >
              설정
            </motion.h1>

            <div className="w-10" /> {/* Spacer */}
          </div>

          {/* Profile Card */}
          <motion.div
            className="rounded-3xl p-5 backdrop-blur-sm"
            style={{
              background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.8) 0%, rgba(255, 249, 245, 0.8) 100%)',
              border: '2px solid rgba(232, 221, 250, 0.3)',
              boxShadow: '0 8px 24px rgba(184, 164, 201, 0.15)'
            }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <div className="flex items-center gap-4">
              {/* Character Avatar */}
              <motion.div
                className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl relative"
                style={{ 
                  background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
                  boxShadow: '0 4px 16px rgba(255, 184, 198, 0.3)'
                }}
                animate={{ 
                  y: [0, -5, 0],
                }}
                transition={{ 
                  duration: 2.5,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                🐻
                {/* Online indicator */}
                <div 
                  className="absolute bottom-0 right-0 w-4 h-4 rounded-full border-2 border-white"
                  style={{ background: '#7FDD8F' }}
                />
              </motion.div>

              {/* User Info */}
              <div className="flex-1">
                <h3 className="text-base mb-1" style={{ color: '#8B7B9E', fontWeight: 500 }}>
                  나의 루틴 친구
                </h3>
                <p className="text-xs" style={{ color: '#B8A4C9' }}>
                  오늘도 함께 해요! 🌟
                </p>
              </div>

              {/* Stats Badge */}
              <div className="text-center">
                <div className="text-lg mb-0.5" style={{ color: '#FFB8C6', fontWeight: 600 }}>
                  3
                </div>
                <div className="text-xs" style={{ color: '#B8A4C9' }}>
                  연속 일
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Settings List */}
        <div className="px-6 pb-6 overflow-y-auto relative z-10" style={{ height: 'calc(100% - 240px)' }}>
          {settingsSections.map((section, sectionIndex) => (
            <motion.div
              key={section.title}
              className="mb-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 + sectionIndex * 0.1 }}
            >
              {/* Section Title */}
              <h3 className="text-xs mb-3 px-3" style={{ color: '#B8A4C9', fontWeight: 500 }}>
                {section.title}
              </h3>

              {/* Section Items */}
              <div className="rounded-2xl overflow-hidden backdrop-blur-sm"
                   style={{
                     background: 'rgba(255, 255, 255, 0.6)',
                     border: '1px solid rgba(232, 221, 250, 0.3)'
                   }}>
                {section.items.map((item, itemIndex) => (
                  <SettingItem
                    key={item.label}
                    item={item}
                    isLast={itemIndex === section.items.length - 1}
                  />
                ))}
              </div>
            </motion.div>
          ))}

          {/* Footer */}
          <motion.div
            className="text-center pt-4 pb-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
          >
            <div className="text-xs mb-2" style={{ color: '#B8A4C9' }}>
              Made with 💕
            </div>
            <div className="text-xs" style={{ color: '#D4C5F0' }}>
              Routine Timer App
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}

// Setting Item Component
interface SettingItemProps {
  item: {
    icon: React.ReactNode;
    label: string;
    type: 'toggle' | 'navigation' | 'info';
    value?: any;
    onChange?: (value: any) => void;
    onClick?: () => void;
    color: string;
  };
  isLast: boolean;
}

function SettingItem({ item, isLast }: SettingItemProps) {
  return (
    <motion.div
      className="px-4 py-4 flex items-center gap-3"
      style={{
        borderBottom: isLast ? 'none' : '1px solid rgba(232, 221, 250, 0.2)'
      }}
      whileTap={item.type === 'navigation' ? { scale: 0.98 } : {}}
      onClick={item.onClick}
    >
      {/* Icon */}
      <div 
        className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
        style={{ 
          background: `${item.color}40`,
          color: item.color
        }}
      >
        {item.icon}
      </div>

      {/* Label */}
      <div className="flex-1">
        <div className="text-sm" style={{ color: '#8B7B9E', fontWeight: 500 }}>
          {item.label}
        </div>
      </div>

      {/* Action */}
      <div className="flex-shrink-0">
        {item.type === 'toggle' && (
          <Toggle 
            value={item.value} 
            onChange={item.onChange!}
            color={item.color}
          />
        )}
        
        {item.type === 'navigation' && (
          <ChevronRight className="w-5 h-5" style={{ color: '#B8A4C9' }} />
        )}
        
        {item.type === 'info' && (
          <span className="text-xs px-3 py-1 rounded-full"
                style={{ 
                  background: 'rgba(184, 164, 201, 0.15)',
                  color: '#8B7B9E'
                }}>
            {item.value}
          </span>
        )}
      </div>
    </motion.div>
  );
}

// Toggle Component
interface ToggleProps {
  value: boolean;
  onChange: (value: boolean) => void;
  color: string;
}

function Toggle({ value, onChange, color }: ToggleProps) {
  return (
    <motion.button
      className="relative w-12 h-7 rounded-full"
      style={{
        background: value 
          ? `linear-gradient(135deg, ${color} 0%, ${color}CC 100%)`
          : 'rgba(184, 164, 201, 0.2)'
      }}
      onClick={() => onChange(!value)}
      whileTap={{ scale: 0.95 }}
    >
      <motion.div
        className="absolute top-1 w-5 h-5 rounded-full bg-white shadow-md"
        animate={{
          x: value ? 26 : 4
        }}
        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
      />
    </motion.button>
  );
}

// Subtle Decorations
function SubtleDecorations() {
  return (
    <>
      {/* Minimal sparkles */}
      {[...Array(4)].map((_, i) => (
        <motion.div
          key={`sparkle-${i}`}
          className="absolute"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 6 + 10}px`,
            opacity: 0.15,
          }}
          animate={{
            opacity: [0.1, 0.3, 0.1],
            scale: [0.8, 1.2, 0.8],
          }}
          transition={{
            duration: 3 + Math.random() * 2,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: "easeInOut"
          }}
        >
          ✨
        </motion.div>
      ))}

      {/* Minimal stars */}
      {[...Array(3)].map((_, i) => (
        <motion.div
          key={`star-${i}`}
          className="absolute"
          style={{
            top: `${Math.random() * 100}%`,
            left: `${Math.random() * 100}%`,
            fontSize: `${Math.random() * 6 + 8}px`,
            opacity: 0.12,
          }}
          animate={{
            opacity: [0.08, 0.25, 0.08],
            rotate: [0, 180, 360],
          }}
          transition={{
            duration: 4 + Math.random() * 2,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: "easeInOut"
          }}
        >
          ⭐
        </motion.div>
      ))}
    </>
  );
}
