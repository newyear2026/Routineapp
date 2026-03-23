# 🐻 Routine Timer - Flutter 앱

귀엽고 감성적인 루틴 관리 모바일 앱

## 📱 프로젝트 소개

하루 24시간을 원형 시간표로 보여주고, 시간마다 알림과 캐릭터 반응으로 루틴 실행을 유도하는 감성 루틴 관리 앱입니다.

### 주요 특징

- 🎨 **파스텔톤 디자인** - 부드럽고 따뜻한 UI/UX
- ⏰ **원형 시간표** - 24시간을 직관적으로 시각화
- 🔔 **스마트 알림** - 루틴 시간마다 귀여운 알림
- 📊 **진행률 추적** - 오늘의 달성률과 통계 확인
- 💕 **캐릭터 피드백** - 격려 메시지로 동기 부여

## 🚀 시작하기

### 필수 요구사항

- Flutter SDK 3.0.0 이상
- Dart 3.0.0 이상
- iOS: Xcode 14 이상 (macOS에서만)
- Android: Android Studio / Android SDK

### 설치 방법

1. **Flutter 프로젝트 생성**

```bash
flutter create routine_timer
cd routine_timer
```

2. **파일 복사**

`flutter_app/` 폴더의 모든 파일을 프로젝트에 복사:
- `lib/` - 모든 Dart 소스 파일
- `pubspec.yaml` - 의존성 설정

3. **의존성 설치**

```bash
flutter pub get
```

4. **실행**

```bash
# iOS 시뮬레이터
flutter run -d iPhone

# Android 에뮬레이터
flutter run -d emulator

# 연결된 실제 기기
flutter run
```

## 📂 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── screens/                           # 모든 화면
│   ├── splash_screen.dart            # 스플래시 화면
│   ├── onboarding_screen.dart        # 온보딩 (3페이지)
│   ├── notification_permission_screen.dart  # 알림 권한
│   ├── initial_routine_setup_screen.dart    # 루틴 초기 설정
│   ├── home_screen.dart              # 메인 홈 (원형 시계)
│   ├── today_progress_screen.dart    # 오늘 진행률
│   └── settings_screen.dart          # 설정
├── widgets/                           # 재사용 위젯 (향후 추가)
│   └── routine_detail_sheet.dart
├── models/                            # 데이터 모델 (향후 추가)
└── utils/                             # 유틸리티 (향후 추가)
```

## 🎯 완성된 화면

### ✅ 구현 완료

1. **스플래시 화면**
   - 로고 애니메이션
   - 자동 온보딩 이동

2. **온보딩 화면**
   - 3페이지 스와이프
   - 페이지 인디케이터
   - Skip 기능

3. **알림 권한 요청**
   - 흔들리는 벨 애니메이션
   - 알림 예시 카드

4. **초기 루틴 설정**
   - 템플릿 선택/해제
   - 체크 애니메이션
   - 추천 뱃지

5. **메인 홈 화면**
   - 원형 시간표 (CustomPaint)
   - 실시간 시침
   - 루틴 세그먼트 표시
   - 캐릭터 & 말풍선
   - 진행률 바
   - 완료/나중에/스킵 버튼

6. **진행률 화면**
   - 원형 프로그레스 바
   - 상태별 루틴 목록
   - 캐릭터 피드백
   - 연속 달성 통계

7. **설정 화면**
   - 프로필 카드
   - 토글 스위치 (커스텀)
   - 섹션별 그룹화

## 🛠 주요 기술

- **상태 관리**: setState (기본)
- **라우팅**: go_router
- **애니메이션**: AnimationController, TweenAnimationBuilder
- **커스텀 페인팅**: CustomPainter (원형 시계)
- **그라데이션**: LinearGradient, RadialGradient

## 📦 사용된 패키지

```yaml
dependencies:
  flutter_animate: ^4.5.0      # 애니메이션
  go_router: ^13.0.0           # 라우팅
  provider: ^6.1.1             # 상태 관리
  shared_preferences: ^2.2.2   # 로컬 저장
  flutter_local_notifications: ^17.0.0  # 알림
  intl: ^0.19.0                # 날짜/시간 포맷
```

## 🔄 화면 네비게이션

```
/ (스플래시)
  ↓
/onboarding (온보딩)
  ↓
/notification-permission (알림 권한)
  ↓
/routine-setup (루틴 설정)
  ↓
/home (메인 홈) ←→ /progress (진행률)
              ←→ /settings (설정)
```

## 🎨 디자인 시스템

### 컬러 팔레트

- **Primary**: `#8B7B9E` (보라 그레이)
- **Secondary**: `#B8A4C9` (연보라)
- **Accent Pink**: `#FFB8C6`
- **Accent Blue**: `#D4E4FF`
- **Accent Orange**: `#FFDDC5`
- **Background**: 그라데이션 (FFF5F5 → FFF9E6 → F0F4FF)

### 타이포그래피

- **Title**: 22-26px, SemiBold
- **Body**: 14-16px, Medium
- **Caption**: 11-13px, Regular

## 🚧 다음 단계 (TODO)

- [ ] 루틴 상세 바텀시트
- [ ] 루틴 추가/수정 화면
- [ ] 데이터 모델 구현
- [ ] Provider를 이용한 상태 관리
- [ ] SharedPreferences로 로컬 저장
- [ ] 실제 알림 기능 구현
- [ ] Apple Watch 연동
- [ ] 테마 설정 (다크 모드)
- [ ] 캐릭터 커스터마이징

## 🔧 개발 팁

### Hot Reload

```bash
# 코드 수정 후 터미널에서
r  # Hot reload
R  # Hot restart
```

### 디버깅

```bash
# 로그 보기
flutter logs

# 성능 분석
flutter run --profile
```

### 빌드

```bash
# Android APK
flutter build apk --release

# iOS (macOS에서만)
flutter build ios --release
```

## 🐛 문제 해결

### 패키지 오류
```bash
flutter clean
flutter pub get
```

### iOS 빌드 오류
```bash
cd ios
pod install
cd ..
flutter run
```

### 시뮬레이터/에뮬레이터 목록
```bash
flutter devices
flutter emulators
```

## 📝 라이선스

이 프로젝트는 개인 포트폴리오 및 학습 목적으로 만들어졌습니다.

## 💬 문의

프로젝트 관련 문의사항이 있으시면 이슈를 등록해주세요.

---

Made with 💕 by Routine Timer Team
