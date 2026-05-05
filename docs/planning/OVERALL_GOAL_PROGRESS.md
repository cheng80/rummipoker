# Overall Goal Progress

> 문서 성격: 전체 목표 진도표 / 작업 수렴 기준
> 목표: Balatro + Into the Breach 같은 전략성을 가진 덱빌딩 기반 로그라이트 완성
> 상세 기준 문서: `docs/current_system/CURRENT_LEVELING_POLICY.md`, `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`, `docs/planning/LEVELING_APPLIED_STATUS.md`

이 문서는 세부 실험과 구현이 전체 완성 목표의 어느 축에 붙는지 추적한다.

상태 기준:

- `Done`: 현재 목표 기준으로 잠금 가능.
- `In progress`: 구현/검증 중.
- `Next`: 바로 다음 작업 후보.
- `Planned`: 설계 필요.
- `Blocked`: 별도 결정이나 선행 작업 필요.

## 1. Goal Pillars

| Pillar | Goal | Status | Progress | Current gate |
|---|---|---|---:|---|
| Core battle strategy | 보드/손패/확정/버림 선택이 매 전투마다 의미 있게 갈린다 | In progress | 67% | 출품용 S1 entry 완화 후 S2~S8 curve 재검증 |
| Market deckbuilding | 후보 노출, 구매, 판매, 장착, 사용이 성장 선택의 중심이 된다 | In progress | 61% | 가격/보상/노출 기준선 정리 |
| Economy leveling | 골드 보상과 가격이 선택 압박을 만들되 좋은 플레이를 부당하게 막지 않는다 | In progress | 55% | watchlist 가격 후보 1차 정리 후 r120~r400 probe |
| Boss pressure | 후반 보스가 압박을 주며 S7~S8은 높은 실패 비중을 유지한다 | Next | 47% | S8 병목 유지 확인 후 S2~S8 장기 재검증 |
| UI/UX/game feel | 카드/타일/정산/마켓 액션이 게임적인 연출로 읽힌다 | In progress | 50% | 예정된 연출 보강 잔여 큐 완료 후 승인 대기 |
| Roguelite meta | 게임오버 이후 보상으로 다음 run 선택지가 열린다 | In progress | 22% | Insight 보상 이후 해금 선택 폭 확장 |
| Run restart loop | 패배/클리어 후 보상, 해금, 새 run 시작이 자연스럽게 이어진다 | In progress | 30% | 일반 run smoke와 저장/복구 재확인 |
| QA/release gate | 웹/모바일에서 저장, 복구, 애니메이션, 경제가 깨지지 않는다 | In progress | 43% | browser/compute QA와 submission candidate 반복 |
| Analysis/documentation governance | 레벨링/경제/ML/출품 문서가 한 기준으로 읽히고 작업 순서가 흔들리지 않는다 | In progress | 35% | ML 오해 소지 정정 후 문서 재정리/아카이브 정리 |

전체 추정 진도: 43%

출품용 프로토타입 추정 진도: 69%

주의:

- 이 퍼센트는 확정 지표가 아니라 현재 증거 기준의 작업 진척 추정치다.
- 큰 설계 변경, 장기 sweep, browser QA, 저장 구조 변경이 생기면 퍼센트는 다시 조정한다.
- 퍼센트는 “작업량”이 아니라 “goal 완성에 필요한 증거가 얼마나 갖춰졌는가”를 기준으로 한다.
- 출품용 프로토타입 퍼센트는 전체 완성이 아니라, 심사자가 플레이 가능한 핵심 vertical slice를 기준으로 한다.

## 2. Percent Checklist

| Area | Progress | Evidence | Missing evidence |
|---|---:|---|---|
| Battle rules and scoring | 77% | 전투/정산/보스 제약 다수 구현, fixture와 provider 테스트 존재, S1 entry smoke 개선 | S2~S8 장기 station curve 재검증 필요 |
| Boss modifier runtime cycle | 70% | S1~S8 cycle 적용, repeat/single rank는 구현 후 cycle 보류 | S7/S8 고난도 비중 재확인 |
| Market offer and inventory | 67% | Jester/Slots와 Tool/Gear 탭별 리롤 분리, 구매/판매/사용, 슬롯 제한 구현 | 가격/노출/구매력 최종 기준 필요 |
| Economy reward and price | 58% | runtime reward/price scale, catalog audit, runtime offer audit, `jester_hook` 1차 조정 | 경제 probe 및 r400/r800 |
| Animation/game feel | 50% | timing 중앙화, 마켓 flight, 정산 reveal 개선 진행 | 예정 연출 큐 완료 및 browser/compute QA |
| Save/restore stability | 65% | active run save/restore, 정산 cash-out 복구 검증 이력 | 새 meta/gameover loop 추가 시 재검증 |
| Roguelite meta growth | 22% | Insight, high stakes 해금, 게임오버/런 완료 보상 표시와 새 run 연결 QA 존재 | unlock tree 확장 |
| Game over reward loop | 34% | RunProgressionService 보상 산식, Insight 저장, 게임오버 보상 UI, S8 boss 완료 cash-out, 패배 보상 browser QA | 일반 run 패배/재시작 smoke |
| Integrated QA | 43% | 단위 테스트, 웹 빌드, S1/S8 smoke, 최종 보스/패배 루프 browser QA, submission smoke 통과 | browser/compute QA 반복과 최종 후보 빌드 필요 |
| Analysis/ML documentation | 28% | `ML` 명칭 오해를 줄이기 위한 휴리스틱 기준 문서와 `analysis/leveling/` 스캐폴딩 존재 | 실제 ML 전환은 미완료. 문서 규합 후 공모전 작업 전에 pre-outcome feature 기반 ML 이행 필요 |

## 3. Current Focus

현재 집중 축:

1. `START_HERE.md` 기준 새 세션 진입 경로와 문서 source-of-truth 정렬
2. 실제 ML 이행: pre-outcome feature table 재설계, baseline model 학습, metric 리포트, 후보 재시뮬레이션, MD 분석 보고서 작성
3. ML 분석 산출물 정리: `analysis/leveling/` 데이터, 노트북, 작업용 Python 파일, 사람이 읽는 리포트 정돈
4. 공모전 기준 텍스트/UX/QA 작업 재개
5. 경제/가격 기준선 정리와 S1~S8 레벨링 검증 재개

현재 경제 판단:

- `reroll_token`은 runtime effective price 기준 자기 회수형이 아니다.
- `trade_ticket`, `ride_the_bus`는 watchlist로 유지하되 즉시 가격 변경은 보류한다.
- `jester_hook`은 효과 대비 effective price가 너무 높아 base 7G로 낮췄다.
- r400 경제 probe에서 `jester_hook` 가격 조정은 즉시 부작용이 없고, `shop_slot_market_v9`는 balanced/power 모두 none보다 clear를 떨어뜨리지 않았다.
- 출품용 프로토타입 기준 경제 baseline은 `good enough`로 잠그고, S7/S8 난이도는 boss/target/market availability sweep으로 별도 조정한다.
- S1은 출품용 입구 안정성을 우선해 target 240/264/265와 red dampener 35% 감소로 완화했다. r240 smoke에서 S1 path는 94.2~95.0%이며, 후반 S8 병목은 남아 있다.

현재 ML/분석 판단:

- 현재 런타임 레벨링은 실제 머신러닝이 자동 조정하지 않는다.
- 현재 기준은 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 휴리스틱 라벨, 사람 승인 절차다.
- `analysis/leveling/`의 feature table과 RandomForest 결과는 실제 ML 전환 완료 증거가 아니라 전환 준비용 스캐폴딩이다.
- 실제 ML 전환은 pre-outcome feature, supervised target, train/test split, metric, 후보 추천, 후보 재시뮬레이션, 사람 승인 후 적용까지 갖춘 뒤 별도 milestone으로 진행한다.
- 이 실제 ML 이행 gate는 공모전 기준 작업 재개보다 앞에 둔다. 공모전 작업으로 돌아가기 전에 최소 baseline model과 후보 재시뮬레이션 리포트까지 완료/보류 사유를 남긴다.

## 4. Competition Prototype Track

목표: `2026-05-14 15:00 KST` BIC 일반부문 1차 접수용 플레이 가능 빌드.

공식 접수 안내 기준:

- 일반부문 접수 기간: `2026-04-08` ~ `2026-05-14`
- 접수 시작/마감시간: 오후 3시 KST
- 실행 가능한 게임 빌드 제출 필수
- 접수 마감 이후 빌드 업데이트 불가

출품용 프로토타입은 전체 goal 100%가 아니라 아래 조건을 잠그는 것을 목표로 한다.

| Gate | Prototype target | Status | Progress |
|---|---|---|---:|
| Playable vertical slice | 새 run 시작 -> 전투 -> 마켓 -> 보스 -> 정산/패배 -> 재시작 흐름이 끊기지 않는다 | In progress | 72% |
| Strategy readability | 타일/카드/아이템/보스 제약이 설명 없이도 선택 압박으로 읽힌다 | In progress | 60% |
| Economy baseline | 골드와 가격이 과다 지급처럼 보이지 않고, 좋은 플레이는 부당하게 막지 않는다 | In progress | 60% |
| Roguelite loop stub | 게임오버 보상과 다음 run 복귀가 최소 형태로 존재한다 | In progress | 40% |
| Game feel baseline | 마켓/전투/정산의 대표 액션 연출이 어색하지 않다 | In progress | 55% |
| Submission QA | 웹 빌드, 저장/복구, 플레이 영상 촬영 가능한 안정성을 확보한다 | In progress | 58% |

출품 모드 작업 원칙:

- 세부 수치 완성보다 큰 구조를 먼저 잠근다.
- 경제/레벨링은 `good enough` 기준으로 닫고, 상세 polishing은 출품 후 트랙으로 분리한다.
- 신규 시스템은 심사용 플레이 흐름을 막는 경우에만 추가한다.
- 5월 12일을 feature freeze로 보고, 5월 13일은 QA/빌드/영상/제출 자료에 둔다.
- 5월 14일은 수정일이 아니라 제출 버퍼로 남긴다.

출품용 일정 잠금:

| Date | Gate | Done 기준 |
|---|---|---|
| `2026-05-09` | 구조 잠금 | 새 run, 전투, 마켓, 보스, 정산, 게임오버/런 완료, Insight 보상 루프가 하나의 playable vertical slice로 이어진다. |
| `2026-05-10` | 경제/레벨링 잠금 | S1 입구 안정성, S2~S3 성장 압박, S7~S8 후반 압박을 출품용 smoke로 확인하고 세부 수치 polishing은 분리한다. |
| `2026-05-11` | 대표 연출 잠금 | 전투/마켓/정산 대표 액션이 어색하게 끊기지 않고, 신규 대형 연출 시스템 추가는 중단한다. |
| `2026-05-12` | Feature freeze | 새 기능 추가를 멈추고 버그 수정, 문구, fixture 정리, 빌드 안정화만 허용한다. |
| `2026-05-13` | Submission candidate | 제출 후보 웹 빌드, 핵심 테스트, browser/compute QA, 플레이 영상 촬영을 완료한다. |
| `2026-05-14` | Submission buffer | `15:00 KST` 마감 전 제출만 수행한다. 수정일로 쓰지 않는다. |

출품용으로 의도적으로 미루는 것:

- S7/S8 장기 clear 비율의 정밀한 최종값.
- 전체 카탈로그 가격 2차 재산정.
- 깊은 meta growth tree와 다수의 run modifier.
- 모든 플랫폼별 세부 레이아웃 polish.
- 신규 후보군을 대량 추가하는 콘텐츠 확장.

출품 전 필수 완료:

- r400 경제 probe로 현재 가격 변경이 부작용을 만들지 않는지 확인.
- `jester_hook` 가격 조정 r400 follow-up은 통과했으므로 추가 가격 후보 확장은 출품 후 polishing으로 넘긴다.
- S1~S8 전체 sweep은 장기 확정용이 아니라 출품 안정성용 최소 판단으로 제한.
- 게임오버 보상 루프는 저장 구조를 크게 깨지 않는 최소 구현으로 제한.
- 연출은 신규 대형 시스템보다 이미 있는 전투/마켓/정산 대표 액션의 어색함 제거에 집중.
- `flutter analyze`, 핵심 `flutter test`, `flutter build web`, browser/compute QA를 통과.

최근 QA:

- `c1f7185` 이후 `final_boss_cash_out_ready` fixture를 Chrome/Computer Use로 재검증했다.
- S8 Boss 확정 후 점수가 `1870/1`까지 정산되고, 정산 완료 sheet에 `획득 예정 Insight +36`과 `런 완료`가 표시된다.
- `런 완료` 클릭 후 Title로 복귀하고 이어하기 저장은 비어 있다.
- 새 게임 화면에서 기존 로컬 `Insight 16`에 보상 `+36`이 반영된 `보유 Insight 52`가 표시된다.
- 이전 clean-state QA에서는 새 게임 화면에서 `보유 Insight 36`, 하이 스테이크 해금 후 `보유 Insight 16`, `선택됨` 상태가 표시됐다.
- `game_over_insight_ready` fixture로 Chrome/Computer Use QA를 수행했다.
- 보드 꽉 참 + 보드 버림 0 상태에서 `드로우` 후 게임오버 dialog가 표시되고, `획득 예정 Insight +4`가 보인다.
- `나가기` 후 Title로 복귀하고 새 게임 화면에서 기존 로컬 `Insight 52`에 보상 `+4`가 반영된 `보유 Insight 56`이 표시된다.
- `flutter analyze lib/services/debug_run_fixture_service.dart test/services/debug_run_fixture_service_test.dart` 통과.
- `flutter test test/services/debug_run_fixture_service_test.dart --reporter expanded` 통과.
- `tools/prototype_submission_smoke.sh`를 추가해 출품 후보용 analyze/test/web build gate를 한 명령으로 묶었다. 저장/복구 경계 확인을 위해 `test/services/active_run_save_service_test.dart`도 포함한다.
- `tools/prototype_submission_smoke.sh --skip-build --skip-pub-get` 통과. 로그: `/tmp/rummipoker_submission_smoke/20260505_210713`
- `tools/prototype_submission_smoke.sh --skip-pub-get` 통과. analyze, 저장/복구 포함 핵심 테스트, `flutter build web`을 모두 통과했다. 로그: `/tmp/rummipoker_submission_smoke/20260505_210901`
- `prototype_stability_submission_r120` 레벨링 smoke 통과. balanced v9 `65.0%`, power v9 `65.8%`, S8 boss 병목 유지. 출품용 기준에서는 target/boss/market 추가 조정을 보류한다.
- `flutter analyze lib/views/game_view.dart lib/views/game/widgets/game_cashout_widgets.dart lib/views/game/widgets/game_shared_widgets.dart lib/services/debug_run_fixture_service.dart test/views/game/game_view_test.dart test/views/game/widgets/game_cashout_widgets_test.dart test/services/debug_run_fixture_service_test.dart` 통과.
- `flutter test test/views/game/game_view_test.dart test/views/game/widgets/game_cashout_widgets_test.dart test/services/debug_run_fixture_service_test.dart test/services/run_progression_service_test.dart test/services/run_unlock_state_service_test.dart test/services/run_completion_flow_test.dart --reporter expanded` 통과.
- `flutter build web` 통과.

출품 후 polishing으로 분리:

- S7/S8 장기 clear 비율 정밀 조정.
- 전체 카탈로그 가격 2차 재산정.
- meta growth tree 확장.
- 반복 플레이용 해금/런 modifier 깊이 확장.
- 모바일/iPad 레이아웃 세부 polish.

## 5. Completed Progress So Far

게임 전반에서 이미 진행된 주요 축:

| Area | Done | Evidence |
|---|---|---|
| Core battle loop | 보드 배치, 손패 드로우/버림, 라인 확정, 점수 계산, 정산 흐름 구현 | `lib/logic/rummi_poker_grid/`, `lib/providers/features/rummi_poker_grid/` |
| Jester runtime | 점수형, 성장형, xmult형, economy형 Jester 효과 다수 구현 | `lib/logic/rummi_poker_grid/jester_meta.dart`, `data/common/jesters_common_phase5.json` |
| Item runtime | quick slot, passive, gear/tool, market-use item 효과 구현 | `data/common/items_common_v1.json`, `lib/logic/rummi_poker_grid/item_effect_runtime.dart` |
| Market UX | Jester/Item offer, 구매, 판매, 사용, 상세 패널, 슬롯 제한, Jester/Slots와 Tool/Gear 분리 리롤 구현 | `lib/views/game/widgets/game_shop_screen.dart`, `lib/logic/rummi_poker_grid/rummi_market_facade.dart` |
| Item resale | Q-Slot/Passive/Tool/Gear/Inventory item 재판매 흐름 적용 | `GameSessionNotifier` item sell path, shop sell feedback tests |
| Market animation | 구매 flight, 판매 feedback, offer reveal timing 개선 | `lib/views/game/widgets/game_shop_screen.dart`, `lib/views/game/game_presentation_timings.dart` |
| Settlement flow | 정산 presentation pause gate, cash-out 복구, bottom sheet reveal 안정화 | `lib/views/game_view.dart`, `lib/views/game/widgets/game_cashout_widgets.dart` |
| Game over reward feedback | 패배 종료 시 획득 예정 Insight를 dialog에서 표시 | `lib/views/game/widgets/game_shared_widgets.dart`, `test/views/game/game_view_test.dart`, `game_over_insight_ready` browser QA |
| Final run completion | S8 boss 정산 후 Market 대신 런 완료 보상으로 닫힘 | `lib/views/game_view.dart`, `lib/views/game/widgets/game_cashout_widgets.dart`, `test/views/game/widgets/game_cashout_widgets_test.dart` |
| Background lifecycle | 게임/마켓 background pause, 복귀 옵션 dialog, BGM resume 보강 | `lib/views/game_view.dart`, `lib/views/game/widgets/game_shop_screen.dart`, `lib/resources/sound_manager.dart` |
| Save/restore | active run 저장/복원, 정산 중 종료 후 cash-out 복구 확인 | `lib/services/active_run_save_service.dart`, debug fixture tests |
| Boss modifiers | 색상/라인/face/all-score/first-confirm/confirm-count/repeat/single rank 계열 구현 | `lib/services/blind_selection_setup.dart`, `lib/logic/rummi_poker_grid/jester_meta.dart` |
| Runtime boss cycle | S1~S8 boss cycle 적용 | `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` |
| Market policy | station band rarity/tag weight, missing growth exposure, high-stakes market pressure 적용 | `RummiStationBandMarketPolicy`, `RummiMarketRuntimeFacade` |
| Economy runtime | reward 0.40 번역, 정수 `11/5` effective price scale 적용 | `RummiEconomyConfig`, catalog JSON |
| Economy tooling | economy trace, gated known cost, reroll/slot/sell proxy, catalog value audit, runtime offer audit 추가 | `tools/sim/economy_audit.py`, `tools/sim/catalog_value_audit.py`, `tools/sim/runtime_market_offer_audit.dart` |
| Leveling docs | current policy/runtime spec/simulation baseline/applied status 문서화 | `docs/current_system/`, `docs/planning/LEVELING_APPLIED_STATUS.md` |
| Goal workflow | 자동 진행 예외, 실험 수렴 규칙, 전체 진도표 규칙 추가 | `AGENTS.md`, `docs/planning/OVERALL_GOAL_PROGRESS.md` |

최근 완료된 경제/레벨링 흐름:

- `reward 0.40 / price 2.2 / catalog_normalized_v1` runtime economy 기준 적용.
- `high_stakes` target 1.04 / reward 1.12 / market pressure profile 적용.
- no-growth gate r120 확인: baseline no-growth는 S3부터 명확히 막히는 방향.
- 성장 route 문제 확인: S4~S8, 특히 S7/S8이 아직 너무 쉬울 수 있어 economy 기준선 후 재검증 필요.
- catalog audit를 runtime effective price 기준으로 보정.
- runtime offer audit로 watchlist 후보가 실제 offer에 노출되는지 확인.

## 6. Milestone Plan

### M0. Documentation And Analysis Source Of Truth

Status: In progress

완료 조건:

- `docs/current_system/`과 `docs/planning/`의 current 문서가 서로 충돌하지 않는다.
- 과거 실험과 폐기 후보는 `docs/archive/`에서만 historical context로 읽힌다.
- ML/휴리스틱/시뮬레이션/경제/출품 문서의 source-of-truth가 명확하다.
- `analysis/leveling/`은 실제 ML 완료가 아니라 스캐폴딩으로 표시된다.

현재 남은 일:

- `START_HERE.md`의 먼저 읽을 문서와 Source of Truth를 현재 문서 체계와 맞춘다.
- 문서 inventory 작성: `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md` 기준.
- current 문서와 archive 문서의 경계 정리.
- 중복 planning 문서 통합 또는 archive 이동은 `START_HERE.md` 참조와 필요한 내용 승격을 확인한 뒤 진행한다.
- 다음 작업 큐가 `OVERALL_GOAL_PROGRESS.md` 기준으로 읽히도록 갱신하되, 실제 ML 이행을 공모전 작업 앞에 유지한다.

### M0.5. Actual ML Leveling Transition

Status: Next

완료 조건:

- feature table을 outcome-derived summary feature가 아니라 추천 가능한 pre-outcome feature 중심으로 재설계한다.
- supervised target, train/test split, baseline model, metric을 명시한다.
- baseline model 결과와 feature importance를 사람이 읽을 수 있는 MD 리포트로 남긴다.
- 모델 후보는 런타임 자동 적용이 아니라 후보 추천으로만 사용한다.
- 추천 후보는 재시뮬레이션으로 검증하고, 사람 승인 전에는 target/boss/market/economy runtime에 반영하지 않는다.

현재 남은 일:

- `analysis/leveling/data/`에 pre-outcome feature table을 생성한다.
- `tools/leveling/`의 feature build/train 스크립트를 실제 ML baseline용으로 분리하거나 명시 옵션을 추가한다.
- baseline model을 학습하고 metric 리포트를 생성한다.
- 후보 재시뮬레이션 범위와 runs를 정하고 실행한다.
- `analysis/leveling/reports/`에 분석 보고서를 작성한다.

### M1. Economy And Price Baseline

Status: In progress

완료 조건:

- runtime effective price 기준 catalog audit가 통과한다.
- watchlist 후보의 조정/보류 판단이 문서화된다.
- 가격 변경은 1차에서 1~2개 이하로 제한한다.
- r120~r400 probe에서 `shop_slot_market_v9`가 none보다 부당하게 낮아지지 않는다.

현재 남은 일:

- r400 경제 probe로 잔고, unaffordable event, clear 역전 여부 확인.

### M2. S1~S8 Leveling Curve

Status: Next

완료 조건:

- S1은 막 플레이하지 않는 이상 대부분 통과한다.
- S2는 성장이 있으면 쉽고, 성장이 없으면 간신히 통과한다.
- S3부터 no-growth는 명확히 막힌다.
- S4~S6은 성장 선택을 점차 검증한다.
- S7~S8은 압박이 크고 clear 비중이 낮은 고난도 구간이다.

현재 남은 일:

- economy 기준선 적용 후 r400/r800 sweep.
- 너무 쉬운 구간은 target/boss severity/market availability 중 하나만 좁혀 조정.

### M3. UI/UX And Game Feel

Status: In progress

완료 조건:

- 마켓 구매/판매/사용 카드 flight가 실제 카드 이동처럼 보인다.
- 정산 bottom sheet는 최종 크기를 잡고 위에서부터 순차 reveal한다.
- 전투/정산/마켓 timing은 `GamePresentationTimings`/`GamePresentationCue` 중심으로 관리한다.
- 연출 검증은 browser/compute QA와 fixture로 확인한다.

현재 남은 일:

- 예정된 연출 큐 마무리.
- 사용자가 지시한 대로 예정 연출 작업 종료 후 다음 목표 승인 대기.

### M4. Roguelite Meta Growth

Status: Planned

완료 조건:

- 게임오버 또는 클리어 후 run 결과가 meta reward로 변환된다.
- meta reward는 다음 run의 선택지를 열지만, 인런 자동 지급으로 유저 선택을 대체하지 않는다.
- 해금/성장으로 blind target, reward, market profile, run modifier가 어떻게 변하는지 명시된다.
- 성장에 따른 레벨링 보정은 명시적 run modifier나 해금 선택으로만 적용한다.

현재 남은 일:

- meta currency/insight/해금 후보 설계.
- game over reward formula 설계.
- 새 run 선택 화면과 modifier 선택 UX 설계.

### M5. Game Over Reward Loop

Status: Planned

완료 조건:

- 패배 원인, 도달 Station, boss clear, 획득 성장에 따라 보상이 산정된다.
- 보상은 다음 run으로 돌아가는 흐름을 만든다.
- 패배 보상이 과도해 난이도를 무효화하지 않는다.
- 저장/복구와 충돌하지 않는다.

현재 남은 일:

- 보상 항목과 저장 포맷 설계.
- UI 흐름 설계.
- 레벨링과 연결되는 run modifier gate 설계.

### M6. Integrated QA

Status: Planned

완료 조건:

- `flutter analyze`
- 핵심 단위 테스트
- `flutter build web`
- `tools/prototype_submission_smoke.sh`
- browser/compute QA로 전투, 마켓, 정산, 저장/복구, 게임오버 루프 확인
- fixture는 남길 것과 제거할 것을 문서 규칙대로 분리

## 7. Work Discipline

- 실험은 완료를 향해 수렴해야 한다.
- 새 실험은 기준선, 중단 조건, 다음 구현 결정을 함께 적는다.
- 실험 결과가 가격/target/boss/market 중 어느 레버로 이어지는지 불명확하면 추가 runs를 늘리지 않는다.
- UI/UX/연출, 로그라이트 meta, 게임오버 루프는 레벨링과 별도 축으로 보되 최종 goal에서는 함께 잠근다.
