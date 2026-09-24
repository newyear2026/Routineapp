import '../l10n/app_localizations.dart';

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
  noResponse,
  pending,
}

extension ProgressRoutineStatusX on ProgressRoutineStatus {
  /// 상태 이름은 언어에 따라 달라지므로 게터가 아니라 현재 언어를 받는다.
  String label(AppLocalizations l10n) {
    switch (this) {
      case ProgressRoutineStatus.completed:
        return l10n.statusCompleted;
      case ProgressRoutineStatus.later:
        return l10n.statusSnoozed;
      case ProgressRoutineStatus.skipped:
        return l10n.statusSkipped;
      case ProgressRoutineStatus.noResponse:
        return l10n.statusNoResponse;
      case ProgressRoutineStatus.pending:
        return l10n.statusWaiting;
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
    required this.titleEmoji,
    required this.title,
    required this.message,
    required this.subMessage,
  });

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
