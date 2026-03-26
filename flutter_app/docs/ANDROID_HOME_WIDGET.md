# Android — Medium App Widget

## 구성

- `RoutineMediumWidgetProvider` — `es.antonborri.home_widget.HomeWidgetProvider` 상속  
- `AndroidManifest.xml`에 `receiver` 등록  
- `res/xml/routine_medium_widget_info.xml` — `minWidth` / `minHeight` Medium 규격  
- `res/layout/widget_routine_medium.xml` — RemoteViews  
- `RoutineWidgetRingBitmap` — JSON → 동심원 도넛 비트맵  

## 데이터

Flutter `home_widget`이 `HomeWidgetPreferences`에 `routine_widget_payload` 키로 JSON 문자열을 저장한다.  
Provider의 `onUpdate`에서 `widgetData.getString("routine_widget_payload", …)` 로 읽는다.

## 갱신

`flutter` 측에서 `HomeWidget.updateWidget(qualifiedAndroidName: 'com.example.routine_timer.RoutineMediumWidgetProvider')` 호출 시 브로드캐스트로 `onUpdate`가 실행된다.

## 홈 화면에 추가

위젯 목록에서 앱 이름 → **하루 루틴 시간표** (Medium) 선택.
