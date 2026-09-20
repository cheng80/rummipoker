import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';

/// 전투 화면은 들어갈 때마다 거의 언제나 새 [GameSessionArgs]로 세션 provider를
/// 만든다. family 구성원이 autoDispose되지 않으면 그 구성원이 컨테이너에 남아
/// 세션 state와 Jester catalog를 계속 붙잡는다. 웹에서 이 누적이 heap 증가로
/// 나타났으므로, 구독이 끝난 구성원이 실제로 사라지는지 여기서 지킨다.
void main() {
  test('구독이 끝난 세션 provider 구성원은 컨테이너에 남지 않는다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (var i = 0; i < 20; i += 1) {
      final args = GameSessionArgs(runSeed: 1000 + i);
      final subscription = container.listen(
        gameSessionNotifierProvider(args),
        (_, _) {},
      );
      expect(subscription.read().session, isNotNull);
      subscription.close();
      // autoDispose는 현재 tick이 끝난 뒤에 정리한다.
      await Future<void>.delayed(Duration.zero);
    }

    final remaining = container
        .getAllProviderElements()
        .where((element) => element.origin.from == gameSessionNotifierProvider)
        .length;
    expect(remaining, 0);
  });
}
