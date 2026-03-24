/// Progress 화면용 모델 (더미 → 이후 저장소/상태로 교체)
class ProgressRoutineItem {
  const ProgressRoutineItem({
    required this.emoji,
    required this.name,
    required this.timeLabel,
  });

  final String emoji;
  final String name;
  final String timeLabel;
}

enum ProgressRoutineStatus {
  completed,
  later,
  skipped,
  pending,
}

extension ProgressRoutineStatusX on ProgressRoutineStatus {
  String get label {
    switch (this) {
      case ProgressRoutineStatus.completed:
        return '완료';
      case ProgressRoutineStatus.later:
        return '나중에';
      case ProgressRoutineStatus.skipped:
        return '스킵';
      case ProgressRoutineStatus.pending:
        return '대기';
    }
  }
}

class ProgressStatusGroup {
  const ProgressStatusGroup({
    required this.status,
    required this.items,
  });

  final ProgressRoutineStatus status;
  final List<ProgressRoutineItem> items;
}

class ProgressFeedbackContent {
  const ProgressFeedbackContent({
    required this.characterEmoji,
    required this.titleEmoji,
    required this.title,
    required this.message,
    required this.subMessage,
  });

  final String characterEmoji;
  final String titleEmoji;
  final String title;
  final String message;
  final String subMessage;
}

class ProgressMiniStat {
  const ProgressMiniStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;
}
