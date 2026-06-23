# app-store-screenshots 글로벌 스킬 사용 설명서

## 결론 요약

`ParthJadhav/app-store-screenshots` 스킬은 Codex 글로벌 스킬로 설치 가능하며, 현재 다음 위치에 설치되어 있다.

- 설치 경로: `/Users/cheng80/.codex/skills/app-store-screenshots`
- 스킬 파일: `/Users/cheng80/.codex/skills/app-store-screenshots/SKILL.md`
- 포함 에셋: `/Users/cheng80/.codex/skills/app-store-screenshots/mockup.png`
- 라이선스: MIT

설치 후 Codex가 새 스킬을 자동 인식하려면 Codex를 재시작해야 한다.

## 무엇을 하는 스킬인가

App Store와 Google Play 등록용 스크린샷을 만드는 Next.js 기반 생성기를 만드는 스킬이다. 단순히 앱 화면을 나열하는 것이 아니라, 각 스크린샷을 마케팅 광고 이미지처럼 구성하는 것을 전제로 한다.

지원 범위는 다음과 같다.

- iPhone 세로 스크린샷
- iPad 세로 스크린샷
- Android Phone 세로 스크린샷
- Android Tablet 7인치 세로/가로 스크린샷
- Android Tablet 10인치 세로/가로 스크린샷
- Google Play Feature Graphic, `1024x500`
- 다국어 스크린샷
- 테마 프리셋
- `html-to-image` 기반 PNG export

## 언제 사용하면 좋은가

다음 작업을 Codex에 요청할 때 이 스킬이 적합하다.

- App Store 제출용 스크린샷 세트를 만들고 싶을 때
- Google Play 등록용 스크린샷과 Feature Graphic을 만들고 싶을 때
- 실제 앱 캡처 이미지를 iPhone/Android 목업 안에 넣어 마케팅 이미지로 구성하고 싶을 때
- 여러 언어별 스크린샷을 같은 디자인으로 뽑고 싶을 때
- Next.js 페이지에서 스크린샷을 렌더링하고 PNG로 export하는 도구를 만들고 싶을 때

예시 요청:

```text
app-store-screenshots 스킬을 사용해서 이 Flutter 게임의 App Store 스크린샷 생성기를 만들어줘.
```

```text
App Store용 iPhone 스크린샷 6장을 만들고 싶어. 실제 화면 캡처는 public/screenshots/ko 안에 있어.
```

```text
Google Play용 Android phone, tablet, feature graphic까지 export 가능한 스크린샷 페이지를 만들어줘.
```

## 작업 전에 준비할 입력

이 스킬은 코드를 만들기 전에 필요한 정보를 먼저 확인하도록 설계되어 있다. 최소한 아래 정보가 필요하다.

- 실제 앱 화면 캡처 PNG 위치
- 앱 아이콘 PNG 위치
- 브랜드 색상: accent, text, background 선호
- 사용할 폰트
- 기능 목록과 우선순위
- 만들 스크린샷 장수
- 원하는 스타일 방향: 예를 들면 clean/minimal, dark/moody, bold/colorful

선택 정보:

- Apple App Store만 필요한지, Google Play도 필요한지
- iPad 스크린샷이 있는지
- Android tablet 스크린샷이 있는지
- Google Play Feature Graphic이 필요한지
- 장식용 컴포넌트 PNG가 있는지
- 다국어가 필요한지
- 하나의 디자인만 쓸지, 여러 테마 프리셋이 필요한지

## 기본 산출물 구조

iPhone만 대상으로 하면 보통 다음 구조를 쓴다.

```text
project/
├── public/
│   ├── mockup.png
│   ├── app-icon.png
│   └── screenshots/
│       ├── ko/
│       │   ├── home.png
│       │   └── feature-1.png
│       └── en/
├── src/app/
│   ├── layout.tsx
│   └── page.tsx
└── package.json
```

Apple과 Android를 같이 만들 때는 플랫폼별 폴더를 나누는 방식이 권장된다.

```text
public/screenshots/
├── apple/
│   ├── iphone/
│   └── ipad/
└── android/
    ├── phone/
    ├── tablet-7/
    └── tablet-10/
```

스킬의 기본 방침은 필요한 기기 폴더만 만드는 것이다. 빈 디렉터리를 만들면 생성기에서 깨진 이미지가 보일 수 있다.

## 스킬의 핵심 작업 흐름

1. 사용자에게 앱 캡처, 아이콘, 브랜드, 기능, 장수, 스타일을 확인한다.
2. 패키지 매니저를 감지한다. 우선순위는 `bun`, `pnpm`, `yarn`, `npm`이다.
3. 기존 Next.js 프로젝트가 없으면 새 프로젝트를 만든다.
4. `html-to-image`를 설치한다.
5. 스킬에 포함된 `mockup.png`를 프로젝트 `public/`에 복사한다.
6. 스크린샷별 카피를 먼저 작성하고 승인받는다.
7. `src/app/page.tsx` 하나에 렌더링/toolbar/export UI를 만든다.
8. 브라우저에서 실제 export 결과를 확인한다.

## 카피 작성 원칙

이 스킬은 스크린샷을 문서가 아니라 광고 이미지로 본다. 그래서 한 장의 스크린샷에는 하나의 메시지만 담는 것이 기본 원칙이다.

권장:

- 첫 장은 가장 강한 핵심 가치 제안
- 한 슬라이드에 한 기능 또는 한 결과만 표현
- 3-5단어 단위로 짧게 줄바꿈
- 썸네일에서도 읽히는 큰 글자
- 다국어에서는 번역 후 줄바꿈과 길이를 다시 점검

피해야 할 것:

- 기능 목록을 headline처럼 나열
- 한 문장에 여러 장점을 `and`로 묶기
- 실제 UI를 작게만 보여주고 메시지가 없는 구성
- 같은 레이아웃을 모든 슬라이드에 반복

## 이 프로젝트에서 사용할 때 주의할 점

현재 프로젝트는 Flutter/Flame 게임 프로젝트이므로, 스킬이 만드는 Next.js 생성기는 앱 본체와 별도 도구로 두는 것이 안전하다.

권장 위치:

```text
tools/app_store_screenshots/
```

이 위치에 별도 Next.js 프로젝트를 만들면 Flutter 런타임 코드와 빌드 설정을 덜 건드린다.

주의:

- 실제 게임 캡처 PNG를 먼저 준비해야 한다.
- App Store용 이미지는 각 locale별 텍스트 길이 검증이 필요하다.
- 한글, 일본어, 중국어는 영문보다 줄바꿈 감각이 다르므로 export 전에 눈검증이 필요하다.
- 프로젝트 규칙상 코드 작성 전 접근 방식 승인이 필요하다.
- 3개 이상 파일을 바꿀 작업이면 작은 단계로 나눠 진행해야 한다.
- 이 프로젝트의 제출 후보 스크린샷 원본은 웹 `PhoneFrame` 캡처보다 iPhone Simulator 캡처를 우선한다. 웹 캡처는 빠른 반복용이고, 최종 후보는 `tools/ios_app_store_screenshot_capture.sh`로 생성한 iOS safe area 기준 PNG를 사용한다.

## 설치 재현 명령

다시 설치해야 할 경우 다음 명령을 사용할 수 있다.

```bash
python3 /Users/cheng80/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo ParthJadhav/app-store-screenshots \
  --path skills/app-store-screenshots
```

이미 같은 폴더가 있으면 설치 스크립트가 중단될 수 있다. 덮어쓰기가 필요하면 기존 설치본을 백업하거나 삭제한 뒤 진행해야 한다.

## 설치 확인 명령

```bash
find /Users/cheng80/.codex/skills/app-store-screenshots -maxdepth 2 -type f -print
```

정상 설치라면 최소한 다음 두 파일이 보여야 한다.

```text
/Users/cheng80/.codex/skills/app-store-screenshots/SKILL.md
/Users/cheng80/.codex/skills/app-store-screenshots/mockup.png
```

## Codex에서 호출하는 방법

Codex를 재시작한 뒤 다음처럼 요청하면 된다.

```text
app-store-screenshots 스킬을 사용해서 App Store 스크린샷 생성기를 만들어줘.
```

또는 명시적으로 스킬명을 쓰지 않아도 App Store/Google Play 스크린샷 생성 요청이면 Codex가 이 스킬을 사용할 수 있다. 단, 확실하게 적용하려면 요청에 `app-store-screenshots 스킬`이라고 적는 편이 좋다.
