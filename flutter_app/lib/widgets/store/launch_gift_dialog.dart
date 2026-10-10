import 'package:flutter/material.dart';

import '../../data/store/character_pack_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../ds/pixel_decoration.dart';
import 'character_pack_preview.dart';

/// true면 바로 팩을 입히고, 닫으면 소유한 상태로 팩 목록에 남긴다.
Future<bool> showLaunchGiftDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF0B3D4A),
        child: SingleChildScrollView(
          child: LaunchGiftCard(
            onClose: () => Navigator.pop(dialogContext, false),
            onUse: () => Navigator.pop(dialogContext, true),
          ),
        ),
      ),
    ) ??
    false;

class LaunchGiftCard extends StatelessWidget {
  const LaunchGiftCard({super.key, required this.onClose, required this.onUse});

  final VoidCallback onClose;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Text('×',
                  style: TextStyle(color: Colors.white, fontSize: 26)),
            ),
          ),
          const CharacterPackPortrait(
            pack: CharacterPackCatalog.stargazerCat,
            size: 150,
          ),
          const SizedBox(height: 16),
          Text(l10n.launchGiftTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSection.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(l10n.launchGiftDescription,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: const Color(0xFFE1EEF0))),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelDecoration(asset: 'stargazer-telescope', size: 42),
              SizedBox(width: 24),
              PixelDecoration(asset: 'stargazer-meteor', size: 42),
              SizedBox(width: 24),
              PixelDecoration(asset: 'stargazer-celestial-globe', size: 42),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onUse,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFFF4C430),
              foregroundColor: const Color(0xFF123041),
              shape:
                  AppPixelStyle.shape(color: const Color(0xFF123041), width: 2),
              textStyle: AppTextStyles.button,
            ),
            child: Text(
              l10n.launchGiftUseAction,
              style: AppTextStyles.button.copyWith(
                color: const Color(0xFF123041),
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
