# Agent 코딩 가이드

## 1. 기본 응답과 작업 원칙

- 항상 한국어로 간결하게 답하고 결과를 먼저 말한다.
- 사용자가 다른 스타일을 지정하지 않으면 `caveman lite`로 filler와 불필요한 hedging을 줄인다.
- 작업 전 기존 코드, 문서, 테스트와 구조를 확인하고 기존 패턴·도구를 재사용한다.
- 가장 단순하고 작은 올바른 변경을 선택하며 사용자 변경을 덮어쓰거나 되돌리지 않는다.

## 2. 규칙 라우터

- 파일을 수정하기 전에 경로가 매칭되는 `.github/instructions/` 문서를 직접 읽는다. 둘 이상 매칭되면 모두 적용한다.
- 자동 주입은 보조 수단이다. `PostToolUse` 주입을 기다리지 말고 아래 표로 먼저 찾는다.

| 작업 영역 | 하위 규칙 | 대표 경로 |
|---|---|---|
| Flutter 화면·연출·다국어·오디오 | [flutter-ui.md](.github/instructions/flutter-ui.md) | `lib/views`, `lib/widgets`, `lib/game`, UI tests, assets |
| 게임 규칙·전투·마켓·저장 | [gameplay-systems.md](.github/instructions/gameplay-systems.md) | `lib/logic`, `lib/providers`, `lib/services`, data, domain tests |
| 풀런봇·시뮬·실기 QA | [full-run-qa.md](.github/instructions/full-run-qa.md) | `tools`, `integration_test`, `test_driver`, `data/full_run_bot` |
| 정본 문서·릴리즈·시각 자산 | [docs-release-assets.md](.github/instructions/docs-release-assets.md) | `README`, `START_HERE`, `docs`, screenshot/imagegen tools |
| 모든 실패·중단·차단 보고 | [failure-reporting.md](.github/instructions/failure-reporting.md) | 항상 적용 |

- 제품 수치와 세부 계약은 규칙 파일에 복제하지 않고 `START_HERE.md`가 가리키는 `docs/core/` 정본을 확인한다.
- `docs/release/`는 build, deploy, store, screenshot, infographic 전용으로 게임 역기획 정본과 분리한다.

## 3. 계획과 승인

- 기능 작업은 기획서 확인 → Plan → 범위 확정 → 구현 → 테스트·검증 → 코드 리뷰 → 커밋 → Pull Request 순서다.
- 코드를 작성하기 전에 접근 방식과 범위를 설명한다. 요구사항이 모호하거나 실무적으로 갈리면 사용자 결정을 받는다.
- 3개 이상 파일을 바꾸는 작업은 작은 검증 단위로 분해한다.
- `/goal` 또는 장기 목표 자동 진행 승인을 받으면 범위 안 구현·테스트·문서 동기화는 단계별 사전 승인 없이 진행할 수 있다.
- 자동 진행 중에도 저장 format 파괴, 큰 UI/UX 구조 변경, 핵심 밸런스 원칙 변경, 삭제·복원·force push, 고비용 장기 실행, 갈리는 스펙은 확인받는다.

## 4. 구현과 사용자 변경 보호

- 기능 하나를 하나의 작업 단위, Worktree, `codex/` feature branch, Pull Request로 관리한다.
- 기본 checkout의 `main`은 확인·병합·정리에만 사용하고 구현은 Worktree에서 진행한다.
- 범위 밖 파일, 다른 작업자의 변경, untracked 산출물을 추측으로 수정·삭제하지 않는다.
- 사용자가 특정 파일·블록만 Git 이전 상태와 비교·복원하라고 하면 그 범위만 `git show`로 확인해 처리한다.
- 파괴적 변경, 원격 저장소 변경, Pull Request 생성과 Merge는 명시적 요청 없이 실행하지 않는다.
- 버그는 재현 테스트를 먼저 만들거나 기존 실패를 정확히 재현한 뒤 근본 원인을 수정한다.

## 5. 검증과 실패 보고

- 완료를 주장하기 전에 관련 test, lint, typecheck, build와 필요한 수동 검증을 실행한다.
- 실행하지 못한 항목은 통과로 쓰지 않고 이유, 영향, 남은 위험, 다음 검증 방법을 밝힌다.
- 코드 변경 뒤 깨질 수 있는 경로를 확인하고 이를 보호하는 최소 테스트를 유지한다.
- 실패·중단·차단은 [failure-reporting.md](.github/instructions/failure-reporting.md)에 따라 원인, 해결책, 대안, 재검증을 함께 보고한다.
- `기존 실패`, `범위 밖`, `실패했다`만 쓰고 끝내지 않는다.

## 6. Git과 Pull Request

- 커밋은 하나의 목적을 가진 논리적 변경 단위로 만들고 staged diff에서 무관한 변경과 비밀정보를 제외한다.
- 커밋 메시지는 한국어 `<분류>: <변경 내용>` 형식을 사용한다. 분류는 `기능`, `수정`, `문서`, `테스트`, `리팩터링`, `설정`, `제거`다.
- Pull Request는 기능 또는 수정 하나만 포함하고 제목·본문을 한국어로 작성한다.
- PR 본문은 `변경 내용`, `변경 이유`, `검증`, `제외 범위 및 주의사항`을 포함한다.
- 실제 실행한 검증만 기록하고 diff·CI 확인 뒤에만 PR을 생성한다. 미완성 실험만 Draft로 둔다.
- Merge 요청을 받으면 CI와 diff를 확인하고 squash merge한 뒤 Worktree와 feature branch를 정리한다.

## 7. 규칙 유지보수

- 사용자 교정마다 재발 방지 규칙을 적절한 하위 문서에서 추가하거나 갱신한다.
- 추가 전에 기존 규칙, 정본 문서, 코드·테스트와 중복되는지 확인하고 새 항목보다 기존 항목 보강을 우선한다.
- 루트에는 모든 작업에 공통인 짧은 원칙과 라우팅만 둔다. 도메인 세부 규칙을 다시 누적하지 않는다.

## 8. RTK

- RTK가 설치되어 있고 출력이 긴 명령은 `rtk git status`, `rtk git diff`, `rtk grep`, `rtk pytest`처럼 wrapper를 우선 사용한다.
- RTK가 없거나 실패하면 일반 명령으로 대체한다.
- `rtk init -g`, `rtk init --global`, `~/.claude` 변경 같은 Claude Code 전역 초기화는 사용하지 않는다.
