# START_HERE

이 문서는 새 세션에서 가장 먼저 읽는 **진입 문서**다.

목적은 하나다.

- 지금 프로젝트가 어디까지 왔는지 빠르게 파악
- 무엇을 먼저 읽어야 하는지 안내
- 어떤 원칙으로 다음 작업을 이어야 하는지 고정

긴 설명은 여기 두지 않는다. 세부 내용은 연결된 문서에서 확인한다.

## 새 세션 시작 지시문

아래 문장 그대로 시작해도 된다.

```text
작업 시작 전에 START_HERE.md, docs/V4/V4_REVIEW_CHECKLIST.md, docs/V4/V4_IMPLEMENTATION_PLAN.md 를 먼저 읽고,
현재 완료된 단계와 다음 단계부터 이어서 진행해라.
문서는 최소 수정 원칙을 유지하고, 코드/테스트 중심으로 작업해라.
```

## 먼저 읽을 문서

읽는 순서는 아래로 고정한다.

1. [START_HERE.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/START_HERE.md)
2. [V4_REVIEW_CHECKLIST.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_REVIEW_CHECKLIST.md)
3. [V4_IMPLEMENTATION_PLAN.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_IMPLEMENTATION_PLAN.md)
4. [V4_PLAN_RISK_REGISTER.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_PLAN_RISK_REGISTER.md)
5. [V4_PLAN_TRACEABILITY_MATRIX.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_PLAN_TRACEABILITY_MATRIX.md)

필요할 때만 추가로 본다.

- [RUMMI_POKER_GRID_V4_COMBINED.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/RUMMI_POKER_GRID_V4_COMBINED.md)
- [CURRENT_SYSTEM_OVERVIEW.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_SYSTEM_OVERVIEW.md)
- [CURRENT_CODE_MAP.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_CODE_MAP.md)
- [CURRENT_TO_V4_GAP.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_TO_V4_GAP.md)

## 현재 작업 원칙

- 현재 프로토타입은 확장 대상이 아니라 **V4 이행의 기준선**이다.
- 현재 코어 루프는 보호하고, 변경은 **V4 구조로 가는 다리**여야 한다.
- 문서는 과하게 늘리지 않는다.
- 새 문서는 꼭 필요할 때만 만들고, 가능하면 기존 문서에 통합한다.
- 작업은 문서보다 **코드와 테스트 중심**으로 진행한다.
- debug 편의 기능은 당장 자주 쓰면 유지할 수 있지만, 일반 런과 의미가 섞이면 분리한다.

## 현재 우선 방향

현재 우선순위는 `일반 런 기능 추가`가 아니라 `V4 목표 구조로의 실제 이행`이다.

즉, 다음 작업 판단 기준은 이것이다.

- 이 변경이 V4 이행을 직접 쉽게 만드는가
- 현재 코어를 깨지 않고 adapter/read model/ruleset/save facade 같은 구조 경계를 늘리는가
- current runtime을 유지한 채 target 구조를 얹을 수 있게 만드는가

## 현재까지 완료된 큰 단계

상세 진행률은 [V4_REVIEW_CHECKLIST.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_REVIEW_CHECKLIST.md)를 본다.

현재 큰 줄기는 여기까지 완료됐다.

- plan lock
- regression protection
- compatibility wrapper skeleton
- ruleset skeleton
- UI terminology bridge
- market adapter preparation
- save adapter preparation

또한 최근에는 아래가 실제 코드에 반영됐다.

- debug fixture 런과 active run 의미 분리
- market facade를 shop UI read path에 실제 연결
- `GameView -> GameShopScreen` 경계에서 market read model 전달 구조 정리
- `cash-out -> market -> next station` 시퀀스를 notifier command로 정리
- battle 화면 read path를 `RummiBattleRuntimeFacade` 기준으로 묶어서 HUD/board/hand가 raw runtime 전체를 직접 받지 않게 정리
- battle 화면의 board tap / selected discard / overlay sell도 notifier 내부 state 기준 command로 옮겨서 `GameView`가 선택 상태를 직접 해석하는 범위를 더 줄임
- active run 저장도 notifier가 만드는 runtime snapshot과 `ActiveRunSaveService.saveRuntimeState()` 기준으로 정리해서 `GameView`의 저장 조립 책임을 줄임
- active run save에 `rulesetId` 저장/복원 경로 반영
- 저장소를 `shared_preferences + device key store` 기준으로 정리하고 web/wasm 빌드 통과
- shop 리롤 mutation을 `GameSessionNotifier.rerollShopFromState()`로 감싸서 UI가 catalog/rng를 직접 알지 않게 정리

## 다음 작업 기본 방향

현재 A 단계 잔여 `current-only` 결합은 한 번 더 점검했다.

- shop/battle/save의 큰 read/write 경계는 이미 facade/notifier 쪽으로 1차 이동 완료
- 남아 있는 것은 주로 `GameView` 내부 UI state 조립과 settlement 표시용 값들
- 즉, A 단계의 큰 migration 작업을 더 미는 것보다 이제 B 구조 설계를 시작하는 쪽이 맞다

다음 작업 우선순위는 아래처럼 고정한다.

1. `B7. Next Station Loop` 설계를 먼저 시작한다.
2. 필요하면 그 설계에 맞춰 battle/settlement/market 사이 UI 책임만 소규모로 다시 나눈다.
3. 그 다음 `B1. Home Layer` 설계를 이어서 정리한다.

현재 바로 이어서 볼 범위는 아래다.

- `B7` 핵심:
  - `Settlement -> Market -> Next Station`을 화면/상태/저장 기준으로 다시 나눈다.
  - current loop에서 유지할 것과 target loop에서 추가할 것을 분리한다.
  - `GameView` 단일 route 유지 여부와 future station map 진입 지점을 정한다.
- `B1` 준비:
  - `Continue / New Run / Trial / Archive` 진입 구조를 title 기준으로 다시 정리한다.
  - 손상 세이브, 이어하기, 삭제 동선을 Home 기준으로 재배치할 틀을 만든다.

즉, 다음 세션에서는 아래 문서와 파일부터 바로 본다.

- 설계 문서:
  - `docs/V4/V4_REVIEW_CHECKLIST.md`
  - `docs/V4/V4_IMPLEMENTATION_PLAN.md`
  - `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md`
- 코드 경계:
  - `lib/views/game_view.dart`
  - `lib/views/game/widgets/game_cashout_widgets.dart`
  - `lib/views/game/widgets/game_shop_screen.dart`
  - `lib/views/title_view.dart`

## 하지 말아야 할 것

아래는 기본적으로 하지 않는다.

- One Pair 점수 변경
- save schema 즉시 교체
- Jester id 변경
- 대규모 symbol rename
- DB 엔진 도입
- 현재 프로토타입 편의 기능을 이유 없이 대규모 정리
- 문서만 늘어나는 작업

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

이 스크립트는 아래를 재사용 가능하게 묶는다.

- iPhone simulator 기준 `flutter run`
- 지정 route 진입
- 실행 후 스크린샷 저장
- URL 전환을 통한 background-save 확인
- 앱 relaunch 후 스크린샷 저장
- 실행 로그 보관

실행 산출물은 기본적으로 `/tmp/rummipoker_ios_smoke/<timestamp>/` 아래에 남긴다.

의미 있는 앱 실구동 검증을 했으면, 체크리스트 갱신 시 아래도 함께 남긴다.

- 어떤 route/시나리오를 검증했는지
- 스크린샷과 로그 산출물 위치

## 참고

기존 archive 문서는 레거시 참고 자료다.

- 현재 기준 source of truth는 `docs/V4/*`와 `docs/current_system/*`, 그리고 실제 `lib/` 코드다.
- archive 문서는 충돌 시 우선순위가 낮다.
