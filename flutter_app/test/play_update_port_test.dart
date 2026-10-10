import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/play_update_port.dart';
import 'package:routine_timer/domain/update/app_update_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  const port = PlayUpdatePort();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Map<String, Object?> response(int availability, {int? version = 7}) => {
        'updateAvailability': availability,
        'immediateAllowed': false,
        'flexibleAllowed': false,
        'availableVersionCode': version,
        'installStatus': 0,
        'packageName': 'com.dayround.app',
        'clientVersionStalenessDays': 2,
        'updatePriority': 0,
      };

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('정상적으로 업데이트가 없다고 응답한 경우만 최신으로 판단한다', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => response(1));
    final result = await port.check();
    expect(result.succeeded, isTrue);
    expect(result.pending, isNull);
  });

  test('설치 가능 여부와 관계없이 새 버전 정보를 전달한다', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => response(2));
    final result = await port.check();
    expect(result.succeeded, isTrue);
    expect(
        result.pending, const PendingUpdate(versionCode: 7, stalenessDays: 2));
  });

  test('알 수 없는 상태나 잘못된 버전 정보는 확인 실패다', () async {
    for (final data in [
      response(0),
      response(3),
      response(2, version: null),
      response(2, version: 0),
      response(2, version: -1),
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => data);
      expect((await port.check()).succeeded, isFalse);
    }
  });

  test('플랫폼 통신 오류를 최신으로 오인하지 않는다', () async {
    messenger.setMockMethodCallHandler(channel,
        (_) async => throw PlatformException(code: 'ERROR_API_NOT_AVAILABLE'));
    expect((await port.check()).succeeded, isFalse);
  });

  testWidgets('응답이 없으면 15초 뒤 실패로 끝나며 늦은 응답을 무시한다', (tester) async {
    final reply = Completer<Map<String, Object?>>();
    messenger.setMockMethodCallHandler(channel, (_) => reply.future);
    UpdateCheckResult? result;
    final check = port.check().then((value) => result = value);
    await tester.pump(const Duration(seconds: 14));
    expect(result, isNull);
    await tester.pump(const Duration(seconds: 1));
    await check;
    expect(result!.succeeded, isFalse);
    reply.complete(response(2));
    await tester.pump();
    expect(result!.succeeded, isFalse);
  });
}
