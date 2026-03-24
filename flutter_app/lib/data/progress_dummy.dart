import '../models/progress_models.dart';

/// Progress 화면 정적 더미
const progressDummyPercent = 50;

const progressDummyCompleted = 4;
const progressDummyTotal = 8;

final progressDummyStatusGroups = <ProgressStatusGroup>[
  const ProgressStatusGroup(
    status: ProgressRoutineStatus.completed,
    items: [
      ProgressRoutineItem(emoji: '🌅', name: '기상', timeLabel: '07:00'),
      ProgressRoutineItem(emoji: '💪', name: '운동', timeLabel: '07:30'),
      ProgressRoutineItem(emoji: '🍳', name: '아침식사', timeLabel: '09:00'),
      ProgressRoutineItem(emoji: '🍱', name: '점심식사', timeLabel: '12:00'),
    ],
  ),
  const ProgressStatusGroup(
    status: ProgressRoutineStatus.later,
    items: [
      ProgressRoutineItem(emoji: '📚', name: '공부', timeLabel: '14:00'),
    ],
  ),
  const ProgressStatusGroup(
    status: ProgressRoutineStatus.skipped,
    items: [
      ProgressRoutineItem(emoji: '🌙', name: '취침', timeLabel: '23:00'),
    ],
  ),
  const ProgressStatusGroup(
    status: ProgressRoutineStatus.pending,
    items: [
      ProgressRoutineItem(emoji: '☕', name: '휴식', timeLabel: '15:00'),
      ProgressRoutineItem(emoji: '🍽️', name: '저녁식사', timeLabel: '18:00'),
    ],
  ),
];

const progressDummyCharacterFeedback = ProgressFeedbackContent(
  characterEmoji: '🐻',
  titleEmoji: '💪',
  title: '오늘 하루 피드백',
  message: '잘하고 있어요!\n벌써 절반이나 했어요!',
  subMessage: '이 기세로 계속 가봐요',
);

const progressDummyMiniStats = <ProgressMiniStat>[
  ProgressMiniStat(emoji: '🔥', label: '연속 달성', value: '3일'),
  ProgressMiniStat(emoji: '⭐', label: '평균 달성률', value: '67%'),
];
