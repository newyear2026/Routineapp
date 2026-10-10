import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'app_telemetry.dart';

/// Android is the released platform. Other previews keep working without a
/// Firebase registration. Local builds opt in explicitly for console validation.
Future<void> initializeFirebaseTelemetry() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  const enabled =
      bool.fromEnvironment('TELEMETRY_ENABLED', defaultValue: kReleaseMode);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    debugPrint('Firebase initialization unavailable: ${error.runtimeType}');
    return;
  }

  final analytics = FirebaseAnalytics.instance;
  final crashlytics = FirebaseCrashlytics.instance;
  var analyticsReady = false;
  var crashlyticsReady = false;
  try {
    // Usage measurement only. AdMob continues to use its own existing UMP flow.
    await analytics.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await analytics.setAnalyticsCollectionEnabled(enabled);
    analyticsReady = enabled;
  } catch (error) {
    debugPrint('Analytics initialization unavailable: ${error.runtimeType}');
  }
  try {
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
    if (enabled) {
      await crashlytics.setCustomKey('app_product', 'loopet');
    }
    crashlyticsReady = enabled;
  } catch (error) {
    debugPrint('Crashlytics initialization unavailable: ${error.runtimeType}');
  }

  final telemetry = AppTelemetry(
    sendEvent: analyticsReady
        ? (name, parameters) =>
            analytics.logEvent(name: name, parameters: parameters)
        : null,
    sendError: crashlyticsReady
        ? (errorType, stack, reason, fatal) => crashlytics.recordError(
              errorType,
              stack,
              reason: reason,
              fatal: fatal,
              printDetails: false,
            )
        : null,
  );
  AppTelemetry.instance = telemetry;

  if (!crashlyticsReady) return;
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterHandler?.call(details);
    unawaited(telemetry.reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      reason: 'flutter_framework',
    ));
  };
  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(telemetry.reportError(error, stack,
        reason: 'unhandled_async', fatal: true));
    return previousPlatformHandler?.call(error, stack) ?? true;
  };
}
