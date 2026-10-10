import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/services/store_review_launcher.dart';
import '../data/seed/our_apps.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_pixel_style.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

/// [packageName]의 스토어 페이지를 연다. 아무것도 열지 못하면 false.
typedef ListingOpener = Future<bool> Function(
  String packageName, {
  String? referrer,
});

/// LOOPET을 만든 사람들의 다른 앱.
///
/// 설정의 행으로만 들어온다. 점도, 홈 카드도, 설치 보상도 없다 — 마지막은 Play
/// 정책이 아예 금한다. 여기 온 사람은 보려고 온 것이다.
class OurAppsScreen extends StatelessWidget {
  const OurAppsScreen({
    super.key,
    this.apps,
    this.openListing = openPlayListingOf,
  });

  /// 비워 두면 [ourApps]다. 테스트가 제 목록을 넘긴다.
  final List<OurApp>? apps;

  /// 테스트가 url_launcher 채널 없이 어느 페이지를 열었는지 볼 수 있게 주입한다.
  final ListingOpener openListing;

  Future<void> _open(BuildContext context, OurApp app) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (await openListing(app.packageName, referrer: ourAppsReferrer)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsReviewOpenFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AppScreenShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.settingsOurApps,
                      style: AppTextStyles.titleScreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.ourAppsIntro, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            for (final app in apps ?? ourApps) ...[
              _AppCard(app: app, onOpen: () => _open(context, app)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onOpen});

  final OurApp app;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // 다른 앱의 원래 아트워크라 LOOPET 스프라이트처럼 최근접 보간을
              // 걸지 않는다. 런처가 매끄럽게 줄이도록 그려진 그림이다.
              // 모서리는 카드와 같은 계단으로 깎고 테두리는 그 위에 그린다 —
              // 네모난 아이콘이 상자를 다 덮으니 뒤에 그리면 가려진다.
              ClipPath(
                clipper: const ShapeBorderClipper(
                  shape: AppPixelStyle.plainShape,
                ),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: ShapeDecoration(shape: AppPixelStyle.shape()),
                  child: Image.asset(
                    app.icon,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: AppTextStyles.titleSection),
                    const SizedBox(height: 2),
                    Text(app.kind(l10n), style: AppTextStyles.captionTight),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(app.blurb(l10n), style: AppTextStyles.body),
          const SizedBox(height: 14),
          // 주 버튼이 아니라 보조 버튼이다. 이 화면에 LOOPET이 꼭 바라는 행동은
          // 없고, 주 버튼이 나란히 서면 정반대를 말하게 된다.
          AppButton(
            label: l10n.ourAppsOpen,
            variant: AppButtonVariant.secondary,
            height: 48,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
