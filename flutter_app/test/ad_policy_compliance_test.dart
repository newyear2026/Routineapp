import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/ad_config.dart';
import 'package:routine_timer/domain/ads/ad_placement_caps.dart';

/// AdMob 정책과 «실수로 실제 광고를 내보내는 사고»를 소스 수준에서 막는다.
///
/// 이 테스트들이 지키는 건 로직이 아니라 **되돌릴 수 없는 실수**다.
/// 지인 테스터가 실제 광고를 누르면 무효 트래픽이 되고 계정이 정지된다.
void main() {
  group('실수 방지 기본값', () {
    test('테스트 광고가 기본값이다', () {
      // 깜빡했을 때 어느 쪽으로 틀리는지가 핵심이다.
      //   기본값이 실제 광고 → 깜빡 = 계정 정지. 되돌릴 수 없다.
      //   기본값이 테스트   → 깜빡 = 수익 0. 하루면 알아채고 고친다.
      // 프로덕션 빌드만 --dart-define=USE_TEST_ADS=false 를 넘긴다.
      expect(AdConfig.useTestAds, isTrue);
    });

    test('EEA 가장은 기본으로 꺼져 있다', () {
      expect(AdConfig.forceEeaForTesting, isFalse);
    });

    test('플래그를 안 넘기면 워밍업은 48시간이다', () {
      // int.fromEnvironment는 커널 컴파일 시점에 값이 박힌다. 기본값 경로가
      // 깨지면 «설치 직후 광고 0» 규칙이 통째로 사라지는데, 화면만 봐서는
      // 광고가 잘 뜨는 것처럼 보여 알아채기 어렵다.
      expect(AdConfig.warmUp, AdPlacementCaps.warmUp);
      expect(AdConfig.warmUp, const Duration(hours: 48));
    });
  });

  group('광고 단위 ID는 한 곳에만 있다', () {
    test('AdUnitIds 밖에서 광고 단위 ID를 쓰지 않는다', () {
      // 화면이나 위젯이 ID를 직접 들면 «테스트로 바꾸는 걸 깜빡한 곳»이
      // 반드시 하나 남는다. 그 하나면 사고가 난다.
      final pattern = RegExp(r'ca-app-pub-\d+/\d+');
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('services/ad_unit_ids.dart')) continue;
        if (pattern.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: '광고 단위 ID는 AdUnitIds에만 둔다: $offenders',
      );
    });

    test('앱 ID는 Dart 코드에 없다 — 매니페스트가 들고 있다', () {
      final pattern = RegExp(r'ca-app-pub-\d+~\d+');
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (pattern.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty, reason: '앱 ID를 코드에 복사하지 않는다: $offenders');
    });
  });

  group('AndroidManifest', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    test('AdMob 앱 ID가 선언돼 있다', () {
      // 이 meta-data가 없으면 SDK 초기화 때 앱이 실행 즉시 죽는다.
      expect(
        manifest.contains('com.google.android.gms.ads.APPLICATION_ID'),
        isTrue,
      );
      expect(RegExp(r'ca-app-pub-\d+~\d+').hasMatch(manifest), isTrue);
    });

    test('테스트용 샘플 앱 ID가 남아 있지 않다', () {
      // Google 샘플 앱 ID로 출시하면 광고가 채워지지 않는다.
      expect(manifest.contains('ca-app-pub-3940256099942544'), isFalse);
    });
  });

  group('개인정보처리방침', () {
    // 광고 SDK 와 방침이 어긋난 채 출시되면 정책 위반으로 앱이 정지된다.
    // 코드 리뷰로는 잘 안 잡힌다 — 문서는 코드 diff 에서 조용하기 때문이다.
    // 그래서 «매니페스트가 광고를 켰으면 방침도 켜져 있어야 한다»를 묶어 둔다.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final adsEnabled =
        manifest.contains('com.google.android.gms.ads.APPLICATION_ID');

    // 앱 문서와 GitHub Pages 로 나가는 공개 페이지. 둘이 갈라지면
    // 심사자가 보는 쪽만 틀리게 된다.
    const policies = [
      'docs/PRIVACY_POLICY.md',
      '../docs/privacy/index.html',
    ];

    test('광고를 켰으면 방침이 AdMob 을 밝힌다', () {
      if (!adsEnabled) return; // 광고를 뺐다면 이 테스트는 할 말이 없다
      for (final path in policies) {
        final text = File(path).readAsStringSync();
        expect(
          text.contains('AdMob'),
          isTrue,
          reason: '$path 가 광고 네트워크를 밝히지 않는다',
        );
        expect(
          text.toLowerCase().contains('advertising id') ||
              text.contains('광고 ID') ||
              text.contains('ID de publicidad'),
          isTrue,
          reason: '$path 가 광고 식별자 수집을 밝히지 않는다',
        );
      }
    });

    test('«외부 SDK 없음»·«인터넷 미사용» 문구가 남아 있지 않다', () {
      if (!adsEnabled) return;
      // 광고를 넣기 전 문장들이다. 하나라도 남아 있으면 방침이 거짓이 된다.
      const stale = {
        '앱은 인터넷 접근 권한을 사용하지 않습니다': '한국어 §4',
        'The App does not use internet access permission': '영어 §4',
        'La Aplicación no utiliza el permiso de acceso a internet': '스페인어 §4',
        '어떠한 광고 네트워크, 분석 도구, 외부 SDK와도': '한국어 §5',
        'does not exchange data with any advertising network': '영어 §5',
        'no intercambia datos con ninguna red publicitaria': '스페인어 §5',
        'does not request internet access': '공개 페이지 §4',
        'no third-party SDKs of any kind': '공개 페이지 §5',
        'Since no data leaves your device': '공개 페이지 §8',
      };
      for (final path in policies) {
        final text = File(path).readAsStringSync();
        for (final entry in stale.entries) {
          expect(
            text.contains(entry.key),
            isFalse,
            reason: '$path 에 광고 이전 문구가 남았다 (${entry.value}): '
                '"${entry.key}"',
          );
        }
      }
    });
  });

  group('광고 표시 방식', () {
    final adWidget =
        File('lib/widgets/ads/home_upcoming_ad_card.dart').readAsStringSync();

    test('커스텀 네이티브 레이아웃 대신 템플릿을 쓴다', () {
      // «Ad» 배지는 템플릿이 직접 그린다. 커스텀 레이아웃으로 가면
      // 배지를 우리가 그려야 하고, 빠뜨리면 정책 위반이다.
      expect(adWidget.contains('nativeTemplateStyle'), isTrue);
      expect(adWidget.contains('factoryId'), isFalse);
    });

    test('광고 높이를 고정하지 않는다', () {
      // 고정 높이는 소재에 따라 광고를 자른다. 잘린 광고는 정책 위반이다.
      expect(adWidget.contains('BoxConstraints'), isTrue);
    });

    test('띄울 수 없으면 자리를 차지하지 않는다', () {
      expect(adWidget.contains('SizedBox.shrink'), isTrue);
    });

    test('띄운 뒤에도 «다음 일정» 조건을 다시 본다', () {
      // 판정은 광고를 불러올 때 한 번뿐이다. build 가 조건을 다시 보지 않으면,
      // 사용자가 마지막 루틴을 끝낸 순간 캡션 한 줄 밑에 광고만 남는다 —
      // 광고가 그 섹션의 본문이 되는 상태이고, minUpcomingForHomeSlot 이
      // 막으려던 바로 그것이다.
      //
      // 실제로 확인하려면 광고가 떠 있어야 하는데 CI 에는 SDK 가 없다.
      // 그래서 소스 수준으로 묶어 되돌아가는 것만 막는다.
      expect(
        adWidget.contains('AdPlacementCaps.minUpcomingForHomeSlot'),
        isTrue,
        reason: '화면이 상한 숫자를 직접 들고 있으면 정책과 갈라진다',
      );

      final build = adWidget.substring(adWidget.indexOf('Widget build('));
      expect(
        build.contains('_hasEnoughUpcoming'),
        isTrue,
        reason: 'build() 가 «다음 일정» 조건을 다시 보지 않는다',
      );
    });
  });
}
