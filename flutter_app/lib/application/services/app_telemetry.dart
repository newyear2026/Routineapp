import 'package:flutter/widgets.dart';

typedef TelemetryEventSender = Future<void> Function(
    String name, Map<String, Object> parameters);
typedef TelemetryErrorSender = Future<void> Function(
    String errorType, StackTrace stack, String reason, bool fatal);

/// Only predefined events and screen names leave the app. Routine content,
/// identifiers, notification payloads and purchase receipts are never parameters.
class AppTelemetry {
  AppTelemetry(
      {TelemetryEventSender? sendEvent, TelemetryErrorSender? sendError})
      : _sendEvent = sendEvent,
        _sendError = sendError;

  // Remains a no-op on unsupported platforms, in tests and before initialization.
  static AppTelemetry instance = AppTelemetry();

  final TelemetryEventSender? _sendEvent;
  final TelemetryErrorSender? _sendError;

  static const _screens = <String, String>{
    '/': 'splash',
    '/onboarding': 'onboarding',
    '/notification-permission': 'notification_permission',
    '/routine-setup': 'routine_setup',
    '/home': 'home',
    '/notification-routine': 'notification_routine',
    '/progress': 'progress',
    '/settings': 'settings',
    '/routines': 'routines',
    '/release-notes': 'release_notes',
    '/our-apps': 'our_apps',
    '/routine-add': 'routine_editor',
    '/widget-medium-preview': 'widget_preview',
    '/character-packs': 'character_store',
    '/character-packs/:id': 'character_pack_detail',
  };

  Future<void> screenViewed(String? routeName) async {
    // GoRouter supplies the route template. Do not send raw locations/queries.
    final screen = _screens[routeName];
    if (screen == null) return;
    await _event('screen_view', {
      'screen_name': screen,
      'screen_class': screen,
    });
  }

  Future<void> routineSaved({required bool created}) =>
      _event(created ? 'routine_created' : 'routine_updated');

  Future<void> routineDeleted() => _event('routine_deleted');

  Future<void> routineAction(String status, {required bool fromNotification}) {
    if (!const {'completed', 'snoozed', 'skipped'}.contains(status)) {
      return Future.value();
    }
    return _event('routine_$status', {
      'action_source': fromNotification ? 'notification' : 'app',
    });
  }

  Future<void> routineActionUndone() => _event('routine_action_undone');

  Future<void> _event(String name,
      [Map<String, Object> parameters = const {}]) async {
    try {
      await _sendEvent?.call(name, parameters);
    } catch (error) {
      // Reporting failures must never change the result of a user's action.
      debugPrint('Telemetry event unavailable: ${error.runtimeType}');
    }
  }

  Future<void> reportError(Object error, StackTrace stack,
      {required String reason, bool fatal = false}) async {
    try {
      // FormatException / storage errors may contain serialized routine content.
      // Preserve the type and stack, but never upload the raw exception message.
      await _sendError?.call(
          error.runtimeType.toString(), stack, reason, fatal);
    } catch (reportingError) {
      debugPrint('Error reporting unavailable: ${reportingError.runtimeType}');
    }
  }
}

class TelemetryRouteObserver extends NavigatorObserver {
  void _record(Route<dynamic>? route) {
    AppTelemetry.instance.screenViewed(route?.settings.name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _record(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _record(newRoute);
}
