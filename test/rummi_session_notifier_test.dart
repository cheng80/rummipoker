import 'package:rummipoker/providers/features/rummi_poker_grid/rummi_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/rummi_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RummiSessionNotifier initial phase is idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(rummiSessionNotifierProvider);
    expect(state.phase, RummiSessionPhase.idle);
  });

  test('setPhase updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(rummiSessionNotifierProvider.notifier)
        .setPhase(RummiSessionPhase.playing);

    expect(
      container.read(rummiSessionNotifierProvider).phase,
      RummiSessionPhase.playing,
    );
  });
}
