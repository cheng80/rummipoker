# Deprecated Analysis Workspace 2026-05

이 폴더는 2026-05 시점에 top-level `analysis/` 아래 있던 ML/LLM/레벨링 실험 산출물을 보관한 archive다.

## 판정

- 현재 게임 정책, 레벨링, 출시 판단의 source-of-truth가 아니다.
- ML 기반 후보 추천은 실무 효과를 확보하지 못했으므로 더 이상 새 자료를 쌓는 경로로 보지 않는다.
- LLM autoplay 자료는 대량 밸런스 기준이 아니라 폐기된 전략 샘플 실험 이력이다.
- 새 구현 판단은 실제 런타임 코드, 테스트, current/spec/planning 문서를 우선한다.

## 내용

- `data/features/`: 당시 feature metadata.
- `models/`: 당시 metric, feature importance, candidate recommendation.
- `reports/`: 당시 fresh policy, LLM station path, smoke report.
- Git에 추적되지 않던 대용량 generated CSV 잔여물은 같은 archive 묶음의 `local_ignored_generated/` 아래로 격리하되 Git에는 올리지 않는다.

## 재사용 금지 기준

- archive 데이터를 새 feature table에 이어붙이지 않는다.
- archive metric이나 recommendation을 현재 밸런스 후보의 근거로 쓰지 않는다.
- 필요한 교훈은 current/spec 문서로 별도 승격한 뒤 사용한다.
