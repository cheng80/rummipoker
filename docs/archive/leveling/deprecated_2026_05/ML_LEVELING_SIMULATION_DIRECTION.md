# Deprecated ML Leveling Simulation Direction

> 이 파일명은 과거 호환용으로만 남긴다.
> 현재 기준 문서는 `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`다.
> 이 경로를 “AI가 학습해 밸런스를 자동 조정한다”는 근거로 사용하지 않는다.

현재 레벨링 분석은 학습 모델이 아니라 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 휴리스틱 진단 라벨, 사람 승인 절차에 기반한다.

기존 `analysis/leveling/` feature table과 RandomForest 결과는 active workspace에서 제거하고 `docs/archive/leveling/legacy_ml_outputs_2026_05/`에 보관한다. 해당 산출물은 기존 summary를 구조화하고 설명 baseline을 시험한 스캐폴딩이며, 현재 판단 근거가 아니다.

실제 ML 전환은 현재 runtime/catalog/ruleset/bot policy 기준 fresh data에서 pre-outcome feature, supervised target, train/test split, 모델 학습, metric 검증, 후보 추천, 후보 재시뮬레이션을 갖춘 뒤에만 “ML 기반”으로 부른다.
