# Heuristic Leveling Simulation Direction

> 문서 성격: current leveling entry / active summary
> 명칭 주의: 이 문서는 파일명에 `ML`이 남아 있지만, 현재 내용은 학습 모델을 적용한 머신러닝 기준이 아니다.
> 현재 단계는 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 진단 라벨, 사람이 승인하는 레벨링 적용 절차다.
> 실제 머신러닝 전환 전까지 이 문서를 “AI가 학습해 밸런스를 자동 조정한다”는 근거로 사용하지 않는다.
> 현재 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 시뮬레이션/휴리스틱 기준: `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> 적용 상태: `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`
> 긴 실험 이력: `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`

## 용어 정정

- 이 문서와 일부 기존 파일명/도구명의 `ML`은 역사적 이름이다.
- 현재까지 실제 적용된 것은 supervised model, train/test split, validation metric이 있는 학습 모델이 아니다.
- 현재 파이프라인은 “시뮬레이션 기반 레벨링 분석”과 “규칙 기반 휴리스틱 라벨링”이다.
- 기존 `analysis/leveling/` feature table과 RandomForest 리포트는 active workspace에서 내리고 `docs/archive/leveling/legacy_ml_outputs_2026_05/`에 보관한다.
- 향후 실제 ML 전환 시에는 현재 runtime/catalog/ruleset/bot policy 기준 fresh simulation 결과를 새 feature table로 정리하고, 휴리스틱 라벨은 초기 `silver label`로만 사용한다.
- 모델 추천은 런타임 자동 적용이 아니라 후보 추천, 재시뮬레이션 검증, 사람 승인 후 적용 순서로 다룬다.

## 현재 확정 정책 요약

- 레벨링은 특정 성장 루트를 유저에게 강제하거나 보장하지 않는다.
- S1 첫 클리어 보너스 골드 외에는 유저에게 공짜 지급이 없다.
- 아이템, Jester, Pack, Tarot-like, Planet-like, 덱 타일, board discard, hand discard, max hand size, slot은 자동 지급하지 않는다.
- 레벨링이 조정할 수 있는 것은 `target score`, `boss constraint`, `market candidate availability`, `rarity/tag/category/slot weight`, 병목 허용치다.
- 특정 구간까지 필요한 성장축을 얻지 못했더라도 직접 지급하지 않는다. 허용되는 보정은 마켓 등장 확률과 슬롯 노출 확률 조정뿐이다.
- 후보가 마켓에 등장해도 구매, 판매, 장착, 사용은 유저 선택이다.
- 마켓 보정은 특정 offer slot 위치를 고정하지 않는다. 후보 위치는 stage/reroll/rng에 따라 흔들려야 한다.
- Rare/Legendary는 초반에도 확률 0으로 막지 않는다.

## 과거 실험 해석 주의사항

- `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`는 과거 실험 로그이며 현재 정책 기준이 아니다.
- 과거 문서의 `resource`, `sustain`, `voucher_resource`, `resource +1`, `soft_resource` 표현은 당시 sim proxy 이름으로만 본다.
- 자동 resource +1이 포함된 과거 experiment는 실제 적용 후보가 아니라 폐기/비교용 이력이다.
- bot 선택은 유저 선택 성향 proxy다. bot이 구매한 결과를 게임이 지급해야 한다는 뜻으로 해석하지 않는다.
- archive 내용을 실제 적용 후보로 되살리려면 먼저 `CURRENT_LEVELING_POLICY.md`에 맞게 요약/승격한 뒤 검토한다.

## 데이터 신뢰도 기준

- 과거 시뮬레이션 데이터는 현재 게임의 결론값이 아니라 방향성 참고다.
- 새 카드, 족보 성장, 슬롯 해금, 마켓/경제/보스 룰, 저장/정산 경로, bot policy가 바뀐 뒤에는 최신 runtime/catalog/ruleset으로 fresh resimulation을 다시 실행해야 한다.
- 오래된 clear rate, 구매 event, path clear, ML 추천표는 현재 제출/레벨링 판단을 닫는 근거로 쓰지 않는다.
- 구 산출물은 너무 많은 상태라 active workspace에서 제거했다. 새 학습/레벨링 데이터셋은 archive를 이어붙이지 않고 fresh run부터 다시 누적한다.
- 과거 row를 feature table에 포함할 때는 `balance_version`, `ruleset_id`, `catalog_versions`, `experiment_id`, `market_profile`, `bot_policy`를 유지해 최신 row와 같은 그룹으로 섞이지 않게 한다.
- 현재 판단은 `planner_v2` 같은 기존 proxy와, 실제 full-run 판단을 일반화한 `full_run_policy_v1` 같은 최신 proxy를 나란히 비교한 fresh 결과를 우선한다.

## 현재 분석 판단

- v84~v86 smoke 기준에서 `shop_slot_market_v9`는 점수 전환 후보를 충분히 노출한다.
- 잔여 S8 boss 실패는 주로 deck exhausted 쪽이며, 즉시 target 하향이나 자동 자원 지급으로 풀지 않는다.
- 다음 검토 후보는 S7~S8 boss 구간에서 덱/타일 형상 보정 후보가 마켓 후보군에 안정적으로 포함되는지 확인하는 것이다.
- 이 후보도 직접 지급이 아니라 market-only availability/weight 조정으로만 본다.

## 마켓 수집 audit 기준

- 수집 audit의 질문은 “모든 후보가 보이는가”, “실제로 살 수 있는가”, “못 산다면 돈/슬롯/후보 필터 중 어디서 막히는가”다.
- `runtime_market_offer_audit`는 독립 샘플뿐 아니라 한 run의 `seen/bought` 기록을 누적하는 collection path를 함께 출력한다.
- 현재 수집 보정은 Jester/Item 모두 미구매 +45, 미노출 +90 가중치다. 직접 지급, 자동 구매, 특정 슬롯 고정은 아니다.
- 기본 판정은 800개 fresh path, S1~S8, stage당 3회 market entry를 사용한다.
- 의미 있는 결과로 보려면 `seen coverage`, `bought coverage`, `gold blocked`, `capacity blocked`, `unseen/unbought ids`를 함께 본다. coverage만 높고 `gold blocked`가 높으면 확률 문제가 아니라 구매력 병목이다.
- `gold blocked`는 전체 수집 완료 전 `pre_collection_*`와 전체 합계를 나눠 본다. 전체 수집 완료 뒤 반복 구매 시도에서 나온 blocked는 수집 가능성 실패로 보지 않는다.
- 골드 병목 분리를 위해 표준 cashout path와 넉넉한 affordability path를 나란히 돌린다.
- 구매 우선순위 비교는 먼저 `planner_v2`와 `full_run_policy_v1`를 나란히 둔다. 같은 경제에서 clear가 크게 갈리면 가격/보상보다 bot policy 또는 플레이 판단 proxy 차이를 먼저 본다.
- choice mode 확대는 r20에서 차이가 난 축만 r80/r120으로 좁혀 돌린다. 전체 12축 장기 실행은 기본 test suite가 아니라 수동 probe로 둔다.

## 다음 작업 기준

1. 실제 적용 전 `CURRENT_LEVELING_POLICY.md`를 먼저 확인한다.
2. 기존 장기 sweep 맥락을 볼 때만 archive history를 검색한다.
3. 조정 후보를 적을 때마다 “직접 지급인가, 마켓 노출인가?”를 먼저 판정한다.
4. 직접 지급으로 읽히는 후보는 폐기하거나 market-only 후보로 다시 번역한다.

## 2026-06-03 fresh small probe gate

- evidence: `.omo/evidence/task-9-small-probe.md`
- current input: `data/common/items_common_v1.json`, `data/common/jesters_common_phase5.json`
- archive input: none
- runtime offer audit now treats the normal item market denominator as 86 current normal-market candidates, excluding the 5 hold/redesign item IDs.
- S1-S4 standard tiny sequence probe is advisory-only. `none` and `shop_slot_market_v9` both had path_clear_rate 0.0 in the small sample, while avg_total_score_ratio stayed near 1.03.
- Early-game overpowered Fate/watchlist frequency was not observed from the sequence purchase trace; catalog watchlist content/source purchase events were 0 in this probe.
- Do not apply pricing, target, rarity, or market weight changes from this probe alone. Broad S1-S8 multi-seed restart must start from current catalog/runtime artifacts, not archived ML outputs.
