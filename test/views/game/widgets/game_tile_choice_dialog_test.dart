import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_tile_choice_dialog.dart';

void main() {
  testWidgets('tile choice candidates are not pre-highlighted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameTileChoiceDialog(
            title: '덱 확인',
            message: '덱 위 3장 중 버릴 타일을 선택합니다.',
            tiles: [
              Tile(color: TileColor.red, number: 1),
              Tile(color: TileColor.blue, number: 2),
              Tile(color: TileColor.yellow, number: 3),
            ],
          ),
        ),
      ),
    );

    final cards = tester
        .widgetList<GameRummiTileCard>(find.byType(GameRummiTileCard))
        .toList();

    expect(cards, hasLength(3));
    expect(cards.every((card) => card.accent == false), isTrue);
    expect(cards.every((card) => card.selected == false), isTrue);
  });
}
