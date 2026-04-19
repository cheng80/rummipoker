import '../../../services/active_run_save_service.dart';
import '../../../services/active_run_save_facade.dart';

/// 타이틀 화면에서 이어하기 관련 저장 상태를 보관한다.
class TitleState {
  const TitleState({
    this.hasStoredActiveRun = false,
    this.lastAvailability = ActiveRunAvailability.none,
    this.storedRunSummary,
  });

  final bool hasStoredActiveRun;
  final ActiveRunAvailability lastAvailability;
  final RummiActiveRunSaveFacade? storedRunSummary;

  TitleState copyWith({
    bool? hasStoredActiveRun,
    ActiveRunAvailability? lastAvailability,
    Object? storedRunSummary = _unset,
  }) {
    return TitleState(
      hasStoredActiveRun: hasStoredActiveRun ?? this.hasStoredActiveRun,
      lastAvailability: lastAvailability ?? this.lastAvailability,
      storedRunSummary: storedRunSummary == _unset
          ? this.storedRunSummary
          : storedRunSummary as RummiActiveRunSaveFacade?,
    );
  }
}

const Object _unset = Object();
