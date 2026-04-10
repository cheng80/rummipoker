import 'package:flame_binggo_card/game/bingo_card_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BingoCardGame can be instantiated', () {
    final game = BingoCardGame();
    expect(game, isNotNull);
  });
}
