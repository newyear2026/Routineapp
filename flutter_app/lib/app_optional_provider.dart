import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// provider에는 «있으면 보고 없으면 넘어간다»가 없다. 예외로 가르는 자리를
/// 한 곳에 모아 둔다.
///
/// 앱에서는 [RoutineTimerApp]이 모든 알림기를 최상단에 걸어 두므로 이 경로로
/// 빠지는 일이 없다. 화면 하나만 띄우는 테스트와 미리보기에서만 null이 되고,
/// 그때 딸린 기능은 **없는** 것이 된다 — 눌러도 답하지 않는 죽은 행이나,
/// 아무것도 가리키지 않는 배너가 남는 것이 아니다.
extension OptionalProvider on BuildContext {
  /// 프로바이더가 없으면 null. 값이 바뀔 때 다시 그린다.
  T? maybeWatch<T extends Object>() {
    try {
      return watch<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// 프로바이더가 없으면 null. 다시 그리지 않는다 —
  /// `didChangeDependencies`에서 한 번 붙잡을 때 쓴다.
  T? maybeRead<T extends Object>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
