# V4 Review Checklist

문서 목적: `V4` 진행 상태를 두 층으로 관리한다.

- `A. Migration Checklist`
  현재 프로토타입을 깨지 않고 V4 구조로 옮겨 가는 체크리스트
- `B. Target Product Checklist`
  V4 최종 장기 목표가 어떤 큰 기능 축으로 완성되어야 하는지 보는 체크리스트

이 문서는 세부 설계 문서가 아니다.  
새 세션에서 “어디까지 왔고, 다음에 무엇을 해야 하는가”를 빠르게 판단하는 용도다.

## 1. Recommended Reading Order

- [ ] `docs/V4/CODEX_V4_PLAN_INSTRUCTION.md`
- [ ] `docs/V4/V4_IMPLEMENTATION_PLAN.md`
- [ ] `docs/V4/V4_PLAN_RISK_REGISTER.md`
- [ ] `docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md`
- [ ] `docs/V4/RUMMI_POKER_GRID_V4_COMBINED.md`
- [ ] `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
- [ ] `docs/current_system/CURRENT_CODE_MAP.md`
- [ ] `docs/current_system/CURRENT_TO_V4_GAP.md`

## 2. A. Migration Checklist

### A1. Plan Lock

- [x] `docs/V4/V4_IMPLEMENTATION_PLAN.md` 작성/갱신
- [x] `docs/V4/V4_PLAN_RISK_REGISTER.md` 작성
- [x] `docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md` 작성
- [x] 사용자가 plan/risk/traceability 3문서를 읽고 방향 승인

완료 기준:
금지 작업, 보호 규칙, 첫 구현 단계가 명확해야 한다.

### A2. Regression Protection

- [x] combat regression test 추가
- [x] save/restart regression test 추가
- [x] One Pair 0점 보호
- [x] contributor union removal 보호
- [x] `stageStartSnapshot` restart semantics 보호
- [x] 관련 테스트 묶음 통과 확인
- [x] 사용자가 회귀 보호 범위를 검토하고 승인

완료 기준:
현재 코어 동작은 문서가 아니라 테스트로 보호되어야 한다.

### A3. Compatibility Wrappers

- [x] `RummiStationRuntimeFacade` 추가
- [x] station facade smoke test 추가
- [x] `RummiMarketRuntimeFacade` 추가
- [x] market facade smoke test 추가
- [x] `RummiActiveRunSaveFacade` 추가
- [x] save facade smoke test 추가
- [x] station facade를 실제 HUD/read path에 연결

완료 기준:
`stage/blind/shop/save` current runtime을 유지한 채 `Station/Market/Checkpoint` 용어로 읽을 수 있어야 한다.

### A4. Ruleset Skeleton

- [x] `RummiRuleset.currentDefaults` 추가
- [x] current default mirror 테스트 추가
- [x] ruleset을 실제 session/provider에 연결할지 여부 결정
- [x] 연결 시 기본값 parity test 확대

완료 기준:
ruleset 계층이 생겨도 current defaults는 그대로 유지되어야 한다.

현재 결정:

- 현재 단계에서는 ruleset을 provider/session 생성 경로에 더해 `HandEvaluator`, `RummiPokerGridEngine`, `RummiPokerGridSession` 내부 판정까지 연결했다.
- 구체적으로 `wheel straight 허용`, `high card / one pair dead-line 여부`, `overlap alpha / cap`, `default/debug hand-size clamp`가 세션의 `ruleset` 값을 직접 읽는다.
- 아직 `RummiRuleset.currentDefaults`만 쓰므로 실사용 동작은 유지되고, custom ruleset 테스트로 내부 판정이 실제로 따라오는지 고정했다.

### A5. UI Terminology Bridge

- [x] `Station/Market/Archive`를 UI copy 수준에서만 도입할지 결정
- [x] code symbol rename 없이 가능한 alias 범위 정의
- [x] title/game/shop 화면별 적용 범위 분리
- [x] `game/shop/cash-out/HUD` 카피 1차 반영
- [x] UI smoke 검증 완료

완료 기준:
용어는 바뀌어도 save/code/runtime 의미는 그대로여야 한다.

### A6. Market Adapter Preparation

- [x] `jester_meta.dart`를 직접 분해하지 않고 read model/adapter 범위 정의
- [x] buy/sell/reroll/current offer semantics 보호 테스트 점검
- [x] current Jester id 유지 정책 재확인
- [x] current shop과 target market 차이 정리
- [x] shop UI read path에 market facade 실제 연결
- [x] `GameView -> GameShopScreen` 경계에 market read model 전달
- [x] shop UI의 direct runtime reads 추가 축소

완료 기준:
현 shop을 깨지 않고 target market 구조를 실제 코드에서 읽기 시작해야 한다.

현재 상태:

- shop UI read path의 가격/보유 슬롯/오퍼/affordability/runtime snapshot 표시는 market facade 기준으로 읽는다.
- shop UI의 `reroll`은 `GameSessionNotifier.rerollShopFromState()`를 통해 notifier 내부 state만 읽도록 정리했다.
- `cash-out -> market -> next station` 시퀀스는 `GameSessionNotifier.prepareSettlementAndCashOut()`, `enterMarketAfterCashOut()`, `advanceToNextStation()` command로 옮겨서 UI가 내부 순서를 직접 조립하지 않게 정리했다.
- `GameView -> GameShopScreen` 경계도 mutable `runProgress` 직접 전달 대신 market/save facade read path를 다시 읽는 방식으로 줄였다.
- battle 화면도 `RummiBattleRuntimeFacade`를 통해 `stage/gold/board/hand/scoring cells` read path를 묶어서 HUD/board/hand UI가 raw runtime 전체를 직접 받지 않게 정리했다.
- battle action도 `tapBoardCell()`, `discardSelectedBoardTileFromState()`, `discardSelectedHandTileFromState()`, `sellSelectedJesterOverlayFromState()` command로 옮겨서 `GameView`가 선택 상태를 직접 해석하는 범위를 더 줄였다.
- active run 저장도 notifier가 만드는 runtime snapshot과 `ActiveRunSaveService.saveRuntimeState()` 기준으로 정리해서 view가 save payload를 직접 조립하는 범위를 줄였다.
- notifier/orchestration state는 `stationView / marketView / battleView / activeRunSaveView`를 함께 보관하며, runtime UI와 options dialog가 그 파생 facade를 직접 소비한다.

### A7. Save Adapter Preparation

- [x] active run save v2를 source of truth로 유지
- [x] adapter/read model shadow mode 범위 정의
- [x] save payload field rename 금지 재검토
- [x] continue/corrupt save/restart parity 테스트 유지
- [x] save facade 소비처 확대 필요 여부 결정

완료 기준:
저장 구조 확장은 가능하되 기존 continue/save는 그대로 살아 있어야 한다.

### A8. Debug / Active Run Separation

- [x] debug fixture와 active run 의미 분리
- [x] fixture 모드 restart 문구 분리
- [x] fixture 모드 active run 저장 차단
- [x] debug 경로의 장기 정리 시점 결정

완료 기준:
debug fixture 흐름이 일반 런 의미를 오염시키지 않아야 한다.

현재 결정:

- debug fixture/auto smoke 경로는 A9 app run validation과 migration read-path 검증이 끝날 때까지 유지한다.
- Station target prototype 또는 별도 QA harness가 생기면 현재 debug route/query hook을 그 단계에서 정리한다.

### A9. App Run Validation

- [x] iOS에서 앱 실행 확인
- [x] title 화면 렌더 확인
- [x] fixture 기반 battle 화면 진입 확인
- [x] background save / continue 감지 확인
- [x] 일반 런 restart 동작 확인
- [x] iOS 시뮬레이터 실구동/스크린샷 검증 절차를 재사용 가능한 프로세스로 정리
- [x] `cash-out -> market -> next station` 전체 루프 실기기 확인
- [x] Chrome 2차 확인 필요 여부 결정

완료 기준:
mobile-first 기준으로 실제 앱이 current baseline과 migration 변경을 함께 견뎌야 한다.

현재 기준 프로세스:

- 기본 스크립트: `tools/ios_sim_smoke.sh`
- 웹 빌드 smoke 스크립트: `tools/web_build_smoke.sh`
- launch/title 확인: `tools/ios_sim_smoke.sh`
- fixture battle 확인: `tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot"`
- background save / relaunch 확인:
  `tools/ios_sim_smoke.sh --open-url "https://example.com" --relaunch`
- full loop 확인:
  `tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1"`
- web build 확인: `tools/web_build_smoke.sh --web-only`
- web wasm build 확인: `tools/web_build_smoke.sh --wasm-only`
- 의미 있는 실구동 검증은 스크린샷/로그 산출물 경로까지 남긴다.

최근 검증 산출물:

- title launch 확인:
  `/tmp/rummipoker_ios_smoke/title_smoke_20260420_0230/`
- fixture battle 확인:
  `/tmp/rummipoker_ios_smoke/fixture_stage2_smoke_20260420_0230/`
- background save / relaunch 확인:
  `/tmp/rummipoker_ios_smoke/background_relaunch_smoke_20260420_0230/`
- `cash-out -> market -> next station` 확인:
  `/tmp/rummipoker_ios_smoke/cashout_market_next_station_smoke_20260420_0252/`

현재 결정:

- Chrome 기기는 현재 연결 가능 상태를 확인했다.
- 이번 단계에서는 mobile-first/iOS smoke가 핵심 acceptance를 충족하므로 Chrome 실구동은 필수 게이트로 두지 않는다.
- 다만 web 저장/라우팅/입력 경계가 바뀌는 PR이나 release 전 점검 단계에서는 `tools/web_build_smoke.sh`를 먼저 돌리고, 필요 시 Chrome 2차 smoke를 다시 수행한다.

## 3. B. Target Product Checklist

아래는 `V4 최종 장기 목표` 기준 체크리스트다.  
현재 구현 여부와 별개로, 장기적으로 이 축들이 모두 정의되고 연결되어야 한다.

상태 해석:

- `not started`
- `defined`
- `partial`
- `implemented`
- `validated`

### B1. Home Layer

- [ ] `Home` 구조 정의 완료
  현재 상태: `partial`
- [ ] `Continue / New Run / Trial / Archive` 4갈래 진입 정리
  현재 상태: `partial`
- [ ] 손상 세이브 / continue / delete 동선이 최종 Home 구조와 맞게 정리
  현재 상태: `partial`

### B2. Run Setup Layer

- [ ] `Run Kit` 선택 구조 정의
  현재 상태: `not started`
- [ ] `Risk Grade` 선택 구조 정의
  현재 상태: `not started`
- [ ] `Seed / Mode` 선택 구조 정리
  현재 상태: `partial`
- [ ] `Run Setup -> Station Map` 전환 구조 정의
  현재 상태: `not started`

### B3. Station Map Layer

- [ ] `Station Map` 화면/도메인 구조 정의
  현재 상태: `not started`
- [ ] `Sector -> Station` 계층 정의
  현재 상태: `defined`
- [ ] `Entry / Pressure / Lock / Reward / Market` 연결 규칙 정의
  현재 상태: `defined`

### B4. Station Battle Layer

- [ ] `5x5 전투` current baseline 보호
  현재 상태: `implemented`
- [ ] `Station Objective` read model 연결
  현재 상태: `partial`
- [ ] `Pressure / Lock` 실제 시스템 정의
  현재 상태: `not started`
- [ ] `Jester / Market 효과 반영` target 구조 기준으로 정리
  현재 상태: `partial`

### B5. Station Settlement Layer

- [ ] 점수 정산 구조를 `Settlement` 용어로 명시
  현재 상태: `partial`
- [ ] 보상 계산 구조 확정
  현재 상태: `partial`
- [ ] `Checkpoint` 갱신 개념을 current save와 연결
  현재 상태: `partial`

### B6. Market Layer

- [ ] `Jester` market 카테고리
  현재 상태: `implemented`
- [ ] `Permit` 카테고리 정의
  현재 상태: `not started`
- [ ] `Glyph` 카테고리 정의
  현재 상태: `not started`
- [ ] `Sigil` 카테고리 정의
  현재 상태: `not started`
- [ ] `Echo` 카테고리 정의
  현재 상태: `not started`
- [ ] 기타 장기 콘텐츠 카테고리 정의
  현재 상태: `not started`
- [ ] market offer schema를 다중 카테고리로 확장
  현재 상태: `defined`

### B7. Next Station Loop

- [ ] `Settlement -> Market -> Next Station` 장기 루프 정의
  현재 상태: `partial`
- [ ] `current next stage loop`와 `target next station loop` 차이 정리
  현재 상태: `partial`

### B8. Sector Boss / Final Station

- [ ] `Sector Boss` 구조 정의
  현재 상태: `not started`
- [ ] `Final Station` 구조 정의
  현재 상태: `not started`
- [ ] 일반 station과 boss/final station 차이 규칙 정의
  현재 상태: `not started`

### B9. Run Result Layer

- [ ] `Run Result` 화면/도메인 정의
  현재 상태: `not started`
- [ ] reached station / result / reward summary 구조 정의
  현재 상태: `not started`

### B10. Archive / Stats / Unlock Layer

- [ ] `Archive` 구조 정의
  현재 상태: `defined`
- [ ] `Stats` 구조 정의
  현재 상태: `defined`
- [ ] `Unlock` 반영 구조 정의
  현재 상태: `not started`
- [ ] active run과 archive/history의 경계 확정
  현재 상태: `partial`

## 4. Current Snapshot

### Migration Snapshot

- [x] plan lock
- [x] regression protection
- [x] compatibility wrapper skeleton
- [x] ruleset skeleton
- [x] UI terminology bridge
- [x] market adapter preparation
- [x] save adapter preparation
- [x] debug fixture / active run separation
- [x] full app run validation complete

### Target Snapshot

- `Home`: partial
- `Run Setup`: not started
- `Station Map`: defined
- `Station Battle`: partial
- `Station Settlement`: partial
- `Market`: partial
- `Next Station Loop`: partial
- `Sector Boss / Final Station`: not started
- `Run Result`: not started
- `Archive / Stats / Unlock`: partial

## 5. Recommended Next Decision

최근 반영:

- [x] active run save payload에 `rulesetId` 저장/복원 경로 반영
- [x] shop `reroll` mutation을 notifier command로 1차 이관
- [x] `cash-out -> market -> next station` 시퀀스를 notifier command로 정리
- [x] `GameView -> GameShopScreen` 경계를 market/save facade read path 기준으로 축소
- [x] battle HUD/board/hand read path를 `RummiBattleRuntimeFacade` 기준으로 정리
- [x] active run 저장을 notifier runtime snapshot + `saveRuntimeState()` 기준으로 정리

현재 재점검 결론:

- [x] A 단계 잔여 `current-only` 결합은 다시 확인했다.
- [x] 남은 직접 참조는 주로 `GameView` 내부 UI state/settlement 표현 범위다.
- [x] 코드 상태 기준으로 A의 핵심 migration 목표는 이미 충족한 편이다.

현재 가장 자연스러운 다음 작업:

- [ ] `B7. Next Station Loop` 설계를 시작
  이유: current loop는 이미 notifier/facade 경계로 1차 정리됐고, 이제는 이 흐름을 장기 제품 구조로 어떻게 나눌지 정의하는 편이 더 큰 진전이다.

구체적인 다음 PR 범위:

- `Settlement -> Market -> Next Station`을 `current loop`와 `target loop`로 분리해 정의
- `GameView` 단일 route 유지 범위와 future station map/preview 진입 지점 확정
- `cash-out sheet`, `shop route`, `next station CTA`를 어떤 상태 모델로 묶을지 문서화
- 이어서 `B1. Home Layer` 진입 구조 초안 착수
