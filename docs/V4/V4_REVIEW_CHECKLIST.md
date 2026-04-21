# V4 Review Checklist

문서 목적: `V4` 진행 상태를 두 층으로 관리한다.

- `A. Migration Checklist`
  현재 프로토타입을 깨지 않고 V4 구조로 옮겨 가는 체크리스트
- `B. Target Product Checklist`
  V4 최종 장기 목표가 어떤 큰 기능 축으로 완성되어야 하는지 보는 체크리스트

이 문서는 세부 설계 문서가 아니다.  
새 세션에서 “어디까지 왔고, 다음에 무엇을 해야 하는가”를 빠르게 판단하는 용도다.

## 0. Status Summary

마지막 정리 기준:

- A. Migration Checklist: 거의 완료
- B. Target Product Checklist: 부분 구현
- current playable prototype: 주요 루프 플레이 가능
- V4 target product: Item v1 데이터 카탈로그 작성, 장기 기능 축 일부 미구현

진행률 감각:

| 기준 | 진행률 | 판단 |
|---|---:|---|
| Migration readiness | 90-95% | 코어 보호, facade/read model, ruleset/save adapter, app smoke 절차가 대부분 갖춰졌다. |
| Current playable prototype | 약 70% | title/new-run/blind/battle/settlement/market/next loop가 플레이 가능하다. |
| V4 target product 전체 | 약 57-62% | Item v1 데이터 카탈로그는 작성됐고, loader/market/runtime 연결은 남아 있다. Station Map, Sector/Final, Run Result, Archive data도 남아 있다. |

현재 한 줄 결론:

> 프로토타입을 V4 구조로 흡수하기 위한 기반 공사는 거의 끝났고, Item은 실제 v1 데이터 작성이 끝났으며, 이제 loader/market/runtime 연결로 넘어가는 중이다.

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
- [x] battle / market interaction polish의 현재 1차 방향 문서화

완료 기준:
mobile-first 기준으로 실제 앱이 current baseline과 migration 변경을 함께 견뎌야 한다.

현재 기준 프로세스:

- 기본 스크립트: `tools/ios_sim_smoke.sh`
- 기본 캡처 대기 시간: `4초`
- 느린 화면/첫 프레임 안정화가 필요하면 `--settle 5` 이상으로 완화
- 웹 빌드 smoke 스크립트: `tools/web_build_smoke.sh`
- launch/title 확인: `tools/ios_sim_smoke.sh`
- home/new-run/archive/trial shell 확인:
  `tools/ios_sim_smoke.sh --route "/new-run" --settle 5`
  `tools/ios_sim_smoke.sh --route "/archive" --settle 5`
  `tools/ios_sim_smoke.sh --route "/trial" --settle 5`
- 스크롤이 필요한 shell 하단 확인:
  `tools/ios_sim_smoke.sh --route "/?debug_scroll=bottom" --settle 8`
  `tools/ios_sim_smoke.sh --route "/new-run?debug_scroll=bottom" --settle 8`
  `tools/ios_sim_smoke.sh --route "/archive?debug_scroll=bottom" --settle 8`
  `tools/ios_sim_smoke.sh --route "/trial?debug_scroll=bottom" --settle 8`
- fixture battle 확인: `tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot"`
- background save / relaunch 확인:
  `tools/ios_sim_smoke.sh --open-url "https://example.com" --relaunch`
- full loop 확인:
  `tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1"`
- web build 확인: `tools/web_build_smoke.sh --web-only`
- web wasm build 확인: `tools/web_build_smoke.sh --wasm-only`
- web interaction/dialog 확인:
  `flutter build web` 산출물을 정적 서버로 열고 Playwright로 실제 route/interaction을 눌러 screenshot 확보
- 의미 있는 실구동 검증은 스크린샷/로그 산출물 경로까지 남긴다.

최근 검증 산출물:

- title launch 확인:
  `/tmp/rummipoker_ios_smoke/title_smoke_20260420_0230/`
- home shell 확인:
  `/tmp/rummipoker_ios_smoke/home_shell_check_20260420/`
- home shell 하단 확인:
  `/tmp/rummipoker_ios_smoke/home_bottom_direct_20260420_seq/`
- new run shell 확인:
  `/tmp/rummipoker_ios_smoke/new_run_shell_check_20260420/`
- new run shell 하단 확인:
  `/tmp/rummipoker_ios_smoke/new_run_bottom_direct_20260420_seq/`
- archive shell 확인:
  `/tmp/rummipoker_ios_smoke/archive_shell_check_20260420/`
- archive shell 하단 확인:
  `/tmp/rummipoker_ios_smoke/archive_bottom_direct_20260420_seq/`
- trial shell 확인:
  `/tmp/rummipoker_ios_smoke/trial_shell_check_20260420/`
- trial shell 하단 확인:
  `/tmp/rummipoker_ios_smoke/trial_bottom_direct_20260420_seq/`
- fixture battle 확인:
  `/tmp/rummipoker_ios_smoke/fixture_stage2_smoke_20260420_0230/`
- background save / relaunch 확인:
  `/tmp/rummipoker_ios_smoke/background_relaunch_smoke_20260420_0230/`
- `cash-out -> market -> next station` 확인:
  `/tmp/rummipoker_ios_smoke/cashout_market_next_station_smoke_20260420_0252/`
- web dialog/button smoke 확인:
  `/tmp/rummipoker_web_smoke/browser_buttons_20260420_fix/`
- Playwright screenshot 산출물:
  `/tmp/rp_playwright_smoke/title_continue_dialog_fixed.png`
  `/tmp/rp_playwright_smoke/blind_start_dialog_fixed.png`

현재 결정:

- Chrome 기기는 현재 연결 가능 상태를 확인했다.
- 이번 단계에서는 mobile-first/iOS smoke가 핵심 acceptance를 충족하므로 Chrome 실구동은 필수 게이트로 두지 않는다.
- 다만 web 저장/라우팅/입력 경계가 바뀌는 PR이나 release 전 점검 단계에서는 `tools/web_build_smoke.sh`를 먼저 돌리고, 필요 시 `local server + Playwright` interaction screenshot까지 같이 수행한다.

최근 UI 정리 메모:

- market는 scroll list 대신 `카드 선택 + 상세 패널 + page/reroll` 구조로 재정리됐다.
- market 상단 `Jester Slots / Item Slots` 분리와 card-only shop 표현이 반영됐다.
- battle item zone은 설명형 bar 대신 큰 slot 3개 중심으로 정리 중이다.
- battle debug 조작은 inline cluster를 제거하고 small debug button + bottom sheet 구조로 이동했다.

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
- [x] `TitleView`를 Home 1차 구조로 재구성
  현재 상태: `implemented`
- [x] `이어하기` block에 저장 진행 summary 노출
  현재 상태: `implemented`
- [x] `새 시작` entry를 전용 route로 분리
  현재 상태: `implemented`
- [x] `특별 모드` placeholder route 분리
  현재 상태: `implemented`
- [x] `기록실` placeholder route 분리
  현재 상태: `implemented`
- [x] `기록실` 전용 route/view 분리
  현재 상태: `implemented`
- [x] 개발/검증용 진입을 `디버그` 섹션으로만 분리
  현재 상태: `implemented`
- [ ] `Continue / New Run / Trial / Archive` 4갈래 진입 정리
  현재 상태: `partial`
- [ ] `특별 모드`를 실제 유저 모드로 둘지 placeholder로 유지할지 결정
  현재 상태: `not started`
- [x] `기록실` 첫 실제 블록(예: 기록/수집/통계 shell) 연결
  현재 상태: `implemented`
- [x] `기록 / 수집 / 통계` 3블록을 각각 독립 section으로 노출
  현재 상태: `implemented`
- [ ] 손상 세이브 / continue / delete 동선이 최종 Home 구조와 맞게 정리
  현재 상태: `partial`
- [x] continue/delete/corrupt save dialog를 게임 톤의 custom dialog로 1차 교체
  현재 상태: `implemented`

### B2. Run Setup Layer

- [x] `새 게임 시작` 전용 route 분리
  현재 상태: `implemented`
- [x] `Random Start / Seed Start`를 `새 게임 시작` 화면으로 이동
  현재 상태: `implemented`
- [x] blind select에서 `블라인드 시작` 확인 dialog를 custom dialog로 연결
  현재 상태: `implemented`
- [x] `덱 선택` 플레이스홀더 card 유지
  현재 상태: `implemented`
- [x] `난이도 선택` 잠금 구조/해금 상태 읽기 연결
  현재 상태: `implemented`
- [x] `새 게임 시작 -> 블라인드 선택` route 분리
  현재 상태: `implemented`
- [x] `블라인드 선택` 1차 shell/UI 연결
  현재 상태: `implemented`
- [x] `스몰/빅/보스 블라인드` 조건 미리보기 데이터 구조 추가
  현재 상태: `implemented`
- [x] 선택한 `blind tier`가 실제 전투 시작값에 반영
  현재 상태: `implemented`
- [x] `빅/보스 블라인드` 실제 선택 해금
  현재 상태: `implemented`
- [x] `이어하기 -> 블라인드 선택` 복귀 구조 연결
  현재 상태: `implemented`
- [ ] `Seed / Difficulty / Blind` 선택 흐름 정리
  현재 상태: `partial`
- [ ] `Balatro식 Blind Skip` 도입 여부/조건 정의
  현재 상태: `not started`
  현재 결정: blind tier/station progression/save 복원이 먼저이며, skip은 그 뒤 단계에서 분리 검토
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

- [x] `Jester` market 카테고리
  현재 상태: `implemented`
- [x] `Item` v1 실제 데이터 카탈로그 작성
  현재 상태: `implemented`
  기준 파일: `data/common/items_common_v1.json`
- [ ] `ItemDefinition` loader / repository 연결
  현재 상태: `not started`
- [ ] `ItemOffer` market adapter 연결
  현재 상태: `not started`
- [ ] `OwnedItemEntry` / quick slot / passive rack runtime 연결
  현재 상태: `not started`
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

- [x] `small -> big -> boss -> next station small` blind progression 반영
  현재 상태: `implemented`
- [x] `보스 클리어 -> settlement -> market -> 다음 station blind select` 연결
  현재 상태: `implemented`
- [x] `blind select` scene save/continue 경로 반영
  현재 상태: `implemented`
- [x] 다음 station 루프 디버그 강제 진입 액션 추가
  현재 상태: `implemented`

### B8. Runtime Polish / Safety

- [x] stage clear settlement와 game over dialog 동시 노출 회귀 수정
  현재 상태: `implemented`
- [x] confirm/selection 하단 버튼 오동작 완화 배치 조정
  현재 상태: `implemented`
- [x] market drag-sell 안내와 reroll 영역 간격 보정
  현재 상태: `implemented`
- [x] game dialog / home button glow 제거와 높이 재조정
  현재 상태: `implemented`

- [ ] `Settlement -> Market -> Next Station` 장기 루프 정의
  현재 상태: `partial`
- [ ] `current next stage loop`와 `target next station loop` 차이 정리
  현재 상태: `partial`
- [ ] `Market -> 블라인드 선택 -> 전투 시작` 연결
  현재 상태: `not started`
- [ ] active run save가 `blind select` scene을 복원
  현재 상태: `not started`

### B9. Sector Boss / Final Station

- [ ] `Sector Boss` 구조 정의
  현재 상태: `not started`
- [ ] `Final Station` 구조 정의
  현재 상태: `not started`
- [ ] 일반 station과 boss/final station 차이 규칙 정의
  현재 상태: `not started`

### B10. Run Result Layer

- [ ] `Run Result` 화면/도메인 정의
  현재 상태: `not started`
- [ ] reached station / result / reward summary 구조 정의
  현재 상태: `not started`

### B11. Archive / Stats / Unlock Layer

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
- `Run Setup`: partial
- `Station Map`: defined
- `Station Battle`: partial
- `Station Settlement`: partial
- `Market`: partial, Item v1 data catalog implemented
- `Next Station Loop`: partial
- `Runtime Polish / Safety`: partial
- `Sector Boss / Final Station`: not started
- `Run Result`: not started
- `Archive / Stats / Unlock`: partial

## 5. Recommended Next Decision

현재 재점검 결론:

- [x] A 단계 핵심 migration 목표는 충족한 편이다.
- [x] 코어 전투/save/restart는 regression과 smoke 절차로 보호된다.
- [x] battle/shop/save read path는 facade/notifier 기반으로 1차 정리됐다.
- [x] `새 게임 시작 -> 블라인드 선택 -> 전투 시작` 흐름은 실제 코드에 연결됐다.
- [x] `small -> big -> boss -> market -> next station blind select` 1차 루프가 연결됐다.
- [x] battle/market UI는 카드 슬롯 체급과 선택 외곽선 기준을 고정하는 중이다.
- [x] Item은 `data/common/items_common_v1.json`에 41개 v1 실사용 후보 데이터로 작성됐다.

현재 가장 자연스러운 다음 작업 축:

1. `B6` Item system runtime 연결
   - `items_common_v1.json` loader / `ItemDefinition` 모델 추가
   - market item offer adapter 연결
   - quick slot / equipment / passive rack 저장 구조 연결
2. `B2/B7` blind/station pacing polish
   - station target scale 기본값 재점검
   - small/big/boss 보상/압박 수치 재조정
   - blind unlock 템포와 continue 복귀 동선 확인
3. `B6/B8` market/battle interaction polish
   - market 카드/아이템 슬롯 기준 유지
   - 설명 패널 고정 높이와 텍스트 말줄임 기준 안정화
   - button/dialog visual consistency 유지
4. `B2` deferred run rule 정리
   - Balatro식 blind skip 도입 여부와 조건 결정
   - skip을 넣는다면 save/checkpoint/보상 규칙을 먼저 문서화
5. `B3/B10/B11` target product 첫 기능 착수 결정
   - Station Map
   - Archive 실제 데이터 연결
   - Run Result

다음 PR 후보:

- `Item catalog loader + ItemDefinition` 작은 런타임 PR
- `ItemOffer market adapter` 작은 연결 PR
- `blind/station pacing` 작은 수치 PR
- `market/battle UI stability` 작은 polish PR
- `Blind Skip decision` 문서 + 최소 코드 hook PR
- `Archive first data block` 착수 PR
