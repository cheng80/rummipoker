# 앱 스토어 출시 체크리스트

> Flutter 앱 출시 시 재사용 가능한 체크리스트. 앱별로 Bundle ID, applicationId 등은 수정하여 사용.

---

## HabitCell 전용

| 항목 | 값 |
|------|-----|
| Bundle ID (iOS) | `com.cheng80.habitcell` |
| applicationId (Android) | `com.cheng80.habitcell` |
| 카테고리 | 생산성 (Productivity) |

---

## 앱 스토어 (iOS)

- 현재 출시 버전: `1.0.0+2` (App Store 배포 완료)

- [ ] **Apple Developer Program 가입**
  - [developer.apple.com](https://developer.apple.com) 연간 $99

- [ ] **App Store Connect 앱 등록**
  - Bundle ID 설정
  - 앱 이름, 부제목, 설명 작성
  - 카테고리 선택

- [x] **스크린샷 준비** (iOS 완료)
  - iPhone 6.7", 6.5", 5.5" (필수)
  - iPad (선택)

- [ ] **앱 정책·메타데이터**
  - 개인정보 처리방침 URL (데이터 수집 시)
  - 권한 사용 설명 (Info.plist - 알림 등)
  - 나이 등급, 연락처

- [ ] **TestFlight 배포**
  - 내부 테스트 → 외부 테스트
  - TestFlight 빌드 제출

- [ ] **업로드 직전 버전/빌드 번호 올리기 (필수)**
  - 같은 버전 재업로드 시에도 `build number`는 반드시 증가
  - 권장: `pubspec.yaml`의 `version: x.y.z+n` 먼저 갱신
    - 예: `version: 1.0.0+1` → `version: 1.0.1+2`
  - 릴리즈 빌드 명령어(명시):
    - `flutter build ipa --release --build-name 1.0.1 --build-number 2`
  - 참고: iOS에서 `build-name` = `CFBundleShortVersionString`, `build-number` = `CFBundleVersion`

- [x] **App Store 제출** (출시 완료)
  - 가격 책정 (무료/유료)
  - 심사 제출 및 승인 (Released)

---

## 플레이 스토어 (Android)

- [ ] **Google Play Console 개발자 등록**
  - [play.google.com/console](https://play.google.com/console) 일회성 $25

- [ ] **앱 등록**
  - applicationId 설정
  - 앱 이름, 짧은 설명, 전체 설명

- [ ] **스크린샷 준비**
  - 폰 7인치, 10인치 (필수)
  - 태블릿 (선택)

- [ ] **앱 정책·메타데이터**
  - 개인정보 처리방침 URL
  - 권한 사용 설명
  - 콘텐츠 등급 설문

- [ ] **서명 설정**
  - release keystore 생성·보관
  - `key.properties`, `build.gradle` 서명 설정

- [ ] **내부/알파/베타 테스트**
  - Internal testing track 등록
  - `requestReview()` 테스트 시 Internal app sharing 또는 Internal test track 사용

- [ ] **업로드 직전 버전/빌드 번호 올리기 (필수)**
  - 플레이스토어 업로드마다 버전코드(= `build number`)는 반드시 증가
  - 권장: `pubspec.yaml`의 `version: x.y.z+n` 먼저 갱신
    - 예: `version: 1.0.0+1` → `version: 1.0.1+2`
  - 릴리즈 빌드 명령어(명시):
    - `flutter build appbundle --release --build-name 1.0.1 --build-number 2`
  - 참고: Android에서 `build-name` = `versionName`, `build-number` = `versionCode`

- [ ] **프로덕션 출시**
  - 국가·가격 설정
  - 심사 제출

---

## 공통 (앱 코드)

- [ ] **버전 업데이트** (마켓 빌드 전 필수)
  - `pubspec.yaml`의 `version` 수동 수정
  - 형식: `1.0.0+1` (버전명+빌드번호)
  - 버전명: 사용자 노출 (Drawer 푸터, 스토어)
  - 빌드 번호: 스토어 업로드 시 이전보다 커야 함
  - Flutter는 자동 증가 없음 → 매 빌드마다 수동 올림
  - 대안: `flutter build apk --build-name=1.0.1 --build-number=2` 로 오버라이드

- [x] **스토어 평점/리뷰 팝업** (구현 완료)
  - 패키지: `in_app_review: ^2.0.11`
  - `InAppReviewService`: `requestReview()` 자동 호출 (5개 완료 또는 3일 경과)
  - Drawer "평점 남기기" → `openStoreListing()` (iOS `appStoreId` 설정 완료)
  - 설정값: `lib/service/in_app_review_service.dart` → `appStoreId = 6759329455`

- [ ] **스크린샷·문서**
  - `docs/screensshots/` 대표 이미지 (README 연동)
  - `docs/erd/`, `docs/system/` 다이어그램

- [ ] **릴리즈 빌드 점검**
  - 업로드 전에 버전 증가했는지 확인 (`version: x.y.z+n` 또는 `--build-name/--build-number`)
  - `flutter build ipa --release --build-name <버전> --build-number <빌드번호>`
  - `flutter build appbundle --release --build-name <버전> --build-number <빌드번호>`
  - 프로덕션 설정 확인 (API 키, 디버그 로그 제거 등)

---

## 참고 문서

- `docs/DRAWER_AND_VERSION_GUIDE.md` — Drawer 구조, package_info_plus, 버전 업데이트 (다른 앱 적용 가이드)
- `README.md` — 버전 관리 요약
- `docs/IN_APP_REVIEW_GUIDE.md` — 인앱 리뷰 테스트·가이드라인
