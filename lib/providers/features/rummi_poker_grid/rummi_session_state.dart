/// Rummi Poker Grid 세션 스냅샷 (UI·Flame가 구독할 최소 상태).
///
/// 엔진(덱·보드·핸드)이 커지면 이 클래스를 확장하거나 하위 상태로 분리한다.
class RummiSessionState {
  const RummiSessionState({
    this.phase = RummiSessionPhase.idle,
  });

  final RummiSessionPhase phase;

  RummiSessionState copyWith({
    RummiSessionPhase? phase,
  }) {
    return RummiSessionState(
      phase: phase ?? this.phase,
    );
  }
}

/// 앱 라우트와 별개인 **게임 세션** 생명주기.
/// (예: 타이틀에서 /game 진입 시 `playing`으로 전환 — 추후 연결)
enum RummiSessionPhase {
  /// 아직 세션 없음 (또는 이전 게임 종료 후)
  idle,

  /// 로딩·에셋 준비 등
  loading,

  /// 인게임
  playing,

  /// 일시정지 오버레이
  paused,
}
