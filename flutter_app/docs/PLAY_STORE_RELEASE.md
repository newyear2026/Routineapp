# Google Play 출시 가이드

`com.dayround.app` 기준. Play Console에 앱을 만든 뒤에는 패키지 이름을 바꿀 수 없다.

---

## 0. 현재 상태

| 항목 | 값 |
|------|-----|
| 패키지 이름 | `com.dayround.app` (Android `applicationId`, iOS Bundle ID 동일) |
| App Group (iOS) | `group.com.dayround.app` |
| 앱 이름 | `LOOPET` (en·ko·es 공통) |
| `targetSdk` | 36 (Flutter 3.41 기본) — 2026-08-31 요건 충족 |
| `minSdk` | 24 |
| 버전 | `pubspec.yaml`의 `version: 1.0.0+1` → versionName 1.0.0 / versionCode 1 |
| 서명 | `android/key.properties` 있으면 업로드 키, 없으면 debug 키 |

---

## 1. 업로드 키스토어 만들기 (최초 1회)

**이 키를 잃어버리면 같은 앱으로 업데이트를 올릴 수 없다.** 저장소 밖에 두고 따로 백업한다.

```bash
# macOS에 별도 JDK가 없으면 Android Studio 번들 JDK를 쓴다.
KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"

mkdir -p ~/keys
"$KEYTOOL" -genkeypair -v \
  -keystore ~/keys/dayround-upload.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

비밀번호를 물어보면 직접 정한다. 그다음 템플릿을 복사해 값을 채운다.

```bash
cp android/key.properties.example android/key.properties
chmod 600 android/key.properties
```

```properties
storeFile=/Users/<사용자명>/keys/dayround-upload.jks
storePassword=<위에서 정한 비밀번호>
keyAlias=upload
keyPassword=<위에서 정한 비밀번호>
```

`key.properties`와 `*.jks`는 `android/.gitignore`에 이미 걸려 있다. 절대 커밋하지 않는다.

Play 앱 서명(신규 앱 기본값)에 가입하면 실제 배포 서명은 Google이 맡고, 위 키는 "업로드 키" 역할만 한다. 업로드 키는 분실 시 재설정을 요청할 수 있지만 백업이 우선이다.

---

## 2. AAB 빌드

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

결과: `build/app/outputs/bundle/release/app-release.aab`

### 광고 빌드 플래그

광고 단위는 빌드 플래그로 갈린다(`lib/application/services/ad_config.dart`).
플래그 없이 빌드하면 **Google 테스트 광고**가 나온다. 깜빡해도 안전한 쪽으로
틀리게 하려고 일부러 기본값을 테스트로 뒀다.

| 트랙 | 명령 |
|------|------|
| 비공개 테스트 | `flutter build appbundle --release --dart-define=AD_WARMUP_HOURS=0` |
| 프로덕션 | `flutter build appbundle --release --dart-define=USE_TEST_ADS=false` |

- 비공개 테스트는 테스트 광고를 쓴다. 지인 테스터가 실제 광고를 누르면 무효
  트래픽이 되어 AdMob 계정이 정지될 수 있다.
- `AD_WARMUP_HOURS=0`은 설치 직후 광고 유예를 끈다. 켜 두면 테스터가 광고를
  한 번도 못 본 채 14일이 끝날 수 있다.
- 프로덕션 빌드에만 `USE_TEST_ADS=false`를 넘긴다. 빠뜨리면 수익이 0이 된다.

테스트 광고를 쓰더라도 광고 SDK와 광고 ID는 그대로 들어가므로, 6장의 Play
선언은 트랙과 관계없이 «광고 포함»이다.

빌드 로그에 서명 관련 경고가 없는지, `key.properties`가 실제로 읽혔는지 확인한다. 확인 방법은 debug 키로 서명된 AAB를 올리면 Play가 거부하므로, 업로드 단계에서 바로 드러난다.

버전을 올릴 때는 `pubspec.yaml`의 `version: 1.0.0+1`에서 `+` 뒤 숫자(versionCode)를 반드시 증가시킨다. 같은 versionCode는 재업로드가 안 된다.

---

## 3. 아이콘 다시 만들기

아이콘 원본은 손으로 만들지 않는다. `lib/widgets/brand_mark.dart`에서 렌더링한다.

```bash
flutter test tool/generate_app_icon.dart   # assets/icon/*.png 생성
dart run flutter_launcher_icons             # 플랫폼별 해상도 생성
```

브랜드 마크를 수정하면 이 두 줄을 다시 돌려야 스플래시와 런처 아이콘이 어긋나지 않는다.

---

## 4. Play Console 앱 만들기

| 항목 | 값 |
|------|-----|
| 앱 이름 | `LOOPET` |
| 패키지 이름 | `com.dayround.app` |
| 기본 언어 | 영어(미국) |
| 앱 또는 게임 | 앱 |
| 유료 또는 무료 | **무료** |
| 선언 2개 | 모두 체크 |

무료를 골라야 한다. 무료 앱은 나중에 유료로 바꿀 수 없지만 인앱결제는 자유롭게 추가할 수 있고, `BUSINESS_MODEL.md`의 수익 모델이 인앱결제 기반이다.

한국어·스페인어 앱 이름은 앱 생성 후 **스토어 등록정보 > 언어 추가**에서 넣는다.

---

## 5. 스토어 등록정보에 필요한 자료

| 자료 | 규격 |
|------|------|
| 앱 아이콘 | 512×512 PNG (`assets/icon/app_icon.png`를 512로 리사이즈) |
| 그래픽 이미지 | 1024×500 PNG/JPG |
| 휴대전화 스크린샷 | 최소 2장, 16:9 또는 9:16, 320~3840px. `assets/store/screenshots/marketing/play/` (1080×1920) |
| 간단한 설명 | 80자 이내 |
| 자세한 설명 | 4000자 이내 |

문안은 `docs/STORE_LISTING.md` 참고.

---

## 6. 앱 콘텐츠 (필수 설문)

| 항목 | 답변 |
|------|------|
| 개인정보처리방침 | URL 필수 — `docs/PRIVACY_POLICY.md`를 웹에 올린다 |
| 광고 | **광고 포함** (Google AdMob) |
| 광고 ID | **사용함** — 목적: 광고. `AD_ID` 권한이 `google_mobile_ads`에서 병합된다 |
| 앱 액세스 권한 | 제한 없음 (로그인 없음) |
| 알람 및 리마인더 권한 | 해당 없음 — `USE_EXACT_ALARM` 을 쓰지 않는다. 아래 참고 |
| 콘텐츠 등급 | 설문 후 자동 산정 (유틸리티, 전체이용가 예상) |
| 타겟층 | 만 13세 이상 권장 |
| 데이터 안전성 | AdMob 항목 + Firebase의 **앱 활동, 기기 또는 기타 ID, 충돌 로그·진단** 등 실제 수집 항목 반영 |
| 정부 앱 | 아니요 |

루틴 원문·기록은 `SharedPreferences` 로컬에 저장한다. Firebase Analytics에는
화면 방문과 루틴 동작 종류를 전송하고, Crashlytics에는 오류 유형·스택과
SDK가 수집하는 앱·기기·설치 정보를 전송한다. 루틴 제목·메모·알림 payload·
루틴 ID·구매 영수증을 맞춤 이벤트나 오류 메시지에 넣지 않는다.

Google AdMob SDK는 광고 ID 등을 처리한다. 기존 광고 항목과 함께 Firebase 항목도
실제 설정에 맞춰 신고한다. SDK 버전별 전체 항목은 아래 공식 공개 문서를 기준으로 확인한다.

- 수집: 기기 또는 기타 ID — 목적: 광고 또는 마케팅
- 공유: 같은 항목을 Google(광고 네트워크)과 공유
- Firebase Analytics: 앱 활동(앱 상호작용 등), 앱 인스턴스 식별자, 앱·기기 정보,
  대략적인 지역 및 SDK 자동 수집 이벤트 — 목적: 분석. Analytics의 광고 ID 수집과
  맞춤 광고 신호는 비활성화했지만 AdMob의 광고 ID 사용은 그대로다.
- Firebase Crashlytics: 충돌 로그·진단 및 설치 식별자 — 목적: 앱 기능·분석.
  서비스 제공자 처리와 Play의 «공유» 예외는 공식 설문 정의에 따라 판단한다.
- 전송 중 암호화: 예
- 로컬 데이터는 앱 삭제로 제거된다. 이미 전송된 분석·진단 데이터는 서비스 보존 정책을
  따른다. 광고 ID 재설정이 Firebase 설치 식별자나 기존 보고서까지 삭제하지는 않는다.

공식 자료: [Firebase 데이터 공개](https://firebase.google.com/docs/android/play-data-disclosure),
[Analytics 데이터 공개](https://support.google.com/analytics/answer/11582702),
[Firebase 개인정보 처리](https://firebase.google.com/support/privacy).

EEA 사용자에게는 UMP 동의 창을 먼저 띄우고, 동의 상태를 확인한 뒤에만 광고를 요청한다(`ad_bootstrap.dart`). 개인정보처리방침(`PRIVACY_POLICY.md`, `docs/privacy/index.html`)도 같은 내용으로 맞춰 두었다.

Firebase를 포함하는 빌드를 배포하기 전에 수정된 공개 개인정보처리방침을 게시하고,
Play Console의 데이터 안전성을 갱신한다. 저장소 파일을 수정하는 것만으로 공개 페이지나
Play Console 답변이 자동 갱신되지는 않는다. 연결 정보와 검증 절차는 `FIREBASE.md`를 따른다.

### 정확한 알람: `USE_EXACT_ALARM` 을 쓰지 않는 이유

**결론 — 쓰지 않는다.** `AndroidManifest.xml` 에는 `SCHEDULE_EXACT_ALARM` 만 둔다.

2026-09 에 한 번 `USE_EXACT_ALARM` 으로 바꿔 올렸다가 되돌렸다. 기록을 남긴다.

**바꾸려 한 이유.** Android 14 부터 `SCHEDULE_EXACT_ALARM` 이 기본 «거부»다.
신규 사용자 대부분이 몇 분씩 늦는 알림을 받는 상태로 앱을 시작하고, 앱은 그
권한을 스스로 켤 수 없어 설정 항목으로 사용자를 시스템 설정까지 데려가야 한다.

**되돌린 이유.** Play Console 의 선언 서식은 «앱의 핵심 기능이 무엇인가요?» 를
**«알람 시계»와 «캘린더» 둘 중 하나로만** 고르게 한다. «루틴 앱» 칸은 없다.
그런데 이 앱은 24시간 원형 시간표가 중심이고, 스토어 문안(`STORE_LISTING.md`)도
알림을 부가 기능으로 적고 있다 — «알림을 아예 쓰지 않아도 앱의 모든 기능을
그대로 쓸 수 있습니다». 둘 중 무엇을 골라도 문안과 어긋난다. 서식은 자격이
없으면 «모든 트랙의 앱에서 이 권한을 삭제해야 합니다» 라고 경고한다.

**다시 쓰려면** 스토어 문안부터 바꿔야 한다. 알림이 «있으면 좋은 것»이 아니라
«정해진 시각에 울리는 것이 이 앱»이 되도록 설명을 다시 쓰고, 그 다음에
«알람 시계»로 선언한다. 문안을 그대로 두고 선언만 하는 건 허위 선언이다.

**지금 구조에서 감수하는 것.** Android 14+ 신규 사용자는 설정 > 알림에서
«정확한 알림»을 직접 켜야 정한 시각에 알림을 받는다. 켜지 않으면 앱은 부정확
알람으로 후퇴하고, 알림은 오되 몇 분 늦을 수 있다. 온보딩에서 알림을 허용한
사람은 시스템 설정 화면으로 한 번 안내한다.

---

## 7. 비공개 테스트 (개인 계정 필수)

2023-11-13 이후 만든 **개인** 개발자 계정은 프로덕션 전에 다음을 충족해야 한다.

- 테스터 **12명 이상**이 참여를 수락(opt-in)한 상태
- **14일 연속** 유지
- 실기기 사용 (에뮬레이터는 인정되지 않는 경우가 많음)
- 중간에 12명 아래로 떨어지면 14일이 초기화됨

여유 있게 15~20명을 모으는 편이 안전하다. 법인 계정은 면제다.

계정 유형은 Play Console > **설정 > 개발자 계정 > 계정 상세정보**의 "계정 유형"에서 확인한다.

---

## 8. 출시 순서 요약

1. 업로드 키스토어 생성 → `key.properties` 작성
2. `flutter build appbundle --release` (트랙별 광고 플래그는 2장 참고)
3. Play Console에서 앱 생성 (패키지 이름 확정 — 되돌릴 수 없음)
4. 스토어 등록정보 + 앱 콘텐츠 설문 작성
5. 비공개 테스트 트랙에 AAB 업로드 → 테스터 12명 × 14일
6. 프로덕션 액세스 신청 → 심사
7. 프로덕션 출시
