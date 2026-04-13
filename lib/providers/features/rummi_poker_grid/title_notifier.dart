import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/active_run_save_service.dart';
import 'title_state.dart';

final titleNotifierProvider =
    AsyncNotifierProvider<TitleNotifier, TitleState>(TitleNotifier.new);

/// 타이틀 화면의 이어하기/삭제용 저장 상태를 관리한다.
class TitleNotifier extends AsyncNotifier<TitleState> {
  @override
  Future<TitleState> build() async {
    return _inspectState();
  }

  Future<TitleState> refreshAvailability() async {
    final next = await _inspectState();
    state = AsyncData(next);
    return next;
  }

  Future<ActiveRunRuntimeState?> loadStoredRun() {
    return ActiveRunSaveService.loadActiveRun();
  }

  Future<void> clearStoredRun() async {
    await ActiveRunSaveService.clearActiveRun();
    final next = const TitleState(
      hasStoredActiveRun: false,
      lastAvailability: ActiveRunAvailability.none,
    );
    state = AsyncData(next);
  }

  Future<TitleState> _inspectState() async {
    final availability = await ActiveRunSaveService.inspectActiveRun();
    return TitleState(
      hasStoredActiveRun: ActiveRunSaveService.hasStoredActiveRun(),
      lastAvailability: availability,
    );
  }
}
