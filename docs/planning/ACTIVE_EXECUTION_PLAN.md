# Active Execution Plan

> 역할: 지금 진행 중인 일, 다음에 할 일, 막힌 이유, 완료 근거만 적는다. 게임 규칙은 [core 문서](../core/GAME_DESIGN.md), 정확한 콘텐츠 목록은 [generated catalog](../generated/CONTENT_CATALOG.md), 역기획·비교·BM 내용은 [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md)가 맡는다.

## Planning Ownership

계획 문서는 다음 네 개만 기준으로 사용한다.

| 문서 | 소유하는 정보 |
|---|---|
| `ACTIVE_EXECUTION_PLAN.md` | current active track, next action, blocker, Done evidence |
| [OPEN_DECISIONS.md](OPEN_DECISIONS.md) | code/test로 미결임이 확인된 선택지만 |
| [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md) | 역기획 비교·재미 후보·BM 권고 요약 |
| [TEST_QA_ACCEPTANCE.md](verification/TEST_QA_ACCEPTANCE.md) | 반복 실행 가능한 검증 절차와 acceptance |

## 현재 실행 상태

| Track | 상태 | 다음 판단 |
|---|---|---|
| 현재 활성 구현 track | 연출 보강 | F와 T0~T5 구현은 `codex/fx-integration`에 합쳤다. 최종 눈검증, 한가한 기기의 프레임 재측정, 풀런봇 1회를 마친 뒤 리뷰·병합한다 |
| release 준비 | 미완료 | [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md)의 build·실기 QA·store 항목을 처리한다 |
| 광고/IAP | 보류 | 비즈니스 결정과 선행 gate 없이는 시작하지 않는다 |

## 연출 보강 track

버튼을 누르거나 점수가 오를 때의 손맛을 키우는 작업이다. 공통 기반을 한 번 만들고, 이후 트랙은 그 기반의 API만 호출한다. 게임 결과와 저장 형식은 바꾸지 않는다.

| 트랙 | 범위 | Done 기준 | 상태와 근거 |
|---|---|---|---|
| F 연출 공통 기반 | 연출 시계, juice, spring-follow, 화면 흔들림, 전역 FX 레이어, pitch·햅틱, 의미 레지스트리, 연출 설정, 비싼 렌더 패턴 제거 | analyze·전체 test·release web build 통과, 새 로직 단위 테스트, 변경 전후 frame timing, main 빌드와 같은 픽스처 눈검증 비교 | 구현 완료. analyze·전체 test·release web build 통과. 웹 눈검증에서 main과 같은 장면을 확인했고, 확정 구간 raster p99가 약 20% 줄었다(3회 중앙값) |
| T0 공통 입력 | 버튼·칩·타일 선택처럼 모든 화면이 공유하는 누름 반응과 소리·햅틱 | 공용 입력이 pointer-down에 반응하고 `GameCue`로 소리·햅틱을 같은 시점에 낸다. 동작 줄이기에서 juice가 0이다 | 구현 완료. 공용 `PressFeedback`, 팝업 scale-pop, 화면 전환, 의미 소리를 넣었다. 누름·거절·전환은 웹 눈검증을 했고 modifier 거절 흔들림과 해금 불꽃은 위젯 테스트로만 확인했다 |
| T1 전투 입력 | 드로우, 배치, 이동, 버림, 확정 입력의 연출 | 입력마다 즉시 반응이 보이고 입력 잠금이 늘지 않는다. 위젯 테스트와 눈검증 몽타주가 있다 | 구현 완료. 입력 손맛과 거절 통일을 넣고 위젯 테스트로 증명했다. 진입 deal과 거절 흔들림은 캡처 간격 때문에 눈으로 보지 못했다 |
| T2 정산 | 단계별 pitch 상승, 점수 카운트업, hit-stop, 큰 점수 단계, 정산 속도 반영 | 정산 결과가 바뀌지 않고, 1x·4x·즉시에서 끝 상태가 같다. 흔들림·파티클은 설정을 따른다 | 구현 완료. 1x·즉시·중간 스킵·동작 줄이기에서 저장 상태가 같음을 테스트로 증명했다. 정산 소요 시간은 이전 눈검증 8.2초에서 6.2초로 줄었다. 풀런봇은 아직 돌리지 않았다 |
| T3 상점·보상 | 구매·판매·리롤·거절, 보상 공개의 전용 연출 | 경제 동사마다 다른 소리·햅틱과 연출이 있고 거절은 상태를 바꾸지 않는다 | 구현 완료. 구매·판매·리롤·거절·NEW 공개 연출을 넣었고 거절은 상태를 바꾸지 않음을 테스트했다. 짧은 연출의 중간 프레임 눈검증은 남았다 |
| T4 흐름·메타 | 화면 전환, 보스 소개, 게임오버 전역 pitch 하강, 해금 | 전환 중 입력과 저장 순서가 기존 계약을 지키고, 게임오버 뒤 pitch가 1로 복귀한다 | 구현 완료. Boss 인트로, 게임오버·런 완료 장면, Blind Select, 타이틀, Archive를 넣었다. 움직이는 중간 프레임은 브라우저 rAF 제한으로 못 봤고 위젯 테스트로 닫았다 |
| T5 재질·분위기 | 타일 edition 광택, 배경 분위기 | 모바일 웹 raster 비용이 트랙 F 기준보다 크게 늘지 않고, 동작 줄이기에서 idle 모션이 0이다 | 구현 완료. 재질과 별 배경, `FxAmbient`를 화면에 연결했다. 웹 눈검증은 했으나 raster p90 +10% 기준은 환경 부하로 측정하지 못했다. 통합 빌드로 재측정해야 한다 |

## 다음에 할 일

1. 통합 브랜치에서 최종 눈검증(정산·Boss 인트로·Market 분위기 전환), 프레임 재측정(한가한 기기에서 시작 커밋과 통합 빌드를 각 3회), 풀런봇 1회를 실행한 뒤 리뷰·병합한다.
2. 연출 보강 뒤에는 [OPEN_DECISIONS.md](OPEN_DECISIONS.md)의 OD-02·OD-03 또는 [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md) 중에서 다음 track을 고른다.
3. release 준비를 고르면 최신 build에서 analyze, test, build, 실기 QA, full-run 증거를 새로 남긴다.
4. 광고/IAP 구현은 비즈니스 결정 없이는 시작하지 않는다.

## 다음 작업 Done 기준

- 선택한 track의 범위, acceptance, 검증 방법을 구현 전에 확정한다.
- OD-02·OD-03을 고르면 code와 test로 결정을 증명하고 [OPEN_DECISIONS.md](OPEN_DECISIONS.md)에서 닫는다.
- release 준비를 고르면 [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md)를 최신 release candidate 기준으로 실행한다.
- 실행 증거는 다시 확인할 수 있는 경로에 보존하고 임시 `/tmp` 경로만 완료 근거로 사용하지 않는다.

## 막힌 점

- 연출 보강 track의 구현을 막는 확인된 기술 blocker는 없다. iOS 웹은 진동 API가 없고, 네이티브 효과음은 음높이 변주를 적용하지 않는다.
- 광고 파일럿은 consent/ledger/analytics 선행 gate와 비즈니스 결정이 필요하다.
- `en → ja → zh-CN → zh-TW`는 사용자 지시로 실제 실행을 생략했으므로 해당 locale의 runtime QA 증거는 없다.

## 최근 완료 근거

- 문서 authority consolidation과 역기획 정리는 core 7개, generated 2개, planning과 [START_HERE](../../START_HERE.md) 수렴으로 닫았다.
- P0 reward/settlement/save trust는 commit `1a356bb`의 runtime·회귀 테스트와 문서로 닫았다.
- Market 저장·복원 복구는 PR #14, squash merge `36052cf5`로 닫았다.
- `ko` 표준·도전 S1~S8 locale gate 결과는 [ko_cycle_review.md](verification/ko_cycle_review.md)에 요약했다. 당시 임시 실행 경로는 보존되지 않았으므로 release 제출 증거가 필요하면 다시 실행한다.
