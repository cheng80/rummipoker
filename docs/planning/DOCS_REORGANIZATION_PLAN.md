# Docs Reorganization Plan

> GCSE role: `Execution`
> Source of truth: 문서 재구성 작업 계획.

이 문서는 `docs/` 문서를 목적형 폴더로 정리하고, 각 폴더의 GCSE 역할을 명시하기 위한 실행 계획이다.

## Goal

- 문서별 책임을 분리한다.
- 진행 상태와 기능 명세가 섞이지 않게 한다.
- 새 세션에서 읽을 문서 체인을 짧게 유지한다.
- 중복 문서는 삭제 전에 archive 후보로 격리한다.

## Phase 1: Non-Destructive Setup

상태: 완료

- [x] `docs/00_docs_README.md` 추가
- [x] `docs/goals/00_goals_README.md` 추가
- [x] `docs/current_system/00_current_system_README.md` 추가
- [x] `docs/specs/00_specs_README.md` 추가
- [x] `docs/planning/00_planning_README.md` 추가
- [x] `docs/archive/00_archive_README.md` 추가
- [x] `docs/archive/legacy/00_legacy_README.md` 추가
- [x] `docs/archive/generated/00_generated_README.md` 추가
- [x] `docs/archive/prompts/00_prompts_README.md` 추가
- [x] `START_HERE.md`를 목적형 문서 진입점으로 축소
- [x] 핵심 기존 문서에 역할 배너 추가
- [x] `current_system`을 코드 기준 작업 재개 패킷으로 승격
- [x] `CURRENT_CODE_MAP.md`를 코드 작업 재개 기준 문서로 전체 재작성
- [x] 기준 문서에 코드 기준 3종 문서 원칙 명시

## Phase 2: Move and Link Update

상태: 완료

- [x] Current context 문서를 `docs/current_system/`로 이동
- [x] V4 spec 문서 세트를 `docs/specs/V4/`로 이동
- [x] Review checklist를 `docs/planning/STATUS.md`로 이동
- [x] Implementation plan을 `docs/planning/IMPLEMENTATION_PLAN.md`로 이동
- [x] Item effect matrix를 `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`로 이동
- [x] Board move / hand size feature plan을 `docs/planning/feature_plans/`로 이동
- [x] Web build guide를 `docs/planning/verification/`로 이동
- [x] Combined generated snapshot을 `docs/archive/generated/`로 이동
- [x] Codex planning prompt를 `docs/archive/prompts/`로 이동
- [x] 기존 `docs/archive/*` 문서를 `docs/archive/legacy/`로 이동
- [x] Risk register를 `docs/planning/IMPLEMENTATION_PLAN.md`에 흡수
- [x] Traceability matrix를 `docs/planning/IMPLEMENTATION_PLAN.md`에 흡수
- [x] 절대 링크와 상대 링크를 새 경로로 갱신
- [x] GCSE 약어 폴더명을 목적형 폴더명으로 변경
- [x] 폴더 정의서 파일명을 목적형 폴더명 기준으로 변경

## Phase 3: Duplication Reduction and Semantic Split

상태: 진행 중

- [x] `RUMMI_POKER_GRID_V4_COMBINED.md`가 개별 원본보다 우선하지 않도록 모든 진입 링크에서 제외
- [x] `goals` 폴더에 제품 목표 요약 문서 추가
- [x] `RISK_REGISTER.md`를 `IMPLEMENTATION_PLAN.md`에 흡수
- [x] `TRACEABILITY_MATRIX.md`를 `IMPLEMENTATION_PLAN.md`에 흡수
- [x] `CURRENT_CODE_MAP.md`의 legacy order 블록을 전체 재작성으로 제거
- [x] `specs/V4`에서 current baseline을 `current_system`으로 분리
- [x] `specs/V4`에서 migration roadmap, QA acceptance, open decisions를 `planning`으로 분리
- [x] `specs/V4`에서 changelog와 master summary를 `archive`로 분리
- [x] `specs/V4/00_README.md`를 기능 명세 색인으로 재작성
- [x] `START_HERE.md`의 다음 작업 정보가 `STATUS.md`와 중복되지 않는지 재확인
- [x] Item/Jester-Market spec의 item catalog 수량과 runtime 상태를 실제 데이터/계획 문서 기준으로 갱신
- [x] `planning/IMPLEMENTATION_PLAN.md`와 `planning/MIGRATION_ROADMAP.md` 중복 범위 축소
- [x] `03_RUN_META_ECONOMY.md`를 run meta / Station / economy 계약 중심으로 재작성
- [x] `04_JESTER_MARKET_CONTENT.md`를 Jester / Item / Market 계약 중심으로 재작성
- [x] `05_SAVE_CHECKPOINT_DATA.md`를 save compatibility / checkpoint / data model 계약 중심으로 재작성
- [x] `06_UI_UX_FLOW.md`를 UI/UX 계약 중심으로 재작성
- [x] `07_TECHNICAL_ARCHITECTURE.md`를 target architecture / refactor contract 중심으로 재작성
- [x] 기능별 spec 문서 내부의 current 상세 중복을 `current_system` 참조로 축소
- [x] `02_CORE_COMBAT_RULES.md`의 규칙 표기 라벨을 `[CURRENT]` 중심에서 `[V4_DECISION]` 중심으로 정리
- [x] `STATUS.md`는 최신 상태만 남기고 기존 상세 이력은 `docs/archive/legacy/V4_STATUS_HISTORY_2026-04-22.md`로 이동
- [x] `archive`를 기존 이력/맥락 검색용 참고 자료로 정의 보강

## Guardrails

- 새 문서는 목적형 폴더 기준 위치에 추가한다.
- 파일 이동은 링크 갱신과 같은 작업 단위로 처리한다.
- 최신 진행 상태는 한 문서에만 기록한다.
- archive 문서는 최신 구현 기준으로 직접 사용하지 않는다.
