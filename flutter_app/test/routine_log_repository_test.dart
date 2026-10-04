import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_notification_platform/routine_notification_platform.dart';
import 'package:routine_timer/data/local/local_routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final snooze = RoutineLog(
    id: 'reading_2026-10-04',
    routineId: 'reading',
    dateYmd: '2026-10-04',
    status: RoutineLogStatus.snoozed,
    snoozedUntilMs: DateTime(2026, 10, 4, 9, 20).millisecondsSinceEpoch,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in <String, RoutineLogRepository Function()>{
    'local': () => LocalRoutineLogRepository.instance,
    'memory': () => MemoryLogRepository(),
  }.entries) {
    group('${entry.key} conditional snooze contract', () {
      late RoutineLogRepository repository;
      setUp(() {
        // Exercise the Dart storage implementation without the Android plugin.
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        repository = entry.value();
      });

      test('inserts and replaces an earlier snooze by routine and date',
          () async {
        expect(await repository.saveNotificationSnooze(snooze), isTrue);
        final later = snooze.copyWith(
          id: 'different-id',
          snoozedUntilMs: snooze.snoozedUntilMs! + 60000,
        );
        expect(await repository.saveNotificationSnooze(later), isTrue);
        final saved = await repository.loadLogsForDate(DateTime(2026, 10, 4));
        expect(saved.single.toJson(), later.toJson());
      });

      for (final status in [
        RoutineLogStatus.completed,
        RoutineLogStatus.skipped
      ]) {
        test('preserves $status even when the incoming id differs', () async {
          final terminal = snooze.copyWith(id: 'terminal', status: status);
          await repository.upsertLog(terminal);
          expect(await repository.saveNotificationSnooze(snooze), isFalse);
          expect((await repository.loadAllLogs()).single.toJson(),
              terminal.toJson());
        });
      }

      test('rejects duplicate or earlier snooze deliveries', () async {
        await repository.upsertLog(snooze);
        expect(await repository.saveNotificationSnooze(snooze), isFalse);
        expect(
          await repository.saveNotificationSnooze(
            snooze.copyWith(snoozedUntilMs: snooze.snoozedUntilMs! - 60000),
          ),
          isFalse,
        );
        expect(
            (await repository.loadAllLogs()).single.toJson(), snooze.toJson());
      });

      test('completion on another routine or date does not block this snooze',
          () async {
        final otherRoutine = snooze.copyWith(
          id: 'exercise',
          routineId: 'exercise',
          status: RoutineLogStatus.completed,
        );
        final otherDate = snooze.copyWith(
          id: 'yesterday',
          dateYmd: '2026-10-03',
          status: RoutineLogStatus.completed,
        );
        await repository.upsertLog(otherRoutine);
        await repository.upsertLog(otherDate);
        expect(await repository.saveNotificationSnooze(snooze), isTrue);
        expect(
          (await repository.loadAllLogs()).map((log) => log.toJson()),
          unorderedEquals(
              [otherRoutine.toJson(), otherDate.toJson(), snooze.toJson()]),
        );
      });
    });
  }

  for (final accepted in [true, false]) {
    test(
        'Android returns native conditional write result ($accepted) without fallback',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(RoutineNotificationPlatform.channel,
          (call) async {
        calls.add(call);
        return accepted;
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(
            RoutineNotificationPlatform.channel, null);
      });

      final RoutineLogRepository repository =
          LocalRoutineLogRepository.instance;
      expect(await repository.saveNotificationSnooze(snooze), accepted);
      expect(calls.single.method, 'mutateLogs');
      expect(calls.single.arguments['operation'], 'snooze');
      expect(
          jsonDecode(calls.single.arguments['log'] as String), snooze.toJson());
      // The native result is authoritative, including false; no Dart write follows.
      expect(await repository.loadAllLogs(), isEmpty);
    });
  }
}
