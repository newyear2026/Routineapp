import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_text_styles.dart';
import '../ds/animated_cat.dart';
import '../ds/ds.dart';

/// Informational card for the bundled theme; it does not enable theme selection.
class CatThemeCard extends StatelessWidget {
  const CatThemeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(child: LayoutBuilder(builder: (context, box) {
      final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.catStarlightTheme, style: AppTextStyles.bodyStrong),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              AppStatusBadge(
                  label: l10n.themeIncluded, tone: AppStatusBadgeTone.neutral),
              AppStatusBadge(
                  label: l10n.themeInUse, tone: AppStatusBadgeTone.success),
            ]),
          ]);
      const cat = SizedBox(
          key: Key('settings-theme-cat'),
          width: 96,
          height: 104,
          child: AnimatedCat(pose: CatPose.idle));
      if (box.maxWidth < 260) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [cat, const SizedBox(height: 12), details]);
      }
      return Row(
          children: [cat, const SizedBox(width: 14), Expanded(child: details)]);
    }));
  }
}
