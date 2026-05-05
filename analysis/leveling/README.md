# Leveling Analysis Workspace

이 폴더는 레벨링 분석과 실제 ML 전환 산출물을 모으는 작업 공간이다.

## 성격 구분

- 기존 레벨링 기준은 시뮬레이션과 휴리스틱 진단 라벨에 기반한다.
- 실제 ML 전환은 feature table, train/test split, 모델 학습, metric 검증, 후보 재시뮬레이션을 갖춘 뒤에만 이 폴더의 `models/`와 `reports/`에 기록한다.
- 휴리스틱 라벨은 초기 `silver label`로만 사용한다.

## 폴더

- `data/raw/`: 원본 summary JSON 또는 장기 sweep 산출물 복사본.
- `data/features/`: 모델 학습용 tabular feature table.
- `models/`: 학습된 모델과 metric 산출물.
- `notebooks/`: 사람이 읽고 검토하기 위한 Jupyter notebook.
- `reports/`: MD 기반 분석 리포트.
