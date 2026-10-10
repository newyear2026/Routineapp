import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/home/home_cat_pose.dart';
import 'package:routine_timer/domain/models/routine_icon_id.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';

void main() {
  test('완료·미루기·스킵은 슬롯 상태가 포즈를 정한다', () {
    expect(
      catPoseFor(
        status: RoutineLogStatus.completed,
        iconId: RoutineIconId.bowl,
      ),
      CatPose.complete,
    );
    expect(
      catPoseFor(
        status: RoutineLogStatus.snoozed,
        iconId: RoutineIconId.sun,
      ),
      CatPose.rest,
    );
    expect(
      catPoseFor(
        status: RoutineLogStatus.skipped,
        iconId: RoutineIconId.sun,
      ),
      CatPose.idle,
    );
  });

  test('진행 중이면 아이콘으로 휴식·집중·활동을 가른다', () {
    expect(
      catPoseFor(
        status: RoutineLogStatus.active,
        iconId: RoutineIconId.coffee,
      ),
      CatPose.rest,
    );
    expect(
      catPoseFor(
        status: RoutineLogStatus.active,
        iconId: RoutineIconId.book,
      ),
      CatPose.focus,
    );
    expect(
      catPoseFor(
        status: RoutineLogStatus.active,
        iconId: RoutineIconId.sun,
      ),
      CatPose.activity,
    );
    expect(catPoseFor(status: null, iconId: null), CatPose.idle);
  });
}
