import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/widget_medium/widget_theme.dart';

/// 홈 화면 위젯이 앱 팔레트에서 다시 떨어져 나가지 않게 잠근다.
///
/// 예전 위젯은 아이보리(#FFF7ED)·브라운(#5C4033)·테라코타(#E07A5F) 팔레트를
/// 세 벌(Dart·Swift·Kotlin)에 각각 하드코딩해 두고 있었다. 앱 색을 바꿔도
/// 위젯만 옛 색으로 남았고, 작은 글자 대비는 2.95~3.64:1이었다.
void main() {
  group('위젯 색은 앱 토큰에서 온다', () {
    test('바탕·본문·강조가 AppColors와 같은 값이다', () {
      expect(WidgetTheme.background, AppColors.pageBackground);
      expect(WidgetTheme.surface, AppColors.orbitSurface);
      expect(WidgetTheme.textPrimary, AppColors.textPrimary);
      expect(WidgetTheme.textMuted, AppColors.textMuted);
      expect(WidgetTheme.accent, AppColors.orbitPrimary);
      expect(WidgetTheme.ringTrack, AppColors.orbitHalo);
    });

    test('옛 팔레트가 다시 들어오지 않는다', () {
      const retired = <Color>[
        Color(0xFFFFF7ED),
        Color(0xFF5C4033),
        Color(0xFF8B7D72),
        Color(0xFFE07A5F),
        Color(0xFF9A8AAC),
      ];
      for (final color in retired) {
        expect(
          [
            WidgetTheme.background,
            WidgetTheme.surface,
            WidgetTheme.textPrimary,
            WidgetTheme.textMuted,
            WidgetTheme.accent,
            WidgetTheme.ringTrack,
          ],
          isNot(contains(color)),
        );
      }
    });
  });

  group('위젯 글자는 AA(4.5:1)를 만족한다', () {
    test('본문·보조 문구', () {
      expect(
        _contrast(WidgetTheme.textPrimary, WidgetTheme.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(WidgetTheme.textMuted, WidgetTheme.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('상태 배지 — 예전 테라코타는 2.95:1이었다', () {
      final ratio = _contrast(WidgetTheme.onAccent, WidgetTheme.accent);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: '배지 대비 ${ratio.toStringAsFixed(2)}:1',
      );
      expect(_contrast(Colors.white, const Color(0xFFE07A5F)), lessThan(4.5));
    });

    test('정보 텍스트는 13 미만으로 내려가지 않는다', () {
      // UI_STANDARDS 6. 배지·시각 라벨만 캡션(12)을 쓴다.
      expect(WidgetTheme.bodySize, greaterThanOrEqualTo(13));
      expect(WidgetTheme.titleSize, greaterThanOrEqualTo(13));
      expect(WidgetTheme.captionSize, greaterThanOrEqualTo(12));
    });
  });

  group('네이티브 두 벌이 같은 값을 미러링한다', () {
    test('Android widget_colors.xml', () {
      final xml =
          File('android/app/src/main/res/values/widget_colors.xml').readAsStringSync();
      _expectHex(xml, 'widget_background', WidgetTheme.background);
      _expectHex(xml, 'widget_surface', WidgetTheme.surface);
      _expectHex(xml, 'widget_border', WidgetTheme.border);
      _expectHex(xml, 'widget_text_primary', WidgetTheme.textPrimary);
      _expectHex(xml, 'widget_text_muted', WidgetTheme.textMuted);
      _expectHex(xml, 'widget_accent', WidgetTheme.accent);
      _expectHex(xml, 'widget_ring_track', WidgetTheme.ringTrack);
    });

    test('iOS WidgetTokens', () {
      final swift =
          File('ios/RoutineWidgetExtension/RoutineWidgetExtension.swift')
              .readAsStringSync();
      for (final color in <Color>[
        WidgetTheme.background,
        WidgetTheme.surface,
        WidgetTheme.border,
        WidgetTheme.textPrimary,
        WidgetTheme.textMuted,
        WidgetTheme.accent,
        WidgetTheme.ringTrack,
      ]) {
        expect(
          swift,
          contains('0x${_hex(color)}'),
          reason: '#${_hex(color)}가 Swift 토큰에 없다',
        );
      }
    });

    test('Kotlin 링 비트맵 토큰', () {
      final kotlin = File(
        'android/app/src/main/kotlin/com/dayround/app/RoutineWidgetRingBitmap.kt',
      ).readAsStringSync();
      for (final color in <Color>[
        WidgetTheme.surface,
        WidgetTheme.textPrimary,
        WidgetTheme.textMuted,
        WidgetTheme.accent,
        WidgetTheme.ringTrack,
      ]) {
        expect(kotlin, contains('#${_hex(color)}'));
      }
    });
  });
}

String _hex(Color color) => color
    .toARGB32()
    .toRadixString(16)
    .padLeft(8, '0')
    .substring(2)
    .toUpperCase();

void _expectHex(String xml, String name, Color color) {
  expect(
    xml,
    contains('name="$name">#${_hex(color)}<'),
    reason: '$name이 #${_hex(color)}가 아니다',
  );
}

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
