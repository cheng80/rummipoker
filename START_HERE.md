# START_HERE

이 문서는 새 세션에서 가장 먼저 읽는 **진입 문서**다.

목적은 세 가지다.

- 지금 프로젝트가 어디까지 왔는지 빠르게 파악한다.
- 무엇을 먼저 읽어야 하는지 안내한다.
- 다음 작업 판단 원칙을 고정한다.

상세 진행률과 긴 변경 내역은 여기 두지 않는다.
상세 상태는 [V4_REVIEW_CHECKLIST.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_REVIEW_CHECKLIST.md)를 source of truth로 본다.

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
6. [BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md)

필요할 때만 추가로 본다.

- [RUMMI_POKER_GRID_V4_COMBINED.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/RUMMI_POKER_GRID_V4_COMBINED.md)
- [CURRENT_SYSTEM_OVERVIEW.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_SYSTEM_OVERVIEW.md)
- [CURRENT_CODE_MAP.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_CODE_MAP.md)
- [CURRENT_TO_V4_GAP.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/current_system/CURRENT_TO_V4_GAP.md)

## 현재 상태 요약

- A. Migration Checklist는 거의 완료 상태다.
- current prototype의 핵심 루프와 save/restart는 회귀 테스트와 smoke 절차로 보호되고 있다.
- facade/read model/ruleset/save adapter 기반은 실제 코드 경로에 1차 연결됐다.
- Home / New Run / Blind Select / Market / Battle UI는 V4 구조 쪽으로 이동 중이다.
- B. Target Product는 부분 구현 상태이며, Item은 실제 v1 데이터 카탈로그, ko localization key 참조, `ItemDefinition` loader, market item offer read model, `OwnedItemEntry` / quick slot / passive rack 저장 shape, Market Item Shop read path, Item 구매 command, owned item inventory 반영, battle item zone read path, quick slot consumable의 discard 자원 effect runtime까지 준비됐다. 전투 item은 슬롯 탭 즉시 사용하지 않고 정보 overlay의 `사용` 버튼으로 확정한다. 더 많은 item effect op 연결은 아직 남아 있다. Station Map, Run Result, Sector Boss / Final Station, Archive 실제 데이터 연결도 큰 미완성 축이다.

현재 진행률 감각:

- migration readiness: 약 `90-95%`
- current playable prototype: 약 `70%`
- V4 target product 전체: 약 `58-63%`

## 현재 작업 원칙

- 현재 프로토타입은 확장 대상이 아니라 **V4 이행의 기준선**이다.
- 현재 코어 루프는 보호하고, 변경은 **V4 구조로 가는 다리**여야 한다.
- 문서는 과하게 늘리지 않는다.
- 새 문서는 꼭 필요할 때만 만들고, 가능하면 기존 문서에 통합한다.
- 작업은 문서보다 **코드와 테스트 중심**으로 진행한다.
- debug 편의 기능은 자주 쓰면 유지할 수 있지만, 일반 런과 의미가 섞이면 분리한다.

## 현재 우선 방향

현재 우선순위는 `일반 런 기능 추가`가 아니라 `V4 목표 구조로의 실제 이행`이다.

다음 작업 판단 기준:

- 이 변경이 V4 이행을 직접 쉽게 만드는가
- 현재 코어를 깨지 않고 adapter/read model/ruleset/save facade 같은 구조 경계를 늘리는가
- current runtime을 유지한 채 target 구조를 얹을 수 있게 만드는가
- item/Jester effect 적용처럼 애니메이션/후속 콜백이 붙을 작업은 전담 runtime/result/event 경계를 먼저 두는가

## 다음 작업 기본 방향

현재 A 단계의 큰 read/write 경계는 1차 정리됐다.

- shop/battle/save read path는 facade/notifier 쪽으로 이동했다.
- `새 게임 시작 -> 블라인드 선택 -> 전투 시작`은 연결됐다.
- `settlement -> market -> next blind select`는 debug/runtime 기준 1차 루프가 연결됐고, target loop/save 복원은 아직 남아 있다.
- battle/market UI는 카드 슬롯 체급과 선택 외곽선 기준을 고정하는 중이다.

다음 우선순위:

1. Item system runtime 계속
   다음은 item effect runtime을 small op 단위로 넓힌다. 우선 `draw_if_hand_empty` 같은 조건부 quick slot op를 별도 command/test로 연결한다.
2. 보드 이동 / 손패 한도 / Item-Jester runtime 통합 작업
   `보드 이동`을 `보드 버림`/`손패 버림`과 같은 전투 자원으로 추가하고, 이동/손패 한도 관련 Item/Jester 및 기존 item 미구현 effect를 [BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md) 순서로 진행한다.
3. market/battle interaction polish
   아이템 상점/전투 슬롯 기준 유지, 상세 패널, dialog/button visual consistency 보정
4. blind/station pacing polish
   target score scale, station별 체감 난도, blind unlock 템포 보정
5. deferred run rule 정리
   blind skip 같은 미룬 규칙을 문서 기준으로 다시 고정
6. target product 기능 착수
   Station Map, Archive data, Run Result 중 첫 범위 결정

## 바로 볼 코드 범위

- `lib/views/blind_select_view.dart`
- `lib/services/blind_selection_setup.dart`
- `lib/services/active_run_save_service.dart`
- `lib/router.dart`
- `lib/views/game_view.dart`
- `lib/views/title_view.dart`
- `lib/views/game/widgets/game_shop_screen.dart`
- `lib/views/game/widgets/game_jester_widgets.dart`
- `data/common/items_common_v1.json`
- `docs/V4/rummi_poker_grid_design_docs_v4/13_ITEM_SYSTEM_CONTRACT.md`
- `docs/V4/ITEM_EFFECT_RUNTIME_MATRIX.md`
- `docs/V4/BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md`

## 하지 말아야 할 것

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

web 저장/라우팅/입력 경계가 바뀌면 아래 스크립트를 먼저 확인한다.

- `tools/web_build_smoke.sh`

의미 있는 앱 실구동 검증을 했으면 [V4_REVIEW_CHECKLIST.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/V4/V4_REVIEW_CHECKLIST.md)에 route/시나리오와 산출물 경로를 남긴다.

## 참고

기존 archive 문서는 레거시 참고 자료다.

- 현재 기준 source of truth는 `docs/V4/*`와 `docs/current_system/*`, 그리고 실제 `lib/` 코드다.
- archive 문서는 충돌 시 우선순위가 낮다.
