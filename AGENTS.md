# Agent 코딩 가이드

> 이 파일을 프로젝트에 추가하여 코딩 에이전트가 따라야 할 규칙을 정의합니다.

## 1. 계획 먼저, 승인 후 코딩

- 코드를 작성하기 **전에** 접근 방식을 설명하고 승인을 기다리세요.
- 요구 사항이 모호한 경우, 모든 코드를 작성하기 전에 **반드시** 명확한 질문을 던지세요.
- GDD·체크리스트·`START_HERE.md` 등에 **미정**이거나 **실무적으로 갈래가 나는 스펙**은, 코드·문서에 반영하기 전에 **반드시 사용자에게 확인**받는다. (추측으로 잠정 구현만 하고 넘어가지 않는다. 잠정안이면 그 사실을 명시한다.)

## 2. 큰 작업은 작게 분해

- 작업이 **3개 이상의 파일**을 변경해야 한다면, 먼저 멈추고 **작은 작업으로 분해**하세요.
- 각 단계를 순차적으로 진행하고, 필요 시 사용자 확인을 받으세요.

## 3. 코드 작성 후 영향 분석

- 코드를 작성한 후, **무엇이 깨질 수 있는지** 나열하세요.
- 이를 커버할 **테스트를 제안**하세요.

## 4. 버그 수정 시 테스트 우선

- 버그가 생기면 **재현하는 테스트를 먼저 작성**하세요.
- 테스트가 통과할 때까지 고치세요.

## 5. 교정 시 규칙 추가

- 사용자가 수정을 요청할 때마다, 이 **AGENTS.md** 파일에 새로운 규칙을 추가하세요.
- 동일한 실수가 다시 발생하지 않도록 하세요.
- 사용자가 **"특정 영역만 Git의 이전 상태와 비교/복원"** 하라고 지시하면, 그 범위만 `git show` 등으로 먼저 확인한 뒤 **지정된 파일/블록만** 되돌린다. 다른 최신 작업본은 추측으로 함께 건드리지 않는다.

---

## Flutter 앱 개발 원칙

- **간결함**: 요구 사항에 맞춰 작성하고, 오버스펙을 피한다.
- **초급자 관점**: 이 앱을 이어 받을 팀원이 초급이라고 가정한다. 복잡한 로직보다 **이해도와 가독성**을 우선한다.
- **한글 주석**: 핵심 기능에는 항상 간결한 한글 주석을 작성한다.
- **UI 모듈화**: 반복되거나 화면이 복잡해지는 부분은 모듈/클래스/함수로 분리한다.
- **MVVM 패턴**: `view`에는 UI 제어 로직만 둔다. 그 외 로직은 `vm` 폴더의 ViewModel로 분리한다.

---

## Flutter 실행 환경

- **우선 기기**: iOS 시뮬레이터 (모바일 앱 우선 개발)
- **우선 모드**: Debug (run보다 debug 우선)
- macOS/웹은 보조용

## 반응형 레이아웃 (세로·iPhone / iPad)

- **폰 기준 세로 UI + 태블릿에서 가로 여백·배경만 확장**하는 패턴은 `docs/OLD/DESIGN.md`의 responsive frame 규칙을 따른다.
- 새 화면·`GameWidget` 래퍼를 만들 때 배경과 콘텐츠 프레임을 분리하고, 논리 해상도·`FittedBox`·`MediaQuery` 덮어쓰기 적용 여부를 그 문서와 맞출 것.

---

## 네이밍 (vm 폴더)

- **Handler**: DB/저장소 접근 전담 (예: DatabaseHandler, TagHandler)
- **Notifier**: Riverpod 상태 관리 (예: TodoListNotifier, TagListNotifier)
- Repository 용어는 Git과 혼동되므로 사용하지 않는다.

## Riverpod

- **`riverpod_annotation` / `build_runner` 코드젠은 도입하지 않는다.** `Notifier`·`NotifierProvider` 등은 수동 선언한다.

---

## UI 코딩 규칙

- **Row/Column 동일 간격**: `SizedBox` 대신 `spacing` 파라미터를 사용한다. (위젯 태그 과다 방지)
- **게임 설명 텍스트 말줄임표 금지**: 전투/상점/정보 패널의 설명 문구는 `TextOverflow.ellipsis`로 숨기지 않는다. 문구를 줄이기 전에 리스트/보조 영역을 줄여 설명 공간을 먼저 확보하고, 긴 팝업 설명은 내부 스크롤로 읽을 수 있게 한다.
- **정산 피드백 안정성**: Jester/Item 발동 callout은 타원형 pill보다 직사각형 패널을 우선하고, HUD container 자체를 scale/translate하지 않는다. 여러 발동 효과는 가능한 한 그룹으로 묶어 정산 시간이 선형으로 늘지 않게 한다.
- **보스/제약 표시 가시성**: 전투 중 제약 대상은 작은 점이나 단독 `!` 아이콘만으로 표시하지 않는다. 점수 영향이 즉시 읽히는 각진 배지와 높은 대비를 사용한다.
- **저장 상태와 연출 상태 분리**: Battle/Market/Settlement 모두 확정된 게임 결과와 저장 데이터가 정답이다. 애니메이션, HUD/골드 표시 지연값, reveal 상태, 선택/오버레이 상태는 transient presentation state로 두고 저장/이어하기 기준에 포함하지 않는다.

---

## 주석 규칙

- 주석은 **한글**로 작성한다.
- 코드가 하는 일을 그대로 옮기는 주석은 달지 않는다. ("이게 뭔가", "왜 이렇게 하나", "어떻게 동작하나"에 해당할 때만 작성)
- 클래스/mixin의 **역할과 존재 이유**를 간결하게 설명한다.
- 의도가 드러나지 않는 로직에는 **의도(why)**를 적는다.
- 그림 문자(이모지)는 사용하지 않는다. (디버깅 시 구분 용도로만 허용)
- "초보자용", "쉽게 설명하면" 같은 문구는 넣지 않는다.

---

## Flame 게임 성능 규칙

### 원칙

- Flame(`GameWidget`)과 Flutter 위젯은 **같은 프레임 예산을 공유**한다. 한쪽이 무거우면 다른 쪽도 FPS가 떨어진다.
- 사용자가 지시한 내용이 **성능 하락을 유발할 수 있는 구조**라면, 바로 작업하지 말고 **문제점과 개선책을 먼저 제안**한다.

### Flutter 위젯 + GameWidget 혼용 시 주의사항

- **정적 위젯**(AppBar, 고정 버튼 등)은 GameWidget과 함께 써도 성능 영향 없다.
- **실시간 갱신 위젯**(매 프레임 setState/rebuild)을 GameWidget 위에 올리면 성능 저하 원인이 된다.
  - 실시간 HUD(점수, 체력 등)는 Flame 내부 `TextComponent`/`SpriteComponent`로 처리하거나 오버레이로 분리한다.
- 복잡한 위젯(블러, 그라데이션 애니메이션 등)이 매 프레임 repaint되지 않도록 한다.

### 권장 패턴

| 패턴 | 설명 |
|------|------|
| 정적 레이어 | 자주 바뀌지 않는 UI는 Flutter 위젯으로 (rebuild 최소화) |
| Flame 오버레이 | 게임 위 팝업/메뉴는 `overlayBuilderMap`으로 관리 |
| RepaintBoundary | Flame 영역과 UI 영역을 분리해 불필요한 repaint 차단 |
| 게임 내부 HUD | 실시간 정보는 Flame 컴포넌트로 처리, 앱 UI는 Flutter로 |

---

## 문서화

- 사용자가 **문서화해 달라고 요청하기 전까지** `.md` 파일을 작성하지 않는다.
- 설계, 플랜, 요약 등은 응답으로만 보여주고, 파일로 저장하지 않는다.

---

## 추가 참고

- **언어**: 모든 응답은 한국어로 작성합니다.
- **출처**: [@svpino - X/Twitter](https://x.com/svpino/status/2018682144361734368)

<!-- BEGIN GSTACK-CODEX MANAGED BLOCK -->
## gstack — AI Engineering Workflow

This block is managed by `gstack-codex`. Do not edit inside this block.

Skills live in `.agents/skills`. Invoke them by name, e.g. `/office-hours`.
Refresh with `npx gstack-codex init --project`.
This repo currently has the `full` pack installed.

## Available skills

| Skill | What it does |
|-------|-------------|
| `/office-hours` | YC Office Hours — two modes. Startup mode: six forcing questions that expose demand reality, status quo, desperate specificity, narrowest wedge, observation, and future-fit. |
| `/plan-ceo-review` | CEO/founder-mode plan review. Rethink the problem, find the 10-star product, challenge premises, expand scope when it creates a better product. |
| `/plan-eng-review` | Eng manager-mode plan review. Lock in the execution plan — architecture, data flow, diagrams, edge cases, test coverage, performance. |
| `/plan-design-review` | Designer's eye plan review — interactive, like CEO and Eng review. |
| `/design-consultation` | Design consultation: understands your product, researches the landscape, proposes a complete design system (aesthetic, typography, color, layout, spacing, motion), and generates font+color preview pages. |
| `/review` | Pre-landing PR review. Analyzes diff against the base branch for SQL safety, LLM trust boundary violations, conditional side effects, and other structural issues. |
| `/investigate` | Systematic debugging with root cause investigation. Four phases: investigate, analyze, hypothesize, implement. |
| `/design-review` | Designer's eye QA: finds visual inconsistency, spacing issues, hierarchy problems, AI slop patterns, and slow interactions — then fixes them. |
| `/qa` | Systematically QA test a web application and fix bugs found. |
| `/qa-only` | Report-only QA testing. Systematically tests a web application and produces a structured report with health score, screenshots, and repro steps — but never fixes anything. |
| `/ship` | Ship workflow: detect + merge base branch, run tests, review diff, bump VERSION, update CHANGELOG, commit, push, create PR. |
| `/document-release` | Post-ship documentation update. Reads all project docs, cross-references the diff, updates README/ARCHITECTURE/CONTRIBUTING/CLAUDE.md to match what shipped, polishes CHANGELOG voice, cleans up TODOS, and optionally bumps VERSION. |
| `/retro` | Weekly engineering retrospective. Analyzes commit history, work patterns, and code quality metrics with persistent history and trend tracking. |
| `/browse` | Fast headless browser for QA testing and site dogfooding. Navigate any URL, interact with elements, verify page state, diff before/after actions, take annotated screenshots, check responsive layouts, test forms and uploads, handle dialogs, and assert element states. |
| `/setup-browser-cookies` | Import cookies from your real Chromium browser into the headless browse session. |
| `/careful` | Safety guardrails for destructive commands. Warns before rm -rf, DROP TABLE, force-push, git reset --hard, kubectl delete, and similar destructive operations. |
| `/freeze` | Restrict file edits to a specific directory for the session. |
| `/guard` | Full safety mode: destructive command warnings + directory-scoped edits. |
| `/unfreeze` | Clear the freeze boundary set by /freeze, allowing edits to all directories again. |
| `/gstack-upgrade` | Upgrade gstack to the latest version. Detects global vs vendored install, runs the upgrade, and shows what's new. |
| `/autoplan` | Auto-review pipeline — reads the full CEO, design, eng, and DX review skills from disk and runs them sequentially with auto-decisions using 6 decision principles. |
| `/benchmark` | Performance regression detection using the browse daemon. Establishes baselines for page load times, Core Web Vitals, and resource sizes. |
| `/benchmark-models` | Cross-model benchmark for gstack skills. Runs the same prompt through Claude, GPT (via Codex CLI), and Gemini side-by-side — compares latency, tokens, cost, and optionally quality via LLM judge. |
| `/canary` | Post-deploy canary monitoring. Watches the live app for console errors, performance regressions, and page failures using the browse daemon. |
| `/context-restore` | Restore working context saved earlier by /context-save. Loads the most recent saved state (across all branches by default) so you can pick up where you left off — even across Conductor workspace handoffs. |
| `/context-save` | Save working context. Captures git state, decisions made, and remaining work so any future session can pick up without losing a beat. |
| `/cso` | Chief Security Officer mode. Infrastructure-first security audit: secrets archaeology, dependency supply chain, CI/CD pipeline security, LLM/AI security, skill supply chain scanning, plus OWASP Top 10, STRIDE threat modeling, and active verification. |
| `/design-html` | Design finalization: generates production-quality Pretext-native HTML/CSS. |
| `/design-shotgun` | Design shotgun: generate multiple AI design variants, open a comparison board, collect structured feedback, and iterate. |
| `/devex-review` | Live developer experience audit. Uses the browse tool to actually TEST the developer experience: navigates docs, tries the getting started flow, times TTHW, screenshots error messages, evaluates CLI help text. |
| `/health` | Code quality dashboard. Wraps existing project tools (type checker, linter, test runner, dead code detector, shell linter), computes a weighted composite 0-10 score, and tracks trends over time. |
| `/land-and-deploy` | Land and deploy workflow. Merges the PR, waits for CI and deploy, verifies production health via canary checks. |
| `/learn` | Manage project learnings. Review, search, prune, and export what gstack has learned across sessions. |
| `/make-pdf` | Turn any markdown file into a publication-quality PDF. Proper 1in margins, intelligent page breaks, page numbers, cover pages, running headers, curly quotes and em dashes, clickable TOC, diagonal DRAFT watermark. |
| `/open-gstack-browser` | Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in. |
| `/pair-agent` | Pair a remote AI agent with your browser. One command generates a setup key and prints instructions the other agent can follow to connect. |
| `/plan-devex-review` | Interactive developer experience plan review. Explores developer personas, benchmarks against competitors, designs magical moments, and traces friction points before scoring. |
| `/plan-tune` | Self-tuning question sensitivity + developer psychographic for gstack (v1: observational). |
| `/setup-deploy` | Configure deployment settings for /land-and-deploy. Detects your deploy platform (Fly.io, Render, Vercel, Netlify, Heroku, GitHub Actions, custom), production URL, health check endpoints, and deploy status commands. |

Repo installs include the full generated skill pack. Heavy browser/runtime binaries stay machine-local in v1.
Installed release: `0.2.0`
<!-- END GSTACK-CODEX MANAGED BLOCK -->
