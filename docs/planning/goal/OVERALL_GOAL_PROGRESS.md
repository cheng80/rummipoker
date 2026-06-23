# Overall Goal Progress

> 문서 성격: 전체 목표 진도표 / 작업 수렴 기준
> 목표: Balatro + Into the Breach 같은 전략성을 가진 덱빌딩 기반 로그라이트 완성
> 상세 기준 문서: `docs/current_system/CURRENT_LEVELING_POLICY.md`, `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`, `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`
> 현재 실행 라우터: `docs/planning/ACTIVE_EXECUTION_PLAN.md`

이 문서는 세부 실험과 구현이 전체 완성 목표의 어느 축에 붙는지 추적한다.
현재 활성 트랙과 다음 작업 선택은 `docs/planning/ACTIVE_EXECUTION_PLAN.md`를 먼저 따른다.

상태 기준:

- `Done`: 현재 목표 기준으로 잠금 가능.
- `In progress`: 구현/검증 중.
- `Next`: 바로 다음 작업 후보.
- `Planned`: 설계 필요.
- `Blocked`: 별도 결정이나 선행 작업 필요.

## 0. 실제 Goal 기준 첫 화면

현재 결론:

- 실제 제품 완성도는 아직 `In progress`이며, 전체 추정 진도는 42%다.
- 2026-05-15 12시경 공모전 최종 산출물을 우선 등록했으므로 공모전 트랙은 off다. 현재 활성 실행은 `docs/planning/ACTIVE_EXECUTION_PLAN.md`의 post-contest 안정화/리팩터링 트랙이다.
- 공모전 이후 안정화로 손패 최대치, 전투 자원, 보유/후보 슬롯 상한과 no-op 정책을 닫았다.
- Jester/Item/Tool/Gear 정책 리스크는 상당 부분 분해/수정됐다. 특수 타일 modifier V1과 V2-A 판본 1차, runtime state / transient presentation state 분리 1차, settlement 효과 단계 분리도 닫았다. 2026-06-09에는 S1 첫 Market 무료 리롤 보상, 아이템/패시브 리롤 할인 표시, stale save guard를 현재 정책 기준으로 다시 잠갔다.
- 가격/가치 판단과 장기 경제 gate는 exploratory probe 단계로 남아 있으며, 런타임 반영 전 fresh 검증이 필요하다. 기존 ML/시뮬레이션 산출물은 active 판단 근거로 재사용하지 않고, 현재 runtime 기준 fresh row 5000건 이상 축적부터 다시 시작한다.

현재 재개 대상:

- 장기 multi-seed r400/r800 밸런스 확정
- ML 리포트 갱신과 NotebookLM용 재가공
- production ML 또는 runtime 자동 밸런싱
- 저장 포맷을 크게 바꾸는 meta growth 확장
- 신규 대형 UI 구조 변경
- 전체 카탈로그 가격 2차 재산정
- 반복 플레이용 해금 tree와 run modifier 깊이 확장

현재 재개 순서:

1. 완료: `docs/archive/feature_plan_history/TILE_MODIFIER_V1_V2_PLAN.md` 기준 특수 타일 V1 구현.
2. 완료: modifier 없는 기존 저장 호환과 modifier 포함 저장/복원/전투/마켓 표시 검증.
3. 완료: 특수 타일 V2-A 판본 1차 구현과 저장/마켓/정산/badge 검증.
4. 완료: runtime state와 transient presentation state 분리 1차.
5. 완료: UI/UX 예정 연출 큐 1차. settlement에서 Jester / Tile modifier / Item 효과 단계를 분리했다.
6. 완료: 1차 리팩터링/상수 분리. HUD/timing/카드 metric 일부를 공용 상수로 이동했다.
7. 진행 중: 구 시뮬레이션/ML 산출물을 active workspace에서 archive로 내린 상태를 유지하고, 새 학습 데이터셋은 fresh run부터 다시 쌓는다.
   - 현재 runtime/catalog/ruleset/bot policy/feature schema와 산출 당시 조건이 다르면 현재 판단 근거로 바로 쓰지 않는다.
   - 과거 row와 리포트는 `historical prior`로만 두고, 새 feature table에는 기본적으로 섞지 않는다.
   - 2026-05-29 bootstrap으로 `planner_v2` fresh 5,049 JSONL rows를 생성했다. tracked 요약은 `analysis/leveling/reports/fresh_runtime_data_2026_05_29.md`.
8. 장기 S1~S8 밸런스를 fresh data 이후 multi-seed r400/r800 기준으로 재검증한다.
9. 경제/가격/market availability를 `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md` 기준으로 다시 연다.
10. 새 ML/휴리스틱 산출물은 `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`와 `analysis/leveling/` 기준으로 fresh data에서 다시 만든다.
11. 깊은 meta growth, 해금 tree, run modifier, 반복 플레이 polish를 실제 Goal track으로 확장한다.

장기 Done 기준:

- 앱/runtime에 반영되고 저장/복원/시뮬레이션/관련 테스트 경로가 확인되어야 한다.
- 문서 정리, sim-only probe, ML 추천표, offline metric, 후보 설계는 완료가 아니라 중간 산출물이다.
- 공모전 handoff는 장기 Goal 완료와 다르다.

## 1. Goal Pillars

| Pillar | Goal | Status | Progress | Current gate |
|---|---|---|---:|---|
| Core battle strategy | 보드/손패/확정/버림 선택이 매 전투마다 의미 있게 갈린다 | In progress | 67% | 손패 상한/no-op 정책 후 S2~S8 curve 재검증 |
| Market deckbuilding | 후보 노출, 구매, 판매, 장착, 사용이 성장 선택의 중심이 된다 | In progress | 61% | Jester/Item/Tool/Gear 정책 리스크 분해 |
| Economy leveling | 골드 보상과 가격이 선택 부담을 만들되 좋은 플레이를 부당하게 막지 않는다 | In progress | 59% | post-contest 경제 gate 재개 |
| Boss pressure | 후반 보스가 높은 난도를 만들며 S7~S8은 높은 실패 비중을 유지한다 | In progress | 52% | 장기 boss pool 재검증 |
| UI/UX/game feel | 카드/타일/정산/마켓 액션이 게임적인 연출로 읽힌다 | In progress | 45% | post-contest 조작감/표시 결함 안정화 |
| Roguelite meta | 게임오버 이후 기억 카드 보상으로 다음 run 선택지가 열린다 | In progress | 38% | 보상/도감/새 run CTA 체감 QA |
| Run restart loop | 패배/클리어 후 실제 보상 획득, 도감 반영, 새 run 시작이 자연스럽게 이어진다 | In progress | 42% | 자연 진행 full end-to-end QA |
| QA/release gate | 웹/모바일에서 저장, 복구, 애니메이션, 경제가 깨지지 않는다 | In progress | 35% | post-contest smoke baseline 재수립 |
| Analysis/documentation governance | 레벨링/경제/ML/출품 문서가 한 기준으로 읽히고 작업 순서가 흔들리지 않는다 | In progress | 42% | 공모전 off와 post-contest 실행 라우터 분리 |

전체 추정 진도: 42%

공모전 제출 트랙: Closed / off. 상세 증거는 `docs/archive/competition_history_2026_06/`에서만 참고한다.

주의:

- 이 퍼센트는 확정 지표가 아니라 현재 증거 기준의 작업 진척 추정치다.
- 큰 설계 변경, 장기 sweep, browser QA, 저장 구조 변경이 생기면 퍼센트는 다시 조정한다.
- 퍼센트는 “작업량”이 아니라 “goal 완성에 필요한 증거가 얼마나 갖춰졌는가”를 기준으로 한다.
- 공모전 제출 퍼센트는 현재 의사결정 지표가 아니다.

## 2. Percent Checklist

| Area | Progress | Evidence | Missing evidence |
|---|---:|---|---|
| Battle rules and scoring | 77% | 전투/정산/보스 제약 다수 구현, fixture와 provider 테스트 존재, S1 entry smoke 개선 | S2~S8 장기 station curve 재검증 필요 |
| Boss modifier runtime/sim pool | 88% | S1~S8 station 난이도 level별 3~4개 seed 기반 boss pool 적용, S4 rank pressure 후보 가중 보정, simulation runtime-station mirror/variant profile 추가, fresh r400에서 S1/S8 boss 실패 유지 | 장기 밸런스에서는 multi-seed/r800 재검증 |
| Market offer and inventory | 71% | Jester/Slots와 Tool/Gear 탭별 리롤 분리, 구매/판매/사용, 슬롯 제한, S1 첫 Market 무료 리롤 보상, stale save guard | 셔플/추가 밸런스 변경 시 재검증 |
| Economy reward and price | 76% | runtime reward/price scale, growth-access price cap, S1 첫 Market 무료 리롤 보상, catalog audit, runtime offer audit, fresh r400 economy audit 즉시 경고 없음 | power none 높음은 known risk, 장기 밸런스에서 재검증 |
| Animation/game feel | 45% | timing 중앙화, 마켓 flight, 정산 reveal 개선 진행 | 게임오버 CTA, 도감 실물 카드 표시, 마켓/전투/정산 시각 연결감 QA |
| Save/restore stability | 65% | active run save/restore, 정산 cash-out 복구 검증 이력 | 새 meta/gameover loop 추가 시 재검증 |
| Roguelite meta growth | 38% | 기억 카드 보상 표시, high stakes 해금, 기억 카드 획득 이력, 마켓/구매/Boss/Station 수집형 도감 저장 | 보상이 다시 시작 욕구를 만드는지 시각/문구 QA, unlock tree 확장, 항목별 상태 UI |
| Game over reward loop | 42% | RunProgressionService 보상 산식, 내부 meta reward 저장, 기억 카드 획득 이력, 게임오버 `새 run 준비` CTA, 도감 반영 | 자연 진행 full end-to-end QA, 게임오버 화면의 재도전 유도력 QA |
| Integrated QA | 35% | 단위 테스트, 이전 웹 빌드, S1/S8 smoke, 최종 보스/패배 루프 browser QA, 수집 저장 테스트 | 최신 변경 후 전체 smoke/web build/browser QA 재실행, debug fixture 없는 자연 QA |
| Analysis/ML documentation | 64% | source split 검증과 sequence/path 후보 선별 보조 신호 존재 | ML 갱신은 보류, production 자동 적용 금지 |

## 3. 장기 레벨링/경제/ML 요약

장기 Goal 관점의 현재 판단:

- S1~S8 runtime target은 2026-05-19 post-contest 로그형 상향 표로 교체됐다.
- `challenge`는 1.5배 target과 standard S8 클리어 기반 carryover 구조로 설계/적용됐다.
- `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1`은 이전 handoff 후보였지만 장기 밸런스 완료가 아니다.
- `power none`이 일부 seed에서 목표보다 높고, `balanced v9`가 한 seed에서 목표 60%를 살짝 밑돈다.
- 경제/가격/market availability는 즉시 경고는 없지만 장기 gate를 닫지 않는다.

ML/분석 상태:

- 현재 런타임 레벨링은 실제 머신러닝이 자동 조정하지 않는다.
- 현재 기준은 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 휴리스틱 라벨, 사람 승인 절차다.
- 기존 `analysis/leveling/` feature table과 model 결과는 active workspace에서 제거하고 archive로 내렸다.
- 과거 ML/시뮬레이션 데이터는 현재 runtime/catalog/ruleset/bot policy 기준 fresh row로 재검증되기 전까지 현재 수치 판단이나 추천 결론의 직접 근거로 쓰지 않는다.
- 새 ML/레벨링 데이터셋은 archive 데이터를 이어붙이지 않고 fresh simulation row부터 다시 누적한다.
- ML 갱신과 NotebookLM 보고서/인포그래픽 재생성은 모델/데이터 기준이 실무 사용 수준에 도달하기 전까지 보류한다.
- production ML 또는 runtime 자동 적용 표현은 계속 금지한다.

상세 근거 위치:

- 레벨링 적용 상태: `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`
- 경제/가격/리롤 probe: `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md`
- 휴리스틱/시뮬레이션 진입 요약: `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`
- 과거 순서 lock snapshot: `docs/archive/planning_legacy_2026_05/TEMP_WORK_SEQUENCE_PLAN.md`

## 4. Closed Competition Track

공모전 제출 트랙은 `Closed / off`다. 2026-05-15 12시경 최종 산출물을 우선 등록했고, 이후 공모전 문서는 현재 작업 큐가 아니라 제출 이력과 증거 확인용으로만 본다.

요약:

- `ko`, `en` 표준/도전 S1~S8 Boss full-run과 최신 `ko` 재확인을 통과했다.
- 제출 전 상점 회귀, 용어 UX, web BGM, 정산 overlay, 튜토리얼, 도감/보상/새 run 복귀 관련 주요 결함은 당시 기준으로 닫았다.
- `ja`, `zh-CN`, `zh-TW` full-run과 S9+ 장기 생존은 제출 gate가 아니라 필요 시 여는 추가 검증 후보다.
- 상세 로그, bot 조건, 제출 증거는 `docs/archive/competition_history_2026_06/COMPETITION_SUBMISSION_CHECKLIST.md`와 `docs/planning/ACTIVE_EXECUTION_PLAN.md`의 공모전 이력 섹션에서만 참고한다.

현재 Goal 판단에는 공모전 퍼센트나 출품 일정표를 쓰지 않는다. 이후 작업은 post-contest 런타임 고도화, 장기 밸런스, meta growth, 자연 full-play QA 기준으로 수렴한다.

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
| Game over reward feedback | 패배 종료 시 기억 카드 획득 보상 카드와 `새 run 준비` CTA 표시. 기억 카드 획득 이력과 도감 반영 저장 | `lib/views/game/widgets/game_shared_widgets.dart`, `lib/services/run_unlock_state_service.dart`, `test/views/game/game_view_test.dart`, `test/services/run_progression_service_test.dart` |
| Archive collection loop | 마켓 노출/구매/Boss/Station/기억 카드 이력을 저장하고 도감에 실제 Jester/Item 카드 face로 표시 | `lib/views/archive_view.dart`, `test/views/archive_view_test.dart` |
| Final run completion | S8 boss 정산 후 런 완료 또는 계속 진행을 선택할 수 있음 | `lib/views/game_view.dart`, `lib/views/game/widgets/game_cashout_widgets.dart`, `test/views/game/widgets/game_cashout_widgets_test.dart` |
| Background lifecycle | 게임/마켓 background pause, 복귀 옵션 dialog, BGM resume 보강 | `lib/views/game_view.dart`, `lib/views/game/widgets/game_shop_screen.dart`, `lib/resources/sound_manager.dart` |
| Save/restore | active run 저장/복원, 정산 중 종료 후 cash-out 복구 확인 | `lib/services/active_run_save_service.dart`, debug fixture tests |
| Boss modifiers | 색상/라인/face/all-score/first-confirm/confirm-count/repeat/single rank 계열 구현 | `lib/services/blind_selection_setup.dart`, `lib/logic/rummi_poker_grid/jester_meta.dart` |
| Runtime boss pool | S1~S8 station level boss pool 적용 | `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` |
| Market policy | station band rarity/tag weight, missing growth exposure, high-stakes market pressure 적용 | `RummiStationBandMarketPolicy`, `RummiMarketRuntimeFacade` |
| Economy runtime | reward 0.40 번역, 정수 `11/5` effective price scale 적용 | `RummiEconomyConfig`, catalog JSON |
| Economy tooling | economy trace, gated known cost, reroll/slot/sell proxy, catalog value audit, runtime offer audit 추가 | `tools/sim/economy_audit.py`, `tools/sim/catalog_value_audit.py`, `tools/sim/runtime_market_offer_audit.dart` |
| Leveling docs | current policy/runtime spec/simulation baseline/applied status 문서화 | `docs/current_system/`, `docs/planning/leveling/LEVELING_APPLIED_STATUS.md` |
| Goal workflow | 자동 진행 예외, 실험 수렴 규칙, 전체 진도표 규칙 추가 | `AGENTS.md`, `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` |

최근 완료된 경제/레벨링 흐름:

- `reward 0.40 / price 2.2 / catalog_normalized_v1` runtime economy 기준 적용.
- `high_stakes` target 1.04 / reward 1.12 / market pressure profile 적용.
- no-growth gate r120 확인: baseline no-growth는 S3부터 명확히 막히는 방향.
- 성장 route 문제 확인: S4~S8, 특히 S7/S8이 아직 너무 쉬울 수 있어 economy 기준선 후 재검증 필요.
- catalog audit를 runtime effective price 기준으로 보정.
- runtime offer audit로 watchlist 후보가 실제 offer에 노출되는지 확인.

## 6. Milestone Plan

### M0. Documentation And Analysis Source Of Truth

Status: In progress / source-of-truth cleanup still open

완료 조건:

- `docs/current_system/`과 `docs/planning/`의 current 문서가 서로 충돌하지 않는다.
- 과거 실험과 폐기 후보는 `docs/archive/`에서만 historical context로 읽힌다.
- ML/휴리스틱/시뮬레이션/경제/출품 문서의 source-of-truth가 명확하다.
- `analysis/leveling/`은 실제 ML 완료가 아니라 스캐폴딩으로 표시된다.

현재 남은 일:

- `START_HERE.md`의 먼저 읽을 문서와 Source of Truth를 현재 문서 체계와 맞춘다.
- 문서 inventory 작성: `docs/archive/planning_superseded/DOCUMENTATION_CONSOLIDATION_PLAN.md` 기준.
- current 문서와 archive 문서의 경계 정리.
- 중복 planning 문서 통합 또는 archive 이동은 `START_HERE.md` 참조와 필요한 내용 승격을 확인한 뒤 진행한다.
- 다음 작업 큐가 `OVERALL_GOAL_PROGRESS.md` 기준으로 읽히도록 갱신하되, 실제 ML 이행을 공모전 작업 앞에 유지한다.

### M0.5. Actual ML Leveling Transition

Status: Closed for offline ML handoff / production auto-balancing disabled

완료 조건:

- feature table을 outcome-derived summary feature가 아니라 추천 가능한 pre-outcome feature 중심으로 재설계한다.
- supervised target, train/test split, baseline model, metric을 명시한다. 회귀 모델은 MAE/RMSE/R2를 함께 기록한다.
- baseline model 결과와 feature importance를 사람이 읽을 수 있는 MD 리포트로 남긴다.
- 모델 후보는 런타임 자동 적용이 아니라 후보 추천으로만 사용한다.
- 추천 후보는 재시뮬레이션으로 검증하고, 사람 승인 전에는 target/boss/market/economy runtime에 반영하지 않는다.
- 모델 지표가 실무 추천 기준에 충분히 좋아야 recommendation gate 완료로 인정한다.

완료:

- broader target/economy candidate grid를 만들었다.
- station/tier `clear_rate` 모델과 sequence/path `path_clear_rate` 모델을 학습했다.
- 모델 추천표를 생성했다.
- target/economy 후보를 fresh r80으로 재시뮬레이션했다.
- 사람 승인용 MD 보고서를 작성했다.
- runtime 값은 바꾸지 않았다.
- pre-outcome feature table을 248,248 source rows로 증량하고, station/tier 모델에 boss/market/economy 상호작용, 실제 target score, reward/resource pressure feature를 추가했다.
- 모델 반복 실행 비용을 줄이기 위해 큰 데이터 baseline tree 수와 `n_jobs=2`를 조정했다. `run_count`는 feature가 아니라 학습 가중치로만 쓴다.

남은 주의:

- station/tier smoothed 모델은 random split R2 0.9037이지만 source-path split R2 0.5264라 구간 위험 힌트 전용이다.
- sequence/path 모델은 random split R2 0.9014, source-path split R2 0.8408로 후보 선별 보조 신호다.
- `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1` r400 multi-seed가 v9 >= none을 만족했고, sequence/path 추천표에서도 fresh gate와 ML gate를 모두 통과했다.
- production ML 자동 적용은 여전히 아니다. 다음 모델 재생성 때도 MAE/RMSE/R2를 모두 기록하고, 실무 기준 충족 여부를 별도로 판단한다.

### M1. Economy And Price Baseline

Status: In progress

완료 조건:

- runtime effective price 기준 catalog audit가 통과한다.
- watchlist 후보의 조정/보류 판단이 문서화된다.
- 가격 변경은 1차에서 1~2개 이하로 제한한다.
- r120~r400 probe에서 `shop_slot_market_v9`가 none보다 부당하게 낮아지지 않는다.

현재 남은 일:

- `slot_sell_v1`은 목표 clear에 도달했지만 v9 final gold 평균이 16~24G로 올라간다. 리롤 비용을 완전히 제거할지, 첫 리롤/조건부 할인/아이템 보강으로 옮길지 정책 영향 검토가 남아 있다.
- `first_reroll_free_v1` r400은 v9 final gold가 balanced 8.0G, power 11.2G라 경제적으로 더 안전하지만, balanced v9가 54.5%라 목표 60%에 못 닿는다. 다음 후보는 리롤 비용만이 아니라 후반 성장 후보 접근성과 구매 선택 조건을 같이 본다.
- 후반 후보 접근성 실험 결과, `v15/v16 + first_reroll_free_v1`은 power에는 도움이 되지만 balanced를 안정적으로 60% 이상으로 올리지 못했다. 지금 문제는 “후보가 아예 안 보임” 하나가 아니라 “필요 후보가 보여도 balanced가 살 수 있는 가격/타이밍”까지 같이 묶인 문제다.
- 최신 runtime 기준 `growth_access_v1 + first_reroll_free_v1 + affordable_alternative_v2` r400에서 none balanced 48.8%, none power 54.8%, v9 balanced 60.5%, v9 power 69.8%가 나왔다. 성장 후보 가격 상한은 이미 runtime에 있다. 단, 제품 UI 기준 첫 리롤 무료는 “상점마다 무료”가 아니라 S1 기본 첫 Market 이용 보상 1회로 잠갔다. 아이템/패시브 리롤 할인은 별도 할인으로 표시한다. 이 항목은 ML 재학습/추천표 갱신 전까지 “runtime 적용 후 검증 완료, ML 반영 대기” 상태다.
- 셔플 검토 참고 자료를 확인했다. 현재 방향은 Fisher-Yates/seed 기반 셔플 유지가 기본이며, Bag/Pity/Smart shuffle은 레벨링과 경제를 바꾸는 별도 룰 후보로만 검토한다.

### M2. S1~S8 Leveling Curve

Status: Next

완료 조건:

- S1은 막 플레이하지 않는 이상 대부분 통과한다.
- S2는 성장이 있으면 쉽고, 성장이 없으면 간신히 통과한다.
- S3부터 no-growth는 명확히 막힌다.
- S4~S6은 성장 선택을 점차 검증한다.
- S7~S8은 clear 비중이 낮은 고난도 구간이다.

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

분리 원칙:

- 예정 연출 큐 마무리는 장기 밸런스/경제/ML 재검증과 같은 트랙으로 묶지 않는다.
- 연출 작업은 transient presentation state와 `GamePresentationTimings`/`GamePresentationCue` 정리, browser/compute 눈검증 기준으로 별도 완료 처리한다.

### M4. Roguelite Meta Growth

Status: In progress

완료 조건:

- 게임오버 또는 클리어 후 run 결과가 meta reward로 변환된다.
- meta reward는 다음 run의 선택지를 열지만, 인런 자동 지급으로 유저 선택을 대체하지 않는다.
- 해금/성장으로 blind target, reward, market profile, run modifier가 어떻게 변하는지 명시된다.
- 성장에 따른 레벨링 보정은 명시적 run modifier나 해금 선택으로만 적용한다.

현재 남은 일:

- 현재 최소 구현은 기억 카드 보상, high stakes 해금, target/reward modifier preview까지 존재한다.
- 남은 일은 해금 선택 폭 확장과, 보상이 다음 run 난이도를 무효화하지 않는지 검증하는 것이다.
- 공모전 기준으로는 새 레벨링 수치 조정보다 게임오버/런 완료 후 보상 반영과 새 run 복귀 QA를 먼저 닫는다.

### M5. Game Over Reward Loop

Status: In progress

완료 조건:

- 패배 원인, 도달 Station, boss clear, 획득 성장에 따라 보상이 산정된다.
- 보상은 다음 run으로 돌아가는 흐름을 만든다.
- 패배 보상이 과도해 난이도를 무효화하지 않는다.
- 저장/복구와 충돌하지 않는다.

현재 남은 일:

- 패배 후 보상 확인, Title 복귀, 새 run 화면의 기억 카드/해금 상태 반영을 browser/compute QA로 확인한다.
- S8 boss 완료 후 `런 완료`와 `계속 진행` 분기, Title 복귀, S9+ 진입을 browser/compute QA로 확인한다.
- 회차 결과 보상 산식이 도달 Station, boss clear, 클리어 여부 기준으로 계산되고, 직접 지급/자동 성장 강제가 아닌 선택지 해금으로만 이어지는지 확인한다.
- high stakes 같은 회차 선택 modifier가 UI preview, runtime target/reward, 저장/복원에서 같은 값으로 이어지는지 확인한다.

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
