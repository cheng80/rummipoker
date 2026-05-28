# Leveling Analysis Workspace

이 폴더는 앞으로 새로 쌓을 레벨링 분석 자료와 실제 ML 전환 준비물을 모으는 작업 공간이다.

## 성격 구분

- 이전 feature table, RandomForest 모델, 추천 리포트, notebook은 active workspace에서 제거하고 archive로 내렸다.
- archived 산출물은 현재 런타임 판단 근거가 아니라 `historical prior`다.
- 새 학습 데이터는 현재 runtime/catalog/ruleset/bot policy/feature schema 기준 fresh simulation에서 다시 쌓는다.
- 실제 ML 전환은 pre-outcome feature, supervised target, train/test split, metric, 추천 후보 재시뮬레이션, 사람 승인까지 갖춘 뒤에만 “ML 기반 레벨링”으로 기록한다.
- 휴리스틱 라벨은 향후 초기 `silver label`로만 사용할 수 있다.

## 폴더

- `data/raw/`: 새 fresh simulation 원본 summary/JSONL에서 선별해 둘 입력 자료.
- `data/features/`: 새 모델링 준비용 feature table metadata와 lightweight descriptor.
- `generated/`: 새 feature CSV 등 재생성 가능한 heavy 산출물. git 추적 제외.
- `models/`: 새 모델과 metric 산출물.
- `reports/`: 새 분석 리포트와 사람 검토용 보고서.
- `archive/`: 로컬 old generated artifacts. git 추적 제외.

## Legacy Artifacts

- tracked legacy outputs: `docs/archive/leveling/legacy_ml_outputs_2026_05/`
- ignored generated legacy outputs: `analysis/leveling/archive/legacy_pre_20260529/`
- ignored simulation logs: `logs/archive/legacy_pre_20260529/sim/`

## Next Data Rule

새 ML/레벨링 작업은 archive 데이터를 feature table에 바로 섞지 않는다. 먼저 현재 코드로 fresh run을 만들고, 필요하면 archive는 후보 축과 과거 실패/성공 패턴을 찾는 참고 자료로만 본다.
