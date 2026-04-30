import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../services/new_run_setup.dart';
import 'game_session_state.dart';

class GameSessionArgs {
  const GameSessionArgs({
    required this.runSeed,
    this.restoredRun,
    this.debugFixtureId,
    this.ruleset = RummiRuleset.currentDefaults,
    this.difficulty = NewRunDifficulty.standard,
    this.blindTier = BlindTier.small,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final RummiRuleset ruleset;
  final NewRunDifficulty difficulty;
  final BlindTier blindTier;

  @override
  bool operator ==(Object other) =>
      other is GameSessionArgs &&
      other.runSeed == runSeed &&
      identical(other.restoredRun, restoredRun) &&
      other.debugFixtureId == debugFixtureId &&
      other.ruleset == ruleset &&
      other.difficulty == difficulty &&
      other.blindTier == blindTier;

  @override
  int get hashCode => Object.hash(
    runSeed,
    restoredRun,
    debugFixtureId,
    ruleset,
    difficulty,
    blindTier,
  );
}

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<
      GameSessionNotifier,
      GameSessionState,
      GameSessionArgs
    >(GameSessionNotifier.new);

class DeckPeekBattleUseResult {
  const DeckPeekBattleUseResult._({required this.candidates, this.failMessage});

  const DeckPeekBattleUseResult.success(List<Tile> candidates)
    : this._(candidates: candidates);

  const DeckPeekBattleUseResult.failure(String message)
    : this._(candidates: const [], failMessage: message);

  final List<Tile> candidates;
  final String? failMessage;

  bool get isSuccess => failMessage == null;
}

class GameSessionNotifier
    extends FamilyNotifier<GameSessionState, GameSessionArgs> {
  @override
  GameSessionState build(GameSessionArgs args) {
    final restoredRun = args.restoredRun;
    if (restoredRun != null) {
      return _withDerivedViews(
        GameSessionState(
          session: restoredRun.session,
          runProgress: restoredRun.runProgress,
          stageStartSnapshot: restoredRun.stageStartSnapshot,
          ruleset: args.ruleset,
          runLoopPhase: _sceneToLoopPhase(restoredRun.activeScene),
          activeRunScene: restoredRun.activeScene,
          debugFixtureId: args.debugFixtureId,
        ),
      );
    }

    final ruleset = args.ruleset;
    final initialBlind = BlindSelectionSetup.resolveSpec(
      tier: args.blindTier,
      stationIndex: 1,
      difficulty: args.difficulty,
      ruleset: ruleset,
    );
    final session = RummiPokerGridSession(
      runSeed: args.runSeed,
      deckCopiesPerTile: ruleset.copiesPerTile,
      ruleset: ruleset,
      blind: RummiBlindState(
        targetScore: initialBlind.targetScore,
        boardDiscardsRemaining: initialBlind.boardDiscards,
        handDiscardsRemaining: initialBlind.handDiscards,
        bossModifier: initialBlind.bossModifier,
      ),
    );
    session.maxHandSize = initialBlind.maxHandSize;
    final runProgress = RummiRunProgress()
      ..currentStationBlindTierIndex = args.blindTier.index
      ..gold = _initialGold(args.difficulty)
      ..rerollCost = _initialRerollCost(args.difficulty);
    return _withDerivedViews(
      GameSessionState(
        session: session,
        runProgress: runProgress,
        ruleset: ruleset,
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
        runLoopPhase: GameRunLoopPhase.battle,
        activeRunScene: ActiveRunScene.battle,
        debugFixtureId: args.debugFixtureId,
      ),
    );
  }

  static int _initialGold(NewRunDifficulty difficulty) {
    return switch (difficulty) {
      NewRunDifficulty.standard => RummiEconomyConfig.startingGold,
      NewRunDifficulty.relaxed => RummiEconomyConfig.startingGold + 3,
      NewRunDifficulty.pressure => RummiEconomyConfig.startingGold,
    };
  }

  static int _initialRerollCost(NewRunDifficulty difficulty) {
    return switch (difficulty) {
      NewRunDifficulty.relaxed => RummiRunProgress.shopBaseRerollCost - 1,
      _ => RummiRunProgress.shopBaseRerollCost,
    };
  }

  void markDirty() {
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    _replaceState(
      state.copyWith(jesterCatalog: catalog, revision: state.revision + 1),
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    _replaceState(
      state.copyWith(
        runLoopPhase: _sceneToLoopPhase(scene),
        activeRunScene: scene,
        revision: state.revision + 1,
      ),
    );
  }

  ActiveRunRuntimeState buildSaveRuntimeState({
    ActiveRunScene? scene,
    required NewRunDifficulty difficulty,
    bool useStageStartSnapshotAsCurrent = false,
  }) {
    final currentScene = scene ?? state.activeRunScene;
    if (useStageStartSnapshotAsCurrent) {
      final stageStartSnapshot = state.stageStartSnapshot!;
      final retrySnapshot = ActiveRunStageSnapshot(
        session: stageStartSnapshot.session.copySnapshot(),
        runProgress: stageStartSnapshot.runProgress.copySnapshot(),
      );
      return ActiveRunRuntimeState(
        activeScene: ActiveRunScene.battle,
        difficulty: difficulty,
        session: retrySnapshot.session,
        runProgress: retrySnapshot.runProgress,
        stageStartSnapshot: retrySnapshot,
      );
    }

    return ActiveRunRuntimeState(
      activeScene: currentScene,
      difficulty: difficulty,
      session: state.session!,
      runProgress: state.runProgress!,
      stageStartSnapshot: state.stageStartSnapshot!,
    );
  }

  void setStageStartSnapshot(ActiveRunStageSnapshot snapshot) {
    _replaceState(
      state.copyWith(
        stageStartSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void replaceRuntimeState({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
    ActiveRunScene activeRunScene = ActiveRunScene.battle,
  }) {
    _replaceState(
      state.copyWith(
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: stageStartSnapshot,
        runLoopPhase: _sceneToLoopPhase(activeRunScene),
        activeRunScene: activeRunScene,
        debugFixtureId: state.debugFixtureId,
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        selectedJesterOverlayIndex: null,
        stageFlowPhase: GameStageFlowPhase.none,
        stageScoreAdded: 0,
        activeSettlementLine: null,
        activeSettlementStep: ScoringPresentationStep.none,
        activeSettlementEffectIndex: null,
        settlementBoardSnapshot: const {},
        settlementSequenceTick: 0,
        revision: state.revision + 1,
      ),
    );
  }

  /// 현재 스테이지 시작 시점(stageStartSnapshot)으로 복원.
  void restartCurrentStage() {
    final snapshot = state.stageStartSnapshot;
    if (snapshot == null) return;
    final restoredSession = snapshot.session.copySnapshot();
    final restoredRunProgress = snapshot.runProgress.copySnapshot();
    final refreshedSnapshot = ActiveRunSaveService.captureStageStartSnapshot(
      session: restoredSession,
      runProgress: restoredRunProgress,
    );
    replaceRuntimeState(
      session: restoredSession,
      runProgress: restoredRunProgress,
      stageStartSnapshot: refreshedSnapshot,
      activeRunScene: ActiveRunScene.battle,
    );
  }

  void setDebugMaxHandSize(int value) {
    final session = state.session;
    if (session == null) return;
    final ruleset = state.ruleset;
    final clamped = value.clamp(
      ruleset.minDebugMaxHandSize,
      ruleset.maxDebugMaxHandSize,
    );
    session.setDebugMaxHandSize(clamped);
    final selectedHandTile = state.selectedHandTile;
    _replaceState(
      state.copyWith(
        selectedHandTile:
            selectedHandTile != null && !session.hand.contains(selectedHandTile)
            ? null
            : selectedHandTile,
        revision: state.revision + 1,
      ),
    );
  }

  void clearSelections() {
    _replaceState(
      state.copyWith(
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedHandTile(Tile? tile) {
    _replaceState(
      state.copyWith(
        selectedHandTile: tile,
        selectedBoardRow: tile == null ? state.selectedBoardRow : null,
        selectedBoardCol: tile == null ? state.selectedBoardCol : null,
        revision: state.revision + 1,
      ),
    );
  }

  void toggleSelectedHandTile(Tile tile) {
    setSelectedHandTile(state.selectedHandTile == tile ? null : tile);
  }

  void setSelectedBoardCell(int? row, int? col) {
    _replaceState(
      state.copyWith(
        selectedBoardRow: row,
        selectedBoardCol: col,
        selectedHandTile: row == null && col == null
            ? state.selectedHandTile
            : null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: index,
        revision: state.revision + 1,
      ),
    );
  }

  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    _replaceState(
      state.copyWith(
        settlementBoardSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    ScoringPresentationStep activeSettlementStep = ScoringPresentationStep.none,
    int? activeSettlementEffectIndex,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    _replaceState(
      state.copyWith(
        stageFlowPhase: phase,
        stageScoreAdded: stageScoreAdded,
        activeSettlementLine: activeSettlementLine,
        activeSettlementStep: activeSettlementStep,
        activeSettlementEffectIndex: activeSettlementEffectIndex,
        settlementBoardSnapshot: settlementBoardSnapshot,
        settlementSequenceTick: bumpSettlementSequence
            ? state.settlementSequenceTick + 1
            : state.settlementSequenceTick,
        revision: state.revision + 1,
      ),
    );
  }

  // -- Business logic --

  BattleBoardTapResult tapBoardCell(int row, int col) {
    final session = state.session;
    if (session == null) {
      return const BattleBoardTapResult.fail('세션이 없습니다.');
    }

    final selectedHand = state.selectedHandTile;
    if (selectedHand != null) {
      final placed = tryPlaceTile(selectedHand, row, col);
      if (!placed) {
        return const BattleBoardTapResult.fail('이 칸에 둘 수 없습니다.');
      }
      return const BattleBoardTapResult.placed();
    }

    if (session.board.cellAt(row, col) == null) {
      return const BattleBoardTapResult.ignored();
    }
    if (state.selectedBoardRow == row && state.selectedBoardCol == col) {
      setSelectedBoardCell(null, null);
    } else {
      setSelectedBoardCell(row, col);
    }
    return const BattleBoardTapResult.selectionChanged();
  }

  /// 보드 스냅샷을 캡처하고 모든 완성 줄을 확정한다.
  /// 성공 시 결과를 반환하고, 확정할 줄이 없으면 null.
  ConfirmLinesResult? confirmLines() {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return null;

    final snapshot = <String, Tile>{};
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        final tile = session.board.cellAt(row, col);
        if (tile != null) {
          snapshot['$row:$col'] = tile;
        }
      }
    }

    final out = session.confirmAllFullLines(
      jesters: runProgress.ownedJesters,
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      applyScoreToBlind: false,
    );
    if (!out.result.ok) return null;

    runProgress.onConfirmedLines(out.result.lineBreakdowns);
    clearSelections();
    setSettlementBoardSnapshot(snapshot);
    return ConfirmLinesResult(
      totalScore: out.result.scoreAdded,
      lineBreakdowns: out.result.lineBreakdowns,
      stageCleared: out.cleared != null,
    );
  }

  ExpiryGuardResult? applyExpiryGuard({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null || itemCatalog == null) {
      return null;
    }
    final signals = session.evaluateExpirySignals();
    if (signals.isEmpty) return null;
    final results = ItemEffectRuntime.applyOwnedExpiryGuardItems(
      catalog: itemCatalog,
      session: session,
      runProgress: runProgress,
      signals: signals,
    );
    final appliedResults = results.where(
      (result) =>
          result.isSuccess &&
          result.events.any(
            (event) => event.kind == ItemEffectEventKind.expiryGuardTriggered,
          ),
    );
    final applied = appliedResults.isNotEmpty;
    if (!applied) return null;
    clearSelections();
    _replaceState(state.copyWith(revision: state.revision + 1));
    return ExpiryGuardResult(
      signals: signals,
      events: [for (final result in appliedResults) ...result.events],
    );
  }

  void applyConfirmedScore(int score) {
    final session = state.session;
    if (session == null) return;
    session.addScoreToBlind(score);
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    final breakdown = runProgress.buildCashOutBreakdown(
      session,
      itemCatalog: itemCatalog,
    );
    runProgress.applyCashOut(breakdown);
    if (itemCatalog != null &&
        runProgress.currentStationBlindTierIndex == BlindTier.boss.index) {
      ItemEffectRuntime.applyOwnedBossClearItems(
        catalog: itemCatalog,
        runProgress: runProgress,
      );
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return breakdown;
  }

  /// 전투 정산 직후 캐시아웃 준비를 notifier 경계로 모은다.
  RummiCashOutBreakdown prepareSettlementAndCashOut({
    ItemCatalog? itemCatalog,
  }) {
    final breakdown = prepareCashOut(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.settlement,
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
    return breakdown;
  }

  /// 디버그용: 현재 블라인드를 즉시 클리어 상태로 만든다.
  int debugForceBlindClear({BlindTier? overrideTier}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return 0;
    final remainingScore = max(
      0,
      session.blind.targetScore - session.blind.scoreTowardBlind,
    );
    session.blind.scoreTowardBlind = session.blind.targetScore;
    if (overrideTier != null) {
      runProgress.currentStationBlindTierIndex = overrideTier.index;
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return remainingScore;
  }

  /// 상점 열기: 오퍼 생성.
  void openShop({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    final catalog = state.jesterCatalog;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
    );
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: itemCatalog,
        runProgress: runProgress,
      );
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 캐시아웃 뒤 market 진입 준비를 notifier 경계에서 처리한다.
  void enterMarketAfterCashOut({ItemCatalog? itemCatalog}) {
    openShop(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.market,
        activeRunScene: ActiveRunScene.shop,
        revision: state.revision + 1,
      ),
    );
  }

  String? rerollShopFromState({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final catalog =
        state.jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[];
    return rerollShop(
      catalog: catalog,
      rng: session.runRandom,
      itemCatalog: itemCatalog,
    );
  }

  String? rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollShop(catalog: catalog, rng: rng);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketRerollItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
  }) {
    if (catalog == null || runProgress.effectiveRerollCost() <= 0) {
      return null;
    }
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null) continue;
      if (item.effect.timing == 'market_reroll' &&
          item.effect.op == 'free_next_reroll' &&
          item.effect.consume) {
        return item;
      }
    }
    return null;
  }

  String? buyShopOffer(int offerIndex, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.shopOffers.length) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= runProgress.jesterSlotCapacity()) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'jester',
    );
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final price = runProgress.effectiveJesterOfferPrice(offerIndex);
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(offerIndex);
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyItemOffer(
    RummiMarketItemOfferView offer, {
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final quickSlotCapacity = runProgress.quickSlotCapacity(
      itemCatalog: itemCatalog,
    );
    if (!runProgress.itemInventory.canAcquire(
      offer.item,
      quickSlotCapacity: quickSlotCapacity,
      passiveRelicCapacity: runProgress.passiveRelicCapacity(
        itemCatalog: itemCatalog,
      ),
    )) {
      return '이미 보유 한도에 도달한 아이템입니다.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'item',
    );
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final price = runProgress.effectiveItemPrice(offer.item);
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyItem(
      offer.item,
      price: price,
      itemCatalog: itemCatalog,
    );
    if (!ok) {
      return '아이템 구매 처리에 실패했습니다.';
    }
    runProgress.markItemOfferConsumed(offer.contentId);
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketBuyItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
    required String category,
  }) {
    if (catalog == null) return null;
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null || item.effect.op != 'discount_next_purchase') {
        continue;
      }
      if (item.effect.timing == 'market_buy') {
        return item;
      }
      if (item.effect.timing == 'market_buy_if_category' &&
          item.effect.value('category') == category) {
        return item;
      }
    }
    return null;
  }

  /// market 종료 후 다음 station 로딩 직전의 짧은 전환 단계를 기록한다.
  void beginNextStationTransition() {
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.nextStationTransition,
        activeRunScene: ActiveRunScene.blindSelect,
        revision: state.revision + 1,
      ),
    );
  }

  /// Market 종료 뒤 blind select route로 넘길 runtime을 station-loop 경계에서 만든다.
  ActiveRunRuntimeState prepareNextStationBlindSelectRuntime({
    required NewRunDifficulty difficulty,
  }) {
    beginNextStationTransition();
    return BlindSelectionSetup.prepareRuntimeForBlindSelect(
      runtime: buildSaveRuntimeState(
        scene: ActiveRunScene.blindSelect,
        difficulty: difficulty,
      ),
    );
  }

  /// 다음 스테이지로 진입 처리.
  void advanceToNextStage(int runSeed, {ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    runProgress.advanceStage(session, runSeed: runSeed);
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
      );
    }
    clearSelections();
    _replaceState(
      state.copyWith(
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
        runLoopPhase: GameRunLoopPhase.battle,
        revision: state.revision + 1,
      ),
    );
  }

  /// market 종료 후 다음 station 진입까지를 notifier command로 감싼다.
  void advanceToNextStation(int runSeed, {ItemCatalog? itemCatalog}) {
    advanceToNextStage(runSeed, itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
  }

  // -- 전투 액션 (View에서 직접 session을 조작하던 것을 이관) --

  /// 손패 타일을 보드에 배치. 성공 시 true.
  bool tryPlaceTile(Tile tile, int row, int col) {
    final session = state.session;
    if (session == null) return false;
    final placed = session.tryPlaceFromHand(tile, row, col);
    if (!placed) return false;
    clearSelections();
    _replaceState(state.copyWith(revision: state.revision + 1));
    return true;
  }

  /// 덱에서 손패로 드로우. 실패 사유를 문자열로 반환 (성공 시 null).
  String? drawTile() {
    final session = state.session;
    if (session == null) return '세션이 없습니다.';
    if (!session.canDrawFromDeck) {
      if (session.deck.isEmpty) return '덱이 비었습니다.';
      return '손패는 최대 ${session.maxHandSize}장입니다.';
    }
    final drawn = session.drawToHand();
    if (drawn == null) return '드로우에 실패했습니다.';
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  /// 보드 타일 버림. 실패 사유를 문자열로 반환 (성공 시 null).
  String? discardBoardTile(int row, int col) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return '세션이 없습니다.';
    final result = session.tryDiscardFromBoard(row, col);
    if (result.fail != null) {
      return switch (result.fail!) {
        DiscardFailReason.noBoardDiscardsLeft => '보드패 버림 횟수가 없습니다.',
        DiscardFailReason.noHandDiscardsLeft => '손패 버림 횟수가 없습니다.',
        DiscardFailReason.cellEmpty => '해당 칸이 비어 있습니다.',
        DiscardFailReason.tileNotInHand => '손패에서 버릴 카드를 찾지 못했습니다.',
      };
    }
    runProgress.onDiscardUsed();
    clearSelections();
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? discardSelectedBoardTileFromState() {
    final row = state.selectedBoardRow;
    final col = state.selectedBoardCol;
    if (row == null || col == null) {
      return '보드에서 버릴 타일을 먼저 선택하세요.';
    }
    return discardBoardTile(row, col);
  }

  /// 손패 타일 버림. 실패 사유를 문자열로 반환 (성공 시 null).
  String? discardHandTile(Tile tile) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return '세션이 없습니다.';
    final result = session.tryDiscardFromHand(tile);
    if (result.fail != null) {
      return switch (result.fail!) {
        DiscardFailReason.noBoardDiscardsLeft => '보드패 버림 횟수가 없습니다.',
        DiscardFailReason.noHandDiscardsLeft => '손패 버림 횟수가 없습니다.',
        DiscardFailReason.cellEmpty => '해당 칸이 비어 있습니다.',
        DiscardFailReason.tileNotInHand => '손패에서 버릴 카드를 찾지 못했습니다.',
      };
    }
    runProgress.onDiscardUsed();
    clearSelections();
    state = state.copyWith(revision: state.revision + 1);
    return null;
  }

  String? discardSelectedHandTileFromState() {
    final tile = state.selectedHandTile;
    if (tile == null) {
      return '손패에서 버릴 카드를 먼저 선택하세요.';
    }
    return discardHandTile(tile);
  }

  String? moveBoardTile({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    final session = state.session;
    if (session == null) return '세션이 없습니다.';
    final fail = session.tryMoveBoardTile(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
    );
    if (fail != null) {
      return switch (fail) {
        BoardMoveFailReason.noBoardMovesLeft => '보드 이동 횟수가 없습니다.',
        BoardMoveFailReason.sourceCellEmpty => '이동할 타일이 없습니다.',
        BoardMoveFailReason.destinationOccupied => '이동할 칸이 비어 있지 않습니다.',
      };
    }
    clearSelections();
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? moveSelectedBoardTileToFromState({
    required int toRow,
    required int toCol,
  }) {
    final fromRow = state.selectedBoardRow;
    final fromCol = state.selectedBoardCol;
    if (fromRow == null || fromCol == null) {
      return '이동할 보드 타일을 먼저 선택하세요.';
    }
    return moveBoardTile(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
    );
  }

  String? useBattleItem(ItemDefinition item) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return '세션이 없습니다.';

    final result = ItemEffectRuntime.useBattleItem(
      item: item,
      session: session,
      runProgress: runProgress,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? useMarketItem(ItemDefinition item) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';

    final result = ItemEffectRuntime.applyMarketUseItem(
      item: item,
      runProgress: runProgress,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  DeckPeekBattleUseResult consumeBattleDeckPeekItem(ItemDefinition item) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return const DeckPeekBattleUseResult.failure('세션이 없습니다.');
    }
    final result = ItemEffectRuntime.consumeBattleDeckPeekItem(
      item: item,
      session: session,
      runProgress: runProgress,
    );
    if (!result.isSuccess) {
      return DeckPeekBattleUseResult.failure(
        result.failMessage ?? '아이템을 사용할 수 없습니다.',
      );
    }
    final count =
        (item.effect.value('lookAt') as num?)?.toInt() ??
        (item.effect.value('peek') as num?)?.toInt() ??
        3;
    final candidates = session.peekDeckTop(count);
    _replaceState(state.copyWith(revision: state.revision + 1));
    return DeckPeekBattleUseResult.success(candidates);
  }

  String? useBattleDeckPeekDiscardItem(ItemDefinition item, int topIndex) {
    final session = state.session;
    if (session == null) return '세션이 없습니다.';

    final result = ItemEffectRuntime.useBattleDeckPeekDiscardItem(
      item: item,
      session: session,
      topIndex: topIndex,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  /// 장착 제스터 판매. 성공 시 true.
  bool sellOwnedJester(int index, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedJester(index, itemCatalog: itemCatalog);
    if (!ok) return false;
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: null,
        revision: state.revision + 1,
      ),
    );
    return true;
  }

  bool sellSelectedJesterOverlayFromState() {
    final index = state.selectedJesterOverlayIndex;
    if (index == null) return false;
    return sellOwnedJester(index);
  }

  /// 만료 신호 평가. 만료 시 신호 리스트 반환 (아니면 빈 리스트).
  List<RummiExpirySignal> evaluateExpiry() {
    final session = state.session;
    if (session == null) return const [];
    return session.evaluateExpirySignals();
  }

  /// 검사용 상점 열기 (특정 오퍼 ID 지정).
  void openShopForTest({required List<String> preferredOfferIds}) {
    final session = state.session;
    final runProgress = state.runProgress;
    final catalog = state.jesterCatalog;
    if (session == null || runProgress == null) return;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: preferredOfferIds.length,
    );
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  void _replaceState(GameSessionState next) {
    state = _withDerivedViews(next);
  }

  GameSessionState _withDerivedViews(GameSessionState next) {
    final session = next.session;
    final runProgress = next.runProgress;
    if (session == null || runProgress == null) {
      return next.copyWith(
        stationView: null,
        marketView: null,
        battleView: null,
        activeRunSaveView: null,
      );
    }

    return next.copyWith(
      stationView: RummiStationRuntimeFacade.fromSession(session),
      marketView: RummiMarketRuntimeFacade.fromRunProgress(runProgress),
      battleView: RummiBattleRuntimeFacade.fromRuntime(
        session: session,
        runProgress: runProgress,
      ),
      activeRunSaveView: RummiActiveRunSaveFacade.fromRuntimeState(
        ActiveRunRuntimeState(
          activeScene: next.activeRunScene,
          difficulty: arg.difficulty,
          session: session,
          runProgress: runProgress,
          stageStartSnapshot:
              next.stageStartSnapshot ??
              ActiveRunSaveService.captureStageStartSnapshot(
                session: session,
                runProgress: runProgress,
              ),
        ),
      ),
    );
  }

  GameRunLoopPhase _sceneToLoopPhase(ActiveRunScene scene) {
    return switch (scene) {
      ActiveRunScene.shop => GameRunLoopPhase.market,
      ActiveRunScene.blindSelect => GameRunLoopPhase.nextStationTransition,
      ActiveRunScene.battle => GameRunLoopPhase.battle,
    };
  }
}

/// [GameSessionNotifier.confirmLines] 결과.
class ConfirmLinesResult {
  const ConfirmLinesResult({
    required this.totalScore,
    required this.lineBreakdowns,
    required this.stageCleared,
  });

  final int totalScore;
  final List<ConfirmedLineBreakdown> lineBreakdowns;
  final bool stageCleared;
}

class ExpiryGuardResult {
  const ExpiryGuardResult({required this.signals, required this.events});

  final List<RummiExpirySignal> signals;
  final List<ItemEffectEvent> events;

  String get message {
    final hasBoardRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.boardDiscardAdded,
    );
    final hasDrawRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.tileDrawn,
    );
    if (hasBoardRescue && hasDrawRescue) {
      return '안전망이 보드 버림과 구조 드로우를 확보했습니다.';
    }
    if (hasBoardRescue) {
      return '안전망이 보드 버림 1회를 확보했습니다.';
    }
    return '안전망이 제거 더미를 섞어 타일 1장을 구조했습니다.';
  }

  String get feedbackDetail {
    final hasBoardRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.boardDiscardAdded,
    );
    final hasDrawRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.tileDrawn,
    );
    if (hasBoardRescue && hasDrawRescue) {
      return '보드 버림 +1 · 구조 드로우 +1';
    }
    if (hasBoardRescue) {
      return '보드 버림 +1';
    }
    return '구조 드로우 +1';
  }
}

class BattleBoardTapResult {
  const BattleBoardTapResult._({
    required this.didPlaceTile,
    required this.didChangeSelection,
    this.failMessage,
  });

  const BattleBoardTapResult.placed()
    : this._(didPlaceTile: true, didChangeSelection: false);

  const BattleBoardTapResult.selectionChanged()
    : this._(didPlaceTile: false, didChangeSelection: true);

  const BattleBoardTapResult.ignored()
    : this._(didPlaceTile: false, didChangeSelection: false);

  const BattleBoardTapResult.fail(String message)
    : this._(
        didPlaceTile: false,
        didChangeSelection: false,
        failMessage: message,
      );

  final bool didPlaceTile;
  final bool didChangeSelection;
  final String? failMessage;
}
