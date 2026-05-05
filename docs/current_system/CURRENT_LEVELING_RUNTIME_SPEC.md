# Current Leveling Runtime Spec

> 문서 성격: current runtime leveling table / implementation-facing spec
> 근거 기준: `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md`
> 정책 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 코드 기준: `lib/services/blind_selection_spec.dart`, `lib/logic/rummi_poker_grid/jester_meta.dart`, `lib/logic/rummi_poker_grid/rummi_market_facade.dart`

## 1. 목적

이 문서는 76차 이상 진행한 ML/Flutter CLI/자체 시뮬레이션 실험을 실제 런타임 기준표로 번역한 문서다.

정하는 대상:

- S1~S8 station/tier target score
- small/big/boss curve와 `standard` 난이도 기준
- station band별 market candidate availability와 weight 방향
- Jester / Item / Pack / Tarot-like / Planet-like 역할군
- boss constraint type, pool, station band, severity
- S1/S4/S5/S8 병목 허용치
- board locked / deck exhausted / avg turn / path clear 해석 기준
- bot proxy 해석과 폐기 후보

## 2. S1~S8 Standard Target Table

현재 runtime target은 `BlindSelectionSpecBuilder._standardTargetScore` 기준이다.

| Station | Small | Big | Boss |
|---:|---:|---:|---:|
| S1 | 257 | 284 | 285 |
| S2 | 372 | 431 | 439 |
| S3 | 463 | 537 | 547 |
| S4 | 580 | 672 | 685 |
| S5 | 725 | 841 | 857 |
| S6 | 923 | 1112 | 1121 |
| S7 | 1154 | 1391 | 1401 |
| S8 | 1441 | 1738 | 1739 |

난이도 multiplier:

| Difficulty | Multiplier |
|---|---:|
| relaxed | 0.8 |
| standard | 1.0 |
| pressure | 1.2 |

Run modifier multiplier:

| Modifier | Target | Reward |
|---|---:|---:|
| `basic` | 1.0 | 1.0 |
| `high_stakes` | 1.04 | 1.12 |

Run modifier는 숨은 자동 보정이 아니다. 새 런 시작 시 명시적으로 선택된 modifier만 target score와 blind reward에 배율을 적용한다. `basic`은 기존 레벨링 값을 그대로 유지한다.

`high_stakes`는 Insight 20으로 해금하는 명시적 계약이다. 목표 점수와 blind reward preview/reward만 함께 올리며, 인런 골드/아이템/Jester/자원은 직접 지급하지 않는다. active run 저장에는 선택된 modifier id를 보존하고, 기존 저장처럼 modifier가 없는 payload는 `basic`으로 복원한다.

`high_stakes`는 압박이 높기 때문에 상점 생성/표시 시점의 transient market pressure profile도 함께 사용한다. 이 profile은 저장 포맷을 늘리지 않고 선택된 run modifier에서 파생한다. 효과는 S3 이후 item offer 후보 폭 +1, missing growth 후보의 item/Jester 마켓 노출 확률 보강이며, 자동 지급/고정 슬롯/자동 구매는 하지 않는다.

`high_stakes`는 고레벨 계약이므로 `basic`과 같은 clear rate를 목표로 하지 않는다. 목표는 압박 제거가 아니라, 좋은 market 선택 proxy가 none/control보다 낮아지는 불합리한 역전을 막으면서 S8 boss와 board/draw 병목이 남는 상태를 유지하는 것이다.

S8 이후는 실제 진행 구간 밖이다. 디버그/테스트용으로만 마지막 구간 성장률을 이어 붙여 단조 증가를 보장한다.

## 3. Blind Resource Pressure

이 값은 전투 시작 자원 압박이며, 자동 보상/성장 지급이 아니다.

| Tier | board discard | hand discard | max hand size | reward preview |
|---|---|---|---|---:|
| Small | base | base | base | `stageClearGoldBase` |
| Big | base - 1, min 1 | base | base | `stageClearGoldBase + 4` |
| Boss | base - 1, min 1 | base - 1, min 1 | base - 1, min 1 | `stageClearGoldBase + 8` |

Runtime economy constants:

| Field | Value |
|---|---:|
| `stageClearGoldBase` | 4G |
| `firstBlindClearBonusGold` | 2G |
| `remainingBoardDiscardGoldBonus` | 2G |
| `remainingHandDiscardGoldBonus` | 1G |
| `marketPriceScale` | `11/5`, rounded to integer G |
| `shopBaseRerollCost` | 5G |
| `shopRerollCostStep` | 2G |

가격 표시는 항상 정수 G다. 카탈로그 기준가를 먼저 보정하고, 실제 구매/표시 가격은 `RummiEconomyConfig.scaledMarketPrice`로 정수 반올림한다. `sellPrice`와 reroll 비용은 현재 별도 배율을 적용하지 않는다.

Catalog economy normalization:

| Candidate | Runtime base price |
|---|---:|
| `reroll_token` | 5G |
| `coin_cache` | 4G |
| `thin_wallet` | 7G |
| `green_jester` | 8G |
| `popcorn` | 6G |
| `ice_cream` | 7G |
| `banner` | 7G |
| `gros_michel` | 7G |
| `supernova` | 8G |

## 4. Runtime Boss Modifier Cycle

현재 런타임 Boss 표시/전투 제약은 station index 순환이다.

| Station | Runtime boss modifier |
|---:|---|
| S1 | `redDampener` |
| S2 | `rowDampener` |
| S3 | `faceDampener` |
| S4 | `columnDampener` |
| S5 | `allScoreDampener` |
| S6 | `diagonalDampener` |
| S7 | `firstConfirmTax` |
| S8 | `confirmCountTax` |

표시 정책:

- 보스/제약 설명은 말줄임으로 숨기지 않는다.
- 색상 타일 약화처럼 특정 타일에 걸리는 제약만 타일 위에 표시한다.
- 라인 종류 제약은 개별 타일 배지로 표시하지 않고 보스 팝업/라인/정산 표시에서 설명한다.

## 5. Simulation Boss Constraint Pool

시뮬레이션 기준 boss pool은 Balatro boss 제약을 우리 게임 규칙으로 치환한 proxy다.

| Slot | Constraint | Family | 현재 해석 |
|---:|---|---|---|
| 0 | `color_dampener_cycle` | tile color weaken | 색상 약화 계열 |
| 1 | `line_kind_dampener_cycle` | line kind weaken | row/column/diagonal 약화 계열 |
| 2 | `face_tile_dampener` | face tile weaken | 11~13 face tile 압박 |
| 3 | `repeat_rank_pressure_v4` | repeat hand rank weaken | 같은 rank/족보 반복 압박 |
| 4 | `single_rank_pressure` | single hand rank pressure | 단일 rank/족보 압박 |
| 5 | `confirm_count_tax_v2` | confirm count tax | confirm 횟수 이후 점수 세금 |
| 6 | `all_score_dampener` | base score and mult weaken | 전체 score 약화 |
| 7 | `first_confirm_tax` | opening tax | 첫 confirm 약화 |
| 8 | `target_spike_wall` | large target spike | 목표 점수 spike |
| 9 | `resource_squeeze` | hand size/discard pressure | 손패/버림 압박 proxy |

Weighted boss pool v3:

| Band | Station | 우선 slot |
|---|---|---|
| early | S1~S2 | 2, 1, 0, 7, 9 중심 |
| mid | S3~S5 | 3, 4, 5, 6 중심 |
| late | S6~S7 | 5, 6, 8, 9 중심 |
| final | S8+ | 6, 9, 5, 7, 3, 8 중심 |

현재 기준:

- `boss_constraint_pool_v4`와 `late_boss_068` 계열을 유지한다.
- S8 boss를 더 낮출 근거는 없다.
- `target_spike_wall`은 S8 단일 전투에서 약한 축으로 남긴다.
- `color_dampener_cycle`, `confirm_count_tax_v2`는 runtime modifier로 적용했으나 S1~S8 cycle 변경 후 smoke 재검증이 필요하다.

Runtime migration status:

- 현재 구현된 런타임 보스 제약은 `tileColorWeaken`, `lineKindWeaken`, `faceTileWeaken`, `allScoreWeaken`, `firstConfirmWeaken`, `confirmCountWeaken`, `repeatHandRankWeaken`, `singleHandRankPressure`이다.
- `face_tile_dampener`는 runtime boss modifier로 적용한다. 기존 타일 대상 약화 구조를 확장하며, 11~13 face tile 압박이라는 의미도 분명하다.
- `all_score_dampener`는 모든 점수 라인 20% 감소로 적용한다. 특정 타일 표시 대상이 아니므로 보스 팝업/정산 penalty 표시를 기준으로 읽힌다.
- `first_confirm_tax`는 첫 confirm 점수 라인 30% 감소로 적용한다.
- `confirm_count_tax_v2`는 세 번째 confirm부터 점수 라인 25% 감소로 적용한다. 새 저장 필드 없이 기존 `confirmCountThisStation`을 사용한다.
- `repeat_rank_pressure_v4`는 이전 confirm에서 나온 같은 족보를 다시 확정하면 점수 라인을 20% 감소시키는 modifier로 구현됐다. 확정된 족보 이력은 `confirmedRanksThisStation`으로 저장/복원한다.
- `single_rank_pressure`는 A안 기준으로 첫 confirm 족보를 다시 확정하면 점수 라인을 30% 감소시키는 modifier로 구현됐다. 타일별 제약이 아니므로 타일 배지는 표시하지 않고 보스 팝업/정산 penalty로 읽힌다.
- `repeat_rank_pressure_v4`, `single_rank_pressure`는 아직 S1~S8 runtime boss cycle에는 편입하지 않았다. cycle 편입 전 별도 sweep으로 severity와 배치 위치를 검증한다.
- `target_spike_wall`은 boss modifier가 아니라 target score 레버로 본다.
- `resource_squeeze`는 자동 자원 지급/보정이 아니라 시작 압박 또는 마켓 후보 수요로만 해석한다.

Runtime S1~S8 boss cycle:

| Station | Modifier | 역할 |
|---:|---|---|
| S1 | `red_dampener_v1` | 색상 약화 family 대표 |
| S2 | `row_line_dampener_v1` | line kind 약화 |
| S3 | `face_tile_dampener_v1` | 11~13 타일 압박 |
| S4 | `column_line_dampener_v1` | line kind 약화 |
| S5 | `all_score_dampener_v1` | 전체 점수 약화 |
| S6 | `diagonal_line_dampener_v1` | line kind 약화 |
| S7 | `first_confirm_tax_v1` | 첫 confirm 압박 |
| S8 | `confirm_count_tax_v2` | 후반 confirm 압박 |

## 6. Market Band Policy

현재 runtime market policy는 `RummiStationBandMarketPolicy` 기준이다.

| Band | Station | 역할 |
|---|---|---|
| early | S1~S2 | economy/market, discard/safety/move, tile color/rank/draw 후보를 열어 초반 선택지를 만든다. |
| mid | S3~S5 | score/rank/tile_color 성장 후보를 중심으로, market/rarity/capacity와 discard/safety/move를 보조한다. |
| late | S6~S8 | boss/legendary, score/xmult/rarity 후보를 강화하고, market/capacity와 safety/move/discard를 보조한다. |

Jester rarity weight:

| Stage tier | Common | Uncommon | Rare | Legendary |
|---:|---:|---:|---:|---:|
| 1 | 860 | 120 | 20 | 1 |
| 2 | 780 | 170 | 40 | 2 |
| 3 | 700 | 220 | 70 | 4 |
| 4 | 620 | 270 | 100 | 8 |
| 5 | 550 | 310 | 130 | 12 |
| 6+ | 480 | 340 | 160 | 20 |

Item rarity base weight:

| Band | Common | Uncommon | Rare | Legendary |
|---|---:|---:|---:|---:|
| early | 580 | 220 | 60 | 4 |
| mid | 360 | 420 | 140 | 10 |
| late | 260 | 360 | 260 | 30 |

Missing growth exposure:

| Station | Missing condition | Added tags | Focus chance |
|---|---|---|---:|
| S3+ | no score/rank/tile_color tags | `score`, `rank`, `tile_color` | S3: 35% |
| S4+ | no discard/move/safety tags | `discard`, `move`, `safety` | S4~S5: 45% |
| S6+ | no boss/xmult/legendary tags | `boss`, `xmult`, `legendary` | S6+: 55% |

Rules:

- Focus slot은 확률적으로만 생기며, 위치는 stage/reroll/rng에 따라 흔들린다.
- Matching tag bonus는 tag당 +45, 최대 2개까지만 적용한다.
- 이 보정은 직접 지급이 아니라 등장 확률 보정이다.

Final band shape correction:

| Station | Condition | Bonus | Purpose |
|---|---|---:|---|
| S7~S8 | `tile_color`, `draw`, 또는 `score` 없는 순수 `rank` 후보 | +80 | S8 boss의 deck exhausted 축을 직접 지급 없이 마켓 후보군 안정성으로 완화 |

이 보정은 `score/xmult/boss` 후보를 더 올리는 조정이 아니다. 이미 충분했던 점수 전환 후보보다 낮게 보이던 덱/타일 형상 보정 후보를 final band에서 완전히 밀려나지 않게 만드는 floor다.

Sim parity:

- `tools/sim/run_balance_sim.dart`의 `shop_slot_market_v9`도 S7~S8에서 shape proxy 후보를 완전히 밀어내지 않도록 맞춘다.
- sim shape proxy는 `s1_tile_pack_plus5`, `s1_build_aware_pack_plus5`, `s1_candidate_tarot_build_pack`이다.
- 이 parity는 시뮬 후보 노출/선택 proxy만 맞추며, 실제 런타임 지급이나 슬롯 수를 바꾸지 않는다.

## 7. Candidate Role Interpretation

| Candidate family | 실제 의미 | 적용 방식 |
|---|---|---|
| Jester | 점수 성장, 조건부 score/mult/chip/xmult, build identity | rarity/tag/category weight |
| Item | Q-SLT/GEAR/PSV/Tool 기반 전투/상점/패시브 선택지 | item rarity/tag weight |
| Pack | 덱/타일 형상 보정 또는 선택지 확장 proxy | market candidate availability |
| Tarot-like | tile shape/color/rank correction proxy | market candidate availability |
| Planet-like | rank/line score progression proxy | market candidate availability |
| Voucher-like | run-long market/economy/capacity proxy | market-only 구매 후보, 자동 지급 아님 |

## 8. Bottleneck Interpretation

| Signal | 해석 | 먼저 볼 레버 |
|---|---|---|
| S1 boss top failure | 초반 보스 압박이 살아 있음 | target/constraint display/첫 클리어 골드 흐름 |
| S4/S5 failure | 중반 성장축/board pressure 병목 | market candidate availability, score/shape 후보 |
| S8 boss deck exhausted | 후반 점수 전환은 충분하나 덱/타일 형상 후보가 낮을 수 있음 | late boss band 후보군 availability |
| board locked 증가 | 슬롯/자원 자동 보정 근거 아님 | board pressure 완화 후보 노출/가격 |
| avg total turn 감소 | 템포 개선 | clear rate와 같이 확인 |
| path clear 급등 | 과보정 의심 | failure distribution과 top bottleneck 확인 |

## 9. 폐기 기준

아래는 수치가 좋아도 실제 적용하지 않는다.

- 자동 resource +1
- board discard/hand discard/max hand size 자동 증가
- 아이템/Jester/Pack/덱 타일 직접 지급
- 특정 slot 고정 노출
- bot 구매 결과를 시스템 지급으로 번역
- S1 boss target만 낮춰 `small < big < boss` 압박을 깨는 조정

## 10. 다음 적용 후보

다음 후보는 `shop_slot_market_v9`의 S7~S8 boss band에서 덱/타일 형상 보정 후보 availability floor를 검토하는 것이다.

조건:

- slot 수를 늘리지 않는다.
- 직접 지급하지 않는다.
- 특정 위치를 고정하지 않는다.
- 후보군 포함 안정성만 조정한다.
- smoke 후 장기 sweep에서 path clear, avg total turn, S1/S4/S5/S8 병목, board locked/draw exhausted를 같이 본다.
