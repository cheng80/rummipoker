# Active Execution Plan

> 문서 성격: 현재 실행 라우터
> 기준: 문서 진입과 읽는 순서는 `START_HERE.md`를 따른다. 이 문서는 `planning` 단계에서 현재 어떤 트랙을 실행할지 정한다.

이 문서는 공모전 기준 완성과 실제 Goal 기준 완성을 분리한다.
새 세션은 `START_HERE.md`와 `current_system` 기준 문서를 읽은 뒤, 이 문서에서 현재 활성 트랙과 다음 작업만 확인한다.

## 1. 현재 활성 트랙

| Track | Status | 기준 문서 | 지금 판단 |
|---|---|---|---|
| 공모전 기준 완성 | Active for challenge full-run | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 2026-05-09 최신 룰/UI 후보에서 `contest_full_run_bot` fresh 표준 S1~S8 boss 통과 증거를 확보했다. 다음은 Flutter semantics 반복 경고를 먼저 정리하고, 도전 난이도 fresh S1~S8 full-run을 시작한다. |
| 실제 Goal 기준 완성 | Runtime rule V1 landed | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 족보 레벨 성장, 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상, 타일 구매 연출/선택 표시 보강은 런타임 반영과 핵심 검증 완료. 장기 밸런스는 별도 트랙으로 남긴다. |

현재는 공모전 기준 QA를 재개한다. 단, full-run console 0건 기준을 위해 Flutter semantics 반복 경고를 먼저 닫고 도전 난이도 풀런으로 넘어간다.

## 2. 공모전 기준 다음 작업

상세 체크리스트는 `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
현재 실행 순서는 아래로 고정한다.

1. 최신 build를 띄워 Browser/WebDriver smoke로 console error/warn 0건을 확인한다.
2. 현재 fresh 표준 풀런에서 반복 출력된 Flutter semantics route label 경고를 수정하고, 관련 위젯 테스트 또는 smoke로 재확인한다.
3. `contest_full_run_bot` policy code/test가 tile lane 구매, 추가 덱, 특수 족보 점수를 실제 평가하는지 확인한다.
4. 부족하면 bot 후보 평가에 특수 족보 근접도와 추가 타일 구매 판단을 보강한다.
5. `contest_full_run_bot`을 도전 난이도 fresh S1부터 최신 build 기준으로 실행한다.
6. 도전 full-run 도중 세션이 종료되면 마지막 로그/출력 디렉터리/checkpoint를 먼저 확인하고, debug fixture 없이 이어서 진행한다.

최근 `contest_full_run_bot` 기준선:

- 최신 fresh 표준 실행 로그: `/tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log`
- 실행 조건: `--seed 91460 --difficulty standard --web-port 7362 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- S8 boss 정산: `870/3 -> 728/2 -> 312/1`, 목표 `1739` 통과
- game over/retry: 없음
- 보스 클리어 덱 타일 보상: S2 `deck=53`부터 S8 `deck=59`까지 증가 확인
- 남은 문제: `Semantic node ... scopesRoute and namesRoute ... missing the label` Flutter semantics 경고가 반복 출력된다. 제출 console 0건 기준 전에는 open이다.

## 3. 공모전 Done Evidence

공모전 트랙은 기능 존재만으로 닫지 않는다.
아래 증거가 있어야 제출 후보로 본다.

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- Browser/WebDriver full-play QA에서 최신 빌드 기준 console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 S1~S8 clear 확인
- full-play 중 마켓 구매와 아이템 실제 사용 증거 확인
- 게임오버/런 완료 보상, 도감, 새 run 복귀가 심사자에게 설명 없이 읽힌다는 눈검증

## 4. 지금 시작하지 않는 작업

아래 항목은 실제 Goal 기준 완성 트랙으로 넘긴다.

- 장기 multi-seed r400/r800 밸런스 확정
- ML 리포트 갱신과 NotebookLM용 재가공
- production ML 또는 runtime 자동 밸런싱
- 신규 대형 UI 구조 변경
- 전체 카탈로그 가격 2차 재산정
- 반복 플레이용 해금 tree와 run modifier 깊이 확장

예외적으로 지금 시작하는 작업:

- 족보 완성 시 족보 자체가 성장하는 최소 런타임 규칙
- 그 규칙에 필요한 저장/복원/정산 테스트
- 게임 중/게임 밖에서 언제든 족보 성장 상태를 확인하는 `런 정보` 화면 또는 동등한 UI
- 새 run까지 이어지는 영구 계승은 이번 1차 범위에서 제외하고 별도 검토로 남긴다.
- 공모전 풀런봇이 성장한 족보를 평가하도록 하는 bot 정책 동기화

## 5. 문서 교통정리

| 필요 | 읽을 문서 |
|---|---|
| 전체 문서 흐름과 읽는 순서 | `START_HERE.md` |
| docs 폴더 분류 규칙 | `docs/00_docs_README.md` |
| 현재 코드 사실과 보호 규칙 | `docs/current_system/*` |
| 현재 실행 트랙 선택 | `docs/planning/ACTIVE_EXECUTION_PLAN.md` |
| 공모전 제출 세부 체크 | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` |
| 공모전 full-play bot 제작 기준 | `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md` |
| 실제 Goal 전체 진도 | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` |
| 장기 레벨링/경제 적용 상태 | `docs/planning/leveling/*` |
| 과거 V4/migration 순서 lock | `docs/planning/legacy/*` |

`docs/planning/legacy/*`는 현재 실행 판단 기준이 아니다.
