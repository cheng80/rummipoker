# Analysis Legacy 2026-05

이 폴더는 top-level `analysis/`, ML/LLM 실험 도구, 노트북, 실행 로그를 current root에서 제거하고 보관한 root archive다.

## 판정

- `analysis/`는 현재 게임 정책, 출시, 레벨링 판단의 active source-of-truth가 아니다.
- 과거 ML/LLM autoplay/feature table 실험은 실무 효과를 확보하지 못했으므로 더 이상 새 자료를 쌓는 경로로 보지 않는다.
- 현재 판단은 코드, 테스트, `docs/current_system/`, `docs/specs/`, `docs/planning/`에 승격된 내용만 따른다.

## 구성

- `analysis/leveling/`: Git에 추적되던 2026-05 ML/LLM/레벨링 실험 산출물.
- `notebooks/`: ML 레벨링 워크벤치 노트북.
- `tools/leveling/`: 과거 feature table, baseline model, candidate recommendation 스크립트.
- `tools/llm_agent/`: 과거 LLM autoplay/smoke 실험 도구.
- `tools/sim_ml/`: ML sweep/report 계열 시뮬레이션 보조 스크립트.
- `tests/tools/sim/`: 위 ML 보조 스크립트 전용 테스트.
- `local_ignored_generated/`: Git에 올리지 않는 대용량 generated CSV, logs, cache 잔여물. 로컬 보관용이며 current 문서/도구가 참조하지 않는다.

## 재사용 금지

- 이 archive의 metric, model, recommendation, generated CSV를 현재 밸런스 후보 근거로 쓰지 않는다.
- 필요한 교훈은 active current/spec/planning 문서로 별도 승격한 뒤 사용한다.
