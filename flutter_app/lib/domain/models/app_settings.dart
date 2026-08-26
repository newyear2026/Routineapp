/// 앱 전역 설정 — 로컬 우선, 추후 서버 프로필과 동기화 시 동일 스키마로 매핑
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.pushEnabled = true,
    this.themeId,
    this.localeCode,
    this.onboardingCompleted = false,
    this.notificationPermissionAsked = false,
  });

  final bool soundEnabled;
  final bool pushEnabled;

  /// null이면 시스템/기본 테마
  final String? themeId;

  /// 앱에서 쓸 언어(`ko` / `en` / `es`).
  ///
  /// null이면 기기 언어를 따른다. 사용자가 설정에서 명시적으로 고른 경우에만
  /// 값이 들어간다 — 기기 언어를 그대로 복사해 저장하면, 나중에 기기 언어를
  /// 바꿔도 앱이 옛 언어에 묶인다.
  final String? localeCode;
  final bool onboardingCompleted;
  final bool notificationPermissionAsked;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? pushEnabled,
    String? themeId,
    String? localeCode,
    bool? clearLocaleCode,
    bool? onboardingCompleted,
    bool? notificationPermissionAsked,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      themeId: themeId ?? this.themeId,
      // '기기 설정 따르기'로 되돌리려면 null을 넣어야 하는데, `??` 패턴만으로는
      // null을 '값 없음'과 구분할 수 없다. 지우는 의도는 별도 플래그로 받는다.
      localeCode:
          (clearLocaleCode ?? false) ? null : (localeCode ?? this.localeCode),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationPermissionAsked:
          notificationPermissionAsked ?? this.notificationPermissionAsked,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'pushEnabled': pushEnabled,
        'themeId': themeId,
        'localeCode': localeCode,
        'onboardingCompleted': onboardingCompleted,
        'notificationPermissionAsked': notificationPermissionAsked,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      themeId: json['themeId'] as String?,
      localeCode: json['localeCode'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      notificationPermissionAsked:
          json['notificationPermissionAsked'] as bool? ?? false,
    );
  }
}
