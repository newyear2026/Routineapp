import { motion } from 'motion/react';

interface CircularClockProps {
  currentRoutine: string;
}

export function CircularClock({ currentRoutine }: CircularClockProps) {
  const routines = [
    { time: '6시', label: '기상', color: '#FFE4E9', angle: 0 },
    { time: '7시', label: '운동', color: '#FFD4E0', angle: 30 },
    { time: '8시', label: '샤워', color: '#FFC9DA', angle: 60 },
    { time: '9시', label: '아침', color: '#FFB8C6', angle: 90 },
    { time: '10시', label: '공부', color: '#E8DDFA', angle: 120 },
    { time: '11시', label: '작업', color: '#D4C5F0', angle: 150 },
    { time: '12시', label: '점심', color: '#C4B5E6', angle: 180 },
    { time: '13시', label: '휴식', color: '#B8A4C9', angle: 210 },
  ];

  const currentHour = 9;
  const currentMinute = 30;
  const hourAngle = ((currentHour % 12) * 30 + currentMinute * 0.5) - 90;

  return (
    <div className="relative w-full aspect-square max-w-[300px] mx-auto">
      {/* Background Circle */}
      <div className="absolute inset-0 rounded-full" 
           style={{ 
             background: 'linear-gradient(135deg, #FFFFFF 0%, #FFF9F5 100%)',
             boxShadow: '0 8px 32px rgba(255, 184, 198, 0.2)'
           }}>
      </div>

      {/* Routine Segments */}
      <svg className="absolute inset-0 w-full h-full" viewBox="0 0 200 200">
        <defs>
          {routines.map((routine, index) => (
            <linearGradient key={index} id={`gradient-${index}`} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style={{ stopColor: routine.color, stopOpacity: 0.8 }} />
              <stop offset="100%" style={{ stopColor: routine.color, stopOpacity: 0.4 }} />
            </linearGradient>
          ))}
        </defs>
        
        {routines.map((routine, index) => {
          const startAngle = index * 45;
          const endAngle = (index + 1) * 45;
          const innerRadius = 60;
          const outerRadius = 85;
          
          const startAngleRad = (startAngle - 90) * (Math.PI / 180);
          const endAngleRad = (endAngle - 90) * (Math.PI / 180);
          
          const x1 = 100 + innerRadius * Math.cos(startAngleRad);
          const y1 = 100 + innerRadius * Math.sin(startAngleRad);
          const x2 = 100 + outerRadius * Math.cos(startAngleRad);
          const y2 = 100 + outerRadius * Math.sin(startAngleRad);
          const x3 = 100 + outerRadius * Math.cos(endAngleRad);
          const y3 = 100 + outerRadius * Math.sin(endAngleRad);
          const x4 = 100 + innerRadius * Math.cos(endAngleRad);
          const y4 = 100 + innerRadius * Math.sin(endAngleRad);
          
          const largeArc = endAngle - startAngle > 180 ? 1 : 0;
          
          return (
            <motion.path
              key={index}
              d={`M ${x1} ${y1} L ${x2} ${y2} A ${outerRadius} ${outerRadius} 0 ${largeArc} 1 ${x3} ${y3} L ${x4} ${y4} A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${x1} ${y1} Z`}
              fill={`url(#gradient-${index})`}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: index * 0.05 }}
            />
          );
        })}
      </svg>

      {/* Labels */}
      {routines.map((routine, index) => {
        const angle = index * 45;
        const radius = 95;
        const angleRad = (angle - 90) * (Math.PI / 180);
        const x = 50 + (radius / 2) * Math.cos(angleRad);
        const y = 50 + (radius / 2) * Math.sin(angleRad);
        
        return (
          <motion.div
            key={index}
            className="absolute text-xs text-center"
            style={{
              left: `${x}%`,
              top: `${y}%`,
              transform: 'translate(-50%, -50%)',
              color: '#8B7B9E',
              fontWeight: 500
            }}
            initial={{ opacity: 0, scale: 0 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.4, delay: 0.3 + index * 0.05 }}
          >
            {routine.label}
          </motion.div>
        );
      })}

      {/* Center Circle */}
      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 
                      w-[120px] h-[120px] rounded-full flex items-center justify-center"
           style={{ 
             background: 'linear-gradient(135deg, #FFFFFF 0%, #FFF9F5 100%)',
             boxShadow: '0 4px 16px rgba(184, 164, 201, 0.2)'
           }}>
        <div className="text-center">
          <motion.div 
            className="text-3xl mb-1"
            style={{ color: '#8B7B9E' }}
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', duration: 0.6, delay: 0.5 }}
          >
            {currentHour}:{currentMinute.toString().padStart(2, '0')}
          </motion.div>
          <div className="text-xs" style={{ color: '#B8A4C9' }}>현재 시간</div>
        </div>
      </div>

      {/* Clock Hand */}
      <motion.div
        className="absolute top-1/2 left-1/2 origin-left"
        style={{
          width: '60px',
          height: '3px',
          background: 'linear-gradient(90deg, #FFB8C6 0%, #FF8CA8 100%)',
          borderRadius: '999px',
          transform: `translate(-10px, -1.5px) rotate(${hourAngle}deg)`,
          boxShadow: '0 2px 8px rgba(255, 140, 168, 0.4)'
        }}
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: 'spring', duration: 0.8, delay: 0.7 }}
      />
      
      {/* Clock Hand Dot */}
      <motion.div
        className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 
                   w-3 h-3 rounded-full"
        style={{
          background: 'linear-gradient(135deg, #FFB8C6 0%, #FF8CA8 100%)',
          boxShadow: '0 2px 8px rgba(255, 140, 168, 0.4)'
        }}
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: 'spring', duration: 0.6, delay: 0.8 }}
      />

      {/* Decorative Sparkles */}
      <motion.div
        className="absolute top-[10%] right-[15%] text-xl"
        animate={{ 
          rotate: [0, 15, 0],
          scale: [1, 1.2, 1]
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
        className="absolute bottom-[15%] left-[10%] text-lg"
        animate={{ 
          rotate: [0, -15, 0],
          scale: [1, 1.1, 1]
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
    </div>
  );
}
