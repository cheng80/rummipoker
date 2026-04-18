/// GDD §4.2 족보 (높은 것이 enum 앞쪽에 오도록 유지 — 판정 순서와 무관, 표시용).
enum RummiHandRank {
  highCard,
  onePair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
}

/// 현재 룰 기준 기본 점수. 투페어 이상만 점수를 준다.
int gddBaseScore(RummiHandRank r) => switch (r) {
  RummiHandRank.highCard => 0,
  RummiHandRank.onePair => 0,
  RummiHandRank.twoPair => 25,
  RummiHandRank.threeOfAKind => 40,
  RummiHandRank.straight => 70,
  RummiHandRank.flush => 50,
  RummiHandRank.fullHouse => 80,
  RummiHandRank.fourOfAKind => 100,
  RummiHandRank.straightFlush => 150,
};

/// 현재는 하이카드와 원페어를 점수 없는 줄로 취급한다.
bool isDeadLineRank(RummiHandRank r) =>
    r == RummiHandRank.highCard || r == RummiHandRank.onePair;

/// 5칸이 찬 줄은 플레이어가 수동으로 제거 시도 가능 (GDD §4.3).
bool gddCanClearLine(RummiHandRank r) => true;
