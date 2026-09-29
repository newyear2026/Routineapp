import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/app_version_service.dart';
import 'package:routine_timer/application/update/app_updates_controller.dart';
import 'package:routine_timer/data/local/app_update_storage.dart';
import 'package:routine_timer/domain/update/app_update_port.dart';
import 'package:routine_timer/widgets/update/update_banner.dart';
import 'package:routine_timer/widgets/update/update_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';

/// 테스트에서는 아예 닿을 수 없는 Play 자리.
class _FakePort implements AppUpdatePort {
  _FakePort({this.available, this.storeOpens = true});

  PendingUpdate? available;
  bool storeOpens;
  int checks = 0;
  int opens = 0;

  @override
  bool get canCheck => true;

  @override
  Future<PendingUpdate?> check() async {
    checks++;
    return available;
  }

  @override
  Future<bool> openStore() async {
    opens++;
    return storeOpens;
  }
}

/// 기기 장부를 메모리에 둔다. 정책만 보는 테스트가 저장 구현까지 끌고 올 이유가
/// 없고, 여러 «실행»을 한 장부 위에서 이어 붙일 수 있다.
class _MemoryStore {
  AppUpdateRecord record = AppUpdateStorage.empty;

  Future<AppUpdateRecord> load() async => record;

  Future<void> save(AppUpdateRecord next) async => record = next;
}

/// 테스트에서 빌드 이름을 말해 주지 않는 플랫폼 자리.
AppVersionLoader _installed(String buildNumber) =>
    () async => AppVersion(version: '1.0.1', buildNumber: buildNumber);

void main() {
  const v7 = PendingUpdate(versionCode: 7);
  const v8 = PendingUpdate(versionCode: 8);

  final monday = DateTime(2026, 9, 21, 9);
  final tuesday = DateTime(2026, 9, 22, 9);

  AppUpdates build({
    required _FakePort port,
    required _MemoryStore store,
    DateTime? now,
    String installedBuild = '2',
  }) =>
      AppUpdates(
        port: port,
        recordLoader: store.load,
        recordSaver: store.save,
        now: () => now ?? monday,
        versionLoader: _installed(installedBuild),
      );

  group('스토어에 묻는 때', () {
    test('하루에 한 번, 날이 바뀌기 전에는 다시 묻지 않는다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();
      final updates = build(port: port, store: store);

      await updates.refresh();
      await updates.refresh();
      await updates.refresh();

      expect(port.checks, 1);
    });

    test('하루 예산은 실행을 넘어 기억된다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      await build(port: port, store: store).refresh();
      expect(port.checks, 1);

      // 같은 장부를 물려받은 새 프로세스.
      await build(port: port, store: store).refresh();
      expect(port.checks, 1);

      // 날이 바뀌면 다시 묻는다.
      await build(port: port, store: store, now: tuesday).refresh();
      expect(port.checks, 2);
    });

    test('찾아 둔 안내는 그것을 찾은 실행보다 오래 산다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      await build(port: port, store: store).refresh();

      final next = build(port: port, store: store);
      await next.refresh();

      // 묻지 않았는데도 손에 들려 있다.
      expect(port.checks, 1);
      expect(next.pending, v7);
    });

    test('그러나 배너로 돌아오고, 다이얼로그로는 다시 오지 않는다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      final first = build(port: port, store: store);
      await first.refresh();
      expect(first.shouldPrompt, isTrue);

      final second = build(port: port, store: store);
      await second.refresh();
      expect(second.shouldPrompt, isFalse);
      expect(second.showBanner, isTrue);
    });

    test('기기가 이미 받은 안내는 버린다', () async {
      final port = _FakePort(available: const PendingUpdate(versionCode: 3));
      final store = _MemoryStore();

      await build(port: port, store: store, installedBuild: '2').refresh();

      // 설치가 끝나 이제 3번 빌드가 돌고 있다. 같은 날, 예산은 이미 썼다.
      final after = build(port: port, store: store, installedBuild: '3');
      await after.refresh();

      expect(after.pending, isNull);
      expect(after.showBanner, isFalse);
    });

    test('강제 확인은 예산을 무시한다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();
      final updates = build(port: port, store: store);

      await updates.refresh();
      await updates.refresh(force: true);

      expect(port.checks, 2);
    });

    test('기다리는 것이 없으면 아무것도 내놓지 않는다', () async {
      final port = _FakePort();
      final updates = build(port: port, store: _MemoryStore());

      await updates.refresh();

      expect(updates.pending, isNull);
      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isFalse);
    });

    test('Play에 닿지 못하는 포트는 그냥 조용하다', () async {
      final updates = AppUpdates(
        port: const UnavailableUpdatePort(),
        recordLoader: _MemoryStore().load,
        recordSaver: (_) async {},
        now: () => monday,
        versionLoader: _installed('2'),
      );

      await updates.refresh();

      expect(updates.pending, isNull);
      expect(updates.showBanner, isFalse);
      expect(updates.canCheck, isFalse);
    });
  });

  group('얼마나 고집스러운가', () {
    test('다이얼로그가 먼저이고, 배너가 이어받는다', () async {
      final updates =
          build(port: _FakePort(available: v7), store: _MemoryStore());
      await updates.refresh();

      expect(updates.shouldPrompt, isTrue);
      expect(updates.showBanner, isFalse);

      updates.markPromptShown();
      updates.markPromptClosed();

      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isTrue);
    });

    test('배너는 다이얼로그가 열리기를 기다리지 않고 닫히기를 기다린다', () async {
      final updates =
          build(port: _FakePort(available: v7), store: _MemoryStore());
      await updates.refresh();

      updates.markPromptShown();
      // 스크림이 아직 올라와 있다. 같은 소식이 두 벌 보이면 안 된다.
      expect(updates.showBanner, isFalse);

      updates.markPromptClosed();
      expect(updates.showBanner, isTrue);
    });

    test('배너를 닫는 것은 이번 실행까지다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      final first = build(port: port, store: store);
      await first.refresh();
      first.markPromptShown();
      first.markPromptClosed();
      first.hideBanner();
      expect(first.showBanner, isFalse);

      final second = build(port: port, store: store);
      await second.refresh();
      expect(second.showBanner, isTrue);
    });

    test('미룬 업데이트는 다시 끼어들지 않는다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      final first = build(port: port, store: store);
      await first.refresh();
      await first.dismiss();

      final second = build(port: port, store: store, now: tuesday);
      await second.refresh();

      expect(second.pending, v7);
      expect(second.shouldPrompt, isFalse);
      expect(second.showBanner, isTrue);
    });

    test('그러나 그 다음 업데이트는 끼어든다', () async {
      final port = _FakePort(available: v7);
      final store = _MemoryStore();

      final first = build(port: port, store: store);
      await first.refresh();
      await first.dismiss();

      port.available = v8;
      final second = build(port: port, store: store, now: tuesday);
      await second.refresh();

      expect(second.shouldPrompt, isTrue);
    });

    test('강제 확인은 앞서 누른 «나중에»를 되돌린다', () async {
      final port = _FakePort(available: v7);
      final updates = build(port: port, store: _MemoryStore());

      await updates.refresh();
      await updates.dismiss();
      expect(updates.shouldPrompt, isFalse);

      await updates.refresh(force: true);
      expect(updates.shouldPrompt, isTrue);
    });
  });

  group('다이얼로그', () {
    Future<AppUpdates> pumpPrompt(
      WidgetTester tester, {
      bool storeOpens = true,
    }) async {
      final updates = build(
        port: _FakePort(available: v7, storeOpens: storeOpens),
        store: _MemoryStore(),
      );
      await updates.refresh();

      await tester.pumpWidget(localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showUpdatePrompt(
                  context,
                  updates: updates,
                  currentVersion: '1.0.1',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return updates;
    }

    testWidgets('스토어를 권하고 «나중에»를 기억한다', (tester) async {
      final updates = await pumpPrompt(tester);

      expect(find.text(testL10n.updateAvailableTitle), findsOneWidget);
      expect(find.text(testL10n.updateCurrentVersion('1.0.1')), findsOneWidget);

      await tester.tap(find.text(testL10n.updateLater));
      await tester.pumpAndSettle();

      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isTrue);
    });

    testWidgets('«업데이트하기»에서 스토어로 넘긴다', (tester) async {
      final updates = await pumpPrompt(tester);

      await tester.tap(find.text(testL10n.updateAction));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.updateStoreFailed), findsNothing);
      // 스토어로 넘긴 것은 미룬 것이 아니다 — 배너는 남아 있어야 한다.
      expect(updates.showBanner, isTrue);
    });

    testWidgets('열 스토어가 없으면 그렇다고 말한다', (tester) async {
      await pumpPrompt(tester, storeOpens: false);

      await tester.tap(find.text(testL10n.updateAction));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.updateStoreFailed), findsOneWidget);
    });
  });

  group('배너', () {
    testWidgets('안내와 빠져나갈 길을 함께 지닌다', (tester) async {
      var updated = 0;
      var dismissed = 0;

      await tester.pumpWidget(localizedApp(
        home: Scaffold(
          body: UpdateBanner(
            onUpdate: () => updated++,
            onDismiss: () => dismissed++,
          ),
        ),
      ));

      expect(find.text(testL10n.updateBannerMessage), findsOneWidget);

      await tester.tap(find.text(testL10n.updateAction));
      expect(updated, 1);

      await tester.tap(find.byTooltip(testL10n.updateBannerDismiss));
      expect(dismissed, 1);
    });
  });

  group('기기 장부', () {
    test('실제 저장소를 거쳐도 같은 값이 돌아온다', () async {
      SharedPreferences.setMockInitialValues({});

      final port = _FakePort(available: v7);
      final first = AppUpdates(
        port: port,
        now: () => monday,
        versionLoader: _installed('2'),
      );
      await first.refresh();
      await first.dismiss();

      // 기본 생성자는 SharedPreferences를 쓴다. 새 프로세스가 같은 답을 받아야
      // 정책이 실제로 앱을 껐다 켠 뒤에도 유지된다.
      final second = AppUpdates(
        port: port,
        now: () => monday,
        versionLoader: _installed('2'),
      );
      await second.refresh();

      expect(port.checks, 1, reason: '예산이 저장되지 않았다');
      expect(second.pending, v7, reason: '안내가 저장되지 않았다');
      expect(second.shouldPrompt, isFalse, reason: '«나중에»가 저장되지 않았다');
    });
  });
}
