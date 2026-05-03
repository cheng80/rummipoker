# Current Leveling ML Baseline

> 문서 성격: current leveling baseline / simulation-derived standard
> 근거 이력: `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`
> 정책 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> 적용 상태: 일부 runtime 반영 완료, 추가 조정은 market-only 원칙으로 검토

## 1. 76차 이상 실험의 목적

이 문서는 단순 요약이 아니라, 76차 이상 진행한 머신러닝/Flutter CLI/자체 시뮬레이션 실험이 무엇을 정하기 위한 것이었는지 보존하는 기준 문서다.

해당 실험들은 아래 항목을 정하기 위한 근거였다.

| 결정 대상 | 실험이 확인한 것 | 현재 해석 |
|---|---|---|
| S1~S8 station/tier target score | small/big/boss 목표 점수가 station path에서 진행 가능한지 | S1~S8 standard target table을 runtime에 연결 |
| `standard` 난이도 기준 | relaxed/standard/pressure 중 기본 플레이 기준이 되는 curve | 현재 기본 판단은 `standard` 중심 |
| station band별 마켓 후보군 | S1~S2, S3~S5, S6~S8에서 어떤 성장 후보가 필요해지는지 | early/mid/late market band policy로 번역 |
| Jester 후보 weight | Common/Uncommon/Rare/Legendary가 어느 구간부터 의미 있는지 | Rare/Legendary도 0으로 막지 않고 낮은 확률 유지 |
| Item/Pack/Tarot-like/Planet-like 후보 weight | 덱/타일 형상, 점수 성장, boss 대응, market/economy 후보의 역할 | 직접 지급이 아니라 market candidate availability/weight로만 반영 |
| 보스 제약 타입 | Balatro boss 제약을 우리 게임의 color/line/rank/confirm/score/resource 압박으로 치환 가능한지 | weighted boss pool과 runtime boss modifier로 분리 |
| 보스 제약 severity | hard wall이 되는 제약과 긴장감만 주는 제약의 차이 | `boss_constraint_pool_v4`, `late_boss_068` 계열 유지 |
| 병목 허용치 | S1/S4/S5/S8에서 어느 정도 실패가 남아야 긴장감이 유지되는지 | top failure가 0이 되는 방향은 목표가 아님 |
| failure 해석 | board locked, deck exhausted, avg turn, path clear가 어떤 조정 레버를 의미하는지 | 자동 자원이 아니라 target/constraint/market availability로 해석 |
| bot proxy 의미 | bot 구매 선택이 유저 선택 성향을 얼마나 대변하는지 | bot 선택은 지급 근거가 아니라 후보 유효성 proxy |
| 폐기 후보 | 자동 resource +1, 고정 지급, 특정 슬롯 고정이 수치상 좋아도 정책 위반인지 | 폐기/비교용 이력으로만 보존 |

따라서 이 문서는 “레벨링 정책 논의 기록”이 아니라, 실제 런타임 target, 마켓 weight, boss constraint 후보를 정하기 위한 실험 산출물의 현재 기준이다.

## 2. 현재 기준 조합

현재 실제 기준 후보는 아래 조합이다.

| 축 | 기준 |
|---|---|
| difficulty | `standard` |
| experiment | `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068` |
| market | `shop_slot_market_v9` |
| route 해석 | `progression_route_balanced`, `progression_route_power` 중심 |
| bot proxy | `planner_v2` |
| runtime target | S1~S8 standard target table은 `BlindSelectionSpecBuilder`에 연결됨 |
| runtime market | station band rarity/tag weight + missing growth market exposure 반영 |

이 조합의 의미:

- 자동 자원 지급 없이 S1~S8 path가 진행 가능한 기준점이다.
- `shop_slot_market_v9`는 고정 지급이 아니라 station band별 후보 weight/availability 정책으로 해석한다.
- `late_boss_068`은 S6~S8 boss 압박을 낮추되 finale 긴장감을 유지하는 기준이다.

## 3. 확정 정책

- S1 첫 클리어 보너스 골드 외에는 공짜 지급이 없다.
- 아이템/Jester/Pack/Tarot-like/Planet-like/덱 타일을 직접 지급하지 않는다.
- board discard, hand discard, max hand size, slot, hand size를 자동 보정하지 않는다.
- 필요한 성장축을 못 얻은 경우에도 직접 지급이 아니라 마켓 후보 등장 확률/슬롯 노출 확률만 조정한다.
- 후보가 마켓에 떠도 구매, 판매, 장착, 사용은 유저 선택이다.
- 특정 offer slot 위치를 고정하지 않는다.

## 4. 핵심 실험 흐름 요약

| 구간 | 결론 |
|---|---|
| v1~v18 | base score curve와 boss constraint 후보를 분리해야 한다는 결론. 강한 단일 build와 실제 station path가 다른 문제임을 확인. |
| v19~v31 | `base_score_curve_v2`, `boss_constraint_pool_v4`, S1 soft 계열, progression route, role pool을 분리. 고정 지급형 market profile은 실제 적용 후보가 아님. |
| v39~v53 | 실제 상점에 가까운 슬롯형 market profile을 검증. `shop_slot_market_v2`에서 시작해 후반 static guard/late breaker proxy를 도입. |
| v60~v63 | `shop_slot_market_v9`가 late breaker 후보로 의미 있음을 확인. 실제 상점에서는 고정 지급이 아니라 S7~S8 후보 pool weight로 번역해야 한다고 정리. |
| v64~v67 | 자동 resource +1 계열은 수치가 좋아도 폐기. 자동 자원 없는 후보 중 `shop_slot_market_v9 + late_boss_068`을 기준으로 유지. |
| v68~v72 | 3구간 목표표와 runtime 전환. S1 첫 클리어 보너스 골드, station band market policy, missing growth market exposure를 runtime 방향으로 정리. |
| v73~v76 | smoke/confirm sweep에서 v72 exposure가 과보정이 아님을 확인. `shop_slot_market_v9`는 path clear를 올리지만 S1/S8 boss 병목은 남김. |
| v77~v79 | board pressure 후보 availability/가격 가능성 probe. 슬롯 수나 자동 자원보다 후보 노출/구매 가능성을 봐야 한다고 정리. |
| v80~v83 | S1 boss 축 분리와 runtime display 확인. `red_dampener_v1` 0.6은 초반 보스를 무력화하지 않고, UI 설명 말줄임 없이 표시. |
| v84~v86 | v72 exposure 재확인, S8 boss 축 분리, late offer exposure 확인. 점수 전환 후보는 충분하나 S8 boss에서 덱/타일 형상 보정 후보 노출은 낮음. |

## 5. 현재 수치 기준

### v74 confirm sweep 기준

800 runs 기준:

| route | market | path clear | avg total turn | 주요 병목 |
|---|---|---:|---:|---|
| balanced | `shop_slot_market_v9` | 62.9% | 1348.5 | S1 boss, S8 boss, S4 boss, S5 boss |
| power | `shop_slot_market_v9` | 67.3% | 1307.6 | S1 boss, S8 boss, S1 big, S1 small |

Station battle 기준:

| market | S1 clear | S4 clear | S5 clear | S8 clear |
|---|---:|---:|---:|---:|
| `shop_slot_market_v9` | 96.7% | 98.2% | 98.9% | 96.9% |

판정:

- `shop_slot_market_v9`는 유효하지만 과보정은 아니다.
- S1/S8 boss는 top failure에 남아야 정상이다. 완전히 제거하면 긴장감이 사라진다.

### v84 smoke 기준

120 runs 기준:

| loadout | market | path clear | avg total turn | 주요 stop |
|---|---|---:|---:|---|
| balanced | none | 55.8% | 1361.6 | board 27, draw 25 |
| balanced | v9 | 57.5% | 1319.7 | board 38, draw 12 |
| power | none | 65.0% | 1336.8 | board 25, draw 17 |
| power | v9 | 73.3% | 1377.9 | board 21, draw 11 |

판정:

- v72 exposure 보정은 과하게 올리지 않았다.
- S1/S4/S5는 완화되고 잔여 병목은 S8 boss 쪽으로 이동한다.
- slot focus 확률을 낮출 근거는 없다.

### v85 S8 boss 축

S8 boss 단일 전투 400 runs:

| result | count |
|---|---:|
| clear | 351 |
| deck exhausted | 45 |
| board locked | 4 |

약한 constraint:

- `color_dampener_cycle`
- `confirm_count_tax_v2`
- `target_spike_wall`

판정:

- S8 boss clear 87.8%는 너무 쉽지 않다.
- `late_boss_068`을 더 낮출 근거는 없다.
- 실패 대부분은 board lock보다 deck exhausted다.

### v86 late offer exposure

S8 boss 슬롯 노출률:

| candidate | availability |
|---|---:|
| `s1_candidate_rare_xmult_jester` | 84.4% |
| `s1_candidate_planet_rank_level` | 81.3% |
| `s1_candidate_uncommon_build_jester` | 79.2% |
| `s1_candidate_legendary_bridge` | 36.7% |
| `s1_candidate_tarot_build_pack` | 16.3% |
| `s1_build_aware_pack_plus5` | 12.8% |
| `s1_buy_discard_glove` | 12.1% |
| `s1_candidate_voucher_resource` | 5.9% |
| `s1_tile_pack_plus5` | 3.5% |

판정:

- 점수 전환 후보는 충분히 노출된다.
- 덱/타일 형상 보정 후보는 S8 boss에서 낮다.
- 다음 검토 후보는 S7~S8 boss band의 덱/타일 형상 보정 후보 availability floor다.
- `voucher_resource`는 sim proxy 이름일 뿐 자동 resource 지급 후보가 아니다.

## 6. 폐기된 방향

| 방향 | 폐기 이유 |
|---|---|
| 자동 resource +1 계열 | S1 첫 클리어 보너스 골드 외 공짜 지급 금지 원칙 위반 |
| `late_boss_070_resource_1` | 수치상 좋지만 자동 자원 +1 포함 |
| S1 boss target만 낮추기 | `small < big < boss` 압박 구조가 깨짐 |
| 고정 지급형 market profile | 유저 선택을 대체함 |
| 특정 slot 위치 고정 노출 | 마켓이 scripted하게 보임 |
| board/hand/max hand size 자동 보정 | 성장 수요를 게임이 대신 해결함 |
| v10식 과한 resource/voucher 선택 유도 | clear 안정성이 깨지고 선택이 한쪽으로 쏠림 |

## 7. 실제 적용 레버

허용:

- station/tier target score 조정
- boss constraint pool/weight 조정
- market candidate availability 조정
- station band rarity/tag/category/slot weight 조정
- candidate 가격대 검토
- bot/user 선택 proxy 개선

금지:

- 아이템/Jester/Pack 직접 지급
- 덱 타일 직접 지급
- board discard/hand discard/max hand size 자동 증가
- 슬롯 자동 증가
- 구매/판매/장착/사용 자동 대행

## 8. 다음 검증 후보

1. S7~S8 boss band에서 덱/타일 형상 보정 후보 availability floor를 검토한다.
2. 이 floor는 slot 수 증가가 아니라 후보군 포함 안정성으로만 설계한다.
3. 후보 위치는 stage/reroll/rng에 따라 흔들리게 유지한다.
4. smoke 이후 장기 sweep에서 path clear, avg total turn, S1/S4/S5/S8 병목, board lock/draw exhausted를 같이 본다.
5. 너무 강하면 weight를 낮추고, 너무 약하면 slot 수가 아니라 후보군 availability를 먼저 본다.

현재 1차 적용:

- S7~S8 final band에서 `tile_color`, `draw`, 또는 `score` 없는 순수 `rank` 후보에 item weight +80을 추가했다.
- slot 수, 직접 지급, 특정 위치 고정은 변경하지 않았다.
- runtime market offer 분포 probe에서는 shape floor share가 S6 10.3%에서 S7~S8 12.5%로 올랐다.
- sim `shop_slot_market_v9`도 final band shape proxy floor를 반영하도록 맞췄다.
- v87 runtime parity r120 smoke에서 `shop_slot_market_v9`는 path clear를 올리지만 S1/S7/S8 boss 병목을 지우지 않았다.
- final band v9 slot exposure는 shape proxy 740, score breaker proxy 1619로, shape 후보가 살아났지만 score breaker를 밀어내지는 않았다.

## 9. 관련 문서

- 현재 정책: `docs/current_system/CURRENT_LEVELING_POLICY.md`
- 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
- 적용 상태: `docs/planning/LEVELING_APPLIED_STATUS.md`
- active 진입 요약: `docs/planning/ML_LEVELING_SIMULATION_DIRECTION.md`
- 긴 실험 이력: `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`
- 시뮬 CLI: `tools/sim/run_balance_sim.dart`
- sweep dataset: `tools/sim/ml_sweep_dataset.py`
