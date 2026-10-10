import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/release/release_announcements.dart';
import 'package:routine_timer/application/services/app_version_service.dart';
import 'package:routine_timer/data/local/release_notes_storage.dart';
import 'package:routine_timer/data/seed/release_notes.dart';
import 'package:routine_timer/widgets/release/release_announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';

/// 기기 장부를 메모리에 둔다 — 여러 «실행»을 한 장부 위에 이어 붙일 수 있다.
class _MemoryStore {
  _MemoryStore([this.record = ReleaseNotesStorage.empty]);

  ReleaseNotesRecord record;

  Future<ReleaseNotesRecord> load() async => record;

  Future<void> save(ReleaseNotesRecord next) async => record = next;
}

AppVersionLoader _running(String version, [String build = '2']) =>
    () async => AppVersion(version: version, buildNumber: build);

final _notes = [
  ReleaseNote(
    version: '1.1.0',
    releasedOn: DateTime(2026, 10, 2),
    lines: [(l10n) => l10n.releaseNote101Snooze],
  ),
  ReleaseNote(
    version: '1.0.1',
    releasedOn: DateTime(2026, 9, 22),
    lines: [(l10n) => l10n.releaseNote101PixelClouds],
  ),
];

void main() {
  ReleaseAnnouncements build({
    required _MemoryStore store,
    String version = '1.0.1',
    String build = '2',
    AppVersionLoader? versionLoader,
  }) =>
      ReleaseAnnouncements(
        recordLoader: store.load,
        recordSaver: store.save,
        versionLoader: versionLoader ?? _running(version, build),
        notes: _notes,
      );

  group('맨 처음 실행', () {
    test('바뀐 것이 없으므로 아무것도 알리지 않는다', () async {
      final announcements = build(store: _MemoryStore());
      await announcements.start();

      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isFalse);
    });

    test('출발점을 적어 두어 다음 릴리스가 변화가 되게 한다', () async {
      final store = _MemoryStore();
      await build(store: store).start();

      expect(store.record.announcedVersion, '1.0.1');
      expect(store.record.readVersion, '1.0.1');

      // 다음 릴리스를 깔았다.
      final next = build(store: store, version: '1.1.0');
      await next.start();
      expect(next.shouldAnnounce, isTrue);
    });
  });

  group('업데이트를 설치한 뒤', () {
    test('카드는 한 번 뜨고 멈춘다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();
      expect(announcements.shouldAnnounce, isTrue);

      await announcements.markAnnounced();
      expect(announcements.shouldAnnounce, isFalse);

      // 앱을 껐다 켠다.
      final next = build(store: store, version: '1.1.0');
      await next.start();
      expect(next.shouldAnnounce, isFalse);
    });

    test('같은 버전의 새 빌드는 새 릴리스가 아니다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.1.0', readVersion: '1.1.0'),
      );
      // 버전 이름은 같고 빌드 번호만 올랐다.
      final announcements = build(store: store, version: '1.1.0', build: '9');
      await announcements.start();

      expect(announcements.shouldAnnounce, isFalse);
    });

    test('노트 없이 나간 버전은 아무 말도 하지 않는다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.2.0');
      await announcements.start();

      expect(announcements.currentNote, isNull);
      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isFalse);
    });

    test('플랫폼이 빌드를 말하지 않으면 조용하다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(
        store: store,
        versionLoader: () async => null,
      );
      await announcements.start();

      expect(announcements.version, isNull);
      expect(announcements.shouldAnnounce, isFalse);
    });
  });

  group('설정 행의 표시', () {
    test('카드보다 오래 남고, 읽을 때만 지워진다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();

      await announcements.markAnnounced();
      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isTrue, reason: '닫은 것은 읽은 것이 아니다');

      await announcements.markRead();
      expect(announcements.hasUnreadNotes, isFalse);
    });

    test('읽는 것은 알린 것까지 덮는다 — 찾아간 사람에게는 카드가 필요 없다', () async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();

      // 카드를 보기 전에 설정에서 노트를 먼저 열었다.
      await announcements.markRead();

      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isFalse);
    });
  });

  group('기기 장부', () {
    test('실제 저장소를 거쳐도 유지된다', () async {
      SharedPreferences.setMockInitialValues({
        'device.notes.announced_version': '1.0.1',
        'device.notes.read_version': '1.0.1',
      });

      final first = ReleaseAnnouncements(
        versionLoader: _running('1.1.0'),
        notes: _notes,
      );
      await first.start();
      expect(first.shouldAnnounce, isTrue);
      await first.markAnnounced();

      final second = ReleaseAnnouncements(
        versionLoader: _running('1.1.0'),
        notes: _notes,
      );
      await second.start();

      expect(second.shouldAnnounce, isFalse, reason: '«알렸음»이 저장되지 않았다');
      expect(second.hasUnreadNotes, isTrue, reason: '«읽음»까지 덮였다');
    });
  });

  group('카드', () {
    testWidgets('변경점을 직접 보여 준다', (tester) async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();

      await tester.pumpWidget(localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showReleaseAnnouncement(
                  context,
                  announcements: announcements,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.releaseNotesTitle), findsOneWidget);
      expect(find.text(testL10n.releaseNote101Snooze), findsOneWidget);
      // 카드가 떴다는 것은 기록되지만, 읽은 것은 아니다.
      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isTrue);
    });

    testWidgets('«지난 변경점 보기»는 호출자에게 그 뜻을 돌려준다', (tester) async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();

      bool? wantsMore;
      await tester.pumpWidget(localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => wantsMore = await showReleaseAnnouncement(
                  context,
                  announcements: announcements,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.releaseAnnouncementMore));
      await tester.pumpAndSettle();
      expect(wantsMore, isTrue);
    });

    testWidgets('«확인했어요»는 그 뜻을 돌려주지 않는다', (tester) async {
      final store = _MemoryStore(
        (announcedVersion: '1.0.1', readVersion: '1.0.1'),
      );
      final announcements = build(store: store, version: '1.1.0');
      await announcements.start();

      bool? wantsMore;
      await tester.pumpWidget(localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => wantsMore = await showReleaseAnnouncement(
                  context,
                  announcements: announcements,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.releaseAnnouncementAction));
      await tester.pumpAndSettle();
      expect(wantsMore, isFalse);
    });
  });
}
