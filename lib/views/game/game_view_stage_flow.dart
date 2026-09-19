part of '../game_view.dart';

extension _GameViewStageFlow on _GameViewState {
  void _logScoreConfirm({
    required List<ConfirmedLineBreakdown> lines,
    required int totalScore,
    required bool stageCleared,
    required int targetBefore,
  }) {
    if (lines.isEmpty) return;
    final rankCounts = <String, int>{};
    for (final line in lines) {
      rankCounts.update(
        line.rank.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final sortedRankKeys = rankCounts.keys.toList()..sort();
    final maxRank = lines
        .map((line) => line.rank)
        .reduce((a, b) => a.index >= b.index ? a : b);
    final maxOverlap = lines
        .map((line) => line.overlapMultiplier)
        .fold<double>(1.0, math.max);
    final baseScore = lines.fold<int>(0, (sum, line) => sum + line.baseScore);
    final finalScore = lines.fold<int>(0, (sum, line) => sum + line.finalScore);

    unawaited(
      GameAnalyticsService.instance.logEvent(
        'score_confirm',
        parameters: {
          ..._battleAnalyticsBaseParams(),
          'line_count': lines.length,
          'rank_summary': [
            for (final key in sortedRankKeys) '$key:${rankCounts[key]}',
          ].join(','),
          'max_rank': maxRank.name,
          'has_overlap': lines.any((line) => line.overlapBonus > 0),
          'max_overlap_bucket': _overlapBucket(maxOverlap),
          'base_score': baseScore,
          'final_score': finalScore,
          'score_delta': totalScore,
          'target_before': targetBefore,
          'target_after': targetBefore + totalScore,
          'station_cleared': stageCleared,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  String _overlapBucket(double multiplier) {
    if (multiplier <= 1) return 'x1';
    if (multiplier < 2) return 'x1_to_x2';
    if (multiplier < 3) return 'x2_to_x3';
    return 'x3_plus';
  }

  void _logStationClear(int scoreAdded) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'station_clear',
        parameters: {
          ..._battleAnalyticsBaseParams(),
          'score_delta': scoreAdded,
          'is_final_boss': _isFinalBossCleared,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logCashOutResult(
    RummiCashOutBreakdown breakdown,
    GameCashOutAction? action, {
    required bool completesRun,
  }) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'cashout_result',
        parameters: {
          ..._battleAnalyticsBaseParams(),
          'cashout_action': action?.name ?? 'dismissed',
          'blind_reward': breakdown.blindReward,
          'discard_gold':
              breakdown.boardDiscardGold + breakdown.handDiscardGold,
          'board_move_gold': breakdown.boardMoveGold,
          'economy_gold': breakdown.economyGold,
          'item_gold': breakdown.itemGold,
          'overkill_gold': breakdown.overkillGoldBonus,
          'total_gold': breakdown.totalGold,
          'deck_reward_count': breakdown.deckTileRewards.length,
          'growth_bonus_count': breakdown.overkillGrowthBonuses.length,
          'completes_run': completesRun,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logStationAdvance(ActiveRunRuntimeState runtime) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'station_advance',
        parameters: {
          'difficulty': widget.difficulty.name,
          'modifier': widget.runModifier.id,
          'from_station_index': _battleView.stageIndex,
          'to_station_index': runtime.runProgress.stageIndex,
          'gold': runtime.runProgress.gold,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logMarketAction(
    String action, {
    required String category,
    int spentGold = 0,
    int gainedGold = 0,
    String? contentId,
    String? itemPlacement,
    String? itemRarity,
    Tile? tile,
  }) {
    final market = _marketView;
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'market_action',
        parameters: {
          'difficulty': widget.difficulty.name,
          'modifier': widget.runModifier.id,
          'station_index': _battleView.stageIndex,
          'blind_tier': widget.blindTier.name,
          'category': category,
          'action': action,
          'spent_gold': spentGold,
          'gained_gold': gainedGold,
          'remaining_gold': market.gold,
          'content_id': ?contentId,
          'item_placement': ?itemPlacement,
          'rarity': ?itemRarity,
          if (tile != null) 'tile_color': tile.color.name,
          if (tile != null) 'tile_number': tile.number,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logMarketActionFailed(
    String action, {
    required String category,
    required String reason,
    String? contentId,
  }) {
    final market = _marketView;
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'market_action_failed',
        parameters: {
          'difficulty': widget.difficulty.name,
          'modifier': widget.runModifier.id,
          'station_index': _battleView.stageIndex,
          'blind_tier': widget.blindTier.name,
          'category': category,
          'action': action,
          'reason': reason,
          'remaining_gold': market.gold,
          'content_id': ?contentId,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _logMarketEntry() {
    final market = _marketView;
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'market_entry',
        parameters: {
          'difficulty': widget.difficulty.name,
          'modifier': widget.runModifier.id,
          'station_index': _battleView.stageIndex,
          'blind_tier': widget.blindTier.name,
          'gold': market.gold,
          'jester_count': market.ownedEntries.length,
          'item_count': market.itemSlots
              .where((slot) => slot.contentId != null)
              .length,
          'jester_offer_count': market.offers.length,
          'item_offer_count': market.itemOffers.length,
          'tile_offer_count': market.tileOffers.length,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  String? _loggableFailReason(String? failMessage) {
    if (failMessage == null) return null;
    if (failMessage.contains('골드')) return 'not_enough_gold';
    if (failMessage.contains('공간') || failMessage.contains('슬롯')) {
      return 'no_space';
    }
    return 'denied';
  }

  String? _rerollMarketForAnalytics() {
    final before = _marketView;
    final fail = _gameNotifier.rerollShopFromState(itemCatalog: _itemCatalog);
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed('reroll', category: 'jester', reason: reason);
      return fail;
    }
    _logMarketAction(
      'reroll',
      category: 'jester',
      spentGold: before.rerollCost,
    );
    return null;
  }

  String? _rerollItemOffersForAnalytics(ItemPlacement placement) {
    final before = _marketView;
    final fail = _gameNotifier.rerollItemOffersFromState(
      itemCatalog: _itemCatalog,
      placement: placement,
    );
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed('reroll', category: 'item', reason: reason);
      return fail;
    }
    _logMarketAction(
      'reroll',
      category: 'item',
      spentGold: before.itemRerollCostFor(placement),
      itemPlacement: placement.name,
    );
    return null;
  }

  String? _rerollTileOffersForAnalytics() {
    final before = _marketView;
    final fail = _gameNotifier.rerollTileOffersFromState(
      itemCatalog: _itemCatalog,
    );
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed('reroll', category: 'tile', reason: reason);
      return fail;
    }
    _logMarketAction(
      'reroll',
      category: 'tile',
      spentGold: before.tileRerollCost,
    );
    return null;
  }

  String? _buyJesterOfferForAnalytics(RummiMarketOfferView offer) {
    final fail = _gameNotifier.buyShopOfferView(
      offer,
      itemCatalog: _itemCatalog,
    );
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed(
        'buy',
        category: 'jester',
        reason: reason,
        contentId: offer.contentId,
      );
      return fail;
    }
    _logMarketAction(
      'buy',
      category: 'jester',
      spentGold: offer.price,
      contentId: offer.contentId,
    );
    return null;
  }

  String? _buyItemOfferForAnalytics(RummiMarketItemOfferView offer) {
    final fail = _gameNotifier.buyItemOffer(offer, itemCatalog: _itemCatalog);
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed(
        'buy',
        category: 'item',
        reason: reason,
        contentId: offer.contentId,
      );
      return fail;
    }
    _logMarketAction(
      'buy',
      category: 'item',
      spentGold: offer.price,
      contentId: offer.contentId,
      itemPlacement: offer.item.placement.name,
      itemRarity: offer.item.rarity.name,
    );
    return null;
  }

  String? _buyTileOfferForAnalytics(int offerIndex) {
    final offer = _marketView.tileOffers
        .where((candidate) => candidate.slotIndex == offerIndex)
        .firstOrNull;
    final fail = _gameNotifier.buyTileOffer(offerIndex);
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed('buy', category: 'tile', reason: reason);
      return fail;
    }
    _logMarketAction(
      'buy',
      category: 'tile',
      spentGold: offer?.price ?? 0,
      tile: offer?.tile,
    );
    return null;
  }

  String? _useMarketItemForAnalytics(ItemDefinition item) {
    final fail = _gameNotifier.useMarketItem(item);
    final reason = _loggableFailReason(fail);
    if (reason != null) {
      _logMarketActionFailed(
        'use',
        category: 'item',
        reason: reason,
        contentId: item.id,
      );
      return fail;
    }
    _logMarketAction(
      'use',
      category: 'item',
      contentId: item.id,
      itemPlacement: item.placement.name,
      itemRarity: item.rarity.name,
    );
    return null;
  }

  bool _sellOwnedJesterForAnalytics(int index) {
    final entry = index >= 0 && index < _marketView.ownedEntries.length
        ? _marketView.ownedEntries[index]
        : null;
    final ok = _gameNotifier.sellOwnedJester(index, itemCatalog: _itemCatalog);
    if (!ok) {
      _logMarketActionFailed('sell', category: 'jester', reason: 'denied');
      return false;
    }
    _logMarketAction(
      'sell',
      category: 'jester',
      gainedGold: entry?.sellPrice ?? 0,
      contentId: entry?.contentId,
    );
    return true;
  }

  bool _sellMarketItemForAnalytics(ItemDefinition item) {
    final ok = _gameNotifier.sellMarketItem(item);
    if (!ok) {
      _logMarketActionFailed(
        'sell',
        category: 'item',
        reason: 'denied',
        contentId: item.id,
      );
      return false;
    }
    _logMarketAction(
      'sell',
      category: 'item',
      gainedGold: item.sellPrice,
      contentId: item.id,
      itemPlacement: item.placement.name,
      itemRarity: item.rarity.name,
    );
    return true;
  }

  Future<void> _runSettlementSequence({
    required List<ConfirmedLineBreakdown> lines,
    required int totalScore,
    required bool shouldClearAfter,
    required int settlementGoalBaseScore,
    int settlementGoalAppliedScore = 0,
    int index = 0,
  }) async {
    if (!mounted) return;
    if (index == 0) _resetSettlementPresentation();
    if (lines.isEmpty || index >= lines.length) {
      await _waitWhilePresentationPaused();
      if (!mounted) return;
      _mutate(_resetSettlementPresentation);
      _gameNotifier.setStageFlow(
        phase: GameStageFlowPhase.none,
        activeSettlementLine: null,
        activeSettlementStep: ScoringPresentationStep.none,
        activeSettlementEffectIndex: null,
        settlementGoalDisplayScore: null,
        settlementBoardSnapshot: const {},
      );
      if (shouldClearAfter) {
        SoundManager.playSfx(AssetPaths.sfxClear);
        await _runStageClearFlow(totalScore);
      } else {
        await _saveActiveRun(scene: ActiveRunScene.battle);
      }
      return;
    }

    final line = lines[index];
    final lineGoalStartScore =
        settlementGoalBaseScore + settlementGoalAppliedScore;
    final lineGoalDisplayScore =
        settlementGoalBaseScore + settlementGoalAppliedScore + line.finalScore;
    final ownedEntries = _marketView.ownedEntries;
    final jesterSlotById = <String, int>{
      for (var i = ownedEntries.length - 1; i >= 0; i--)
        ownedEntries[i].card.id: i,
    };
    // 왼쪽 슬롯부터 한 장씩 발동한다.
    final jesterEffectIndexes =
        <int>[
          for (var i = 0; i < line.effects.length; i++)
            if (jesterSlotById.containsKey(line.effects[i].jesterId)) i,
        ]..sort(
          (a, b) => jesterSlotById[line.effects[a].jesterId]!.compareTo(
            jesterSlotById[line.effects[b].jesterId]!,
          ),
        );
    final tileEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (_isTileSettlementEffect(line.effects[i].jesterId)) i,
    ];
    final itemEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (!jesterSlotById.containsKey(line.effects[i].jesterId) &&
            !_isTileSettlementEffect(line.effects[i].jesterId))
          i,
    ];
    final cellAppearances = <String, int>{
      for (final other in lines)
        for (final (row, col) in other.contributingCells) '$row:$col': 0,
    };
    for (final other in lines) {
      for (final (row, col) in other.contributingCells) {
        cellAppearances.update('$row:$col', (count) => count + 1);
      }
    }

    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.boardLine,
      settlementGoalDisplayScore: lineGoalStartScore,
      bump: true,
      delay: Duration.zero,
    );
    if (!mounted) return;
    await _playSettlementTileTicks(line, cellAppearances);
    if (!mounted) return;
    await _presentationDelay(GamePresentationTimings.settlementBoardLineStep);
    if (!mounted) return;
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.handRank,
      settlementGoalDisplayScore: lineGoalStartScore,
      cue: GameCue.scoreTick,
      delay: GamePresentationTimings.settlementHandRankStep,
    );
    if (!mounted) return;
    if (line.overlapBonus > 0) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.overlap,
        settlementGoalDisplayScore: lineGoalStartScore,
        cue: GameCue.overlapHit,
        delay: GamePresentationTimings.settlementOverlapStep,
      );
      if (!mounted) return;
    }
    if (line.constraintPenalties.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.constraint,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        cue: GameCue.penalty,
        risingPitch: false,
        delay: GamePresentationTimings.settlementConstraintStep,
      );
      if (!mounted) return;
    }
    for (final effectIndex in jesterEffectIndexes) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.jester,
        effectIndexes: [effectIndex],
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        cue: GameCue.jesterFire,
        pitch: _jesterFirePitch(line.effects[effectIndex]),
        delay: GamePresentationTimings.settlementJesterFire,
      );
      if (!mounted) return;
    }
    if (tileEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.tile,
        effectIndexes: tileEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        cue: GameCue.tileModifierFire,
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    if (itemEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.item,
        effectIndexes: itemEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        cue: GameCue.itemFire,
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    final grade = GameSettlementPacing.grade(
      line.finalScore,
      _stationView.objective.targetScore,
    );
    final isFinisher = shouldClearAfter && index == lines.length - 1;
    _mutate(() {
      _settlementGrade = grade;
      _settlementSlowMo = isFinisher;
    });
    if (!_settlementSkipRequested) {
      if (isFinisher) {
        _presentationClock.hitStop(
          GamePresentationTimings.settlementFinisherHitStop,
        );
        ScreenShake.instance.add(0.55);
      } else if (grade >= GameSettlementPacing.impactGrade) {
        _presentationClock.hitStop(
          GamePresentationTimings.settlementGradeHitStop,
        );
        ScreenShake.instance.add(grade >= 3 ? 0.45 : 0.32);
      }
    }
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.finalScore,
      settlementGoalDisplayScore: lineGoalDisplayScore,
      cue: _gradeCues[grade.clamp(0, _gradeCues.length - 1)],
      risingPitch: false,
      delay: GamePresentationTimings.settlementFinalScoreStep,
    );
    if (!mounted) return;
    _mutate(() => _settlementSlowMo = false);

    await _presentationDelay(GamePresentationTimings.settlementLineTail);
    if (!mounted) return;
    await _runSettlementSequence(
      lines: lines,
      totalScore: totalScore,
      shouldClearAfter: shouldClearAfter,
      settlementGoalBaseScore: settlementGoalBaseScore,
      settlementGoalAppliedScore: settlementGoalAppliedScore + line.finalScore,
      index: index + 1,
    );
  }

  static const List<GameCue> _gradeCues = [
    GameCue.bigScore1,
    GameCue.bigScore2,
    GameCue.bigScore3,
    GameCue.bigScore4,
  ];

  /// 칩 가산은 낮게, % 가산은 중간, ×N 곱연산은 높게.
  double _jesterFirePitch(RummiJesterEffectBreakdown effect) {
    if (effect.xmultBonus > 1.0) return 1.25;
    if (effect.multBonus > 0) return 1.08;
    return 0.92;
  }

  /// 한 확정의 연출 전용 상태를 비운다. 게임 결과 state는 건드리지 않는다.
  void _resetSettlementPresentation() {
    _settlementSkipRequested = false;
    _settlementSlowMo = false;
    _settlementStepCount = 0;
    _settlementTickIndex = 0;
    _settlementGrade = 0;
    _settlementTileHeat = const {};
    _settlementTileHitSerial = const {};
  }

  /// 정산 도중 탭하면 남은 연출을 건너뛴다. 스텝은 그대로 진행되어 최종 상태가 같다.
  void _skipSettlementPresentation() {
    if (_stageFlowPhase != GameStageFlowPhase.confirmSettlement) return;
    if (_settlementSkipRequested) return;
    _mutate(() => _settlementSkipRequested = true);
  }

  /// 줄 안의 타일이 하나씩 반응한다. 음높이는 확정 전체에 걸쳐 오른다.
  ///
  /// 여러 줄에 기여한 교차 타일은 맞을 때마다 달아오르고 다른 음색을 낸다.
  Future<void> _playSettlementTileTicks(
    ConfirmedLineBreakdown line,
    Map<String, int> cellAppearances,
  ) async {
    for (final (row, col) in line.contributingCells) {
      if (!mounted) return;
      final key = '$row:$col';
      final crossing = (cellAppearances[key] ?? 0) > 1;
      final heat = crossing ? (_settlementTileHeat[key] ?? 0) + 1 : 0;
      _mutate(() {
        _settlementHitSerial++;
        _settlementTileHitSerial = {
          ..._settlementTileHitSerial,
          key: _settlementHitSerial,
        };
        if (crossing) {
          _settlementTileHeat = {..._settlementTileHeat, key: heat};
        }
      });
      if (!_settlementSkipRequested) {
        final pitch = GameSettlementPacing.tickPitch(_settlementTickIndex);
        if (heat > 1) {
          GameFeedback.play(GameCue.overlapHit, pitch: pitch);
          ScreenShake.instance.add(0.12 + 0.08 * heat);
        } else {
          GameFeedback.play(GameCue.scoreTick, pitch: pitch);
          ScreenShake.instance.add(0.08);
        }
      }
      _settlementTickIndex++;
      await _presentationDelay(GamePresentationTimings.settlementTileTick);
    }
  }

  Future<void> _showSettlementStep({
    required int totalScore,
    required ConfirmedLineBreakdown line,
    required ScoringPresentationStep step,
    required Duration delay,
    int? effectIndex,
    List<int> effectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    bool bump = false,
    GameCue? cue,
    double pitch = 1,
    bool risingPitch = true,
  }) async {
    await _waitWhilePresentationPaused();
    if (!mounted) return;
    _settlementStepCount++;
    if (cue != null && !_settlementSkipRequested) {
      GameFeedback.play(
        cue,
        pitch: risingPitch
            ? pitch * GameSettlementPacing.tickPitch(_settlementTickIndex)
            : pitch,
      );
      if (risingPitch) _settlementTickIndex++;
    }
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.confirmSettlement,
      stageScoreAdded: totalScore,
      activeSettlementLine: line,
      activeSettlementStep: step,
      activeSettlementEffectIndex: effectIndex,
      activeSettlementEffectIndexes: effectIndexes,
      settlementGoalDisplayScore: settlementGoalDisplayScore,
      bumpSettlementSequence: bump,
    );
    await _presentationDelay(delay);
  }

  bool _isTileSettlementEffect(String effectId) {
    return effectId.startsWith('tile:') || effectId.startsWith('tile_edition:');
  }

  Future<void> _runStageClearFlow(int scoreAdded) async {
    _logStationClear(scoreAdded);
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    if (widget.debugCompleteRunOnClear) {
      await _completeRunAndReturnToTitle();
      return;
    }
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _debugForceBlindClear() async {
    if (!AppConfig.showDebugFixtures || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear();
    await _runStageClearFlow(scoreAdded);
  }

  Future<void> _debugForceBossClearToNextBlindSelect() async {
    if (!AppConfig.showDebugFixtures || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear(
      overrideTier: BlindTier.boss,
    );
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(
      breakdown,
      autoEnterMarketOnLoad: true,
      autoAdvanceMarketOnLoad: true,
    );
  }

  Future<bool> _runStageClearPresentation(int scoreAdded) async {
    if (!mounted) return false;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.cleared,
      stageScoreAdded: scoreAdded,
      activeSettlementLine: null,
    );

    await _presentationDelay(GamePresentationTimings.stageClearClearedHold);
    if (!mounted) return false;
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.settlement);

    await _presentationDelay(GamePresentationTimings.stageClearSettlementHold);
    return mounted;
  }

  Future<GameCashOutAction?> _showCashOutSheet(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool completesRun = false,
  }) {
    final settlementView = RummiSettlementRuntimeFacade.fromCashOut(
      breakdown: breakdown,
      currentGold: _marketView.gold,
    );
    final insightReward = completesRun
        ? RunProgressionService.calculateInsightReward(_completedRunSummary())
        : 0;
    final showsChallengeCarryoverNotice =
        completesRun && widget.difficulty == NewRunDifficulty.standard;
    return showGeneralDialog<GameCashOutAction>(
      context: context,
      barrierLabel: '정산 결과',
      barrierDismissible: false,
      barrierColor: kGameModalBarrierColor,
      routeSettings: const RouteSettings(name: '정산 결과'),
      transitionDuration: MotionPolicy.reduceMotion
          ? Duration.zero
          : GamePresentationTimings.cashOutSheetIn,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PhoneFrame(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Semantics(
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: '정산 결과',
              child: GameCashOutSheet(
                settlement: settlementView,
                autoEnterMarketOnLoad:
                    !completesRun &&
                    (autoEnterMarketOnLoad || widget.autoEnterMarketOnCashOut),
                completesRun: completesRun,
                insightReward: insightReward,
                showsChallengeCarryoverNotice: showsChallengeCarryoverNotice,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAutoCashOutLoopOnLoad() async {
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _runSettlementToNextStationLoop(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool autoAdvanceMarketOnLoad = false,
  }) async {
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);
    await _saveActiveRun(scene: ActiveRunScene.battle);

    final completesRun = _isFinalBossCleared;
    final cashOutAction = await _showCashOutSheet(
      breakdown,
      autoEnterMarketOnLoad: autoEnterMarketOnLoad,
      completesRun: completesRun,
    );
    _logCashOutResult(breakdown, cashOutAction, completesRun: completesRun);
    if (cashOutAction == GameCashOutAction.completeRun) {
      await _completeRunAndReturnToTitle();
      return;
    }
    if (cashOutAction == GameCashOutAction.continueEndless) {
      await _claimRunCompletionRewardIfNeeded();
    }
    if (!mounted ||
        cashOutAction != GameCashOutAction.enterMarket &&
            cashOutAction != GameCashOutAction.continueEndless) {
      return;
    }

    _gameNotifier.enterMarketAfterCashOut(itemCatalog: _itemCatalog);
    await _saveActiveRun();
    if (!mounted) return;
    await _playSettlementToMarketTransition(breakdown);
    if (!mounted) return;

    _logMarketEntry();
    final nextStage = await _showShopScreen(
      autoAdvanceOnLoad: autoAdvanceMarketOnLoad,
    );
    if (!mounted || nextStage != true) return;

    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    _logStationAdvance(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  bool get _isFinalBossCleared {
    return _battleView.stageIndex == _GameViewState._finalStationIndex &&
        _battleView.currentBlindTierIndex >= BlindTier.boss.index;
  }

  Future<void> _claimRunCompletionRewardIfNeeded() async {
    final runProgress = _gameState.runProgress;
    if (runProgress == null || runProgress.runCompletionRewardClaimed) {
      return;
    }
    await _recordRunEndIfNeeded(_completedRunSummary());
    runProgress.runCompletionRewardClaimed = true;
    _gameNotifier.markDirty();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  RunEndSummary _completedRunSummary() {
    return RunEndSummary(
      result: RunEndResult.completed,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: true),
      seenMarketJesterIds: _runProgressCollection.seenMarketJesterIds,
      seenMarketItemIds: _runProgressCollection.seenMarketItemIds,
      boughtJesterIds: _runProgressCollection.boughtJesterIds,
      boughtItemIds: _runProgressCollection.boughtItemIds,
      seenBossModifierIds: _runProgressCollection.seenBossModifierIds,
      clearedStationKeys: _runProgressCollection.clearedStationKeys,
      playedHandCounts: _runProgressCollection.snapshotPlayedHandCounts(),
      handGrowthStates: _runProgressCollection.snapshotHandGrowthStates(),
      addedDeckTiles: List<Tile>.from(_runProgressCollection.addedDeckTiles),
    );
  }

  RummiRunProgress get _runProgressCollection {
    return _gameState.runProgress ?? RummiRunProgress();
  }

  Future<void> _playSettlementToMarketTransition(
    RummiCashOutBreakdown breakdown,
  ) async {
    if (!mounted) return;
    _mutate(() => _settlementToMarketTransition = breakdown);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    _mutate(() => _settlementToMarketTransition = null);
  }

  Future<void> _goToNextStationBlindSelect() async {
    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    _logStationAdvance(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<void> _playNextStationTransition() async {
    if (!mounted) return;
    _mutate(() => _nextStationTransitionVisible = true);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    _mutate(() => _nextStationTransitionVisible = false);
  }

  Future<bool?> _showShopScreen({bool autoAdvanceOnLoad = false}) {
    _removeBattleTutorialForPause();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runSeed: widget.runSeed,
          readMarketView: _readMarketViewWithItemOffers,
          onReroll: _rerollMarketForAnalytics,
          onRerollItemOffers: _rerollItemOffersForAnalytics,
          onRerollTileOffers: _rerollTileOffersForAnalytics,
          onBuyOffer: _buyJesterOfferForAnalytics,
          onBuyItemOffer: _buyItemOfferForAnalytics,
          onBuyTileOffer: _buyTileOfferForAnalytics,
          onUseMarketItem: _useMarketItemForAnalytics,
          onSellOwnedJester: _sellOwnedJesterForAnalytics,
          onSellMarketItem: _sellMarketItemForAnalytics,
          autoStartTutorials: _shouldAutoStartTutorials,
          onSlotUnlockPresentationShown: () async {
            _gameNotifier.markSlotUnlockPresentationShown();
            await _saveActiveRun(scene: ActiveRunScene.shop);
          },
          onStateChanged: _saveActiveRun,
          readActiveRunSaveView: () => ref
              .read(gameSessionNotifierProvider(_gameArgs))
              .activeRunSaveView,
          onOpenSettings: () async {
            await WidgetsBinding.instance.endOfFrame;
            if (!mounted) return;
            if (!context.mounted) return;
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onBookmarkRun: _bookmarkCurrentRun,
          onLoadBookmarkRun: _loadBookmarkRunFromOptions,
          onRestartRun: _restartCurrentRun,
          isDebugFixtureRun: _isDebugFixtureRun,
          initialItemShopTab: widget.debugStartItemShop,
          initialItemPresentationEvents:
              _gameState.pendingItemPresentationEvents,
          onItemPresentationEventsShown:
              _gameNotifier.clearPendingItemPresentationEvents,
          autoAdvanceOnLoad:
              autoAdvanceOnLoad || widget.autoAdvanceMarketOnLoad,
        ),
      ),
    );
  }
}
