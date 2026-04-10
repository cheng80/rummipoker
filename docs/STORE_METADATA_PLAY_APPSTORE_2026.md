# 순서대로 TapTap 스토어 등록 메타데이터 (Google Play / Apple App Store)

최종 업데이트: 2026-03-04  
앱: `순서대로 TapTap` (`com.cheng80.binggocard`)

이 문서는 **Google Play / Apple 공식 문서** 기준으로 정리한 등록용 메타데이터입니다.  
목표는 아래 2가지입니다.

1. 심사 시 필요한 **필수 입력 항목** 누락 방지
2. 콘솔에 바로 붙여 넣을 수 있는 **제출 초안(ko-KR / en-US)** 제공

---

## 1) 공식 문서 기준 필수 항목

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
- `Data safety form` (공개/테스트 트랙 앱 필수)
- `Privacy policy URL` (Data safety 제출 및 노출 연계)
- `Ads declaration` (Contains ads 여부)
- `Target audience and content`
- `Content rating`
- `App access` (로그인 없음, 전체 기능 공개)

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
- `Support URL` (필수)
- `Copyright` (필수)

### 2) App Review Information 필수
- `Contact name`
- `Contact email`
- `Contact phone`

---

## 2) 순서대로 TapTap 공통 입력값

- 앱 이름: `순서대로 TapTap` (영문: `TapTap in Order`)
- Android package: `com.cheng80.binggocard`
- iOS bundle id: `com.cheng80.binggocard`
- 카테고리: `Games` > `Puzzle` (또는 `Casual`)
- 지원 이메일: `cheng80@gmail.com`
- 개인정보처리방침 URL: `https://cheng80.myqnapcloud.com/web/binggocard/privacy.html` (출시 전 설정)
- 앱 버전(현재): `1.0.0+1`

---

## 3) Google Play 제출용 입력안 (ko-KR / en-US)

## A. Product details

### ko-KR
- App name: `순서대로 TapTap`
- Short description (<=80):  
  `1부터 50까지, A부터 Z까지 순서대로 탭하는 두뇌 퍼즐 게임`
- Full description (<=4000):

```text
순서대로 TapTap은 숫자(1~50) 또는 알파벳(A~Z)을 순서대로 탭하는 두뇌 퍼즐 게임입니다.

[핵심 기능]
- 숫자 모드: 1~25가 5×5 그리드에 셔플된 후, 순서대로 탭해 50까지 완성
- 알파벳 모드: A~Y가 셔플된 후, 순서대로 탭해 Z까지 완성
- 베스트 스코어 기록 (모드별 저장)
- BGM·효과음, 볼륨·음소거 설정
- 화면 꺼짐 방지 옵션
- 다국어 지원 (ko, en, ja, zh-CN, zh-TW)

[데이터]
- 설정(볼륨, 음소거 등)과 베스트 스코어는 기기에만 저장됩니다.
- 로그인 없이 모든 기능을 이용할 수 있습니다.

[권한]
- 인터넷: 사용하지 않음 (오프라인 플레이 가능)
```

### en-US
- App name: `TapTap in Order`
- Short description (<=80):  
  `Tap numbers 1-50 or letters A-Z in order. Brain puzzle game.`
- Full description (<=4000):

```text
TapTap in Order is a brain puzzle game where you tap numbers (1-50) or letters (A-Z) in sequence.

[Key Features]
- Number mode: 1-25 shuffled in a 5×5 grid, tap in order to reach 50
- Alphabet mode: A-Y shuffled, tap in order to reach Z
- Best score saved per mode
- BGM and sound effects, volume and mute settings
- Keep screen on option
- Multi-language (ko, en, ja, zh-CN, zh-TW)

[Data]
- Settings (volume, mute, etc.) and best scores are stored only on device.
- No login required; all features available offline.

[Permissions]
- Internet: Not used (play offline)
```

---

## B. Graphics checklist (Play)

### Play 필수/권장 이미지 규격 (픽셀)

| 항목 | 필수 여부 | 규격 |
|---|---|---|
| App icon | 필수 | `512 x 512` PNG (32-bit, alpha), 최대 1024KB |
| Feature graphic | 필수 | `1024 x 500` JPG 또는 24-bit PNG |
| Phone screenshots | 필수 | 최소 2장, 최대 8장/기기타입 |

### Play 스크린샷 권장 해상도

- 세로 기본: `1080 x 1920` (9:16)
- 가로 선택: `1920 x 1080` (16:9)

권장 스크린샷 구성: 타이틀 화면 → 게임 플레이 → 클리어 화면 → 설정 화면

---

## C. App content / Data safety 입력 가이드

- Data collected: `No` (설정·베스트 스코어는 기기 로컬 저장, 서버 전송 없음)
- Data shared: `No`
- Privacy policy URL: `https://cheng80.myqnapcloud.com/web/binggocard/privacy.html`
- Ads: `No` (광고 없음)
- App access: `All functionality is available without special access` (로그인 불필요)
- Target audience and content: 퍼즐 게임 기준 연령 설정
- Content rating: 설문 기반 생성

---

## 4) Apple App Store 제출용 입력안 (ko / en)

## A. App Information

- Name: `순서대로 TapTap` (<=30)
- Subtitle (ko): `숫자·알파벳 순서 퍼즐` (<=30)
- Subtitle (en): `1-50 & A-Z Order Puzzle` (<=30)
- Primary Category: `Games` > `Puzzle`
- Age Rating: 퍼즐 게임 기준 설문 응답
- Privacy Policy URL: `https://cheng80.myqnapcloud.com/web/binggocard/privacy.html`

---

## B. Version metadata

### Promotional Text (선택, <=170)
- ko: `1부터 50, A부터 Z까지 순서대로 탭하세요. 두뇌 퍼즐 게임.`
- en: `Tap 1 to 50, A to Z in order. Brain puzzle game.`

### Description (필수, <=4000)

ko:
```text
순서대로 TapTap은 숫자(1~50) 또는 알파벳(A~Z)을 순서대로 탭하는 두뇌 퍼즐 게임입니다.

주요 기능
- 숫자 모드: 1~25 셔플 후 5×5 그리드에서 순서대로 탭해 50까지
- 알파벳 모드: A~Y 셔플 후 순서대로 탭해 Z까지
- 베스트 스코어 기록 (모드별)
- BGM·효과음, 볼륨·음소거, 화면 꺼짐 방지
- 다국어 (ko, en, ja, zh-CN, zh-TW)

데이터
- 설정과 베스트 스코어는 기기에만 저장됩니다. 로그인 없이 이용 가능합니다.
```

en:
```text
TapTap in Order is a brain puzzle game where you tap numbers (1-50) or letters (A-Z) in sequence.

Key features
- Number mode: 1-25 shuffled in 5×5 grid, tap in order to 50
- Alphabet mode: A-Y shuffled, tap in order to Z
- Best score saved per mode
- BGM, sound effects, volume, mute, keep screen on
- Multi-language (ko, en, ja, zh-CN, zh-TW)

Data
- Settings and best scores stored on device only. No login required.
```

### Keywords (필수, <=100 bytes)
- ko 예시: `퍼즐,숫자,알파벳,순서,두뇌,게임,1to50,탭`
- en 예시: `puzzle,number,alphabet,order,brain,game,1to50,tap`

### Support URL (필수)
- `https://cheng80.myqnapcloud.com/web/binggocard/privacy.html`

### Copyright
- `2026 KIM TAEK KWON`

---

## C. Screenshot checklist (Apple)

### Apple 스크린샷 필수 규칙

- 포맷: `.jpeg`, `.jpg`, `.png`
- 수량: 디바이스 타입별 `1~10장`
- iPhone용 최소 1장 이상 필수
- iPad 지원 시 iPad용 최소 1장 이상 필수

### Apple 권장 해상도

| 기기군 | 권장 해상도(세로) |
|---|---|
| iPhone (6.9") | `1320 x 2868` |
| iPad (13") | `2064 x 2752` |

권장 스크린샷 흐름: 타이틀 → 게임 플레이 → 클리어 → 설정

---

## 5) 제출 전 최종 체크리스트

- [ ] 앱명/패키지명/Bundle ID 확인 (`순서대로 TapTap`, `com.cheng80.binggocard`)
- [ ] 개인정보처리방침 URL 운영 확인
- [ ] Play/App Store locale별 텍스트 최종 교정
- [ ] 최신 UI 기준 스크린샷 교체
- [ ] Play Data safety: 로컬 저장만 사용 확인
- [ ] Apple Support URL 연락 정보 충족 여부 점검
- [ ] App Review 연락처/전화번호 최종 입력

---

## 6) 공식 문서 출처

## Google Play
- Create and set up your app  
  https://support.google.com/googleplay/android-developer/answer/9859152
- Add preview assets  
  https://support.google.com/googleplay/android-developer/answer/9866151
- Data safety section  
  https://support.google.com/googleplay/android-developer/answer/10787469

## Apple App Store Connect
- App information  
  https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- Screenshot specifications  
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
