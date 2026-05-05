# Leveling Tools

이 폴더는 시뮬레이션 기반 레벨링 분석을 향후 실제 ML 추천 파이프라인으로 전환하기 위한 스캐폴딩 스크립트를 둔다.

현재 스크립트 산출물은 실제 ML 전환 완료 증거가 아니다. `train_leveling_model.py`의 기본 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target/boss/market/economy 후보를 추천해 적용하는 모델이 아니다.

## Scripts

- `build_feature_table.py`
  - `run_balance_sim.dart` summary JSON을 tabular feature table CSV로 변환한다.
  - 기존 `ml_labels` key는 호환을 위해 읽되, 출력 feature table에서는 `heuristic_labels`로 기록한다.

- `train_leveling_model.py`
  - feature table을 train/test split으로 나누고 RandomForest 회귀 모델을 학습한다.
  - metric과 feature importance를 `analysis/leveling/models/`에 저장한다.
  - 결과 리포트는 `analysis/leveling/reports/model_recommendation_report.md`에 저장한다.
  - 현재 목적은 모델링 포맷과 재현성을 확인하는 것이다. 추천 후보 생성과 runtime 적용은 아직 하지 않는다.

## Policy

모델 결과는 런타임 자동 적용값이 아니다. 실제 ML 전환 단계에서도 모델은 후보 추천 근거를 만들 뿐이며, 후보는 재시뮬레이션과 사람 승인 후에만 코드나 데이터에 반영한다.
