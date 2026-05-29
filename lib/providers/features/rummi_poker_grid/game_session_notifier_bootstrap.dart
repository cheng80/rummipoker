part of 'game_session_notifier.dart';

GameSessionState _buildInitialGameSessionState(GameSessionArgs args) {
  final restoredRun = args.restoredRun;
  if (restoredRun != null) {
    return GameSessionState(
      session: restoredRun.session,
      runProgress: restoredRun.runProgress,
      stageStartSnapshot: restoredRun.stageStartSnapshot,
      ruleset: args.ruleset,
      runModifier: restoredRun.runModifier,
      runLoopPhase: _loopPhaseForScene(restoredRun.activeScene),
      activeRunScene: restoredRun.activeScene,
      debugFixtureId: args.debugFixtureId,
    );
  }

  final ruleset = args.ruleset;
  final challengeCarryover = args.difficulty == NewRunDifficulty.challenge
      ? args.challengeCarryover
      : null;
  final initialDeckSource = challengeCarryover?.addedDeckTiles.isEmpty ?? true
      ? null
      : [
          ...buildStandardPokerDeck(copiesPerTile: ruleset.copiesPerTile),
          ...challengeCarryover!.addedDeckTiles,
        ];
  final initialBlind = BlindSelectionSetup.resolveSpec(
    tier: args.blindTier,
    stationIndex: 1,
    difficulty: args.difficulty,
    runModifier: args.runModifier,
    runSeed: args.runSeed,
    ruleset: ruleset,
  );
  final session = RummiPokerGridSession(
    runSeed: args.runSeed,
    deckCopiesPerTile: ruleset.copiesPerTile,
    ruleset: ruleset,
    deckSource: initialDeckSource,
    blind: RummiBlindState(
      targetScore: initialBlind.targetScore,
      boardDiscardsRemaining: initialBlind.boardDiscards,
      handDiscardsRemaining: initialBlind.handDiscards,
      bossModifier: initialBlind.bossModifier,
    ),
  );
  session.maxHandSize = initialBlind.maxHandSize;
  final rerollCost = _initialRerollCost(args.difficulty);
  final runProgress = RummiRunProgress()
    ..currentStationBlindTierIndex = args.blindTier.index
    ..gold = _initialGold(args.difficulty)
    ..rerollCost = rerollCost
    ..itemRerollCost = rerollCost
    ..quickSlotRerollCost = rerollCost
    ..passiveRerollCost = rerollCost
    ..toolRerollCost = rerollCost
    ..gearRerollCost = rerollCost;
  if (challengeCarryover != null) {
    runProgress.applyChallengeCarryover(
      playedHandCounts: challengeCarryover.playedHandCounts,
      handGrowthStates: challengeCarryover.handGrowthStates,
      addedDeckTiles: challengeCarryover.addedDeckTiles,
    );
  }
  runProgress.recordSeenBossModifier(initialBlind.bossModifier?.id);
  return GameSessionState(
    session: session,
    runProgress: runProgress,
    ruleset: ruleset,
    runModifier: args.runModifier,
    stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
      session: session,
      runProgress: runProgress,
    ),
    runLoopPhase: GameRunLoopPhase.battle,
    activeRunScene: ActiveRunScene.battle,
    debugFixtureId: args.debugFixtureId,
  );
}

int _initialGold(NewRunDifficulty difficulty) {
  return RummiEconomyConfig.startingGold;
}

int _initialRerollCost(NewRunDifficulty difficulty) {
  return switch (difficulty) {
    NewRunDifficulty.relaxed => RummiRunProgress.shopBaseRerollCost - 1,
    _ => RummiRunProgress.shopBaseRerollCost,
  };
}

GameRunLoopPhase _loopPhaseForScene(ActiveRunScene scene) {
  return switch (scene) {
    ActiveRunScene.shop => GameRunLoopPhase.market,
    ActiveRunScene.blindSelect => GameRunLoopPhase.nextStationTransition,
    ActiveRunScene.battle => GameRunLoopPhase.battle,
  };
}
