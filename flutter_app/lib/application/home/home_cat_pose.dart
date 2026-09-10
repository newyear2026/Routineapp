import 'home_snapshot.dart';
import '../../domain/models/routine_log_status.dart';

enum CatPose { idle, activity, focus, complete, rest, guide }

/// Selects a decorative pose; stored legacy icons are never rendered as text.
CatPose homeCatPose(HomeSnapshot home) {
  if (home.currentRoutineLogStatus == RoutineLogStatus.completed) {
    return CatPose.complete;
  }
  if (home.currentRoutineLogStatus == RoutineLogStatus.snoozed) {
    return CatPose.rest;
  }
  if (home.currentRoutineLogStatus == RoutineLogStatus.skipped ||
      home.currentRoutine == null) {
    return CatPose.idle;
  }
  final icon = home.currentRoutine!.iconEmoji;
  if (const ['☕', '🌙', '🛌', '😴', '💤'].contains(icon)) return CatPose.rest;
  if (const ['📚', '📖', '💻', '✏️'].contains(icon)) return CatPose.focus;
  return CatPose.activity;
}
