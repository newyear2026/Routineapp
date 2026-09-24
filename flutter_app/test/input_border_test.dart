import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_pixel_style.dart';
import 'package:routine_timer/theme/app_theme.dart';

/// 입력창은 상태를 **색으로만** 말한다.
///
/// 굵기까지 상태마다 다르면 포커스가 들고 날 때 테두리가 튄다. 실제로
/// 그랬다 — 공통 굵기를 1.5 로 내리면서 기본/활성 테두리만 바꾸고,
/// 포커스·오류 테두리는 2 로 남아 있었다.
void main() {
  double widthOf(InputBorder? border) =>
      (border! as OutlineInputBorder).borderSide.width;

  Color colorOf(InputBorder? border) =>
      (border! as OutlineInputBorder).borderSide.color;

  test('네 가지 테두리가 모두 같은 굵기다', () {
    final input = buildRoutineTheme().inputDecorationTheme;

    for (final entry in <String, InputBorder?>{
      'border': input.border,
      'enabledBorder': input.enabledBorder,
      'focusedBorder': input.focusedBorder,
      'errorBorder': input.errorBorder,
      'focusedErrorBorder': input.focusedErrorBorder,
    }.entries) {
      expect(
        widthOf(entry.value),
        AppPixelStyle.borderWidth,
        reason: '${entry.key} 만 굵기가 다르면 그 상태로 들어갈 때 테두리가 튄다',
      );
    }
  });

  test('상태는 색으로 갈린다', () {
    // 굵기를 묶었으니 구분은 색이 전부 진다. 색까지 같아지면 포커스와
    // 오류가 보이지 않는다.
    final input = buildRoutineTheme().inputDecorationTheme;

    expect(colorOf(input.focusedBorder), isNot(colorOf(input.enabledBorder)));
    expect(colorOf(input.errorBorder), isNot(colorOf(input.enabledBorder)));
    expect(colorOf(input.focusedErrorBorder), colorOf(input.errorBorder));
  });
}
