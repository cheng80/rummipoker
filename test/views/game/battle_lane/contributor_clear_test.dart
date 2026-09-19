import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/game_presentation_timings.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

void main() {
  tearDown(() => MotionPolicy.debugReduceMotionOverride = null);

  const snapshot = {
    '2:0': Tile(color: TileColor.red, number: 1),
    '2:1': Tile(color: TileColor.blue, number: 2),
    '2:2': Tile(color: TileColor.yellow, number: 3),
  };

  testWidgets('snapshot이 비면 contributor가 줄 순서로 터지고 잔광 뒤 사라진다', (tester) async {
    MotionPolicy.debugReduceMotionOverride = false;
    final taps = <String>[];
    final board = RummiBoard()
      ..setCell(0, 0, const Tile(color: TileColor.black, number: 9));
    await tester.pumpWidget(_host(board, snapshot, taps));
    await tester.pumpWidget(_host(board, const {}, taps));
    await tester.pump();

    for (final key in snapshot.keys) {
      expect(
        find.byKey(ValueKey('contributor-clear-tile-$key')),
        findsOneWidget,
      );
    }
    // 제거 연출 중에도 입력은 막히지 않는다.
    await tester.tap(find.byKey(const ValueKey('board-cell-4-4')));
    expect(taps, ['4:4']);

    await tester.pump(
      GamePresentationTimings.contributorClearStagger * snapshot.length +
          GamePresentationTimings.contributorClearPop +
          GamePresentationTimings.contributorClearAfterglow +
          const Duration(milliseconds: 50),
    );
    expect(
      find.byKey(const ValueKey('contributor-clear-tile-2:0')),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('동작 줄이기에서는 제거 연출 없이 바로 비운다', (tester) async {
    MotionPolicy.debugReduceMotionOverride = true;
    final board = RummiBoard();
    await tester.pumpWidget(_host(board, snapshot, []));
    await tester.pumpWidget(_host(board, const {}, []));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('contributor-clear-tile-2:0')),
      findsNothing,
    );
  });

  testWidgets('전투 진입 deal은 짧게 돌고 끝나며, 동작 줄이기에서는 돌지 않는다', (tester) async {
    final board = RummiBoard()
      ..setCell(1, 1, const Tile(color: TileColor.black, number: 9));
    MotionPolicy.debugReduceMotionOverride = false;
    await tester.pumpWidget(_host(board, const {}, [], dealOnEnter: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    MotionPolicy.debugReduceMotionOverride = true;
    await tester.pumpWidget(_host(board, const {}, [], dealOnEnter: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('교차 타일은 맞은 횟수만큼 달아오른다', (tester) async {
    final board = RummiBoard()
      ..setCell(0, 0, const Tile(color: TileColor.black, number: 9));
    await tester.pumpWidget(
      _host(
        board,
        const {},
        [],
        heat: const {'0:0': 2},
        hitSerial: const {'0:0': 3},
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('board-cell-heat-0-0-2')), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

Widget _host(
  RummiBoard board,
  Map<String, Tile> snapshot,
  List<String> taps, {
  Map<String, int> heat = const {},
  Map<String, int> hitSerial = const {},
  bool dealOnEnter = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 260,
          child: GameBoardGrid(
            board: board,
            scoringCells: const {},
            constrainedScoringCells: const {},
            activeSettlementCells: const {},
            settlementBoardSnapshot: snapshot,
            settlementTileHeat: heat,
            settlementTileHitSerial: hitSerial,
            dealOnEnter: dealOnEnter,
            selectedRow: null,
            selectedCol: null,
            boardMoveMode: false,
            moveSourceRow: null,
            moveSourceCol: null,
            onTapCell: (row, col) => taps.add('$row:$col'),
            onLongPressTile: (_) {},
          ),
        ),
      ),
    ),
  );
}
