import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RummiPokerGridSession은 시드로 생성 가능', () {
    final s = RummiPokerGridSession(runSeed: 42);
    expect(s.runSeed, 42);
    expect(s.conservationTotal, 52);
  });
}
