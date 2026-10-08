import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/routine_load_failure_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_pixel_style.dart';
import '../theme/app_text_styles.dart';
import '../widget_medium/home_medium_widget.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import '../widget_medium/home_medium_widget_view_model.dart';
import '../widgets/ds/ds.dart';
import '../widgets/ds/app_pixel_switch.dart';

/// 홈 화면 위젯이 지금 어떻게 보이는지 확인하는 화면.
class WidgetMediumPreviewScreen extends StatefulWidget {
  const WidgetMediumPreviewScreen({super.key});

  @override
  State<WidgetMediumPreviewScreen> createState() =>
      _WidgetMediumPreviewScreenState();
}

class _WidgetMediumPreviewScreenState extends State<WidgetMediumPreviewScreen> {
  bool _useSampleData = false;
  bool _sampleCompleted = false;
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AppScreenShell(
        child: Consumer<RoutineAppController>(
          builder: (context, app, _) {
            if (app.hasBlockingLoadError) {
              return const RoutineLoadFailureView();
            }
            if (!app.isLoaded) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.orbitPrimary,
                ),
              );
            }

            final HomeMediumWidgetViewModel vm = _useSampleData
                ? HomeMediumWidgetViewModel.dummy(l10n,
                    completed: _sampleCompleted)
                : HomeMediumWidgetSelector.fromSnapshot(
                    app.homeSnapshotFor(l10n), l10n);

            return ListView(
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
                          child: Text(l10n.widgetPreviewTitle,
                              style: AppTextStyles.titleScreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final style in HomeWidgetStyle.values) ...[
                  Text(
                      switch (style) {
                        HomeWidgetStyle.cards => l10n.widgetStyleCards,
                        HomeWidgetStyle.ring => l10n.widgetStyleRing,
                        HomeWidgetStyle.timeline => l10n.widgetStyleTimeline,
                      },
                      style: AppTextStyles.bodyStrong),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        shape: AppPixelStyle.shape()),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                            width: 340,
                            child: MediaQuery.withNoTextScaling(
                                child: HomeMediumWidget(
                                    viewModel: vm,
                                    style: style,
                                    pack: app.currentPack,
                                    onComplete: _completing
                                        ? null
                                        : () async {
                                            if (_useSampleData) {
                                              setState(() =>
                                                  _sampleCompleted = true);
                                              return;
                                            }
                                            setState(() => _completing = true);
                                            try {
                                              await app.completeCurrent();
                                            } catch (error) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(l10n
                                                            .homeActionSaveFailed)));
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                    () => _completing = false);
                                              }
                                            }
                                          })))),
                  ),
                  const SizedBox(height: 18),
                ],
                const SizedBox(height: 10),
                // 안내 문구는 패널 밖에 둔다. 패널 위에서는 대비가 2.5:1로 떨어진다.
                Text(
                  l10n.widgetPreviewNote,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.widgetPreviewSample,
                                style: AppTextStyles.bodyStrong),
                            const SizedBox(height: 2),
                            Text(l10n.widgetPreviewSampleNote,
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      AppPixelSwitch(
                        label: l10n.widgetPreviewSample,
                        value: _useSampleData,
                        onChanged: (value) => setState(() {
                          _useSampleData = value;
                          _sampleCompleted = false;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
