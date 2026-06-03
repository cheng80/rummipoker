# Task 3 Compact Review Packet v2

Review target: Fate required comprehension feedback.

## Approve If

- RED proves missing Fate selection observability.
- GREEN proves: candidate visible -> selected visible -> no result before confirm -> confirm -> flash -> result feedback.
- Candidate/selected visual distinction is proven by production painter logic.
- Existing feedback regression, analyze, cleanup pass.

## Scope

Production/UI:

- `lib/views/game/widgets/game_shared_board_widgets.dart`
- `lib/views/game/game_view_battle_actions.dart`
- `lib/views/game_view.dart`
- `lib/views/game/game_view_item_effect_widgets.dart`

Tests/process:

- Added `test/views/game/game_view_fate_feedback_test.dart`
- Existing `test/views/game/game_view_item_feedback_test.dart` still passes.
- `AGENTS.md` adds compact reviewer packet fallback rule.

## RED Evidence

File: `.omo/evidence/task-3-red-fate-confirm-flow.txt`

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'fate-line-selection-overlay'>]
```

Meaning: old Fate flow lacked stable test/reviewer-visible selection state.

## Relevant Diff Proof

Overlay + candidate/selected keys and tap targets:

```dart
// game_shared_board_widgets.dart:386-418
return GestureDetector(
  key: const ValueKey('fate-line-selection-overlay'),
  behavior: HitTestBehavior.opaque,
  onTapUp: (details) {
    final line = lineAt(details.localPosition);
    if (line != null) onTapLine(line);
  },
  child: Stack(children: [
    Positioned.fill(child: CustomPaint(...)),
    for (final line in lines)
      Positioned.fromRect(
        rect: _lineMarkerRect(line.ref, Size(...)),
        child: GestureDetector(
          key: ValueKey(
            'fate-line-selection-'
            '${line.ref == selectedLineRef ? 'selected' : 'candidate'}-'
            '${_lineRefTestKey(line.ref)}',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapLine(line),
          child: const SizedBox.expand(),
        ),
      ),
  ]),
);
```

Non-overlap hotspot avoids row/col/diag center collisions:

```dart
// game_shared_board_widgets.dart:552-561
String _lineRefTestKey(LineRef ref) => '${ref.kind.name}-${ref.index}';
Rect _lineMarkerRect(LineRef ref, Size size) {
  final metric = _BoardLineOverlayMetric(size);
  final cells = ref.cells();
  final start = metric.centerFor(cells.first.$1, cells.first.$2);
  final next = metric.centerFor(cells[1].$1, cells[1].$2);
  final center = Offset.lerp(start, next, 0.5)!;
  final side = metric.tapTolerance * 1.6;
  return Rect.fromCenter(center: center, width: side, height: side);
}
```

Visual distinction is in painter logic:

```dart
// game_shared_board_widgets.dart:583-599
final selected =
    target.line.ref == selectedLineRef &&
    target.tileIndex == selectedTileIndex;
final color = selected
    ? GameUiPalette.userSelection
    : GameUiPalette.tileBlueSeal;
final glow = Paint()
  ..color = color.withValues(alpha: selected ? 0.24 : 0.12)
  ..strokeWidth = selected ? 8 : 5;
final stroke = Paint()
  ..color = color.withValues(alpha: selected ? 0.98 : 0.68)
  ..strokeWidth = selected ? 4.4 : 2.6;
```

Confirm/result/flash keys:

```dart
// game_view_battle_actions.dart:416-424, 1034-1037
final fateTransformFeedback =
    _isFateLineTransformDefinition(selection.slot.item);
_showItemEffectFeedback(..., fateTransform: fateTransformFeedback);
FilledButton(key: const ValueKey('fate-line-confirm-button'), ...);

// game_view.dart:763-779; game_view_item_effect_widgets.dart:29-32
void _showItemEffectFeedback(..., bool fateTransform = false) { ... }
key: feedback.fateTransform
    ? const ValueKey('fate-line-transform-result-feedback')
    : const ValueKey('item-effect-feedback-toast')

// game_shared_board_widgets.dart:533-544
key: ValueKey('fate-line-transform-flash-${_lineRefTestKey(lineRef)}')
```

## Test Assertion Proof

File: `test/views/game/game_view_fate_feedback_test.dart`

```dart
await _pumpUntilText(tester, '보드에서 적용할 선을 선택하세요.');
await _pumpUntilKey(tester, const ValueKey('fate-line-selection-overlay'));
expect(find.byKey(const ValueKey('fate-line-selection-candidate-row-2')),
    findsOneWidget);
expect(find.byKey(const ValueKey('fate-line-transform-result-feedback')),
    findsNothing);

await tester.tap(find.byKey(
    const ValueKey('fate-line-selection-candidate-row-2')));
await _pumpUntilKey(tester,
    const ValueKey('fate-line-selection-selected-row-2'));
expect(find.byKey(const ValueKey('fate-line-transform-result-feedback')),
    findsNothing);

await tester.tap(find.byKey(const ValueKey('fate-line-confirm-button')));
expect(find.byKey(const ValueKey('fate-line-transform-flash-row-2')),
    findsOneWidget);
await _pumpUntilText(tester, '투페어 운명');
expect(find.byKey(const ValueKey('fate-line-transform-result-feedback')),
    findsOneWidget);
```

## Pass Outputs

```text
.omo/evidence/task-3-green-fate-confirm-flow.txt: 00:00 +1: All tests passed!
.omo/evidence/task-3-game-view-fate-feedback-test.txt: 00:00 +1: All tests passed!
.omo/evidence/task-3-game-view-item-feedback-test.txt: 00:02 +1: All tests passed!
.omo/evidence/task-3-dart-analyze.txt: No issues found!
```

Cleanup file: `.omo/evidence/task-3-cleanup.txt`

```text
No residual flutter test, flutter_tester, ChromeDriver/WebDriver,
serve_rummipoker, or flutter run process from Task 3 remains.
Matched processes were existing user Chrome Helper processes.
```

## Process Fix

Reviewer non-response was treated as an ultrawork operation bug. `AGENTS.md`
now says repeated large reviewer bundles should be replaced by a compact packet.
This v2 packet includes the exact embedded evidence requested after v1 rejection.

## Residual Risk

No browser screenshot was captured. Visual distinction is proven by painter
logic: candidate uses `tileBlueSeal` thinner/lower-alpha stroke; selected uses
`userSelection` thicker/higher-alpha stroke.
