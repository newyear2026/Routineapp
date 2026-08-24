import 'package:flutter/material.dart';
import 'package:routine_timer/l10n/app_localizations.dart';

/// 테스트는 한국어 문구를 검증한다 — 지원 목록의 첫 항목(en)이 기본이 되므로
/// 로케일을 명시하지 않으면 영어로 렌더링된다.
const Locale testLocale = Locale('ko');

/// BuildContext 없이 문자열이 필요한 테스트용.
final AppLocalizations testL10n = lookupAppLocalizations(testLocale);

/// 위젯 테스트용 [MaterialApp] — 델리게이트를 빠뜨리면
/// `AppLocalizations.of(context)`가 그대로 터진다.
MaterialApp localizedApp({Widget? home, RouterConfig<Object>? routerConfig}) {
  if (routerConfig != null) {
    return MaterialApp.router(
      routerConfig: routerConfig,
      locale: testLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
  return MaterialApp(
    home: home,
    locale: testLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
