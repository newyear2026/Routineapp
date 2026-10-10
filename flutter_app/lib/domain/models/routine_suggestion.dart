import 'routine_icon_id.dart';

/// 루틴 추가 화면의 추천 칩. 선언 순서가 곧 화면 순서다(하루 흐름).
///
/// 아이콘은 여기서 정한다. 번역된 이름으로 [RoutineIconId.guess]를 돌리면
/// 추측 규칙이 모르는 언어(es·ja·pt)에서 전부 기본 아이콘이 된다.
/// 이름 문장은 화면이 고른다(PROJECT_RULES 4).
enum RoutineSuggestion {
  wakeUp(RoutineIconId.sun),
  breakfast(RoutineIconId.breakfast),
  exercise(RoutineIconId.dumbbell),
  focus(RoutineIconId.laptop),
  rest(RoutineIconId.coffee),
  walk(RoutineIconId.plant),
  reading(RoutineIconId.book),
  bedtime(RoutineIconId.moon);

  const RoutineSuggestion(this.iconId);

  final RoutineIconId iconId;
}
