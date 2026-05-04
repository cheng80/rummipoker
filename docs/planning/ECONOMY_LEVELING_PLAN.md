# Economy Leveling Plan

> 문서 성격: reward / price leveling execution plan
> 정책 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> 현재 분석 도구: `tools/sim/economy_audit.py`

## 1. 목적

보상 골드, 아이템 가격, Jester 가격, reroll 비용은 target score와 boss constraint만큼 중요한 레벨링 축이다.

기존 v90 장기 sweep은 path clear와 병목을 확인하는 데 유효하지만, 실제 런타임 경제를 충분히 모델링하지 않는다. 따라서 다음 boss/market 장기 sweep을 재개하기 전에 economy leveling gate를 먼저 통과한다.

## 2. 핵심 원칙

- 보상 조정도 레벨링이다. 임시 감각으로 수치를 바꾸지 않는다.
- S1 첫 클리어 보너스 골드 외에는 자동 지급을 추가하지 않는다.
- 아이템/Jester/Pack/Tarot-like/Planet-like는 직접 지급하지 않고, 마켓 후보와 가격/노출로만 다룬다.
- 가격 조정은 특정 성장 루트를 보장하기 위한 수단이 아니다.
- 보상/가격 변경은 path clear, 병목, 구매력, 잔고, missed offer를 같이 보고 판단한다.
- 기존 장기 sweep 결과는 경제 모델이 비어 있던 기준으로 보며, 가격 확정 근거로 단독 사용하지 않는다.

## 3. 현재 관측

`tools/sim/economy_audit.py` 기준 1차 관측:

- common item 평균가: 약 `4.38G`
- common Jester 평균가: 약 `4.27G`
- S1 small 자원 미사용 정산: `39G`
- v90 r800 summary 기반 평균 추정 cashout: 약 `38G`

해석:

- 정산 1회가 common 카드/아이템 약 8장 수준의 구매력이다.
- 현재 “골드가 많다”는 감각은 데이터상 타당하다.
- 다만 기존 sweep은 실제 구매비 차감, 잔고 부족, 판매 회수율, reroll 비용을 path에 반영하지 않으므로 가격 재산정의 직접 근거로는 약하다.

## 4. 측정 지표

경제 레벨링 분석은 아래 지표를 최소 단위로 본다.

| 지표 | 의미 |
|---|---|
| cashout gold by station/tier | 전투 후 실제 구매력의 공급량 |
| reward-to-price ratio | 정산 1회가 평균 item/Jester 몇 장의 가치인지 |
| market offer exposure | 후보가 얼마나 자주 보이는지 |
| purchase event cost | 실제 구매 후보의 비용 분포 |
| missing cost event | sim proxy라 가격을 알 수 없는 구매 이벤트 |
| remaining gold | 구매/리롤 후 남은 골드 |
| missed affordable offer | 후보가 떴지만 슬롯/선택 때문에 사지 않은 경우 |
| missed too expensive offer | 후보가 떴지만 골드 부족으로 못 산 경우 |
| reroll spend | 후보 탐색에 들어간 비용 |
| sell recovery | 기존 카드/아이템 판매로 회수한 골드 |

## 5. 실행 순서

### Phase 1. Economy Audit 고정

목표:

- 현재 카탈로그 가격과 cashout 보상 구매력을 표준 출력으로 만든다.
- 기존 summary-only sweep도 최소한 reward-to-price ratio를 읽을 수 있게 한다.
- raw JSONL이 있으면 purchase event와 cost-null 비율을 읽는다.

완료 조건:

- `tools/sim/economy_audit.py`가 summary-only와 raw JSONL 입력 모두 처리한다.
- `python3 -m py_compile tools/sim/economy_audit.py` 통과.
- 탐색용 raw sweep에서 cost-null 이벤트 비율을 확인한다.

### Phase 2. Sim Economy Layer 설계

목표:

- 실제 런타임처럼 경제를 path simulation에 반영한다.
- 기존 `shop_slot_market_v9`를 공짜 loadout proxy로만 보지 않고, “노출 -> 구매 가능 -> 비용 차감 -> 적용” 흐름으로 검증할 수 있게 한다.

필수 기록:

- station/tier별 시작 골드
- cashout 획득 골드
- offer slot 후보와 가격
- 구매 성공/실패 이유
- reroll 비용과 횟수
- 판매 이벤트와 회수 골드
- station 종료 잔고

설계 gate:

- 이 phase는 sweep 의미를 바꾸므로 구현 전 사용자 승인 대상이다.
- runtime 저장 포맷은 변경하지 않는다.
- sim-only 구조로 먼저 구현한다.

1차 적용:

- `tools/sim/run_balance_sim.dart`에 `trace_only` 경제 원장을 추가한다.
- 기존 battle 결과와 loadout 적용은 바꾸지 않는다.
- 각 battle row에 `sim_economy_trace`를 기록한다.
- sequence summary에 `sim_economy_summary`를 기록한다.
- `tools/sim/economy_audit.py`가 raw JSONL의 sim economy trace를 읽어 cashout, known spend, final gold, unaffordable event를 집계한다.

trace-only probe:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 20 --seed 99200 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --jobs 4 --out-prefix logs/sim/economy_trace_v1_r20`
- audit: `python3 tools/sim/economy_audit.py --summary logs/sim/economy_trace_v1_r20_summary.json --jsonl logs/sim/economy_trace_v1_r20.jsonl --json-out logs/sim/economy_trace_v1_r20_economy_audit.json`
- result: trace-only 평균 최종 잔고가 약 `770G`로 높다.
- interpretation: 기존 sim은 가격/잔고로 path를 제한하지 않으므로, 다음 단계는 별도 gated economy mode로 구매 가능성에 따라 market effect 적용을 제한해야 한다.

### Phase 3. Economy Probe

목표:

- 긴 sweep 전에 짧은 탐색 run으로 구매력 후보를 좁힌다.
- runs를 낮추면 반드시 탐색용으로 표기한다.

최소 비교 후보:

- 보상 scale 후보: `current`, `reward_tight`, `reward_standard`
- 가격 scale 후보: `current`, `price_standard`, `price_high`
- market: `none`, `shop_slot_market_v9`
- loadout: `progression_route_balanced`, `progression_route_power`
- difficulty: `standard`

확인 지표:

- path clear
- avg total turn
- S1/S4/S5/S8 bottleneck
- board locked / draw exhausted
- remaining gold
- missed too expensive offer
- purchase count by category/rarity
- reroll spend

### Phase 4. Economy Long Sweep

목표:

- 탐색 후보 중 1~2개만 기존 장기 sweep 수준으로 재검증한다.

장기 sweep gate:

- 경제 후보가 path clear만 올리는지, 전략 선택 밀도를 유지하는지 확인한다.
- 가격을 올려도 필요한 성장 후보가 “떠도 못 사는 상태”로 과하게 밀리지 않는지 본다.
- 보상을 낮춰도 S1/S4/S5/S8 병목이 hard wall이 되지 않는지 본다.

### Phase 5. Runtime 적용

적용 우선순위:

1. reward formula 조정
2. item/Jester price band 조정
3. reroll cost 조정
4. market availability/weight 조정

주의:

- reward와 price를 동시에 크게 움직이지 않는다.
- 먼저 한 축을 움직이고 probe로 확인한다.
- 실제 수치 변경 전에는 사용자 승인 후 적용한다.

## 6. 현재 보류

- v90 boss runtime cycle 장기 sweep 재개는 economy gate 이후로 미룬다.
- repeat/single rank cycle 편입 sweep도 economy gate 이후로 미룬다.
- Pack/Tarot-like/Planet-like 타입 승격 논의는 economy 모델이 가격을 다룰 수 있게 된 뒤 재개한다.
