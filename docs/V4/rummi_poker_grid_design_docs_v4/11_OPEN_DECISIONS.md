# 11. Open Decisions & Experiments

> 문서 성격: decision log
> 코드 반영 상태: mixed
> 핵심 정책: 결정되지 않은 항목을 current처럼 쓰지 않는다.

## 1. 확정 결정

[V4_DECISION]

| 결정 | 상태 | 이유 |
|---|---|---|
| 현재 전투 코어 유지 | 확정 | 이미 playable loop가 작동함 |
| One Pair 0점 dead line 유지 | 확정 | dead line 압박과 현재 밸런스 보호 |
| contributor만 제거 | 확정 | V4 전투 정체성 |
| overlap 유지 | 확정 | 핵심 전략성 |
| active run save v2 보호 | 확정 | continue/restart 회귀 방지 |
| Station은 target 용어 | 확정 | 현재 stage loop와 장기 구조 연결 |
| 코드 심볼 rename 보류 | 확정 | save/provider/test 영향 큼 |

## 2. 아직 열려 있는 결정

### 2.1 Board Full Expiry

[WATCH]

현재:

```text
boardDiscard <= 0 && boardFull이면 boardFullAfterDcExhausted
```

검토 target:

```text
boardDiscard <= 0 && boardFull && scoringCandidateLines.isEmpty이면 expiry
```

질문:

- 보드가 꽉 찼지만 scoring line이 있으면 확정을 먼저 허용할 것인가?
- 현재 UI에서 game over dialog가 confirm 기회를 빼앗는가?
- 전략적으로 board full은 즉시 실패가 더 재미있는가, 아니면 scoring 기회가 남아야 하는가?

권장:

- 실험 flag로 검증한다.
- 현재 behavior를 즉시 바꾸지 않는다.

### 2.2 One Pair Scoring

[EXPERIMENT]

후보:

```text
One Pair = 10점
```

위험:

- 초반 난이도 급락
- dead line 개념 약화
- Pair 조건 Jester 폭발 가능성
- overlap pair loop 가능성
- target score curve 재조정 필요

결정:

- 기본 V4 ruleset에는 넣지 않는다.
- 실험 ruleset에서만 검증한다.

### 2.3 Station Count

[TARGET]

V3의 30 Station은 후보일 뿐이다.

열린 질문:

- 모바일 1 run 목표 시간이 몇 분인가?
- Station당 평균 전투 시간이 몇 분인가?
- Market 빈도는 얼마가 적절한가?
- Sector당 boss/finale가 필요한가?

결정:

- V4에서는 구조만 정의하고 숫자는 고정하지 않는다.

### 2.4 Economy Curve

[WATCH]

현재:

- startingGold 10
- stageClearGoldBase 10
- reroll 5
- stage target `300 * 1.6^(n-1)`

열린 질문:

- Station 구조에서 보상이 너무 빠르게 누적되는가?
- Jester 가격과 reward 비율이 맞는가?
- Risk Grade별 gold multiplier가 필요한가?

결정:

- 현재 값은 baseline으로 보존한다.
- target economy pass는 Station prototype 후 진행한다.

### 2.4.1 Jester / Item Economy Split

[WATCH]

열린 질문:

- Item 하위 타입을 consumable / equipment / passive_relic / utility로 고정할 것인가?
- Jester와 Item을 같은 market list에 섞되 section만 나눌 것인가, 아예 다른 panel로 둘 것인가?
- GameView에서 item은 quick-use slot인가, inventory panel인가?
- save에서 ownedItems와 equippedItems를 어떻게 나눌 것인가?

현재 결정:

- Jester와 Item은 같은 부류로 다루지 않는다.
- market 진열 레벨에서만 공통 wrapper를 둘 수 있다.
- domain / save / runtime / UI는 분리한다.
- economy 본격 조정은 이 분리 기준과 UI 시안이 먼저 고정된 뒤 진행한다.

### 2.5 Jester Instance Identity

[WATCH]

현재 stateful 값은 slot index 기반이다.

장점:

- 단순함
- 현재 save와 잘 맞음

위험:

- Jester 이동/정렬/강화/edition 추가 시 slot 기반만으로 부족

Target:

- `ownedJesterInstanceId` 추가 후보
- 기존 `ownedJesterIds`와 adapter 필요

### 2.6 Balatro-style Blind Skip

[WATCH]

Balatro의 `Small / Big Blind Skip -> Tag 보상 -> 다음 Blind 직행` 구조를
현재 station/blind select 흐름에 언제 도입할지 아직 정하지 않았다.

열린 질문:

- skip이 `Blind Select` 이전 선택인가, `Market 이후` 선택인가?
- skip 보상은 Tag 그대로 가져오는가, 현재 economy/read model에 맞게 adapter로 바꾸는가?
- skip 시 shop/checkpoint/save scene이 어떻게 바뀌는가?
- boss blind / station reset / continue 복원과 충돌 없이 저장 가능한가?

현재 결정:

- 이번 단계에서는 구현하지 않는다.
- 우선순위는 `small -> big -> boss -> next station small reset`과
  station별 blind scaling, save/continue 복원 안정화가 더 높다.
- blind progression/save scene이 안정화된 뒤 별도 작업으로 검토한다.

결정:

- 지금은 slot index 유지.
- content upgrade/edition 도입 전 instance id 설계.

### 2.6 Persistence Engine

[TARGET]

후보:

- current GetStorage + HMAC 유지
- Drift
- SQLite
- IndexedDB
- hybrid: active run snapshot + archive DB

결정:

- 엔진은 지금 확정하지 않는다.
- active run은 current 구조 유지.
- archive/stats부터 별도 저장소 도입 가능.

### 2.7 Flame Role

[WATCH]

현재 핵심 화면은 Flutter-first이고 Flame은 보조 연출 후보에 가깝다.

질문:

- 타일/보드 렌더를 Flame으로 옮길 필요가 있는가?
- 현재 Flutter 위젯 성능이 충분한가?
- 이펙트만 Flame/Canvas로 두는 게 맞는가?

결정:

- V4에서 Flame 전환을 기본 목표로 두지 않는다.
- UI polish와 effect 최적화 후 재검토.

## 3. Experiment Registry

[EXPERIMENT]

| 실험 | Default | 필요 테스트 |
|---|---|---|
| Pair scoring | off | combat balance, target score, Jester pair condition |
| Board full confirm grace | off | expiry UX, game over timing |
| Station terminology UI | off 또는 gradual | copy consistency, save unaffected |
| Market adapter | off 또는 compatibility | shop flow, buy/sell/reroll |
| Risk Grade | off | economy curve, reward multiplier |
| Station modifiers | off | ruleset isolation |

## 4. Known Code Notes

[WATCH]

- `HandEvaluation.isDeadLine` 주석은 “하이카드만”처럼 보이지만 실제 `isDeadLineRank`는 High Card와 One Pair를 dead line으로 처리한다. 주석 정리가 필요하다.
- `confirmAllFullLines` 이름은 현재 동작과 맞지 않는다. 실제로는 scoring candidate line 즉시 확정이다.
- `gddCanClearLine`은 현재 모든 rank에 true를 반환하지만 확정 후보 필터에는 `isDeadLine`이 쓰인다. 사용 의미 정리가 필요하다.
- `RummiBlindState.discardsRemaining`은 board discard alias다. hand discard와 혼동하지 않도록 문서화가 필요하다.
