# Huashu Design Codex 사용 가이드

## 설치 상태

- 설치 위치: `~/.codex/skills/huashu-design`
- 원본 저장소: `https://github.com/alchaincyf/huashu-design`
- 설치 기준 브랜치: `master`
- Codex 재시작 후 새 skill 목록에 반영됩니다.

## 무엇을 할 때 쓰는가

`huashu-design`은 HTML을 결과물 포맷으로 사용해 시각 디자인 산출물을 만드는 skill입니다. 일반 웹앱 개발용이라기보다, 디자인 시안과 발표용 산출물 제작에 맞춰져 있습니다.

주요 용도:

- 고충실도 앱/웹 프로토타입
- 클릭 가능한 iOS 스타일 mockup
- HTML 기반 발표 슬라이드
- 제품 소개 애니메이션 demo
- MP4/GIF로 내보낼 motion design
- 정보그래픽/시각화
- 여러 디자인 방향 비교
- 디자인 리뷰와 개선안 작성

적합하지 않은 경우:

- 실제 운영용 production web app
- SEO가 중요한 마케팅 사이트
- 백엔드가 필요한 동적 서비스
- 기존 Flutter/React 앱 코드 자체를 고치는 작업

## Codex에서 호출하는 방법

Codex를 재시작한 뒤, 요청에 `huashu-design` 또는 이 skill의 목적이 드러나는 표현을 넣으면 됩니다.

예시:

```text
huashu-design을 써서 이 앱의 온보딩 화면 3개를 HTML 프로토타입으로 만들어줘.
```

```text
huashu-design으로 제품 소개용 30초 애니메이션 demo를 만들고 MP4로 내보낼 수 있게 구성해줘.
```

```text
huashu-design 방식으로 이 서비스의 디자인 방향을 3가지 제안하고, 각 방향별 HTML mockup을 만들어줘.
```

```text
huashu-design으로 지금 UI를 전문가 관점에서 리뷰하고 수정 우선순위를 정리해줘.
```

## 기본 작업 흐름

1. 요구사항과 대상 사용자를 먼저 정리합니다.
2. 브랜드, 제품, 기술, 최신 버전처럼 사실 확인이 필요한 항목은 웹 검색으로 검증합니다.
3. 로고, 제품 이미지, UI 스크린샷, 색상, 폰트 같은 핵심 자산을 수집합니다.
4. 필요한 경우 `brand-spec.md` 또는 `product-facts.md`를 만들어 근거를 고정합니다.
5. HTML 프로토타입, 슬라이드, 애니메이션 등 목적에 맞는 산출물을 만듭니다.
6. Playwright로 화면 렌더링, 콘솔 오류, 클릭 동작을 확인합니다.
7. 필요하면 PDF, PPTX, MP4, GIF로 내보냅니다.

## 자주 쓰는 요청 예시

프로토타입:

```text
huashu-design으로 모바일 가계부 앱의 핵심 화면 4개를 iPhone mockup 형태로 만들어줘. 화면 전환은 클릭 가능해야 해.
```

디자인 방향 탐색:

```text
huashu-design으로 이 서비스에 어울리는 디자인 방향 3가지를 제안하고, 각 방향을 비교할 수 있는 HTML demo를 만들어줘.
```

슬라이드:

```text
huashu-design으로 10분 발표용 HTML 슬라이드 deck을 만들어줘. 16:9 비율이고, 발표자 노트도 포함해줘.
```

애니메이션:

```text
huashu-design으로 신규 기능 출시를 소개하는 20초 애니메이션 HTML을 만들고, MP4 export까지 가능한 구조로 만들어줘.
```

디자인 리뷰:

```text
huashu-design 기준으로 현재 화면을 리뷰해줘. 시각 계층, 정보 밀도, 브랜드 일관성, 인터랙션 품질을 기준으로 봐줘.
```

## 포함된 도구와 의존성

설치된 skill에는 다음 보조 파일이 포함되어 있습니다.

- `assets/`: iOS frame, browser window, animation helper, BGM 파일 등
- `references/`: 디자인 원칙, 애니메이션, 슬라이드, 검증, export 관련 문서
- `scripts/verify.py`: HTML을 Playwright로 열고 screenshot과 console error를 확인
- `scripts/render-video.js`: HTML 애니메이션을 MP4로 렌더링
- `scripts/export_deck_pdf.mjs`: HTML slide deck을 PDF로 내보내기
- `scripts/export_deck_pptx.mjs`: 제한 조건을 만족하는 HTML slide deck을 editable PPTX로 변환

일부 export 기능은 별도 의존성이 필요합니다.

```bash
npm install playwright pptxgenjs sharp pdf-lib
npx playwright install chromium
```

MP4/GIF 작업에는 `ffmpeg`가 필요합니다.

```bash
brew install ffmpeg
```

Python 검증 스크립트를 쓰려면:

```bash
pip install playwright
python -m playwright install chromium
```

## Codex에서 사용할 때의 주의점

- skill 문서에는 `Claude Code`, `~/.claude`, `window.claude.complete`, `WebSearch`, `nano-banana-pro` 같은 표현이 일부 남아 있습니다. Codex에서는 동일 개념을 Codex의 웹 검색, 로컬 파일 작업, 이미지 생성/편집 도구, Playwright 실행으로 해석해 사용합니다.
- Codex의 상위 지침이 항상 우선합니다. 예를 들어 subagent 병렬 작업은 사용자가 명시적으로 요청한 경우에만 사용합니다.
- 이 skill은 디자인 산출물 제작에 강합니다. 현재 Flutter 앱의 production 코드를 수정하는 작업에는 기존 Flutter 개발 흐름을 우선 사용합니다.
- 저장소 라이선스가 `Personal Use Only`로 표시되어 있으므로 상업적 사용 전에는 라이선스 조건을 확인해야 합니다.

## 빠른 검증 명령

HTML 산출물이 생긴 뒤 기본 검증:

```bash
python ~/.codex/skills/huashu-design/scripts/verify.py path/to/design.html --viewports 1440x900,390x844
```

HTML 애니메이션을 MP4로 렌더링:

```bash
NODE_PATH=$(npm root -g) node ~/.codex/skills/huashu-design/scripts/render-video.js path/to/animation.html --duration=20 --width=1920 --height=1080
```

슬라이드 PDF export:

```bash
node ~/.codex/skills/huashu-design/scripts/export_deck_pdf.mjs --slides path/to/slides --out output.pdf
```

## 추천 사용 방식

처음에는 큰 작업을 바로 맡기기보다 다음처럼 범위를 좁히는 편이 좋습니다.

```text
huashu-design을 써서 디자인 방향 3개만 먼저 제안해줘. 아직 HTML 구현은 하지 말고, 각 방향의 장단점과 필요한 브랜드 자산을 정리해줘.
```

방향이 정해진 뒤:

```text
방향 2번으로 진행해줘. 클릭 가능한 HTML 프로토타입을 만들고 Playwright screenshot으로 검증해줘.
```

