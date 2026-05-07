# START_HERE

이 문서는 새 세션에서 가장 먼저 읽는 진입 문서다.

상세 진행률, 긴 변경 내역, 검증 로그는 여기 두지 않는다. 최신 진행 상태는 `planning` 성격의 문서를 source of truth로 본다.

## 문서 체계

이 프로젝트 문서는 목적형 폴더로 정리하고, 각 폴더의 `GCSE` 역할을 정의한다.

- `goals`: Goal, 제품 목표, 방향성, 의사결정 원칙
- `current_system`: Context, 현재 코드/시스템 상태와 배경 맥락
- `specs`: Spec, 기능 규칙, UX, 데이터 계약, 아키텍처 명세
- `planning`: Execution, 진행 상태, 구현 계획, 체크리스트, 검증 절차

전체 문서 분류 규칙은 [docs/00_docs_README.md](docs/00_docs_README.md)를 먼저 따른다.

코드 작업은 `current_system` 기준 문서 3종을 먼저 읽고 이어간다.

- [CURRENT_SYSTEM_OVERVIEW.md](docs/current_system/CURRENT_SYSTEM_OVERVIEW.md)
- [CURRENT_CODE_MAP.md](docs/current_system/CURRENT_CODE_MAP.md)
- [CURRENT_TO_V4_GAP.md](docs/current_system/CURRENT_TO_V4_GAP.md)

## 새 세션 시작 지시문

아래 문장 그대로 시작해도 된다.

```text
작업 시작 전에 START_HERE.md, docs/00_docs_README.md, docs/current_system/CURRENT_SYSTEM_OVERVIEW.md, docs/current_system/CURRENT_CODE_MAP.md, docs/current_system/CURRENT_TO_V4_GAP.md 를 먼저 읽고,
그 다음 docs/planning/ACTIVE_EXECUTION_PLAN.md 를 확인해 현재 활성 트랙과 다음 작업부터 이어서 진행해라.
공모전 제출 준비 작업이면 docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md 를 상세 체크리스트로 확인해라.
장기 Goal/레벨링 작업이면 docs/planning/goal/OVERALL_GOAL_PROGRESS.md 와 docs/planning/leveling/* 를 추가로 확인해라.
문서는 목적형 폴더와 GCSE 역할 기준을 유지하고, 코드/테스트 중심으로 작업해라.
```

gstack 흐름으로 이어갈 때는 목적에 따라 아래처럼 시작한다.

```text
/plan-eng-review
START_HERE.md와 docs/planning/ACTIVE_EXECUTION_PLAN.md를 먼저 읽고, 현재 활성 트랙 기준 다음 구현 후보를 진행하기 위한 최소 구현 계획을 검토해라.
단, 새 구조 설계가 아니라 기존 runtime을 CLI에서 얇게 호출 가능한지 확인하는 import spike/skeleton 중심으로 봐라.
저장 가능한 runtime state와 transient presentation state는 분리하고, presentation queue는 save/continue 기준에 포함하지 않는다.
```

UI 연출 구조를 먼저 정리하려면 아래처럼 시작한다.

```text
/plan-eng-review
START_HERE.md와 docs/planning/ACTIVE_EXECUTION_PLAN.md를 먼저 읽고, 활성 트랙에서 허용되는 범위 안에서 Battle/Market/Settlement 연출을 GamePresentationEvent / presentationQueue 같은 transient event list로 묶을지 검토해라.
save/continue source of truth는 runtime state로 유지하고, queue는 저장하지 않는 조건으로 최소 리팩터링 범위만 제안해라.
```

## 먼저 읽을 문서

읽는 순서는 아래로 고정한다.

1. [START_HERE.md](START_HERE.md)
2. [docs/00_docs_README.md](docs/00_docs_README.md)
3. [CURRENT_SYSTEM_OVERVIEW.md](docs/current_system/CURRENT_SYSTEM_OVERVIEW.md)
4. [CURRENT_CODE_MAP.md](docs/current_system/CURRENT_CODE_MAP.md)
5. [CURRENT_TO_V4_GAP.md](docs/current_system/CURRENT_TO_V4_GAP.md)
6. [CURRENT_LEVELING_POLICY.md](docs/current_system/CURRENT_LEVELING_POLICY.md)
7. [CURRENT_LEVELING_SIMULATION_BASELINE.md](docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md)
8. [CURRENT_LEVELING_RUNTIME_SPEC.md](docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md)
9. [ACTIVE_EXECUTION_PLAN.md](docs/planning/ACTIVE_EXECUTION_PLAN.md)
10. [OVERALL_GOAL_PROGRESS.md](docs/planning/goal/OVERALL_GOAL_PROGRESS.md)
11. [LEVELING_APPLIED_STATUS.md](docs/planning/leveling/LEVELING_APPLIED_STATUS.md)
12. [ECONOMY_LEVELING_PLAN.md](docs/planning/leveling/ECONOMY_LEVELING_PLAN.md)
13. [DOCUMENTATION_CONSOLIDATION_PLAN.md](docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md)
14. [COMPETITION_SUBMISSION_CHECKLIST.md](docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md)

필요할 때만 추가로 본다. archive 문서는 현재 기준이 아니라 과거 참고다.

- [STATUS.md](docs/planning/legacy/STATUS.md)
- [IMPLEMENTATION_PLAN.md](docs/planning/legacy/IMPLEMENTATION_PLAN.md)
- [MIGRATION_ROADMAP.md](docs/planning/legacy/MIGRATION_ROADMAP.md)
- [CURRENT_LEVELING_ML_BASELINE.md](docs/current_system/CURRENT_LEVELING_ML_BASELINE.md)
- [ITEM_EFFECT_RUNTIME_MATRIX.md](docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md)
- [13_ITEM_SYSTEM_CONTRACT.md](docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md)
- [TEST_QA_ACCEPTANCE.md](docs/planning/verification/TEST_QA_ACCEPTANCE.md)
- [OPEN_DECISIONS.md](docs/planning/feature_plans/OPEN_DECISIONS.md)
- [feature plan archive](docs/archive/feature_plans_2026_04/00_feature_plans_2026_04_README.md)
- [leveling archive](docs/archive/leveling/00_leveling_archive_README.md)

## 현재 문서 매핑

문서는 아래 위치를 기준으로 읽는다.

| 폴더 | GCSE 역할 | 현재 경로 | 역할 |
| --- | --- | --- | --- |
| goals | Goal | `docs/goals/*` | 제품 목표, 방향성, 의사결정 원칙 |
| current_system | Context | `docs/current_system/*` | 현재 구현 상태, 코드 맵, current-to-target gap, 레벨링 현재 정책 |
| specs | Spec | `docs/specs/V4/*.md` | 기능별 V4 명세 |
| planning | Execution | `docs/planning/ACTIVE_EXECUTION_PLAN.md`, `docs/planning/competition/*`, `docs/planning/goal/*`, `docs/planning/leveling/*`, `docs/planning/feature_plans/*`, `docs/planning/legacy/*`, `docs/planning/verification/*` | 현재 실행 라우터, 공모전 실행표, Goal 진도, 레벨링/경제 상태, 기능별 계획, legacy snapshot, 검증 절차 |
| archive | Archive | `docs/archive/*`, generated/prompt/history 문서 | 최신 판단 기준은 아니지만 이력 검색에 사용할 수 있는 참고 자료 |

## Source of Truth

- 현재 활성 트랙과 다음 작업: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
- 실제 Goal 전체 진도: `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`
- 공모전 제출 준비 체크리스트: `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`
- 레벨링 적용 상태: `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`
- 경제 계획: `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md`
- 문서 정리 순서: `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md`
- Item effect 실행 상태: `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md`
- 레벨링 현재 정책: `docs/current_system/CURRENT_LEVELING_POLICY.md`
- 레벨링 시뮬레이션/휴리스틱 기준값: `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md`
- 레벨링 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
- 현재 코드 설명과 작업 재개 기준: `docs/current_system/*`
- 기능 명세: `docs/specs/V4/*`
- 과거 V4 진행 snapshot: `docs/planning/legacy/STATUS.md`, `docs/planning/legacy/IMPLEMENTATION_PLAN.md`, `docs/planning/legacy/MIGRATION_ROADMAP.md`
- 과거 ML 경로 호환 안내: `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md`
- 과거 참고: `docs/archive/*`

`docs/archive/generated/RUMMI_POKER_GRID_V4_COMBINED.md`는 병합 스냅샷으로 보고, 개별 원본 문서보다 우선하지 않는다.

코드 구조가 바뀌면 `CURRENT_CODE_MAP.md`, 구현 상태가 바뀌면 `CURRENT_SYSTEM_OVERVIEW.md`, current-to-target 차이가 바뀌면 `CURRENT_TO_V4_GAP.md`를 갱신한다.

## 현재 작업 원칙

- 현재 프로토타입은 V4 이행의 기준선이다.
- 현재 코어 루프는 보호하고, 변경은 V4 구조로 가는 다리여야 한다.
- 문서는 과하게 늘리지 않는다.
- 새 문서는 꼭 필요할 때만 만들고, 가능하면 기존 목적형 폴더에 통합한다.
- 작업은 문서보다 코드와 테스트 중심으로 진행한다.
- debug 편의 기능은 일반 런과 의미가 섞이면 분리한다.
- UI 표시, 화면 전환, 저장/복귀 동선, settlement/market/next station loop를 바꾼 작업은 자동 테스트 통과만으로 끝내지 말고, iOS 시뮬레이터 스모크 또는 개발자 눈검증 필요 여부를 작업 결과에 명시한다. 필요하면 `tools/ios_sim_smoke.sh`를 우선 사용한다.

## 하지 말아야 할 것

- One Pair 점수 변경
- save schema 즉시 교체
- Jester id 변경
- 대규모 symbol rename
- DB 엔진 도입
- 현재 프로토타입 편의 기능을 이유 없이 대규모 정리
- 진행 상태를 여러 문서에 중복 기록

## 주 타깃 플랫폼

- 1차 기본: `iOS`
- 2차 보조: `Chrome`

실행 테스트 기준도 mobile-first로 본다.

## 재사용 검증 프로세스

iOS 시뮬레이터 실구동/스크린샷 검증은 필요할 때마다 ad-hoc으로 하지 않고 아래 스크립트를 우선 사용한다.

- `tools/ios_sim_smoke.sh`

기본 예시:

```bash
tools/ios_sim_smoke.sh
tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot"
tools/ios_sim_smoke.sh --open-url "https://example.com" --relaunch
```

web 저장/라우팅/입력 경계가 바뀌면 아래 스크립트를 먼저 확인한다.

- `tools/web_build_smoke.sh`

의미 있는 앱 실구동 검증을 했으면 최신 판단에 필요한 요약만 [ACTIVE_EXECUTION_PLAN.md](docs/planning/ACTIVE_EXECUTION_PLAN.md), [OVERALL_GOAL_PROGRESS.md](docs/planning/goal/OVERALL_GOAL_PROGRESS.md) 또는 해당 source-of-truth 문서에 남긴다. 긴 route/시나리오와 산출물 경로 이력은 `docs/planning/verification/daily_logs/YYYY-MM-DD.md` 날짜별 파일에 남긴다.
