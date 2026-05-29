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

## Trace 보강

- `market_purchase_events`에서 `shop_slot_market_v9` 같은 sim policy container는 실제 구매가 아니므로 제외한다.
- 실제 후보 이벤트에는 `selected_profile`, `scaled_cost`, `effective_cost`, `gold_before_market`, `gold_after_market`, `affordable`, `blocked_reason`을 남긴다.
- source backlog 후보가 있는 이벤트는 `source_candidate_id`, `source_candidate_profile`을 평탄 필드로 함께 남긴다.
- smoke command: `dart run tools/sim/run_balance_sim.dart --runs 20 --bot planner_v2 --seed 93400 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic`
- smoke audit: rows 510, purchase events 128, missing cost events 0, known spend 1,584G.
- top purchased content에서 `shop_slot_market_v9`가 제거되고 실제 proxy/item/pack/planet/voucher id만 남는다.

## 외부 검토 자료 반영

사용자가 제공한 `rummipoker_leveling_ml_final_recommendations.md`의 결론은 현재 방향과 일치한다.

- 외부 카드/RL 데이터셋을 직접 붙이지 않고, 현재 Dart simulator와 bot policy로 fresh JSONL을 만든다.
- 첫 단계는 ML이 아니라 station/blind/bot/loadout/market별 통계 리포트다.
- 초기 supervised target은 `score_ratio = final_score / target_score`와 `cleared`가 적합하다.
- 강화학습은 legal action mask와 env 동기화 비용이 크므로 후순위다.
- 모델은 candidate JSON과 보고서만 만들고, runtime balance는 사람 검토 후 별도 반영한다.

이에 맞춰 `run_balance_sim.dart --flush-every-rows`, `tools/sim/chunked_balance_run.py`, `tools/sim/summarize_balance_jsonl.dart`를 fresh data runner 기반으로 둔다.

## 다음 작업

1. `contest_policy_v1` 또는 full-runbot급 policy를 chunked data runner로 실행해 중간 산출물을 잃지 않게 한다.
2. 보강된 trace schema로 5,000행 이상 fresh row를 다시 생성해 economy/market 학습 입력으로 승격한다.
3. 5,049 fresh row와 trace-fix 이후 fresh row를 feature table builder의 새 입력으로 연결하되, archive row는 섞지 않는다.
