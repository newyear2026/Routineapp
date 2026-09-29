import '../../domain/models/routine_icon_id.dart';
import '../../domain/models/routine_log_status.dart';
import 'home_focus_state.dart';
import 'home_snapshot.dart';

enum CatPose { idle, activity, focus, complete, rest, guide }

/// 홈 첫 카드의 고양이는 카드 상태를 따른다. 다른 탭은 메뉴 고정 포즈를 쓴다.
CatPose homeCatPose(HomeSnapshot home) => switch (home.focusState) {
      HomeFocusState.dayDone => CatPose.complete,
      HomeFocusState.empty => CatPose.guide,
      _ => catPoseFor(
          status: home.currentRoutineLogStatus,
          iconId: home.currentRoutine?.iconId,
        ),
    };

CatPose catPoseFor({
  required RoutineLogStatus? status,
  RoutineIconId? iconId,
}) {
  if (status == RoutineLogStatus.completed) return CatPose.complete;
  if (status == RoutineLogStatus.snoozed) return CatPose.rest;
  if (status == RoutineLogStatus.skipped || iconId == null) {
    return CatPose.idle;
  }
  return switch (iconId) {
    RoutineIconId.coffee || RoutineIconId.moon => CatPose.rest,
    RoutineIconId.book || RoutineIconId.laptop => CatPose.focus,
    _ => CatPose.activity,
  };
}
