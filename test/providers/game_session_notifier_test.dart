import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';

void main() {
  group('GameSessionNotifier', () {
    test('새 런 초기화 시 세션과 진행도가 준비된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 12345);

      container
          .read(gameSessionNotifierProvider(args).notifier);

      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.isReady, isTrue);
      expect(state.session?.runSeed, 12345);
      expect(state.runProgress, isNotNull);
      expect(state.pendingResumeShop, isFalse);
    });

    test('손패 선택과 선택 해제를 상태에서 관리한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 7);

      final notifier = container.read(gameSessionNotifierProvider(args).notifier);

      const tile = Tile(id: 1, color: TileColor.red, number: 1);
      notifier.setSelectedHandTile(tile);
      expect(
        container.read(gameSessionNotifierProvider(args)).selectedHandTile,
        tile,
      );

      notifier.clearSelections();
      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.selectedHandTile, isNull);
      expect(state.selectedBoardRow, isNull);
      expect(state.selectedBoardCol, isNull);
    });

    test('디버그 손패 수를 바꾸면 세션 값이 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const args = GameSessionArgs(runSeed: 9);

      final notifier = container.read(gameSessionNotifierProvider(args).notifier);
      notifier.setDebugMaxHandSize(3);

      final state = container.read(gameSessionNotifierProvider(args));
      expect(state.session?.maxHandSize, 3);
    });
  });
}
