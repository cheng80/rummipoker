# Leveling Tools

이 폴더는 과거 시뮬레이션 기반 레벨링/ML 스캐폴딩 스크립트를 둔다. 현재 게임 정책에서는 새 ML 자료 축적 경로로 쓰지 않는다.

현재 스크립트 산출물은 실제 ML 전환 완료 증거가 아니다. `train_leveling_model.py`의 기본 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target/boss/market/economy 후보를 추천해 적용하는 모델이 아니다.

`--feature-mode preoutcome` 산출물도 legacy scaffold다. production ML이나 런타임 자동 밸런스 조정이 아니다.

## Scripts

- `build_feature_table.py`
  - `run_balance_sim.dart` summary JSON을 tabular feature table CSV로 변환한다.
  - 기존 `ml_labels` key는 호환을 위해 읽되, 출력 feature table에서는 `heuristic_labels`로 기록한다.
  - `--feature-mode preoutcome`은 outcome summary feature를 제외한 planned transition용 table을 만든다.

- `train_leveling_model.py`
  - feature table을 train/test split으로 나누고 RandomForest 회귀 모델을 학습한다.
  - metric과 feature importance를 `.omo/legacy_leveling/models/`에 저장한다.
  - 결과 리포트는 `.omo/legacy_leveling/reports/model_recommendation_report.md`에 저장한다.
  - `--feature-mode preoutcome`은 `.omo/legacy_leveling/reports/preoutcome_baseline_model_report.md`에 planned transition scaffold report를 저장한다.
  - 현재 목적은 모델링 포맷과 재현성을 확인하는 것이다. 추천 후보 생성과 runtime 적용은 아직 하지 않는다.

## Policy

모델 결과는 런타임 자동 적용값이 아니다. 현재 정책에서는 후보 추천 근거로도 사용하지 않는다.

현재 사람 검토용 연결 보고서는 `.omo/legacy_leveling/reports/preoutcome_candidate_resimulation_report.md`다.

## Fresh Data Runner

장기 로그 수집은 `tools/sim/chunked_balance_run.py`를 우선 사용한다. 이 runner는 `run_balance_sim.dart`를 여러 chunk로 나눠 실행하고, 각 chunk JSONL/summary, merged JSONL, merged summary, manifest를 남긴다. 긴 `full_run_policy_v1` 실행이 중간에 끊겨도 완료된 chunk를 재사용할 수 있게 하기 위한 도구다.

`run_balance_sim.dart`는 `--flush-every-rows`를 지원한다. 장기 실행에서는 stdout progress와 디스크 flush를 남겨, 프로세스가 중단되어도 raw JSONL 손실 범위를 줄인다.

Bot별 로그는 섞지 않는다. `greedy_v1`, `planner_v2`/`planner_v3`, `full_run_policy_v1` 데이터는 같은 stage라도 다른 플레이어 proxy로 해석한다.

## Market Collection Audit

전체 수집 가능성은 `tools/sim/runtime_market_offer_audit.dart`의 collection audit로 확인한다. 이 audit는 한 run의 `seen/bought` 기록을 누적하면서 S1~S8 market entry를 통과해, 모든 Jester/Item이 실제로 보이는지와 살 수 있는지, 그리고 실패가 돈/슬롯 중 어디서 나는지를 분리한다.

예시 실행은 Flutter test wrapper인 `test/tools/sim/runtime_market_collection_audit_smoke_test.dart`를 사용한다. 현재 기준 산출물은 `logs/sim/runtime_market_collection_audit_standard_r800_20260511_064500.json`과 `logs/sim/runtime_market_collection_audit_affordability_r800_20260511_064500.json`이다.

## Historical Data

과거 시뮬레이션 CSV/JSON/리포트는 최신 게임 밸런스의 직접 증거가 아니다. 새 카드, 족보 성장, 슬롯 해금, 마켓/경제, 보스 룰, 저장/정산 경로, bot policy가 바뀌면 최신 runtime과 catalog로 fresh resimulation을 다시 만든다.

과거 row를 분석에 포함할 때는 `balance_version`, `ruleset_id`, `catalog_versions`, `experiment_id`, `market_profile`, `bot_policy`를 보존한다. 이 값이 다른 row는 같은 신뢰도로 섞지 않고, historical prior 또는 비교 이력으로만 사용한다.
