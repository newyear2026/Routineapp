import { useState } from 'react';
import { useNavigate } from 'react-router';
import { motion } from 'motion/react';
import { Check } from 'lucide-react';

interface Routine {
  id: string;
  name: string;
  emoji: string;
  defaultTime: string;
  color: string;
  selected: boolean;
}

export function InitialRoutineSetupScreen() {
  const navigate = useNavigate();
  
  const [routines, setRoutines] = useState<Routine[]>([
    {
      id: '1',
      name: '기상',
      emoji: '🌅',
      defaultTime: '07:00',
      color: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
      selected: true
    },
    {
      id: '2',
      name: '운동',
      emoji: '💪',
      defaultTime: '07:30',
      color: 'linear-gradient(135deg, #FFD4E0 0%, #FFC9DA 100%)',
      selected: true
    },
    {
      id: '3',
      name: '아침식사',
      emoji: '🍳',
      defaultTime: '09:00',
      color: 'linear-gradient(135deg, #FFE9D4 0%, #FFDDC5 100%)',
      selected: true
    },
    {
      id: '4',
      name: '공부',
      emoji: '📚',
      defaultTime: '10:00',
      color: 'linear-gradient(135deg, #E8DDFA 0%, #D4C5F0 100%)',
      selected: true
    },
    {
      id: '5',
      name: '점심식사',
      emoji: '🍱',
      defaultTime: '12:00',
      color: 'linear-gradient(135deg, #FFDDC5 0%, #FFD0B8 100%)',
      selected: true
    },
    {
      id: '6',
      name: '휴식',
      emoji: '☕',
      defaultTime: '15:00',
      color: 'linear-gradient(135deg, #D4E4FF 0%, #C5D5F0 100%)',
      selected: false
    },
    {
      id: '7',
      name: '저녁식사',
      emoji: '🍽️',
      defaultTime: '18:00',
      color: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)',
      selected: true
    },
    {
      id: '8',
      name: '취침',
      emoji: '🌙',
      defaultTime: '23:00',
      color: 'linear-gradient(135deg, #D4C5F0 0%, #C4B5E6 100%)',
      selected: true
    }
  ]);

  const toggleRoutine = (id: string) => {
    setRoutines(routines.map(routine => 
      routine.id === id ? { ...routine, selected: !routine.selected } : routine
    ));
  };

  const updateRoutineTime = (id: string, time: string) => {
    setRoutines(routines.map(routine => 
      routine.id === id ? { ...routine, defaultTime: time } : routine
    ));
  };

  const handleComplete = () => {
    navigate('/home');
  };

  const selectedCount = routines.filter(r => r.selected).length;

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
          className="absolute top-[8%] right-[10%] text-2xl z-0"
          animate={{ 
            rotate: [0, 15, 0],
            scale: [1, 1.2, 1],
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
          className="absolute top-[12%] left-[8%] text-xl z-0"
          animate={{ 
            rotate: [0, -12, 0],
            scale: [1, 1.15, 1],
          }}
          transition={{ 
            duration: 2.8,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 0.5
          }}
        >
          🌟
        </motion.div>

        {/* Content */}
        <div className="h-full flex flex-col relative z-10">
          
          {/* Header */}
          <motion.div
            className="px-6 pt-12 pb-6"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="text-center mb-2">
              <h2 className="text-3xl mb-3" style={{ color: '#8B7B9E' }}>
                하루의 기본 루틴을<br />만들어볼까요?
              </h2>
              <p className="text-sm" style={{ color: '#B8A4C9' }}>
                원하는 루틴을 선택하고 시간을 설정해보세요
              </p>
            </div>

            {/* Progress Indicator */}
            <motion.div
              className="mt-4 text-center"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full"
                   style={{ 
                     background: 'rgba(255, 184, 198, 0.15)',
                     border: '1px solid rgba(255, 184, 198, 0.3)'
                   }}>
                <span className="text-sm" style={{ color: '#FFB8C6' }}>
                  {selectedCount}개 선택됨
                </span>
              </div>
            </motion.div>
          </motion.div>

          {/* Routines Grid */}
          <div className="flex-1 overflow-y-auto px-6 pb-24">
            <div className="grid grid-cols-2 gap-3">
              {routines.map((routine, index) => (
                <RoutineCard
                  key={routine.id}
                  routine={routine}
                  index={index}
                  onToggle={() => toggleRoutine(routine.id)}
                  onTimeChange={(time) => updateRoutineTime(routine.id, time)}
                />
              ))}
            </div>

            {/* Tip */}
            <motion.div
              className="mt-6 p-4 rounded-2xl text-center"
              style={{
                background: 'linear-gradient(135deg, rgba(232, 221, 250, 0.3) 0%, rgba(212, 197, 240, 0.3) 100%)',
                border: '1px solid rgba(212, 197, 240, 0.4)'
              }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8 }}
            >
              <div className="text-2xl mb-2">💡</div>
              <p className="text-xs leading-relaxed" style={{ color: '#B8A4C9' }}>
                나중에 언제든지 루틴을 추가하거나<br />
                수정할 수 있어요
              </p>
            </motion.div>
          </div>

          {/* Bottom Button */}
          <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-[#FFF5F8] via-[#FFF5F8]/95 to-transparent">
            <motion.button
              className="w-full py-4 rounded-3xl flex items-center justify-center gap-2 shadow-lg text-white"
              style={{
                background: 'linear-gradient(135deg, #FFB8C6 0%, #D4C5F0 100%)'
              }}
              onClick={handleComplete}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              <span className="text-lg">완료하고 시작하기</span>
              <Check className="w-5 h-5" />
            </motion.button>

            <motion.p
              className="text-center mt-3 text-xs"
              style={{ color: '#B8A4C9' }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.7 }}
            >
              선택된 루틴이 원형 시간표에 표시돼요
            </motion.p>
          </div>
        </div>
      </div>
    </div>
  );
}

// Routine Card Component
interface RoutineCardProps {
  routine: Routine;
  index: number;
  onToggle: () => void;
  onTimeChange: (time: string) => void;
}

function RoutineCard({ routine, index, onToggle, onTimeChange }: RoutineCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.1 * index }}
    >
      <motion.button
        className="w-full rounded-2xl p-4 shadow-md relative overflow-hidden"
        style={{
          background: routine.selected ? routine.color : '#FFFFFF',
          border: routine.selected 
            ? '2px solid rgba(255, 255, 255, 0.8)' 
            : '2px solid rgba(184, 164, 201, 0.2)',
        }}
        onClick={onToggle}
        whileTap={{ scale: 0.95 }}
      >
        {/* Check Badge */}
        <motion.div
          className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
          style={{
            background: routine.selected 
              ? 'rgba(255, 255, 255, 0.9)' 
              : 'rgba(184, 164, 201, 0.2)',
          }}
          initial={false}
          animate={{ scale: routine.selected ? 1 : 0.8 }}
        >
          {routine.selected && (
            <Check className="w-4 h-4" style={{ color: '#FFB8C6' }} />
          )}
        </motion.div>

        {/* Emoji */}
        <div className="text-4xl mb-2">{routine.emoji}</div>

        {/* Name */}
        <div className="text-sm mb-3" 
             style={{ 
               color: routine.selected ? '#8B7B9E' : '#B8A4C9',
               fontWeight: routine.selected ? 500 : 400
             }}>
          {routine.name}
        </div>

        {/* Time Picker */}
        {routine.selected && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            onClick={(e) => e.stopPropagation()}
          >
            <input
              type="time"
              value={routine.defaultTime}
              onChange={(e) => onTimeChange(e.target.value)}
              className="w-full px-3 py-2 rounded-xl text-sm text-center bg-white/70 backdrop-blur-sm"
              style={{
                color: '#8B7B9E',
                border: '1px solid rgba(255, 255, 255, 0.8)',
                outline: 'none'
              }}
            />
          </motion.div>
        )}
      </motion.button>
    </motion.div>
  );
}
