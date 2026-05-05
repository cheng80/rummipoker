# Deprecated Current Leveling ML Baseline

> 이 파일명은 과거 호환용으로만 남긴다.
> 현재 기준 문서는 `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md`다.
> 이 경로를 supervised model, train/test split, validation metric이 있는 실제 머신러닝 기준으로 인용하지 않는다.

현재 레벨링 기준은 시뮬레이션 결과와 규칙 기반 휴리스틱 라벨 해석이다.

`analysis/leveling/`의 현재 feature table과 RandomForest 산출물은 실제 ML 전환 완료 증거가 아니다. outcome-derived summary feature로 `clear_rate`를 설명하는 스캐폴딩이며, target/boss/market/economy 후보를 추천하거나 런타임에 적용하지 않는다.

향후 실제 머신러닝 전환 시에는 pre-outcome feature, supervised target, train/test split, metric, 후보 재시뮬레이션, 사람 승인 절차를 갖춘 뒤에만 “ML 기반 레벨링”으로 기록한다. 휴리스틱 라벨은 초기 `silver label`로만 사용한다.
