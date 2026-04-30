# Rummi Poker Grid V4 Implementation Plan

> GCSE role: `Execution`
> Source of truth: V4 구현 순서, PR 분해, migration plan.

검토용 순서/진행 체크는 [STATUS.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/planning/STATUS.md)에서 함께 본다.

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
- Item: v1 data catalog/loader/market read path/buy command/inventory save/runtime hooks mostly connected; remaining hooks are tracked in `ITEM_EFFECT_RUNTIME_MATRIX.md`
- Save: active run save v2, `stageStartSnapshot`, HMAC
- UI: title, game, full-screen shop, settings

[WATCH] [CODE VERIFIED]

현재 `confirmAllFullLines`라는 이름은 legacy지만, 실제 동작은 “현재 scoring line 즉시 확정”이다.

[WATCH] [DOC VERIFIED]

최근 UI 쪽 current baseline 변화:

- market는 full-screen shop route를 유지하되 내부 표현은 `카드 선택 + 상세 패널 + page/reroll` 구조로 이동 중이다.
- battle item zone은 Quick `Q1-Q3`와 Passive `P1-P2`를 의미별로 분리 표시한다. 초기에는 `Q1/Q2/P1`만 열고 `Q3/P2`는 잠금으로 노출한다.
- battle debug 조작은 options dialog/in-line HUD에서 분리해 작은 진입 버튼과 modal bottom sheet로 모으는 방향을 채택했다.

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

| Area | Current Source | V4 Source | Status | Notes |
|---|---|---|---|---|
| Combat board size | `lib/logic/rummi_poker_grid/models/board.dart` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | 5x5 고정 |
| Hand rank scoring | `lib/logic/rummi_poker_grid/hand_rank.dart` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | One Pair 0점 |
| Partial line evaluation | `lib/logic/rummi_poker_grid/hand_evaluator.dart` | `docs/current_system/CURRENT_BUILD_BASELINE.md` | [CODE VERIFIED] | 2~5장 평가 |
| Line scan scope | `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | 행/열/대각 12줄 |
| Confirm removal policy | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | contributor union만 제거 |
| Overlap constants | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | alpha 0.3, cap 2.0 |
| Stage resource model | `lib/logic/rummi_poker_grid/rummi_blind_state.dart` | `docs/specs/V4/03_RUN_META_ECONOMY.md` | [CODE VERIFIED] | `Blind` 명칭 유지 |
| Jester/economy/shop | `lib/logic/rummi_poker_grid/jester_meta.dart` | `docs/specs/V4/04_JESTER_MARKET_CONTENT.md` | [CODE VERIFIED] | Jester 중심 shop |
| Active run save | `lib/services/active_run_save_service.dart` | `docs/specs/V4/05_SAVE_CHECKPOINT_DATA.md` | [CODE VERIFIED] | save v2 + stageStartSnapshot |
| Save storage backend | `lib/utils/storage_helper.dart` | `docs/specs/V4/05_SAVE_CHECKPOINT_DATA.md` | [CODE VERIFIED] | GetStorage wrapper |
| Runtime orchestration | `lib/providers/features/rummi_poker_grid/game_session_notifier.dart` | `docs/specs/V4/07_TECHNICAL_ARCHITECTURE.md` | [CODE VERIFIED] | confirm/cash-out/shop/stage flow |
| Title continue flow | `lib/providers/features/rummi_poker_grid/title_notifier.dart`, `lib/views/title_view.dart` | `docs/specs/V4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | continue/delete/corrupt save 분기 |
| Game UI flow | `lib/views/game_view.dart` | `docs/specs/V4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | battle -> cash-out -> shop |
| Shop UI | `lib/views/game/widgets/game_shop_screen.dart` | `docs/specs/V4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | full-screen shop 유지 |
| Current baseline summary | `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md` | `docs/current_system/CURRENT_BUILD_BASELINE.md` | [DOC VERIFIED] | current baseline 보조 문서 |
| Code ownership map | `docs/current_system/CURRENT_CODE_MAP.md` | `docs/specs/V4/07_TECHNICAL_ARCHITECTURE.md` | [DOC VERIFIED] | 파일 책임 정리 |
| Current-to-target gap | `docs/current_system/CURRENT_TO_V4_GAP.md` | `docs/planning/MIGRATION_ROADMAP.md` | [DOC VERIFIED] | target 단계화 근거 |
| One Pair future pressure | `docs/planning/OPEN_DECISIONS.md` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | [CONFLICT] | 일부 타겟 논의와 current code 충돌 가능, 초기 계획에서는 보호 대상 |

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

| Risk | Impact | Likelihood | Mitigation | Guardrail Test |
|---|---|---|---|---|
| One Pair 10점 오도입 | Critical | Medium | `hand_rank.dart` 기준을 baseline lock, PR 체크리스트에 명시 | `One Pair == 0`, confirm 후보 아님 |
| contributor 제거 대신 line 전체 제거 회귀 | Critical | Medium | confirm 변경은 compatibility wrapper 뒤에서만 수행 | Two Pair 키커 유지 테스트 |
| overlap multiplier 상수 변경 | High | Medium | alpha/cap을 ruleset default에 명시하되 current default 보호 | overlap alpha/cap regression test |
| Jester 발동 순서 변경 | High | Medium | 슬롯 순서 처리 정책 문서화, refactor 전 snapshot test | Jester effect ordering test |
| `stageStartSnapshot` 손상 | Critical | Medium | save/restart adapter는 read-only shadow mode부터 시작 | restart returns exact stage-start state |
| active run save/load 호환성 파손 | Critical | Medium | save schema 교체 금지, adapter layer만 허용 | save/load parity + HMAC verify |
| 코드 rename으로 Provider/UI/save 연결 파손 | High | Medium | terminology 전환은 docs -> UI copy -> code rename 순서 고정 | route + provider smoke tests |
| Station 용어가 current runtime으로 오해됨 | Medium | High | plan/docs에 target label 강제, feature flag 전까지 UI-only 용어 제한 | review checklist for labels |
| DB 도입으로 continue 깨짐 | Critical | Medium | DB는 read model 또는 adapter 준비 단계까지만 허용 | continue load existing save v2 |
| Jester catalog id 변경 | Critical | Low | id rename 금지 정책 명시 | catalog load + saved state restore |
| economy 수치와 전투 룰 동시 변경 | High | Medium | combat PR과 balance PR 분리 | PR scope checklist |
| UI-only 변경이 도메인 변경으로 번짐 | High | Medium | 전투 로직 수정과 UI 리디자인 PR 분리 | UI PR must not touch logic files |
| `Blind`/`Stage` alias 도입이 저장 필드 rename으로 이어짐 | High | Medium | alias 문서화만 먼저, persistence key rename 금지 | save payload field snapshot |
| ruleset config skeleton이 current behavior를 바꿈 | High | Medium | default config는 current constants mirror only | current ruleset parity tests |
| shop adapter 작업 중 기존 reroll/buy/sell 흐름 파손 | High | Medium | adapter는 `jester_meta.dart` 앞단에 얇게 두기 | shop buy/sell/reroll smoke test |
| archive/stats read model이 active run과 결합됨 | Medium | Medium | read model은 append-only summary from existing state | no active run schema diff review |

## 7. Migration Phase Source

상세 phase 정의는 [MIGRATION_ROADMAP.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/planning/MIGRATION_ROADMAP.md)를 단일 기준으로 둔다.

이 문서는 phase별 상세 작업을 반복하지 않고, 아래 실행 판단만 유지한다.

| Phase | Execution focus | Implementation-plan concern |
|---|---|---|
| 0 | Docs lock | 문서 권한과 금지 규칙 고정 |
| 1 | Regression tests | 전투/save/restart 보호망 선행 |
| 2 | Compatibility wrappers | 기존 runtime 교체 없이 alias/facade 추가 |
| 3 | Ruleset config skeleton | default behavior parity 유지 |
| 4 | UI-only terminology bridge | UI copy 전환과 code/save rename 분리 |
| 5 | Market/Jester adapter | Jester id와 shop flow 보호 |
| 6 | Save/checkpoint adapter | active run save v2 유지 |
| 7 | Station prototype | feature flag 뒤에서만 실험 |
| 8 | Archive/stats read model | active run schema와 결합 금지 |
| 9 | Balance pass | 구조 안정 후 수치 조정 |
| 10 | Optional code rename | behavior change 없는 별도 rename PR |

## 8. PR Breakdown

| PR | Type | Goal | Files | Risk | Must Pass | Not Allowed |
|---|---|---|---|---|---|---|
| PR1 | docs-only | V4 implementation plan lock | `docs/planning/*PLAN*.md` | Low | doc review | code change |
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
- market resume는 provider 전역 상태가 아니라 `GameView` 로컬 복귀 책임으로 정리됐다

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
- `GameView` 로컬 market resume 판단을 장기적으로 어떤 navigation state로 치환할지

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
- `docs/specs/V4/06_UI_UX_FLOW.md`

### Step 4. 검증 기준

Required verification:

- provider test: settlement -> market -> next station 상태 전이
- widget test: market resume/read path 유지
- iOS smoke: full loop 재실행 가능

Acceptance:

- current loop를 유지한 채 `B7` 문서와 코드 용어가 서로 맞는다
- `GameView`가 모든 단계를 직접 조립하지 않아도 된다
- 이후 `B1 Home Layer`, `B3 Station Map`로 자연스럽게 이어질 수 있다

Current applied note:

- Group 4 settlement item reward가 cash-out breakdown과 settlement read model에 연결됐다.
- Group 5 inventory/sell hook이 적용됐다. `spare_pouch`는 quick slot 구매/표시 capacity를 늘리고, `jester_hook`은 Market 판매가와 실제 판매 골드를 함께 보정한다.
- Group 6 expiry guard hook이 적용됐다. `safety_net`은 스테이션당 첫 전투 종료 위기에서 보드 버림 또는 구조 드로우를 제공하고 해당 사용 상태를 저장/복원한다.
- Group 8 board move follow-up hook이 적용됐다. `slide_wax`는 다음 성공한 board move marker를 저장/소비하고 undo/save/restore 경계를 갖는다.
- next station blind-select runtime 생성은 `GameSessionNotifier.prepareNextStationBlindSelectRuntime`로 이동했다.
- `beginNextStationTransition`은 `activeRunScene = blindSelect`와 `nextStationTransition` phase를 함께 기록한다.
- Market -> Blind Select 전환 affordance는 1차 적용됐다. 다음 blind-select runtime을 먼저 저장한 뒤 짧은 overlay를 재생하고 route를 이동한다.
- ML 기반 밸런스 자동화를 가능하게 하려면 후속 순서를 `Station Preview/Map scope -> Market offer count/rarity roll -> blind/station pacing baseline -> balance simulation readiness`로 둔다.
- Station Preview/Map scope는 `BlindSelectView`를 `Station Preview v1`로 공식화하는 방향으로 결정했다. Station Map graph와 Station modifier는 후속이다.
- Market 생성 규칙 계획은 `MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`에 정리했다. 기본 offer 수 3/3, v1 cap 5, rarity weight, 중복 제외, 구매 후 재노출 방지, item offer save/restore 개선을 후속 구현 기준으로 둔다.
- Blind/Station pacing baseline은 `BLIND_STATION_PACING_BASELINE_PLAN.md`에 `v4_pacing_baseline_1`로 기록했다. 이 pass는 수치 변경 없이 현재 target/reward/pressure 기준을 ML log 기준으로 고정한다.
- Boss modifier taxonomy는 `BOSS_MODIFIER_TAXONOMY_PLAN.md`에 정리했다. Boss는 단순 목표 점수 증가가 아니라 preview/scoring/save/log에 노출되는 visible rule modifier로 다룬다.
- Starting deck archetype reference는 `STARTING_DECK_ARCHETYPE_PLAN.md`에 정리했다. 현재 New Run은 Random/Seed만 유지하고, 후속 덱 선택은 `run_archetype_id`, 타일 강화는 `tile_modifier_id` 기준으로 ML/simulator에 먼저 연결한다.
- Jester reference taxonomy는 `JESTER_REFERENCE_TAXONOMY_PLAN.md`에 정리했다. Balatro식 Joker 목록은 발동 순서, effect category, edition/penalty, ML feature 참고로만 사용하고 기존 Jester id는 유지한다.
- Consumable/Voucher reference taxonomy는 `CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`에 정리했다. Balatro식 Tarot/Planet/Spectral/Voucher는 confirm modifier, tile enhancement, rank progression, high-risk mutation, run-long passive 후보로 분리한다.

Animation polish backlog:

- Already applied:
  - cash-out sheet reward lines use short staggered opacity steps.
  - Jester scoring feedback uses burst/fade style animation.
- Apply to current progressed surfaces:
  - settlement item bonus rows should keep the same stagger rhythm as base reward rows.
  - total gold row should get a subtle emphasis when all reward rows have appeared.
  - Market route entry/resume should use a short fade/slide that does not delay purchases or reroll.
  - Next Station / Blind Select transition has a first-pass affordance; future work should extend the same rhythm to Settlement -> Market if needed.
  - item/Jester effect activation should prefer small toast/badge/count feedback over large blocking animation.
- Acceptance:
  - animation duration generally stays in the 120~260ms range.
  - no text overlap, no delayed input for repeated actions, and no layout shift after animation completes.
  - iOS smoke screenshot or developer eye-check is required for route/sheet/modal animation changes.

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

현재 코드 반영 메모:

- `TitleView`는 이미 `Continue / New Run / Trial / Archive / Settings` 섹션을 가진 Home 1차 구조로 재구성됐다.
- `Continue`는 active run summary 중 현재 위치만 짧게 보여 주고, 체크포인트 상세는 일반 Home에서 제거했다.
- `New Run`은 전용 route로 분리됐고, 현재 가능한 `Random / Input Seed` entry만 제품 화면에 노출한다. future setup/덱 placeholder는 일반 화면에서 제거했다. 후속 starting deck 선택은 `STARTING_DECK_ARCHETYPE_PLAN.md` 기준으로 simulator/log 경계가 잡힌 뒤 검토한다.
- `새 게임 시작`은 이제 `난이도 선택 -> 블라인드 선택 -> 전투 시작`의 2단계 진입 구조로 이동하기 시작했다.
- `블라인드 선택`은 별도 route로 분리됐고, 현재는 `스몰/빅/보스` 조건 card 3개를 한 화면에서 비교하게 보여 준다. 시작 액션은 card 전체 tap이 아니라 명시적인 play button에만 연결한다.
- `Trial`/`Archive`는 현재 dedicated placeholder route 수준까지 분리됐다.
- `Archive`는 이제 `기록 / 수집 / 통계` 3블록을 가진 첫 shell 화면으로 올라왔다.
- 다음 구현 전에는 `06_UI_UX_FLOW.md`에 있는 ASCII stencil을 먼저 source of truth로 본다.

현재 구현 가드레일:

- 유저에게 내부 구조명 `Trial`, `Archive`, `New Run`, `Home`를 직접 보여주지 않는다.
- 개발/검증용 entry는 `디버그` 섹션으로만 모은다.
- 화면 작업 전에는 stencil을 먼저 고정하고, 그다음에 코드 레이아웃을 맞춘다.
- `덱 선택`처럼 아직 실제 기능이 아닌 future setup 축은 일반 시작 화면에 placeholder로 노출하지 않는다.
- 블라인드 card 설명은 말줄임표가 나오지 않게 짧은 문구 또는 2줄 표시를 사용한다.
- `빅/보스 블라인드`, `이어하기 -> 블라인드 선택`, `Market -> 블라인드 선택`은 1차 연결됐고, 남은 판단은 pacing/transition polish로 본다.

세부 작업 단위:

1. `B1-1` Home 진입 섹션 구조 정리
   - `이어하기 / 새 시작 / 다른 메뉴 / 디버그 / 설정`
2. `B1-2` Continue summary/read model 정리
   - save facade 기반 summary 재사용
3. `B1-3` New Run route 분리
   - Title는 entry만 들고, 시작 방식 상세는 별도 route로 이동
4. `B1-4` placeholder route 분리
   - `특별 모드`, `기록실`
5. `B1-5` placeholder shell을 stencil 기준으로 정리
   - 안내 카드, bullet block, back flow
6. `B1-6` first real shell 결정
   - `기록실` 또는 `특별 모드` 중 무엇을 먼저 실제 block으로 올릴지 결정
7. `B1-7` Archive first shell 고정
   - `기록 / 수집 / 통계` 3블록을 가진 전용 route로 전환

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
`docs/specs/V4/*`
`docs/planning/*`

Files to change:
`docs/planning/IMPLEMENTATION_PLAN.md`

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
11. Balance automation ML 본 구현

[DO-NOT-DO] [DOC VERIFIED]

위 항목은 초기 PR에 섞지 않는다. 특히 전투 규칙 보호 PR과 메타 구조 확장 PR을 절대 결합하지 않는다.
