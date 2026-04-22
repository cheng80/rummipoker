# 07. Technical Architecture

> 문서 성격: target architecture and refactor contract
> 코드 반영 상태: current implemented, target refactor planned
> 핵심 정책: 현재 프로토타입을 보호하기 위해 한 PR에서 한 축만 바꾼다.

현재 코드 파일별 책임과 read order는 `docs/current_system/CURRENT_CODE_MAP.md`를 기준으로 본다.
이 문서는 target 경계와 refactor 제한만 정의한다.

## 1. Current Boundary Reference

[CURRENT]

현재 구현에서 보호해야 할 경계만 요약한다.

- 전투 규칙은 `lib/logic/rummi_poker_grid/`에 집중되어 있다.
- Jester / economy / run progress / shop은 아직 일부 복합 계층이다.
- Riverpod provider는 전투 flow orchestration을 담당한다.
- view 계층은 UI orchestration, navigation, save trigger를 포함한다.
- services 계층은 persistence, debug fixture, platform service를 포함한다.

세부 파일 책임은 `CURRENT_CODE_MAP.md`를 중복하지 않는다.

## 2. Target Domain Split

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

이 구조는 목표 경계이며, 현재 디렉터리 구조를 즉시 바꾸라는 지시가 아니다.

## 3. Content / Market Minimum Boundary

[V4_DECISION]

Jester / Item 분리 구현 시 최소 새 경계는 아래처럼 잡는다.

```text
core/content
- jester_definition.dart
- item_definition.dart
- item_catalog.dart
- market_offer.dart

core/run
- run_inventory_state.dart

services/market
- market_offer_adapter.dart
```

상세 필드 계약은 `13_ITEM_SYSTEM_CONTRACT.md`를 따른다.
v1 데이터 소스는 `data/common/items_common_v1.json`이며, asset path는 `AssetPaths.itemsCommon`을 사용한다.

## 4. Ruleset Config Target

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

기본값은 current prototype과 parity를 유지한다.

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

ruleset config 도입 전까지 현재 코드 상수를 기본값으로 유지한다.

## 5. Confirm Transaction Refactor

[MIGRATION]

`confirmAllFullLines`는 legacy name이므로 다음 구조로 점진 분리한다.

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

Provider와 UI가 의존하므로 한 PR에서 이름 변경과 로직 변경을 동시에 하지 않는다.

## 6. Jester Meta Refactor

[MIGRATION]

복합 Jester/economy/run/shop 계층은 아래 순서로만 분리한다.

1. 테스트 보강
2. `RummiEconomyConfig` 분리
3. `RummiRunProgress` 분리
4. `RummiJesterCard` / catalog 분리
5. `JesterEffectEngine` 분리
6. `MarketOffer` adapter 추가
7. 기존 import compatibility 유지

기존 Jester id와 save restore 경로는 변경하지 않는다.

## 7. Persistence Refactor

[MIGRATION]

저장은 다음 원칙으로만 수정한다.

- schema 변경은 별도 PR
- HMAC verification 유지
- old save invalid 처리 유지
- save/load golden test 필수
- stageStartSnapshot equivalent 유지
- activeScene restore 유지

저장 target 계약은 `05_SAVE_CHECKPOINT_DATA.md`를 기준으로 본다.

## 8. Naming Refactor Policy

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

이름 변경은 save schema, provider, tests가 준비된 뒤 compatibility adapter와 함께 수행한다.

## 9. PR Safety Rule

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
