/// 블라인드당 자원·누적 점수 (GDD §8.2, `game_logic` §5.2).
///
/// 죽은 줄(하이·원페어)은 **줄 확정으로 한 줄씩 지우지 않음**. 보드 칸 비우기는 **버림(D)** 만.
class RummiBlindState {
  RummiBlindState({
    required this.targetScore,
    required this.discardsRemaining,
    this.discardsMax = 4,
    this.scoreTowardBlind = 0,
  });

  int targetScore;
  int discardsRemaining;

  /// 초기 버림(D) 횟수 상한 — UI `남음/최대` 표기용.
  final int discardsMax;

  int scoreTowardBlind;

  bool get isTargetMet => scoreTowardBlind >= targetScore;

  RummiBlindState copyWith({
    int? targetScore,
    int? discardsRemaining,
    int? discardsMax,
    int? scoreTowardBlind,
  }) {
    return RummiBlindState(
      targetScore: targetScore ?? this.targetScore,
      discardsRemaining: discardsRemaining ?? this.discardsRemaining,
      discardsMax: discardsMax ?? this.discardsMax,
      scoreTowardBlind: scoreTowardBlind ?? this.scoreTowardBlind,
    );
  }
}
