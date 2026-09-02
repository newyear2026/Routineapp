import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/ads/ad_placement_caps.dart';
import 'package:routine_timer/domain/ads/ad_policy_context.dart';
import 'package:routine_timer/domain/ads/ad_slot.dart';
import 'package:routine_timer/domain/ads/ad_slot_decision.dart';
import 'package:routine_timer/domain/ads/ad_slot_policy.dart';

final _now = DateTime(2026, 9, 1, 14, 0);

/// 아무 상한에도 걸리지 않는 기본 상황. 각 테스트는 한 값만 비틀어 본다.
AdPolicyContext _context({
  DateTime? firstLaunchAt,
  Duration warmUp = AdPlacementCaps.warmUp,
  bool startedFromNotification = false,
  int nativeImpressionsThisSession = 0,
  Set<AdSlot> slotsShownThisSession = const <AdSlot>{},
  int rewardedShownToday = 0,
  int upcomingCount = 3,
  int todayRoutineCount = 7,
  bool isPro = false,
  bool platformSupported = true,
}) {
  return AdPolicyContext(
    now: _now,
    firstLaunchAt: firstLaunchAt ?? _now.subtract(const Duration(days: 10)),
    warmUp: warmUp,
    startedFromNotification: startedFromNotification,
    nativeImpressionsThisSession: nativeImpressionsThisSession,
    slotsShownThisSession: slotsShownThisSession,
    rewardedShownToday: rewardedShownToday,
    upcomingCount: upcomingCount,
    todayRoutineCount: todayRoutineCount,
    isPro: isPro,
    platformSupported: platformSupported,
  );
}

AdDenialReason? _reason(AdSlot slot, AdPolicyContext context) =>
    AdSlotPolicy.decide(slot, context).reason;

void main() {
  group('기본 허용', () {
    test('상한에 안 걸리면 홈 네이티브는 뜬다', () {
      expect(AdSlotPolicy.decide(AdSlot.homeUpcoming, _context()).isAllowed,
          isTrue);
    });

    test('보상형도 뜬다', () {
      expect(
        AdSlotPolicy.decide(AdSlot.settingsThemeReward, _context()).isAllowed,
        isTrue,
      );
    });
  });

  group('플랫폼 게이트', () {
    test('iOS처럼 App ID가 없는 플랫폼에서는 어떤 자리도 뜨지 않는다', () {
      // App ID 없이 SDK를 초기화하면 실행 즉시 죽는다. 자리를 막는 게
      // 아니라 광고 자체를 켜지 않는 것이므로 가장 먼저 걸린다.
      final context = _context(platformSupported: false);
      for (final slot in AdSlot.values) {
        expect(
          _reason(slot, context),
          AdDenialReason.platformNotSupported,
          reason: '$slot',
        );
      }
    });
  });

  group('Phase 게이트', () {
    test('진행 탭 슬롯은 아직 꺼져 있다', () {
      expect(
        _reason(AdSlot.progressBeforeUpcoming, _context()),
        AdDenialReason.slotNotEnabled,
      );
    });
  });

  group('워밍업', () {
    test('설치 48시간 안에는 뜨지 않는다', () {
      final context = _context(
        firstLaunchAt: _now.subtract(const Duration(hours: 47)),
      );
      expect(_reason(AdSlot.homeUpcoming, context), AdDenialReason.warmUp);
    });

    test('48시간이 지나면 뜬다', () {
      final context = _context(
        firstLaunchAt: _now.subtract(const Duration(hours: 49)),
      );
      expect(AdSlotPolicy.decide(AdSlot.homeUpcoming, context).isAllowed,
          isTrue);
    });

    test('워밍업 0이면 첫 실행에도 뜬다 — 비공개 테스트 빌드', () {
      // 48시간을 그대로 두면 테스터 상당수가 광고를 한 번도 못 본다.
      final context = _context(firstLaunchAt: _now, warmUp: Duration.zero);
      expect(AdSlotPolicy.decide(AdSlot.homeUpcoming, context).isAllowed,
          isTrue);
    });

    test('워밍업은 보상형에도 걸린다', () {
      final context = _context(
        firstLaunchAt: _now.subtract(const Duration(hours: 1)),
      );
      expect(
        _reason(AdSlot.settingsThemeReward, context),
        AdDenialReason.warmUp,
      );
    });
  });

  group('알림으로 들어온 세션', () {
    test('밀어 넣는 광고는 막는다', () {
      final context = _context(startedFromNotification: true);
      expect(
        _reason(AdSlot.homeUpcoming, context),
        AdDenialReason.notificationEntry,
      );
    });

    test('사용자가 직접 누르는 보상형은 막지 않는다', () {
      // 알림으로 들어왔더라도 설정에 들어가 잠긴 테마를 누른 것은
      // 본인 의사다. 여기까지 막으면 기능이 사라진 것처럼 보인다.
      final context = _context(startedFromNotification: true);
      expect(
        AdSlotPolicy.decide(AdSlot.settingsThemeReward, context).isAllowed,
        isTrue,
      );
    });
  });

  group('세션 상한', () {
    test('네이티브 2회를 채우면 더 안 뜬다', () {
      final context = _context(
        nativeImpressionsThisSession:
            AdPlacementCaps.nativeImpressionsPerSession,
      );
      expect(_reason(AdSlot.homeUpcoming, context), AdDenialReason.sessionCap);
    });

    test('네이티브 상한은 보상형을 막지 않는다', () {
      final context = _context(nativeImpressionsThisSession: 9);
      expect(
        AdSlotPolicy.decide(AdSlot.settingsThemeReward, context).isAllowed,
        isTrue,
      );
    });

    test('같은 자리를 한 세션에 두 번 띄우지 않는다', () {
      final context = _context(
        slotsShownThisSession: const {AdSlot.homeUpcoming},
      );
      expect(
        _reason(AdSlot.homeUpcoming, context),
        AdDenialReason.slotAlreadyShown,
      );
    });
  });

  group('보상형 하루 상한', () {
    test('하루 3회를 채우면 더 안 뜬다', () {
      final context = _context(
        rewardedShownToday: AdPlacementCaps.rewardedPerDay,
      );
      expect(
        _reason(AdSlot.settingsThemeReward, context),
        AdDenialReason.dailyRewardCap,
      );
    });

    test('2회까지는 뜬다', () {
      final context = _context(rewardedShownToday: 2);
      expect(
        AdSlotPolicy.decide(AdSlot.settingsThemeReward, context).isAllowed,
        isTrue,
      );
    });
  });

  group('자리별 조건', () {
    test('다음 일정이 비면 홈 슬롯은 안 뜬다', () {
      // 목록 대신 캡션 한 줄만 나오는 화면이라, 그 뒤에 광고를 붙이면
      // 광고가 그 섹션의 본문이 된다.
      final context = _context(upcomingCount: 0);
      expect(
        _reason(AdSlot.homeUpcoming, context),
        AdDenialReason.slotCondition,
      );
    });

    test('오늘 루틴이 4개 미만이면 진행 슬롯 조건에 걸린다', () {
      // Phase 2에 켜질 자리라 지금은 slotNotEnabled가 먼저 걸리지만,
      // 조건 자체는 정책에 들어 있어야 한다.
      final context = _context(todayRoutineCount: 3);
      expect(
        AdSlotPolicy.decide(AdSlot.progressBeforeUpcoming, context).isAllowed,
        isFalse,
      );
    });
  });

  group('Pro 구매자', () {
    test('네이티브는 사라진다', () {
      expect(
        _reason(AdSlot.homeUpcoming, _context(isPro: true)),
        AdDenialReason.proUser,
      );
    });

    test('보상형은 남는다 — 시즌 테마 체험용', () {
      expect(
        AdSlotPolicy.decide(
          AdSlot.settingsThemeReward,
          _context(isPro: true),
        ).isAllowed,
        isTrue,
      );
    });
  });
}
