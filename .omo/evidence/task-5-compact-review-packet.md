# Task 5 Compact Review Packet: Ritual Selection, Flight, Result

## Scope

Plan task: Ritual Selection, Flight, And Result Redesign.

Files in Task 5 scope:

- `lib/views/game/game_view_item_effect_widgets.dart`
- `test/views/game/game_view_ritual_feedback_test.dart`
- `test/views/game/game_view_ritual_gold_feedback_test.dart`
- `test/views/game/game_view_ritual_no_target_test.dart`

Prior Task 3 already added the shared Fate/Ritual overlay keys and confirm button:

- `fate-line-selection-overlay`
- `fate-tile-selection-overlay`
- `fate-line-selection-candidate-*`
- `fate-line-selection-selected-*`
- `fate-tile-selection-candidate-*`
- `fate-tile-selection-selected-*`
- `fate-line-confirm-button`

Task 5 adds visible Ritual flight identity evidence and tests the Ritual paths.

## RED Evidence

Copy/deck flight RED:

- Artifact: `.omo/evidence/task-5-red-ritual-copy-flight.txt`
- Test: `ritual tile copy requires confirm and shows copied tile flight`
- Failure: after confirm, `ritual-deck-flight` existed but no `ritual-deck-flight-tile-*` key existed for the copied tile payload.

Gold flight RED:

- Artifact: `.omo/evidence/task-5-red-ritual-gold-flight.txt`
- Test: `ritual burn requires confirm and shows gold coin flight`
- Failure excerpt:
  - `Expected: exactly one matching candidate`
  - `Actual: Found 0 widgets with key [<'ritual-gold-flight'>]`

These are right-reason REDs: runtime action succeeded, but the UI flight evidence was not distinguishable/testable.

## Implementation Excerpt

`lib/views/game/game_view_item_effect_widgets.dart`

```dart
return Stack(
  key: const ValueKey('ritual-gold-flight'),
  children: [
    for (var i = 0; i < coinCount; i++)
      _RitualGoldCoin(
        key: ValueKey('ritual-gold-flight-coin-$i'),
        progress: progress,
        start: start + Offset((i - 2) * 8.0, (i.isEven ? -10 : 4)),
        end: end + Offset((i % 3 - 1) * 9.0, (i - 3) * 2.0),
        delay: i * 0.055,
        size: 22 + (i % 3) * 2,
      ),
```

```dart
SizedBox(
  key: ValueKey(
    'ritual-deck-flight-tile-${entry.$1}-${entry.$2.code}',
  ),
  width: 34,
  height: 44,
  child: GameRummiTileCard(
    tile: entry.$2,
```

No runtime balance/catalog/market logic changed in Task 5. The production change is stable keys on already-rendered Ritual flight widgets.

## Widget Behavior Evidence

Copy/deck path:

- Test file: `test/views/game/game_view_ritual_feedback_test.dart`
- Fixture: `DebugRunFixtureService.ritualDeckEchoBattlePreview`
- Auto item: `sealed_copy`
- Assertions:
  - waits for `보드에서 적용할 타일을 선택하세요.`
  - finds `fate-tile-selection-overlay`
  - selects `fate-tile-selection-candidate-*`
  - confirms selected state through `fate-tile-selection-selected-*`
  - asserts no `ritual-deck-flight` before confirm
  - taps `fate-line-confirm-button`
  - asserts `ritual-deck-flight`
  - asserts `ritual-deck-flight-tile-*`
  - waits for result text containing `덱 복제`
- GREEN artifact: `.omo/evidence/task-5-game-view-ritual-feedback-test.txt`
- Result: `00:00 +1: All tests passed!`

Gold path:

- Test file: `test/views/game/game_view_ritual_gold_feedback_test.dart`
- Fixture: `DebugRunFixtureService.ritualPruneBurnBattlePreview`
- Auto item: `deadwood_burn`
- Assertions:
  - waits for `보드에서 적용할 선을 선택하세요.`
  - finds `fate-line-selection-overlay`
  - selects `fate-line-selection-candidate-*`
  - confirms selected state through `fate-line-selection-selected-*`
  - asserts no `ritual-gold-flight` before confirm
  - taps `fate-line-confirm-button`
  - asserts `ritual-gold-flight`
  - asserts `ritual-gold-flight-coin-*`
  - waits for `market-gold-gain-badge`
  - asserts `+3G`
- GREEN artifact: `.omo/evidence/task-5-green-ritual-gold-flight.txt`
- Result: `00:00 +1: All tests passed!`

No-target failure path:

- Test file: `test/views/game/game_view_ritual_no_target_test.dart`
- Fixture: `DebugRunFixtureService.ritualGrowthCopyBattlePreview` with inventory replaced by only `sealed_copy`
- Assertions:
  - waits for `선택할 보드 선이 없습니다.`
  - `battle-item-card-sealed_copy` remains present
  - no `fate-tile-selection-overlay`
  - no `ritual-deck-flight`
- GREEN artifact: `.omo/evidence/task-5-ritual-no-target-test.txt`
- Result: `00:00 +1: All tests passed!`

## Runtime And Fixture Regression

Runtime draw order:

- Command: `/Users/cheng80/flutter/bin/flutter test test/logic/item_effect_runtime_test.dart --name "ritual copy effects add scoring tile results to the next draw"`
- Artifact: `.omo/evidence/task-5-ritual-runtime-copy-draw.txt`
- Result: `00:00 +1: All tests passed!`

Fixture coverage:

- Command: `/Users/cheng80/flutter/bin/flutter test test/services/debug_run_fixture_service_test.dart --name "ritual battle preview fixtures expose representative item groups"`
- Artifact: `.omo/evidence/task-5-ritual-fixtures.txt`
- Result: `00:00 +1: All tests passed!`

## Static And Cleanup

Analyze:

- Command: `/Users/cheng80/flutter/bin/dart analyze lib/views/game/game_view_item_effect_widgets.dart test/views/game/game_view_ritual_feedback_test.dart test/views/game/game_view_ritual_gold_feedback_test.dart test/views/game/game_view_ritual_no_target_test.dart`
- Artifact: `.omo/evidence/task-5-dart-analyze.txt`
- Result: `No issues found!`

Cleanup:

- Artifact: `.omo/evidence/task-5-cleanup.txt`
- Result: `no flutter test/flutter_tester/chromedriver/webdriver/flutter web server/headless Chrome residue from Task 5 tests`
- Note: `tmux: unavailable`; evidence captured through command stdout artifacts.

## Reviewer Questions

Please audit:

1. Do the RED/GREEN artifacts prove deck and gold Ritual flights are visually/testably distinguishable after confirm?
2. Do the tests prove candidate -> selected -> confirm grammar, and absence of premature flight before confirm?
3. Does the no-target path prove no item consumption/no overlay/no flight?
4. Is there any behavioral risk from adding keys to existing flight widgets?
