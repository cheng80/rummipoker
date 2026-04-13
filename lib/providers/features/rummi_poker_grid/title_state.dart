import '../../../services/active_run_save_service.dart';

/// 타이틀 화면에서 이어하기 관련 저장 상태를 보관한다.
class TitleState {
  const TitleState({
    this.hasStoredActiveRun = false,
    this.lastAvailability = ActiveRunAvailability.none,
  });

  final bool hasStoredActiveRun;
  final ActiveRunAvailability lastAvailability;

  TitleState copyWith({
    bool? hasStoredActiveRun,
    ActiveRunAvailability? lastAvailability,
  }) {
    return TitleState(
      hasStoredActiveRun: hasStoredActiveRun ?? this.hasStoredActiveRun,
      lastAvailability: lastAvailability ?? this.lastAvailability,
    );
  }
}
