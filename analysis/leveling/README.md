# Leveling Analysis Workspace

이 폴더는 레벨링 분석 자료와 향후 실제 ML 전환 준비물을 모으는 작업 공간이다.

## 성격 구분

- 현재 레벨링 기준은 시뮬레이션과 휴리스틱 진단 라벨에 기반한다.
- 이 폴더의 현재 산출물은 실제 ML 전환 완료 증거가 아니라, 기존 summary를 feature table 형태로 보존하고 모델링 리포트 형식을 시험한 스캐폴딩이다.
- 현재 `models/`와 `reports/`의 RandomForest 결과는 outcome-derived feature로 `clear_rate`를 설명하는 baseline이다. target/boss/market/economy 값을 추천해 적용하는 intervention model이 아니다.
- 실제 ML 전환은 pre-outcome feature, supervised target, train/test split, metric, 추천 후보 재시뮬레이션, 사람 승인까지 갖춘 뒤에만 “ML 기반 레벨링”으로 기록한다.
- 휴리스틱 라벨은 향후 초기 `silver label`로만 사용할 수 있다.

## 폴더

- `data/raw/`: 원본 summary JSON 또는 장기 sweep 산출물 복사본.
- `data/features/`: 모델링 준비용 tabular feature table.
- `models/`: 스캐폴딩 모델과 metric 산출물. 현재 런타임 적용 근거가 아니다.
- `notebooks/`: 사람이 읽고 검토하기 위한 Jupyter notebook.
- `reports/`: MD 기반 분석 리포트와 향후 ML 전환 요구사항.
