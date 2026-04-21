# Rummi Poker Grid Design Docs V4

> 문서 성격: V4 기준 문서 세트 / Current Baseline + Target Product Design + Migration Plan
> 코드 반영 상태: mixed
> Truth source priority:
> 1. 실제 `lib/` 코드
> 2. `CURRENT_SYSTEM_OVERVIEW.md`
> 3. `CURRENT_CODE_MAP.md`
> 4. `CURRENT_TO_V4_GAP.md`
> 5. `docs/archive/`
> 6. V4의 `[TARGET]`, `[FUTURE]`, `[EXPERIMENT]` 섹션
>
> 핵심 정책: `[CURRENT]`로 표시된 항목만 현재 빌드 기준이다. `[TARGET]`은 장기 제품 목표이고, `[FUTURE]`는 이후 확장 후보이며, `[EXPERIMENT]`는 기본값이 아닌 실험안이다.

## 1. V4의 목적

V4는 V3처럼 현재 구현과 미래 목표가 같은 강도로 섞이는 문제를 막기 위한 기준 문서 세트다.

V4의 한 문장 정의는 다음이다.

> 현재 작동하는 `즉시 확정 + 부분 줄 평가 + overlap + contributor 제거` 보드 전투 프로토타입을, 장기 제품 구조로 안전하게 흡수 확장하기 위한 기준 문서.

V4는 새 게임을 다시 설계하는 문서가 아니다. 현재 코드가 이미 확보한 코어 루프를 보호하면서, 장기 구조인 Station, Market, Archive, Profile, Trial, Risk Grade 등을 단계적으로 얹기 위한 문서다.

## 2. V4에서 즉시 고정하는 결정

| 항목 | V4 결정 |
|---|---|
| 전투 코어 | 현재 구현을 V4의 핵심 규칙으로 채택한다. |
| 보드 | 5x5 유지. |
| 평가 라인 | 12줄 유지. |
| 부분 줄 평가 | 유지. 5칸 강제 완성으로 되돌리지 않는다. |
| 즉시 확정 | 유지. |
| Overlap | 유지. 기본 상수 `alpha = 0.3`, `cap = 2.0`. |
| 제거 규칙 | 줄 전체가 아니라 contributor만 제거한다. |
| One Pair | V4 기본 규칙에서도 0점 dead line으로 유지한다. |
| Stage / Blind 코드명 | 당장 코드 리네임하지 않는다. |
| Station | 장기 UI/메타 용어로 도입한다. 코드 심볼 리네임은 별도 단계. |
| 저장 | 현재 active run save v2 + stageStartSnapshot을 보호한다. |
| DB | 장기 목표로 정의하되 즉시 교체하지 않는다. |
| Jester | 현재 curated common Jester 중심 구조를 유지하고 Market/Content 계층으로 확장한다. |

## 3. V4에서 금지하는 즉시 변경

아래 항목은 V4 문서가 있어도 바로 코드 기본값으로 바꾸지 않는다.

- One Pair 10점화
- `Start Gold 6` 같은 장기 목표 경제 수치의 즉시 적용
- 30 Station 테이블 전체 확정
- Entry / Pressure / Lock의 즉시 런타임 강제 적용
- Drift / SQLite / IndexedDB로 active run save 즉시 교체
- `BlindState -> StationState`, `scoreTowardBlind -> scoreTowardStation` 같은 코드 심볼 일괄 리네임
- Jester ID 변경 또는 기존 저장 데이터와 맞지 않는 콘텐츠 ID 변경

## 4. 문서 라벨 규칙

| 라벨 | 의미 | 구현 근거 |
|---|---|---|
| `[CURRENT]` | 현재 코드가 실제로 구현한 기준 | 코드 / current docs |
| `[V4_DECISION]` | V4에서 기준으로 채택한 정책 | 현재 구현 + 설계 판단 |
| `[TARGET]` | 출시판 또는 중기 목표 | 구현 전 또는 부분 구현 |
| `[FUTURE]` | 이후 확장 후보 | 지금 구현 기준 아님 |
| `[MIGRATION]` | current에서 target으로 이동하는 절차 | PR 분해 기준 |
| `[EXPERIMENT]` | 기본값이 아닌 실험 ruleset | feature flag 필요 |
| `[WATCH]` | 코드와 문서, 의도 사이에 주의가 필요한 영역 | 검증 필요 |

## 5. 문서 구성

| 파일 | 역할 |
|---|---|
| `00_README.md` | V4 문서 읽는 법, 우선순위, 금지 규칙 |
| `01_CURRENT_BASELINE.md` | 현재 코드 기준 baseline |
| `02_CORE_COMBAT_RULES.md` | 전투 규칙, 평가, 확정, 제거, 만료 |
| `03_RUN_META_ECONOMY.md` | stage 기반 현재 루프와 Station 목표 구조 |
| `04_JESTER_MARKET_CONTENT.md` | 현재 Jester 구현과 장기 콘텐츠 체계 |
| `05_SAVE_CHECKPOINT_DATA.md` | active run save v2와 장기 데이터 구조 |
| `06_UI_UX_FLOW.md` | 현재 화면 흐름과 목표 UX |
| `07_TECHNICAL_ARCHITECTURE.md` | 현재 코드 경계와 목표 아키텍처 |
| `08_MIGRATION_ROADMAP.md` | PR 단위 이행 계획 |
| `09_TEST_QA_ACCEPTANCE.md` | 회귀 방지 테스트와 승인 조건 |
| `10_TERMINOLOGY_ALIAS.md` | 용어 정책과 코드 리네임 원칙 |
| `11_OPEN_DECISIONS.md` | 남은 결정사항과 실험 후보 |
| `12_CHANGELOG_FROM_V3.md` | V3 대비 V4 수정 원칙 |
| `13_ITEM_SYSTEM_CONTRACT.md` | Jester / Item 분리 후 Item UI 계약, 도메인 모델, 화면 정보 구조, v1 아이템 카탈로그 기준 |
| `14_BALANCE_AUTOMATION_ML.md` | 자동 시뮬레이션 로그와 PyTorch 밸런스 예측 파이프라인 후보 |
| `V4_MASTER_SPEC.md` | 위 내용을 하나로 묶은 실행 기준 요약 |

## 6. 소스 입력

V4 작성 시 사용한 입력은 다음이다.

- `lib.zip`: Flutter `lib/` 코드 전체
- `CURRENT_CODE_MAP.md`
- `CURRENT_SYSTEM_OVERVIEW.md`
- `CURRENT_TO_V4_GAP.md`
- `archive.zip`: 기존 설계 문서 묶음

## 7. 입력 파일 해시

| 파일 | SHA-256 |
|---|---|
| `lib.zip` | `c9548f83dddc9da1b08ab6751c0a278113c67dd8174bda212dec51c7ece54c4e` |
| `archive.zip` | `33f6eefed3a5161c3c224c10ab4225494bbb209f4adec6f875fd50dfac6750a9` |
| `CURRENT_CODE_MAP.md` | `40fb5b2269d21fc28c8c00a70d42c668242fe17e6c3991473307ee57a0a5fe7a` |
| `CURRENT_SYSTEM_OVERVIEW.md` | `a087e8c397374a930f55214baf0de2ff968e850beb0c0e5a8e7130bd4eec32e6` |
| `CURRENT_TO_V4_GAP.md` | `313376c89896eba0ba753ab5fc11b3e4c88e8181b5a0cbecab5859e050df666e` |
