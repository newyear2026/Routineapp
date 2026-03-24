# Routine Timer (Flutter)

귀엽고 감성적인 **하루 루틴 시간표** 모바일 앱입니다.  
Figma 디자인([Cute Emotional Routine App UI](https://www.figma.com/design/7u3ixFSgljZPwdJwxdYuYp/Cute-Emotional-Routine-App-UI))을 기준으로 Flutter로 구현합니다.

## 요구 사항

- Flutter SDK 3.x
- Dart 3.x

## 실행

```bash
cd flutter_app
flutter pub get
flutter run
```

기기/에뮬레이터 목록: `flutter devices`  
웹(Chrome): `flutter run -d chrome`  
Windows 데스크톱: `flutter run -d windows`

## 프로젝트 구조

- `flutter_app/lib/` — 앱 소스 (`main.dart`, `screens/`, `widgets/`, `theme/`, `data/`, `models/`)
- `flutter_app/pubspec.yaml` — 의존성

이 저장소의 **단일 앱은 Flutter**입니다. (이전 웹/React 번들은 제거되었습니다.)

루트에 예전 `node_modules` 폴더가 남아 있으면(파일 잠금 등으로 삭제 실패 시) IDE를 닫은 뒤 폴더를 수동으로 지우거나, 사용하지 않아도 빌드에는 영향 없습니다.

## 라우트

| 경로 | 화면 |
|------|------|
| `/` | 스플래시 |
| `/onboarding` | 온보딩 |
| `/notification-permission` | 알림 권한 |
| `/routine-setup` | 초기 루틴 설정 |
| `/home` | 홈 |
| `/progress` | 오늘 진행 |
| `/settings` | 설정 |

## 문서

- `flutter_app/README.md` — 상세 안내
