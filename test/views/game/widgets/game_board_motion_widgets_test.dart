import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  testWidgets('GameBoardGrid marks source and destination during board move', (
    tester,
  ) async {
    final board = RummiBoard()
      ..setCell(0, 0, const Tile(color: TileColor.red, number: 7));

    await tester.pumpWidget(_host(board));
    await tester.pump();

    final moved = board.copy();
    expect(moved.moveCell(fromRow: 0, fromCol: 0, toRow: 0, toCol: 1), isTrue);

    await tester.pumpWidget(_host(moved));
    await tester.pump();

    expect(find.byKey(const ValueKey('board-move-flight')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('board-move-flight-source-ring')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('board-move-flight-destination-ring')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Widget _host(RummiBoard board) {
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
            settlementBoardSnapshot: const {},
            selectedRow: null,
            selectedCol: null,
            boardMoveMode: false,
            moveSourceRow: null,
            moveSourceCol: null,
            onTapCell: (_, _) {},
            onLongPressTile: (_) {},
          ),
        ),
      ),
    ),
  );
}
