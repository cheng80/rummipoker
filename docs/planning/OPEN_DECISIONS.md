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

- Jester와 Item을 같은 market list에 섞되 section만 나눌 것인가, 아예 다른 panel로 둘 것인가?
- GameView에서 item은 quick-use slot인가, inventory panel인가?
- save에서 ownedItems와 equippedItems를 어떻게 나눌 것인가?

현재 결정:

- Jester와 Item은 같은 부류로 다루지 않는다.
- Item 하위 타입은 v1 기준 `consumable / equipment / passive_relic / utility`로 고정한다.
- 실제 v1 카탈로그는 `data/common/items_common_v1.json`을 기준으로 한다.
- market 진열 레벨에서만 공통 wrapper를 둘 수 있다.
- domain / save / runtime / UI는 분리한다.
- economy 본격 조정은 이 분리 기준과 UI 시안이 먼저 고정된 뒤 진행한다.

다음 구현 질문:

- `items_common_v1.json`을 어떤 repository/loader에서 읽을 것인가?
- `effect.op`를 즉시 전부 구현할 것인가, market 노출 가능 op부터 단계적으로 열 것인가?
- owned item 저장은 기존 active run save v2에 optional field로 확장할 것인가, 별도 adapter shadow state로 시작할 것인가?

추가 열린 질문:

- Balatro-style 상점 분류를 참고할 때 `Permit / Run Kit upgrade / Sigil`을 `Meta Shop`으로 묶을 것인가?
- `Glyph / Echo`를 `Pack`형 구매층으로 묶을 것인가, 독립 상점으로 둘 것인가?
- `Service`는 `Item Shop`에 흡수할 것인가, 독립 Utility Shop으로 둘 것인가?

### 2.4.2 Battle Item Zone Layout

[WATCH]

열린 질문:

- item zone을 battle 상단 가로 bar로 유지할 것인가?
- item slot을 제스터 카드급 체급으로 키울 때, `Q1 / Q2 / Passive` 라벨 외에 어떤 정보까지 남길 것인가?
- item detail은 전용 overlay를 둘 것인가, 현재 jester/detail 공용 패널을 계속 쓸 것인가?

현재 결정:

- battle item zone은 우선 `가로 슬롯 3개` 구조를 유지한다.
- item slot은 제스터 카드와 비슷한 체급으로 키우되, 부가 설명 문구는 제거하고 slot 정체성만 남긴다.
- detail은 battle 공용 정보 패널을 계속 사용한다.

보류 이유:

- `5x5` 보드 우측 세로 item column 안은 detail panel/overlay와 충돌 위험이 커서 현재 phone frame에서 안정적이지 않다.
- 먼저 `slot 체급`, `공용 detail`, `battle HUD 압축`을 고정한 뒤에 다시 검토한다.

### 2.4.3 Debug Entry Placement

[WATCH]

현재 결정:

- debug 조작은 일반 HUD/action 영역과 섞지 않는다.
- battle 화면에서는 `작은 debug button -> modal bottom sheet` 구조로 모은다.
- `MARKET`, `Hand size`, `현재 Blind 즉시 클리어`, `보스 클리어 후 다음 Blind Select`는 이 bottom sheet 안에서만 제공한다.

의도:

- 일반 플레이 의미와 debug 의미를 화면 수준에서 분리한다.
- options dialog는 런/설정/종료 중심으로 남기고, debug는 별도 surface로 격리한다.

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

결정:

- 지금은 slot index 유지.
- content upgrade/edition 도입 전 instance id 설계.

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

### 2.7 Persistence Engine

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

### 2.8 Flame Role

[WATCH]

현재 핵심 화면은 Flutter-first이고 Flame은 보조 연출 후보에 가깝다.

질문:

- 타일/보드 렌더를 Flame으로 옮길 필요가 있는가?
- 현재 Flutter 위젯 성능이 충분한가?
- 이펙트만 Flame/Canvas로 두는 게 맞는가?

결정:

- V4에서 Flame 전환을 기본 목표로 두지 않는다.
- UI polish와 effect 최적화 후 재검토.

### 2.9 Balance Automation / ML Pipeline

[FUTURE]

로컬 머신에서 자동 시뮬레이션을 돌려 JSONL 데이터를 쌓고,
PyTorch 모델로 station / blind / market / item 조합의 난이도 경향을 예측하는 방안이다.

현재 결정:

- 지금은 구현하지 않는다.
- Flutter UI 자동 클릭이 아니라 Dart game logic simulator + bot policy + JSONL 로그 구조를 후보로 둔다.
- 모델 결과는 자동 패치가 아니라 사람이 밸런스 수치를 조정할 때 참고하는 리포트로 쓴다.
- 상세 후보 설계는 `14_BALANCE_AUTOMATION_ML.md`를 기준으로 본다.

진행 가능 조건:

1. Station Preview/Map 최소 범위가 결정되어 `station_id`, blind tier, 선택지 구조가 로그 스키마에서 흔들리지 않는다.
   - 결정 완료: 현재 `BlindSelectView`를 `Station Preview v1`로 공식화하고, Station Map graph는 후속으로 둔다.
2. Market offer count와 rarity weighted roll 규칙이 결정되어 simulator가 실제 상점 분포를 재현할 수 있다.
   - 계획 완료: 기본 offer 수 3/3, v1 cap 5, 공통 rarity weight, `rarityWeightBonus` 적용 방향은 `MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`를 기준으로 본다.
3. target score curve, small/big/boss 보상/압박, discard reward의 baseline balance version이 정해진다.
   - 완료: 현재 런타임 수치를 `v4_pacing_baseline_1`로 기록했다. 상세는 `BLIND_STATION_PACING_BASELINE_PLAN.md`를 기준으로 본다.
4. Boss modifier taxonomy가 정해져 simulator가 보스 제약을 id/category/parameter로 남길 수 있다.
   - 완료: `BOSS_MODIFIER_TAXONOMY_PLAN.md`에서 tile color, hand rank, number/rank, Jester, score/resource, board/line 제약 범주를 정리했다.
5. Starting deck archetype 기준이 정해져 simulator가 시작 덱/타일 강화 축을 별도 feature로 남길 수 있다.
   - 완료: `STARTING_DECK_ARCHETYPE_PLAN.md`에서 현재 runtime은 Random/Seed만 유지하고, 후속 starting deck은 `run_archetype_id`, tile enhancement는 `tile_modifier_id`로 분리했다.
6. Jester taxonomy 기준이 정해져 simulator가 effect category, trigger stage, edition/penalty 후보를 별도 feature로 남길 수 있다.
   - 완료: `JESTER_REFERENCE_TAXONOMY_PLAN.md`에서 activation order, rank inheritance caution, edition/penalty, effect category 후보를 정리했다.
7. Consumable / voucher taxonomy 기준이 정해져 simulator가 Item 확장 축을 별도 feature로 남길 수 있다.
   - 완료: `CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`에서 consumable, rank progression, high-risk mutation, voucher/passive 후보를 분리했다.
8. Dart game logic simulator에서 UI 없이 battle/settlement/market/next station 한 바퀴를 deterministic seed로 실행할 수 있다.

따라서 후속 작업 순서는 `balance simulation readiness pass -> market rarity roll implementation pass`로 본다.

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
| Balance automation ML | off | simulator determinism, log schema, report accuracy |

### 3.1 Boss Modifier Direction

[FUTURE]

Boss blind는 단순히 목표 점수와 자원을 올리는 전투가 아니라, 전투 시작 전 공개되는 제약/변형 규칙을 갖는 방향으로 본다.

상세 taxonomy와 적용 순서는 `docs/planning/feature_plans/BOSS_MODIFIER_TAXONOMY_PLAN.md`를 기준으로 본다.

후보 범주:

- tile color 약화
- hand rank 약화 또는 특정 rank 보너스 감소
- tile number/rank 약화
- Jester slot/effect 제한
- score/chip 출력 압박
- board/hand discard 또는 hand size 압박
- board/line 제약

주의:

- Balatro의 face-down hand card류 규칙은 우리 게임에 그대로 옮기지 않는다.
- 이 게임은 손패가 한 번에 주어지는 구조가 아니라 draw 기반이므로, 숨김 정보는 계획성을 해칠 수 있다.
- 숨김/비활성 제약을 넣는다면 반드시 entering 전 preview와 affected tile/Jester 표시가 필요하다.
- Boss modifier는 `v4_pacing_baseline_1`의 target/resource baseline과 분리된 후속 pass로 다룬다.
- Boss modifier는 preview, battle UI, scoring feedback, save/restore, simulator log에 같은 id/category로 나타나야 한다.
- 제약 표시는 `CONSTRAINT_VISUAL_LANGUAGE_PLAN.md`를 따른다.
- 첫 Boss modifier 구현 전에 entry popup, compact marker, position-local penalty float 기준을 먼저 적용한다.
- user-facing 화면에는 내부 modifier 변수명을 노출하지 않고, 짧은 한글 설명만 사용한다.

현재 적용:

- Boss modifier v1은 `빨간 타일 약화`다.
- 보스 블라인드 진입 시 한글 팝업으로 규칙을 설명한다.
- 전투 중 red tile에는 작은 marker를 표시한다.
- 점수 정산 중 제약 적용 callout을 표시한다.
- 남은 open decision은 simulator log field와 추가 Boss modifier category다.

### 3.2 Ante / Stake Score Curve Reference

[FUTURE]

Balatro의 ante / stake별 요구 칩 표는 점수 곡선의 참고 자료로만 둔다.

현재 결정:

- Balatro 수치를 그대로 복사하지 않는다.
- Small / Big / Boss의 `1.0 / 1.5 / 2.0` 압박 구조는 현재 baseline과 유사하므로 reference shape로 유지한다.
- stake처럼 요구 점수 증가 속도를 올리는 구조는 우리 게임의 `difficulty_target_multiplier`, `station_growth_base`, `stationTargetScoreScale` 후보로 해석한다.
- stake식 누적 제약은 `BOSS_MODIFIER_TAXONOMY_PLAN.md`의 difficulty/stake reference를 기준으로 후속 balance version에서 검토한다.
- 실제 요구 점수 조정은 `balance simulation readiness pass` 이후 ML/simulator 로그를 기반으로 한다.
- target score 변경 시 `balance_version`을 갱신한다.

### 3.3 Starting Deck / Tile Enhancement Reference

[FUTURE]

Balatro의 시작 덱과 카드 강화 구조는 run archetype과 tile modifier 후보로만 참고한다.

현재 결정:

- 지금 New Run 화면에는 시작 덱 선택을 노출하지 않는다.
- 현재 기본 런은 `standard_tile_deck_v1`에 해당하는 단일 archetype으로 본다.
- 시작 덱은 후속 `run_archetype_id`로 표현한다.
- 카드 강화/인장/에디션류는 후속 `tile_modifier_id` 또는 Jester/Item edition 후보로 분리한다.
- 시작 덱 선택은 balance simulation readiness 이후, simulator가 archetype별 결과를 비교할 수 있을 때 검토한다.

상세 기준은 `docs/planning/feature_plans/STARTING_DECK_ARCHETYPE_PLAN.md`를 따른다.

### 3.4 Jester Reference Taxonomy

[FUTURE]

Balatro의 Joker 목록은 Jester catalog 확장과 ML feature 설계의 taxonomy reference로만 둔다.

현재 결정:

- 기존 Jester id는 변경하지 않는다.
- Jester는 slot order로 발동한다.
- hand-rank condition inheritance는 후속 데이터/테스트가 준비되기 전까지 암묵 적용하지 않는다.
- edition/penalty는 base Jester id가 아니라 owned Jester instance modifier로 본다.
- 새 effect category는 scoring feedback과 simulator log에 나타나기 전까지 Market에 노출하지 않는다.

상세 기준은 `docs/planning/feature_plans/JESTER_REFERENCE_TAXONOMY_PLAN.md`를 따른다.

### 3.5 Consumable / Voucher Reference Taxonomy

[FUTURE]

Balatro의 Tarot / Planet / Spectral / Voucher 구조는 Item 확장 taxonomy reference로만 둔다.

현재 결정:

- 현재 Item 49개 runtime은 유지한다.
- Tarot-like 효과는 confirm modifier, tile enhancement, tile conversion, economy, Jester mutation 후보로 나눈다.
- Planet-like 효과는 hand-rank progression 후보로 분리한다.
- Spectral-like 효과는 high-risk mutation 후보로 분리하고 일반 market pool에는 바로 넣지 않는다.
- Voucher-like 효과는 ordinary quick-use item이 아니라 run-long passive 또는 후속 `Run Voucher` content type으로 다룬다.

상세 기준은 `docs/planning/feature_plans/CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`를 따른다.

## 4. Known Code Notes

[WATCH]

- `HandEvaluation.isDeadLine` 주석은 “하이카드만”처럼 보이지만 실제 `isDeadLineRank`는 High Card와 One Pair를 dead line으로 처리한다. 주석 정리가 필요하다.
- `confirmAllFullLines` 이름은 현재 동작과 맞지 않는다. 실제로는 scoring candidate line 즉시 확정이다.
- `gddCanClearLine`은 현재 모든 rank에 true를 반환하지만 확정 후보 필터에는 `isDeadLine`이 쓰인다. 사용 의미 정리가 필요하다.
- `RummiBlindState.discardsRemaining`은 board discard alias다. hand discard와 혼동하지 않도록 문서화가 필요하다.
