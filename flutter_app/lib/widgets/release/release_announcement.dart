import 'package:flutter/material.dart';

import '../../application/release/release_announcements.dart';
import '../../data/seed/release_notes.dart';
import '../../domain/utils/app_date_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/app_button.dart';
import '../ds/app_card.dart';
import '../ds/pixel_icon.dart';

/// 방금 설치한 업데이트가 무엇을 바꿨는지 한 번 말한다.
///
/// 아이콘·색이 업데이트 안내와 다른 것은 일부러다. 업데이트는 사용자에게
/// 무언가를 **요청**하므로 행동색인 [AppColors.orbitPrimary] 를 쓰고, 이쪽은
/// **알리기만** 하므로 [AppColors.orbitAccent] 를 쓴다. 같은 색이면 둘이 한
/// 기능처럼 읽힌다.
///
/// 돌려주는 값은 «지난 변경점 보기»를 눌렀는지다. 노트 화면으로 보내는 일은
/// 라우터를 아는 호출자가 한다.
Future<bool> showReleaseAnnouncement(
  BuildContext context, {
  required ReleaseAnnouncements announcements,
}) async {
  final note = announcements.currentNote;
  if (note == null) return false;

  // 카드가 열리기 전에 적는다. 열려 있는 동안 다시 그려지는 것이 두 번째
  // 사본을 요구할 수 없어야 한다 — 업데이트 다이얼로그와 같은 이유다.
  await announcements.markAnnounced();
  if (!context.mounted) return false;

  final wantsMore = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x99221C42),
    builder: (context) => _ReleaseAnnouncementDialog(
      note: note,
      version: announcements.version?.version ?? note.version,
    ),
  );
  return wantsMore ?? false;
}

class _ReleaseAnnouncementDialog extends StatelessWidget {
  const _ReleaseAnnouncementDialog({
    required this.note,
    required this.version,
  });

  final ReleaseNote note;
  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: appSurfaceDecoration(elevated: true),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(
                    Icons.auto_awesome_rounded,
                    size: 24,
                    color: AppColors.orbitAccent,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.releaseNotesTitle,
                          style: AppTextStyles.titleSection,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v$version · '
                          '${AppDateFormats.monthDay(context, note.releasedOn)}',
                          style: AppTextStyles.captionTight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.orbitBorder,
              ),
              const SizedBox(height: 14),
              ReleaseNoteLines(note: note),
              const SizedBox(height: 18),
              AppButton(
                label: l10n.releaseAnnouncementAction,
                height: 50,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              AppButton(
                label: l10n.releaseAnnouncementMore,
                variant: AppButtonVariant.ghost,
                height: 44,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 한 버전의 변경점 목록. 카드와 노트 화면이 같은 모양을 쓴다.
class ReleaseNoteLines extends StatelessWidget {
  const ReleaseNoteLines({super.key, required this.note, this.muted = false});

  final ReleaseNote note;

  /// 지난 버전 카드는 한 단계 눌러 둔다 — 현재 버전이 먼저 읽혀야 한다.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = muted ? AppColors.textMuted : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 인덱스로 센다. 마지막 줄을 함수 참조 비교로 찾으면 같은 키를 두 번 쓴
        // 노트에서 간격이 엉뚱한 줄에 붙는다.
        for (final (index, line) in note.lines.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == note.lines.length - 1 ? 0 : 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // 글머리표를 첫 줄 글자 가운데에 맞춘다.
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    color: muted
                        ? AppColors.textMuted
                        : AppColors.orbitPrimary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    line(l10n),
                    style: AppTextStyles.helper.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
