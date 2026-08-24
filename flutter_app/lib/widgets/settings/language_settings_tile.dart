import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/routine_app_controller.dart';
import '../../domain/settings/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';

/// 언어 설정 행 — 현재 언어를 보여주고, 누르면 선택 시트를 연다.
///
/// 기본값은 '기기 설정 따르기'다. 여기서 고른 값만 저장되고, 고르지 않으면
/// `MaterialApp.locale`이 null로 남아 Flutter가 기기 언어로 해석한다.
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.watch<RoutineAppController>();

    return AppSettingsTile(
      icon: Icons.translate_rounded,
      label: l10n.settingsLanguage,
      description: l10n.settingsLanguageDesc,
      onTap: () => _openPicker(context, app),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageLabel(l10n, app.language),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.orbitPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    RoutineAppController app,
  ) async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguageSheet(current: app.language),
    );
    if (selected == null || selected == app.language) return;
    await app.updateLanguage(selected);
  }
}

/// 언어 이름은 ARB가 갖는다 — 열거형에 표시 문자열을 두면 번역이 두 곳으로 갈린다.
String languageLabel(AppLocalizations l10n, AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      return l10n.languageSystem;
    case AppLanguage.korean:
      return l10n.languageKorean;
    case AppLanguage.english:
      return l10n.languageEnglish;
    case AppLanguage.spanish:
      return l10n.languageSpanish;
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});

  final AppLanguage current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: appSurfaceDecoration(radius: 24, elevated: true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.languageSheetTitle, style: AppTextStyles.titleSection),
            const SizedBox(height: 12),
            for (final language in AppLanguage.values)
              _LanguageOption(
                label: languageLabel(l10n, language),
                // '기기 설정 따르기'만 무엇을 뜻하는지 설명이 필요하다.
                description: language == AppLanguage.system
                    ? l10n.languageSystemDesc
                    : null,
                selected: language == current,
                onTap: () => Navigator.of(context).pop(language),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = this.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.orbitPrimary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Semantics(
            selected: selected,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.orbitPrimary
                      : AppColors.orbitBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodyStrong.copyWith(
                            fontSize: 15,
                            color: selected
                                ? AppColors.orbitPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 3),
                          Text(description, style: AppTextStyles.caption),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.orbitPrimary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
