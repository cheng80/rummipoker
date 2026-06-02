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
    if (slot.item.effect.op == 'add_hand_rank_progress_from_selected_line' ||
        slot.item.effect.op == 'ritual_line_effect') {
      await _useScoringLineTargetItem(slot);
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

  Future<void> _useScoringLineTargetItem(RummiBattleItemSlotView slot) async {
    final session = _gameState.session;
    if (session == null) {
      _showSnack('세션이 없습니다.');
      return;
    }
    final isRitual = slot.item.effect.op == 'ritual_line_effect';
    final usesBoardLineSelection =
        isRitual ||
        slot.item.effect.op == 'add_hand_rank_progress_from_selected_line';
    final allLines = isRitual
        ? session.currentBoardLineSummaries()
        : session.currentScoringLineSummaries();
    final lines = isRitual
        ? _ritualSelectableLinesForItem(slot.item, allLines)
        : allLines;
    if (lines.isEmpty) {
      _showSnack(isRitual ? '선택할 보드 선이 없습니다.' : '선택할 완성 줄이 없습니다.');
      return;
    }
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    if (usesBoardLineSelection) {
      _startFateLineSelection(slot: slot, itemName: itemName, lines: lines);
      return;
    }
    final selected = await showDialog<RummiScoringLineSummary>(
      context: context,
      barrierDismissible: true,
      routeSettings: RouteSettings(name: isRitual ? '의식 보드 선 선택' : '의식 줄 선택'),
      builder: (context) {
        if (isRitual) {
          return _RitualBoardLineChoiceDialog(
            title: '$itemName 대상 선택',
            board: session.board,
            lines: lines,
            lineLabel: _lineChoiceLabel,
            rankLabel: _lineChoiceRankLabel,
          );
        }
        return AlertDialog(
          backgroundColor: GameUiPalette.surfaceModal,
          title: Text('$itemName 대상 선택'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in lines)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${_lineChoiceLabel(line.ref)} · ${_lineChoiceRankLabel(line)}',
                    ),
                    subtitle: Text(
                      line.isScoringLine
                          ? '칩 ${line.baseScore} · 타일 ${line.occupiedCount}'
                          : '미완성/무득점 · 타일 ${line.occupiedCount}',
                    ),
                    onTap: () => Navigator.of(context).pop(line),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
    if (!mounted || selected == null) return;

    int? tileIndex;
    Tile? selectedTile;
    final needsTileTarget = slot.item.effect.value('target') == 'tile';
    if (needsTileTarget) {
      tileIndex = await showDialog<int>(
        context: context,
        barrierDismissible: true,
        routeSettings: const RouteSettings(name: '의식 타일 선택'),
        builder: (context) => GameTileChoiceDialog(
          title: '$itemName 타일 선택',
          message: '선택한 줄 안에서 효과를 적용할 타일을 고릅니다.',
          tiles: selected.scoringTiles,
          closeLabel: '취소',
        ),
      );
      if (!mounted || tileIndex == null) return;
      selectedTile = selected.scoringTiles[tileIndex];
    }

    final failReason = slot.item.effect.op == 'ritual_line_effect'
        ? _gameNotifier.useBattleItemOnRitualTarget(
            slot.item,
            selected.ref,
            tileIndex: tileIndex,
          )
        : _gameNotifier.useBattleItemOnLine(slot.item, selected.ref);
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final targetLabel =
        '${_lineChoiceLabel(selected.ref)} ${_lineChoiceRankLabel(selected)}';
    _showSnack('$itemName 사용');
    _showItemEffectFeedback(
      title: itemName,
      detail: _scoringLineTargetFeedbackDetail(
        slot.item,
        targetLabel,
        selectedTile,
      ),
      sourceLabel: slot.slotLabel,
    );
    _mutate(() => _selectedBattleItemSlot = null);
    await _saveActiveRun();
  }

  void _startFateLineSelection({
    required RummiBattleItemSlotView slot,
    required String itemName,
    required List<RummiScoringLineSummary> lines,
  }) {
    _clearSelections();
    _mutate(() {
      _selectedBattleItemSlot = null;
      _fateLineSelection = _FateLineSelection(
        slot: slot,
        itemName: itemName,
        lines: lines,
      );
    });
    _showSnack(
      slot.item.effect.value('target') == 'tile'
          ? '보드에서 적용할 타일을 선택하세요.'
          : '보드에서 적용할 선을 선택하세요.',
    );
  }

  void _selectFateLine(RummiScoringLineSummary line) {
    final current = _fateLineSelection;
    if (current == null) return;
    _mutate(
      () => _fateLineSelection = current.copyWith(
        selectedLine: line,
        selectedTileIndex: current.needsTileTarget ? -1 : null,
      ),
    );
  }

  void _selectFateTile(GameBoardTileSelectionTarget target) {
    final current = _fateLineSelection;
    if (current == null) return;
    _mutate(
      () => _fateLineSelection = current.copyWith(
        selectedLine: target.line,
        selectedTileIndex: target.tileIndex,
      ),
    );
  }

  void _cancelFateLineSelection() {
    if (_fateLineSelection == null) return;
    _mutate(() => _fateLineSelection = null);
  }

  Future<void> _confirmFateLineSelection() async {
    final selection = _fateLineSelection;
    final selected = selection?.selectedLine;
    if (selection == null || selected == null) {
      _showSnack(
        selection?.needsTileTarget == true
            ? '적용할 보드 타일을 먼저 선택하세요.'
            : '적용할 보드 선을 먼저 선택하세요.',
      );
      return;
    }
    if (selection.needsTileTarget && selection.selectedTileIndex == null) {
      _showSnack('적용할 보드 타일을 먼저 선택하세요.');
      return;
    }
    final useResult = _gameNotifier.useBattleItemOnRitualTargetResult(
      selection.slot.item,
      selected.ref,
      tileIndex: selection.selectedTileIndex,
    );
    if (!useResult.isSuccess) {
      _showSnack(useResult.failMessage ?? '아이템을 사용할 수 없습니다.');
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _mutate(() {
      _fateLineSelection = null;
      _fateTransformFlashLineRef = selected.ref;
      _fateTransformFlashTick += 1;
    });
    _showSnack('${selection.itemName} 사용');
    final feedbackDetail = _scoringLineTargetFeedbackDetail(
      selection.slot.item,
      '${_lineChoiceLabel(selected.ref)} ${_lineChoiceRankLabel(selected)}',
      selection.selectedTile,
    );
    final feedbackDelay = _ritualFlightDurationForEvents(useResult.events);
    if (feedbackDelay == Duration.zero) {
      _showItemEffectFeedback(
        title: selection.itemName,
        detail: feedbackDetail,
        sourceLabel: selection.slot.slotLabel,
      );
    } else {
      unawaited(
        Future<void>.delayed(feedbackDelay, () {
          if (!mounted) return;
          _showItemEffectFeedback(
            title: selection.itemName,
            detail: feedbackDetail,
            sourceLabel: selection.slot.slotLabel,
          );
        }),
      );
    }
    _showRitualEffectFlight(useResult.events);
    final tick = _fateTransformFlashTick;
    unawaited(
      Future<void>.delayed(GamePresentationTimings.fateLineTransformFlash, () {
        if (!mounted || _fateTransformFlashTick != tick) return;
        _mutate(() => _fateTransformFlashLineRef = null);
      }),
    );
    await _saveActiveRun();
  }

  Duration _ritualFlightDurationForEvents(List<ItemEffectEvent> events) {
    if (events.any((event) => event.kind == ItemEffectEventKind.goldGained)) {
      return GamePresentationTimings.ritualGoldFlight;
    }
    if (events.any(
      (event) => event.kind == ItemEffectEventKind.deckTileAdded,
    )) {
      return GamePresentationTimings.ritualDeckTileFlight;
    }
    return Duration.zero;
  }

  void _showRitualEffectFlight(List<ItemEffectEvent> events) {
    final gold = events
        .where((event) => event.kind == ItemEffectEventKind.goldGained)
        .fold<int>(0, (sum, event) => sum + event.amount.round());
    final deckTiles = [
      for (final event in events)
        if (event.kind == ItemEffectEventKind.deckTileAdded)
          _tileFromEffectDetail(event.detail),
    ].nonNulls.toList(growable: false);
    if (gold <= 0 && deckTiles.isEmpty) return;
    final tick = _ritualEffectFlightTick + 1;
    _mutate(() {
      _ritualEffectFlightTick = tick;
      _ritualEffectFlight = gold > 0
          ? _RitualEffectFlight.gold(gold)
          : _RitualEffectFlight.deck(deckTiles);
    });
    final duration = gold > 0
        ? GamePresentationTimings.ritualGoldFlight
        : GamePresentationTimings.ritualDeckTileFlight;
    unawaited(
      Future<void>.delayed(duration, () {
        if (!mounted || _ritualEffectFlightTick != tick) return;
        _mutate(() => _ritualEffectFlight = null);
      }),
    );
  }

  List<RummiScoringLineSummary> _ritualSelectableLinesForItem(
    ItemDefinition item,
    List<RummiScoringLineSummary> lines,
  ) {
    final action = item.effect.value('ritualAction') as String? ?? '';
    bool hasSelectedTile(RummiScoringLineSummary line) =>
        line.scoringTiles.isNotEmpty;
    bool hasValidTileTarget(RummiScoringLineSummary line) {
      final maxCount = math.min(
        line.scoringTiles.length,
        line.contributingCells.length,
      );
      for (var i = 0; i < maxCount; i += 1) {
        if (_isValidRitualTileTarget(
          item,
          line,
          line.scoringTiles[i],
          line.contributingCells[i],
        )) {
          return true;
        }
      }
      return false;
    }

    bool hasCenterTile(RummiScoringLineSummary line) {
      final centerCell = line.ref.cells()[2];
      return line.contributingCells.any((cell) => cell == centerCell);
    }

    bool hasEndpointOrTile(RummiScoringLineSummary line) {
      final cells = line.ref.cells();
      return line.contributingCells.any(
            (cell) => cell == cells.first || cell == cells.last,
          ) ||
          hasSelectedTile(line);
    }

    return List<RummiScoringLineSummary>.unmodifiable([
      for (final line in lines)
        if (switch (action) {
          'growth' ||
          'center_growth' ||
          'growth_marker' ||
          'line_bonus_25' ||
          'line_bonus_35' => line.isScoringLine,
          'override_three_kind' ||
          'override_straight' ||
          'override_flush' ||
          'override_full_house' ||
          'override_four_kind' ||
          'override_five_kind' => line.occupiedCount >= 3,
          'fate_royal_flush' ||
          'fate_straight_flush_high' ||
          'fate_straight_flush_low' ||
          'fate_four_kind_high' ||
          'fate_four_kind_low' ||
          'fate_full_house_high' ||
          'fate_full_house_low' ||
          'fate_flush_house' ||
          'fate_flush_five' ||
          'fate_flush_high' ||
          'fate_flush_low' ||
          'fate_straight_high' ||
          'fate_straight_low' ||
          'fate_three_kind_high' ||
          'fate_three_kind_low' ||
          'fate_two_pair_high' => line.occupiedCount > 0,
          'copy_center' => hasCenterTile(line),
          'copy_endpoint' => hasEndpointOrTile(line),
          'copy_selected' ||
          'copy_rank' ||
          'copy_color' ||
          'prune_line_to_color' ||
          'growth_marker' => hasValidTileTarget(line),
          'seal_line_mark' ||
          'seal_growth' ||
          'seal_gold' ||
          'seal_echo' ||
          'seal_anchor' ||
          'seal_risk' ||
          'seal_bridge' ||
          'remove_same_tile' ||
          'remove_same_rank' => hasSelectedTile(line),
          'burn_line' => line.occupiedCount > 0,
          'sacrifice_line' => line.occupiedCount >= 2,
          _ => line.occupiedCount > 0,
        })
          line,
    ]);
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
      'add_hand_rank_progress_from_selected_line' => '선택 줄 족보 성장 +1',
      'ritual_line_effect' => _ritualActionLabel(
        item.effect.value('ritualAction'),
      ),
      'chips_bonus' => '다음 확정 칩 보너스',
      'mult_bonus' => '다음 확정 점수 +% 보너스',
      'xmult_bonus' => '다음 확정 점수 x 보너스',
      'temporary_overlap_cap_bonus' => '다음 확정 overlap 보너스',
      _ => '효과 적용',
    };
  }

  String _scoringLineTargetFeedbackDetail(
    ItemDefinition item,
    String targetLabel,
    Tile? tile,
  ) {
    if (item.effect.op != 'ritual_line_effect') {
      return '$targetLabel 성장 +${item.effect.value('amount') ?? 1}';
    }
    final tileLabel = tile == null ? '' : ' · ${tile.code}';
    return '$targetLabel$tileLabel · ${_ritualActionLabel(item.effect.value('ritualAction'))}';
  }

  String _ritualActionLabel(Object? actionValue) {
    return switch (actionValue?.toString()) {
      'growth' || 'center_growth' => '족보 성장',
      'growth_marker' => '교차 기억 표식',
      'copy_center' ||
      'copy_endpoint' ||
      'copy_selected' ||
      'copy_rank' ||
      'copy_color' => '덱 복제',
      'seal_line_mark' ||
      'seal_growth' ||
      'seal_gold' ||
      'seal_echo' ||
      'seal_anchor' ||
      'seal_risk' ||
      'seal_bridge' => '타일 봉인',
      'override_three_kind' ||
      'override_straight' ||
      'override_flush' ||
      'override_full_house' ||
      'override_four_kind' ||
      'override_five_kind' => '족보 강제 치환',
      'fate_royal_flush' => '로얄플러시 세트 변환',
      'fate_straight_flush_high' || 'fate_straight_flush_low' => '스티플 세트 변환',
      'fate_four_kind_high' || 'fate_four_kind_low' => '포카드 세트 변환',
      'fate_full_house_high' || 'fate_full_house_low' => '풀하우스 세트 변환',
      'fate_flush_house' => '플러시 하우스 세트 변환',
      'fate_flush_five' => '플러시 파이브 세트 변환',
      'fate_flush_high' || 'fate_flush_low' => '플러시 세트 변환',
      'fate_straight_high' || 'fate_straight_low' => '스트레이트 세트 변환',
      'fate_three_kind_high' || 'fate_three_kind_low' => '트리플 세트 변환',
      'fate_two_pair_high' => '투페어 세트 변환',
      'line_bonus_25' || 'line_bonus_35' => '선택 줄 보너스',
      'remove_same_tile' || 'remove_same_rank' => '덱 파괴',
      'prune_line_to_color' => '색 가지치기',
      'burn_line' => '줄 파괴',
      'sacrifice_line' => '줄 희생',
      _ => '의식 효과',
    };
  }

  String _lineChoiceLabel(LineRef ref) {
    return switch (ref.kind) {
      LineKind.row => '가로 ${ref.index + 1}',
      LineKind.col => '세로 ${ref.index + 1}',
      LineKind.diagMain => '대각 ↘',
      LineKind.diagAnti => '대각 ↙',
    };
  }

  String _lineChoiceRankLabel(RummiScoringLineSummary line) {
    if (!line.isScoringLine) return '미완성/무득점';
    return gameHandRankLabel(line.rank);
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

class _FateLineSelection {
  const _FateLineSelection({
    required this.slot,
    required this.itemName,
    required this.lines,
    this.selectedLine,
    this.selectedTileIndex,
  });

  final RummiBattleItemSlotView slot;
  final String itemName;
  final List<RummiScoringLineSummary> lines;
  final RummiScoringLineSummary? selectedLine;
  final int? selectedTileIndex;

  bool get needsTileTarget => slot.item.effect.value('target') == 'tile';

  Tile? get selectedTile {
    final line = selectedLine;
    final index = selectedTileIndex;
    if (line == null || index == null) return null;
    if (index < 0 || index >= line.scoringTiles.length) return null;
    return line.scoringTiles[index];
  }

  List<GameBoardTileSelectionTarget> get tileTargets {
    final targets = <GameBoardTileSelectionTarget>[];
    for (final line in lines) {
      final maxCount = math.min(
        line.scoringTiles.length,
        line.contributingCells.length,
      );
      for (var i = 0; i < maxCount; i += 1) {
        final tile = line.scoringTiles[i];
        final cell = line.contributingCells[i];
        if (!_isValidRitualTileTarget(slot.item, line, tile, cell)) continue;
        targets.add(
          GameBoardTileSelectionTarget(
            line: line,
            tileIndex: i,
            cell: cell,
            tile: tile,
          ),
        );
      }
    }
    return List<GameBoardTileSelectionTarget>.unmodifiable(targets);
  }

  _FateLineSelection copyWith({
    RummiScoringLineSummary? selectedLine,
    int? selectedTileIndex,
  }) {
    return _FateLineSelection(
      slot: slot,
      itemName: itemName,
      lines: lines,
      selectedLine: selectedLine ?? this.selectedLine,
      selectedTileIndex: selectedTileIndex == -1
          ? null
          : selectedTileIndex ?? this.selectedTileIndex,
    );
  }
}

class _FateLineSelectionPanel extends StatelessWidget {
  const _FateLineSelectionPanel({
    required this.selection,
    required this.onConfirm,
    required this.onCancel,
  });

  final _FateLineSelection selection;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final selectedLine = selection.selectedLine;
    final selectedTile = selection.selectedTile;
    final previewText = selectedLine == null
        ? selection.needsTileTarget
              ? '보드 위 파란 테두리 타일 후보를 직접 선택하세요.'
              : '보드 위 파란 테두리 줄 후보를 직접 선택하세요.'
        : _ritualSelectionPreviewText(
            selection.slot.item,
            selectedLine,
            selectedTile,
          );
    final targetText = selectedLine == null
        ? '선택 없음'
        : selection.needsTileTarget
        ? '${_lineLabel(selectedLine.ref)} · ${selectedTile?.code ?? '타일 선택 필요'}'
        : '${_lineLabel(selectedLine.ref)} · ${_rankLabel(selectedLine)} · 타일 ${selectedLine.occupiedCount}';
    final confirmEnabled =
        selectedLine != null &&
        (!selection.needsTileTarget || selectedTile != null);
    final confirmLabel = _isFateLineTransformDefinition(selection.slot.item)
        ? '변환'
        : '확인';
    final countText = selection.needsTileTarget
        ? '${selection.tileTargets.length}개 타일'
        : '${selection.lines.length}개 선';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceModalInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.userSelection.withValues(alpha: 0.72),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.34),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selection.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  countText,
                  style: const TextStyle(
                    color: GameUiPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              targetText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameUiPalette.userSelection,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 11.5,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('취소')),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: confirmEnabled ? onConfirm : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isValidRitualTileTarget(
  ItemDefinition item,
  RummiScoringLineSummary line,
  Tile tile,
  (int, int) cell,
) {
  return switch (item.effect.value('ritualAction')?.toString()) {
    'prune_line_to_color' => line.lineTiles.any(
      (candidate) => candidate.color != tile.color,
    ),
    'copy_selected' when item.id == 'sealed_copy' =>
      tile.seal != null || tile.enhancement != null,
    'copy_selected' when item.id == 'edge_copy' => _isLineEndpoint(
      line.ref,
      cell,
    ),
    _ => true,
  };
}

bool _isLineEndpoint(LineRef ref, (int, int) cell) {
  final cells = ref.cells();
  return cell == cells.first || cell == cells.last;
}

bool _isFateLineTransformDefinition(ItemDefinition item) {
  return switch (item.effect.value('ritualAction')?.toString()) {
    'fate_royal_flush' ||
    'fate_straight_flush_high' ||
    'fate_straight_flush_low' ||
    'fate_four_kind_high' ||
    'fate_four_kind_low' ||
    'fate_full_house_high' ||
    'fate_full_house_low' ||
    'fate_flush_house' ||
    'fate_flush_five' ||
    'fate_flush_high' ||
    'fate_flush_low' ||
    'fate_straight_high' ||
    'fate_straight_low' ||
    'fate_three_kind_high' ||
    'fate_three_kind_low' ||
    'fate_two_pair_high' => true,
    _ => false,
  };
}

String _ritualSelectionPreviewText(
  ItemDefinition item,
  RummiScoringLineSummary line,
  Tile? selectedTile,
) {
  final action = item.effect.value('ritualAction')?.toString();
  final centerCell = line.ref.cells()[2];
  final centerIndex = line.contributingCells.indexWhere(
    (cell) => cell == centerCell,
  );
  final centerTile = centerIndex >= 0 && centerIndex < line.scoringTiles.length
      ? line.scoringTiles[centerIndex]
      : null;
  final chosenTileText = selectedTile == null
      ? '선택한 점수 타일'
      : '${selectedTile.code} 점수 타일';
  final centerTileText = centerTile == null
      ? '중앙 점수 타일'
      : '${centerTile.code} 중앙 점수 타일';
  return switch (action) {
    'prune_line_to_color' =>
      selectedTile == null
          ? '선택 색이 아닌 타일을 제거하고 같은 색 타일을 덱 맨 위에 올립니다.'
          : '${_colorLabel(selectedTile.color)}기준: 다른 색 타일 제거 후 덱 위 보충.',
    'burn_line' => '선택한 줄을 지우고 골드 +3을 얻습니다.',
    'sacrifice_line' => '선택한 줄을 지우고 앞의 타일 2장을 덱 맨 위에 복사합니다.',
    'copy_center' => '$centerTileText 복사본을 덱 맨 위에 추가합니다.',
    'copy_selected' => '$chosenTileText 복사본을 덱 맨 위에 추가합니다.',
    'copy_color' => '$chosenTileText 색상과 같은 무작위 숫자 타일을 덱 맨 위에 추가합니다.',
    'copy_rank' => '$chosenTileText 숫자와 같은 무작위 색 타일을 덱 맨 위에 추가합니다.',
    'copy_endpoint' => '$chosenTileText 끝점 복사본을 덱 맨 위에 추가합니다.',
    'growth_marker' => '$chosenTileText에 교차 기억 표식을 붙입니다. 이후 겹친 줄 정산 시 추가 성장.',
    _ => _fateLinePreviewText(item, line),
  };
}

String _fateLinePreviewText(ItemDefinition item, RummiScoringLineSummary line) {
  final action = item.effect.value('ritualAction')?.toString();
  final high = _tileByNumberForPreview(line.lineTiles, preferHigh: true);
  final low = _tileByNumberForPreview(line.lineTiles, preferHigh: false);
  final royalAnchor = _royalAnchorTileForPreview(line.lineTiles);
  String tileText(Tile? tile) =>
      tile == null ? '기준 없음' : '${_colorLabel(tile.color)}${tile.number}';
  return switch (action) {
    'fate_royal_flush' =>
      '로얄 기준 ${tileText(royalAnchor)} 색상으로 10-11-12-13-1 로얄플러시 세트.',
    'fate_straight_flush_high' => '최고 기준 ${tileText(high)}에서 가능한 가장 높은 스티플 세트.',
    'fate_straight_flush_low' => '최저 기준 ${tileText(low)}에서 가능한 가장 낮은 스티플 세트.',
    'fate_four_kind_high' => '최고 숫자 ${high?.number ?? '-'} 포카드 세트.',
    'fate_four_kind_low' => '최저 숫자 ${low?.number ?? '-'} 포카드 세트.',
    'fate_full_house_high' => '최고 숫자 triple + 차순위 높은 숫자 pair 풀하우스 세트.',
    'fate_full_house_low' => '차순위 낮은 숫자 triple + 최고 숫자 pair 풀하우스 세트.',
    'fate_flush_house' => '최고 숫자 3장 + 차순위 높은 숫자 2장을 같은 색으로 만드는 플러시 하우스 세트.',
    'fate_flush_five' => '최고 숫자 5장을 같은 색으로 만드는 플러시 파이브 세트.',
    'fate_flush_high' => '최고 기준 ${tileText(high)} 색상 플러시 세트.',
    'fate_flush_low' => '최저 기준 ${tileText(low)} 색상 플러시 세트.',
    'fate_straight_high' => '최고 기준 ${tileText(high)}에서 가능한 높은 스트레이트 세트.',
    'fate_straight_low' => '최저 기준 ${tileText(low)}에서 가능한 낮은 스트레이트 세트.',
    'fate_three_kind_high' => '최고 숫자 ${high?.number ?? '-'} 트리플 세트.',
    'fate_three_kind_low' => '차순위 낮은 숫자 트리플 세트.',
    'fate_two_pair_high' => '최고/차순위 높은 숫자 투페어 세트.',
    _ => '선택한 보드 선을 운명 세트로 변환합니다.',
  };
}

Tile? _tileByNumberForPreview(List<Tile> tiles, {required bool preferHigh}) {
  if (tiles.isEmpty) return null;
  return tiles.reduce((a, b) {
    final compare = a.number.compareTo(b.number);
    if (compare == 0) return a;
    return preferHigh ? (compare > 0 ? a : b) : (compare < 0 ? a : b);
  });
}

Tile? _royalAnchorTileForPreview(List<Tile> tiles) {
  for (final tile in tiles) {
    if (tile.number == 1) return tile;
  }
  return _tileByNumberForPreview(tiles, preferHigh: true);
}

String _lineLabel(LineRef ref) {
  return switch (ref.kind) {
    LineKind.row => '가로 ${ref.index + 1}',
    LineKind.col => '세로 ${ref.index + 1}',
    LineKind.diagMain => '대각 ↘',
    LineKind.diagAnti => '대각 ↙',
  };
}

String _rankLabel(RummiScoringLineSummary line) {
  if (!line.isScoringLine) return '미완성/무득점';
  return switch (line.rank) {
    RummiHandRank.twoPair => '투페어',
    RummiHandRank.threeOfAKind => '트리플',
    RummiHandRank.straight => '스트레이트',
    RummiHandRank.flush => '플러시',
    RummiHandRank.fullHouse => '풀하우스',
    RummiHandRank.fourOfAKind => '포카드',
    RummiHandRank.straightFlush => '스티플',
    RummiHandRank.prismStraight => '프리즘 스트레이트',
    RummiHandRank.crownFourOfAKind => '왕관 포카드',
    RummiHandRank.lowStraightFlush => '로우 스티플',
    RummiHandRank.royalStraightFlush => '로얄 스티플',
    RummiHandRank.fiveOfAKind => '파이브카드',
    RummiHandRank.flushHouse => '플러시 하우스',
    RummiHandRank.flushFive => '플러시 파이브',
    RummiHandRank.highCard => '하이카드',
    RummiHandRank.onePair => '원페어',
  };
}

String _colorLabel(TileColor color) {
  return switch (color) {
    TileColor.red => '빨강 ',
    TileColor.blue => '파랑 ',
    TileColor.yellow => '노랑 ',
    TileColor.black => '검정 ',
  };
}

Tile? _tileFromEffectDetail(String? detail) {
  if (detail == null || detail.isEmpty) return null;
  final parts = detail.split(':');
  final code = parts.firstWhere(
    (part) =>
        part.length >= 2 &&
        const ['R', 'B', 'Y', 'K'].contains(part[0]) &&
        int.tryParse(part.substring(1).split('#').first) != null,
    orElse: () => '',
  );
  if (code.length < 2) return null;
  final color = switch (code[0]) {
    'R' => TileColor.red,
    'B' => TileColor.blue,
    'Y' => TileColor.yellow,
    'K' => TileColor.black,
    _ => null,
  };
  if (color == null) return null;
  final number = int.tryParse(code.substring(1).split('#').first);
  if (number == null || number < 1 || number > 13) return null;
  String? valueFor(String key) {
    final prefix = '$key=';
    for (final part in parts) {
      if (part.startsWith(prefix)) return part.substring(prefix.length);
    }
    return null;
  }

  return Tile(
    color: color,
    number: number,
    enhancement: TileEnhancement.fromPersistenceValue(valueFor('enhancement')),
    seal: TileSeal.fromPersistenceValue(valueFor('seal')),
    edition: TileEdition.fromPersistenceValue(valueFor('edition')),
  );
}

class _RitualBoardLineChoiceDialog extends StatefulWidget {
  const _RitualBoardLineChoiceDialog({
    required this.title,
    required this.board,
    required this.lines,
    required this.lineLabel,
    required this.rankLabel,
  });

  final String title;
  final RummiBoard board;
  final List<RummiScoringLineSummary> lines;
  final String Function(LineRef ref) lineLabel;
  final String Function(RummiScoringLineSummary line) rankLabel;

  @override
  State<_RitualBoardLineChoiceDialog> createState() =>
      _RitualBoardLineChoiceDialogState();
}

class _RitualBoardLineChoiceDialogState
    extends State<_RitualBoardLineChoiceDialog> {
  RummiScoringLineSummary? _selectedLine;

  void _selectLine(RummiScoringLineSummary line) {
    setState(() => _selectedLine = line);
  }

  void _confirmSelection() {
    final selectedLine = _selectedLine;
    if (selectedLine == null) return;
    Navigator.of(context).pop(selectedLine);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameUiPalette.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kPhoneFrameRefW - 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiPalette.surfaceModalInner.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameUiPalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '보드 선을 선택합니다. 미완성/무득점 선도 효과에 따라 사용할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameUiPalette.textSecondary,
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 238,
                    height: 238,
                    child: _RitualBoardLinePreview(
                      board: widget.board,
                      lines: widget.lines,
                      selectedLine: _selectedLine,
                      onLineSelected: _selectLine,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 190),
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final line in widget.lines)
                          _RitualLineChoiceChip(
                            line: line,
                            selected: line.ref == _selectedLine?.ref,
                            label: widget.lineLabel(line.ref),
                            rankText: widget.rankLabel(line),
                            onTap: () => _selectLine(line),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _selectedLine == null
                          ? null
                          : _confirmSelection,
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualBoardLinePreview extends StatelessWidget {
  const _RitualBoardLinePreview({
    required this.board,
    required this.lines,
    required this.selectedLine,
    required this.onLineSelected,
  });

  final RummiBoard board;
  final List<RummiScoringLineSummary> lines;
  final RummiScoringLineSummary? selectedLine;
  final ValueChanged<RummiScoringLineSummary> onLineSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        RummiScoringLineSummary? lineAt(Offset localPosition) {
          final metric = _RitualLinePreviewMetric(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          RummiScoringLineSummary? closestLine;
          var closestDistance = double.infinity;
          for (final line in lines) {
            final cells = line.ref.cells();
            final start = metric.centerFor(cells.first.$1, cells.first.$2);
            final end = metric.centerFor(cells.last.$1, cells.last.$2);
            final distance = _distanceToSegment(localPosition, start, end);
            if (distance < closestDistance) {
              closestDistance = distance;
              closestLine = line;
            }
          }
          return closestDistance <= 18 ? closestLine : null;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final line = lineAt(details.localPosition);
            if (line == null) return;
            onLineSelected(line);
          },
          child: CustomPaint(
            foregroundPainter: _RitualLinePreviewPainter(
              lines,
              selectedLine: selectedLine,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiPalette.surfacePanel.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kBoardSize,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: kBoardSize * kBoardSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ kBoardSize;
                    final col = index % kBoardSize;
                    return _RitualBoardMiniCell(tile: board.cellAt(row, col));
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RitualBoardMiniCell extends StatelessWidget {
  const _RitualBoardMiniCell({required this.tile});

  final Tile? tile;

  @override
  Widget build(BuildContext context) {
    final tile = this.tile;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tile == null
            ? GameUiPalette.ink.withValues(alpha: 0.52)
            : GameUiPalette.cardArtSurface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: tile == null
              ? GameUiPalette.textPrimary.withValues(alpha: 0.08)
              : _ritualTileColor(tile.color).withValues(alpha: 0.9),
          width: tile == null ? 1 : 1.4,
        ),
      ),
      child: tile == null
          ? null
          : Center(
              child: Text(
                '${tile.number}',
                style: TextStyle(
                  color: _ritualTileColor(tile.color),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
    );
  }
}

class _RitualLineChoiceChip extends StatelessWidget {
  const _RitualLineChoiceChip({
    required this.line,
    required this.label,
    required this.rankText,
    required this.selected,
    required this.onTap,
  });

  final RummiScoringLineSummary line;
  final String label;
  final String rankText;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = line.isScoringLine
        ? GameUiPalette.actionGold
        : GameUiPalette.tileBlueSeal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? GameUiPalette.userSelection.withValues(alpha: 0.24)
              : Color.lerp(GameUiPalette.ink, color, 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? GameUiPalette.userSelection : color,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            '$label · $rankText · ${line.occupiedCount}',
            style: const TextStyle(
              color: GameUiPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualLinePreviewPainter extends CustomPainter {
  const _RitualLinePreviewPainter(this.lines, {required this.selectedLine});

  final List<RummiScoringLineSummary> lines;
  final RummiScoringLineSummary? selectedLine;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _RitualLinePreviewMetric(size);

    for (final line in lines) {
      final cells = line.ref.cells();
      final start = metric.centerFor(cells.first.$1, cells.first.$2);
      final end = metric.centerFor(cells.last.$1, cells.last.$2);
      final selected = line.ref == selectedLine?.ref;
      final color = line.isScoringLine
          ? GameUiPalette.actionGold
          : GameUiPalette.tileBlueSeal;
      final paint = Paint()
        ..color = selected
            ? GameUiPalette.userSelection.withValues(alpha: 0.88)
            : color.withValues(alpha: line.isScoringLine ? 0.52 : 0.38)
        ..strokeWidth = selected
            ? 9
            : line.isScoringLine
            ? 7
            : 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RitualLinePreviewPainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.selectedLine?.ref != selectedLine?.ref;
  }
}

class _RitualLinePreviewMetric {
  const _RitualLinePreviewMetric(this.size);

  final Size size;

  static const double _inset = 10;
  static const double _gap = 3;

  double get _gridSide => size.shortestSide - _inset * 2;
  double get _cellSide => (_gridSide - _gap * (kBoardSize - 1)) / kBoardSize;

  Offset centerFor(int row, int col) {
    return Offset(
      _inset + col * (_cellSide + _gap) + _cellSide / 2,
      _inset + row * (_cellSide + _gap) + _cellSide / 2,
    );
  }
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return (point - start).distance;
  final t =
      (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
      lengthSquared;
  final clamped = t.clamp(0.0, 1.0);
  final projection = Offset(start.dx + dx * clamped, start.dy + dy * clamped);
  return (point - projection).distance;
}

Color _ritualTileColor(TileColor color) {
  return switch (color) {
    TileColor.red => GameUiPalette.tileRed,
    TileColor.blue => GameUiPalette.tileBlue,
    TileColor.yellow => GameUiPalette.tileYellow,
    TileColor.black => GameUiPalette.tileBlack,
  };
}
