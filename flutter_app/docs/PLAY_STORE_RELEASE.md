# Google Play 출시 가이드

`com.dayround.app` 기준. Play Console에 앱을 만든 뒤에는 패키지 이름을 바꿀 수 없다.

---

## 0. 현재 상태

| 항목 | 값 |
|------|-----|
| 패키지 이름 | `com.dayround.app` (Android `applicationId`, iOS Bundle ID 동일) |
| App Group (iOS) | `group.com.dayround.app` |
| 앱 이름 | en `DayRound` / ko `하루한바퀴` / es `Vuelta al Día` |
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
| 앱 이름 | `DayRound` |
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
| 휴대전화 스크린샷 | 최소 2장, 16:9 또는 9:16, 320~3840px |
| 간단한 설명 | 80자 이내 |
| 자세한 설명 | 4000자 이내 |

문안은 `docs/STORE_LISTING.md` 참고.

---

## 6. 앱 콘텐츠 (필수 설문)

| 항목 | 답변 |
|------|------|
| 개인정보처리방침 | URL 필수 — `docs/PRIVACY_POLICY.md`를 웹에 올린다 |
| 광고 | 없음 |
| 앱 액세스 권한 | 제한 없음 (로그인 없음) |
| 콘텐츠 등급 | 설문 후 자동 산정 (유틸리티, 전체이용가 예상) |
| 타겟층 | 만 13세 이상 권장 |
| 데이터 안전성 | **데이터를 수집하거나 공유하지 않음** |
| 정부 앱 | 아니요 |

데이터 안전성을 "수집 안 함"으로 신고할 수 있는 근거는 아래와 같다. 서버가 없고, `AndroidManifest.xml`에 `INTERNET` 권한조차 없으며, 모든 저장이 `SharedPreferences` 로컬이다. 이후 광고 SDK나 분석 도구를 넣으면 이 답변을 반드시 갱신해야 한다.

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
2. `flutter build appbundle --release`
3. Play Console에서 앱 생성 (패키지 이름 확정 — 되돌릴 수 없음)
4. 스토어 등록정보 + 앱 콘텐츠 설문 작성
5. 비공개 테스트 트랙에 AAB 업로드 → 테스터 12명 × 14일
6. 프로덕션 액세스 신청 → 심사
7. 프로덕션 출시
