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
| Core battle strategy | 보드/손패/확정/버림 선택이 매 전투마다 의미 있게 갈린다 | In progress | 67% | 출품용 S1 entry 낮춤 후 S2~S8 curve 재검증 |
| Market deckbuilding | 후보 노출, 구매, 판매, 장착, 사용이 성장 선택의 중심이 된다 | In progress | 61% | 가격/보상/노출 기준선 정리 |
| Economy leveling | 골드 보상과 가격이 선택 부담을 만들되 좋은 플레이를 부당하게 막지 않는다 | In progress | 59% | 공모전 임시 handoff 가능, power none 높음은 known risk |
| Boss pressure | 후반 보스가 높은 난도를 만들며 S7~S8은 높은 실패 비중을 유지한다 | In progress | 52% | 공모전 기준 boss pool 고정 후 QA |
| UI/UX/game feel | 카드/타일/정산/마켓 액션이 게임적인 연출로 읽힌다 | In progress | 45% | 공모전 시각/조작감 재점검 |
| Roguelite meta | 게임오버 이후 기억 카드 보상으로 다음 run 선택지가 열린다 | In progress | 38% | 보상/도감/새 run CTA 체감 QA |
| Run restart loop | 패배/클리어 후 실제 보상 획득, 도감 반영, 새 run 시작이 자연스럽게 이어진다 | In progress | 42% | 자연 진행 full end-to-end QA |
| QA/release gate | 웹/모바일에서 저장, 복구, 애니메이션, 경제가 깨지지 않는다 | In progress | 35% | 최신 변경 후 submission candidate 재생성 |
| Analysis/documentation governance | 레벨링/경제/ML/출품 문서가 한 기준으로 읽히고 작업 순서가 흔들리지 않는다 | In progress | 42% | ML 보류와 공모전 재개 기준 분리 |

전체 추정 진도: 42%

출품용 프로토타입 추정 진도: 58%

주의:

- 이 퍼센트는 확정 지표가 아니라 현재 증거 기준의 작업 진척 추정치다.
- 큰 설계 변경, 장기 sweep, browser QA, 저장 구조 변경이 생기면 퍼센트는 다시 조정한다.
- 퍼센트는 “작업량”이 아니라 “goal 완성에 필요한 증거가 얼마나 갖춰졌는가”를 기준으로 한다.
- 출품용 프로토타입 퍼센트는 전체 완성이 아니라, 심사자가 플레이 가능한 핵심 vertical slice를 기준으로 한다.

## 2. Percent Checklist

| Area | Progress | Evidence | Missing evidence |
|---|---:|---|---|
| Battle rules and scoring | 77% | 전투/정산/보스 제약 다수 구현, fixture와 provider 테스트 존재, S1 entry smoke 개선 | S2~S8 장기 station curve 재검증 필요 |
| Boss modifier runtime/sim pool | 88% | S1~S8 station 난이도 level별 3~4개 seed 기반 boss pool 적용, S4 rank pressure 후보 가중 보정, simulation runtime-station mirror/variant profile 추가, fresh r400에서 S1/S8 boss 실패 유지 | 장기 밸런스에서는 multi-seed/r800 재검증 |
| Market offer and inventory | 70% | Jester/Slots와 Tool/Gear 탭별 리롤 분리, 구매/판매/사용, 슬롯 제한, 첫 리롤 무료 runtime 적용 | 셔플/추가 밸런스 변경 시 재검증 |
| Economy reward and price | 76% | runtime reward/price scale, growth-access price cap, 첫 리롤 무료, catalog audit, runtime offer audit, fresh r400 economy audit 즉시 경고 없음 | power none 높음은 known risk, 장기 밸런스에서 재검증 |
| Animation/game feel | 45% | timing 중앙화, 마켓 flight, 정산 reveal 개선 진행 | 게임오버 CTA, 도감 실물 카드 표시, 마켓/전투/정산 시각 연결감 QA |
| Save/restore stability | 65% | active run save/restore, 정산 cash-out 복구 검증 이력 | 새 meta/gameover loop 추가 시 재검증 |
| Roguelite meta growth | 38% | 기억 카드 보상 표시, high stakes 해금, 기억 카드 획득 이력, 마켓/구매/Boss/Station 수집형 도감 저장 | 보상이 다시 시작 욕구를 만드는지 시각/문구 QA, unlock tree 확장, 항목별 상태 UI |
| Game over reward loop | 42% | RunProgressionService 보상 산식, 내부 meta reward 저장, 기억 카드 획득 이력, 게임오버 `새 run 준비` CTA, 도감 반영 | 자연 진행 full end-to-end QA, 게임오버 화면의 재도전 유도력 QA |
| Integrated QA | 35% | 단위 테스트, 이전 웹 빌드, S1/S8 smoke, 최종 보스/패배 루프 browser QA, 수집 저장 테스트 | 최신 변경 후 전체 smoke/web build/browser QA 재실행, debug fixture 없는 자연 QA |
| Analysis/ML documentation | 64% | source split 검증과 sequence/path 후보 선별 보조 신호 존재 | ML 갱신은 보류, production 자동 적용 금지 |

## 3. Current Focus

현재 집중 축:

1. Boss pool mapping 및 1차 확장: S1~S8 station 난이도 level별 3~4개 seed 기반 runtime boss pool과 simulation mirror profile 적용. 새 저장 schema 없이 기존 blind boss modifier 저장 경로 재사용
2. 확장 boss pool 기준 레벨링/경제 probe: S4 rank pressure 후보 가중 + growth-access price cap + 첫 리롤 무료 기준에서 v9가 대체로 none보다 높고, economy audit 즉시 경고가 없어 공모전 기준 임시 handoff 가능
3. 공모전 기준 재정비: ML은 production/자동 적용이 아니므로 잠시 보류하고, runtime/economy/boss pool 기준으로 vertical slice QA를 재개한다.

현재 경제 판단:

- `reroll_token`은 runtime effective price 기준 자기 회수형이 아니다.
- `trade_ticket`, `ride_the_bus`는 watchlist로 유지하되 즉시 가격 변경은 보류한다.
- `jester_hook`은 효과 대비 effective price가 너무 높아 base 7G로 낮췄다.
- r400 경제 probe에서 `jester_hook` 가격 조정은 즉시 부작용이 없고, `shop_slot_market_v9`는 balanced/power 모두 none보다 clear를 떨어뜨리지 않았다.
- 출품용 프로토타입 기준 경제 baseline은 `good enough`로 잠그고, S7/S8 난이도는 boss/target/market availability sweep으로 별도 조정한다.
- Jester/Slots와 Tool/Gear lane reroll 분리 이후 current boss pool 기준 r400 raw probe는 balanced none 50.0%, balanced v9 57.0%, power none 64.2%, power v9 63.5%였다. v9 final gold avg 약 6.24G, v9 S8 boss 시작 골드 약 9.43G, reroll spend 99,571G, unaffordable event 7,686회로 즉시 경고는 없지만, boss pool 확장 전 기준이라 최종 경제 gate는 아니다.
- 확장 boss pool `confirm_limit_tax_v1` profile 기준 r400 raw economy probe는 balanced none 49.8%, balanced v9 56.0%, power none 59.0%, power v9 58.8%였다. v9 final gold avg 약 6.45G, v9 S8 boss 시작 골드 약 9.4G, reroll spend 98,470G, unaffordable event 7,474회로 즉시 경고는 없지만, power v9 미세 역전이 있어 최종 경제 gate는 아니다. seed 기반 runtime pool 적용 후 재검증이 필요하다.
- runtime station pool 기준 r400 leveling probe는 balanced none 48.0%, balanced v9 67.2%, power none 54.0%, power v9 66.0%로 v9가 none보다 높다. S8/S1/S3/S4 병목은 남아 있다.
- 같은 runtime station pool의 economy r400은 balanced none 48.5%, balanced v9 48.2%, power none 56.8%, power v9 56.8%였다. v9 final gold avg 약 6.23G, v9 S8 boss 시작 골드 약 9.48G, reroll spend 96,307G, unaffordable event 7,185회로 즉시 경제 경고는 없지만, v9가 clear를 올리지 못하므로 경제 gate는 닫지 않는다.
- runtime station pool market availability r80에서 balanced는 none 57.5%, v9 48.8%, v11 53.8%, v13 52.5%이고, power는 none 62.5%, v9 63.7%, v10 67.5%, v12 66.2%였다. 단일 availability profile로 balanced/power를 동시에 해결하지 못하므로 다음은 S4~S8 role band와 boss severity 위치를 분리한다.
- S4~S8 role band 분리 r80도 같은 방향이었다. balanced는 none 57.5% 대비 v9 48.8%, v10 48.8%, v11 53.8%, v12 50.0%, v13 52.5%로 모두 낮고, power는 v10 67.5%, v12 66.2%가 올랐지만 v13 43.8%는 크게 낮다. 단일 market profile로 gate를 닫지 않는다.
- boss severity placement 분리 r80에서는 `single_rank S4`가 balanced none 57.5%, balanced v9 58.8%, power none 68.8%, power v9 81.2%로 가장 강하지만 과보정 watch다. `confirm_limit S5`는 balanced none 46.2%, balanced v9 55.0%, power none/v9 56.2%로 balanced 회복 후보지만 power 개선은 없다. 둘 다 후속 r120 후보이며 runtime 값은 바꾸지 않는다.
- sim-only `shop_slot_market_v14`를 추가해 S4+ missing-growth와 직전 board/draw 실패 구간 보강을 조건부로 묶어 봤다. r120 확인에서 balanced none 53.3%, v9 49.2%, v14 51.7% / power none 58.3%, v9 60.0%, v14 59.2%로 v9 대비 balanced는 회복했지만 strict gate인 balanced v14 >= none은 통과하지 못했다. runtime 적용은 금지하고, market 단독 해결 대신 boss placement/market 조합의 seed 안정성을 더 봐야 한다.
- 기존 조건형 profile 검토에서는 `banded_candidate_pool_v2`가 runtime station pool 기준 balanced 59.2%, power 62.5%로 none 대비 balanced를 올리고 power를 유지했다. `confirm_limit S5 + banded_v2`는 balanced 59.2%, power 70.8%로 양쪽을 올렸고 S8/board/draw 병목도 남겼지만, banded/state profile은 shop-slot lane 경제와 1:1 대응되지 않는다. 다음 후보는 이 조건을 shop-slot 구조로 옮긴 sim-only profile이며 runtime 값은 아직 바꾸지 않는다.
- sim-only `shop_slot_market_v15`는 현재 상황을 보고 상점 후보를 고르는 실험이다. 하지만 runtime station pool r80에서 none은 balanced 51.2%, power 57.5%였고, v15는 balanced 50.0%, power 56.2%로 둘 다 낮았다. `single_rank S4`, `confirm_limit S5`와 섞어도 같은 boss 조건의 none보다 낮아 runtime 적용 후보가 아니다.
- 쉬운 판단: 지금 문제는 상점 후보만 조금 더 똑똑하게 고르면 끝나는 문제가 아니다. S1 boss와 S8 boss가 같이 남고, 실패 원인도 board full과 draw exhausted가 같이 남으므로 boss 배치, target, market 후보가 서로 충돌하는 부분을 줄여야 한다.
- S1/S8 target split r80에서는 초반 보스만 5% 낮춰도 v9가 거의 회복되지 않았다. 마지막 보스만 5% 낮추면 v9 balanced 43.8% -> 46.2%, power 51.2% -> 53.8%로 조금 오르지만, 기준 none balanced 52.5%, power 60.0%보다 낮다. 다음은 target 한 곳 낮춤이 아니라 v9 상점 선택이 중간/후반 boss에서 무엇을 잘못 고르는지 본다.
- market choice split r80에서 최종 재선택을 끄면 v9 balanced는 43.8% -> 48.8%로 좋아지지만 power는 51.2% -> 50.0%로 낮다. v15는 balanced 57.5%로 기준을 넘지만 power 45.0%로 무너진다. 다음 후보는 market profile을 더 키우는 것이 아니라, 최종 구매 선택도 현재 상태와 성장 route를 보게 하는 sim-only `affordable_alternative_v2`다.
- bot/proxy 확인: `planner_v2`는 전투 배치/확정/버림을 고르는 봇이고, 상점 구매는 별도 proxy가 처리한다. `average_market_choice_v1`로 비싼 구매와 슬롯 교체를 피하게 해도 v9 balanced 46.2%, power 51.2%라 기준 none 52.5%/60.0%보다 낮다. 다음은 상점 proxy뿐 아니라 전투 bot의 보드 정리/낮은 점수 확정 판단도 같이 본다.
- 첫 실무 후보: `single_rank S4 + growth_access_v1` r400에서 기준 none은 balanced 51.7%, power 57.8%였고, v9는 balanced 58.0%, power 62.5%, v15는 balanced 59.2%, power 60.5%였다. 경제 감사에서도 v9/v15 final gold 평균 약 6G, 즉시 경고 없음. 아직 runtime 적용 완료가 아니라 seed 재현, feature 재생성, ML/리포트 갱신이 남아 있다.
- 최종 runtime handoff 후보: `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1` r400에서 none은 balanced 47.5%, power 53.8%이고, v9는 balanced 52.0%, power 57.0%다. v9 final gold 평균 약 5.86G, v9 S8 boss 시작 약 9.98G, 즉시 경제 경고 없음. S1/S8 boss와 board/draw 실패가 남아 후반 난도도 유지된다.
- S1은 출품용 입구 안정성을 우선해 target 240/264/265와 red dampener 35% 감소로 낮췄다. r240 smoke에서 S1 path는 94.2~95.0%이며, 후반 S8 병목은 남아 있다.

현재 ML/분석 판단:

- 현재 런타임 레벨링은 실제 머신러닝이 자동 조정하지 않는다.
- 현재 기준은 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 휴리스틱 라벨, 사람 승인 절차다.
- `analysis/leveling/`의 pre-outcome feature table과 tree ensemble 결과는 planned transition scaffold다.
- `analysis/leveling/reports/preoutcome_candidate_resimulation_report.md`가 baseline metric과 r120 후보 재시뮬레이션을 연결한다.
- production ML 자동 적용은 하지 않는다. random split 기준은 낙관적이었으므로, 이번 ML은 sequence/path 후보 선별 보조 신호와 fresh r400+ 검증을 묶어 쓴다.
- pre-outcome feature table은 297,051 source rows로 재생성했다.
- station/tier random split은 MAE 0.0206, RMSE 0.0608, R2 0.9004이고, source-path split은 MAE 0.0487, RMSE 0.0952, R2 0.7265이다. 구간 위험 힌트로만 사용한다.
- sequence/path random split은 MAE 0.0480, RMSE 0.0816, R2 0.9154이고, source-path split은 MAE 0.0560, RMSE 0.1055, R2 0.8482이다. 후보 선별 보조 신호로 사용한다.
- 최신 runtime 후보 `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1 + first_reroll_free_v1 + affordable_alternative_v2`의 기존 r400은 none balanced 48.8%, none power 54.8%, v9 balanced 60.5%, v9 power 69.8%다.
- 2026-05-07 fresh r400 재확인에서는 seed별로 none balanced 49.5~51.5%, none power 58.8~62.0%, v9 balanced 59.0~65.2%, v9 power 65.0~68.0%다.
- 쉬운 판단: 좋은 상점 선택인 v9는 대체로 none보다 높고, S1/S8 boss와 board/draw 실패가 남는다. 다만 power none이 목표보다 높고 balanced v9가 한 seed에서 60%를 살짝 밑돌아 장기 밸런스 완료가 아니라 공모전 기준 임시 handoff로 둔다.
- ML 갱신과 NotebookLM 보고서/인포그래픽 재생성은 보류한다. production ML/자동 적용 표현은 계속 금지한다.

임시 작업 순서 플랜 처리:

- `docs/planning/TEMP_WORK_SEQUENCE_PLAN.md`는 아직 삭제 대상이 아니다.
- ML 표현 감사/정정, 텍스트 줄바꿈 정책, `START_HERE.md` 기준 문서 점검은 완료됐다.
- 실제 ML 이행은 offline candidate recommendation 도구로 사용할 수 있는 수준이지만, 공모전 기준에서는 잠시 보류한다. production ML/자동 적용은 아니다.
- 경제/레벨링/boss pool은 S4 rank weight + growth-access + first-reroll-free runtime handoff 후보 기준으로 공모전 임시 handoff 가능하다.
- 공모전 기준 작업은 재개 가능하다. 단, `power none` 높음과 balanced v9 seed 편차는 known risk로 둔다.

## 4. Competition Prototype Track

목표: `2026-05-14 15:00 KST` BIC 일반부문 1차 접수용 플레이 가능 빌드.

상세 제출 준비 체크리스트는 `docs/planning/COMPETITION_SUBMISSION_CHECKLIST.md`를 기준으로 진행한다. 이 문서는 전체 진도와 gate 상태만 갱신한다.

공식 접수 안내 기준:

- 일반부문 접수 기간: `2026-04-08` ~ `2026-05-14`
- 접수 시작/마감시간: 오후 3시 KST
- 실행 가능한 게임 빌드 제출 필수
- 접수 마감 이후 빌드 업데이트 불가

출품용 프로토타입은 전체 goal 100%가 아니라 아래 조건을 잠그는 것을 목표로 한다.

| Gate | Prototype target | Status | Progress |
|---|---|---|---:|
| Playable vertical slice | 새 run 시작 -> 전투 -> 마켓 -> 보스 -> 정산/패배 -> 실제 보상 -> 도감/새 run 복귀 흐름이 끊기지 않는다 | In progress | 62% |
| Strategy readability | 타일/카드/아이템/보스 제약이 설명 없이도 선택 부담으로 읽힌다 | In progress | 55% |
| Economy baseline | 골드와 가격이 과다 지급처럼 보이지 않고, 좋은 플레이는 부당하게 막지 않는다 | In progress | 58% |
| Roguelite loop stub | 게임오버 보상과 다음 run 복귀가 최소 형태로 존재한다 | In progress | 42% |
| Game feel baseline | 마켓/전투/정산/게임오버/도감의 대표 화면이 어색하지 않다 | In progress | 45% |
| Submission QA | 웹 빌드, 저장/복구, 플레이 영상 촬영 가능한 안정성을 확보한다 | In progress | 38% |

출품 모드 작업 원칙:

- 세부 수치 완성보다 큰 구조를 먼저 잠근다.
- 경제/레벨링은 `good enough` 기준으로 닫고, 상세 polishing은 출품 후 트랙으로 분리한다.
- 신규 시스템은 심사용 플레이 흐름을 막는 경우에만 추가한다.
- 5월 12일을 feature freeze로 보고, 5월 13일은 QA/빌드/영상/제출 자료에 둔다.
- 5월 14일은 수정일이 아니라 제출 버퍼로 남긴다.

작업 시간 산정 기준:

- 기본 산정은 하루 8~10시간 실작업 기준이다.
- 현실적인 공모전 대응 기준은 하루 10~12시간 집중 작업 + 야간 자동 실행이다.
- 야간에는 r400/r800 sweep, 경제 probe, ML feature rebuild/train, `flutter test`, `flutter analyze`, `flutter build web`, submission smoke처럼 사람 판단이 적은 작업을 돌린다.
- Boss pool 설계 판단, UI/텍스트/IP 네이밍 최종 결정, 런타임 값 적용 여부, 최종 browser/compute 시각 QA 판정은 사람이 깨어 있을 때 한다.
- 2026-05-06 새벽 기준으로는 08:30 KST 전까지 현재 boss pool 기준 post lane-reroll 경제 raw probe처럼 이후 비교에 쓸 수 있는 자동 작업을 우선 돌린다.

출품용 일정 잠금:

| Date | Gate | Done 기준 |
|---|---|---|
| `2026-05-09` | 구조 잠금 | 새 run, 전투, 마켓, 보스, 정산, 게임오버/런 완료, 기억 카드 보상 루프가 하나의 playable vertical slice로 이어진다. |
| `2026-05-10` | 경제/레벨링 잠금 | S1 입구 안정성, S2~S3 성장 필요 구간, S7~S8 후반 난도를 출품용 smoke로 확인하고 세부 수치 polishing은 분리한다. |
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
- 저장 포맷, UI/피드백 구조, 정산 reward tax line, Jester/Item 비활성 표시가 필요한 boss 후보 적용.

출품용에 포함하는 Boss pool 작업:

- 현재 S1~S8 boss는 station 난이도 level별 3~4개 seed 기반 pool로 확장했지만, 반복 플레이 다양성은 r80/r400 재검증 전이다.
- 참고 원본 보스 패턴은 28개로 확인됐고, 현재 우리 게임은 이를 10개 simulation proxy와 14개 runtime modifier id로 압축해 둔 상태다.
- 공모전용 품질 기준에서는 boss pool 확장을 미루지 않고, 먼저 원본 패턴을 우리 룰로 번역한 매핑표를 만든다.
- 구현은 이름/IP를 가져오지 않고, 색/라인/타일/rank/확정/자원/골드/아이템·Jester 발동 제한 같은 룰 패턴으로 재작성한다.
- 출품 전 1차 목표는 안정성을 해치지 않는 추가 boss modifier 후보를 station level pool 후보로 늘리는 것이다.
- 저장 포맷 변경, 자동 자원 보정, 유저 선택 강제는 금지한다.
- 저장/UI/정산/Jester·Item 비활성 표시가 필요한 나머지 boss 후보는 공모전 이후 적용 후보로 넘긴다.
- 출품 전 boss 작업은 현재 runtime/simulation mirror pool을 기준으로 레벨링/경제 재검증을 닫는 데 집중한다.

출품 전 필수 완료:

- r400 경제 probe로 현재 가격 변경이 부작용을 만들지 않는지 확인. 현재는 공모전 handoff 후보이며 장기 완료는 아니다.
- Boss pool 확장 매핑표와 출품용 1차 추가 범위를 확정한다. 현재 runtime pool은 적용됐지만 최신 브라우저 자연 QA로 체감 난도를 다시 본다.
- `jester_hook` 가격 조정 r400 follow-up은 통과했으므로 추가 가격 후보 확장은 출품 후 polishing으로 넘긴다.
- S1~S8 전체 sweep은 장기 확정용이 아니라 출품 안정성용 최소 판단으로 제한.
- 게임오버 보상 루프는 기억 카드/보상 카드 획득 이력과 도감 반영까지 확인한다. 현재처럼 내부 수치를 카드처럼 표시하는 수준은 placeholder로만 본다.
- 연출은 신규 대형 시스템보다 이미 있는 전투/마켓/정산 대표 액션의 어색함 제거에 집중.
- 도감은 실물 카드 face를 쓰는 방향으로 맞췄지만, 실제 화면에서 카드 크기/밀도/읽힘/수집 욕구가 충분한지 다시 본다.
- 게임오버는 `새 run 준비` CTA를 추가했지만, 패배 직후 재도전 욕구를 만드는 문구/버튼 위계/보상 피드백은 browser QA에서 다시 판단한다.
- `flutter analyze`, 핵심 `flutter test`, `flutter build web`, browser/compute QA를 통과.

최근 QA:

- 2026-05-07 재정정: `COMPETITION_SUBMISSION_CHECKLIST.md`의 도감/보상/end-to-end 항목을 과하게 닫은 것을 되돌렸다.
- 2026-05-07: 도감 수집 저장 1차 구현을 추가했다. `run_unlock_state_v1`에 마켓 노출 Jester/Item, 구매 Jester/Item, 만난 Boss, 깬 Station, 기억 카드 획득 이력을 저장하고 도감의 내 기록 섹션에서 확인한다.
- 2026-05-07: 게임오버 dialog에 `새 run 준비` CTA를 추가해, 패배 후 기록을 남긴 뒤 바로 새 run 준비 화면으로 이동할 수 있게 했다.
- 최신 Browser Use full route QA는 디버그 즉시 클리어와 fixture를 섞은 화면 전환 smoke다. 자연 진행 S1~S8 full-play 검증은 다시 열어 둔다.
- 2026-05-07 재산정: 기능 체크만 기준으로 삼으면 출품용 68%로 보일 수 있지만, 자연 full-play, 최신 web build, 게임오버 재도전 유도력, 도감 심미성, 실제 플레이 영상 안정성이 아직 부족해 출품용 프로토타입 추정 진도를 58%로 낮춘다.

- `c1f7185` 이후 `final_boss_cash_out_ready` fixture를 Chrome/Computer Use로 재검증했다.
- S8 Boss 확정 후 정산 완료 sheet에 `기억 카드 획득`, `계속 진행`, `런 완료`가 표시된다.
- `런 완료` 클릭 후 Title로 복귀하고 이어하기 저장은 비어 있다.
- `계속 진행` 클릭 후 S8 승리 보상/해금을 1회 반영하고 Market을 거쳐 S9 Station Select로 이어진다.
- 새 게임 화면에서는 내부 meta reward 값을 수치 재화로 노출하지 않고 `기억 카드 보유`, `기억 카드 필요`, `기억 카드로 해금`으로 표시된다.
- `game_over_insight_ready` fixture로 Chrome/Computer Use QA를 수행했다.
- 보드 꽉 참 + 보드 버림 0 상태에서 `드로우` 후 게임오버 dialog가 표시되고, `기억 카드 획득` 보상 카드가 보인다.
- `나가기` 후 Title로 복귀하고 새 게임 화면에서 기억 카드/해금 상태가 최신 값으로 보인다.
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

Status: In progress / source-of-truth cleanup still open

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
- 최신 runtime 기준 `growth_access_v1 + first_reroll_free_v1 + affordable_alternative_v2` r400에서 none balanced 48.8%, none power 54.8%, v9 balanced 60.5%, v9 power 69.8%가 나왔다. 성장 후보 가격 상한은 이미 runtime에 있고, 첫 리롤 무료 정책도 runtime에 적용했다. 첫 리롤 무료는 “상점마다 첫 리롤 1회 무료”로 유지한다. 이 항목은 ML 재학습/추천표 갱신 전까지 “runtime 적용 후 검증 완료, ML 반영 대기” 상태다.
- 셔플 검토 참고 자료는 `/Users/cheng80/Desktop/셔플.txt`에서 확인했다. 현재 방향은 Fisher-Yates/seed 기반 셔플 유지가 기본이며, Bag/Pity/Smart shuffle은 레벨링과 경제를 바꾸는 별도 룰 후보로만 검토한다.

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
