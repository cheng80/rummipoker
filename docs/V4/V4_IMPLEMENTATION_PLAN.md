# Rummi Poker Grid V4 Implementation Plan

검토용 순서/진행 체크는 [V4_REVIEW_CHECKLIST.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_REVIEW_CHECKLIST.md)에서 함께 본다.

## 1. Plan Scope

[CURRENT] [DOC VERIFIED]

이 문서는 **구현 플랜**이다. 이번 작업 자체는 `plan-only / docs-only`이며, 현재 프로토타입을 장기 제품 구조로 흡수 확장하기 위한 순서를 정의한다.

[PROTECT] [CODE VERIFIED]

이번 계획의 최우선 원칙은 현재 프로토타입 코어 보호다.

- 5x5 보드
- 12라인 평가
- 부분 줄 평가
- 즉시 확정
- One Pair = 0점 dead line
- overlap 보너스
- contributor union만 제거
- `copiesPerTile` 기반 덱
- stage → cash-out → full-screen Jester shop → next stage
- active run save v2
- `stageStartSnapshot` 기반 현재 stage 재시작
- shared_preferences + device key store(native secure storage / web local storage) + HMAC-SHA256 무결성

[DO-NOT-DO] [DOC VERIFIED]

이번 계획 단계와 초기 PR에서 하지 않는 일:

- `lib/` 직접 구조 변경
- save schema 즉시 교체
- One Pair 점수 변경
- economy 수치 즉시 변경
- Jester id 변경
- code symbol 대규모 rename
- DB 엔진 도입

## 2. Current Baseline Summary

[CURRENT] [CODE VERIFIED]

현재 구현 baseline은 아래와 같다.

- Combat: 5x5, 12라인, partial line evaluation, instant confirm, contributor-only removal, overlap
- Scoring: High Card 0, One Pair 0, Two Pair 이상 scoring
- Deck: `copiesPerTile` 기반, 기본 52장
- Hand: 기본 1장, debug 1~3장
- Resources: board discard 4, hand discard 2
- Run: stage → cash-out → full-screen Jester shop → next stage
- Economy: start gold 10, stage clear base 10, reroll 5
- Jester: curated common catalog, equipped slots 5, buy/sell/reroll, stateful 일부
- Save: active run save v2, `stageStartSnapshot`, HMAC
- UI: title, game, full-screen shop, settings

[WATCH] [CODE VERIFIED]

현재 `confirmAllFullLines`라는 이름은 legacy지만, 실제 동작은 “현재 scoring line 즉시 확정”이다.

## 3. Non-Negotiable Protection Rules

[PROTECT] [CODE VERIFIED]

초기 마이그레이션에서 깨면 안 되는 규칙:

1. One Pair는 기본 ruleset에서 계속 0점이다.
2. High Card / One Pair는 confirm scoring candidate가 아니다.
3. 제거는 line 전체가 아니라 contributor union만 수행한다.
4. overlap default는 `alpha = 0.3`, `cap = 2.0`다.
5. Jester id는 변경하지 않는다.
6. active run save v2를 깨지 않는다.
7. `stageStartSnapshot` 재시작 semantics를 유지한다.
8. `RummiBlindState`, `scoreTowardBlind` 등 code symbol은 즉시 rename하지 않는다.
9. Station/Market/Archive 구조는 초기에는 adapter 또는 feature flag 뒤에 둔다.
10. 전투 규칙 변경과 경제 변경을 한 PR에 섞지 않는다.

## 4. Source Traceability

[CURRENT] [DOC VERIFIED]

상세 표는 [V4_PLAN_TRACEABILITY_MATRIX.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md)에 정리한다.

핵심 연결만 요약하면 아래와 같다.

| Area | Current Source | V4 Source | Status | Notes |
|---|---|---|---|---|
| Combat scoring | `lib/logic/rummi_poker_grid/hand_rank.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | One Pair 0 |
| Confirm/removal | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | contributor union |
| Jester/shop | `lib/logic/rummi_poker_grid/jester_meta.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/04_JESTER_MARKET_CONTENT.md` | [CODE VERIFIED] | current Jester 중심 |
| Save/checkpoint | `lib/services/active_run_save_service.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/05_SAVE_CHECKPOINT_DATA.md` | [CODE VERIFIED] | save v2 유지 |
| UI flow | `lib/views/game_view.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | battle → shop |

## 5. Current Code Anchors

[CURRENT] [CODE VERIFIED]

| File | Responsibility | Migration Risk | Plan Policy |
|---|---|---:|---|
| `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | confirm/removal/expiry/stage transition | Critical | tests first, wrapper only |
| `lib/logic/rummi_poker_grid/hand_rank.dart` | scoring constants / dead line | High | baseline lock |
| `lib/logic/rummi_poker_grid/hand_evaluator.dart` | partial line evaluation / contributor indexes | High | parity tests before refactor |
| `lib/logic/rummi_poker_grid/jester_meta.dart` | Jester, economy, shop, run progress | Critical | adapter before split |
| `lib/services/active_run_save_service.dart` | active run save/load / checkpoint snapshot | Critical | compatibility first |
| `lib/providers/features/rummi_poker_grid/game_session_notifier.dart` | orchestration for confirm/cash-out/shop/stage | High | keep flow stable, isolate new adapters |
| `lib/views/game_view.dart` | runtime UI flow / save trigger / navigation | High | UI PR separate from rules PR |
| `lib/logic/rummi_poker_grid/rummi_battle_facade.dart` | battle HUD/board/hand read model | Medium | expand read path without replacing session runtime |
| `lib/views/game/widgets/game_shop_screen.dart` | current full-screen shop UX | Medium | preserve route/UX in early phases |
| `lib/providers/features/rummi_poker_grid/title_notifier.dart` | continue availability / clear stored run | Medium | protect continue flow |
| `lib/utils/storage_helper.dart` | SharedPreferences wrapper | Medium | preserve as backend until adapter layer exists |

## 6. Risk Register

[CURRENT] [DOC VERIFIED]

상세 표는 [V4_PLAN_RISK_REGISTER.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_PLAN_RISK_REGISTER.md)에 정리한다.

핵심 리스크 요약:

| Risk | Impact | Likelihood | Mitigation | Guardrail Test |
|---|---|---|---|---|
| One Pair 10점 오도입 | Critical | Medium | baseline lock | One Pair 0 regression |
| contributor 제거 회귀 | Critical | Medium | wrapper before refactor | Two Pair/Four of a Kind removal tests |
| overlap 상수 변경 | High | Medium | current defaults lock | overlap parity test |
| `stageStartSnapshot` 손상 | Critical | Medium | save adapter shadow mode | restart parity |
| save/load 호환성 파손 | Critical | Medium | save v2 유지 | HMAC + restore tests |
| code rename 파손 | High | Medium | terminology migration last | provider/route smoke tests |

## 7. Migration Phases

### Phase 0: Plan lock

Goal:
V4 기준 구현 순서를 문서로 고정하고 금지 규칙을 명시한다.

Files likely touched:
`docs/V4/V4_IMPLEMENTATION_PLAN.md`
`docs/V4/V4_PLAN_RISK_REGISTER.md`
`docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md`

Allowed changes:
docs only

Forbidden changes:
`lib/`, `test/`, `data/`, save schema

Required tests:
없음. 문서 리뷰만

Acceptance criteria:
첫 3개 PR과 금지 작업이 명확하다.

Rollback strategy:
문서 revert

### Phase 1: Regression tests

Goal:
현재 코어 전투와 save/restart를 테스트로 먼저 보호한다.

Files likely touched:
`test/logic/*`
`test/providers/*`

Allowed changes:
current behavior를 고정하는 regression test 추가

Forbidden changes:
behavior 변경, economy 변경, save schema 변경

Required tests:
combat / expiry / restart / save-load parity

Acceptance criteria:
One Pair 0, contributor removal, overlap, restart semantics가 테스트로 식별된다.

Rollback strategy:
추가 테스트만 되돌리면 됨

### Phase 2: Compatibility wrappers

Goal:
현재 코드 심볼과 target 문서 사이의 용어/구조 차이를 wrapper로 흡수한다.

Files likely touched:
new adapter/wrapper docs and thin Dart wrappers around existing state

Allowed changes:
read-only adapter, alias, facade

Forbidden changes:
핵심 session 로직 교체

Required tests:
existing tests + adapter smoke

Acceptance criteria:
target 문서가 current runtime을 직접 깨지 않고 읽을 수 있다.

Rollback strategy:
wrapper 제거, core untouched

### Phase 3: Ruleset config skeleton

Goal:
current combat default를 보존하는 ruleset/config 뼈대를 만든다.

Files likely touched:
new ruleset config files or models

Allowed changes:
default mirror constants only

Forbidden changes:
default behavior change, One Pair score change

Required tests:
config enabled/disabled parity

Acceptance criteria:
ruleset 계층이 생겨도 current defaults가 유지된다.

Rollback strategy:
feature flag off

### Phase 4: UI-only terminology bridge

Goal:
Station/Market/Archive 용어를 UI copy 또는 docs alias로만 부분 도입한다.

Files likely touched:
copy resources, docs, UI labels

Allowed changes:
player-facing text only

Forbidden changes:
save field rename, code symbol rename

Required tests:
title/game/shop smoke tests

Acceptance criteria:
용어 전환이 런타임 구조 변경 없이 가능하다.

Rollback strategy:
text revert

### Phase 5: Market/Jester adapter preparation

Goal:
current Jester-only shop를 장기 Market 구조와 연결할 adapter/read model 준비를 한다.

Files likely touched:
new market adapter models, docs

Allowed changes:
adapter layer, read model, mapping

Forbidden changes:
`jester_meta.dart` 즉시 분해, id rename

Required tests:
shop buy/sell/reroll smoke

Acceptance criteria:
current shop를 유지한 채 future market slot 확장 준비가 된다.

Rollback strategy:
adapter layer 제거

### Phase 6: Save/checkpoint adapter preparation

Goal:
active run save v2를 유지하면서 future domain model과 연결할 adapter를 준비한다.

Files likely touched:
save DTO mapper, migration doc/tests

Allowed changes:
read model, mapper, compatibility validator

Forbidden changes:
backend 교체, persistence key rename

Required tests:
save/load, corrupt save, restart parity

Acceptance criteria:
current save stays source of truth, future domain mapping 가능

Rollback strategy:
adapter 제거, save v2 유지

### Phase 7: Station target prototype behind feature flag

Goal:
stage 기반 current loop 위에 Station target 구조를 feature flag 뒤에서만 실험한다.

Files likely touched:
new prototype files only

Allowed changes:
feature-flagged prototype path

Forbidden changes:
default runtime replacement

Required tests:
flag off parity, flag on isolated smoke

Acceptance criteria:
current stage loop가 기본값으로 유지된다.

Rollback strategy:
flag off

### Phase 8: Archive/stats read model

Goal:
active run과 분리된 archive/stats read model을 추가한다.

Files likely touched:
new stats/archive models and readers

Allowed changes:
append-only or derived models

Forbidden changes:
active run schema replacement

Required tests:
read model generation tests

Acceptance criteria:
archive/stats가 current save를 깨지 않고 읽힌다.

Rollback strategy:
read model 비활성화

### Phase 9: Balance pass

Goal:
구조가 안정된 뒤 economy와 target 수치를 조정한다.

Files likely touched:
config/data/docs

Allowed changes:
수치 조정

Forbidden changes:
combat core semantics 변경

Required tests:
combat/save regression 전부

Acceptance criteria:
balance 조정이 구조 회귀 없이 가능하다.

Rollback strategy:
data revert

### Phase 10: Optional code rename

Goal:
충분히 안정된 뒤 `Blind/Stage` 계열 code symbol을 rename할지 검토한다.

Files likely touched:
wide but intentional rename PR

Allowed changes:
mechanical rename only

Forbidden changes:
logic change 동시 진행

Required tests:
full suite

Acceptance criteria:
rename only PR, no behavior change

Rollback strategy:
single revertable rename PR

## 8. PR Breakdown

| PR | Type | Goal | Files | Risk | Must Pass | Not Allowed |
|---|---|---|---|---|---|---|
| PR1 | docs-only | V4 implementation plan lock | `docs/V4/*plan*.md` | Low | doc review | code change |
| PR2 | test | combat regression tests | `test/logic/*` | Medium | hand/session tests | scoring change |
| PR3 | test | save/restart regression tests | `test/providers/*`, save tests | High | restart/save tests | save schema change |
| PR4 | compat | confirm compatibility wrapper | new wrapper + minimal glue | Medium | all current tests | session rewrite |
| PR5 | compat | ruleset config skeleton | new config/models | Medium | parity tests | default rules change |
| PR6 | ui-copy | terminology alias UI-only | UI copy/resources/docs | Low | smoke tests | code rename |
| PR7 | adapter | market offer adapter | adapter/read model | Medium | shop smoke | Jester id change |
| PR8 | adapter | save/checkpoint adapter | mapper/read model | High | save/restart tests | backend swap |
| PR9 | read-model | archive/stats read model | new models/services | Medium | summary tests | active run replace |
| PR10 | feature-flag | station prototype behind flag | isolated prototype files | High | flag-off parity | default runtime replace |

## 9. Test Strategy

[PROTECT] [TEST VERIFIED]

초기 보호 테스트 우선순위:

1. `HandRank.onePair` score remains `0`
2. One Pair는 confirm scoring candidate가 아님
3. Two Pair contributor 4장만 제거
4. Four of a Kind contributor 4장만 제거
5. Straight / Flush / Full House는 5장 contributor
6. overlap alpha/cap 유지
7. board full + no discard 만료 조건
8. deck exhausted + no playable action 만료 조건
9. stage clear → cash-out → shop → next stage
10. `stageStartSnapshot` restart
11. active run save/load HMAC 검증
12. corrupted save 처리
13. Jester stateful value save/restore

[MIGRATION] [DOC VERIFIED]

PR2와 PR3에서 부족한 회귀 테스트를 추가하는 것이 전체 마이그레이션의 선행 조건이다.

앱 실구동 검증이 필요한 단계에서는 iOS 시뮬레이터 수동 검증을 ad-hoc으로 반복하지 않고 `tools/ios_sim_smoke.sh` 기준으로 실행한다.
스크린샷과 로그는 `/tmp/rummipoker_ios_smoke/<timestamp>/` 산출물을 기준으로 남기고, 체크리스트에는 검증 route/시나리오를 함께 적는다.
web 저장/플러그인 경계 검증은 `tools/web_build_smoke.sh` 기준으로 `flutter build web` / `flutter build web --wasm`를 재사용 가능한 절차로 실행한다.

## 10. Save Compatibility Strategy

[PROTECT] [CODE VERIFIED]

저장 전략 기본값:

1. current active run save v2 유지
2. current `stageStartSnapshot` semantics 유지
3. DB/Archive는 즉시 대체가 아니라 read model 또는 adapter로 접근
4. 기존 save payload key와 HMAC 체계를 깨지 않는다
5. schema 변경이 필요하면 별도 PR + migration test + rollback plan이 필요하다

[DO-NOT-DO] [DOC VERIFIED]

- GetStorage 제거
- secure storage key 교체
- active run payload 필드 rename
- checkpoint 삭제

## 11. Terminology Migration Strategy

[MIGRATION] [DOC VERIFIED]

용어 전환 순서:

1. 문서 alias
2. UI-only 용어 전환
3. adapter/facade 명칭 정리
4. 마지막에 code symbol rename 검토

[PROTECT] [CODE VERIFIED]

초기에는 아래를 유지한다.

- `RummiBlindState`
- `scoreTowardBlind`
- stage index

즉, Station은 먼저 **문서와 UX 레이어의 장기 용어**로만 사용한다.

## 12. Jester / Market Migration Strategy

[CURRENT] [CODE VERIFIED]

현재는 `jester_meta.dart`가 Jester + economy + run progress + shop을 함께 관리한다.

[MIGRATION] [DOC VERIFIED]

초기 전략:

1. current `jester_meta.dart`는 즉시 분해하지 않는다
2. 먼저 market read model / adapter를 둔다
3. Jester id와 stateful slot 구조를 보호한다
4. Run Kit / Permit / Glyph / Orbit / Echo / Sigil은 target/future로 분리한다

[DO-NOT-DO] [CODE VERIFIED]

- Jester id rename
- saved slot index semantics 변경
- current shop를 market full implementation으로 바로 대체

## 13. UI / UX Migration Strategy

[CURRENT] [CODE VERIFIED]

현재 보호할 흐름:

- title
- game
- confirm settlement
- cash-out
- full-screen shop
- next stage

[MIGRATION] [DOC VERIFIED]

장기 UX로 가는 방법:

1. current battle/shop flow 유지
2. Station map / Archive / Trial은 별도 route로 target 처리
3. 전투 화면 리디자인은 전투 로직 변경 PR과 분리
4. player-facing terminology만 먼저 bridge

## 14. Open Decisions

[OPEN] [DOC VERIFIED]

초기 마이그레이션에서 보류 또는 별도 실험으로 남겨 둘 결정:

1. One Pair 10점 실험 여부
2. 최종 Station 수
3. Entry/Pressure/Lock 수치
4. 최종 economy 수치
5. DB 엔진 도입 시점
6. Archive/Stats 최소 범위
7. code rename 시점
8. Market가 Jester-only를 벗어나는 최소 단계

## 15. B7 Next Station Loop UI Plan

[NEXT] [DOC VERIFIED]

다음 구현/설계 시작점은 `B7. Next Station Loop`다.

이 단계 목표는 current loop를 갈아엎는 것이 아니라, 이미 돌아가는
`settlement -> shop -> next stage` 흐름을 장기 `Settlement -> Market -> Next Station`
구조로 다시 읽을 수 있게 만드는 것이다.

현재 코드 기준 고정점:

- battle 종료 후 settlement 연출이 있다
- cash-out sheet가 보상 요약과 gold 반영을 맡는다
- market은 full-screen route다
- next station 진입은 notifier command로 이미 감싸져 있다
- active run 저장은 scene/runtime snapshot 기준으로 유지된다

이번 설계에서 먼저 나눌 축:

1. 화면 축
   - `Battle`
   - `Settlement`
   - `Market`
   - `Next Station Transition`
2. 상태 축
   - battle 결과 표시 상태
   - settlement 보상 확정 상태
   - market 체류 상태
   - next station 진입 준비 상태
3. 저장 축
   - battle 중 저장
   - settlement 직후 저장
   - market 체류 중 저장
   - next station 진입 직후 checkpoint 갱신

세부 UI 분해 순서:

### Step 1. Settlement 경계 명확화

Goal:
cash-out 연출/보상 합산/다음 버튼의 책임을 `Settlement` 단계로 명시한다.

Questions:

- 현재 `cash-out sheet`가 담당하는 정보 중 무엇이 장기 settlement read model로 남아야 하는가
- `confirm settlement`와 `cash-out complete`를 같은 단계로 둘지 분리할지
- settlement 종료 시 저장 scene을 어디로 둘지

Likely files:

- `lib/views/game_view.dart`
- `lib/views/game/widgets/game_cashout_widgets.dart`
- `lib/providers/features/rummi_poker_grid/game_session_state.dart`

### Step 2. Market 진입/복귀 구조 정리

Goal:
market route가 단순 shop 화면인지, station loop의 정식 단계인지 명확히 한다.

Questions:

- current full-screen shop route를 그대로 `Market`으로 승격할지
- market에서 뒤로 가기/중단/저장 semantics를 어떻게 둘지
- `pendingResumeShop`이 장기적으로 어떤 navigation state를 대신하는지

Likely files:

- `lib/views/game/widgets/game_shop_screen.dart`
- `lib/views/game_view.dart`
- `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`

### Step 3. Next Station CTA/Transition 정의

Goal:
현재 `next stage` 버튼을 장기 `Next Station` 전환 단계로 재정의한다.

Questions:

- next station 진입 전에 preview 또는 map entry가 필요한지
- 없으면 현재처럼 즉시 진입하되 어떤 facade/state 이름으로 감쌀지
- checkpoint 갱신 시점을 settlement 완료 기준으로 둘지, station 진입 완료 기준으로 둘지

Likely files:

- `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
- `lib/services/active_run_save_service.dart`
- `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md`

### Step 4. 검증 기준

Required verification:

- provider test: settlement -> market -> next station 상태 전이
- widget test: market resume/read path 유지
- iOS smoke: full loop 재실행 가능

Acceptance:

- current loop를 유지한 채 `B7` 문서와 코드 용어가 서로 맞는다
- `GameView`가 모든 단계를 직접 조립하지 않아도 된다
- 이후 `B1 Home Layer`, `B3 Station Map`로 자연스럽게 이어질 수 있다

## 16. B1 Home Layer UI Plan

[NEXT] [DOC VERIFIED]

`B7` 바로 다음 후보는 `B1. Home Layer`다.

핵심은 현재 `TitleView` 중심 진입을 장기 Home 구조로 확장하되,
continue/delete/corrupt save 동선을 망가뜨리지 않는 것이다.

우선 나눌 화면 블록:

1. `Continue`
2. `New Run`
3. `Trial`
4. `Archive`
5. `Settings`

초기 설계 질문:

- 지금 `TitleView`를 Home의 1차 구현으로 볼지, 새 route를 둘지
- `continue / delete / corrupted save` dialog를 Home card/action 구조로 흡수할지
- debug fixture 진입을 release-visible Home에서 완전히 분리할지

초기 구현 원칙:

- 새 런 진입 세부 단계는 `B2`로 넘기고, `B1`에서는 entry layout만 정리
- active run summary는 save facade read model 재사용
- archive/trial은 눌렀을 때 placeholder여도 route 구조는 먼저 정리 가능

## 17. Acceptance Criteria

[DOC VERIFIED]

이 계획 문서가 완료되었다고 보려면 아래를 만족해야 한다.

1. 첫 3개 PR이 명확하다
2. 각 PR의 금지 작업이 명시되어 있다
3. current 코어 전투 보호 테스트가 식별되어 있다
4. save/restart 보호 전략이 있다
5. Station/Market/Archive가 current runtime으로 오해되지 않는다
6. One Pair 0점 규칙이 보호 대상임이 분명하다
7. current-to-target migration이 단계별로 되돌릴 수 있다

## 18. First 3 PR Detailed Plan

### PR 1: V4 implementation plan lock

Goal:
V4 마이그레이션 계획을 문서로 고정한다.

Files to inspect:
`START_HERE.md`
`docs/current_system/*`
`docs/V4/*`

Files to change:
`docs/V4/V4_IMPLEMENTATION_PLAN.md`
`docs/V4/V4_PLAN_RISK_REGISTER.md`
`docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md`

Tests to add or run:
없음. 문서 리뷰

Review checklist:
- current baseline 보호 규칙이 명확한가
- 금지 작업이 적혀 있는가
- 첫 3 PR이 되돌릴 수 있게 분리되어 있는가

Abort conditions:
- current baseline과 target이 구분되지 않음

### PR 2: combat regression tests

Goal:
combat core 회귀를 테스트로 고정한다.

Files to inspect:
`lib/logic/rummi_poker_grid/hand_rank.dart`
`lib/logic/rummi_poker_grid/hand_evaluator.dart`
`lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
`test/logic/rummi_board_engine_test.dart`
`test/logic/rummi_session_test.dart`

Files to change:
combat regression 관련 `test/logic/*`

Tests to add or run:
- One Pair 0
- One Pair not scoring candidate
- contributor removal parity
- overlap parity
- expiry parity

Review checklist:
- 테스트가 current behavior만 고정하는가
- target behavior를 앞당겨 도입하지 않았는가

Abort conditions:
- 테스트 추가가 behavior change를 요구함

### PR 3: save/restart regression tests

Goal:
active run save/load와 stage restart semantics를 보호한다.

Files to inspect:
`lib/services/active_run_save_service.dart`
`lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
`lib/views/game_view.dart`
existing provider/save tests

Files to change:
save/restart 관련 `test/`만

Tests to add or run:
- active run save/load parity
- HMAC invalid save rejection
- `stageStartSnapshot` restart parity
- stateful Jester restore

Review checklist:
- 현재 save payload를 변경하지 않았는가
- continue/clear/corrupt save 흐름이 그대로인가

Abort conditions:
- 테스트 추가만으로 save schema 변경이 필요함

## 19. Explicitly Deferred Work

[FUTURE] [DOC VERIFIED]

초기 마이그레이션에서 명시적으로 미루는 작업:

1. One Pair 10점 기본 도입
2. Station 30개 전체 구현
3. Entry/Pressure/Lock 본 구현
4. DB 저장소 교체
5. Archive 완성형 구현
6. Risk Grade / Trial 구현
7. 대규모 code rename
8. Jester catalog id 변경
9. economy full rebalance
10. `jester_meta.dart` 대분해

[DO-NOT-DO] [DOC VERIFIED]

위 항목은 초기 PR에 섞지 않는다. 특히 전투 규칙 보호 PR과 메타 구조 확장 PR을 절대 결합하지 않는다.
