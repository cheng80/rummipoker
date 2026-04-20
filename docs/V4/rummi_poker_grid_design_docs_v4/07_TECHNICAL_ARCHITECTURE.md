# 07. Technical Architecture

> 문서 성격: current code map + target architecture
> 코드 반영 상태: current implemented, target refactor planned
> 핵심 정책: 현재 프로토타입을 보호하기 위해 한 PR에서 한 축만 바꾼다.

## 1. Current Layers

[CURRENT]

현재 코드는 다음 계층으로 읽는다.

```text
lib/logic/rummi_poker_grid/
  순수 전투 로직에 가까운 계층

lib/logic/rummi_poker_grid/jester_meta.dart
  Jester + economy + run progress 복합 계층

lib/providers/features/rummi_poker_grid/
  Riverpod orchestration 계층

lib/views/
  UI orchestration + navigation + save trigger 계층

lib/services/
  persistence / debug fixture / platform service 계층
```

## 2. Current Core Boundaries

[CURRENT]

| 파일 | 현재 책임 |
|---|---|
| `tile.dart` | 타일 값 객체 |
| `poker_deck.dart` | 덱 생성, 셔플, 스냅샷 |
| `board.dart` | 5x5 cell storage |
| `hand_rank.dart` | rank enum, score, dead line |
| `hand_evaluator.dart` | 라인 평가, contributor index |
| `rummi_poker_grid_engine.dart` | 12줄 평가 |
| `rummi_poker_grid_session.dart` | 전투 session 퍼사드 |
| `rummi_blind_state.dart` | 현재 전투 목표와 discard 자원 |
| `jester_meta.dart` | Jester/economy/run/shop |
| `active_run_save_service.dart` | active run save/load |
| `game_session_notifier.dart` | 전투 flow orchestration |
| `game_view.dart` | 전투 UI, 정산 시퀀스, 저장 호출 |

## 3. Current State Management

[CURRENT]

`GameSessionState`는 mutable `session`, mutable `runProgress`를 보관하고 `revision` 증가로 redraw를 유도한다.

장점:

- 프로토타입 속도가 빠르다.
- 기존 session 객체를 그대로 조작할 수 있다.
- save snapshot을 만들기 쉽다.

주의:

- pure immutable state는 아니다.
- state mutation 후 `revision` 누락 시 UI 갱신이 빠질 수 있다.
- 장기적으로 action/reducer 형태로 나눌 수 있다.

## 4. Target Domain Split

[TARGET]

V4 장기 구조는 다음처럼 분리한다.

```text
core/combat
- Tile
- Board
- Deck
- HandEvaluator
- LineEvaluator
- CombatSession
- ConfirmTransaction

core/ruleset
- RummiRulesetConfig
- ScoreTable
- ExpiryPolicy
- OverlapPolicy

core/run
- RunProgress
- StationProgress
- Checkpoint
- RewardSettlement

core/content
- ContentDefinition
- JesterDefinition
- ItemDefinition
- MarketOffer
- ItemOffer
- OwnedItemEntry
- EffectDefinition

core/effects
- JesterEffectEngine
- ModifierEngine
- StationModifierEngine

services/persistence
- ActiveRunSaveService
- SaveAdapter
- ArchiveRepository

providers
- GameSessionNotifier
- TitleNotifier
- SettingsNotifier

views
- Title
- Battle
- Market
- StationMap
- Archive
```

[V4_DECISION]

Jester / Item 분리 구현 시 최소 새 경계는 아래처럼 잡는다.

```text
core/content
- jester_definition.dart
- item_definition.dart
- market_offer.dart

core/run
- run_inventory_state.dart

services/market
- market_offer_adapter.dart
```

상세 필드 계약은 `13_ITEM_SYSTEM_CONTRACT.md`를 따른다.

[MIGRATION]

이 구조는 한 번에 만들지 않는다. 먼저 adapter와 테스트를 추가한 뒤 파일 분리를 진행한다.

## 5. Ruleset Config Target

[TARGET]

V4에서 실험 규칙은 config로 분리한다.

```dart
class RummiRulesetConfig {
  final bool enablePairScoring;
  final bool enableStationTerminology;
  final bool enableEntryPressureLock;
  final bool enableRunKit;
  final bool enableArchive;
  final double overlapAlpha;
  final double overlapCap;
}
```

기본값:

```dart
const currentPrototypeRuleset = RummiRulesetConfig(
  enablePairScoring: false,
  enableStationTerminology: false,
  enableEntryPressureLock: false,
  enableRunKit: false,
  enableArchive: false,
  overlapAlpha: 0.3,
  overlapCap: 2.0,
);
```

[V4_DECISION]

ruleset config 도입 전까지 현재 코드 상수를 기본값으로 유지한다.

## 6. Confirm Transaction Refactor

[MIGRATION]

현재 `confirmAllFullLines`를 다음 구조로 점진 분리한다.

```text
ConfirmScoringLinesUseCase
- scan lines
- evaluate candidates
- compute overlap
- apply scoring effects
- produce removal set
- produce settlement result
```

권장 API:

```dart
ConfirmClearResult confirmScoringLines(...);

@Deprecated('Use confirmScoringLines. Kept for prototype compatibility.')
ConfirmClearResult confirmAllFullLines(...) => confirmScoringLines(...);
```

단, 현재 Provider와 UI가 의존하므로 한 PR에서 이름 변경과 로직 변경을 동시에 하지 않는다.

## 7. Jester Meta Refactor

[MIGRATION]

현재 `jester_meta.dart`는 크지만 작동한다. 분리 순서:

1. 테스트 보강
2. `RummiEconomyConfig` 분리
3. `RummiRunProgress` 분리
4. `RummiJesterCard` / `Catalog` 분리
5. `JesterEffectEngine` 분리
6. `MarketOffer` adapter 추가
7. 기존 import compatibility 유지

## 8. Persistence Refactor

[MIGRATION]

저장은 다음 원칙으로만 수정한다.

- schema 변경은 별도 PR
- HMAC verification 유지
- old save invalid 처리 유지
- save/load golden test 필수
- stageStartSnapshot equivalent 유지
- activeScene restore 유지

## 9. Naming Refactor Policy

[V4_DECISION]

코드명 rename은 마지막 단계다.

지금 유지:

- `RummiBlindState`
- `scoreTowardBlind`
- `confirmAllFullLines`
- `stageIndex`

나중에 검토:

- `StationState`
- `scoreTowardStation`
- `confirmScoringLines`
- `stationIndex`

[MIGRATION]

이름 변경은 save schema, provider, tests가 준비된 뒤 compatibility adapter와 함께 수행한다.

## 10. PR Safety Rule

[V4_DECISION]

한 PR에서 동시에 하지 말 것:

- 전투 룰 변경 + 저장 schema 변경
- 코드 rename + 경제 밸런스 변경
- DB 도입 + active run save 제거
- Jester refactor + catalog id 변경
- UI terminology 변경 + provider state 구조 변경

권장 단위:

1. docs only
2. tests only
3. pure logic only
4. provider orchestration only
5. UI copy only
6. persistence adapter only
