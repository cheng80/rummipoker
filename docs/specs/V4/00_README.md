# V4 Functional Specs Index

> 문서 성격: 기능별 V4 명세 색인
> GCSE 역할: `Spec`
> 범위: 전투, 런/경제, 콘텐츠, 저장, UI, 아키텍처, 용어, 아이템, 밸런스 자동화 계약

`docs/specs/V4/`는 V4의 기능 계약을 기능 영역별로 나눈 폴더다.

이 폴더는 진행 상태, PR 순서, 현재 코드 baseline 원본을 보관하지 않는다.

## 1. 사용 기준

기능을 구현하거나 수정할 때는 아래 순서로 확인한다.

1. 실제 코드와 테스트
2. `docs/current_system/`의 현재 코드 기준 문서
3. 이 폴더의 기능별 명세
4. `docs/planning/`의 실행 계획과 상태

`[CURRENT]`는 현재 코드 사실을 설명할 때만 쓴다. 현재 코드 사실의 원본은 `docs/current_system/`이며, 이 폴더에서는 기능 계약 이해에 필요한 범위로만 참조한다.

## 2. 문서 구성

| 파일 | 역할 |
|---|---|
| `02_CORE_COMBAT_RULES.md` | 전투 규칙, 평가, 확정, 제거, 만료 |
| `03_RUN_META_ECONOMY.md` | stage 기반 현재 루프와 Station 목표 구조 |
| `04_JESTER_MARKET_CONTENT.md` | Jester, Market, 콘텐츠 계층 계약 |
| `05_SAVE_CHECKPOINT_DATA.md` | active run save와 장기 데이터 구조 |
| `06_UI_UX_FLOW.md` | 현재 화면 흐름과 목표 UX |
| `07_TECHNICAL_ARCHITECTURE.md` | 현재 코드 경계와 목표 아키텍처 |
| `10_TERMINOLOGY_ALIAS.md` | 용어 정책과 코드 리네임 원칙 |
| `13_ITEM_SYSTEM_CONTRACT.md` | Item UI 계약, 도메인 모델, 화면 정보 구조 |
| `14_BALANCE_AUTOMATION_ML.md` | 자동 시뮬레이션 로그와 밸런스 예측 파이프라인 후보 |

## 3. 다른 폴더로 분리한 문서

| 기존 성격 | 현재 위치 |
|---|---|
| 현재 코드 baseline | `docs/current_system/CURRENT_BUILD_BASELINE.md` |
| migration roadmap | `docs/planning/MIGRATION_ROADMAP.md` |
| Test/QA acceptance | `docs/planning/verification/TEST_QA_ACCEPTANCE.md` |
| open decisions / experiments | `docs/planning/OPEN_DECISIONS.md` |
| V3 -> V4 changelog | `docs/archive/legacy/V4_CHANGELOG_FROM_V3.md` |
| V4 master summary | `docs/archive/generated/V4_MASTER_SPEC.md` |

## 4. 라벨 규칙

| 라벨 | 의미 |
|---|---|
| `[CURRENT]` | 현재 코드와 일치하는 사실. 원본은 `docs/current_system/`이다. |
| `[V4_DECISION]` | V4 기능 계약에서 채택한 정책 |
| `[TARGET]` | 중기 또는 출시판 목표. 현재 구현으로 오해하지 않는다. |
| `[FUTURE]` | 이후 확장 후보 |
| `[EXPERIMENT]` | feature flag나 별도 ruleset에서만 검증할 후보 |
| `[WATCH]` | 코드와 문서, 의도 사이에 재확인이 필요한 영역 |
