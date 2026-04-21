/// 블라인드당 자원·누적 점수 (GDD §8.2, `game_logic` §5.2).
///
/// 죽은 줄(하이·원페어)은 **줄 확정으로 한 줄씩 지우지 않음**. 보드 칸 비우기는 **버림(D)** 만.
class RummiBlindState {
  RummiBlindState({
    required this.targetScore,
    int? boardDiscardsRemaining,
    int? boardDiscardsMax,
    int? handDiscardsRemaining,
    int? handDiscardsMax,
    int? boardMovesRemaining,
    int? boardMovesMax,
    int? discardsRemaining,
    int? discardsMax,
    this.scoreTowardBlind = 0,
  }) : boardDiscardsRemaining =
           boardDiscardsRemaining ?? discardsRemaining ?? 4,
       boardDiscardsMax = boardDiscardsMax ?? discardsMax ?? 4,
       handDiscardsRemaining = handDiscardsRemaining ?? 2,
       handDiscardsMax = handDiscardsMax ?? 2,
       boardMovesRemaining = boardMovesRemaining ?? 3,
       boardMovesMax = boardMovesMax ?? 3;

  int targetScore;
  int boardDiscardsRemaining;
  int handDiscardsRemaining;
  int boardMovesRemaining;

  /// 초기 보드 버림(D) 횟수 상한 — UI `남음/최대` 표기용.
  final int boardDiscardsMax;

  /// 초기 손패 버림 횟수 상한 — UI `남음/최대` 표기용.
  final int handDiscardsMax;

  /// 초기 보드 이동 횟수 상한 — UI `남음/최대` 표기용.
  final int boardMovesMax;

  int scoreTowardBlind;

  /// 기존 코드/문서 호환용 별칭. 현재는 보드 버림 자원을 가리킨다.
  int get discardsRemaining => boardDiscardsRemaining;
  set discardsRemaining(int value) => boardDiscardsRemaining = value;

  /// 기존 코드/문서 호환용 별칭. 현재는 보드 버림 상한을 가리킨다.
  int get discardsMax => boardDiscardsMax;

  bool get isTargetMet => scoreTowardBlind >= targetScore;

  Map<String, dynamic> toJson() {
    return {
      'targetScore': targetScore,
      'boardDiscardsRemaining': boardDiscardsRemaining,
      'boardDiscardsMax': boardDiscardsMax,
      'handDiscardsRemaining': handDiscardsRemaining,
      'handDiscardsMax': handDiscardsMax,
      'boardMovesRemaining': boardMovesRemaining,
      'boardMovesMax': boardMovesMax,
      'scoreTowardBlind': scoreTowardBlind,
    };
  }

  static RummiBlindState fromJson(Map<String, dynamic> json) {
    return RummiBlindState(
      targetScore: (json['targetScore'] as num).toInt(),
      boardDiscardsRemaining: (json['boardDiscardsRemaining'] as num?)?.toInt(),
      boardDiscardsMax: (json['boardDiscardsMax'] as num?)?.toInt(),
      handDiscardsRemaining: (json['handDiscardsRemaining'] as num?)?.toInt(),
      handDiscardsMax: (json['handDiscardsMax'] as num?)?.toInt(),
      boardMovesRemaining: (json['boardMovesRemaining'] as num?)?.toInt(),
      boardMovesMax: (json['boardMovesMax'] as num?)?.toInt(),
      scoreTowardBlind: (json['scoreTowardBlind'] as num?)?.toInt() ?? 0,
    );
  }

  RummiBlindState copyWith({
    int? targetScore,
    int? boardDiscardsRemaining,
    int? boardDiscardsMax,
    int? handDiscardsRemaining,
    int? handDiscardsMax,
    int? boardMovesRemaining,
    int? boardMovesMax,
    int? discardsRemaining,
    int? discardsMax,
    int? scoreTowardBlind,
  }) {
    return RummiBlindState(
      targetScore: targetScore ?? this.targetScore,
      boardDiscardsRemaining:
          boardDiscardsRemaining ??
          discardsRemaining ??
          this.boardDiscardsRemaining,
      boardDiscardsMax:
          boardDiscardsMax ?? discardsMax ?? this.boardDiscardsMax,
      handDiscardsRemaining:
          handDiscardsRemaining ?? this.handDiscardsRemaining,
      handDiscardsMax: handDiscardsMax ?? this.handDiscardsMax,
      boardMovesRemaining: boardMovesRemaining ?? this.boardMovesRemaining,
      boardMovesMax: boardMovesMax ?? this.boardMovesMax,
      scoreTowardBlind: scoreTowardBlind ?? this.scoreTowardBlind,
    );
  }
}
