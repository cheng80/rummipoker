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

## 다음 작업 기본 방향

다음 작업은 아래 성격을 우선한다.

- facade/read model을 실제 UI나 orchestration에 연결
- current runtime의 직접 참조를 줄이고 V4 용어 계층으로 읽게 만들기
- `jester_meta.dart`, save, station, market 쪽 책임을 작게 분리할 준비를 진행

현재 맥락상 가장 자연스러운 다음 후보는 이런 부류다.

- Station facade를 HUD/read path에 실제 연결
- Market facade 소비 범위를 더 넓혀 direct runtime reads를 줄이기
- save/runtime/orchestration 경계의 current-only 결합을 더 낮추기

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

## 참고

기존 archive 문서는 레거시 참고 자료다.

- 현재 기준 source of truth는 `docs/V4/*`와 `docs/current_system/*`, 그리고 실제 `lib/` 코드다.
- archive 문서는 충돌 시 우선순위가 낮다.
