# gstack-codex 사용 요약

## 설치 상태

- 설치 방식: 프로젝트 로컬 설치
- 설치 명령:

```bash
npx gstack-codex@latest init --project
```

- 설치된 버전: `0.2.0`
- 추가된 위치:
  - `AGENTS.md`의 `gstack-codex` 관리 블록
  - `.agents/skills/`의 gstack 스킬 파일들

## 기본 사용법

Codex를 이 프로젝트에서 연 뒤 slash command를 실행한다.

```text
/office-hours
```

slash command가 보이지 않으면 Codex에게 이렇게 요청한다.

```text
office hours를 시작해줘
```

## 자주 쓰는 명령

| 명령 | 용도 |
| --- | --- |
| `/office-hours` | 아이디어를 질문 기반으로 정리 |
| `/plan-ceo-review` | 제품 관점에서 계획 검토 |
| `/plan-eng-review` | 기술 구현 관점에서 계획 검토 |
| `/plan-design-review` | 구현 전 UI/UX 계획 검토 |
| `/plan-devex-review` | 개발자 경험 관점에서 계획 검토 |
| `/review` | 변경 사항 리뷰 |
| `/investigate` | 버그 원인 조사 |
| `/browse` | 브라우저를 열어 실제 화면/흐름 확인 |
| `/qa` | 웹 앱 QA 후 수정 |
| `/qa-only` | 수정 없이 QA 리포트만 작성 |
| `/design-review` | 구현된 UI를 시각/UX 관점에서 점검하고 수정 |
| `/health` | 프로젝트 품질 체크 묶음 실행 |
| `/ship` | 테스트, 리뷰, 릴리즈 흐름 진행 |
| `/gstack-upgrade` | gstack 스킬 업그레이드 |

## 명령 분류

### 기획 / 설계

| 명령 | 언제 쓰나 |
| --- | --- |
| `/office-hours` | 아이디어, 기능 방향, 제품 가설을 먼저 좁힐 때 |
| `/plan-ceo-review` | 제품 가치와 범위를 다시 판단할 때 |
| `/plan-eng-review` | 구현 구조, 데이터 흐름, 테스트 범위를 잠그고 싶을 때 |
| `/plan-design-review` | UI 작업 전에 화면 구조와 시각 규칙을 검토할 때 |

### 구현 / 정리

| 명령 | 언제 쓰나 |
| --- | --- |
| `/investigate` | 버그 원인을 먼저 조사해야 할 때 |
| `/review` | 커밋/PR 전 코드 리뷰가 필요할 때 |
| `/document-release` | 구현 후 README/문서/변경 내역을 맞출 때 |
| `/context-save` | 긴 작업의 현재 맥락을 저장할 때 |
| `/context-restore` | 이전 작업 맥락을 다시 불러올 때 |

### 검증 / QA

| 명령 | 언제 쓰나 |
| --- | --- |
| `/browse` | 실제 브라우저에서 페이지를 열고 상태를 확인할 때 |
| `/qa` | QA를 수행하고 발견한 문제까지 고칠 때 |
| `/qa-only` | 수정 없이 재현 절차와 리포트만 받을 때 |
| `/design-review` | 구현된 UI의 밀도, 간격, 위계, 반응형 문제를 잡을 때 |
| `/health` | 분석, 테스트, 품질 체크를 묶어서 보고 싶을 때 |

### 마무리 / 배포

| 명령 | 언제 쓰나 |
| --- | --- |
| `/ship` | 테스트, diff 검토, 커밋/푸시/PR 흐름을 진행할 때 |
| `/land-and-deploy` | PR 병합과 배포 확인까지 이어갈 때 |
| `/canary` | 배포 후 프로덕션 화면/콘솔/성능 이상을 감시할 때 |

## 이 프로젝트용 명령 선택

### 계획을 먼저 잡을 때

| 상황 | 권장 명령 |
| --- | --- |
| 제품 방향, 기능 범위, 우선순위가 애매함 | `/office-hours` |
| 제품 관점에서 더 크게/작게 볼지 판단 | `/plan-ceo-review` |
| 구현 구조, 저장 경계, 테스트 범위 검토 | `/plan-eng-review` |
| 화면 구조, 시각 규칙, UX 흐름 검토 | `/plan-design-review` |

### 구현 중 문제가 생겼을 때

| 상황 | 권장 명령 |
| --- | --- |
| 버그 원인을 모름 | `/investigate` |
| 코드 변경 전/후 리뷰 필요 | `/review` |
| 웹/브라우저 화면 확인 필요 | `/browse` |
| QA와 수정까지 맡김 | `/qa` |
| QA 리포트만 필요 | `/qa-only` |
| UI가 어색하거나 깨짐 | `/design-review` |

### 작업을 마무리할 때

| 상황 | 권장 명령 |
| --- | --- |
| 변경사항 커밋/푸시/PR 흐름 | `/ship` |
| 배포 후 확인 | `/canary` |
| 문서 정리 | `/document-release` |
| 현재 작업 맥락 저장 | `/context-save` |
| 저장한 작업 맥락 복원 | `/context-restore` |

### 이 프로젝트에서 자주 쓸 요청 문장

```text
/plan-eng-review
START_HERE.md와 docs/planning/goal/OVERALL_GOAL_PROGRESS.md를 먼저 읽고, 현재 다음 구현 후보를 확인한 뒤 최소 변경 계획을 검토해줘.
```

```text
/investigate
현상을 재현하는 테스트나 코드 경로를 먼저 찾고, 원인 확인 전에는 수정하지 말아줘.
```

```text
/ship
현재 변경사항을 테스트하고 커밋/푸시해줘.
```

slash command가 바로 실행되지 않으면 자연어로 같은 의도를 말해도 된다.

## 다시 설치/갱신

프로젝트 스킬을 다시 생성하거나 갱신할 때 사용한다.

```bash
npx gstack-codex@latest init --project
```

## 글로벌 설치가 필요한 경우

깨끗한 Codex 전용 환경에서 모든 프로젝트에 공통으로 쓰고 싶을 때만 사용한다.

```bash
npx gstack-codex@latest init --global
```

이 프로젝트는 이미 로컬 설치를 했으므로 보통은 글로벌 설치가 필요 없다.

## 업데이트

```bash
npx gstack-codex@latest init --project
```

스킬 자체 업데이트는 Codex 안에서 아래 명령을 먼저 쓴다.

```text
/gstack-upgrade
```

## 사용 팁

- 큰 구현 전에 `/plan-eng-review` 또는 `/plan-ceo-review`로 범위와 구조를 먼저 잠근다.
- UI 작업은 구현 후 `/browse`, `/qa`, `/design-review`로 실제 화면을 본다.
- 긴 작업은 중간에 `/context-save`로 맥락을 남긴다.
- 커밋/푸시 전에는 `/review` 또는 `/ship` 흐름을 사용한다.
- 이 프로젝트에서는 저장 가능한 runtime state와 transient presentation state를 분리한다. gstack에게 작업을 시킬 때도 “save/continue 기준은 runtime state”라고 명시한다.

## 주의사항

- `gstack-codex`가 관리하는 `AGENTS.md` 블록 안은 직접 수정하지 않는다.
- 프로젝트 규칙은 기존 `AGENTS.md` 내용이 우선이며, gstack은 추가 워크플로로 사용한다.
- 공식 README 기준 권장 환경은 Node.js `18.17+`, Codex CLI `0.122.0+`이다.
- 이 PC의 `codex-cli`는 Homebrew cask로 `0.125.0`까지 업데이트했다.

## 참고 링크

- GitHub: https://github.com/phd-peter/gstack-codex
- 설치 문서: https://github.com/phd-peter/gstack-codex/blob/main/docs/install.md
