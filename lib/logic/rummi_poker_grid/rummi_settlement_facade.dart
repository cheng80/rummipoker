import 'jester_meta.dart';

/// Current cash-out result를 장기 Settlement 용어로 읽기 위한 read model.
///
/// Important:
/// - 현재 `RummiCashOutBreakdown` 계산/저장 semantics는 유지한다.
/// - 이 facade는 `GameView -> cash-out sheet` 경계를 얇게 만드는 용도다.
/// - settlement 화면 구조를 미리 전면 교체하지 않는다.
enum RummiSettlementEntryKind {
  stationReward,
  boardDiscardReward,
  handDiscardReward,
  economyBonus,
  itemBonus,
}

class RummiSettlementEntryView {
  const RummiSettlementEntryView({
    required this.kind,
    required this.leadingLabel,
    required this.description,
    required this.gold,
    this.jesterId,
    this.itemId,
    this.displayName,
  });

  final RummiSettlementEntryKind kind;
  final String leadingLabel;
  final String description;
  final int gold;
  final String? jesterId;
  final String? itemId;
  final String? displayName;

  bool get isEconomyBonus => kind == RummiSettlementEntryKind.economyBonus;
  bool get isItemBonus => kind == RummiSettlementEntryKind.itemBonus;
  bool get isBonus => isEconomyBonus || isItemBonus;
}

class RummiSettlementRuntimeFacade {
  const RummiSettlementRuntimeFacade({
    required this.stageIndex,
    required this.targetScore,
    required this.currentGold,
    required this.totalGold,
    required this.entries,
  });

  factory RummiSettlementRuntimeFacade.fromCashOut({
    required RummiCashOutBreakdown breakdown,
    required int currentGold,
  }) {
    final entries = <RummiSettlementEntryView>[
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.stationReward,
        leadingLabel: 'Station ${breakdown.stageIndex}',
        description: 'Station Goal ${breakdown.targetScore} 달성 보상',
        gold: breakdown.blindReward,
      ),
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.boardDiscardReward,
        leadingLabel: '${breakdown.remainingBoardDiscards}',
        description:
            '남은 보드 버림 ${breakdown.remainingBoardDiscards}회 x ${breakdown.perBoardDiscardBonus}',
        gold: breakdown.boardDiscardGold,
      ),
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.handDiscardReward,
        leadingLabel: '${breakdown.remainingHandDiscards}',
        description:
            '남은 손패 버림 ${breakdown.remainingHandDiscards}회 x ${breakdown.perHandDiscardBonus}',
        gold: breakdown.handDiscardGold,
      ),
      ...breakdown.economyBonuses.map(
        (bonus) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.economyBonus,
          leadingLabel: 'J',
          description: '${bonus.displayName} 보너스',
          gold: bonus.gold,
          jesterId: bonus.jesterId,
          displayName: bonus.displayName,
        ),
      ),
      ...breakdown.itemBonuses.map(
        (bonus) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.itemBonus,
          leadingLabel: 'I',
          description: '${bonus.displayName} 보너스',
          gold: bonus.gold,
          itemId: bonus.itemId,
          displayName: bonus.displayName,
        ),
      ),
    ];

    return RummiSettlementRuntimeFacade(
      stageIndex: breakdown.stageIndex,
      targetScore: breakdown.targetScore,
      currentGold: currentGold,
      totalGold: breakdown.totalGold,
      entries: List<RummiSettlementEntryView>.unmodifiable(entries),
    );
  }

  final int stageIndex;
  final int targetScore;
  final int currentGold;
  final int totalGold;
  final List<RummiSettlementEntryView> entries;
}
