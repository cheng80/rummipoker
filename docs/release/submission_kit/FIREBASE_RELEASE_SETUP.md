# Firebase Analytics·Crashlytics 설정과 출시 체크리스트

Rummi Poker의 Firebase 연결 구조와 출시 전 확인 항목을 함께 기록한 문서다. 체크 항목은 실제 앱 또는 Firebase Console에서 확인한 뒤 표시한다.

## 현재 앱 식별자

- Android package name: `com.cheng80.rummipoker`
- iOS bundle id: `com.cheng80.rummipoker`
- Firebase project: `rummi-poker`
- Target platforms: Android, iOS, Web

## 현재 설정 요약

| 항목 | 현재 설정 |
| --- | --- |
| Firebase 초기화 | `lib/main.dart`에서 `DefaultFirebaseOptions.currentPlatform`으로 1회 초기화 |
| GA4 자동 수집 | `FirebaseAnalyticsObserver`가 `GoRouter` 화면 전환을 관찰 |
| GA4 게임 이벤트 | `GameAnalyticsService`가 `FirebaseAnalytics.instance.logEvent`로 전송 |
| Crashlytics Flutter 오류 | 모바일에서 `FlutterError.onError`를 fatal로 기록 |
| Crashlytics 비동기 오류 | 모바일에서 `PlatformDispatcher.instance.onError`를 fatal로 기록 |
| Web Crashlytics | 사용하지 않음. Crashlytics 오류 핸들러는 `kIsWeb`에서 등록하지 않음 |
| 테스트 크래시 | `--dart-define=ENABLE_TEST_CRASH=true`일 때 게임 메뉴에만 노출 |

### 설정 파일과 담당 범위

- `pubspec.yaml`: `firebase_core`, `firebase_analytics`, `firebase_crashlytics` 패키지
- `lib/firebase_options.dart`: FlutterFire가 생성한 Android/iOS/Web 앱 옵션
- `android/app/google-services.json`: Android Firebase 앱 등록 정보
- `ios/Runner/GoogleService-Info.plist`: iOS Firebase 앱 등록 정보
- `android/settings.gradle.kts`, `android/app/build.gradle.kts`: Google Services와 Crashlytics Gradle plugin
- `lib/main.dart`: Firebase 초기화와 Crashlytics 오류 연결
- `lib/router.dart`: `FirebaseAnalyticsObserver` 등록
- `lib/services/game_analytics_service.dart`: GA4 이벤트 이름·파라미터 정규화와 전송 실패 격리

Firebase 설정 파일에는 앱 식별 정보가 포함된다. 문서나 로그에 API key 원문을 복사하지 말고, Firebase 앱을 바꿀 때는 `flutterfire configure`로 관련 파일을 함께 다시 생성한다.

## 1. Firebase Console Project

- [x] Firebase project `rummi-poker` 및 Android/iOS app id가 설정 파일과 일치
- [x] Android Google Analytics 이벤트 수집 확인
- [ ] iOS Analytics/Crashlytics 실기기 확인

## 1.1 Latest Handoff (2026-07-16)

- Android: Firebase Core, Analytics, Crashlytics 및 Crashlytics Gradle plugin을 연결했고 debug/release APK 빌드를 통과했다.
- Android Analytics: 실행 중인 에뮬레이터에서 DebugView를 활성화한 뒤 `station_select`, `battle_action`, `tutorial_already_seen` 전송과 Google Analytics HTTP 204 응답을 확인했다. 튜토리얼 완료, 첫 전투, 첫 Market 구매까지 수동 진행했다.
- Android Crashlytics: 콘솔 집계 화면 갱신을 기다리는 중이다. 테스트 크래시 issue 수신은 아직 완료 처리하지 않는다.
- iOS: `GoogleService-Info.plist`의 `IS_ANALYTICS_ENABLED=false` 의미와 실기기 Analytics/Crashlytics 수신을 재확인해야 한다.
- 저장: 에뮬레이터의 기존 이어하기 데이터가 손상/호환 불가 안내를 보였다. 원인은 로그에서 확인하지 못했으므로 사용자 데이터를 삭제하지 말고, 다음 진단은 `ActiveRunSaveService.inspectActiveRun`의 invalid 사유를 확인하는 것부터 시작한다.

## 2. Local CLI 준비

프로젝트 루트:

```bash
cd <project-root>
```

Firebase CLI 확인:

```bash
firebase --version
```

Firebase CLI가 없으면 설치:

```bash
npm install -g firebase-tools
```

Firebase 로그인:

```bash
firebase login
```

FlutterFire CLI 설치:

```bash
dart pub global activate flutterfire_cli
```

`flutterfire` 명령을 못 찾으면 현재 터미널에 PATH 추가:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

체크:

- [x] `firebase --version` 성공 (`15.8.0`)
- [x] `firebase login` 성공
- [x] `flutterfire --version` 성공 (`1.4.0`)

## 3. FlutterFire Configure

Firebase 프로젝트 생성 후 실행:

```bash
flutterfire configure
```

선택값:

- [x] Firebase project: `rummi-poker`
- [x] Platforms: `android`, `ios`, `web`
- [x] Android package name: `com.cheng80.rummipoker`
- [x] iOS bundle id: `com.cheng80.rummipoker`

완료 후 생성/수정되어야 하는 파일:

- [x] `lib/firebase_options.dart`
- [x] `android/app/google-services.json`
- [x] `ios/Runner/GoogleService-Info.plist`

## 4. Flutter Packages

추가할 패키지:

```bash
flutter pub add firebase_core firebase_analytics firebase_crashlytics
```

체크:

- [x] `pubspec.yaml`에 `firebase_core` 추가 (`^4.11.0`)
- [x] `pubspec.yaml`에 `firebase_analytics` 추가 (`^12.4.3`)
- [x] `pubspec.yaml`에 `firebase_crashlytics` 추가 (`^5.2.4`)
- [x] `pubspec.lock` 확인

## 5. App Code Wiring

코드 반영 범위:

- [x] `main.dart`에서 `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` 호출
- [x] `FlutterError.onError`를 Crashlytics fatal error 기록으로 연결
- [x] `PlatformDispatcher.instance.onError`를 Crashlytics fatal async error 기록으로 연결
- [x] Analytics 기본 인스턴스 접근 경로 추가 (`FirebaseAnalyticsObserver`)
- [x] Gameplay Analytics 이벤트 정의 및 코드 연결
  - [x] 앱 시작/세션/화면 전환: Firebase 자동 이벤트 + `FirebaseAnalyticsObserver`
  - [x] 새 런 시작
  - [x] Station 선택
  - [x] 전투 액션/실패
  - [x] 튜토리얼 시작/완료/스킵/이미 완료 진입 체크
  - [x] 점수 확정/Station 클리어
  - [x] 정산/다음 Station 진행
  - [x] Market 진입/구매/판매/리롤/실패
  - [x] Run 종료

### Gameplay Analytics Taxonomy

모든 직접 수집 이벤트는 `GameAnalyticsService`를 통해 전송한다. 이 서비스는 GA4 제한에 맞게 이름/파라미터를 정규화하고, debug fixture, bot/debug query 실행, 실패한 Analytics 전송을 게임 진행에 영향 주지 않게 막는다.

| Event | Trigger | Key parameters | Excluded cases |
| --- | --- | --- | --- |
| `run_start` | 랜덤/시드 새 런 시작 | `seed_mode`, `seed_bucket`, `difficulty`, `modifier` | Debug fixture/query |
| `station_select` | 선택 가능한 blind 시작 | `station_index`, `blind_tier`, `target_score`, `seed_mode`, `is_endless` | 잠긴 blind, debug fixture/query |
| `battle_action` | 전투 액션 성공 | `action`, `station_index`, `blind_tier`, `score`, `target_score`, `deck_remaining`, `hand_count`, `board_tiles` | hover/선택/overlay 열기 |
| `battle_action_fail` | 유저에게 의미 있는 전투 액션 실패 | `action`, `reason`, 전투 공통 context | 내부 animation step, 단순 hover |
| `tutorial_start` | 첫 전투/첫 Market 자동 튜토리얼 표시 | `tutorial_id`, `outcome` | 수동 다시 보기 |
| `tutorial_complete` | 자동 튜토리얼을 끝까지 완료 | `tutorial_id`, `outcome` | 수동 다시 보기, 강제 종료 |
| `tutorial_skip` | 사용자가 스킵 버튼으로 튜토리얼 종료 | `tutorial_id`, `outcome` | 포커스 아웃/옵션 진입/화면 전환 |
| `tutorial_already_seen` | 이미 완료/스킵한 유저가 해당 화면에 진입 | `tutorial_id`, `outcome` | 같은 화면 state 내 중복 체크 |
| `score_confirm` | 족보 확정 1회 | `line_count`, `rank_summary`, `max_rank`, `has_overlap`, `base_score`, `final_score`, `score_delta`, `station_cleared` | 정산 animation frame |
| `station_clear` | 목표 점수 달성 | `score_delta`, `score`, `target_score`, station context | 미달성 score confirm |
| `cashout_result` | 정산 결과 처리 | `cashout_action`, `blind_reward`, `total_gold`, `deck_reward_count`, `completes_run` | 정산 sheet 표시만 한 경우 |
| `station_advance` | 다음 Station 런타임 진입 | `from_station_index`, `to_station_index`, `gold`, `difficulty`, `modifier` | 최종 완료 run |
| `market_entry` | Market 화면 진입 | `station_index`, `gold`, `jester_count`, `item_count`, offer counts | Debug fixture/query |
| `market_action` | Market 구매/판매/리롤/아이템 사용 성공 | `category`, `action`, `spent_gold`, `gained_gold`, `remaining_gold`, `content_id`, `rarity`, `item_placement`, tile info | 표시 텍스트, 내부 label |
| `market_action_failed` | Market 액션 거절 | `category`, `action`, `reason`, `remaining_gold`, `content_id` | 단순 선택/탭 이동 |
| `run_end` | Game over 또는 run complete | `result`, `station_index`, `reached_stage_index`, `defeated_boss_count`, summary counts | 중복 종료 경로, debug fixture/query |

공통 전투 이벤트(`battle_action`, `battle_action_fail`, `score_confirm`, `station_clear`, `cashout_result`)에는 `difficulty`, `modifier`, `station_index`, `blind_tier`, `target_score`, `score`, `deck_remaining`, `hand_count`, `board_tiles`가 포함된다. `score_confirm`에는 족보·점수·overlap 정보가, `run_end`에는 본 런에서 본/구매한 콘텐츠 수가 추가된다.

자동 이벤트로 충분한 앱 시작/세션 시작은 별도 custom event로 중복 수집하지 않는다. 필요하면 Firebase DebugView 확인 뒤에만 추가한다.

### GA4 수집 제외 규칙

다음 실행에서는 직접 이벤트를 보내지 않는다.

- `fixture`가 있는 디버그 픽스처 실행
- `auto_advance_market`, `auto_enter_market`, `auto_cashout_loop` 자동화 실행
- `debug_`로 시작하는 QA query parameter 실행
- `GameAnalyticsContext(enabled: false)` 또는 `debugFixture: true`

이름은 영문자로 시작하는 GA4 호환 이름으로 바꾸고, 예약 접두사(`firebase_`, `google_`, `ga_`)를 피한다. 파라미터는 이벤트당 최대 25개, 문자열은 최대 100자로 제한한다. 전송 실패는 예외를 밖으로 내보내지 않아 게임 진행을 중단시키지 않는다.

## Crashlytics 오류 흐름

1. 앱이 Firebase를 초기화한다.
2. Web이 아닌 플랫폼에서 Flutter 프레임워크 오류를 `recordFlutterFatalError`로 기록한다.
3. 처리되지 않은 비동기 오류는 `recordError(..., fatal: true)`로 기록한다.
4. Android release 빌드는 Crashlytics Gradle plugin을 통해 mapping 파일 업로드 task를 제공한다.

테스트 크래시는 일반 빌드에서 노출하지 않는다. 수신 확인이 필요할 때만 아래처럼 QA 빌드를 실행하고, 게임 메뉴의 `Crashlytics 테스트 크래시`를 누른다.

```bash
flutter run --dart-define=ENABLE_TEST_CRASH=true
```

테스트 크래시는 앱 프로세스를 종료시키므로 저장되지 않은 진행을 잃을 수 있다. Firebase Console의 Crashlytics에서 새 issue가 수신된 것을 확인한 뒤 테스트 플래그 없이 다시 실행한다. 이 버튼은 출시 빌드에 포함하지 않는다.

## 플랫폼별 주의사항

### Android

- `com.cheng80.rummipoker`가 Firebase Android 앱과 일치해야 한다.
- `google-services`와 `com.google.firebase.crashlytics` Gradle plugin이 모두 적용되어야 한다.
- GA4 DebugView 확인 시 앱을 debug 대상으로 지정한다.

```bash
adb shell setprop debug.firebase.analytics.app com.cheng80.rummipoker
adb logcat -s FA FA-SVC
```

확인 후에는 debug 대상 지정을 해제한다.

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

### iOS

- `com.cheng80.rummipoker`와 `ios/Runner/GoogleService-Info.plist`의 bundle id가 일치해야 한다.
- 현재 `GoogleService-Info.plist`의 `IS_ANALYTICS_ENABLED` 값은 `false`다. 따라서 iOS GA4는 코드가 연결되어 있어도 실기기와 Console에서 수집 여부를 별도로 확인하고, 수집이 필요하면 Firebase 설정 파일을 다시 생성한 뒤 검증한다.
- iOS Crashlytics는 release 앱 또는 실기기에서 테스트 크래시를 보내고 Console 수신을 확인해야 한다.
- 현재 iOS 빌드의 deployment target은 `15.0`이다.

### Web

- `lib/firebase_options.dart`에 Web `measurementId`가 있어 GA4 초기화 대상이다.
- Crashlytics 오류 핸들러는 Web에서 등록하지 않는다.
- Web의 자동화·fixture 실행은 모바일과 같은 제외 규칙을 따른다.

## 6. Native Build Verification

Android:

- [x] `flutter analyze lib test`
- [x] `flutter build apk --debug`
- [x] `flutter build apk --release`
- [x] Firebase console에서 Android 앱 등록 상태와 app id 일치 확인
- [x] Analytics DebugView/로그 전송 확인
- [x] `com.google.firebase.crashlytics` Gradle plugin 적용 및 release mapping upload task 확인
- [ ] Crashlytics test crash issue 수신 확인

iOS:

- [ ] `flutter analyze`
- [x] `flutter build ios --release --no-codesign`
- [ ] Firebase console에서 iOS 앱 등록 상태 확인
- [ ] `IS_ANALYTICS_ENABLED=false` 설정과 Analytics 수집 여부 확인
- [ ] Xcode archive 또는 실기기 실행 확인
- [ ] Crashlytics test crash 수신 확인

## 7. Release Gate

- [x] Android Firebase 초기화 실패 없이 앱 시작
- [x] Android Analytics DebugView/Realtime 전송 확인
- [ ] Android Crashlytics 콘솔에서 테스트 크래시 issue 확인
- [ ] iOS Firebase 초기화/Analytics/Crashlytics 실기기 확인
- [x] Android release APK 빌드 확인
- [x] iOS release app 빌드 확인 (`--no-codesign`)
- [ ] iOS App Store archive/signing 확인
- [x] 웹 release 빌드가 Firebase 설정 때문에 깨지지 않음
- [ ] 웹 테스트만으로 완료 처리하지 않음
- [x] Gameplay Analytics facade/test/checklist 반영
- [x] Debug fixture/query 실행은 production Analytics에서 제외

## 8. Local Verification Log

현재 로컬에서 확인한 항목:

- [x] `flutterfire configure --project=rummi-poker`
- [x] `flutter pub add firebase_core firebase_analytics firebase_crashlytics`
- [x] Firebase 초기화/Crashlytics/Analytics observer 코드 연결
- [x] Gameplay Analytics 이벤트 코드 연결
- [x] 관련 Dart 파일 `flutter analyze`
- [x] 관련 widget/unit test
- [x] `flutter build web --release`
- [x] `flutter build apk --release`
- [x] `flutter build ios --release --no-codesign`

다음 세션에서 직접 확인할 항목:

- [ ] iOS release 앱에서 Analytics DebugView/Realtime 이벤트 수신
- [ ] Android Crashlytics test crash issue 수신과 콘솔 집계 갱신
- [ ] iOS Crashlytics test crash 수신
- [ ] iOS App Store archive/signing
- [ ] 기존 Android 이어하기 저장 손상/호환 불가 안내의 invalid 사유 진단

## Notes

- 현재까지 웹 테스트를 주로 했지만 실제 출시는 Android/iOS 앱 기준이다.
- Crashlytics 완료 기준은 모바일 앱 빌드에서 테스트 크래시가 Firebase 콘솔에 들어오는 것이다.
- Firebase project config 파일에는 앱 식별 정보가 들어간다. 비밀키처럼 취급할 필요는 없지만, 실제 연결 프로젝트가 바뀌면 `flutterfire configure`로 다시 생성한다.
- Firebase iOS SPM 패키지 요구사항 때문에 iOS deployment target은 `15.0` 이상이어야 한다.
