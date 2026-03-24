/// 앱 전역 설정 — 로컬 우선, 추후 서버 프로필과 동기화 시 동일 스키마로 매핑
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.pushEnabled = true,
    this.themeId,
    this.onboardingCompleted = false,
    this.notificationPermissionAsked = false,
  });

  final bool soundEnabled;
  final bool pushEnabled;

  /// null이면 시스템/기본 테마
  final String? themeId;
  final bool onboardingCompleted;
  final bool notificationPermissionAsked;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? pushEnabled,
    String? themeId,
    bool? onboardingCompleted,
    bool? notificationPermissionAsked,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      themeId: themeId ?? this.themeId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationPermissionAsked:
          notificationPermissionAsked ?? this.notificationPermissionAsked,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'pushEnabled': pushEnabled,
        'themeId': themeId,
        'onboardingCompleted': onboardingCompleted,
        'notificationPermissionAsked': notificationPermissionAsked,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      themeId: json['themeId'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      notificationPermissionAsked:
          json['notificationPermissionAsked'] as bool? ?? false,
    );
  }
}
