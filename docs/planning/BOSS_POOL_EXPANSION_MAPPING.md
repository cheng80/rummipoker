# Boss Pool Expansion Mapping

> 문서 성격: planning / reference-only mapping
> 목적: 공모전용 boss pool 1차 확장을 위해 외부 reference boss pattern을 우리 게임 룰 패턴으로 재작성한다.
> 주의: 아래 reference 이름은 매핑 검토용이다. 런타임 표시명, 저장 id, UI copy로 그대로 쓰지 않는다.

## 1. Current State

현재 우리 게임의 boss pool은 두 층으로 나뉜다.

| Layer | Count | Notes |
|---|---:|---|
| Simulation proxy pool | 10+3+5 | `CURRENT_LEVELING_RUNTIME_SPEC.md`의 boss constraint proxy 기준 + 1차 확장 experiment axis + Stage A simulation-only proxy |
| Runtime modifier type | 9 | battle/save/display/settlement penalty 경로가 있는 modifier 타입. `confirm_limit_tax_v1`은 구현됐지만 cycle 미편입 |
| S1~S8 runtime cycle slot | 8 | Station마다 1개씩 고정 배치 |

현재 문제:

- S1~S8에 boss가 8번만 나오므로 반복 run에서 전략 학습 폭이 좁다.
- reference boss pattern은 28개인데, 현재는 이를 10개 family로 압축했다.
- 공모전용 vertical slice 기준에서도 boss 다양성은 전략성 인상에 직접 영향을 준다.

## 2. Mapping Policy

- reference 이름과 테마를 그대로 쓰지 않는다.
- 우리 게임의 타일/라인/확정/자원/골드/마켓/아이템/Jester 발동 제한으로 다시 쓴다.
- 자동 자원 지급, 직접 지급, 고정 offer slot, 강제 판매/강제 구매는 금지한다.
- 유저 선택을 빼앗는 효과는 simulation-only 또는 제외한다.
- 저장 포맷이 필요한 후보는 출품 전 1차 구현에서 제외하거나 별도 승인 대상으로 둔다.

## 3. Reference Pattern Mapping

| # | Reference pattern | Core pressure | Current absorption | Proposed game pattern | 1차 판단 |
|---:|---|---|---|---|---|
| 1 | The Hook | play 후 hand disruption | not absorbed | 확정 후 손패 1~2장 임시 잠금 또는 추가 discard pressure | simulation first |
| 2 | The Ox | 특정 hand type 사용 시 money reset | partial via economy tax ideas | 가장 많이 확정한 족보를 다시 쓰면 이번 Station reward 일부 tax | runtime possible |
| 3 | The House | first hand hidden | not absorbed | 전투 시작 손패 일부를 첫 이동 전까지 정보 숨김 | risky UI, defer |
| 4 | The Wall | larger target | proxy `target_spike_wall` | Boss target multiplier spike | simulation only first |
| 5 | The Wheel | random hidden cards | not absorbed | 드로우된 손패 일부가 값/색 중 하나를 늦게 reveal | risky UI, defer |
| 6 | The Arm | played hand level down | partial via score dampening | 확정한 족보 family의 다음 점수 base 감소 | runtime possible |
| 7 | The Club | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 8 | The Fish | hidden after each play | not absorbed | 확정 후 다음 드로우 일부 늦게 reveal | risky UI, defer |
| 9 | The Psychic | fixed play size | not absorbed | 확정 라인의 최소 기여 타일 수 조건 | runtime possible |
| 10 | The Goad | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 11 | The Water | no discard | partial via resource squeeze | hand discard 0 또는 discard cost 증가 | simulation first |
| 12 | The Window | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 13 | The Manacle | hand size -1 | proxy `resource_squeeze` | max hand size pressure | simulation first, runtime risky |
| 14 | The Eye | no repeated hand type | implemented repeat pressure | 같은 족보 반복 확정 시 점수 감소 또는 무효화 | implemented, not in cycle |
| 15 | The Mouth | only one hand type | implemented single rank pressure | 첫 확정 족보 family만 고효율, 다른 family penalty | implemented, not in cycle |
| 16 | The Plant | face card debuff | absorbed by face tile dampener | 11~13 포함 라인 점수 감소 | already absorbed |
| 17 | The Serpent | draw count fixed | not absorbed | 확정/버림 후 refill 수 제한 또는 고정 | simulation first |
| 18 | The Pillar | previous ante cards debuff | not absorbed | 이전 Station에서 많이 쓴 rank/color가 다음 Boss에서 약화 | needs tracking, defer |
| 19 | The Needle | one hand only | not absorbed | confirm 횟수 1회 제한 또는 2회차 이후 큰 tax | runtime possible via confirm count |
| 20 | The Head | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 21 | The Tooth | played card money loss | not absorbed | 확정 기여 타일 수만큼 reward tax | runtime possible |
| 22 | The Flint | base chip/mult halved | absorbed by all score dampener | 모든 점수 라인 감소 | already absorbed |
| 23 | The Mark | face cards hidden | not absorbed | 11~13 타일 정보 일부 늦게 reveal | risky UI, defer |
| 24 | Amber Acorn | Joker hidden/reordered | not absorbed | Jester 발동 순서 일부 셔플 또는 표시 지연 | risky, defer |
| 25 | Verdant Leaf | sell Joker to remove debuff | not allowed as forced sell | 판매 강제 대신 보유 Jester 수에 따른 boss tax | simulation only / redesign |
| 26 | Violet Vessel | very large target | proxy `target_spike_wall` | Boss target multiplier spike stronger variant | simulation only first |
| 27 | Crimson Heart | random Joker disabled each hand | not absorbed | 매 confirm마다 Jester 1개 발동 제외 | runtime possible, high risk |
| 28 | Cerulean Bell | force selected card | not absorbed | 손패/보드 후보 1개를 이번 액션에 반드시 포함하면 bonus, 미포함 penalty는 금지 | redesign needed |

## 4. 1차 확장 후보

출품 전 1차로 비교적 안전한 후보:

| Candidate | Base reference | Why |
|---|---|---|
| `reward_tax_by_repeat_rank_v1` | Ox / Tooth | reward tax는 저장 포맷 변경 없이 settlement/economy trace로 검증 가능 |
| `min_contributor_count_v1` | Psychic | 확정 후보 계산 경로에 붙일 수 있고 전략성이 분명함 |
| `confirm_limit_tax_v1` | Needle | 기존 confirm count tax 경로를 확장 가능 |
| `rank_family_decay_v1` | Arm | 기존 repeat/single rank pressure와 유사한 저장/표시 구조 활용 가능 |
| `jester_skip_one_v1` | Crimson Heart | 전략성은 강하지만 UI/정산 feedback이 필요하므로 마지막 후보 |

1차 runtime 편입 우선순위:

1. `confirm_limit_tax_v1`
2. `min_contributor_count_v1`
3. `reward_tax_by_repeat_rank_v1`
4. `rank_family_decay_v1`
5. `jester_skip_one_v1`

## 4.0 재검토 분류: 재미 다양성 기준

2026-05-06 재검토에서는 기존 "이미 흡수됨/보류/위험" 분류만으로는 boss pool 다양성이 충분히 늘지 않는다고 판단했다.
기존 family variant라도 반복 run에서 다른 선택 압박을 만들 수 있으면 별도 후보로 살린다.
단, 유저 선택 강제, 자동 지급, 특정 슬롯 고정은 그대로 금지한다.

### Stage A: 빠른 simulation-only proxy

저장 포맷과 UI를 바꾸지 않고, 먼저 path clear와 병목 변화를 확인할 후보군이다.
이 단계는 runtime 적용이 아니라 boss pool 다양성의 방향과 규모를 보는 탐색이다.

| Candidate | Reference pattern | Pattern axis | Simulation 처리 | 판단 목적 |
|---|---|---|---|---|
| `target_spike_wall_soft_v1` | #4 / #26 | 목표 점수 spike | boss target multiplier 소폭 상승 | target spike family가 S8 압박을 살리는지 확인 |
| `target_spike_wall_hard_v1` | #4 / #26 | 목표 점수 spike | stronger multiplier variant | 강한 목표 spike가 v9를 무너뜨리는지 확인 |
| `hand_discard_cost_v1` | #11 | 손패/버림 압박 | hand discard 사용 비용 또는 discard 0 proxy | resource squeeze를 자동 지급 없이 압박으로만 해석 |
| `max_hand_size_pressure_v1` | #13 | 손패 크기 압박 | max hand size -1 proxy | 손패 압박이 board/draw 병목에 미치는 영향 확인 |
| `refill_limit_v1` | #17 | 드로우/보충 압박 | confirm/버림 후 refill 수 제한 proxy | deck exhausted와 선택 압박 변화 확인 |
| `reward_tax_by_contributor_v1` | #21 | 정산/economy 압박 | 확정 기여 타일 수 기반 reward tax | 점수 penalty가 아닌 경제 penalty 축 확인 |
| `reward_tax_by_repeat_rank_v1` | #2 | 반복 족보 economy tax | 많이 쓴 족보 재사용 시 Station reward tax | 반복 억제와 경제 압박의 결합 확인 |
| `color_dampener_variant_v1` | #7/#10/#12/#20 | 색상 약화 family variant | 색상 cycle severity/station band variant | 이미 흡수된 family도 pool 폭을 늘릴 수 있는지 확인 |
| `face_tile_dampener_variant_v1` | #16/#23 | face tile 압박 variant | face severity 또는 reveal 없는 face penalty | face family의 단조로움 완화 |

Stage A 우선 probe 후보:

1. `target_spike_wall_soft_v1`
2. `hand_discard_cost_v1`
3. `refill_limit_v1`
4. `reward_tax_by_contributor_v1`
5. `color_dampener_variant_v1`

위 5개는 숫자 penalty만이 아니라 target, 자원, 드로우, 정산, 색상 family variant를 골고루 포함한다.
`min_contributor_count_v1`, `rank_family_decay_v1`, `confirm_limit_tax_v1`은 이미 1차 simulation proxy에 들어갔으므로 새 Stage A probe에는 중복으로 넣지 않는다.

Stage A 적용 상태:

- experiment id: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_probe_v1`
- runtime cycle에는 편입하지 않았다.
- 저장 포맷과 UI는 변경하지 않았다.
- `reward_tax_by_contributor_v1`은 simulation economy cashout에만 적용한다.
- `refill_limit_v1`은 첫 구현에서 `maxDrawActions 18`이 S3 boss를 거의 전부 막아 `maxDrawActions 42`로 완화했다.

r80 exploratory smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 80 --seed 90980 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_stage_a_probe_v1_r80`
- summary: `logs/sim/boss_expansion_stage_a_probe_v1_r80_summary.json`
- report: `logs/sim/boss_expansion_stage_a_probe_v1_r80_report.md`

Path clear:

| Loadout | Market | Clear | 주요 병목 |
|---|---|---:|---|
| balanced | none | 40.0% | S5 boss, S8 boss, S3 boss |
| balanced | v9 | 61.3% | S5 boss, S8 boss, S4 boss |
| power | none | 62.5% | S8 boss, S4 big, S6/S7 boss |
| power | v9 | 68.8% | S8 boss, S3 boss, S8 big |

Boss 전투 단위 aggregate:

| Proxy | Clear | Runs | 주요 outcome |
|---|---:|---:|---|
| `target_spike_wall_soft_v1` | 98.4% | 313 | mostly clear |
| `hand_discard_cost_v1` | 99.3% | 301 | mostly clear |
| `refill_limit_v1` | 93.8% | 292 | score shortfall 14, board locked 4 |
| `reward_tax_by_contributor_v1` | 98.1% | 267 | mostly clear |
| `color_dampener_variant_v1` | 92.5% | 253 | deck exhausted 17 |

Stage A r80 판정:

- v9가 none보다 낮아지는 역전은 없다.
- `balanced none`은 40.0%까지 내려가지만, Stage A는 출품 runtime 적용이 아니라 확장 후보 탐색이므로 즉시 폐기하지 않는다.
- `refill_limit_v1`은 완화 후에도 path 병목에 크게 관여하므로, 단독 split probe 없이는 runtime 후보로 올리지 않는다.
- `target_spike_wall_soft_v1`, `hand_discard_cost_v1`, `reward_tax_by_contributor_v1`은 boss 전투 단위 clear가 높아 다음 split 후보로 남긴다.
- `color_dampener_variant_v1`은 기존 family variant지만 deck exhausted 신호가 있어, S5 이후 배치와 severity를 분리해서 본다.

Stage A split r80:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 80 --seed 91080 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_target_spike_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_hand_discard_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_refill_limit_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_reward_tax_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_stage_a_color_variant_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_stage_a_split_probe_v1_r80`
- summary: `logs/sim/boss_expansion_stage_a_split_probe_v1_r80_summary.json`
- report: `logs/sim/boss_expansion_stage_a_split_probe_v1_r80_report.md`

Path clear:

| Profile | balanced none | balanced v9 | power none | power v9 | 1차 판정 |
|---|---:|---:|---:|---:|---|
| `target_spike_wall_soft_v1` | 53.8% | 60.0% | 68.8% | 81.2% | v9 역전은 없지만 power v9가 너무 높아 배치/severity watch |
| `hand_discard_cost_v1` | 58.8% | 63.7% | 58.8% | 75.0% | 실행 안정, Stage B 후보 |
| `refill_limit_v1` | 50.0% | 62.5% | 62.5% | 71.2% | draw-limit stop이 남아 simulation-only 유지 |
| `reward_tax_by_contributor_v1` | 52.5% | 70.0% | 57.5% | 70.0% | 실행 안정, Stage B 후보 |
| `color_dampener_variant_v1` | 43.8% | 70.0% | 67.5% | 70.0% | family variant 후보지만 balanced none 압박 큼 |

Boss 전투 단위 aggregate:

| Proxy | Clear | Runs | 주요 outcome |
|---|---:|---:|---|
| `target_spike_wall_soft_v1` | 98.4% | 310 | board locked 4, deck exhausted 1 |
| `hand_discard_cost_v1` | 98.2% | 285 | board locked 5 |
| `refill_limit_v1` | 96.0% | 273 | score shortfall 6, board locked 5 |
| `reward_tax_by_contributor_v1` | 98.8% | 252 | board locked 2, deck exhausted 1 |
| `color_dampener_variant_v1` | 93.4% | 256 | deck exhausted 15 |

Split 판정:

- Stage B 우선 후보는 `reward_tax_by_contributor_v1`과 `hand_discard_cost_v1`이다.
- `target_spike_wall_soft_v1`은 target table lever라 구현은 쉽지만 power v9가 높아, S7/S8 후반 압박을 지우지 않는 배치/severity로 다시 확인해야 한다.
- `color_dampener_variant_v1`은 기존 family variant로 boss pool 폭은 늘리지만, 새로운 플레이 양상은 약하다. S5 배치보다 색상/Station variant pool 후보로 둔다.
- `refill_limit_v1`은 draw-limit stop이 직접 남으므로 runtime 후보가 아니라 Stage A simulation-only 후보로 유지한다.

### Stage B: 저장 포맷 변경 없이 runtime 가능

기존 boss modifier JSON, confirm count, confirmed rank, target table, settlement/economy trace로 구현 가능한 후보군이다.
이 단계도 cycle 편입 전에는 별도 experiment axis로 검증한다.

| Candidate | Runtime anchor | 저장/복원 영향 | UI/피드백 영향 | 현재 판단 |
|---|---|---|---|---|
| `confirm_limit_tax_v1` | `confirmCountWeaken` threshold variant | 새 schema 없이 선택 필드 round-trip 완료 | 기존 confirm count penalty 표시 재사용 | 구현 완료, cycle 미편입 |
| `target_spike_wall_soft_v1` | boss target table lever | 저장 영향 없음 | boss target preview/설명 필요 | runtime 가능, severity 검증 필요 |
| `color_dampener_variant_v1` | `tileColorWeaken` | 저장 영향 없음 | 기존 타일 배지/보스 팝업 재사용 | runtime 가능 |
| `face_tile_dampener_variant_v1` | `faceTileWeaken` | 저장 영향 없음 | 기존 타일 배지/보스 팝업 재사용 | runtime 가능 |
| `reward_tax_by_contributor_v1` | settlement reward/economy trace | 저장 영향 없음, 정산 결과만 확정값 | 정산 reward tax 표시 필요 | runtime 가능하나 economy probe 필요 |
| `reward_tax_by_repeat_rank_v1` | confirmed rank + settlement reward tax | 기존 confirmed rank 저장 재사용 가능성 있음 | 정산 reward tax 표시 필요 | runtime 가능성 있음 |
| `min_contributor_count_v1` | confirm candidate scoring/penalty | 저장 영향 없음 | 라인 preview/정산 penalty 설명 필요 | simulation 역전 신호로 보류 |
| `rank_family_decay_v1` | confirmed rank/family pressure | 기존 confirmed rank 저장 재사용 가능성 있음 | 보스 팝업/정산 penalty 필요 | simulation 역전 신호로 보류 |

Stage B 우선 후보 영향 경로:

| Candidate | 저장/복원 | 전투/정산 source of truth | 표시/피드백 | 구현 전 검증 |
|---|---|---|---|---|
| `reward_tax_by_contributor_v1` | 새 저장 schema 없이 `RummiBossModifier` 또는 blind spec에 reward tax 수치가 들어가면 active run save의 boss modifier JSON round-trip 확인 필요 | 전투 점수는 그대로 두고, 정산 reward 계산에서 확정 기여 라인/타일 수 기반 gold tax를 적용한다. 확정된 gold 결과가 source of truth이고 연출 지연값은 저장하지 않는다 | boss popup에 "확정 기여 수에 따라 보상 골드 감소"를 표시하고, settlement/cashout reward line에 tax를 별도 행으로 표시해야 한다 | reward preview, cashout, active run save/restore, final boss run completion reward, economy audit 경로를 함께 확인 |
| `hand_discard_cost_v1` | 손패 버림 횟수 자체를 줄이는 방식이면 기존 blind resource 저장만 사용 가능. "버림 비용"으로 구현하면 gold 변화가 필요해 정산/전투 gold source를 따로 검토해야 함 | 출품 전 1차는 hand discard 0 또는 -1 pressure로만 본다. gold cost 방식은 경제/저장 영향이 커서 별도 승인 전 구현하지 않는다 | boss popup과 전투 HUD의 남은 hand discard 값만으로 읽혀야 하며, 자동 자원 지급이나 hidden correction은 없다 | S2~S3 boss 배치, no-growth route, board/draw stop, active run save/restore를 확인 |

Stage B 구현 원칙:

- `reward_tax_by_contributor_v1`은 전투 점수 penalty가 아니라 정산/economy penalty다.
- `hand_discard_cost_v1`은 먼저 기존 blind resource pressure 계열로만 구현한다. gold cost 방식은 이번 단계에서 제외한다.
- 두 후보 모두 S1~S8 cycle에 바로 넣지 않고 별도 runtime experiment axis 또는 pool 후보로 검증한다.
- 저장 포맷을 늘려야 하는 구현안이 나오면 코드 작성 전에 영향과 검증 경로를 다시 확인한다.

Stage B code path check:

| Candidate | 현재 코드 anchor | 3파일 이하 1차 단위 | 큰 변경으로 넘어가는 경계 |
|---|---|---|---|
| `hand_discard_cost_v1` | `lib/services/blind_selection_spec.dart`의 boss tier `handDiscards` 계산, `lib/views/blind_select_view.dart`의 조건 요약, `test/services/blind_selection_setup_test.dart`의 boss resource/cycle test | S1~S8 cycle 미편입 상태에서 특정 boss spec의 `handDiscards`를 0 또는 `base - 1`로 낮추는 resource-pressure spike. 저장은 기존 `RummiBlindState.handDiscardsRemaining/Max`를 사용한다 | `RummiBossModifier`에 resource category를 추가해 boss popup/chip/title까지 일반화하거나, runtime cycle에 넣어 player-facing boss로 고정하면 `boss_modifier.dart`, blind select UI, active run save round-trip test까지 포함한다 |
| `reward_tax_by_contributor_v1` | `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`의 cash-out command, `lib/logic/rummi_poker_grid/item_effect_runtime.dart`의 settlement reward modifier, `lib/views/game/widgets/game_cashout_widgets.dart`의 reward line 표시 | 문서/시뮬 기준으로는 후보 유지. 코드 1차 단위로 자르려면 reward preview를 바꾸지 않는 internal tax calculation spike부터 분리해야 한다 | boss modifier JSON에 reward tax parameter를 넣거나 cashout sheet에 tax line을 표시하면 저장/복원, final boss reward, economy audit, widget test까지 같이 확인해야 한다 |

Code path 판정:

- 다음 구현은 `hand_discard_cost_v1`의 resource-pressure spike가 가장 작다.
- 이 spike는 저장 포맷을 늘리지 않는다. blind 시작 시 확정된 `handDiscards` 값이 기존 active run save payload에 저장된다.
- 앱 runtime에는 simulator의 `experiment-id`처럼 boss 후보만 주입하는 축이 없다. 현재 `NewRunModifier`는 `basic` / `high_stakes`뿐이고, debug fixture는 QA fixture이지 밸런스 실험 축이 아니다.
- 따라서 `hand_discard_cost_v1` resource spike를 코드에 넣으면 숨은 실험이 아니라 실제 런타임 규칙 변경이다. S1~S8 cycle 편입 전이라도 사람 승인 후 적용한다.
- 단, 이 구현은 아직 player-facing boss modifier 타입 확장이 아니다. 표시명/보스 chip까지 붙이는 순간 보스 modifier taxonomy 확장 작업으로 분리한다.
- `reward_tax_by_contributor_v1`은 재미 가치는 높지만 정산 source of truth와 reward 표시를 건드리므로, hand discard resource spike 이후 별도 작업으로 둔다.

### Stage C: 저장/UI 변경이 필요하지만 재미 가치가 큰 실험

출품 전 즉시 구현 후보는 아니지만, boss전 다양성을 위해 폐기하지 않고 실험 후보로 보존한다.
이 후보들은 구현 전 저장/복원, 표시, 정산 검증 경로를 먼저 따로 제시해야 한다.

| Candidate | Reference pattern | 필요한 변경 | 재미 가치 | 주의 |
|---|---|---|---|---|
| `hand_lock_after_confirm_v1` | #1 | 손패 tile lock 상태 추적, 표시, 복원 | 확정 후 다음 선택이 달라짐 | 선택 불능처럼 보이지 않게 duration 짧게 설계 |
| `delayed_reveal_hand_v1` | #3/#5/#8/#23 | hidden/reveal presentation state, 접근성 표시 | 정보 불완전성으로 전투 리듬 변화 | 값/색 판독 UX가 나빠질 수 있음 |
| `previous_station_memory_v1` | #18 | 이전 Station rank/color 사용 통계 저장 | run 전체의 선택 기억이 생김 | 저장 schema 영향, 승인 필요 |
| `jester_order_shuffle_v1` | #24 | Jester 발동 순서/표시 queue 조정 | 정산 예측과 빌드 안정성 압박 | 정산 feedback이 복잡해짐 |
| `jester_skip_one_v1` | #27 | Jester별 이번 confirm 비활성 상태와 표시 | Jester 의존 빌드에 강한 변주 | UI/정산 feedback 없으면 불공정하게 보임 |

### Redesign 가능 후보

원본 패턴 그대로는 금지 원칙을 건드리지만, 우리 게임의 선택 원칙을 지키는 형태로 바꾸면 후보로 남길 수 있다.

| Reference pattern | 그대로 불가한 이유 | Redesign 방향 |
|---|---|---|
| #25 forced sell 계열 | Jester 판매 강제는 유저 선택 강제 | 보유 Jester 수 또는 최고 rarity Jester 수에 따른 boss tax. 판매는 유저 선택으로 유지 |
| #28 forced selected card 계열 | 특정 타일 포함 강제는 선택 강제 | 지정 조건을 만족하면 bonus만 제공하고, 미충족 penalty는 두지 않음 |
| hidden 계열 | 정보 숨김이 UI 품질을 해칠 수 있음 | 값 전체 숨김보다 색/계열/정산 예상 일부 지연 reveal로 축소 |

## 4.1 Simulation Proxy 1차 적용 상태

2026-05-06 기준으로 아래 후보는 runtime cycle이 아니라 simulation-only experiment axis에 먼저 추가했다.

Experiment id:

- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_probe_v1`

추가된 simulation proxy:

| Proxy | Pattern | 현재 처리 |
|---|---|---|
| `min_contributor_count_v1` | 확정 라인의 최소 기여 타일 수 압박 | 기여 타일 4개 미만 라인 25% penalty |
| `rank_family_decay_v1` | 같은 족보 family 반복 사용 압박 | 이미 쓴 set/sequence/color/hybrid family를 다시 쓰면 15% penalty |
| `confirm_limit_tax_v1` | 후속 확정 tax 압박 | 두 번째 confirm부터 30% penalty, boss target multiplier 0.82 |

r80 exploratory smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 80 --seed 90680 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_probe_v1_r80`
- summary: `logs/sim/boss_expansion_probe_v1_r80_summary.json`
- report: `logs/sim/boss_expansion_probe_v1_r80_report.md`

Path clear:

| Experiment | Loadout | Market | Clear |
|---|---|---|---:|
| current boss pool baseline | balanced | none | 51.25% |
| current boss pool baseline | balanced | v9 | 80.00% |
| current boss pool baseline | power | none | 70.00% |
| current boss pool baseline | power | v9 | 66.25% |
| boss expansion probe v1 | balanced | none | 50.00% |
| boss expansion probe v1 | balanced | v9 | 66.25% |
| boss expansion probe v1 | power | none | 55.00% |
| boss expansion probe v1 | power | v9 | 71.25% |

판정:

- r80은 탐색용이며 gate 완료 근거가 아니다.
- 새 proxy 자체는 실행 가능하고 boss 전투 단위 clear는 모두 91% 이상이었다.
- path 기준으로 `balanced + v9`와 `power + none`이 같은 seed baseline보다 내려가므로, 이 profile을 바로 runtime 편입 후보로 잠그지 않는다.
- 다음은 r120 재확인 또는 severity 완화 profile을 비교한 뒤 안전한 runtime 후보를 좁힌다.

r120 exploratory follow-up:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 906120 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_probe_v1_r120`
- summary: `logs/sim/boss_expansion_probe_v1_r120_summary.json`
- report: `logs/sim/boss_expansion_probe_v1_r120_report.md`

Path clear:

| Loadout | Market | Clear | 주요 병목 |
|---|---|---:|---|
| balanced | none | 48.3% | S4 boss, S5 boss, S8 boss |
| balanced | v9 | 60.8% | S1 boss, S7 boss, S8 boss |
| power | none | 62.5% | S1 boss, S8 boss |
| power | v9 | 69.2% | S1 boss, S7 boss, S8 boss |

Boss 전투 단위 clear:

| Proxy | Clear |
|---|---:|
| `min_contributor_count_v1` | 99.3% |
| `rank_family_decay_v1` | 97.1% |
| `confirm_limit_tax_v1` | 99.1% |

Follow-up 판정:

- `boss_expansion_probe_v1`은 r120에서도 실행 안정성은 있다.
- S1/S7/S8 boss 병목이 남아 있고, v9가 none보다 낮아지는 역전은 없다.
- 단, balanced v9가 60.8%로 과도하게 여유로운 후보는 아니므로 runtime cycle 편입은 아직 보류한다.
- 다음 작은 작업은 severity 완화가 아니라, 후보별 단독 profile 또는 runtime 구현 가능성이 높은 `min_contributor_count_v1` / `confirm_limit_tax_v1` 중심 분리 smoke다.

후보별 r80 split probe:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 80 --seed 90780 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_min_contributor_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_rank_family_probe_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_confirm_limit_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_split_probe_v1_r80`
- summary: `logs/sim/boss_expansion_split_probe_v1_r80_summary.json`
- report: `logs/sim/boss_expansion_split_probe_v1_r80_report.md`

Path clear:

| Profile | Loadout | none | v9 | 1차 판정 |
|---|---|---:|---:|---|
| `min_contributor` | balanced | 66.2% | 60.0% | v9 역전 신호, runtime 보류 |
| `min_contributor` | power | 68.8% | 71.2% | 단독으론 가능하나 balanced 역전 때문에 보류 |
| `rank_family` | balanced | 55.0% | 53.8% | v9 역전 신호, runtime 보류 |
| `rank_family` | power | 65.0% | 68.8% | 단독으론 가능하나 balanced 역전 때문에 보류 |
| `confirm_limit` | balanced | 47.5% | 62.5% | 1차 runtime 후보로 좁힘 |
| `confirm_limit` | power | 57.5% | 71.2% | 1차 runtime 후보로 좁힘 |

Boss 전투 단위 clear:

| Profile | Proxy | Clear |
|---|---|---:|
| `min_contributor` | `min_contributor_count_v1` | 97.9% |
| `rank_family` | `rank_family_decay_v1` | 98.0% |
| `confirm_limit` | `confirm_limit_tax_v1` | 98.7% |

Split 판정:

- `confirm_limit_tax_v1`은 r80 split에서 v9가 none보다 명확히 높고, S1/S8 boss 병목도 남아 있어 1차 runtime 구현 후보로 좁힌다.
- `min_contributor_count_v1`과 `rank_family_decay_v1`은 boss 전투 단위로는 안전하지만 path 기준 balanced v9 역전 신호가 있어 simulation-only 보류한다.
- 다음 작은 작업은 `confirm_limit_tax_v1` runtime 구현 가능 경로 확인이다. 저장 포맷 변경 없이 기존 confirm count 상태로 처리 가능한지, 보스 표시와 정산 penalty가 자연스럽게 이어지는지 먼저 본다.

Runtime path check:

- `confirm_limit_tax_v1`은 runtime modifier로 구현했다.
- 저장/복원은 새 저장 schema 없이 `RummiBossModifier` JSON의 `firstAffectedConfirmOrdinal` 선택 필드로 round-trip한다. 기존 저장 payload는 기본값 3으로 복원되어 `confirm_count_tax_v2` 의미를 유지한다.
- 전투 penalty는 기존 `confirmCountThisStation`과 confirm ordinal 경로를 재사용한다.
- HUD/정산 penalty 표시는 기존 `confirmCountWeaken` category 경로를 재사용한다.
- S1~S8 runtime cycle에는 아직 편입하지 않았다.

r400 leveling revalidation:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 400 --seed 908400 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_boss_expansion_confirm_limit_probe_v1 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/boss_expansion_confirm_limit_v1_r400`
- summary: `logs/sim/boss_expansion_confirm_limit_v1_r400_summary.json`
- report: `logs/sim/boss_expansion_confirm_limit_v1_r400_report.md`

Path clear:

| Loadout | Market | Clear | 주요 병목 |
|---|---|---:|---|
| balanced | none | 50.7% | S1 boss, S4 boss, S8 boss |
| balanced | v9 | 68.8% | S1 boss, S4/S5 boss, S8 boss |
| power | none | 63.5% | S1 boss, S8 boss |
| power | v9 | 69.0% | S1 boss, S7/S8 boss |

Leveling 판정:

- v9가 none보다 낮아지는 역전은 없다.
- S1/S8 boss 병목이 남아 있어 후반 압박을 지우지 않는다.
- `confirm_limit_tax_v1` boss 전투 단위 clear는 98.5%라 단독 boss가 과도하게 막는 후보는 아니다.
- 이 결과는 확장 boss pool 기준 r400 레벨링 probe로 기록한다. 다음 gate는 같은 확장 profile 기준 경제 raw probe다.

## 5. 출품 전 즉시 구현 제외 / 재설계 보존

- hidden card 계열은 UI/정보 reveal 작업이 커서 출품 전 즉시 runtime 구현은 위험하다. 다만 `delayed_reveal_hand_v1`처럼 표시 범위를 줄인 Stage C 후보로 보존한다.
- forced sell / forced selection 계열은 원형 그대로는 유저 선택 강제라 금지한다. 다만 boss tax 또는 bonus-only 조건으로 재설계하면 후보로 남길 수 있다.
- previous Station memory 계열은 새 tracking과 저장/복원 리스크가 있어 Stage C로 둔다.
- very large target 계열은 숫자만 키운 boss로 끝나기 쉬우므로, 먼저 soft/hard target spike simulation proxy로만 본다.
- `TEMP_WORK_SEQUENCE_PLAN.md` 삭제나 공모전 기준 작업 재개는 사람 검토 승인 전까지 하지 않는다.

## 6. Next Step

1. `hand_discard_cost_v1`를 저장 schema 변경 없는 resource-pressure spike로 구현할지 결정한다.
2. 구현한다면 1차 범위는 `BlindSelectionSpec` resource 계산과 해당 service test로 제한하고, S1~S8 cycle 편입과 player-facing boss modifier 일반화는 뒤로 둔다.
3. 앱 runtime에는 독립 boss experiment axis가 없으므로, `hand_discard_cost_v1`도 코드 적용 전 승인 대상으로 둔다.
4. `reward_tax_by_contributor_v1`는 cashout/economy/UI 영향이 커서 별도 구현 계획으로 분리한다.
5. runtime smoke가 안정적이면 확장 boss pool 기준 레벨링/경제/ML 재검증 순서로 돌아간다.
