import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// 모든 테스트 파일 앞에 한 번 실행된다.
///
/// 앱은 `main()`에서 날짜 심볼을 올리지만 테스트는 `main()`을 타지 않는다.
/// 초기화를 빠뜨리면 로케일 기반 [DateFormat]이 곧바로 예외를 던진다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
