part of 'game_session_notifier.dart';

mixin GameSessionNotifierStationCommands
    on FamilyNotifier<GameSessionState, GameSessionArgs> {
  void _replaceState(GameSessionState next);
  void clearSelections();
  ActiveRunRuntimeState buildSaveRuntimeState({
    ActiveRunScene? scene,
    required NewRunDifficulty difficulty,
    bool useStageStartSnapshotAsCurrent,
  });

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    var breakdown = runProgress.buildCashOutBreakdown(
      session,
      itemCatalog: itemCatalog,
      rewardMultiplier: state.runModifier.rewardMultiplier,
    );
    runProgress.applyCashOut(breakdown);
    if (runProgress.currentStationBlindTierIndex == BlindTier.boss.index) {
      final rewardTile = runProgress.addBossClearDeckTileReward(
        session.runRandom,
      );
      breakdown = breakdown.copyWith(deckTileRewards: [rewardTile]);
      if (itemCatalog != null) {
        ItemEffectRuntime.applyOwnedBossClearItems(
          catalog: itemCatalog,
          runProgress: runProgress,
        );
      }
      runProgress.claimBossSlotUnlockRewards(itemCatalog: itemCatalog);
      runProgress.recordSeenBossModifier(session.blind.bossModifier?.id);
      runProgress.recordClearedStation(runProgress.stageIndex);
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
    var pendingItemPresentationEvents = state.pendingItemPresentationEvents;
    if (itemCatalog != null) {
      final results = ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
      );
      pendingItemPresentationEvents = [
        ...pendingItemPresentationEvents,
        ..._itemPresentationEventsForResults(
          catalog: itemCatalog,
          results: results,
        ),
      ];
    }
    clearSelections();
    _replaceState(
      state.copyWith(
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
        runLoopPhase: GameRunLoopPhase.battle,
        pendingItemPresentationEvents: pendingItemPresentationEvents,
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

  List<ItemPresentationEvent> _itemPresentationEventsForResults({
    required ItemCatalog catalog,
    required List<ItemUseResult> results,
  }) {
    final events = <ItemPresentationEvent>[];
    for (final result in results) {
      if (!result.isSuccess || result.events.isEmpty) continue;
      final item = catalog.findById(result.itemId);
      if (item == null) continue;
      final effectEvent = result.events.firstWhere(
        (event) => event.kind != ItemEffectEventKind.itemConsumed,
        orElse: () => result.events.first,
      );
      events.add(
        ItemPresentationEvent(
          itemId: item.id,
          sourceKind: itemPresentationSourceKindForPlacement(item.placement),
          sourceLabel: item.displayName,
          target: itemPresentationTargetForEvent(item, effectEvent),
          resultLabel: '발동: ${itemUseResultPresentationLabel(result)}',
          effectEvent: effectEvent,
        ),
      );
    }
    return List<ItemPresentationEvent>.unmodifiable(events);
  }
}
