import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';

/// 디자인 토큰의 대비를 코드로 잠근다.
///
/// 이전 팔레트는 배경 `#F7F4EE` 위에 카드 `#FCFAF6`(1.06:1)를 얹어 카드가
/// 배경에 묻혔고, 진행 화면의 '완료'·'예정' 라벨은 1.6:1로 사실상 읽히지
/// 않았다. 같은 실수가 다시 들어오면 이 테스트가 먼저 깨진다.
void main() {
  group('상태 라벨은 카드 서피스 위에서 WCAG AA(4.5:1)를 만족한다', () {
    const cases = <String, Color>{
      'successText': AppColors.successText,
      'scheduledText': AppColors.scheduledText,
      'activeText': AppColors.activeText,
      'dangerText': AppColors.dangerText,
    };

    cases.forEach((name, color) {
      test(name, () {
        final ratio = _contrast(color, AppColors.orbitSurface);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name 대비 ${ratio.toStringAsFixed(2)}:1 — 본문 기준 미달',
        );
      });
    });
  });

  group('본문 텍스트는 페이지 배경과 카드 양쪽에서 AA를 만족한다', () {
    for (final surface in const <String, Color>{
      'pageBackground': AppColors.pageBackground,
      'orbitSurface': AppColors.orbitSurface,
    }.entries) {
      test('textPrimary on ${surface.key}', () {
        expect(
          _contrast(AppColors.textPrimary, surface.value),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('textMuted on ${surface.key}', () {
        expect(
          _contrast(AppColors.textMuted, surface.value),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  test('카드 서피스는 페이지 배경과 눈에 보이는 명도차를 갖는다', () {
    final delta =
        _lStar(AppColors.orbitSurface) - _lStar(AppColors.pageBackground);
    expect(
      delta,
      greaterThanOrEqualTo(5),
      reason: '명도차 ${delta.toStringAsFixed(1)} — 카드가 그림자로만 구분된다',
    );
  });

  test('페이지 인디케이터·아이콘 같은 비텍스트 요소는 배경 대비 3:1을 넘는다', () {
    // 이전 온보딩은 accentLavender(#D9D1F2)를 활성 인디케이터로 써서
    // 새 배경 위에서 1.2:1 — 몇 번째 장인지 보이지 않았다.
    final ratio = _contrast(AppColors.orbitPrimary, AppColors.pageBackground);
    expect(
      ratio,
      greaterThanOrEqualTo(3.0),
      reason: '대비 ${ratio.toStringAsFixed(2)}:1',
    );
    // 비활성 인디케이터도 같은 기준을 받는다. orbitBorder(1.22:1)로 되돌리면
    // 몇 번째 장인지 다시 보이지 않게 된다.
    expect(
      _contrast(AppColors.orbitBorder, AppColors.pageBackground),
      lessThan(3.0),
      reason: 'orbitBorder는 인디케이터로 쓸 수 없다는 근거를 남긴다',
    );
    final inactiveDot = Color.alphaBlend(
      AppColors.textMuted.withValues(alpha: 0.8),
      AppColors.pageBackground,
    );
    expect(
      _contrast(inactiveDot, AppColors.pageBackground),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('보더는 카드 서피스와 구분된다', () {
    expect(
      _lStar(AppColors.orbitSurface) - _lStar(AppColors.orbitBorder),
      greaterThanOrEqualTo(10),
    );
  });

  test('장식용 상태 채움색은 글자용 토큰과 분리되어 있다', () {
    // success / orbitAccent 는 배지 배경·점 전용이다.
    // 글자에 그대로 쓰면 대비가 무너지므로 값이 같아지면 안 된다.
    expect(AppColors.success, isNot(AppColors.successText));
    expect(AppColors.orbitAccent, isNot(AppColors.scheduledText));
    expect(_contrast(AppColors.success, AppColors.orbitSurface), lessThan(4.5));
    expect(
      _contrast(AppColors.orbitAccent, AppColors.orbitSurface),
      lessThan(4.5),
    );
  });
}

double _linear(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 상대 휘도.
double _luminance(Color color) {
  return 0.2126 * _linear(color.r) +
      0.7152 * _linear(color.g) +
      0.0722 * _linear(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// CIE L* — 사람이 느끼는 밝기. 대비비보다 '눈에 띄는 차이' 판단에 맞다.
double _lStar(Color color) {
  final y = _luminance(color);
  return y <= 0.008856
      ? 903.3 * y
      : 116 * math.pow(y, 1 / 3).toDouble() - 16;
}
