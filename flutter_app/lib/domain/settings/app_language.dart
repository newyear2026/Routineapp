import 'dart:ui' show Locale;

/// 앱이 지원하는 언어와 '기기 설정 따르기'.
///
/// 저장값은 [code]이고, `null`(= [AppLanguage.system])이면 기기 언어를 따른다.
/// 화면에 보일 이름은 여기 두지 않는다 — 번역은 ARB가 갖고, 이 열거형은
/// 저장·해석에만 쓰인다.
enum AppLanguage {
  system(null),
  korean('ko'),
  english('en'),
  spanish('es');

  const AppLanguage(this.code);

  /// `null`이면 기기 언어를 따른다.
  final String? code;

  Locale? get locale {
    final code = this.code;
    return code == null ? null : Locale(code);
  }

  /// 저장된 코드를 해석한다. 모르는 코드는 기기 설정으로 되돌린다 —
  /// 지원 목록에서 언어를 뺐을 때 앱이 빈 화면으로 뜨지 않게 한다.
  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.system;
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.system;
  }

  /// 기기 언어가 지원 목록에 없을 때 쓰는 언어.
  ///
  /// 한국어를 두면 전 세계 낯선 사용자가 한글 화면을 보게 되므로 영어로 둔다.
  /// `supportedLocales`의 첫 항목이 Flutter의 기본 폴백이기도 해서, 두 곳이
  /// 어긋나지 않도록 여기서 한 번만 정한다.
  static const AppLanguage fallback = AppLanguage.english;

  /// `MaterialApp.supportedLocales`에 넣을 목록. 첫 항목이 폴백이다.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ko'),
  ];
}
