import 'dart:math';

import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../utils/seeded_random.dart';
import 'active_run_save_service.dart';
import 'new_run_setup.dart';

class DebugRunFixtureDefinition {
  const DebugRunFixtureDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.builder,
  });

  final String id;
  final String label;
  final String description;
  final ActiveRunRuntimeState Function() builder;
}

class DebugRunFixtureService {
  DebugRunFixtureService._();

  static const String stage2ScoringSnapshot = 'stage2_scoring_snapshot';
  static const String stage2MarketResume = 'stage2_market_resume';
  static const String deckNeedleBattle = 'deck_needle_battle';

  /// 새 디버그 픽스처는 여기에 등록하고, 아래에 대응하는 builder를 추가한다.
  static final List<DebugRunFixtureDefinition> _fixtures = [
    DebugRunFixtureDefinition(
      id: stage2ScoringSnapshot,
      label: 'Stage 2 점수 스냅샷',
      description:
          'Stage 2 / Gold 36 / Crazy Jester + Scary Face / Hand 비어 있음 / Deck 34',
      builder: _buildStage2ScoringSnapshot,
    ),
    DebugRunFixtureDefinition(
      id: stage2MarketResume,
      label: 'Stage 2 Market 복귀',
      description: 'Stage 2 / Shop scene 복귀 / Gold 46 / 다음 Station 자동 진행 검증용',
      builder: _buildStage2MarketResume,
    ),
    DebugRunFixtureDefinition(
      id: deckNeedleBattle,
      label: 'Deck Needle 전투 아이템',
      description: 'Deck Needle 보유 / 덱 상단 3장 확인 dialog 검증용',
      builder: _buildDeckNeedleBattle,
    ),
  ];

  static List<DebugRunFixtureDefinition> get fixtures =>
      List<DebugRunFixtureDefinition>.unmodifiable(_fixtures);

  static DebugRunFixtureDefinition? find(String fixtureId) {
    for (final fixture in _fixtures) {
      if (fixture.id == fixtureId) {
        return fixture;
      }
    }
    return null;
  }

  static ActiveRunRuntimeState? build(String fixtureId) {
    return find(fixtureId)?.builder();
  }

  static ActiveRunRuntimeState _buildStage2ScoringSnapshot() {
    final board = RummiBoard()
      ..setCell(0, 0, _tile(TileColor.blue, 12))
      ..setCell(0, 1, _tile(TileColor.blue, 11))
      ..setCell(0, 2, _tile(TileColor.red, 10))
      ..setCell(0, 3, _tile(TileColor.black, 8))
      ..setCell(0, 4, _tile(TileColor.red, 9))
      ..setCell(1, 0, _tile(TileColor.blue, 4))
      ..setCell(1, 1, _tile(TileColor.red, 5))
      ..setCell(1, 2, _tile(TileColor.black, 5))
      ..setCell(1, 3, _tile(TileColor.blue, 8))
      ..setCell(2, 0, _tile(TileColor.blue, 2))
      ..setCell(2, 1, _tile(TileColor.red, 2))
      ..setCell(2, 2, _tile(TileColor.yellow, 7))
      ..setCell(2, 3, _tile(TileColor.red, 8))
      ..setCell(3, 1, _tile(TileColor.yellow, 12))
      ..setCell(3, 2, _tile(TileColor.yellow, 4))
      ..setCell(4, 2, _tile(TileColor.black, 7))
      ..setCell(4, 3, _tile(TileColor.black, 11))
      ..setCell(4, 4, _tile(TileColor.black, 12));

    final session = RummiPokerGridSession.restored(
      runSeed: 2026041901,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(2026041901).state,
      blind: RummiBlindState(
        targetScore: 480,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
      ),
      deck: PokerDeck.remainingAfterPlaced(
        board: board,
        random: Random(2026041901),
      ),
      board: board,
      hand: const [],
      eliminated: const [],
    );

    final runProgress = RummiRunProgress.restore(
      stageIndex: 2,
      gold: 36,
      rerollCost: RummiRunProgress.shopBaseRerollCost,
      ownedJesters: const [
        RummiJesterCard(
          id: 'crazy_jester',
          displayName: 'Crazy Jester',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Played hand containing a Straight gives +12 Mult',
          effectType: 'mult_bonus',
          trigger: 'onScore',
          conditionType: 'straight',
          conditionValue: 'contains_straight',
          value: 12,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [],
        ),
        RummiJesterCard(
          id: 'scary_face',
          displayName: 'Scary Face',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Played face cards give +30 Chips when scored',
          effectType: 'chips_bonus',
          trigger: 'onScore',
          conditionType: 'face_card',
          conditionValue: 'jack_queen_king',
          value: 30,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [11, 12, 13],
        ),
      ],
      shopOffers: const [],
      statefulValuesBySlot: const {},
      playedHandCounts: const <RummiHandRank, int>{},
    );

    final stageStartSnapshot = ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildStage2MarketResume() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..gold = 46
      ..shopOffers.addAll([
        RummiShopOffer(
          slotIndex: 0,
          card: RummiJesterCard(
            id: 'green_jester',
            displayName: 'Green Jester',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Every discard changes current Mult by +1',
            effectType: 'stateful_growth',
            trigger: 'onDiscard',
            conditionType: 'none',
            conditionValue: null,
            value: 0,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 7,
        ),
        RummiShopOffer(
          slotIndex: 1,
          card: RummiJesterCard(
            id: 'popcorn',
            displayName: 'Popcorn',
            rarity: RummiJesterRarity.common,
            baseCost: 5,
            effectText: 'Starts at +20 Mult, decreases by 4 each round',
            effectType: 'stateful_growth',
            trigger: 'onScore',
            conditionType: 'none',
            conditionValue: null,
            value: 20,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 8,
        ),
      ]);

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: base.stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildDeckNeedleBattle() {
    final base = _buildStage2ScoringSnapshot();
    final deckTop = [
      _tile(TileColor.black, 4),
      _tile(TileColor.yellow, 3),
      _tile(TileColor.blue, 2),
      _tile(TileColor.red, 1),
    ];
    final session = RummiPokerGridSession.restored(
      runSeed: base.session.runSeed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: base.session.maxHandSize,
      runRandomState: base.session.runRandom.state,
      ruleset: base.session.ruleset,
      blind: base.session.blind.copyWith(),
      deck: PokerDeck.fromSnapshot(deckTop),
      board: base.session.board.copy(),
      hand: List<Tile>.from(base.session.hand),
      eliminated: List<Tile>.from(base.session.eliminated),
      boardMoveHistory: List<BoardMoveRecord>.from(
        base.session.boardMoveHistory,
      ),
    );
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'deck_needle',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['deck_needle'],
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static Tile _tile(TileColor color, int number) =>
      Tile(color: color, number: number);
}
