part of 'game_session_notifier.dart';

mixin GameSessionNotifierBattleCommands
    on FamilyNotifier<GameSessionState, GameSessionArgs> {
  void _replaceState(GameSessionState next);
  void clearSelections();
  void setSelectedBoardCell(int? row, int? col);
  void setSettlementBoardSnapshot(Map<String, Tile> snapshot);
  GameSessionState withValidSelections(GameSessionState current);

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

  /// 보드 스냅샷을 캡처하고 모든 완성 줄을 확정한다.
  ExpiryGuardResult? applyExpiryGuard({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null || itemCatalog == null) {
      return null;
    }
    if (session.blind.scoreTowardBlind >= session.blind.targetScore) {
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
    _replaceState(
      withValidSelections(state).copyWith(revision: state.revision + 1),
    );
    return null;
  }

  String? useBattleItemOnLine(ItemDefinition item, LineRef lineRef) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) return '세션이 없습니다.';

    final result = ItemEffectRuntime.useBattleItemOnLine(
      item: item,
      session: session,
      runProgress: runProgress,
      lineRef: lineRef,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(
      withValidSelections(state).copyWith(revision: state.revision + 1),
    );
    return null;
  }

  String? useBattleItemOnRitualTarget(
    ItemDefinition item,
    LineRef lineRef, {
    int? tileIndex,
  }) {
    final result = useBattleItemOnRitualTargetResult(
      item,
      lineRef,
      tileIndex: tileIndex,
    );
    return result.isSuccess ? null : result.failMessage;
  }

  ItemUseResult useBattleItemOnRitualTargetResult(
    ItemDefinition item,
    LineRef lineRef, {
    int? tileIndex,
  }) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return ItemUseResult.failure(itemId: item.id, message: '세션이 없습니다.');
    }

    final result = ItemEffectRuntime.useBattleItemOnRitualTarget(
      item: item,
      session: session,
      runProgress: runProgress,
      lineRef: lineRef,
      tileIndex: tileIndex,
    );
    if (!result.isSuccess) return result;
    _replaceState(
      withValidSelections(state).copyWith(revision: state.revision + 1),
    );
    return result;
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

  /// 만료 신호 평가. 만료 시 신호 리스트 반환 (아니면 빈 리스트).
  List<RummiExpirySignal> evaluateExpiry() {
    final session = state.session;
    if (session == null) return const [];
    return session.evaluateExpirySignals();
  }
}
