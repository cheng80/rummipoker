# HabitCell 스토어 등록 메타데이터 (Google Play / Apple App Store)

최종 업데이트: 2026-02-17  
앱: `HabitCell` (`com.cheng80.habitcell`)

이 문서는 2026-02-17 기준으로 **Google Play / Apple 공식 문서 웹 검증** 후 정리한 등록용 메타데이터입니다.  
목표는 아래 2가지입니다.

1. 심사 시 필요한 **필수 입력 항목** 누락 방지
2. 콘솔에 바로 붙여 넣을 수 있는 **HabitCell 제출 초안(ko-KR / en-US)** 제공

---

## 1) 공식 문서 기준 필수 항목 (검증 완료)

## A. Google Play (Play Console)

### 1) 메인 스토어 리스팅 필수
- `App name` (최대 30자)
- `Short description` (최대 80자)
- `Full description` (최대 4000자)
- `App icon` (필수, `512 x 512`, 32-bit PNG, 최대 1024KB)
- `Feature graphic` (필수, `1024 x 500`, JPG 또는 24-bit PNG)
- `Screenshots` (게시를 위해 최소 2장, device type별 최대 8장)
- `Contact email` (필수)

### 2) App content/정책 제출 필수
- `Data safety form` (내부 테스트 전용 제외, 사실상 모든 공개/테스트 트랙 앱 필수)
- `Privacy policy URL` (Data safety 제출 및 노출 연계)
- `Ads declaration` (Contains ads 여부)
- `Target audience and content`
- `Content rating`
- `App access` (로그인/제한 기능이 있으면 심사용 접근 정보 필수)

---

## B. Apple App Store (App Store Connect)

### 1) App Information / Platform Version 필수
- `Name` (2~30자)
- `Age Rating` (필수)
- `Primary Category` (필수)
- `Privacy Policy URL` (iOS/macOS 앱 필수)
- `Screenshots` (필수, 디바이스 타입별 1~10장)
- `Description` (필수, 최대 4000자)
- `Keywords` (필수, 최대 100 bytes)
- `Support URL` (필수, 실제 연락 정보로 연결되어야 함)
- `Copyright` (필수)

### 2) App Review Information 필수
- `Contact name`
- `Contact email`
- `Contact phone`
- `Demo account` (로그인 필요 앱인 경우)

### 3) 선택 항목
- `Promotional Text` (최대 170자)
- `Marketing URL`

---

## 2) HabitCell 공통 입력값

아래는 현재 프로젝트 코드/웹 문서 기준으로 채운 값입니다.

- 앱 이름: `HabitCell`
- Android package: `com.cheng80.habitcell`
- iOS bundle id: `com.cheng80.habitcell`
- 카테고리: `Productivity`
- 지원 이메일: `cheng80@gmail.com`
- 개인정보처리방침 URL: `https://cheng80.myqnapcloud.com/habitcell/privacy.html`
- 이용약관 URL: `https://cheng80.myqnapcloud.com/habitcell/terms.html`
- 앱 소개/마케팅 URL: `https://cheng80.myqnapcloud.com/habitcell/index.html`
- 앱 버전(현재): `1.0.0+1`

---

## 3) Google Play 제출용 입력안 (ko-KR / en-US)

## A. Product details

### ko-KR
- App name: `HabitCell`
- Short description (<=80):  
  `일별 기록, 히트맵, 스트릭으로 습관을 꾸준히 관리하는 앱`
- Full description (<=4000):

```text
HabitCell은 매일의 작은 실행을 기록해 습관을 꾸준히 이어가도록 돕는 습관 추적 앱입니다.

[핵심 기능]
- 일별 +1/-1 기록으로 오늘 실행 횟수 관리
- 목표 달성 여부 즉시 확인
- 주/월/년/전체 히트맵 시각화
- 전체/습관별 Streak 및 최근 7일/30일 통계
- 카테고리/색상 커스터마이징
- 마감 알림 및 앱 아이콘 배지
- 라이트/다크/시스템 테마
- 다국어 지원 (ko, en, ja, zh-CN, zh-TW)

[개인정보 및 데이터]
- 사용자 데이터는 기기에 로컬 저장됩니다.
- 외부 서버로 개인정보를 수집하거나 전송하지 않습니다.

[권한 안내]
- 알림 권한(선택): 마감 알림 제공에 사용됩니다.
- 권한을 허용하지 않아도 핵심 기록 기능은 정상 사용 가능합니다.
```

### en-US
- App name: `HabitCell`
- Short description (<=80):  
  `Track habits with daily logs, heatmaps, streaks, and smart reminders.`
- Full description (<=4000):

```text
HabitCell helps you build consistency by tracking small daily actions.

[Key Features]
- Daily +1/-1 logging for each habit
- Instant goal completion visibility
- Week/Month/Year/All-time heatmap views
- Overall and per-habit streak analytics
- 7-day and 30-day completion stats
- Custom categories and color themes
- Deadline reminders and app badge
- Light/Dark/System themes
- Multi-language support (ko, en, ja, zh-CN, zh-TW)

[Privacy and Data]
- Your data is stored locally on your device.
- No personal data is collected or transmitted to external servers.

[Permission]
- Notification permission (optional): used for deadline reminders.
- Core logging features still work when permission is denied.
```

---

## B. Graphics checklist (Play)

### Play 필수/권장 이미지 규격 (픽셀)

| 항목 | 필수 여부 | 규격 |
|---|---|---|
| App icon | 필수 | `512 x 512` PNG (32-bit, alpha), 최대 1024KB |
| Feature graphic | 필수 | `1024 x 500` JPG 또는 24-bit PNG |
| Phone screenshots | 필수 | 최소 2장, 최대 8장/기기타입 |

### Play 스크린샷 실제 제작 해상도 (HabitCell 권장)

Play는 폭넓은 범위를 허용하므로, 아래 2종만 준비해도 안정적으로 운영 가능합니다.

- 세로 기본본(권장): `1080 x 1920` (9:16)
- 가로 기본본(선택): `1920 x 1080` (16:9)

추가 규칙(공식):
- 최대 한 변 `3840px`
- 긴 변은 짧은 변의 2배 초과 불가

노출 최적화(권장):
- 앱은 `1080px 이상` 스크린샷 4장 이상 권장
- 태블릿 노출을 원하면 태블릿 스크린샷도 별도 업로드 권장

---

## C. App content / Data safety 입력 가이드 (HabitCell 기준)

> 최종 제출 전에는 포함 SDK의 실제 네트워크 전송 여부를 다시 검증하세요.

- Data collected: `No` (로컬 저장 중심)
- Data shared: `No`
- Privacy policy URL: `필수 입력`
- Ads: `No` (현재 코드/문서 기준 광고 SDK 확인되지 않음)
- App access: `No restrictions` (로그인 요구 없음)
- Target audience and content: 일반 생산성 앱 기준으로 실제 타깃 연령 설정
- Content rating: 설문 기반으로 생성

---

## 4) Apple App Store 제출용 입력안 (ko / en)

## A. App Information

- Name: `HabitCell` (<=30)
- Subtitle (ko): `히트맵으로 보는 습관 기록` (<=30)
- Subtitle (en): `Habit Tracker with Heatmap` (<=30)
- Primary Category: `Productivity`
- Age Rating: 생산성 앱 기준 설문 응답
- Privacy Policy URL: `https://cheng80.myqnapcloud.com/habitcell/privacy.html`

---

## B. Version metadata

### Promotional Text (선택, <=170)
- ko: `일별 기록, 히트맵, 스트릭 통계로 습관 형성을 더 꾸준하게 만드세요.`
- en: `Build consistency with daily logs, heatmaps, and streak insights.`

### Description (필수, <=4000)

ko:
```text
HabitCell은 일별 기록과 히트맵, 스트릭 분석으로 습관 형성을 돕는 습관 추적 앱입니다.

주요 기능
- +1/-1 일별 기록
- 목표 달성 상태 확인
- 주/월/년/전체 히트맵
- 전체/습관별 스트릭 통계
- 카테고리 및 색상 커스터마이징
- 마감 알림/배지, 테마, 다국어 지원

개인정보 및 데이터
- 모든 데이터는 기기에 로컬 저장됩니다.
- 외부 서버로 개인정보를 수집/전송하지 않습니다.

권한
- 알림 권한(선택): 마감 알림 기능에 사용됩니다.
- 미허용 시에도 핵심 기록 기능은 사용 가능합니다.
```

en:
```text
HabitCell is a habit tracking app designed to help you stay consistent with daily logging, heatmaps, and streak analytics.

Key features
- Daily +1/-1 habit logging
- Goal completion visibility
- Week/Month/Year/All-time heatmaps
- Overall and per-habit streak stats
- Custom categories and colors
- Reminder notifications, badge support, themes, and localization

Privacy and data
- All data stays locally on your device.
- No personal data is collected or sent to external servers.

Permission
- Notification permission (optional): used for reminders.
- Core tracking works even when permission is denied.
```

### Keywords (필수, <=100 bytes)
- ko 예시: `습관,습관기록,히트맵,스트릭,목표,알림,생산성`
- en 예시: `habit,tracker,heatmap,streak,goal,reminder,productivity`

### Support URL (필수)
- `https://cheng80.myqnapcloud.com/habitcell/privacy.html`

### Marketing URL (선택)
- `https://cheng80.myqnapcloud.com/habitcell/index.html`

### Copyright
- `2026 KIM TAEK KWON`

---

## C. Screenshot checklist (Apple)

프로젝트 설정 확인 결과:
- `ios/Runner.xcodeproj/project.pbxproj` -> `TARGETED_DEVICE_FAMILY = "1,2"`
- 즉, **HabitCell은 iPhone + iPad 지원 앱**이며 두 기기군 스크린샷이 모두 필요합니다.

### Apple 스크린샷 필수 규칙

- 포맷: `.jpeg`, `.jpg`, `.png`
- 수량: 디바이스 타입별 `1~10장`
- iPhone용 최소 1장 이상 필수
- iPad 지원 앱은 iPad용 최소 1장 이상 필수

### Apple 실제 제작 해상도 (HabitCell 준비 기준)

| 기기군 | 준비 권장 해상도(세로) | 비고 |
|---|---:|---|
| iPhone (6.9") | `1320 x 2868` | 최신 대화면 기준, 이 해상도 세트 권장 |
| iPhone (대체) | `1290 x 2796` 또는 `1260 x 2736` | 6.9" 허용 해상도 대체값 |
| iPhone (6.5") | `1284 x 2778` 또는 `1242 x 2688` | 6.9" 미제공 시 사용 |
| iPad (13") | `2064 x 2752` | iPad 지원 앱 권장 기본 |
| iPad (대체) | `2048 x 2732` | 13" 허용 해상도 대체값 |

HabitCell 권장 최소 세트(실무):
- iPhone 6.9" 세로 `1320 x 2868`로 5장
- iPad 13" 세로 `2064 x 2752`로 5장
- 총 10장(스토어 설명 흐름: 홈/오늘 목록 -> 습관 추가/수정 -> 히트맵 -> 통계 -> 설정)

---

## 5) 제출 전 최종 체크리스트

- [x] 앱명/패키지명/Bundle ID 확인 (`HabitCell`, `com.cheng80.habitcell`)
- [x] 개인정보처리방침/이용약관 URL 운영 확인
- [ ] Play/App Store locale별 텍스트 최종 교정
- [ ] 최신 UI 기준 스크린샷 교체
- [ ] Play Data safety: SDK별 실제 전송 데이터 재검증
- [ ] Apple Support URL에 연락 정보(이메일/전화/주소) 충족 여부 최종 점검
- [ ] App Review 연락처/전화번호/테스트 계정 필요 여부 최종 입력

---

## 6) 공식 문서 출처 (웹 검증 완료)

## Google Play (공식 Help Center)
- Create and set up your app  
  https://support.google.com/googleplay/android-developer/answer/9859152
- Add preview assets to showcase your app  
  https://support.google.com/googleplay/android-developer/answer/9866151
- Provide information for Google Play's Data safety section  
  https://support.google.com/googleplay/android-developer/answer/10787469
- Prepare your app for review  
  https://support.google.com/googleplay/android-developer/answer/9859455

## Apple App Store Connect (공식 Help)
- App information  
  https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- Required, localizable, and editable properties  
  https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/
- Platform version information  
  https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
- Screenshot specifications  
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

