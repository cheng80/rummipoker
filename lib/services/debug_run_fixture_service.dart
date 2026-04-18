import 'dart:math';

import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../utils/seeded_random.dart';
import 'active_run_save_service.dart';

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

  /// 새 디버그 픽스처는 여기에 등록하고, 아래에 대응하는 builder를 추가한다.
  static final List<DebugRunFixtureDefinition> _fixtures = [
    DebugRunFixtureDefinition(
      id: stage2ScoringSnapshot,
      label: 'Stage 2 점수 스냅샷',
      description: 'Stage 2 / Gold 36 / Crazy Jester + Scary Face / Hand 비어 있음 / Deck 34',
      builder: _buildStage2ScoringSnapshot,
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
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
  }

  static Tile _tile(TileColor color, int number) =>
      Tile(color: color, number: number);
}
