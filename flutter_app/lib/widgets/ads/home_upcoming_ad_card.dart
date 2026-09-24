import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../application/services/ad_bootstrap.dart';
import '../../application/services/ad_config.dart';
import '../../application/services/ad_policy_service.dart';
import '../../application/services/ad_unit_ids.dart';
import '../../domain/ads/ad_placement_caps.dart';
import '../../domain/ads/ad_slot.dart';
import '../../theme/app_colors.dart';
import '../ds/app_card.dart';

/// Slot A — 홈 «다음 일정» 섹션 맨 끝에 앉는 네이티브 광고.
///
/// 띄울 수 없는 상황이면 **높이 0으로 사라진다.** 자리표시자나 «광고
/// 로딩 중» 같은 표시를 두지 않는다. 광고가 안 나오는 날 그 자리가
/// 비어 보이면 사용자는 앱이 고장 났다고 읽는다.
///
/// 판정은 하지 않는다. [AdPolicyService]에 묻고 결과만 따른다 —
/// 상한과 조건이 화면으로 새면 정책을 바꿀 수 없게 된다.
class HomeUpcomingAdCard extends StatefulWidget {
  const HomeUpcomingAdCard({super.key, required this.upcomingCount});

  /// «다음 일정»에 남은 개수. 0이면 정책이 알아서 막는다.
  final int upcomingCount;

  @override
  State<HomeUpcomingAdCard> createState() => _HomeUpcomingAdCardState();
}

class _HomeUpcomingAdCardState extends State<HomeUpcomingAdCard> {
  /// 광고를 자르지 않기 위한 높이 범위.
  ///
  /// 고정 높이를 주면 소재에 따라 아래가 잘리는데, **잘린 광고는 AdMob
  /// 정책 위반**이다(광고의 일부를 가리는 배치). 그래서 범위로 준다.
  ///
  /// 상한은 실기기에서 확인하고 좁힌 값이다. small 템플릿은 소재와 무관하게
  /// 거의 같은 높이로 그려져서, 처음 잡았던 200 은 카드 절반이 흰 여백으로
  /// 남았다. 아래 조건에서 «Ad» 배지·별점·CTA 가 모두 온전히 보이는 것을
  /// 확인했다.
  ///
  ///   소재     아이콘형(Google Ads) · 이미지형(Flood-It)
  ///   글꼴     기본 · 1.3 · 1.5 배율
  ///
  /// 더 줄이려면 같은 조건을 다시 확인해야 한다. 여백이 남는 쪽이 잘리는
  /// 쪽보다 언제나 안전하다.
  static const double _minHeight = 90;
  static const double _maxHeight = 120;

  /// 광고를 카드 안쪽으로 들여놓는 정도.
  ///
  /// 카드 모서리는 [AppPixelStyle] 의 계단으로 9px 깎인다. 잘려 나가는 영역은
  /// 모서리에서 x + y < 9 인 삼각형이므로, (8, 8) 지점은 그 바깥 — 카드 면
  /// **안쪽**이다. 그래서 8이면 광고의 네모난 모서리가 카드를 비어져 나오지
  /// 않는다. 계단 크기를 키우면 이 값도 같이 봐야 한다.
  static const double _inset = 8;

  NativeAd? _ad;
  bool _loaded = false;

  /// 이미 [NativeAd] 를 만들었는가. 한 State 에서 두 번 요청하지 않는다.
  bool _requested = false;

  /// 판정이 도는 중인가. 판정은 비동기라 두 번 겹쳐 들어올 수 있다.
  bool _busy = false;

  /// 광고를 얹어도 될 만큼 «다음 일정»이 남아 있는가.
  ///
  /// 숫자는 [AdPlacementCaps] 하나가 들고 있다. 여기서 다시 쓰면 정책과
  /// 화면이 서로 다른 기준으로 갈라진다.
  bool get _hasEnoughUpcoming =>
      widget.upcomingCount >= AdPlacementCaps.minUpcomingForHomeSlot;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant HomeUpcomingAdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 마운트 시점에 «다음 일정»이 비어 있으면 정책이 slotCondition 으로 막는다.
    // initState 는 다시 돌지 않으므로, 그 뒤 사용자가 루틴을 추가해 조건이
    // 채워져도 이 자리는 세션 내내 죽어 있게 된다.
    //
    // 조건이 «채워지는 그 순간»에만 다시 묻는다. 매 rebuild 마다 물으면
    // 상한을 계속 두드리게 되고, 홈은 시계가 갈 때마다 다시 그려진다.
    final wasEnough =
        oldWidget.upcomingCount >= AdPlacementCaps.minUpcomingForHomeSlot;
    if (!wasEnough && _hasEnoughUpcoming) _maybeLoad();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _maybeLoad() async {
    // [didUpdateWidget] 이 다시 부를 수 있다. 이미 요청했거나 판정이 도는
    // 중이면 그냥 돌아간다 — 겹쳐 들어오면 광고 두 개가 뜬다.
    if (_requested || _busy) return;
    _busy = true;
    try {
      await _load();
    } finally {
      _busy = false;
    }
  }

  Future<void> _load() async {
    // 플래그만 보고 넘어가면 초기화가 도는 중에 광고를 요청하게 된다.
    // 홈은 스플래시 직후에 뜨므로 실제로 이 경합에 걸린다.
    await AdBootstrap.instance.ensureInitialized();
    if (!AdBootstrap.instance.isReady) {
      debugPrint('[ads] Slot A 건너뜀: SDK가 준비되지 않았다');
      return;
    }
    if (!mounted) return;

    final decision = await AdPolicyService.instance.decide(
      AdSlot.homeUpcoming,
      upcomingCount: widget.upcomingCount,
    );
    // 광고가 안 뜨는 건 대부분 버그가 아니라 상한이다. 이유를 남기지 않으면
    // 그 둘을 가르는 데 매번 시간이 든다.
    debugPrint(
      '[ads] Slot A 판정: $decision (워밍업 ${AdConfig.warmUp}, '
      '테스트광고=${AdConfig.useTestAds}, 단위=${AdUnitIds.homeUpcomingNative})',
    );
    if (!decision.isAllowed || !mounted) return;

    final ad = NativeAd(
      adUnitId: AdUnitIds.homeUpcomingNative,
      request: const AdRequest(),
      nativeTemplateStyle: _templateStyle(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          // 로드는 «그릴 수 있게 됐다»는 뜻일 뿐이다. 여기서 상한을 세면
          // 안 된다 — 아래 build 는 «다음 일정»이 비면 로드된 광고도
          // SizedBox.shrink 로 접는다. 그 경로에서는 사용자가 아무것도
          // 못 본 채 세션 상한만 깎인다.
          setState(() => _loaded = true);
        },
        // 상한의 단위는 «사용자가 본 광고»다. AdMob 이 자기 기준으로
        // 노출을 인정한 이 시점에만 센다. 로드 시점에 세면 우리 카운트와
        // AdMob 리포트가 갈라져, 나중에 숫자가 안 맞는 이유를 못 찾는다.
        onAdImpression: (_) {
          AdPolicyService.instance.recordShown(AdSlot.homeUpcoming);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[ads] Slot A 로드 실패: ${error.code} ${error.message}');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );

    _requested = true;
    _ad = ad;
    await ad.load();
  }

  /// 광고를 앱 카드처럼 보이게 맞춘다.
  ///
  /// 네이티브를 고른 이유가 여기 있다. 배너는 색을 못 바꾸지만 네이티브는
  /// «다음 일정» 카드와 같은 배경([AppColors.orbitSurface])을 쓸 수 있다.
  /// 모서리는 아래 [cornerRadius] 주석대로 색이 대신 처리한다.
  ///
  /// 다만 **콘텐츠로 위장하지는 않는다.** 광고임을 알리는 «Ad» 배지는
  /// 이 템플릿이 직접 그리며, 그래서 커스텀 레이아웃을 쓰지 않는다.
  /// 배지를 우리가 그리기 시작하면 빠뜨릴 수 있고, 빠뜨리면 정책 위반이다.
  NativeTemplateStyle _templateStyle() {
    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: AppColors.orbitSurface,
      // 이 값은 사실상 보이지 않는다. 광고 면과 뒤에 깔린 카드가 같은 흰색
      // 이라 템플릿의 모서리가 카드 면에 녹아든다 — 예전 18도 그랬다.
      //
      // 그래도 0 으로 둔다. 언젠가 광고 면 색이 카드와 달라지면 그때는
      // 모서리가 드러나는데, 이 앱의 면은 전부 각져 있다.
      cornerRadius: 0,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textPrimary,
        size: 14,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textMuted,
        size: 12,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textMuted,
        size: 11,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: AppColors.orbitPrimary,
        size: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    // 판정은 광고를 «불러올 때» 한 번 한다. 하지만 그 뒤 사용자가 마지막
    // 루틴을 끝내면 목록이 비고, 그러면 캡션 한 줄 밑에 광고만 남아 광고가
    // 그 섹션의 본문이 된다 — [AdPlacementCaps.minUpcomingForHomeSlot] 이
    // 막으려던 바로 그 상태다. 그래서 이 조건만은 그릴 때마다 다시 본다.
    if (!_hasEnoughUpcoming || !_loaded || ad == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      // 위아래로 넉넉히 띄운다. 위로는 «더 보기» 링크, 아래로는 하단
      // 네비게이션이 있는데, 둘 다 사용자가 습관적으로 누르는 자리다.
      // 광고를 그 옆에 붙이면 오탭이 나고, 오탭 유발 배치는 AdMob 정책
      // 위반이다. 아래 24 + 화면 하단 여백 24 = 네비게이션과 48dp.
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      // 광고는 안드로이드 네이티브 뷰라 ClipRRect로 모서리를 깎을 수 없다.
      // 대신 «다음 일정»과 같은 카드를 뒤에 깔고 광고를 [_inset] 만큼
      // 들여놓는다. 두 면이 같은 흰색이라 광고의 모서리가 카드 면에
      // 녹아들어, 카드의 계단식 모서리만 보인다.
      //
      // 광고를 가리는 게 아니라 뒤에 배경을 깔 뿐이라 정책과 무관하다.
      child: Container(
        padding: const EdgeInsets.all(_inset),
        decoration: appSurfaceDecoration(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minHeight,
            maxHeight: _maxHeight,
          ),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
