import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../theme/home_theme.dart';
import '../widget_medium/home_medium_widget.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import '../widget_medium/home_medium_widget_view_model.dart';

/// Medium 위젯 UI 미리보기 — 실제 홈 스냅샷 또는 디자인 시안 더미.
class WidgetMediumPreviewScreen extends StatefulWidget {
  const WidgetMediumPreviewScreen({super.key});

  @override
  State<WidgetMediumPreviewScreen> createState() =>
      _WidgetMediumPreviewScreenState();
}

class _WidgetMediumPreviewScreenState extends State<WidgetMediumPreviewScreen> {
  bool _useDesignDummy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: HomeTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Medium 위젯 미리보기',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: HomeTheme.textPrimary,
          ),
        ),
      ),
      body: Consumer<RoutineAppController>(
        builder: (context, app, _) {
          if (!app.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final HomeMediumWidgetViewModel vm = _useDesignDummy
              ? HomeMediumWidgetViewModel.dummy()
              : HomeMediumWidgetSelector.fromSnapshot(app.homeSnapshot);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '디자인 시안 더미',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Figma 예시 데이터로 표시'),
                value: _useDesignDummy,
                onChanged: (v) => setState(() => _useDesignDummy = v),
              ),
              const SizedBox(height: 12),
              HomeMediumWidget(viewModel: vm),
              const SizedBox(height: 24),
              Text(
                '실데이터 모드는 [HomeSnapshot]을 selector로 매핑합니다.\n'
                'iOS 홈 화면 위젯은 동일 ViewModel을 Swift로 전달해 그리면 됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: HomeTheme.textMuted.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
