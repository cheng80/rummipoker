part of '../game_view.dart';

extension _GameViewBattleActions on _GameViewState {
  Future<bool> _afterAction() async {
    if (_stageFlowPhase != GameStageFlowPhase.none ||
        _stationView.objective.isMet) {
      return false;
    }
    if (await _tryApplyExpiryGuard()) {
      return false;
    }
    final signals = _gameNotifier.evaluateExpiry();
    if (signals.isEmpty) return false;
    _persistRetrySnapshotOnSave = true;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    if (!mounted) return true;
    _showGameOver(signals);
    return true;
  }

  Future<bool> _tryApplyExpiryGuard() async {
    if (_stageFlowPhase != GameStageFlowPhase.none ||
        _stationView.objective.isMet) {
      return false;
    }
    final guardResult = _gameNotifier.applyExpiryGuard(
      itemCatalog: _itemCatalog,
    );
    if (guardResult == null) return false;
    _showSnack(guardResult.message);
    _showItemEffectFeedback(
      title: '안전망 발동',
      detail: guardResult.feedbackDetail,
      passive: true,
    );
    await _saveActiveRun(scene: ActiveRunScene.battle);
    return true;
  }

  void _clearSelections() {
    _mutate(() {
      _boardMoveMode = false;
      _pendingBoardMoveSourceRow = null;
      _pendingBoardMoveSourceCol = null;
    });
    _gameNotifier.clearSelections();
  }

  void _openJesterOverlay(int index) {
    if (_isBattleInputLocked) return;
    _mutate(() {
      _selectedBattleItemSlot = null;
      _selectedHandInfoTile = null;
    });
    _gameNotifier.setSelectedJesterOverlayIndex(index);
  }

  void _closeJesterOverlay() {
    if (!mounted) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
  }

  void _sellOwnedJesterFromOverlay() {
    final ok = _gameNotifier.sellSelectedJesterOverlayFromState();
    if (!ok) return;
    _showSnack('제스터를 판매했습니다.');
  }

  void _openBattleItemOverlay(RummiBattleItemSlotView slot) {
    if (_isBattleInputLocked) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
    _mutate(() {
      _selectedBattleItemSlot = slot;
      _selectedHandInfoTile = null;
    });
  }

  void _closeBattleItemOverlay() {
    if (!mounted) return;
    _mutate(() => _selectedBattleItemSlot = null);
  }

  void _toggleHandTile(Tile tile) {
    if (_isBattleInputLocked) return;
    _gameNotifier.toggleSelectedHandTile(tile);
  }

  void _openHandTileInfoOverlay(Tile tile) {
    if (_isBattleInputLocked) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
    _mutate(() {
      _selectedBattleItemSlot = null;
      _selectedHandInfoTile = tile;
    });
  }

  void _closeHandTileInfoOverlay() {
    if (!mounted) return;
    _mutate(() => _selectedHandInfoTile = null);
  }

  Future<void> _goToTitleAfterStoppingBgm() async {
    _resumePresentation();
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  void _onBoardCellTap(int row, int col) async {
    if (_isUiLocked) return;
    if (_boardMoveMode) {
      await _handleBoardMoveModeTap(row, col);
      return;
    }
    final result = _gameNotifier.tapBoardCell(row, col);
    if (result.failMessage != null) {
      _showSnack(result.failMessage!);
      return;
    }
    if (result.didPlaceTile) {
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      await _saveActiveRun();
    }
  }

  void _drawTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.drawTile();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedBoardTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedBoardTileFromState();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedHandTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedHandTileFromState();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _useBattleItem(RummiBattleItemSlotView slot) async {
    if (_isBattleInputLocked) return;
    if (slot.item.effect.op == 'peek_deck_discard_one') {
      await _useDeckNeedleItem(slot);
      return;
    }
    final undoReturnCell = slot.item.effect.op == 'undo_last_board_move'
        ? _gameState.session?.boardMoveHistory.lastOrNull
        : null;
    final failReason = _gameNotifier.useBattleItem(slot.item);
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    _showSnack('$itemName 사용');
    _showItemEffectFeedback(
      title: itemName,
      detail: _battleItemFeedbackDetail(slot.item),
      sourceLabel: slot.slotLabel,
    );
    if (undoReturnCell != null) {
      _showBoardMoveBonusFlash(
        row: undoReturnCell.fromRow,
        col: undoReturnCell.fromCol,
      );
    }
    if (mounted) {
      _mutate(() => _selectedBattleItemSlot = null);
    }
    await _saveActiveRun();
  }

  Future<void> _useDeckNeedleItem(RummiBattleItemSlotView slot) async {
    final useResult = _gameNotifier.consumeBattleDeckPeekItem(slot.item);
    if (!useResult.isSuccess) {
      _showSnack(useResult.failMessage ?? '아이템을 사용할 수 없습니다.');
      return;
    }
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    if (mounted) {
      _mutate(() => _selectedBattleItemSlot = null);
    }
    await _saveActiveRun();
    if (!mounted) return;

    final selectedIndex = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '덱 확인',
      routeSettings: const RouteSettings(name: '덱 확인'),
      builder: (context) => GameTileChoiceDialog(
        title: '덱 확인',
        message: '덱 위 3장 중 버릴 타일을 선택합니다.',
        tiles: useResult.candidates,
        closeLabel: '닫기',
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (selectedIndex == null) {
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      _showSnack('$itemName 사용');
      _showItemEffectFeedback(
        title: itemName,
        detail: '덱 확인',
        sourceLabel: slot.slotLabel,
      );
      return;
    }

    final selectedTile = useResult.candidates[selectedIndex];
    final failReason = _gameNotifier.useBattleDeckPeekDiscardItem(
      slot.item,
      selectedIndex,
    );
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _showSnack('${selectedTile.code} 제거');
    _showItemEffectFeedback(
      title: itemName,
      detail: '${selectedTile.code} 제거',
      sourceLabel: slot.slotLabel,
    );
    await _saveActiveRun();
  }

  String _battleItemFeedbackDetail(ItemDefinition item) {
    return switch (item.effect.op) {
      'add_board_discard' => '보드 버림 +${item.effect.value('amount') ?? 1}',
      'add_hand_discard' => '손패 버림 +${item.effect.value('amount') ?? 1}',
      'add_board_move' => '타일 이동 +${item.effect.value('amount') ?? 1}',
      'mark_next_board_move_bonus' => '다음 보드 이동 보너스 준비',
      'undo_last_board_move' => '마지막 이동 되돌림',
      'draw_if_hand_empty' => '타일 1장 드로우',
      'increase_hand_size' => '손패 최대치 +${item.effect.value('amount') ?? 1}',
      'add_hand_rank_progress_from_best_line' => '완성 줄 족보 성장 +1',
      'chips_bonus' => '다음 확정 칩 보너스',
      'mult_bonus' => '다음 확정 점수 +% 보너스',
      'xmult_bonus' => '다음 확정 점수 x 보너스',
      'temporary_overlap_cap_bonus' => '다음 확정 overlap 보너스',
      _ => '효과 적용',
    };
  }

  void _confirmLines() async {
    if (_isBattleInputLocked) return;
    final result = _gameNotifier.confirmLines();
    if (result == null) {
      if (await _tryApplyExpiryGuard()) return;
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      _showSnack('확정할 족보 줄이 없습니다.');
      return;
    }
    final settlementGoalBaseScore = _stationView.objective.scoreTowardObjective;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.confirmSettlement,
      activeSettlementLine: null,
      activeSettlementStep: ScoringPresentationStep.none,
      activeSettlementEffectIndex: null,
      settlementGoalDisplayScore: settlementGoalBaseScore,
    );
    _gameNotifier.applyConfirmedScore(result.totalScore);
    await _saveActiveRun(scene: ActiveRunScene.battle);
    if (!mounted) return;

    await _runSettlementSequence(
      lines: result.lineBreakdowns,
      totalScore: result.totalScore,
      shouldClearAfter: result.stageCleared,
      settlementGoalBaseScore: settlementGoalBaseScore,
    );
    if (result.stageCleared) {
      return;
    }
    await _afterAction();
  }

  void _startBoardMoveMode() {
    if (_isUiLocked) return;
    final row = _selectedBoardRow;
    final col = _selectedBoardCol;
    if (row == null || col == null) {
      _showSnack('이동할 보드 타일을 먼저 선택하세요.');
      return;
    }
    if (_stationView.resources.boardMovesRemaining <= 0) {
      _showSnack('보드 이동 횟수가 없습니다.');
      return;
    }
    _mutate(() {
      _selectedBattleItemSlot = null;
      _boardMoveMode = true;
      _pendingBoardMoveSourceRow = row;
      _pendingBoardMoveSourceCol = col;
    });
  }

  void _cancelBoardMoveMode() {
    if (!mounted) return;
    _mutate(() {
      _boardMoveMode = false;
      _pendingBoardMoveSourceRow = null;
      _pendingBoardMoveSourceCol = null;
    });
  }

  Future<void> _handleBoardMoveModeTap(int row, int col) async {
    final fromRow = _pendingBoardMoveSourceRow;
    final fromCol = _pendingBoardMoveSourceCol;
    if (fromRow == null || fromCol == null) {
      _cancelBoardMoveMode();
      return;
    }
    if (row == fromRow && col == fromCol) {
      _cancelBoardMoveMode();
      return;
    }
    if (_battleView.board.cellAt(row, col) != null) {
      _showSnack('빈 칸으로만 이동할 수 있습니다.');
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: '보드 이동',
      message: '선택한 타일을 빈 칸으로 이동합니다.\n이동 횟수 1회를 사용합니다.',
      cancelLabel: '취소',
      confirmLabel: '이동',
      barrierDismissible: false,
    );
    if (!confirmed || !mounted) return;

    final hadSlideBonus =
        _gameState.session?.nextBoardMoveSlideBonusQueued ?? false;
    final failReason = _gameNotifier.moveBoardTile(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: row,
      toCol: col,
    );
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    _cancelBoardMoveMode();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _showSnack(hadSlideBonus ? '보드 이동 보너스가 발동했습니다.' : '타일을 이동했습니다.');
    if (hadSlideBonus) {
      _showBoardMoveBonusFlash(row: row, col: col);
      _showItemEffectFeedback(title: '슬라이드 왁스', detail: '이동 보너스 발동');
    }
    await _saveActiveRun();
  }

  void _showBoardMoveBonusFlash({required int row, required int col}) {
    if (!mounted) return;
    final tick = _boardMoveBonusFlashTick + 1;
    _mutate(() {
      _boardMoveBonusFlashTick = tick;
      _boardMoveBonusTargetCellKey = '$row:$col';
    });
    unawaited(
      Future<void>.delayed(GamePresentationTimings.boardMoveBonusFlash, () {
        if (!mounted || _boardMoveBonusFlashTick != tick) return;
        _mutate(() => _boardMoveBonusTargetCellKey = null);
      }),
    );
  }
}
