import { motion, AnimatePresence } from 'motion/react';
import { X, Edit, Trash2, Clock, Calendar, Hash, Palette, FileText, CheckCircle2 } from 'lucide-react';

interface RoutineDetailSheetProps {
  isOpen: boolean;
  onClose: () => void;
  routine: {
    name: string;
    emoji: string;
    startTime: string;
    endTime: string;
    color: string;
    repeatDays: string[];
    memo: string;
    todayStatus: 'pending' | 'completed' | 'skipped';
  };
  onEdit: () => void;
  onDelete: () => void;
}

export function RoutineDetailSheet({ isOpen, onClose, routine, onEdit, onDelete }: RoutineDetailSheetProps) {
  const dayNames: { [key: string]: string } = {
    '월': '월요일',
    '화': '화요일',
    '수': '수요일',
    '목': '목요일',
    '금': '금요일',
    '토': '토요일',
    '일': '일요일'
  };

  const allDays = ['월', '화', '수', '목', '금', '토', '일'];

  const getStatusInfo = () => {
    switch (routine.todayStatus) {
      case 'completed':
        return {
          text: '완료됨',
          emoji: '✅',
          color: '#D4E4FF',
          textColor: '#6B8BC9'
        };
      case 'skipped':
        return {
          text: '건너뜀',
          emoji: '⏭️',
          color: '#FFE4E9',
          textColor: '#D99BB0'
        };
      default:
        return {
          text: '대기 중',
          emoji: '⏰',
          color: '#FFE9D4',
          textColor: '#D9A57B'
        };
    }
  };

  const statusInfo = getStatusInfo();

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Bottom Sheet */}
          <motion.div
            className="fixed bottom-0 left-0 right-0 z-50 flex items-end justify-center px-4 pb-4"
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
          >
            <div className="w-full max-w-[390px] rounded-t-[40px] overflow-hidden"
                 style={{
                   background: 'linear-gradient(180deg, #FFF8F3 0%, #FFF5F8 100%)',
                   maxHeight: '85vh'
                 }}>
              
              {/* Decorative elements */}
              <div className="absolute top-4 right-8 text-2xl opacity-40">✨</div>
              <div className="absolute top-12 left-8 text-xl opacity-30">🌟</div>

              {/* Handle bar */}
              <div className="pt-3 pb-4 flex justify-center">
                <div className="w-12 h-1.5 rounded-full" 
                     style={{ background: 'rgba(184, 164, 201, 0.3)' }} />
              </div>

              {/* Header */}
              <div className="px-6 pb-4">
                <div className="flex items-start justify-between">
                  {/* Routine Icon & Name */}
                  <div className="flex items-center gap-4">
                    <motion.div
                      className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl shadow-lg"
                      style={{
                        background: `linear-gradient(135deg, ${routine.color} 0%, ${routine.color}CC 100%)`
                      }}
                      initial={{ scale: 0, rotate: -180 }}
                      animate={{ scale: 1, rotate: 0 }}
                      transition={{ type: 'spring', duration: 0.6 }}
                    >
                      {routine.emoji}
                    </motion.div>

                    <div>
                      <motion.h2
                        className="text-2xl mb-1"
                        style={{ color: '#8B7B9E' }}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.1 }}
                      >
                        {routine.name}
                      </motion.h2>
                      <motion.div
                        className="flex items-center gap-2"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.2 }}
                      >
                        <Clock className="w-4 h-4" style={{ color: '#B8A4C9' }} />
                        <span className="text-sm" style={{ color: '#B8A4C9' }}>
                          {routine.startTime} - {routine.endTime}
                        </span>
                      </motion.div>
                    </div>
                  </div>

                  {/* Close Button */}
                  <motion.button
                    className="w-10 h-10 rounded-full flex items-center justify-center"
                    style={{ background: 'rgba(184, 164, 201, 0.15)' }}
                    onClick={onClose}
                    whileTap={{ scale: 0.9 }}
                    initial={{ opacity: 0, scale: 0 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.2 }}
                  >
                    <X className="w-5 h-5" style={{ color: '#B8A4C9' }} />
                  </motion.button>
                </div>
              </div>

              {/* Content */}
              <div className="px-6 pb-6 overflow-y-auto" style={{ maxHeight: '60vh' }}>
                
                {/* Today's Status */}
                <motion.div
                  className="mb-4 p-4 rounded-2xl"
                  style={{
                    background: statusInfo.color,
                  }}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{statusInfo.emoji}</span>
                      <div>
                        <div className="text-xs mb-0.5" style={{ color: statusInfo.textColor, opacity: 0.8 }}>
                          오늘 상태
                        </div>
                        <div className="text-sm" style={{ color: statusInfo.textColor, fontWeight: 500 }}>
                          {statusInfo.text}
                        </div>
                      </div>
                    </div>
                    {routine.todayStatus === 'completed' && (
                      <CheckCircle2 className="w-6 h-6" style={{ color: statusInfo.textColor }} />
                    )}
                  </div>
                </motion.div>

                {/* Info Cards */}
                <div className="space-y-3 mb-6">
                  
                  {/* Time Range */}
                  <InfoCard
                    icon={<Clock className="w-5 h-5" style={{ color: '#FFB8C6' }} />}
                    label="시간"
                    value={`${routine.startTime} - ${routine.endTime}`}
                    delay={0.4}
                  />

                  {/* Repeat Days */}
                  <motion.div
                    className="rounded-2xl p-4"
                    style={{
                      background: 'rgba(255, 255, 255, 0.6)',
                      border: '1px solid rgba(232, 221, 250, 0.3)'
                    }}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                  >
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 rounded-full flex items-center justify-center"
                           style={{ background: 'rgba(212, 197, 240, 0.2)' }}>
                        <Calendar className="w-5 h-5" style={{ color: '#D4C5F0' }} />
                      </div>
                      <div>
                        <div className="text-xs mb-0.5" style={{ color: '#B8A4C9' }}>반복 요일</div>
                        <div className="text-sm" style={{ color: '#8B7B9E', fontWeight: 500 }}>
                          {routine.repeatDays.length === 7 ? '매일' : routine.repeatDays.join(', ')}
                        </div>
                      </div>
                    </div>
                    
                    {/* Day Pills */}
                    <div className="flex gap-2">
                      {allDays.map((day) => {
                        const isActive = routine.repeatDays.includes(day);
                        return (
                          <motion.div
                            key={day}
                            className="flex-1 py-2 rounded-xl text-center text-xs"
                            style={{
                              background: isActive 
                                ? 'linear-gradient(135deg, #D4C5F0 0%, #C4B5E6 100%)'
                                : 'rgba(184, 164, 201, 0.1)',
                              color: isActive ? '#FFFFFF' : '#B8A4C9',
                              fontWeight: isActive ? 500 : 400
                            }}
                            whileHover={{ scale: 1.05 }}
                          >
                            {day}
                          </motion.div>
                        );
                      })}
                    </div>
                  </motion.div>

                  {/* Color */}
                  <InfoCard
                    icon={<Palette className="w-5 h-5" style={{ color: '#FFDDC5' }} />}
                    label="색상"
                    value={
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full border-2 border-white shadow-md"
                             style={{ background: routine.color }} />
                        <span>{routine.color}</span>
                      </div>
                    }
                    delay={0.6}
                  />

                  {/* Memo */}
                  {routine.memo && (
                    <motion.div
                      className="rounded-2xl p-4"
                      style={{
                        background: 'rgba(255, 255, 255, 0.6)',
                        border: '1px solid rgba(255, 233, 212, 0.3)'
                      }}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.7 }}
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                             style={{ background: 'rgba(255, 233, 212, 0.3)' }}>
                          <FileText className="w-5 h-5" style={{ color: '#FFDDC5' }} />
                        </div>
                        <div className="flex-1">
                          <div className="text-xs mb-1" style={{ color: '#B8A4C9' }}>메모</div>
                          <div className="text-sm leading-relaxed" style={{ color: '#8B7B9E' }}>
                            {routine.memo}
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </div>

                {/* Action Buttons */}
                <motion.div
                  className="flex gap-3"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.8 }}
                >
                  {/* Edit Button */}
                  <motion.button
                    className="flex-1 py-4 rounded-2xl flex items-center justify-center gap-2 shadow-lg"
                    style={{
                      background: 'linear-gradient(135deg, #D4E4FF 0%, #C5D5F0 100%)'
                    }}
                    onClick={onEdit}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <Edit className="w-5 h-5" style={{ color: '#6B8BC9' }} />
                    <span style={{ color: '#6B8BC9', fontWeight: 500 }}>수정하기</span>
                  </motion.button>

                  {/* Delete Button */}
                  <motion.button
                    className="py-4 px-5 rounded-2xl flex items-center justify-center shadow-lg"
                    style={{
                      background: 'linear-gradient(135deg, #FFE4E9 0%, #FFD4E0 100%)'
                    }}
                    onClick={onDelete}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <Trash2 className="w-5 h-5" style={{ color: '#D99BB0' }} />
                  </motion.button>
                </motion.div>

                {/* Tip */}
                <motion.div
                  className="mt-4 p-3 rounded-xl text-center"
                  style={{
                    background: 'rgba(232, 221, 250, 0.2)',
                    border: '1px solid rgba(232, 221, 250, 0.3)'
                  }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.9 }}
                >
                  <div className="text-xs" style={{ color: '#B8A4C9' }}>
                    💡 루틴을 수정하거나 삭제할 수 있어요
                  </div>
                </motion.div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

// Info Card Component
interface InfoCardProps {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
  delay: number;
}

function InfoCard({ icon, label, value, delay }: InfoCardProps) {
  return (
    <motion.div
      className="rounded-2xl p-4"
      style={{
        background: 'rgba(255, 255, 255, 0.6)',
        border: '1px solid rgba(232, 221, 250, 0.3)'
      }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay }}
    >
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full flex items-center justify-center"
             style={{ background: 'rgba(255, 184, 198, 0.2)' }}>
          {icon}
        </div>
        <div className="flex-1">
          <div className="text-xs mb-0.5" style={{ color: '#B8A4C9' }}>{label}</div>
          <div className="text-sm" style={{ color: '#8B7B9E', fontWeight: 500 }}>
            {value}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
