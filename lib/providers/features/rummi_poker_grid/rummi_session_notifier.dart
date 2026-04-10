import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rummi_session_state.dart';

/// Rummi Poker Grid 게임 세션 (향후 `logic/` 엔진과 동기화).
final rummiSessionNotifierProvider =
    NotifierProvider<RummiSessionNotifier, RummiSessionState>(
  RummiSessionNotifier.new,
);

class RummiSessionNotifier extends Notifier<RummiSessionState> {
  @override
  RummiSessionState build() => const RummiSessionState();

  void setPhase(RummiSessionPhase phase) {
    state = state.copyWith(phase: phase);
  }

  void reset() {
    state = const RummiSessionState();
  }
}
