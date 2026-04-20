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
- `cash-out` 결과를 `RummiSettlementRuntimeFacade`로 읽게 해서 settlement summary 경계를 얇게 정리
- market 복귀 판단을 provider 상태에서 빼고 `GameView` 로컬 책임으로 내려서 상태 의미를 단순화
- `GameView`의 `settlement -> market -> next station` 중복 조립을 helper 기준으로 줄임
- `TitleView`를 `B1 Home` 1차 구조처럼 재구성해서 `Continue / New Run / Trial / Archive / Settings` 섹션을 드러냄
- active run summary 문구를 save facade 한 군데에서 재사용하도록 정리
- `새 게임 시작`은 이제 `난이도 선택 -> 블라인드 선택 -> 전투 시작`의 2단계 진입 구조로 이동하기 시작함
- `BlindSelectView`와 `blind_selection_setup.dart`를 추가해서 `스몰/빅/보스` 블라인드 card와 조건 preview를 실제 코드에 연결
- station별 blind 진행은 이제 `스몰 -> 빅 -> 보스 -> 다음 station의 스몰`로 실제 연결된다
- `스몰 클리어 = small card clear/disabled + big selectable`, `빅 클리어 = boss selectable`, `보스 클리어 = 다음 station blind select 복귀` 규칙이 코드에 반영됐다
- 선택한 `blind tier`가 실제 전투 시작값(target score / hand size / discard count)에 반영되도록 `GameSessionArgs`와 notifier 생성 경로 확장
- station target score는 `AppConfig.stationTargetScoreScale` 한 군데에서 일괄 미세 조정할 수 있게 정리했다
- 난이도 해금은 내부 `run unlock state` 저장 구조로 관리되며, 개발용 완료 경로로 iOS 스모크까지 확인함
- `confirm` 직후 stage clear와 expiry/game over가 동시에 겹치던 회귀는 provider/widget test로 재현 후 수정했다
- debug 전용 `현재 Blind 즉시 클리어`, `보스 클리어 후 다음 Blind Select` 액션을 battle debug bottom sheet에 모아 다음 station 루프 테스트 경로를 보강했다
- title / blind select / new run / market / cash-out / game over에서 Flutter 기본 text button 성격을 줄이고 게임용 커스텀 dialog/button 톤으로 정리했다
- web build + local server + Playwright 경로로 `이어하기` dialog / `블라인드 시작` dialog 버튼 렌더 스모크를 실제 캡처로 재검증했다
- battle 하단 action row는 `선택 해제 / 보드 버림 / 손패 버림 / 확정` 순서로 조정했다
- market 상단의 drag-sell 안내와 `Market 오퍼 / 리롤` 줄 사이 간격을 넓혀 오동작/오인식을 줄였다
- market 화면은 Balatro식 카드 선택 구조를 따라 scroll list 대신 `카드 선택 + 상세 패널 + 페이지/리롤` 구조로 재정리했다
- market 상단 `Jester Slots / Item Slots`는 분리된 슬롯 시스템으로 정리했고, 상점 카드는 이름 텍스트를 제거하고 `카드 + 가격`만 보여 주도록 축소했다
- market 설명 패널은 말풍선 꼬리를 제거하고 독립 정보 패널로 정리했으며, 긴 설명을 위해 최소 높이와 줄 수를 늘렸다
- market 카드 간격은 카드 수 기반으로 조정해 3장일 때는 item-slot 수준의 간격, 확장 시에는 jester-slot 수준의 간격으로 맞출 준비를 했다
- battle 화면의 제스터 선택 외곽선은 overlay 선택 상태와 실제 strip 렌더를 다시 연결해 상단 카드에 선택 강조가 보이도록 복구했다
- battle 상단 `JESTER 4/5` 헤더는 `4/5`만 남기도록 축약했고, 확보한 폭을 item zone 확장에 사용하기 시작했다
- battle item zone은 부가 설명을 제거하고 슬롯 3개만 남겨 제스터 카드와 비슷한 체급의 카드형 슬롯으로 키웠다
- battle 디버그 조작은 상단 HUD의 inline cluster 대신 `5x5 영역 우측의 작은 debug 버튼 -> modal bottom sheet` 구조로 이동했다
- debug bottom sheet 안에는 `MARKET`, `Hand size`, `현재 Blind 즉시 클리어`, `보스 클리어 후 다음 Blind Select`를 모았고, options dialog에서는 debug 액션을 제거했다

## 다음 작업 기본 방향

현재 A 단계 잔여 `current-only` 결합은 큰 줄기 기준으로 한 번 더 점검했다.

- shop/battle/save의 큰 read/write 경계는 이미 facade/notifier 쪽으로 1차 이동 완료
- `새 게임 시작 -> 블라인드 선택 -> 전투 시작`, `continue -> blind select 복귀`, `settlement -> market -> blind select` 1차 연결은 들어갔다
- 다음 우선순위는 blind/station pacing 보정, market interaction polish, dialog/button visual polish, skip 같은 미뤄 둔 run rule의 설계 고정 쪽이다
- battle 레이아웃은 `item zone 존재감 확대`와 `공용 상세 패널 유지` 방향으로 조정 중이며, 우측 세로 item column 배치는 상세창 충돌 때문에 보류했다

다음 작업 우선순위는 아래처럼 고정한다.

1. blind/station pacing polish
   target score scale, station별 체감 난도, blind unlock 템포 추가 보정
2. market/battle interaction polish
   버튼 배치, drag area, confirm safety, dialog/button visual consistency 보정
3. deferred run rule 정리
   blind skip 같은 미룬 규칙을 문서 기준으로 다시 고정

현재 바로 이어서 볼 범위는 아래다.

- blind/station:
  - station target scale 기본값과 station별 체감 난도를 다시 점검
  - small/big/boss 보상/압박 수치가 장기 밸런스 기준에 맞는지 재조정
- market/battle:
  - 하단 action row 오동작 방지 배치와 market 상단 조작 간격을 계속 다듬기
  - game dialog/button 컴포넌트를 나머지 화면까지 일관되게 적용할지 판단
- 검증:
  - web 저장/라우팅/interaction이 바뀌는 PR은 `web build + local server + Playwright` 캡처 경로까지 같이 본다

즉, 다음 세션에서는 아래 문서와 파일부터 바로 본다.

- 설계 문서:
  - `docs/V4/V4_REVIEW_CHECKLIST.md`
  - `docs/V4/V4_IMPLEMENTATION_PLAN.md`
  - `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md`
- 코드 경계:
  - `lib/views/blind_select_view.dart`
  - `lib/services/blind_selection_setup.dart`
  - `lib/services/active_run_save_service.dart`
  - `lib/router.dart`
  - `lib/views/game_view.dart`
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
