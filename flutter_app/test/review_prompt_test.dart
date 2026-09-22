import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/review/review_prompt.dart';
import 'package:routine_timer/data/local/review_prompt_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final installedAt = DateTime(2026, 9, 1, 9, 0);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({ReviewPrompt prompt, List<DateTime> requests}) build({
    required DateTime now,
    bool available = true,
    DateTime? installTime,
    bool useInstallTime = true,
    Future<void> Function()? requester,
  }) {
    final requests = <DateTime>[];
    final prompt = ReviewPrompt(
      available: available,
      installTimeLoader: () async =>
          useInstallTime ? (installTime ?? installedAt) : null,
      requester: requester ??
          () async {
            requests.add(now);
          },
      now: () => now,
    );
    return (prompt: prompt, requests: requests);
  }

  test('설치 후 하루가 지나지 않았으면 묻지 않고, 기회도 쓰지 않는다', () async {
    final r = build(now: installedAt.add(const Duration(hours: 23)));

    await r.prompt.onRoutineCompleted();

    expect(r.requests, isEmpty);
    expect(await ReviewPromptStorage.hasRequested(), isFalse);
  });

  test('하루가 지난 뒤 첫 완료에 한 번 묻고 기록한다', () async {
    final r = build(now: installedAt.add(const Duration(days: 1)));

    await r.prompt.onRoutineCompleted();

    expect(r.requests, hasLength(1));
    expect(await ReviewPromptStorage.hasRequested(), isTrue);
  });

  test('한 번 물은 뒤에는 같은 실행에서도, 다음 실행에서도 다시 묻지 않는다', () async {
    final now = installedAt.add(const Duration(days: 3));
    final first = build(now: now);
    await first.prompt.onRoutineCompleted();
    await first.prompt.onRoutineCompleted();
    expect(first.requests, hasLength(1));

    final nextLaunch = build(now: now.add(const Duration(days: 30)));
    await nextLaunch.prompt.onRoutineCompleted();
    expect(nextLaunch.requests, isEmpty);
  });

  test('완료를 연달아 눌러도 한 번만 묻는다', () async {
    final r = build(now: installedAt.add(const Duration(days: 2)));

    await Future.wait([
      r.prompt.onRoutineCompleted(),
      r.prompt.onRoutineCompleted(),
    ]);

    expect(r.requests, hasLength(1));
  });

  test('리뷰를 남길 스토어가 없는 플랫폼에서는 묻지 않는다', () async {
    final r = build(
      now: installedAt.add(const Duration(days: 2)),
      available: false,
    );

    await r.prompt.onRoutineCompleted();

    expect(r.requests, isEmpty);
    expect(await ReviewPromptStorage.hasRequested(), isFalse);
  });

  test('설치 시각을 모르면 묻지 않는다', () async {
    final r = build(
      now: installedAt.add(const Duration(days: 2)),
      useInstallTime: false,
    );

    await r.prompt.onRoutineCompleted();

    expect(r.requests, isEmpty);
  });

  test('요청이 실패해도 앱은 멀쩡하고, 다시 묻지 않는다', () async {
    var calls = 0;
    final r = build(
      now: installedAt.add(const Duration(days: 2)),
      requester: () async {
        calls++;
        throw Exception('Play 서비스 없음');
      },
    );

    await r.prompt.onRoutineCompleted();
    await r.prompt.onRoutineCompleted();

    expect(calls, 1);
    expect(await ReviewPromptStorage.hasRequested(), isTrue);
  });
}
