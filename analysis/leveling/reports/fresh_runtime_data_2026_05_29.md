# Fresh Runtime Data 2026-05-29

## 목적

기존 archive ML/시뮬레이션 산출물을 현재 판단 근거로 재사용하지 않고, 현재 runtime/catalog/ruleset/bot policy 기준 fresh row를 다시 쌓기 시작한다.

## 실행

- command: `dart run tools/sim/run_balance_sim.dart --runs 200 --bot planner_v2 --seed 93300 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic`
- raw JSONL: `logs/sim/fresh_runtime_20260529_planner_r200.jsonl`
- summary: `logs/sim/fresh_runtime_20260529_planner_r200_summary.json`
- economy audit: `logs/sim/fresh_runtime_20260529_planner_r200_economy_audit.json`

`logs/`는 git ignored 산출물이다. 이 리포트만 tracked 요약으로 남긴다.

## 결과

- JSONL rows: 5,049
- battle run count: 4,249
- sequence run count: 800
- matrix:
  - loadout: `progression_route_balanced`, `progression_route_power`
  - market: `none`, `shop_slot_market_v9`
  - run modifier: `basic`
  - difficulty: `standard`

Sequence path clear rate:

| Loadout | Market | Runs | Clear rate |
|---|---|---:|---:|
| `progression_route_balanced` | `none` | 200 | 0.0% |
| `progression_route_power` | `none` | 200 | 0.0% |
| `progression_route_balanced` | `shop_slot_market_v9` | 200 | 0.0% |
| `progression_route_power` | `shop_slot_market_v9` | 200 | 0.0% |

Economy audit highlights:

- offered slots: 3,609
- purchase events: 2,595
- missing cost events: 1,542
- known spend: 14,017G
- reroll spend: 6,406G
- final gold average:
  - `none`: 24.86G
  - `shop_slot_market_v9`: 7.86G
- immediate economy warning: none
- weak point: raw JSONL 구매 이벤트 절반 이상이 `cost=null`이라 실제 가격 산정 근거로는 아직 약하다.

## 해석

- 5000행 이상 fresh data 축적 조건은 충족했다.
- 단, `planner_v2` 기반 수집은 빠른 fresh data bootstrap이다. 사용자가 말한 “기존 풀런봇 수준의 런타임 진행 계약”을 완전히 대체하지 않는다.
- 중단한 `contest_policy_v1 --runs 160`은 15분 이상 CPU를 계속 사용했지만 종료 파일을 만들지 못했다. 장기 데이터 축적용 runner는 chunk 단위 flush/progress 출력 또는 병렬 chunk runner가 필요하다.

## 다음 작업

1. `contest_policy_v1` 또는 full-runbot급 policy를 chunked data runner로 실행해 중간 산출물을 잃지 않게 한다.
2. `shop_slot_market_v9` 구매 이벤트에 source candidate id와 실제 cost를 더 많이 남겨 missing cost 비중을 낮춘다.
3. 5,049 fresh row를 feature table builder의 새 입력으로 연결하되, archive row는 섞지 않는다.
