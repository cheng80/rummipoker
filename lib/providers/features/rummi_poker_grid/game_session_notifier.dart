import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../services/active_run_save_service.dart';
import 'game_session_state.dart';

class GameSessionArgs {
  const GameSessionArgs({
    required this.runSeed,
    this.restoredRun,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;

  @override
  bool operator ==(Object other) =>
      other is GameSessionArgs &&
      other.runSeed == runSeed &&
      identical(other.restoredRun, restoredRun);

  @override
  int get hashCode => Object.hash(runSeed, restoredRun);
}

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<GameSessionNotifier, GameSessionState, GameSessionArgs>(
  GameSessionNotifier.new,
);

class GameSessionNotifier extends FamilyNotifier<GameSessionState, GameSessionArgs> {
  @override
  GameSessionState build(GameSessionArgs args) {
    final restoredRun = args.restoredRun;
    if (restoredRun != null) {
      return GameSessionState(
        session: restoredRun.session,
        runProgress: restoredRun.runProgress,
        stageStartSnapshot: restoredRun.stageStartSnapshot,
        activeRunScene: restoredRun.activeScene,
        pendingResumeShop: restoredRun.activeScene == ActiveRunScene.shop,
      );
    }

    final session = RummiPokerGridSession(runSeed: args.runSeed);
    final runProgress = RummiRunProgress();
    return GameSessionState(
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
        session: session,
        runProgress: runProgress,
      ),
      activeRunScene: ActiveRunScene.battle,
    );
  }

  void markDirty() {
    state = state.copyWith(revision: state.revision + 1);
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    state = state.copyWith(
      jesterCatalog: catalog,
      revision: state.revision + 1,
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    state = state.copyWith(
      activeRunScene: scene,
      revision: state.revision + 1,
    );
  }

  void setPendingResumeShop(bool value) {
    state = state.copyWith(
      pendingResumeShop: value,
      revision: state.revision + 1,
    );
  }

  void setStageStartSnapshot(ActiveRunStageSnapshot snapshot) {
    state = state.copyWith(
      stageStartSnapshot: snapshot,
      revision: state.revision + 1,
    );
  }

  void replaceRuntimeState({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
    ActiveRunScene activeRunScene = ActiveRunScene.battle,
  }) {
    state = state.copyWith(
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
      activeRunScene: activeRunScene,
      pendingResumeShop: false,
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
    session.setDebugMaxHandSize(value);
    final selectedHandTile = state.selectedHandTile;
    state = state.copyWith(
      selectedHandTile:
          selectedHandTile != null && !session.hand.contains(selectedHandTile)
          ? null
          : selectedHandTile,
      revision: state.revision + 1,
    );
  }

  void clearSelections() {
    state = state.copyWith(
      selectedHandTile: null,
      selectedBoardRow: null,
      selectedBoardCol: null,
      revision: state.revision + 1,
    );
  }

  void setSelectedHandTile(Tile? tile) {
    state = state.copyWith(
      selectedHandTile: tile,
      selectedBoardRow: tile == null ? state.selectedBoardRow : null,
      selectedBoardCol: tile == null ? state.selectedBoardCol : null,
      revision: state.revision + 1,
    );
  }

  void setSelectedBoardCell(int? row, int? col) {
    state = state.copyWith(
      selectedBoardRow: row,
      selectedBoardCol: col,
      selectedHandTile: row == null && col == null ? state.selectedHandTile : null,
      revision: state.revision + 1,
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    state = state.copyWith(
      selectedJesterOverlayIndex: index,
      revision: state.revision + 1,
    );
  }

  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    state = state.copyWith(
      settlementBoardSnapshot: snapshot,
      revision: state.revision + 1,
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    state = state.copyWith(
      stageFlowPhase: phase,
      stageScoreAdded: stageScoreAdded,
      activeSettlementLine: activeSettlementLine,
      settlementBoardSnapshot: settlementBoardSnapshot,
      settlementSequenceTick: bumpSettlementSequence
          ? state.settlementSequenceTick + 1
          : state.settlementSequenceTick,
      revision: state.revision + 1,
    );
  }

  // -- Business logic --

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

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut() {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    final breakdown = runProgress.buildCashOutBreakdown(session);
    runProgress.applyCashOut(breakdown);
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
    state = state.copyWith(revision: state.revision + 1);
  }

  /// 다음 스테이지로 진입 처리.
  void advanceToNextStage(int runSeed) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    runProgress.advanceStage(session, runSeed: runSeed);
    clearSelections();
    state = state.copyWith(
      stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
        session: session,
        runProgress: runProgress,
      ),
      revision: state.revision + 1,
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
    state = state.copyWith(revision: state.revision + 1);
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
    state = state.copyWith(revision: state.revision + 1);
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
    state = state.copyWith(revision: state.revision + 1);
    return null;
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

  /// 장착 제스터 판매. 성공 시 true.
  bool sellOwnedJester(int index) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedJester(index);
    if (!ok) return false;
    final newIndex = runProgress.ownedJesters.isEmpty
        ? null
        : index.clamp(0, runProgress.ownedJesters.length - 1);
    state = state.copyWith(
      selectedJesterOverlayIndex: newIndex,
      revision: state.revision + 1,
    );
    return true;
  }

  /// 만료 신호 평가. 만료 시 신호 리스트 반환 (아니면 빈 리스트).
  List<RummiExpirySignal> evaluateExpiry() {
    final session = state.session;
    if (session == null) return const [];
    return session.evaluateExpirySignals();
  }

  /// 검사용 상점 열기 (특정 오퍼 ID 지정).
  void openShopForTest({
    required List<String> preferredOfferIds,
  }) {
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
    state = state.copyWith(revision: state.revision + 1);
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
