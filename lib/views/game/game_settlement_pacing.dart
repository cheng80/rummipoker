import 'dart:math' as math;

/// 정산 연출의 박자·등급 계산. 모두 화면 전용이며 점수 결과를 바꾸지 않는다.
class GameSettlementPacing {
  const GameSettlementPacing._();

  /// 타일 tick 한 번마다 오르는 음높이 비율(레퍼런스 발동당 약 +1.6%).
  static const double tickPitchStep = 0.016;

  /// 한 확정 안에서 음높이가 오를 수 있는 상한.
  static const double tickPitchMax = 1.6;

  /// 이 스텝 수를 넘기면 자동 가속을 시작한다.
  static const int autoAccelStartStep = 8;
  static const double autoAccelPerStep = 0.12;
  static const double autoAccelMax = 2.5;

  /// 목표 점수 대비 줄 점수 비율로 나누는 등급 경계(0~3).
  static const List<double> gradeRatioThresholds = [0.1, 0.25, 0.5];

  /// hit-stop과 화면 흔들림을 쓰는 최소 등급(상위 2단계).
  static const int impactGrade = 2;

  /// [tickIndex]번째 tick(0부터, 확정 전체에 걸쳐 이어짐)의 pitch 배율.
  static double tickPitch(int tickIndex) =>
      math.min(tickPitchMax, 1 + tickPitchStep * tickIndex);

  /// 확정 안에서 [stepCount]번째 스텝의 추가 가속 배율(1 이상).
  static double autoAccel(int stepCount) {
    final over = stepCount - autoAccelStartStep;
    if (over <= 0) return 1;
    return math.min(autoAccelMax, 1 + autoAccelPerStep * over);
  }

  /// 줄 점수 [lineScore]가 목표 [targetScore]의 몇 할인지로 0~3 등급을 매긴다.
  static int grade(int lineScore, int targetScore) {
    if (targetScore <= 0) return gradeRatioThresholds.length;
    final ratio = lineScore / targetScore;
    var grade = 0;
    for (final threshold in gradeRatioThresholds) {
      if (ratio >= threshold) grade++;
    }
    return grade;
  }

  /// 미리보기 점수가 남은 목표를 넘을 때의 달아오름(0~1). 넘지 않으면 0.
  ///
  /// 초과 폭의 로그에 비례한다. 정확히 맞춰도 최소 0.35는 보인다.
  static double goalHeat({required int expectedScore, required int remaining}) {
    if (remaining <= 0 || expectedScore < remaining) return 0;
    final excess = (expectedScore - remaining) / remaining;
    return (0.35 + 0.65 * math.log(1 + excess) / math.log(4)).clamp(0.0, 1.0);
  }
}

enum BoardCalloutHorizontal { full, left, right }

/// 정산 callout이 놓일 보드 가장자리 자리.
class BoardCalloutSlot {
  const BoardCalloutSlot(this.top, this.horizontal);

  final bool top;
  final BoardCalloutHorizontal horizontal;

  String get name => '${top ? 'top' : 'bottom'}-${horizontal.name}';
}

/// callout이 덮을 수 있는 행 수(callout 높이가 한 칸을 조금 넘을 수 있다).
const int _calloutBandRows = 2;

/// 채점 중인 칸 [cells]를 가리지 않는 첫 자리. 위·아래 전체 폭을 먼저, 그다음
/// 좌·우 두 칸 폭을 본다. 5×5 보드의 가로·세로·대각 줄은 항상 자리가 있다.
BoardCalloutSlot boardCalloutSlotFor(
  List<(int, int)> cells, {
  int boardSize = 5,
}) {
  const candidates = [
    BoardCalloutSlot(true, BoardCalloutHorizontal.full),
    BoardCalloutSlot(false, BoardCalloutHorizontal.full),
    BoardCalloutSlot(true, BoardCalloutHorizontal.right),
    BoardCalloutSlot(true, BoardCalloutHorizontal.left),
    BoardCalloutSlot(false, BoardCalloutHorizontal.right),
    BoardCalloutSlot(false, BoardCalloutHorizontal.left),
  ];
  bool covers(BoardCalloutSlot slot, int row, int col) {
    final inBand = slot.top
        ? row < _calloutBandRows
        : row >= boardSize - _calloutBandRows;
    if (!inBand) return false;
    return switch (slot.horizontal) {
      BoardCalloutHorizontal.full => true,
      BoardCalloutHorizontal.left => col < 2,
      BoardCalloutHorizontal.right => col >= boardSize - 2,
    };
  }

  for (final slot in candidates) {
    if (!cells.any((cell) => covers(slot, cell.$1, cell.$2))) return slot;
  }
  return candidates.first;
}

/// 정산 tick 상태. 보드만 다시 그리도록 `ValueNotifier`로 전달한다.
class SettlementTileTicks {
  const SettlementTileTicks({this.heat = const {}, this.hitSerial = const {}});

  static const SettlementTileTicks empty = SettlementTileTicks();

  /// 교차 타일이 맞은 횟수.
  final Map<String, int> heat;

  /// 칸을 마지막으로 친 tick 순번.
  final Map<String, int> hitSerial;
}
