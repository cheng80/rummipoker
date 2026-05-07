# Active Execution Plan

> 문서 성격: 현재 실행 라우터
> 기준: 문서 진입과 읽는 순서는 `START_HERE.md`를 따른다. 이 문서는 `planning` 단계에서 현재 어떤 트랙을 실행할지 정한다.

이 문서는 공모전 기준 완성과 실제 Goal 기준 완성을 분리한다.
새 세션은 `START_HERE.md`와 `current_system` 기준 문서를 읽은 뒤, 이 문서에서 현재 활성 트랙과 다음 작업만 확인한다.

## 1. 현재 활성 트랙

| Track | Status | 기준 문서 | 지금 판단 |
|---|---|---|---|
| 공모전 기준 완성 | Active | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 제출 전 QA, 빌드, 시각/재미도 확인을 우선한다. |
| 실제 Goal 기준 완성 | Paused until contest pass | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 장기 밸런스, ML 갱신, 깊은 meta growth, 대형 구조 변경은 공모전 이후 재개한다. |

현재는 공모전 기준 완성 트랙만 실행한다.

## 2. 공모전 기준 다음 작업

상세 체크리스트는 `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
현재 실행 순서는 아래로 고정한다.

1. 최신 변경 후 제출 후보 web build를 다시 만든다.
2. 새 web-server 또는 최신 build 기준으로 console error/warn 0건을 확인한다.
3. Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 S1부터 S8까지 실제 UI full-play를 수행한다.
4. 게임오버 보상, 도감 카드 face, 새 run 화면이 다시 시작 욕구와 수집 욕구로 읽히는지 눈검증한다.
5. 제출 영상 촬영 기준으로 전투/마켓/정산/도감/새 run 화면이 한 게임처럼 이어지는지 확인한다.

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
- 저장 포맷을 크게 바꾸는 meta growth 확장
- 신규 대형 UI 구조 변경
- 전체 카탈로그 가격 2차 재산정
- 반복 플레이용 해금 tree와 run modifier 깊이 확장

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
