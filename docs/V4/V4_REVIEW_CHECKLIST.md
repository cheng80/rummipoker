# V4 Review Checklist

문서 목적: 사용자가 `docs/V4` 문서를 보면서 현재 마이그레이션 진행 상태를 직접 확인할 수 있도록, 추천 검토 순서와 실행 체크리스트를 한 곳에 정리한다.

## 1. Recommended Reading Order

- [ ] `docs/V4/CODEX_V4_PLAN_INSTRUCTION.md`
  현재 플랜 문서가 어떤 제약과 원칙으로 작성되었는지 먼저 확인한다.
- [ ] `docs/V4/V4_IMPLEMENTATION_PLAN.md`
  전체 마이그레이션 단계, PR 분리 기준, 금지 작업을 확인한다.
- [ ] `docs/V4/V4_PLAN_RISK_REGISTER.md`
  무엇이 가장 쉽게 깨질 수 있는지와 보호 장치를 확인한다.
- [ ] `docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md`
  현재 코드와 V4 문서가 어떻게 연결되는지 확인한다.
- [ ] `docs/V4/RUMMI_POKER_GRID_V4_COMBINED.md`
  V4 통합 문서의 6, 7번이 현재 저장소 구조와 맞는지 검토한다.
- [ ] `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
  현재 구현 baseline을 다시 확인한다.
- [ ] `docs/current_system/CURRENT_CODE_MAP.md`
  실제 수정 anchor 파일을 확인한다.
- [ ] `docs/current_system/CURRENT_TO_V4_GAP.md`
  지금 구조와 V4 목표 사이의 차이를 확인한다.

## 2. Recommended Execution Order

### A. Plan Lock

- [x] `docs/V4/V4_IMPLEMENTATION_PLAN.md` 작성/갱신
- [x] `docs/V4/V4_PLAN_RISK_REGISTER.md` 작성
- [x] `docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md` 작성
- [ ] 사용자가 plan/risk/traceability 3문서를 읽고 방향 승인

완료 기준:
첫 3개 PR과 금지 작업, 보호 규칙이 명확해야 한다.

### B. Regression Protection

- [x] combat regression test 추가
- [x] save/restart regression test 추가
- [x] One Pair 0점 보호
- [x] contributor union removal 보호
- [x] `stageStartSnapshot` restart semantics 보호
- [x] 관련 테스트 묶음 통과 확인
- [ ] 사용자가 회귀 보호 범위를 검토하고 승인

완료 기준:
현재 코어 동작을 문서가 아니라 테스트가 보호해야 한다.

### C. Compatibility Wrapper

- [x] `RummiStationRuntimeFacade` 추가
- [x] facade smoke test 추가
- [ ] facade를 실제 UI/read-model 쪽에 연결할 필요가 있는지 결정
- [ ] 연결이 필요하면 read-only 사용처부터 제한적으로 도입

완료 기준:
`Blind/Stage` 런타임을 건드리지 않고 `Station` 문서 용어를 읽을 수 있어야 한다.

### D. Ruleset Skeleton

- [x] `RummiRuleset.currentDefaults` 추가
- [x] current default mirror 테스트 추가
- [ ] ruleset을 실제 session/provider에 연결할지 여부 결정
- [ ] 연결 시 기본값이 100% 동일한지 parity test 확대

완료 기준:
ruleset 계층이 생겨도 현재 기본 동작은 절대 바뀌면 안 된다.

### E. UI Terminology Bridge

- [x] `Station/Market/Archive`를 UI copy 수준에서만 도입할지 결정
- [x] code symbol rename 없이 가능한 alias 문구 범위 정의
- [x] title/game/shop 화면별 적용 범위 분리
- [ ] UI smoke 검증

완료 기준:
용어는 바뀌어도 save/code/runtime 의미는 그대로여야 한다.

현재 적용 범위:
- `game/shop/cash-out/HUD` 카피만 우선 적용
- `title` 화면 continue/save 관련 문구는 현재 표현 유지
- 내부 code symbol, save field, provider/state 명칭은 유지

### F. Market Adapter Preparation

- [x] `jester_meta.dart`를 직접 분해하지 않고 read model/adapter 범위 정의
- [x] buy/sell/reroll/current offer semantics 보호 테스트 점검
- [x] current Jester id 유지 정책 재확인
- [x] market 확장 문서와 실제 current shop 간 차이 정리

완료 기준:
현 shop을 깨지 않고 future market 구조를 읽을 수 있어야 한다.

현재 차이 요약:
- current shop은 `Jester` 전용이고, V4 target market은 다중 콘텐츠 카테고리를 전제한다.
- current offer는 `RummiShopOffer(card)` 구조이고, target은 `MarketOffer(category/contentId/availabilityReason)` 구조를 지향한다.
- current runtime은 `ownedJesters/shopOffers`를 source of truth로 유지하고, 이번 단계에서는 facade로만 `Market` 용어를 읽는다.
- buy/sell/reroll 로직은 모두 현재 `RummiRunProgress`에 남겨 둔다.

### G. Save Adapter Preparation

- [x] active run save v2를 source of truth로 유지
- [x] adapter/read model shadow mode 범위 정의
- [x] save payload field rename 금지 재검토
- [x] continue/corrupt save/restart parity 테스트 유지

완료 기준:
저장 구조 확장은 가능하되 기존 continue/save는 그대로 살아 있어야 한다.

현재 적용 범위:
- save key, payload field, schema version은 그대로 유지
- `stageIndex/stageStartSnapshot/activeScene`를 future 용어로 읽는 facade만 추가
- 실제 save/load/restore/HMAC 검증 로직은 `ActiveRunSaveService`에 그대로 유지

### H. App Run Validation

- [ ] unit/provider/save 테스트 단계 종료
- [ ] 실제 Flutter 앱 실행
- [ ] title → new run / continue 확인
- [ ] battle → cash-out → full-screen shop → next stage 확인
- [ ] restart current stage 확인
- [ ] save/restore 확인

완료 기준:
이 단계부터가 실제 앱 실행 테스트 단계다.

## 3. Current Progress Snapshot

- [x] Phase 0 Plan lock
- [x] Phase 1 Regression protection
- [x] Phase 2 Compatibility wrapper skeleton
- [x] Phase 3 Ruleset skeleton
- [x] Phase 4 UI terminology bridge
- [x] Phase 5 Market adapter preparation
- [x] Phase 6 Save adapter preparation
- [ ] 실제 앱 실행 테스트

## 4. Recommended Next Decision

현재 가장 자연스러운 다음 선택지는 아래 둘 중 하나다.

- [ ] `UI terminology bridge`부터 진행
  이유: 런타임/저장 구조를 건드리지 않고 V4 용어를 제한적으로 흡수할 수 있다.
- [ ] `Market adapter preparation`부터 진행
  이유: `jester_meta.dart`를 바로 분해하지 않으면서 장기 구조를 위한 읽기 모델을 준비할 수 있다.

현재 추천:
`UI terminology bridge`를 먼저 하고, 그 다음 `Market adapter preparation`으로 넘어간다.
