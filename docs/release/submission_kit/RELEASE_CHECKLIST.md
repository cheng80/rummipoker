# Release Checklist

## 결론

현재 제출 준비의 1차 gate는 Rummi Poker 최신 빌드에서 분석, 테스트, 빌드, Browser/Compute smoke, `contest_full_run_bot` 증거를 모두 맞추는 것이다. Debug fixture는 재현과 눈검증에만 쓰고, 제출 증거는 자연 플레이 흐름 기준으로 남긴다.

## 앱 정보

| 항목 | 현재값 |
| --- | --- |
| 표시명 | Rummi Poker |
| 서브타이틀 | 타일로 만드는 포커 런 |
| 장르 | 타일 배치 / 포커 핸드 / 로그라이트 |
| Bundle ID | 제출 전 확정 필요 |
| Android applicationId | 제출 전 확정 필요 |
| 지원 URL | 제출 전 확정 필요 |
| 개인정보 처리방침 URL | 제출 전 확정 필요 |

## 공모전 제출 전 필수 확인

- [ ] `flutter analyze`
- [ ] 핵심 `flutter test`
- [ ] `flutter build web`
- [ ] 일반 Web release에서 Debug fixture 진입점이 보이지 않는지 확인
- [ ] QA용 빌드에서 `--dart-define=SHOW_DEBUG_FIXTURES=true`로 fixture가 보이는지 확인
- [ ] Browser/WebDriver 또는 Browser Use 기준 console error/warn 0건 확인
- [ ] 표준 난이도 fresh full-run 증거 확인
- [ ] 도전 난이도 fresh S1~S8 `contest_full_run_bot` full-run 확인
- [ ] Game over, 보상, 런 정보, 무한 도전 진입 흐름 눈검증
- [ ] 닫힌 공모전 제출 이력을 현재 출시 체크리스트 기준으로 재검토하지 않음

## 제출 증거 기준

- Debug fixture, 즉시 클리어, forced reward는 full-play evidence가 아니다.
- `contest_full_run_bot` 로그는 fresh run인지 checkpoint resume인지 명확히 적는다.
- 봇 실패 후 WebDriver Chrome, ChromeDriver, Flutter web server 잔여 프로세스를 확인한다.
- 정책 문서를 바꾼 뒤 full-run을 재개하기 전에는 실제 policy code/test 반영 여부를 먼저 확인한다.

## 스토어 제출 전 추가 확인

- [ ] 앱 아이콘, 로고, 스플래시, 스크린샷 최종화
- [ ] 한국어/영어 스토어 문구 확정
- [ ] 개인정보 처리방침과 데이터 수집 여부 확정
- [ ] 연령 등급 설문 확인
- [ ] 인앱 리뷰 트리거가 과하지 않은지 확인
- [ ] `pubspec.yaml` 버전명과 build number 확정
- [ ] 같은 버전 재업로드라도 build number가 이전 업로드보다 큰지 확인
- [ ] title 화면 하단 버전 표시가 제출 빌드 번호와 일치하는지 확인
- [ ] `android/key.properties` 로컬 설정 확인
- [ ] Android release signing이 debug signing으로 떨어지지 않는지 확인
- [ ] Android AAB 출력 확인: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Android APK 출력 확인: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] iOS archive/profile build 확인
- [ ] iOS IPA 출력 확인: `build/ios/ipa/Runner.ipa`
- [ ] Transporter 업로드와 App Store Connect 처리 확인
