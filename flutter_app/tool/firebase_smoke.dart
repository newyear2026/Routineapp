// Separate entrypoint; never included in the production app's main.dart.
// flutter run -t tool/firebase_smoke.dart --dart-define=TELEMETRY_ENABLED=true
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routine_timer/application/services/app_telemetry.dart';
import 'package:routine_timer/application/services/firebase_telemetry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      !const bool.fromEnvironment('TELEMETRY_ENABLED')) {
    throw StateError('Use an Android test device with TELEMETRY_ENABLED=true.');
  }
  await initializeFirebaseTelemetry();
  await FirebaseAnalytics.instance.logEvent(name: 'loopet_telemetry_test');
  await AppTelemetry.instance.reportError(
      StateError('LOOPET test error'), StackTrace.current,
      reason: 'loopet_telemetry_test');
  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('LOOPET Firebase test sent'))),
  ));
  // Opt in only on a test device; restart afterwards to upload the fatal report.
  if (const bool.fromEnvironment('FIREBASE_TEST_CRASH')) {
    await Future<void>.delayed(const Duration(seconds: 3));
    FirebaseCrashlytics.instance.crash();
  }
}
