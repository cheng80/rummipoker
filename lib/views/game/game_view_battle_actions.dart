part of '../game_view.dart';

extension _GameViewBattleActions on _GameViewState {
  GameAnalyticsContext get _gameAnalyticsContext => GameAnalyticsContext(
    debugFixture:
        _isDebugFixtureRun ||
        widget.autoAdvanceMarketOnLoad ||
        widget.autoEnterMarketOnCashOut ||
        widget.autoCashOutLoopOnLoad ||
        widget.debugCompleteRunOnClear ||
        widget.debugCompleteRunOnLoad ||
        widget.debugAutoUseItemId != null ||
        widget.debugStartItemShop ||
        widget.debugShowGameOverOnLoad ||
        widget.debugOpenRunInfoOnLoad,
  );

  Map<String, Object> _battleAnalyticsBaseParams() {
    final battle = _battleView;
    final station = _stationView;
    return {
      'difficulty': widget.difficulty.name,
      'modifier': widget.runModifier.id,
      'station_index': battle.stageIndex,
      'blind_tier': widget.blindTier.name,
      'target_score': station.objective.targetScore,
      'score': station.objective.scoreTowardObjective,
      'deck_remaining': station.resources.drawPileRemaining,
      'hand_count': battle.hand.length,
      'board_tiles': battle.board.snapshotCells().nonNulls.length,
    };
  }

  void _logBattleAction(
    String action, {
    Map<String, Object?> parameters = const {},
  }) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'battle_action',
        parameters: {
          ..._battleAnalyticsBaseParams(),
          'action': action,
          ...parameters,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logBattleActionFail(
    String action,
    String reason, {
    Map<String, Object?> parameters = const {},
  }) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'battle_action_fail',
        parameters: {
          ..._battleAnalyticsBaseParams(),
          'action': action,
          'fail_reason': reason,
          ...parameters,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

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
    await _startGameOverSequence(signals);
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
    _showSnack(
      guardResult.message,
      messageBuilder: (context) =>
          expiryGuardLabel(context, guardResult.events),
    );
    _showItemEffectFeedback(
      title: context.translate('battleSafetyNet'),
      titleBuilder: (context) => context.translate('battleSafetyNet'),
      detail: guardResult.feedbackDetail,
      detailBuilder: (context) =>
          expiryGuardLabel(context, guardResult.events, detail: true),
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
    final slotIndex = _selectedJesterOverlayIndex;
    final ok = _gameNotifier.sellSelectedJesterOverlayFromState();
    if (!ok) return;
    GameFeedback.play(GameCue.sell);
    if (slotIndex != null) _emitJesterSaleBurst(slotIndex);
    _showSnack(context.translate('battleJesterSold'), silent: true);
  }

  /// 상점 판매처럼 팔린 슬롯에서 카드 조각과 코인이 튄다.
  void _emitJesterSaleBurst(int slotIndex) {
    final zoneContext = _battleJesterZoneKey.currentContext;
    final box = zoneContext?.findRenderObject() as RenderBox?;
    if (zoneContext == null || box == null || !box.hasSize) return;
    // GameJesterZone: 좌우 패딩 10, 슬롯 5칸 spaceEvenly.
    const slotCount = 5;
    const padding = 10.0;
    final inner = box.size.width - padding * 2;
    final gap = (inner - kBattleItemSlotWidth * slotCount) / (slotCount + 1);
    final center = Offset(
      padding +
          gap * (slotIndex + 1) +
          kBattleItemSlotWidth * (slotIndex + 0.5),
      box.size.height / 2,
    );
    Fx.emit(zoneContext, FxPresets.shards, [center]);
    Fx.emit(zoneContext, FxPresets.coins, [center]);
    ScreenShake.instance.add(0.15);
  }

  /// 거절 입구. 알림 문구는 그대로 두고 흔들림·오류음·error 햅틱을 더한다.
  void _denyBattleAction(
    String message, {
    required _BattleDenyTarget target,
    ActionFailure? failure,
  }) {
    GameFeedback.play(GameCue.deny);
    _mutate(() {
      _battleDenyTarget = target;
      _battleDenyTick++;
    });
    _showSnack(
      message,
      silent: true,
      messageBuilder: failure == null
          ? null
          : (context) => actionFailureLabel(context, failure),
    );
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
    final selecting = _selectedHandTile != tile;
    _gameNotifier.toggleSelectedHandTile(tile);
    GameFeedback.play(GameCue.tileSelect, pitch: selecting ? 1 : 0.85);
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
    await WidgetsBinding.instance.endOfFrame;
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
      _logBattleActionFail(
        'board_place',
        result.failure?.reason?.name ?? 'denied',
        parameters: {'row': row, 'col': col},
      );
      _denyBattleAction(
        result.failMessage!,
        failure: result.failure,
        target: _BattleDenyTarget.board,
      );
      return;
    }
    if (result.didPlaceTile) {
      _logBattleAction('board_place', parameters: {'row': row, 'col': col});
      GameFeedback.play(GameCue.tilePlace);
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      await _saveActiveRun();
    }
  }

  void _drawTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.drawTileFailure();
    if (failReason != null) {
      _logBattleActionFail('draw', failReason.reason?.name ?? 'denied');
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.hand,
      );
      return;
    }
    _logBattleAction('draw');
    GameFeedback.play(GameCue.tileDraw);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedBoardTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedBoardTileFromStateFailure();
    if (failReason != null) {
      _logBattleActionFail(
        'board_discard',
        failReason.reason?.name ?? 'denied',
      );
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.actions,
      );
      return;
    }
    _logBattleAction('board_discard');
    GameFeedback.play(GameCue.discard);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedHandTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedHandTileFromStateFailure();
    if (failReason != null) {
      _logBattleActionFail('hand_discard', failReason.reason?.name ?? 'denied');
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.actions,
      );
      return;
    }
    _logBattleAction('hand_discard');
    GameFeedback.play(GameCue.discard, pitch: 1.15);
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
    final failReason = _gameNotifier.useBattleItemFailure(slot.item);
    if (failReason != null) {
      _logBattleActionFail(
        'battle_item_use',
        failReason.reason?.name ?? 'denied',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.slots,
      );
      return;
    }
    _logBattleAction(
      'battle_item_use',
      parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
    );
    GameFeedback.play(GameCue.itemUse);
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    _showSnack(
      context.translate('battleItemUsed', namedArgs: {'item': itemName}),
      silent: true,
    );
    _showItemEffectFeedback(
      title: itemName,
      titleBuilder: (context) => ItemTranslationScope.of(
        context,
      ).resolveDisplayName(slot.contentId, slot.displayName),
      detailBuilder: (context) =>
          _battleItemFeedbackDetail(slot.item, feedbackContext: context),
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
      _showSnack(context.translate('battleNoSession'));
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
      _logBattleActionFail(
        'targeted_item_use',
        'no_target_lines',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      _denyBattleAction(
        isRitual
            ? context.translate('battleNoBoardLines')
            : context.translate('battleNoCompleteLines'),
        target: _BattleDenyTarget.slots,
      );
      return;
    }
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    if (usesBoardLineSelection) {
      _startFateLineSelection(slot: slot, lines: lines);
      return;
    }
    final selected = await showDialog<RummiScoringLineSummary>(
      context: context,
      barrierDismissible: true,
      routeSettings: RouteSettings(
        name: isRitual ? 'ritual-board-line-choice' : 'ritual-line-choice',
      ),
      builder: (context) {
        if (isRitual) {
          return _RitualBoardLineChoiceDialog(
            title: context.translate(
              'battleChooseItemTarget',
              namedArgs: {'item': itemName},
            ),
            board: session.board,
            lines: lines,
            lineLabel: _lineChoiceLabel,
            rankLabel: _lineChoiceRankLabel,
          );
        }
        return AlertDialog(
          backgroundColor: GameUiPalette.surfaceModal,
          title: Text(
            context.translate(
              'battleChooseItemTarget',
              namedArgs: {'item': itemName},
            ),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in lines)
                  ListTile(
                    dense: true,
                    title: Text(
                      context.translate(
                        'battleLineRankLabel',
                        namedArgs: {
                          'line': _lineChoiceLabel(line.ref),
                          'rank': _lineChoiceRankLabel(line),
                        },
                      ),
                    ),
                    subtitle: Text(
                      line.isScoringLine
                          ? context.translate(
                              'battleLineChipsTiles',
                              namedArgs: {
                                'chips': '${line.baseScore}',
                                'count': '${line.occupiedCount}',
                              },
                            )
                          : context.translate(
                              'battleIncompleteTiles',
                              namedArgs: {'count': '${line.occupiedCount}'},
                            ),
                    ),
                    onTap: () => Navigator.of(context).pop(line),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.translate('cancel')),
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
        routeSettings: const RouteSettings(name: 'ritual-tile-choice'),
        builder: (context) => GameTileChoiceDialog(
          title: context.translate(
            'battleChooseItemTile',
            namedArgs: {'item': itemName},
          ),
          message: context.translate('battleRitualTilePrompt'),
          tiles: selected.scoringTiles,
          closeLabel: context.translate('cancel'),
        ),
      );
      if (!mounted || tileIndex == null) return;
      selectedTile = selected.scoringTiles[tileIndex];
    }

    final failReason = slot.item.effect.op == 'ritual_line_effect'
        ? _gameNotifier.useBattleItemOnRitualTargetFailure(
            slot.item,
            selected.ref,
            tileIndex: tileIndex,
          )
        : _gameNotifier.useBattleItemOnLineFailure(slot.item, selected.ref);
    if (failReason != null) {
      _logBattleActionFail(
        'targeted_item_use',
        failReason.reason?.name ?? 'denied',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.slots,
      );
      return;
    }
    _logBattleAction(
      'targeted_item_use',
      parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
    );
    GameFeedback.play(GameCue.itemUse);
    _showSnack(
      context.translate('battleItemUsed', namedArgs: {'item': itemName}),
      silent: true,
    );
    _showItemEffectFeedback(
      title: itemName,
      titleBuilder: (context) => ItemTranslationScope.of(
        context,
      ).resolveDisplayName(slot.contentId, slot.displayName),
      detailBuilder: (context) => _scoringLineTargetFeedbackDetail(
        slot.item,
        selected,
        selectedTile,
        feedbackContext: context,
      ),
      detail: _scoringLineTargetFeedbackDetail(
        slot.item,
        selected,
        selectedTile,
      ),
      sourceLabel: slot.slotLabel,
    );
    _mutate(() => _selectedBattleItemSlot = null);
    await _saveActiveRun();
  }

  void _startFateLineSelection({
    required RummiBattleItemSlotView slot,
    required List<RummiScoringLineSummary> lines,
  }) {
    _clearSelections();
    _mutate(() {
      _selectedBattleItemSlot = null;
      _fateLineSelection = _FateLineSelection(slot: slot, lines: lines);
    });
    _showSnack(
      slot.item.effect.value('target') == 'tile'
          ? context.translate('battleSelectBoardTile')
          : context.translate('battleSelectBoardLine'),
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
      _denyBattleAction(
        selection?.needsTileTarget == true
            ? context.translate('battleSelectTileFirst')
            : context.translate('battleSelectLineFirst'),
        target: _BattleDenyTarget.board,
      );
      return;
    }
    if (selection.needsTileTarget && selection.selectedTileIndex == null) {
      _denyBattleAction(
        context.translate('battleSelectTileFirst'),
        target: _BattleDenyTarget.board,
      );
      return;
    }
    final useResult = _gameNotifier.useBattleItemOnRitualTargetResult(
      selection.slot.item,
      selected.ref,
      tileIndex: selection.selectedTileIndex,
    );
    if (!useResult.isSuccess) {
      _logBattleActionFail(
        'targeted_item_use',
        useResult.failure?.reason?.name ?? 'item_use_failed',
        parameters: {
          'item_id': selection.slot.contentId,
          'item_op': selection.slot.item.effect.op,
        },
      );
      _denyBattleAction(
        useResult.failMessage ?? context.translate('battleCannotUseItem'),
        failure: useResult.failure,
        target: _BattleDenyTarget.slots,
      );
      return;
    }
    _logBattleAction(
      'targeted_item_use',
      parameters: {
        'item_id': selection.slot.contentId,
        'item_op': selection.slot.item.effect.op,
      },
    );
    GameFeedback.play(GameCue.lineTransform);
    _mutate(() {
      _fateLineSelection = null;
      _fateTransformFlashLineRef = selected.ref;
      _fateTransformFlashTick += 1;
    });
    _showSnack(
      context.translate(
        'battleItemUsed',
        namedArgs: {'item': selection.displayName(context)},
      ),
      silent: true,
    );
    final feedbackDetail = _scoringLineTargetFeedbackDetail(
      selection.slot.item,
      selected,
      selection.selectedTile,
    );
    final feedbackDelay = _ritualFlightDurationForEvents(useResult.events);
    final fateTransformFeedback = _isFateLineTransformDefinition(
      selection.slot.item,
    );
    if (feedbackDelay == Duration.zero) {
      _showItemEffectFeedback(
        title: selection.displayName(context),
        titleBuilder: selection.displayName,
        detailBuilder: (context) => _scoringLineTargetFeedbackDetail(
          selection.slot.item,
          selected,
          selection.selectedTile,
          feedbackContext: context,
        ),
        detail: feedbackDetail,
        sourceLabel: selection.slot.slotLabel,
        fateTransform: fateTransformFeedback,
      );
    } else {
      unawaited(
        Future<void>.delayed(feedbackDelay, () {
          if (!mounted) return;
          _showItemEffectFeedback(
            title: selection.displayName(context),
            titleBuilder: selection.displayName,
            detailBuilder: (context) => _scoringLineTargetFeedbackDetail(
              selection.slot.item,
              selected,
              selection.selectedTile,
              feedbackContext: context,
            ),
            detail: feedbackDetail,
            sourceLabel: selection.slot.slotLabel,
            fateTransform: fateTransformFeedback,
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
      _logBattleActionFail(
        'deck_peek_discard',
        useResult.failure?.reason?.name ?? 'item_use_failed',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      _denyBattleAction(
        useResult.failMessage ?? context.translate('battleCannotUseItem'),
        failure: useResult.failure,
        target: _BattleDenyTarget.slots,
      );
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
      barrierLabel: context.translate('battlePeekDeck'),
      routeSettings: const RouteSettings(name: 'deck-peek'),
      builder: (context) => GameTileChoiceDialog(
        title: context.translate('battlePeekDeck'),
        message: context.translate('battlePeekDeckPrompt'),
        tiles: useResult.candidates,
        closeLabel: context.translate('battleClose'),
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (selectedIndex == null) {
      _logBattleAction(
        'deck_peek',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      GameFeedback.play(GameCue.itemUse);
      _showSnack(
        context.translate('battleItemUsed', namedArgs: {'item': itemName}),
        silent: true,
      );
      _showItemEffectFeedback(
        title: itemName,
        titleBuilder: (context) => ItemTranslationScope.of(
          context,
        ).resolveDisplayName(slot.contentId, slot.displayName),
        detailBuilder: (context) => context.translate('battlePeekDeck'),
        detail: context.translate('battlePeekDeck'),
        sourceLabel: slot.slotLabel,
      );
      return;
    }

    final selectedTile = useResult.candidates[selectedIndex];
    final failReason = _gameNotifier.useBattleDeckPeekDiscardItemFailure(
      slot.item,
      selectedIndex,
    );
    if (failReason != null) {
      _logBattleActionFail(
        'deck_peek_discard',
        failReason.reason?.name ?? 'denied',
        parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
      );
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.slots,
      );
      return;
    }
    _logBattleAction(
      'deck_peek_discard',
      parameters: {'item_id': slot.contentId, 'item_op': slot.item.effect.op},
    );
    GameFeedback.play(GameCue.discard);
    _showSnack(
      context.translate(
        'battleTileRemoved',
        namedArgs: {'tile': selectedTile.code},
      ),
      silent: true,
    );
    _showItemEffectFeedback(
      title: itemName,
      titleBuilder: (context) => ItemTranslationScope.of(
        context,
      ).resolveDisplayName(slot.contentId, slot.displayName),
      detailBuilder: (context) => context.translate(
        'battleTileRemoved',
        namedArgs: {'tile': selectedTile.code},
      ),
      detail: context.translate(
        'battleTileRemoved',
        namedArgs: {'tile': selectedTile.code},
      ),
      sourceLabel: slot.slotLabel,
    );
    await _saveActiveRun();
  }

  String _battleItemFeedbackDetail(
    ItemDefinition item, {
    BuildContext? feedbackContext,
  }) {
    final context = feedbackContext ?? this.context;
    if (isDelayedItemActivation(item)) {
      return localizedItemPresentationResult(
        context,
        ItemPresentationEvent(
          itemId: item.id,
          sourceKind: itemPresentationSourceKindForPlacement(item.placement),
          sourceLabel: item.displayName,
          target: const ItemPresentationTarget(
            kind: ItemPresentationTargetKind.confirm,
            label: '',
          ),
          resultLabel: delayedItemConsumedTimingLabel(item),
          consumed: item.effect.consume,
          activationTiming: item.effect.timing,
        ),
      );
    }
    return switch (item.effect.op) {
      'add_board_discard' => context.translate(
        'battleBoardDiscardAdded',
        namedArgs: {'amount': '${item.effect.value('amount') ?? 1}'},
      ),
      'add_hand_discard' => context.translate(
        'battleHandDiscardAdded',
        namedArgs: {'amount': '${item.effect.value('amount') ?? 1}'},
      ),
      'add_board_move' => context.translate(
        'battleTileMoveAdded',
        namedArgs: {'amount': '${item.effect.value('amount') ?? 1}'},
      ),
      'mark_next_board_move_bonus' => context.translate('battleMoveBonusReady'),
      'undo_last_board_move' => context.translate('battleMoveUndone'),
      'draw_if_hand_empty' => context.translate('battleDrawOne'),
      'increase_hand_size' => context.translate(
        'battleHandCapacityAdded',
        namedArgs: {'amount': '${item.effect.value('amount') ?? 1}'},
      ),
      'add_hand_rank_progress_from_selected_line' => context.translate(
        'battleSelectedRankGrowth',
      ),
      'ritual_line_effect' => _ritualActionLabel(
        item.effect.value('ritualAction'),
        feedbackContext: context,
      ),
      'chips_bonus' => context.translate('battleNextChips'),
      'mult_bonus' => context.translate('battleNextPercent'),
      'xmult_bonus' => context.translate('battleNextMultiplier'),
      'temporary_overlap_cap_bonus' => context.translate('battleNextOverlap'),
      _ => context.translate('battleEffectApplied'),
    };
  }

  /// Takes the line itself, not a label built by the caller. A sentence that
  /// names a line, its rank and an action belongs to one key, so a language
  /// that orders those parts differently can say so. See docs/core/I18N.md.
  String _scoringLineTargetFeedbackDetail(
    ItemDefinition item,
    RummiScoringLineSummary line,
    Tile? tile, {
    BuildContext? feedbackContext,
  }) {
    final context = feedbackContext ?? this.context;
    final lineLabel = _lineLabel(context, line.ref);
    final rankLabel = line.isScoringLine
        ? context.translate(rummiHandRankKey(line.rank))
        : context.translate('battleNoScoringLine');
    if (item.effect.op != 'ritual_line_effect') {
      return context.translate(
        'battleTargetGrowth',
        namedArgs: {
          'line': lineLabel,
          'rank': rankLabel,
          'amount': '${item.effect.value('amount') ?? 1}',
        },
      );
    }
    final action = _ritualActionLabel(
      item.effect.value('ritualAction'),
      feedbackContext: context,
    );
    return tile == null
        ? context.translate(
            'battleTargetRitualNoTile',
            namedArgs: {
              'line': lineLabel,
              'rank': rankLabel,
              'action': action,
            },
          )
        : context.translate(
            'battleTargetRitual',
            namedArgs: {
              'line': lineLabel,
              'rank': rankLabel,
              'tile': tile.code,
              'action': action,
            },
          );
  }

  String _ritualActionLabel(
    Object? actionValue, {
    BuildContext? feedbackContext,
  }) {
    final context = feedbackContext ?? this.context;
    return switch (actionValue?.toString()) {
      'growth' || 'center_growth' => context.translate('battleRankGrowth'),
      'growth_marker' => context.translate('battleGrowthMarker'),
      'copy_center' ||
      'copy_endpoint' ||
      'copy_selected' ||
      'copy_rank' ||
      'copy_color' => context.translate('battleDeckCopy'),
      'seal_line_mark' ||
      'seal_growth' ||
      'seal_gold' ||
      'seal_echo' ||
      'seal_anchor' ||
      'seal_risk' ||
      'seal_bridge' => context.translate('battleTileSeal'),
      'override_three_kind' ||
      'override_straight' ||
      'override_flush' ||
      'override_full_house' ||
      'override_four_kind' ||
      'override_five_kind' => context.translate('battleOverrideRank'),
      'fate_royal_flush' => context.translate('battleTransformRoyal'),
      'fate_straight_flush_high' || 'fate_straight_flush_low' =>
        context.translate('battleTransformStraightFlush'),
      'fate_four_kind_high' ||
      'fate_four_kind_low' => context.translate('battleTransformFour'),
      'fate_full_house_high' ||
      'fate_full_house_low' => context.translate('battleTransformFullHouse'),
      'fate_flush_house' => context.translate('battleTransformFlushHouse'),
      'fate_flush_five' => context.translate('battleTransformFlushFive'),
      'fate_flush_high' ||
      'fate_flush_low' => context.translate('battleTransformFlush'),
      'fate_straight_high' ||
      'fate_straight_low' => context.translate('battleTransformStraight'),
      'fate_three_kind_high' ||
      'fate_three_kind_low' => context.translate('battleTransformThree'),
      'fate_two_pair_high' => context.translate('battleTransformTwoPair'),
      'line_bonus_25' ||
      'line_bonus_35' => context.translate('battleLineBonus'),
      'remove_same_tile' ||
      'remove_same_rank' => context.translate('battleDeckDestroy'),
      'prune_line_to_color' => context.translate('battleColorPrune'),
      'burn_line' => context.translate('battleBurnLine'),
      'sacrifice_line' => context.translate('battleSacrificeLine'),
      _ => context.translate('battleRitualEffect'),
    };
  }

  String _lineChoiceLabel(LineRef ref) {
    return _lineLabel(context, ref);
  }

  String _lineChoiceRankLabel(RummiScoringLineSummary line) {
    if (!line.isScoringLine) return context.translate('battleNoScoringLine');
    return context.translate(rummiHandRankKey(line.rank));
  }

  void _confirmLines() async {
    if (_isBattleInputLocked) return;
    final result = _gameNotifier.confirmLines();
    if (result == null) {
      if (await _tryApplyExpiryGuard()) return;
      final didGameOver = await _afterAction();
      if (didGameOver || !mounted) return;
      _logBattleActionFail('confirm_lines', 'no_scoring_lines');
      _denyBattleAction(
        context.translate('battleNothingToConfirm'),
        target: _BattleDenyTarget.actions,
      );
      return;
    }
    GameFeedback.play(GameCue.confirmPress);
    final settlementGoalBaseScore = _stationView.objective.scoreTowardObjective;
    _logBattleAction(
      'confirm_lines',
      parameters: {
        'line_count': result.lineBreakdowns.length,
        'score_delta': result.totalScore,
        'stage_cleared': result.stageCleared,
      },
    );
    _logScoreConfirm(
      lines: result.lineBreakdowns,
      totalScore: result.totalScore,
      stageCleared: result.stageCleared,
      targetBefore: settlementGoalBaseScore,
    );
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
      _logBattleActionFail('board_move_start', 'no_source_tile');
      _denyBattleAction(
        context.translate('battleSelectMoveFirst'),
        target: _BattleDenyTarget.board,
      );
      return;
    }
    if (_stationView.resources.boardMovesRemaining <= 0) {
      _logBattleActionFail('board_move_start', 'no_board_moves');
      _denyBattleAction(
        context.translate('battleNoMoves'),
        target: _BattleDenyTarget.actions,
      );
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
      _logBattleActionFail(
        'board_move',
        'destination_occupied',
        parameters: {
          'from_row': fromRow,
          'from_col': fromCol,
          'to_row': row,
          'to_col': col,
        },
      );
      _denyBattleAction(
        context.translate('battleMoveEmptyOnly'),
        target: _BattleDenyTarget.board,
      );
      return;
    }

    final hadSlideBonus =
        _gameState.session?.nextBoardMoveSlideBonusQueued ?? false;
    final failReason = _gameNotifier.moveBoardTileFailure(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: row,
      toCol: col,
    );
    if (failReason != null) {
      _logBattleActionFail(
        'board_move',
        failReason.reason?.name ?? 'denied',
        parameters: {
          'from_row': fromRow,
          'from_col': fromCol,
          'to_row': row,
          'to_col': col,
        },
      );
      _denyBattleAction(
        failReason.legacyMessage,
        failure: failReason,
        target: _BattleDenyTarget.board,
      );
      return;
    }
    _logBattleAction(
      'board_move',
      parameters: {
        'from_row': fromRow,
        'from_col': fromCol,
        'to_row': row,
        'to_col': col,
        'slide_bonus': hadSlideBonus,
      },
    );
    _cancelBoardMoveMode();
    GameFeedback.play(GameCue.tileMove);
    _showSnack(
      hadSlideBonus
          ? context.translate('battleMoveBonusActivated')
          : context.translate('battleTileMoved'),
      silent: true,
    );
    if (hadSlideBonus) {
      _showBoardMoveBonusFlash(row: row, col: col);
      _showItemEffectFeedback(
        title: context.translate('battleSlideWax'),
        titleBuilder: (context) => context.translate('battleSlideWax'),
        detailBuilder: (context) => context.translate('battleMoveBonus'),
        detail: context.translate('battleMoveBonus'),
      );
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
                SemanticText(
                  context.translate('battleRitualLinePrompt'),
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
                      child: Text(context.translate('cancel')),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _selectedLine == null
                          ? null
                          : _confirmSelection,
                      child: Text(context.translate('ok')),
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
