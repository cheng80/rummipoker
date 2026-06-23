# archive Folder Definition

`docs/archive/`는 최신 source of truth가 아니지만, 과거 설계 맥락과 문서 생성 이력을 검색하기 위한 참고 자료를 보관하는 폴더다.

이 폴더는 문서 archive 전용이다. 실행 로그, 노트북, 실험 스크립트, 모델/CSV 산출물, 캐시처럼 문서가 아닌 자료는 루트 `archive/` 아래에 보관한다.

## Purpose

- 과거 설계 문서, 생성 병합본, 과거 프롬프트를 보존한다.
- 기존 이력과 의사결정 배경을 검색할 때 참조할 수 있게 한다.
- 현재 문서 체계에서 기준 역할을 잃은 스냅샷과 중복 요약본을 보존한다.
- 현재 판단 기준과 충돌할 때는 최신 문서를 우선한다.
- archive에서 유효한 내용을 다시 쓰려면 최신 목적형 문서로 승격/요약한 뒤 사용한다.
- 비문서 산출물은 `docs/archive/`로 넣지 않는다. 예: ML/LLM 실험 도구와 로그는 루트 `archive/analysis_legacy_2026_05/`에 둔다.

## Subfolders

- `legacy/`: 과거 설계와 구현 참고 문서
- `generated/`: 병합본, 스냅샷, 자동 생성 산출물
- `prompts/`: 과거 AI/Codex 지시서와 프롬프트
- `feature_plans_2026_04/`: 완료되었거나 현재 기준 역할을 잃은 2026-04 feature plan 스냅샷
- `feature_plan_history/`: planning에서 내려온 과거 feature plan과 prompt
- `leveling/`: 긴 레벨링 시뮬레이션 이력과 과거 후보 기록
- `leveling/automation_ml/`: 현재 spec에서 제외한 balance automation/ML 문서
- `leveling/llm_experiment_history/`: LLM autoplay/setup 실험 문서
- `leveling/target_curve_history/`: 과거 target curve 계산/brief 문서
- `competition_history_2026_06/`: 닫힌 공모전 제출 이력과 full-run bot 증거 참고
- `verification_daily_logs/`: 과거 날짜별 검증 로그
- `planning_superseded/`: 현재 planning에서 제외한 문서 정리/폴더 설명 snapshot
- `redundant_build_docs/`: release 문서로 흡수한 중복 build 문서
- `visual_asset_reviews/`: 특정 시점의 이미지/asset 검수 결과
- `delete_candidates_after_parity/`: 삭제 전 parity 확인이 필요한 구 앱 자료
- `docs_reorganization_2026_06/`: 문서 재정리 판정표와 작업 이력

## Rule

`archive` 문서는 직접적인 구현 기준으로 사용하지 않는다. 필요한 경우 최신 `goals`, `current_system`, `specs`, `planning` 문서로 내용을 승격한 뒤 사용한다.
