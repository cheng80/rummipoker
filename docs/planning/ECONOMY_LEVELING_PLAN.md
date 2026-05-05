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

2차 적용:

- `--sim-economy-mode gated_known_cost`를 추가한다.
- 기본값은 `trace_only`라 기존 sweep 의미는 유지한다.
- `gated_known_cost`에서는 cost를 알 수 없거나 현재 sim 잔고로 살 수 없는 market effect를 적용하지 않는다.
- Jester proxy 후보는 실제 카탈로그 Jester 기준 추정 비용을 붙인다.

gated probe:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 20 --seed 99300 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --sim-economy-mode gated_known_cost --jobs 4 --out-prefix logs/sim/economy_gated_v1_r20`
- audit: `python3 tools/sim/economy_audit.py --summary logs/sim/economy_gated_v1_r20_summary.json --jsonl logs/sim/economy_gated_v1_r20.jsonl --json-out logs/sim/economy_gated_v1_r20_economy_audit.json`
- result: cost-null 이벤트는 크게 줄었지만, 평균 최종 잔고는 여전히 약 `676G`다.
- interpretation: 구매 gating만으로는 부족하다. 보상 scale 또는 가격 scale 후보를 실제 sweep 축으로 추가해야 한다.

3차 적용:

- `--sim-reward-scale`과 `--sim-price-scale`을 추가한다.
- 기본값은 둘 다 `1.0`이다.
- scale은 sim economy 원장과 `gated_known_cost` 구매 가능성에만 반영한다.
- runtime 보상 공식이나 카탈로그 가격은 아직 바꾸지 않는다.

scale probe:

| Probe | Reward scale | Price scale | 1차 해석 |
|---|---:|---:|---|
| `economy_reward034_v1_r20` | 0.34 | 1.0 | 잔고는 크게 줄지만 balanced none clear가 흔들릴 수 있다. |
| `economy_price294_v1_r20` | 1.0 | 2.94 | 가격만 올려도 잔고가 높고, 구매력 조정이 충분하지 않다. |
| `economy_combo045_220_v1_r20` | 0.45 | 2.2 | 단일 축보다 path clear 균형이 덜 흔들리는 1차 후보로 보인다. |

주의:

- r20은 탐색용이며 확정 판단에 쓰지 않는다.
- 평균 최종 잔고는 full path 누적값이므로, 다음 probe에서는 station/tier별 시작 골드와 종료 골드 분포도 함께 본다.
- 다음 탐색은 `reward 0.45 / price 2.2` 주변과 `reward 0.34 / price 1.0` 주변을 r120으로 비교한다.

4차 적용:

- `tools/sim/economy_audit.py`가 raw JSONL의 `sim_economy_trace`를 station/tier별로 집계한다.
- 우선 출력 지점은 `S1 small`, `S4 boss`, `S8 boss`의 시작 골드와 정산 후 골드다.
- `economy_combo045_220_v1_r20` 기준 S1 small 정산 후 평균은 약 `20.9G`, S4 boss 시작 평균은 약 `117.5G`, S8 boss 시작 평균은 약 `245.5G`다.
- 따라서 full path 최종 잔고뿐 아니라 중후반 시작 잔고도 여전히 높다.

r120 economy probe:

| Probe | Reward scale | Price scale | balanced none | balanced v9 | power none | power v9 | 경제 해석 |
|---|---:|---:|---:|---:|---:|---:|---|
| `economy_combo045_220_v1_r120` | 0.45 | 2.2 | 52.5% | 64.2% | 62.5% | 64.2% | S4/S8 시작 잔고가 여전히 높다. |
| `economy_reward034_v1_r120` | 0.34 | 1.0 | 52.5% | 63.3% | 68.3% | 73.3% | 보상만 낮춰도 v9 구매력은 여전히 강하다. |

판정:

- 두 후보 모두 path clear만 보면 즉시 폐기할 정도는 아니다.
- 그러나 `gated_known_cost`에서도 unaffordable event가 거의 없고, S4/S8 시작 잔고가 높다.
- 단순 보상/가격 scale만으로는 경제 압박을 충분히 만들지 못한다.
- 다음은 `market budget behavior`를 모델링한다. 예: market당 구매 개수 제한, reroll spend, slot cap, 보유물 판매 후 구매 여부.

market budget probe:

- mode: `--sim-market-budget-mode station_band_v1`
- budget: early/mid/late market당 `10G / 14G / 18G`
- probe: `economy_budget_v1_r20`
- result: unaffordable event는 생기지만, 알려진 spend가 줄어 중후반 잔고는 오히려 더 높게 남는다.
- interpretation: 단순 지출 예산 제한은 구매 압박을 만들지만 골드 sink가 아니다. 다음은 reroll spend, slot cap, 판매 후 구매 여부를 함께 모델링해야 한다.

5차 적용:

- `--sim-market-spend-mode reroll_slot_sell_v1`을 추가한다.
- 기본값은 `none`이라 기존 sweep 의미는 유지한다.
- `reroll_slot_sell_v1`은 market 진입 전 tier/station band 기반 예상 reroll 비용을 차감한다.
- Jester 슬롯이 가득 찬 상태에서 Jester 계열 후보를 사면, 가장 싼 기존 Jester 판매 회수금을 더하고 Jester 슬롯 cap을 유지한 loadout으로 전투를 돌린다.
- item 계열도 같은 slot family가 가득 찼으면 같은 family의 가장 싼 sellPrice를 회수한다.
- 이 모델은 유저에게 자동 판매를 강제하는 runtime 정책이 아니라, “슬롯이 찼을 때 유저가 판매 후 교체를 선택할 수 있다”는 경제 proxy다.

spend model probe:

- probe: `economy_spend_v1_r20`
- mode: `gated_known_cost`
- scale: reward `0.45`, price `2.2`
- spend mode: `reroll_slot_sell_v1`
- result: 알려진 spend `16039G`, reroll spend `5550G`, sell recovery `352G`, slot replace event `352`.
- result: S4 boss 시작 평균 약 `97.5G`, S8 boss 시작 평균 약 `180.0G`, 최종 잔고 평균 약 `154.1G`.
- path clear: balanced none `65.0%`, balanced v9 `65.0%`, power none `60.0%`, power v9 `70.0%`.
- interpretation: budget cap보다 실제 gold sink 방향은 낫다. 다만 r20 탐색용이고 최종 잔고가 여전히 높아, `reward 0.34/price 1.0`, `reward 0.45/price 2.2`, `reward 0.40/price 2.4` 주변을 spend mode 포함 r120으로 비교한다.

r120 spend model probe:

| Probe | Reward scale | Price scale | balanced none | balanced v9 | power none | power v9 | S4 boss before | S8 boss before | final gold avg | 해석 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `economy_spend_reward034_v1_r120` | 0.34 | 1.0 | 52.5% | 60.8% | 62.5% | 60.8% | 92.1G | 173.4G | 136.5G | 가격이 낮아 구매 압박이 약하다. |
| `economy_spend_combo045_220_v1_r120` | 0.45 | 2.2 | 50.0% | 60.0% | 62.5% | 62.5% | 103.5G | 189.5G | 150.0G | 보상도 높아져 잔고가 더 남는다. |
| `economy_spend_combo040_240_v1_r120` | 0.40 | 2.4 | 50.0% | 57.5% | 64.2% | 61.7% | 82.3G | 152.7G | 121.6G | 잔고는 낮지만 balanced v9 clear가 흔들린다. |

판정:

- `reroll_slot_sell_v1`은 budget cap보다 나은 방향이지만, 여전히 S8 boss 진입 잔고가 높다.
- scale만 더 세게 조이면 clear와 병목이 같이 흔들릴 가능성이 크다.
- 다음은 “가격 전체 배율”이 아니라 rarity/category별 가격 band와 실제 gold sink 누락을 나눠 본다.
- 특히 pack/tarot/planet proxy, voucher proxy, reroll 비용, 판매 회수율이 실제 카탈로그 가격/가치와 맞는지 분리해야 한다.

price band probe:

- `--sim-price-band-mode rarity_category_v1`을 추가했다.
- `--sim-price-band-mode rarity_category_soft_v1`을 추가했다.
- 두 모드 모두 기본값이 아니며 runtime 가격에는 영향이 없다.
- hard band `economy_price_band_v1_r20`: S8 boss 시작 평균 약 `168.1G`, final gold avg 약 `127.6G`, balanced v9 clear `45.0%`, power v9 clear `50.0%`.
- soft band `economy_price_band_soft_v1_r20`: S8 boss 시작 평균 약 `194.1G`, final gold avg 약 `158.5G`, balanced v9 clear `55.0%`, power v9 clear `65.0%`.

판정:

- hard band는 v9 clear를 none보다 낮추는 방향이라 후보 노출을 “떠도 못 사는 상태”로 만들 위험이 있다.
- soft band는 clear 충격은 덜하지만 잔고 압박이 약하다.
- 가격 band 단독 조정은 다음 장기 후보에서 제외한다. 이후에는 실제 구매 후보별 utility/cost 선택 모델과 reroll 빈도, 판매 회수율을 더 현실화한 뒤 재검토한다.

affordable choice probe:

- `--sim-market-choice-mode affordable_alternative_v1`을 추가했다.
- 기본값은 `none`이며 runtime 마켓 선택에는 영향이 없다.
- 이 모드는 shop slot 시장에서 utility 1순위 후보가 비싸더라도, 같은 가판에 있는 구매 가능한 대안 중 utility가 높은 후보를 고른다.
- 이는 “필요 후보가 떴지만 못 사면 전체 market 효과가 사라진다”는 과도한 sim penalty를 줄이고, 실제 유저가 가판에서 대안을 고르는 행동을 모델링하기 위한 proxy다.

| Probe | Reward scale | Price scale | Choice mode | balanced none | balanced v9 | power none | power v9 | S4 boss before | S8 boss before | final gold avg |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| `economy_choice_affordable_v1_r20` | 0.40 | 2.4 | affordable | 30.0% | 55.0% | 50.0% | 70.0% | 77.3G | 136.4G | 111.9G |
| `economy_choice_affordable_v1_r120` | 0.40 | 2.4 | affordable | 52.5% | 70.0% | 63.3% | 67.5% | 78.5G | 142.1G | 121.7G |
| `economy_choice_reward036_price240_v1_r120` | 0.36 | 2.4 | affordable | 55.8% | 70.8% | 66.7% | 61.7% | 70.5G | 129.7G | 106.8G |
| `economy_choice_reward038_price240_v1_r120` | 0.38 | 2.4 | affordable | 54.2% | 65.0% | 63.3% | 67.5% | 75.4G | 138.6G | 116.1G |
| `economy_choice_reward039_price240_v1_r120` | 0.39 | 2.4 | affordable | 55.8% | 60.8% | 64.2% | 66.7% | 77.9G | 146.5G | 121.3G |
| `economy_choice_reward036_price260_v1_r120` | 0.36 | 2.6 | affordable | 57.5% | 64.2% | 68.3% | 66.7% | 70.8G | 131.9G | 108.8G |
| `economy_choice_reward038_price260_v1_r120` | 0.38 | 2.6 | affordable | 50.8% | 65.8% | 69.2% | 68.3% | 75.9G | 139.8G | 116.9G |

판정:

- r120 기준으로 v9가 none보다 명확히 좋은 상태를 유지하면서 S8 boss 진입 잔고를 150G대에서 140G대 초반으로 낮췄다.
- `price 2.6`은 잔고를 낮추지만 power v9가 none보다 낮거나 거의 같아져 시장 성장 보상의 의미가 약해진다.
- `reward 0.36 / price 2.4`는 final gold avg를 약 106.8G까지 낮추지만 power v9가 none보다 낮아져 너무 강하다.
- `tools/sim/economy_audit.py`가 market/loadout별 final gold와 S8 boss market별 시작 골드를 출력한다.
- market별 분리 결과, 전체 final gold avg는 none control의 미사용 골드가 크게 섞인 값이라 경제 gate 판단 근거로 약하다.
- `reward 0.40 / price 2.4`에서 final gold는 none 약 226.1G, v9 약 17.3G다. S8 boss before도 none 약 279.5G, v9 약 22.5G로 갈린다.
- 따라서 현재 장기 후보는 `reward 0.40 / price 2.4 / reroll_slot_sell_v1 / affordable_alternative_v1`을 다시 우선한다. `reward 0.38 / price 2.4`는 v9 잔고를 거의 더 낮추지 못하면서 balanced v9 clear를 70.0%에서 65.0%로 낮춘다.
- 다음은 런타임 적용 전, `reward 0.40 / price 2.4` 후보를 기존 장기 sweep 기준으로 재검증한다. runs를 낮추면 탐색용으로만 기록한다.

long check:

| Probe | runs | balanced none | balanced v9 | power none | power v9 | v9 final gold avg | v9 S8 boss before |
|---|---:|---:|---:|---:|---:|---:|---:|
| `economy_choice_reward040_price240_v1_r800` | 800 | 57.5% | 65.8% | 62.3% | 68.1% | 18.0G | 22.8G |

판정:

- r800에서도 v9는 none보다 clear가 높고, 시장을 사용하는 경로의 최종 잔고는 약 18G로 낮다.
- S8 boss before는 전체 평균 약 144.8G지만, market별로 보면 none 약 279.2G, v9 약 22.8G다.
- `reward 0.40 / price 2.4 / reroll_slot_sell_v1 / affordable_alternative_v1`는 현재 economy sim 후보로 유지한다.
- 이 값은 아직 runtime 적용값이 아니다. runtime 보상/가격 변경은 별도 승인 후 적용한다.

catalog value flags:

- `tools/sim/economy_audit.py`가 `catalog_value_flags`를 출력한다.
- 이 flag는 자동 적용값이 아니라 가격 조정 전 검토 후보만 표시한다.
- `--sim-price-band-mode catalog_value_flags_v1`을 추가했다. flag 후보 일부만 sim-only 가격 상향하는 검증용 band다.
- `economy_choice_reward038_price240_v1_r120` 기준 즉시 회수형 item 후보:
  - `reroll_token`: 3G 구매로 기본 리롤 비용 5G를 대체한다.
  - `coin_cache`: 3G 구매 후 +3G 즉시 회수라 실질 구매 비용이 0G에 가깝다.
  - `thin_wallet`: 조건부지만 5G 구매 후 +5G 회수라 comeback 도구 이상의 순환 골드가 될 수 있다.
- low-price growth Jester 후보:
  - `green_jester`: rare인데 common median 4G와 같은 4G다.
  - `popcorn`, `ice_cream`, `supernova`: stateful growth 계열이 5G라 장기 성장 가치 대비 저렴할 수 있다.
- `catalog_value_flags_v1` r120 결과:
  - `economy_choice_reward038_price240_catalog_flags_v1_r120`: balanced none 53.3%, balanced v9 59.2%, power none 64.2%, power v9 68.3%, S8 boss before 약 137.7G, final gold avg 약 114.9G.
- 판정: 잔고는 약 1.2G만 낮아지는데 balanced v9가 65.0%에서 59.2%까지 떨어진다. 현재 장기 후보에서는 제외하고, 실제 가격표 후보 검증 도구로만 유지한다.
- 다음 가격 후보는 item/Jester 개별 가격표를 바로 바꾸기보다, reward scale 후보와 market availability/gold sink 누락분을 분리해 본다.

catalog-first runtime translation:

- 사용자가 “카탈로그부터 잡고 그 후 배율 적용” 순서를 승인했다.
- `--sim-price-band-mode catalog_normalized_v1`을 추가했다.
- 기준가 후보:
  - `reroll_token`: 3G -> 5G
  - `coin_cache`: 3G -> 4G
  - `thin_wallet`: 5G -> 7G
  - `green_jester`: 4G -> 8G
  - `popcorn`: 5G -> 6G
  - `ice_cream`: 5G -> 7G
  - `banner`: 5G -> 7G
  - `gros_michel`: 5G -> 7G
  - `supernova`: 5G -> 8G
- `reward 0.40 / price 1.0 / catalog_normalized_v1` r120:
  - balanced none 50.8%, balanced v9 67.5%, power none 60.8%, power v9 70.8%
  - v9 final gold avg 약 129.6G, v9 S8 boss before 약 155.3G
  - 판정: 카탈로그 기준가만으로는 골드 압박이 부족하다.
- `reward 0.40 / price 2.4 / catalog_normalized_v1` r120:
  - balanced none 58.3%, balanced v9 66.7%, power none 65.0%, power v9 59.2%
  - v9 final gold avg 약 17.2G, v9 S8 boss before 약 22.9G
  - 판정: 잔고는 맞지만 power v9가 none보다 낮아져 너무 강하다.
- `reward 0.40 / price 2.2 / catalog_normalized_v1` r120:
  - balanced none 54.2%, balanced v9 63.3%, power none 63.3%, power v9 66.7%
  - v9 final gold avg 약 18.7G, v9 S8 boss before 약 23.7G
  - 판정: 카탈로그 정리 후 전체 가격 배율은 `2.2`가 더 안전하다.
- runtime 적용:
  - 보상: `stageClearGoldBase` 4G, S1 첫 클리어 보너스 2G, 남은 board discard 2G, 남은 hand discard 1G
  - 가격: 카탈로그 기준가 보정 후 `11/5` 정수 비율로 effective 구매가를 반올림
  - 표시/구매 단위는 모두 정수 G이며 소수점 가격은 만들지 않는다.
  - sellPrice와 reroll 비용은 이번 변경에서 유지한다.
- runtime economy long check:
  - `economy_runtime_v91_long_r800`: balanced none 55.9%, balanced v9 57.0%, power none 63.6%, power v9 64.4%
  - v9 final gold avg는 balanced 6.23G, power 6.42G
  - v9 S8 boss before는 평균 9.4G
  - unaffordable event는 15395회
- 판정:
  - 새 런타임 경제는 골드 과잉을 해결하지만, v9 clear 상승폭도 크게 줄였다.
  - 이 결과는 시장 후보가 의미 없다는 뜻이 아니라, 가격/리롤/슬롯 교체 비용이 선택 압박을 만든다는 신호로 본다.
  - 다음 조정은 자동 지급이 아니라 S8 후보군 availability, board/move/discard 후보 접근성, 또는 boss severity/cycle 위치를 분리해서 본다.

catalog value audit:

- `tools/sim/catalog_value_audit.py`를 추가했다.
- 이 도구는 runtime 가격을 바꾸지 않고, Item/Jester 카탈로그의 `basePrice`/`baseCost`, rarity, effect role, 즉시 회수 가치, 판매 회수율을 묶어 가격 불일치 후보를 표시한다.
- 현재 audit 범위는 `data/common/items_common_v1.json`과 `data/common/jesters_common_phase5.json`이다.
- Pack/Tarot-like/Planet-like가 독립 카탈로그 타입으로 승격되면 같은 report에 role mapping을 추가해야 한다.
- 1차 출력:
  - item 49개, Jester 43개, 총 92개 후보를 점검한다.
  - role별 median price는 economy 5.5G, resource 7.5G, score boost 4G, growth engine 7.5G, xmult engine 8G, market 9.5G, relic 9G, deck control 9G, tempo score boost 6G다.
  - 즉시 회수 후보는 `reroll_token`이다. 5G 구매로 기본 리롤 5G를 대체하므로 실질 비용이 낮다.
  - 저가 성장 엔진 후보는 `ride_the_bus`다.
  - 저가 high-impact 후보는 `trade_ticket`, `ride_the_bus`다.
  - 고가 low-impact 후보는 `jester_hook`이다.
- 분류 보정:
  - `popcorn`은 영구 성장 엔진이 아니라 `tempo_score_boost`로 본다.
  - `wide_grip`은 단순 utility가 아니라 hand size와 board discard를 교환하는 `resource` 계열로 본다.
  - `deck_needle`, `undo_seal`은 `deck_control`/resource 계열로 보고, 단순 low-impact utility 후보에서 제외한다.
- 판정:
  - 골드 보상과 전체 가격 배율의 1차 상관은 정리됐지만, 개별 카드/아이템의 가치 대비 가격 산정은 아직 완료가 아니다.
  - 다음 가격 변경은 이 audit 후보를 기준으로 role별 기준가를 먼저 잡고, 그 뒤 runtime economy sweep으로 검증한다.
  - 표시/구매 단위는 계속 정수 G로 유지하며 소수점 가격은 만들지 않는다.

catalog audit v2 probe:

- `--sim-price-band-mode catalog_audit_v2`를 추가했다.
- 이 모드는 runtime 가격을 바꾸지 않는 sim-only 후보이며, `catalog_normalized_v1`에 더해 `trade_ticket` 8G, `ride_the_bus` 7G floor를 검증한다.
- r120 탐색:
  - command: `dart run tools/sim/run_balance_sim.dart --runs 120 --bot planner_v2 --seed 91460 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_audit_v2 --run-modifier basic --out logs/sim/economy_catalog_audit_v2_r120.jsonl --summary-out logs/sim/economy_catalog_audit_v2_r120_summary.json`
  - same-seed normalized comparison: `catalog_normalized_v1`
  - balanced none 58.3%, balanced v9 53.3%, power none 58.3%, power v9 55.8%
  - `catalog_audit_v2`와 same-seed `catalog_normalized_v1` 결과가 동일했다.
- 판정:
  - 이번 r120 path에는 `trade_ticket`, `ride_the_bus` 구매 이벤트가 없어 v2 floor가 실제로 발동하지 않았다.
  - 따라서 이 결과만으로 해당 후보 가격을 올릴 근거는 없다.
  - 다음은 가격 인상이 아니라 후보 노출/구매 이벤트 샘플링을 먼저 확인한다. 후보가 거의 구매되지 않는다면 가격 문제가 아니라 availability/utility proxy 문제일 수 있다.
- audit update:
  - `tools/sim/economy_audit.py`가 content id, proxy Jester id, source candidate id별 구매 이벤트 count를 출력한다.
  - `economy_catalog_audit_v2_r120`의 top content는 `planet_rank_level_proxy`, `shop_slot_market_v9`, `uncommon_build_jester_proxy`, `rare_xmult_jester_proxy`, `tarot_build_pack_proxy` 중심이다.
  - top proxy Jester는 `the_duo`, `fibonacci`, `green_jester`, `zany_jester` 중심이다.
  - `trade_ticket`, `ride_the_bus`, `reroll_token`은 이번 probe의 구매 이벤트에 잡히지 않았다.
  - 이번 `shop_slot_market_v9` path에는 source candidate id도 기록되지 않았다. 이 경로는 backlog 후보 샘플링보다 고정 proxy profile 검증에 가깝다.
  - watchlist 출력 기준 `reroll_token`, `trade_ticket`, `ride_the_bus`, `jester_hook`은 content/proxy/source candidate 모두 0회다.
- 추가 판정:
  - 개별 카탈로그 가격 조정 전, sim이 proxy 묶음만 사는지 실제 카탈로그 후보까지 충분히 샘플링하는지 분리해야 한다.
  - 현재는 `trade_ticket`/`ride_the_bus` 가격을 바로 바꿀 근거가 약하다.

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

- v90 boss runtime cycle 장기 sweep은 새 런타임 경제 적용 후 `economy_runtime_v91_long_r800`으로 재개했다. 추가 결론 확정 전에는 후보군 availability와 boss severity를 분리해서 본다.
- repeat/single rank cycle 편입 sweep도 economy gate 이후로 미룬다.
- Pack/Tarot-like/Planet-like 타입 승격 논의는 economy 모델이 가격을 다룰 수 있게 된 뒤 재개한다.
