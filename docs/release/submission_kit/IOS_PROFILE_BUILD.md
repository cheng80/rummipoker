# iOS Profile 빌드

## 이 문서의 목적

iOS profile/release 빌드를 만들고 App Store Connect에 올리는 절차다. iOS만 작업할 때는 이 문서 하나를 순서대로 따라간다.

## 빌드 전에 준비할 것

```bash
flutter pub get
flutter analyze
```

iOS 제출 전에는 Bundle ID, Team, Signing Profile, 버전명, build number를 함께 확인한다.

## 기본 명령

```bash
flutter devices
flutter build ios --profile
```

실기기 실행:

```bash
flutter run --profile -d <device-id>
```

시뮬레이터 시연 영상용 debug 실행:

```bash
flutter run -d <simulator-device-id>
```

Debug fixture와 특별 모드 같은 개발용 진입점은 기본적으로 모든 빌드에서 숨긴다. QA용으로 필요할 때만 다음처럼 명시적으로 켠다.

```bash
flutter run --dart-define=SHOW_DEBUG_FIXTURES=true -d <device-id>
```

Release IPA:

```bash
flutter build ipa --release --build-name=<버전명> --build-number=<빌드번호>
```

출력:

```text
build/ios/ipa/Runner.ipa
```

주의:

- 같은 버전명을 다시 업로드해도 `--build-number`는 반드시 증가해야 한다.
- title 화면 하단 버전 footer가 제출 빌드 번호와 일치하는지 확인한다.

## Transporter 업로드

1. Mac App Store에서 Transporter 앱을 설치한다.
2. Apple Developer 계정으로 로그인한다.
3. `build/ios/ipa/Runner.ipa`를 추가한다.
4. 전송을 실행한다.
5. App Store Connect 처리 완료 후 TestFlight 또는 심사 제출로 진행한다.

## 확인 항목

- iPhone 세로 화면에서 title, 전투, 마켓, 정산 UI가 잘리지 않는지
- iPad에서 콘텐츠 프레임과 배경 확장 규칙이 유지되는지
- 로고 이미지가 뭉개지지 않는지
- 사운드, 진동, 터치 반응이 과하지 않은지
- Debug fixture/특별 모드/전투 디버그 버튼이 기본 debug/profile/release에서 숨겨지는지
- QA용 `--dart-define=SHOW_DEBUG_FIXTURES=true` 실행에서만 Debug fixture 진입점이 보이는지
- App Store Connect signing/profile 설정과 맞는지
- 동일 버전 재업로드 시 build number가 증가했는지

## 제출 전 값

- Bundle ID: 확정 필요
- Team ID: 확정 필요
- Version/Build: 확정 필요
- App Store ID: 확정 필요
