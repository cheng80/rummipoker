import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int get hashCode =>
      Object.hash(
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
      ),
    );
    session.maxHandSize = initialBlind.maxHandSize;
    final runProgress = RummiRunProgress()
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
        session: retrySnapshot.session,
        runProgress: retrySnapshot.runProgress,
        stageStartSnapshot: retrySnapshot,
      );
    }

    return ActiveRunRuntimeState(
      activeScene: currentScene,
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
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    _replaceState(
      state.copyWith(
        stageFlowPhase: phase,
        stageScoreAdded: stageScoreAdded,
        activeSettlementLine: activeSettlementLine,
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

  void applyConfirmedLineScore(int score) {
    final session = state.session;
    if (session == null) return;
    session.addScoreToBlind(score);
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut() {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    final breakdown = runProgress.buildCashOutBreakdown(session);
    runProgress.applyCashOut(breakdown);
    _replaceState(state.copyWith(revision: state.revision + 1));
    return breakdown;
  }

  /// 전투 정산 직후 캐시아웃 준비를 notifier 경계로 모은다.
  RummiCashOutBreakdown prepareSettlementAndCashOut() {
    final breakdown = prepareCashOut();
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.settlement,
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
    return breakdown;
  }

  /// 상점 열기: 오퍼 생성.
  void openShop() {
    final session = state.session!;
    final runProgress = state.runProgress!;
    final catalog = state.jesterCatalog;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
    );
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 캐시아웃 뒤 market 진입 준비를 notifier 경계에서 처리한다.
  void enterMarketAfterCashOut() {
    openShop();
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.market,
        activeRunScene: ActiveRunScene.shop,
        revision: state.revision + 1,
      ),
    );
  }

  String? rerollShopFromState() {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final catalog =
        state.jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[];
    return rerollShop(catalog: catalog, rng: session.runRandom);
  }

  String? rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final ok = runProgress.rerollShop(catalog: catalog, rng: rng);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyShopOffer(int offerIndex) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.shopOffers.length) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= RummiRunProgress.maxJesterSlots) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final offer = runProgress.shopOffers[offerIndex];
    if (runProgress.gold < offer.price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(offerIndex);
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  /// market 종료 후 다음 station 로딩 직전의 짧은 전환 단계를 기록한다.
  void beginNextStationTransition() {
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.nextStationTransition,
        revision: state.revision + 1,
      ),
    );
  }

  /// 다음 스테이지로 진입 처리.
  void advanceToNextStage(int runSeed) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    runProgress.advanceStage(session, runSeed: runSeed);
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
  void advanceToNextStation(int runSeed) {
    advanceToNextStage(runSeed);
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

  /// 장착 제스터 판매. 성공 시 true.
  bool sellOwnedJester(int index) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedJester(index);
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
