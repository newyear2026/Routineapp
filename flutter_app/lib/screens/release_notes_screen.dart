import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/release/release_announcements.dart';
import '../data/seed/release_notes.dart';
import '../domain/utils/app_date_formats.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/release/release_announcement.dart';

/// 최근 버전들의 변경점. 카드가 아니라 화면인 이유는, 카드는 이번 릴리스만
/// 말하고 이 화면은 «그전엔 뭐가 바뀌었지»에 답하기 때문이다.
///
/// 여는 것만으로 읽은 것으로 본다 — 설정 행의 점은 여기서 지워진다.
class ReleaseNotesScreen extends StatefulWidget {
  const ReleaseNotesScreen({super.key});

  @override
  State<ReleaseNotesScreen> createState() => _ReleaseNotesScreenState();
}

class _ReleaseNotesScreenState extends State<ReleaseNotesScreen> {
  bool _marked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 한 번만. 이 화면이 다시 그려질 때마다 쓰기를 걸 이유가 없다.
    if (_marked) return;
    _marked = true;
    context.read<ReleaseAnnouncements>().markRead();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final announcements = context.watch<ReleaseAnnouncements>();
    final notes = announcements.notes;
    final running = announcements.version?.version;

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
                      l10n.releaseNotesTitle,
                      style: AppTextStyles.titleScreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final note in notes) ...[
              _ReleaseNoteCard(
                note: note,
                // 플랫폼이 버전을 알려 주지 않으면 어떤 카드도 현재로 찍지
                // 않는다. 가장 위를 찍어 두면 릴리스를 건너뛴 기기에서
                // 거짓이 된다.
                isCurrent: running != null && note.version == running,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Center(
              child: Text(
                l10n.releaseNotesRetentionHint(releaseNoteRetention),
                style: AppTextStyles.captionTight,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseNoteCard extends StatelessWidget {
  const _ReleaseNoteCard({required this.note, required this.isCurrent});

  final ReleaseNote note;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      variant: isCurrent ? AppCardVariant.elevated : AppCardVariant.standard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'v${note.version}',
                style: AppTextStyles.smallStrong.copyWith(
                  color: isCurrent
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                AppStatusBadge(
                  label: l10n.releaseNotesCurrentBadge,
                  tone: AppStatusBadgeTone.meta,
                  compact: true,
                ),
              ],
              const Spacer(),
              Text(
                AppDateFormats.monthDay(context, note.releasedOn),
                style: AppTextStyles.captionTight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.orbitBorder,
          ),
          const SizedBox(height: 12),
          ReleaseNoteLines(note: note, muted: !isCurrent),
        ],
      ),
    );
  }
}
