import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widget_medium/home_medium_widget.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import '../widget_medium/home_medium_widget_view_model.dart';
import '../widgets/ds/ds.dart';

/// 홈 화면 위젯이 지금 어떻게 보이는지 확인하는 화면.
class WidgetMediumPreviewScreen extends StatefulWidget {
  const WidgetMediumPreviewScreen({super.key});

  @override
  State<WidgetMediumPreviewScreen> createState() =>
      _WidgetMediumPreviewScreenState();
}

class _WidgetMediumPreviewScreenState extends State<WidgetMediumPreviewScreen> {
  bool _useSampleData = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreenShell(
        child: Consumer<RoutineAppController>(
          builder: (context, app, _) {
            if (!app.isLoaded) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.orbitPrimary,
                ),
              );
            }

            final HomeMediumWidgetViewModel vm = _useSampleData
                ? HomeMediumWidgetViewModel.dummy()
                : HomeMediumWidgetSelector.fromSnapshot(app.homeSnapshot);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '뒤로',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textPrimary,
                      ),
                      const Text('위젯 미리보기',
                          style: AppTextStyles.titleScreen),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 위젯 바탕은 앱 페이지 배경과 같은 색이라 이 화면에 그대로
                // 얹으면 경계가 사라진다. orbitBorder로 테두리를 둘러도
                // 배경 대비 1.22:1이라 보이지 않는다.
                // 홈 화면 배경 역할의 패널을 깔아 위젯 면적을 드러낸다.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: HomeMediumWidget(viewModel: vm),
                ),
                const SizedBox(height: 10),
                // 안내 문구는 패널 밖에 둔다. 패널 위에서는 대비가 2.5:1로 떨어진다.
                const Text(
                  '회색 면은 홈 화면 배경을 대신한 자리예요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('예시 데이터로 보기',
                                style: AppTextStyles.bodyStrong),
                            SizedBox(height: 2),
                            Text('오늘 루틴이 없어도 위젯 모습을 확인할 수 있어요.',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _useSampleData,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.orbitPrimary,
                        onChanged: (value) =>
                            setState(() => _useSampleData = value),
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
