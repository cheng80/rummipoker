import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/main.dart' as app;
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_catalog_loader.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/router.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_setup.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_tile_choice_dialog.dart';

import 'competition_bot_policy.dart';
import 'competition_bot_market_policy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'competition bot runs through real browser UI',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      binding.shouldPropagateDevicePointerEvents = true;

      final bot = _CompetitionFullPlayBot(
        tester: tester,
        config: _ContestBotConfig.fromEnvironment(),
      );
      try {
        await bot.run();
      } finally {
        binding.shouldPropagateDevicePointerEvents = false;
      }
    },
    // fresh S1~S8 full-run은 브라우저 구동과 retry 로그까지 포함해 길게 잡는다.
    timeout: const Timeout(Duration(minutes: 120)),
  );
}

enum _ContestBotMode { full, sub }

enum _ContestBotScene { stationSelect, battle, cashOut, market, runComplete }

enum _ContestTutorialKind { battle, market }

class _ContestBotConfig {
  const _ContestBotConfig({
    required this.mode,
    required this.seed,
    required this.difficultyName,
    required this.localeName,
    required this.maxBattleActions,
    required this.maxGameOverRetries,
    required this.resumeActiveRun,
    required this.resumeSaveBase64,
    required this.tutorialsAlreadySeen,
    required this.actionDelay,
    required this.targetStage,
    required this.targetTierName,
    required this.targetScene,
    required this.requiredEvidence,
  });

  factory _ContestBotConfig.fromEnvironment() {
    const modeValue = String.fromEnvironment(
      'CONTEST_BOT_MODE',
      defaultValue: 'full',
    );
    return _ContestBotConfig(
      mode: modeValue == 'sub' ? _ContestBotMode.sub : _ContestBotMode.full,
      seed: const int.fromEnvironment('CONTEST_BOT_SEED', defaultValue: 91460),
      difficultyName: const String.fromEnvironment(
        'CONTEST_BOT_DIFFICULTY',
        defaultValue: 'standard',
      ),
      localeName: const String.fromEnvironment(
        'CONTEST_BOT_LOCALE',
        defaultValue: 'ko',
      ),
      maxBattleActions: const int.fromEnvironment(
        'CONTEST_BOT_MAX_BATTLE_ACTIONS',
        defaultValue: 420,
      ),
      maxGameOverRetries: const int.fromEnvironment(
        'CONTEST_BOT_MAX_GAME_OVER_RETRIES',
        defaultValue: 24,
      ),
      resumeActiveRun: const bool.fromEnvironment(
        'CONTEST_BOT_RESUME_ACTIVE_RUN',
      ),
      resumeSaveBase64: const String.fromEnvironment(
        'CONTEST_BOT_RESUME_SAVE_B64',
      ),
      tutorialsAlreadySeen: const bool.fromEnvironment(
        'CONTEST_BOT_TUTORIALS_ALREADY_SEEN',
      ),
      actionDelay: Duration(
        milliseconds: const int.fromEnvironment(
          'CONTEST_BOT_ACTION_DELAY_MS',
          defaultValue: 250,
        ),
      ),
      targetStage: const int.fromEnvironment(
        'CONTEST_SUB_TARGET_STAGE',
        defaultValue: 1,
      ),
      targetTierName: const String.fromEnvironment(
        'CONTEST_SUB_TARGET_TIER',
        defaultValue: 'boss',
      ),
      targetScene: _parseScene(
        const String.fromEnvironment(
          'CONTEST_SUB_TARGET_SCENE',
          defaultValue: 'cashOut',
        ),
      ),
      requiredEvidence: const String.fromEnvironment(
        'CONTEST_SUB_REQUIRED_EVIDENCE',
      ),
    );
  }

  final _ContestBotMode mode;
  final int seed;
  final String difficultyName;
  final String localeName;
  final int maxBattleActions;
  final int maxGameOverRetries;
  final bool resumeActiveRun;
  final String resumeSaveBase64;
  final bool tutorialsAlreadySeen;
  final Duration actionDelay;
  final int targetStage;
  final String targetTierName;
  final _ContestBotScene targetScene;
  final String requiredEvidence;

  String get logPrefix => mode == _ContestBotMode.full
      ? 'CONTEST_FULL_RUN_BOT'
      : 'CONTEST_SUB_RUN_BOT';

  bool get isFullRun => mode == _ContestBotMode.full;

  bool get needsMarketPurchase =>
      isFullRun || requiredEvidence == 'market_purchase';

  bool get needsItemPurchase =>
      isFullRun || requiredEvidence == 'item_purchase';

  bool get needsItemUse => isFullRun || requiredEvidence == 'item_use';

  NewRunDifficulty get difficulty => NewRunSetup.resolveSelectableDifficulty(
    NewRunSetup.parseDifficulty(difficultyName),
  );

  Locale get locale => _parseLocale(localeName);

  BlindTier get targetTier => switch (targetTierName) {
    'small' => BlindTier.small,
    'big' => BlindTier.big,
    'boss' => BlindTier.boss,
    _ => BlindTier.boss,
  };

  List<String> get tutorialNextLabels => const ['다음', 'Next', '次へ', '下一步'];

  List<String> get tutorialDoneLabels => const ['완료', 'Done', '完了', '完成'];

  bool matchesTarget({required int stage, required BlindTier tier}) {
    if (isFullRun) return stage == 8 && tier == BlindTier.boss;
    return stage >= targetStage && tier == targetTier;
  }

  static _ContestBotScene _parseScene(String value) {
    return switch (value) {
      'stationSelect' || 'StationSelect' => _ContestBotScene.stationSelect,
      'battle' || 'Battle' => _ContestBotScene.battle,
      'market' || 'Market' => _ContestBotScene.market,
      'runComplete' || 'RunComplete' => _ContestBotScene.runComplete,
      _ => _ContestBotScene.cashOut,
    };
  }

  static Locale _parseLocale(String value) {
    return switch (value) {
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      'zh-CN' || 'zh_CN' => const Locale('zh', 'CN'),
      'zh-TW' || 'zh_TW' => const Locale('zh', 'TW'),
      _ => const Locale('ko'),
    };
  }
}

class _BattleItemChoice {
  const _BattleItemChoice({required this.slotIndex, required this.item});

  final int slotIndex;
  final ItemDefinition item;
}

/// 공모전 full-play gate용 실제 UI 조작 bot.
///
/// 판단은 `planner_v2`가 맡고, 전투/마켓/정산 진행은 Flutter Chrome 화면의
/// 버튼과 카드만 눌러 수행한다. debug fixture와 즉시 클리어 경로는 쓰지 않는다.
class _CompetitionFullPlayBot {
  _CompetitionFullPlayBot({required this.tester, required this.config});

  final WidgetTester tester;
  final _ContestBotConfig config;
  final CompetitionPlannerV2Policy battlePolicy =
      const CompetitionPlannerV2Policy();
  final CompetitionPlannerV2Policy retryRecoveryBattlePolicy =
      const CompetitionPlannerV2Policy(enableRetryRecoveryConfirmDelay: true);
  final List<String> log = <String>[];
  ItemCatalog? itemCatalog;

  bool boughtJester = false;
  bool boughtItem = false;
  bool boughtDeckTile = false;
  bool usedItem = false;
  bool battleTutorialCompleted = false;
  bool marketTutorialCompleted = false;
  bool discardedHand = false;
  bool discardedBoard = false;
  bool movedBoard = false;
  int gameOverRetries = 0;
  final Set<String> failedBattleActionRouteKeys = <String>{};
  final Set<String> currentBattleActionRouteKeys = <String>{};

  Future<void> run() async {
    itemCatalog = await ItemCatalogLoader.loadFromAsset(AssetPaths.itemsCommon);
    _syncEvidenceFromResumeConfig();
    await _startSeededRun();
    _syncEvidenceFromState();
    if (find.text('Station Select').evaluate().isNotEmpty &&
        _shouldStopAt(scene: _ContestBotScene.stationSelect)) {
      await _finishSubRun('target station select reached');
      return;
    }

    if (find.text('다음 Station').evaluate().isNotEmpty) {
      final progress = _readGameState().runProgress!;
      await _handleMarket(stage: progress.stageIndex);
      if (find.text('Station Select').evaluate().isNotEmpty &&
          _shouldStopAt(scene: _ContestBotScene.stationSelect)) {
        await _finishSubRun('target station select reached');
        return;
      }
    }

    if (find.text('드로우').evaluate().isEmpty) {
      await _chooseOpenBlind();
    }
    if (_shouldStopAtCurrentBattle()) {
      await _finishSubRun('target battle reached');
      return;
    }

    while (true) {
      await _playCurrentBattle();

      final state = _readGameState();
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      final stage = runProgress.stageIndex;

      if (_shouldStopAt(
        scene: _ContestBotScene.cashOut,
        stage: stage,
        tier: tier,
      )) {
        await _pumpUntilCashOutReady();
        await _finishSubRun('target cash-out reached');
        return;
      }

      await _handleCashOut(stage: stage, tier: tier);
      if (_shouldStopAt(
        scene: _ContestBotScene.market,
        stage: stage,
        tier: tier,
      )) {
        await _handleMarketEvidenceOnly(stage: stage);
        await _finishSubRun('target market reached');
        return;
      }

      if (config.isFullRun && stage == 8 && tier == BlindTier.boss) {
        break;
      }

      await _handleMarket(stage: stage);

      await _chooseOpenBlind();
      if (_shouldStopAtCurrentBattle()) {
        await _finishSubRun('target battle reached');
        return;
      }
    }

    expect(
      boughtJester,
      isTrue,
      reason: 'contest_full_run_bot must buy a Jester',
    );
    expect(boughtItem, isTrue, reason: 'contest_full_run_bot must buy an Item');
    if (!config.resumeActiveRun && !config.tutorialsAlreadySeen) {
      expect(
        battleTutorialCompleted,
        isTrue,
        reason: 'fresh contest_full_run_bot must complete battle tutorial',
      );
      expect(
        marketTutorialCompleted,
        isTrue,
        reason: 'fresh contest_full_run_bot must complete market tutorial',
      );
    }

    _printPassLog('S8 boss full run complete');
  }

  Future<void> _startSeededRun() async {
    app.main();
    await _pumpFor(const Duration(seconds: 5));
    if (!config.resumeActiveRun) {
      await StorageHelper.erase();
    }
    if (config.tutorialsAlreadySeen) {
      await TutorialStateService.markBattleIntroSeen();
      await TutorialStateService.markMarketIntroSeen();
    }
    await tester.element(find.byType(MaterialApp)).setLocale(config.locale);
    await _pumpFor(const Duration(seconds: 2));
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    _record(
      'locale=${config.localeName} '
      'resolvedLocale=${config.locale.languageCode}'
      '${config.locale.countryCode == null ? '' : '-${config.locale.countryCode}'} '
      'freshStorage=${!config.resumeActiveRun}',
    );

    if (config.resumeActiveRun) {
      final restored = await _loadResumeRuntime();
      if (restored != null) {
        final resumeRuntime = restored.activeScene == ActiveRunScene.blindSelect
            ? BlindSelectionSetup.prepareRuntimeForBlindSelect(
                runtime: restored,
              )
            : restored;
        final route = resumeRuntime.activeScene == ActiveRunScene.blindSelect
            ? RoutePaths.blindSelect
            : RoutePaths.game;
        appRouter.go(
          '$route?difficulty=${resumeRuntime.difficulty.name}'
          '&modifier=${resumeRuntime.runModifier.id}',
          extra: resumeRuntime,
        );
        await _pumpFor(const Duration(seconds: 2));
        _record(
          'resumed active run '
          'scene=${resumeRuntime.activeScene.name} '
          'S${resumeRuntime.runProgress.stageIndex} '
          'tier=${resumeRuntime.runProgress.currentStationBlindTierIndex}',
        );
        if (resumeRuntime.activeScene == ActiveRunScene.shop) {
          await _pumpUntilVisible(find.text('다음 Station'));
          return;
        }
        if (resumeRuntime.activeScene == ActiveRunScene.blindSelect) {
          await _pumpUntilVisible(find.text('Station Select'));
          return;
        }
        if (_isCashOutReady()) return;
        await _pumpUntilVisible(find.text('드로우'));
        return;
      }
      _record(
        'resume requested but no active run save found; starting seeded run',
      );
    }

    appRouter.go(
      '${RoutePaths.blindSelect}?seed=${config.seed}'
      '&difficulty=${config.difficulty.name}&modifier=basic',
    );
    await _pumpUntilVisible(find.text('Station Select'));
    log.add(
      'seed=${config.seed} difficulty=${config.difficulty.name} modifier=basic '
      'mode=${config.mode.name} locale=${config.localeName}',
    );
  }

  Future<ActiveRunRuntimeState?> _loadResumeRuntime() async {
    if (config.resumeSaveBase64.isNotEmpty) {
      final jsonString = utf8.decode(base64Decode(config.resumeSaveBase64));
      return ActiveRunSaveService.runtimeStateFromJson(jsonString);
    }
    return ActiveRunSaveService.loadActiveRun();
  }

  Future<void> _chooseOpenBlind() async {
    await _pumpUntilVisible(find.text('Station Select'));
    await _pumpUntilVisible(find.byIcon(Icons.play_arrow_rounded));
    final openButton = find.byIcon(Icons.play_arrow_rounded).first;
    await tester.tap(openButton);
    await _pumpFor(const Duration(seconds: 2));

    if (find.text('전투 시작').evaluate().isNotEmpty) {
      await tester.tap(find.text('전투 시작'));
      await _pumpFor(const Duration(seconds: 1));
    }
    await _pumpUntilVisible(find.text('드로우'));
    await _completeTutorialIfVisible(
      kind: _ContestTutorialKind.battle,
      waitForAppearance:
          !config.resumeActiveRun &&
          !config.tutorialsAlreadySeen &&
          !battleTutorialCompleted,
    );
    await _pumpUntilVisible(find.text('드로우'));
  }

  Future<void> _playCurrentBattle() async {
    var step = 0;
    while (step < config.maxBattleActions) {
      if (await _completeTutorialIfVisible(kind: _ContestTutorialKind.battle)) {
        await _pumpUntilVisible(find.text('드로우'));
        continue;
      }
      if (_isCashOutReady()) {
        return;
      }
      if (await _retryGameOverIfVisible()) {
        step = 0;
        continue;
      }

      final state = _tryReadGameState();
      if (state == null) {
        if (find.text('Station Select').evaluate().isNotEmpty) {
          await _chooseOpenBlind();
        } else {
          await _pumpFor(const Duration(milliseconds: 500));
        }
        continue;
      }
      if (find.text('Station Select').evaluate().isNotEmpty) {
        await _chooseOpenBlind();
        continue;
      }
      final session = state.session!;
      if (session.blind.scoreTowardBlind >= session.blind.targetScore) {
        await _pumpUntilCashOutReady();
        return;
      }
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      final runtimeSnapshot = runProgress.buildRuntimeSnapshot();
      final policy = gameOverRetries >= 2
          ? CompetitionPlannerV2Policy(
              enableRetryRecoveryConfirmDelay: true,
              retryRecoveryAttempt: gameOverRetries,
              avoidedActionRouteKeys: failedBattleActionRouteKeys,
            )
          : battlePolicy;
      final action = policy.chooseAction(
        session,
        jesters: runProgress.ownedJesters,
        runtimeSnapshot: runtimeSnapshot,
      );

      if (await _tryUseBattleItem(plannedAction: action)) {
        await _pumpFor(config.actionDelay + const Duration(seconds: 2));
        continue;
      }

      _record(
        'S${runProgress.stageIndex} ${tier.name} action=$action '
        'score=${session.blind.scoreTowardBlind}/${session.blind.targetScore} '
        '${_battleTraceSuffix(session, runProgress, runtimeSnapshot)}',
      );
      currentBattleActionRouteKeys.add(contestBattleActionRouteKey(action));

      switch (action.type) {
        case CompetitionBattleActionType.draw:
          final handCount = session.hand.length;
          await _tapTextUntilState(
            '드로우',
            (next) => next.session!.hand.length > handCount,
          );
          break;
        case CompetitionBattleActionType.place:
          final tile = session.hand[action.handIndex!];
          await _tapHandTile(tile.toString());
          await _tapBoardCell(action.row!, action.col!);
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) != null,
          );
          break;
        case CompetitionBattleActionType.confirm:
          final score = session.blind.scoreTowardBlind;
          final targetScore = session.blind.targetScore;
          await _tapTextUntilState(
            '확정\n하기',
            (next) =>
                _isCashOutReady() ||
                next.session!.blind.scoreTowardBlind > score,
          );
          if (_readGameState().session!.blind.scoreTowardBlind >= targetScore) {
            await _pumpUntilCashOutReady();
            return;
          }
          if (!_isCashOutReady()) {
            await _pumpUntilState(
              (next) => next.stageFlowPhase == GameStageFlowPhase.none,
              timeout: const Duration(minutes: 2),
            );
          }
          break;
        case CompetitionBattleActionType.discardHand:
          final tile = session.hand[action.handIndex!];
          final handCount = session.hand.length;
          final handDiscards = session.blind.handDiscardsRemaining;
          await _tapHandTile(tile.toString());
          await _tapText('손패\n버림');
          await _pumpUntilState(
            (next) =>
                next.session!.blind.handDiscardsRemaining < handDiscards ||
                next.session!.hand.length != handCount,
          );
          discardedHand = true;
          break;
        case CompetitionBattleActionType.discardBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('보드\n버림');
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) == null,
          );
          discardedBoard = true;
          break;
        case CompetitionBattleActionType.moveBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('타일\n이동');
          await _tapBoardCell(action.toRow!, action.toCol!);
          await _pumpUntilVisible(find.text('보드 이동'));
          await _tapText('이동');
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) == null &&
                next.session!.board.cellAt(action.toRow!, action.toCol!) !=
                    null,
          );
          movedBoard = true;
          break;
        case CompetitionBattleActionType.stop:
          if (await _retryGameOverAfterStop(action.reason ?? 'stop')) {
            step = 0;
            continue;
          }
          await _saveBotCheckpoint();
          fail('battle bot stopped: ${action.reason}');
      }

      step++;
      await _pumpFor(config.actionDelay);
    }

    final state = _readGameState();
    final progress = state.runProgress!;
    await _saveBotCheckpoint();
    fail(
      'battle action cap reached at '
      'S${progress.stageIndex} '
      '${BlindTier.values[progress.currentStationBlindTierIndex].name}',
    );
  }

  Future<bool> _retryGameOverIfVisible() async {
    final retryFinder = _visibleButtonOrTextFinder('다시 도전');
    if (retryFinder.evaluate().isEmpty) return false;
    gameOverRetries++;
    if (gameOverRetries > config.maxGameOverRetries) {
      fail(
        'game over retry cap reached: '
        '$gameOverRetries/${config.maxGameOverRetries}',
      );
    }
    failedBattleActionRouteKeys.addAll(currentBattleActionRouteKeys);
    currentBattleActionRouteKeys.clear();
    await _saveBotCheckpoint();
    _record('game over -> retry $gameOverRetries/${config.maxGameOverRetries}');
    await tester.tap(retryFinder.last, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 800));
    await _pumpUntilVisible(find.text('드로우'));
    return true;
  }

  String _battleTraceSuffix(
    RummiPokerGridSession session,
    RummiRunProgress progress,
    RummiJesterRuntimeSnapshot runtimeSnapshot,
  ) {
    final occupancy = RummiPokerGridSession.countTilesOnBoard(session.board);
    final confirmPreview = session.canConfirmAllFullLines
        ? session
              .copySnapshot()
              .confirmAllFullLines(
                jesters: progress.ownedJesters,
                runtimeSnapshot: runtimeSnapshot,
                applyScoreToBlind: false,
              )
              .result
        : null;
    final confirmText = confirmPreview == null
        ? 'confirm=none'
        : 'confirm=${confirmPreview.scoreAdded}/'
              '${confirmPreview.lineBreakdowns.length}';
    final handText = session.hand.map(_compactTileText).join(',');
    final deckTopText = session.peekDeckTop(3).map(_compactTileText).join(',');
    return 'occ=$occupancy '
        'deck=${session.deck.remaining} '
        'hand=[$handText] '
        'top=[$deckTopText] '
        '$confirmText';
  }

  String _compactTileText(Tile tile) {
    final color = switch (tile.color) {
      TileColor.red => 'R',
      TileColor.blue => 'B',
      TileColor.yellow => 'Y',
      TileColor.black => 'K',
    };
    return '$color${tile.number}';
  }

  Future<bool> _retryGameOverAfterStop(String reason) async {
    await _pumpFor(const Duration(seconds: 2));
    if (await _retryGameOverIfVisible()) return true;
    if (_isCashOutReady()) return true;
    return false;
  }

  Future<void> _handleCashOut({
    required int stage,
    required BlindTier tier,
  }) async {
    await _pumpUntilCashOutReady();
    await _pumpFor(const Duration(seconds: 3));

    if (stage == 8 && tier == BlindTier.boss) {
      _resetBattleRetryLearning();
      await _tapText('런 완료');
      _record('S8 boss: run complete');
      await _pumpFor(const Duration(seconds: 3));
      return;
    }

    _resetBattleRetryLearning();
    await _tapText('Market으로');
    _record('S$stage ${tier.name}: cashout -> market');
    await _pumpUntilVisible(find.text('다음 Station'));
    await _saveBotCheckpoint();
  }

  void _resetBattleRetryLearning() {
    gameOverRetries = 0;
    failedBattleActionRouteKeys.clear();
    currentBattleActionRouteKeys.clear();
  }

  bool _isCashOutReady() {
    if (_tryReadGameState() == null) return false;
    return find.text('정산 완료').evaluate().isNotEmpty ||
        find.text('Market으로').evaluate().isNotEmpty ||
        find.text('런 완료').evaluate().isNotEmpty;
  }

  Future<void> _pumpUntilCashOutReady({
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (_isCashOutReady()) return;
      if (await _retryGameOverIfVisible()) return;
    }
    final state = _tryReadGameState();
    final session = state?.session;
    fail(
      'Timed out waiting for cash-out UI '
      '(phase=${state?.stageFlowPhase}, '
      'score=${session?.blind.scoreTowardBlind}/${session?.blind.targetScore})',
    );
  }

  Future<void> _handleMarket({required int stage}) async {
    await _handleMarketEvidenceOnly(stage: stage);

    await _tapPrimaryActionUntilAnyVisible('다음 Station', [
      find.text('Station Select'),
    ]);
    await _saveBotCheckpoint();
  }

  Future<void> _handleMarketEvidenceOnly({required int stage}) async {
    await _completeTutorialIfVisible(
      kind: _ContestTutorialKind.market,
      waitForAppearance:
          !config.resumeActiveRun &&
          !config.tutorialsAlreadySeen &&
          !marketTutorialCompleted,
    );
    await _buyJestersIfPossible(stage);
    await _buyQuickSlotItemsIfPossible(stage);
    await _buyDeckTileIfPossible(stage);
    await _useMarketItemIfVisible(stage);
  }

  void _syncEvidenceFromState() {
    final state = _tryReadGameState();
    if (state == null) return;
    final progress = state.runProgress;
    if (progress == null) return;
    boughtJester = boughtJester || progress.boughtJesterIds.isNotEmpty;
    boughtItem = boughtItem || progress.boughtItemIds.isNotEmpty;
  }

  void _syncEvidenceFromResumeConfig() {
    final resumeSave = config.resumeSaveBase64;
    if (resumeSave.isEmpty) return;
    try {
      final decoded = utf8.decode(base64Decode(resumeSave));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final progress = json['runProgress'] as Map<String, dynamic>?;
      final session = json['session'] as Map<String, dynamic>?;
      if (progress == null) return;
      boughtJester =
          boughtJester ||
          (progress['boughtJesterIds'] as List<dynamic>? ?? const [])
              .isNotEmpty;
      boughtItem =
          boughtItem ||
          (progress['boughtItemIds'] as List<dynamic>? ?? const []).isNotEmpty;
      boughtDeckTile =
          boughtDeckTile ||
          (progress['addedDeckTiles'] as List<dynamic>? ?? const []).isNotEmpty;
      final blind = session?['blind'] as Map<String, dynamic>?;
      if (blind == null) return;
      final boardDiscardsRemaining = (blind['boardDiscardsRemaining'] as num?)
          ?.toInt();
      final boardDiscardsMax = (blind['boardDiscardsMax'] as num?)?.toInt();
      final handDiscardsRemaining = (blind['handDiscardsRemaining'] as num?)
          ?.toInt();
      final handDiscardsMax = (blind['handDiscardsMax'] as num?)?.toInt();
      final boardMovesRemaining = (blind['boardMovesRemaining'] as num?)
          ?.toInt();
      final boardMovesMax = (blind['boardMovesMax'] as num?)?.toInt();
      discardedBoard =
          discardedBoard ||
          boardDiscardsRemaining != null &&
              boardDiscardsMax != null &&
              boardDiscardsRemaining < boardDiscardsMax;
      discardedHand =
          discardedHand ||
          handDiscardsRemaining != null &&
              handDiscardsMax != null &&
              handDiscardsRemaining < handDiscardsMax;
      movedBoard =
          movedBoard ||
          boardMovesRemaining != null &&
              boardMovesMax != null &&
              boardMovesRemaining < boardMovesMax;
    } catch (_) {
      return;
    }
  }

  Future<void> _buyJestersIfPossible(int stage) async {
    if (!config.needsMarketPurchase && !config.isFullRun) return;
    await _completeTutorialIfVisible(kind: _ContestTutorialKind.market);
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Jester');

    for (var attempt = 0; attempt < 6; attempt++) {
      final state = _readGameState();
      final market = state.marketView;
      final progress = state.runProgress;
      if (market == null || progress == null || market.offers.isEmpty) return;

      final affordableOffers = market.offers
          .where((offer) => offer.isAffordable)
          .toList();
      if (affordableOffers.isEmpty) return;
      affordableOffers.sort(
        (a, b) => _jesterBotScore(
          b.card,
          stage: stage,
        ).compareTo(_jesterBotScore(a.card, stage: stage)),
      );
      final offer = affordableOffers.first;
      final offerScore = _jesterBotScore(offer.card, stage: stage);
      final jesterSlotsFull =
          market.ownedEntries.length >= progress.jesterSlotCapacity();
      if (jesterSlotsFull) {
        final ownedEntries = [...market.ownedEntries]
          ..sort(
            (a, b) =>
                _jesterBotScore(
                  a.card,
                  stateValue: a.stateValue,
                  stage: stage,
                ).compareTo(
                  _jesterBotScore(
                    b.card,
                    stateValue: b.stateValue,
                    stage: stage,
                  ),
                ),
          );
        final weakest = ownedEntries.first;
        final weakestScore = _jesterBotScore(
          weakest.card,
          stateValue: weakest.stateValue,
          stage: stage,
        );
        final canBuyAfterSelling =
            market.gold + weakest.sellPrice >= offer.price;
        if (!canBuyAfterSelling || offerScore <= weakestScore + 40) return;
        if (!await _sellSelectedJesterIfVisible(
          stage,
          contentId: weakest.contentId,
        )) {
          return;
        }
      }

      if (!await _selectJesterOfferByPrice(offer.price)) return;
      if (find.text('구매').evaluate().isEmpty) return;
      await _tapText('구매');
      boughtJester = true;
      _record('S$stage market: bought Jester');
      await _pumpFor(const Duration(seconds: 2));
    }
  }

  int _jesterBotScore(
    RummiJesterCard card, {
    int stateValue = 0,
    int stage = 1,
  }) =>
      contestFullRunBotJesterScore(card, stateValue: stateValue, stage: stage);

  Future<bool> _sellSelectedJesterIfVisible(
    int stage, {
    String? contentId,
  }) async {
    if (find.text('판매').evaluate().isEmpty) {
      await _selectOwnedJesterForSale(contentId: contentId);
    }
    if (find.text('판매').evaluate().isEmpty) return false;
    await _tapText('판매');
    _record('S$stage market: sold Jester for slot');
    await _pumpFor(const Duration(seconds: 2));
    return true;
  }

  Future<void> _selectOwnedJesterForSale({String? contentId}) async {
    final ownedEntries = _readGameState().marketView?.ownedEntries;
    if (ownedEntries == null || ownedEntries.isEmpty) return;
    for (final entry in ownedEntries) {
      if (contentId != null && entry.contentId != contentId) continue;
      final slotFinder = find.byWidgetPredicate(
        (widget) =>
            widget is GameJesterSlot &&
            !widget.locked &&
            widget.card?.id == entry.card.id,
      );
      if (slotFinder.evaluate().isEmpty) continue;
      await tester.tap(slotFinder.first, warnIfMissed: false);
      await _pumpFor(const Duration(milliseconds: 500));
      if (find.text('판매').evaluate().isNotEmpty) return;
    }
  }

  Future<bool> _selectJesterOfferByPrice(int price) async {
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Jester');
    final priceFinder = find.text('${price}G');
    if (priceFinder.evaluate().isEmpty) return false;
    await tester.tap(priceFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 600));
    return true;
  }

  Future<void> _buyDeckTileIfPossible(int stage) async {
    if (!config.needsMarketPurchase && !config.isFullRun) return;
    await _completeTutorialIfVisible(kind: _ContestTutorialKind.market);
    final state = _readGameState();
    final tileOffers =
        state.marketView?.tileOffers
            .where((offer) => offer.isAffordable)
            .toList() ??
        const [];
    if (tileOffers.isEmpty) return;
    tileOffers.sort((a, b) {
      final scoreDiff = _deckTileBotScore(
        b.tile,
      ).compareTo(_deckTileBotScore(a.tile));
      if (scoreDiff != 0) return scoreDiff;
      return a.price.compareTo(b.price);
    });
    final bestOffer = tileOffers.first;
    if (!await _selectTileOfferByPrice(bestOffer.price)) return;
    if (find.text('구매').evaluate().isEmpty) return;
    await _tapText('구매');
    boughtDeckTile = true;
    _record('S$stage market: bought deck tile ${bestOffer.tile.code}');
    await _pumpFor(const Duration(seconds: 2));
  }

  int _deckTileBotScore(Tile tile) {
    final rankScore = tile.number >= 10 ? 18 : tile.number;
    return 40 + rankScore + tile.baseChipValue;
  }

  Future<bool> _selectTileOfferByPrice(int price) async {
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Tile');
    final priceFinder = find.text('${price}G');
    if (priceFinder.evaluate().isEmpty) return false;
    await tester.tap(priceFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 600));
    return true;
  }

  Future<void> _buyQuickSlotItemsIfPossible(int stage) async {
    if (!config.needsItemPurchase && !config.isFullRun) return;
    await _completeTutorialIfVisible(kind: _ContestTutorialKind.market);
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Q-Slot');

    for (var attempt = 0; attempt < 6; attempt++) {
      final state = _readGameState();
      final market = state.marketView;
      final progress = state.runProgress;
      if (market == null || progress == null) return;
      final quickSlotCapacity = progress.quickSlotCapacity(
        itemCatalog: itemCatalog,
      );
      final quickSlotCount = progress.itemInventory.quickSlotItemIds.length;
      final affordableOffers = market.itemOffers
          .where(
            (offer) =>
                offer.item.placement == ItemPlacement.quickSlot &&
                offer.isAffordable,
          )
          .toList();
      if (affordableOffers.isEmpty) return;
      affordableOffers.sort(
        (a, b) => contestFullRunBotItemScore(
          b.item,
          stage: stage,
        ).compareTo(contestFullRunBotItemScore(a.item, stage: stage)),
      );
      final bestOffer = affordableOffers.first;
      final offerScore = contestFullRunBotItemScore(
        bestOffer.item,
        stage: stage,
      );
      if (quickSlotCount >= quickSlotCapacity) {
        final weakest = _weakestOwnedQuickSlotItem(market, stage: stage);
        if (weakest == null) return;
        final weakestScore = contestFullRunBotItemScore(
          weakest.item!,
          stage: stage,
        );
        final canBuyAfterSelling =
            market.gold + weakest.item!.sellPrice >= bestOffer.price;
        if (!canBuyAfterSelling || offerScore <= weakestScore + 25) return;
        if (!await _sellMarketItemSlotIfVisible(stage, weakest)) return;
      }

      await _selectItemOfferLaneForPlacement(bestOffer.item.placement);
      if (!await _selectItemOfferByPrice(
        bestOffer.price,
        placement: bestOffer.item.placement,
      )) {
        return;
      }
      if (find.text('구매').evaluate().isEmpty) return;
      await _tapText('구매');
      boughtItem = true;
      _record('S$stage market: bought Q-Slot Item');
      await _pumpFor(const Duration(seconds: 2));
    }
  }

  Future<void> _selectItemOfferLaneForPlacement(ItemPlacement placement) async {
    switch (placement) {
      case ItemPlacement.quickSlot:
        await _tapTextIfVisible('Jester / Slots');
        await _tapTextIfVisible('Q-Slot');
      case ItemPlacement.passiveRack:
        await _tapTextIfVisible('Jester / Slots');
        await _tapTextIfVisible('Passive');
      case ItemPlacement.inventory:
        await _tapTextIfVisible('Tool / Gear');
        await _tapTextIfVisible('Tool');
      case ItemPlacement.equipped:
        await _tapTextIfVisible('Tool / Gear');
        await _tapTextIfVisible('Gear');
    }
  }

  Future<bool> _selectItemOfferByPrice(
    int price, {
    required ItemPlacement placement,
  }) async {
    await _selectItemOfferLaneForPlacement(placement);
    final priceFinder = find.text('${price}G');
    if (priceFinder.evaluate().isEmpty) return false;
    await tester.tap(priceFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 600));
    return true;
  }

  RummiMarketItemSlotView? _weakestOwnedQuickSlotItem(
    RummiMarketRuntimeFacade market, {
    required int stage,
  }) {
    final candidates = market.itemSlots
        .where(
          (slot) =>
              slot.placement == ItemPlacement.quickSlot &&
              !slot.locked &&
              slot.item != null,
        )
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => contestFullRunBotItemScore(
        a.item!,
        stage: stage,
      ).compareTo(contestFullRunBotItemScore(b.item!, stage: stage)),
    );
    return candidates.first;
  }

  Future<bool> _sellMarketItemSlotIfVisible(
    int stage,
    RummiMarketItemSlotView slot,
  ) async {
    if (find.text('판매').evaluate().isEmpty) {
      await _selectOwnedMarketItemSlot(slot);
    }
    if (find.text('판매').evaluate().isEmpty) return false;
    await _tapText('판매');
    _record('S$stage market: sold Q-Slot Item for replacement');
    await _pumpFor(const Duration(seconds: 2));
    return true;
  }

  Future<void> _selectOwnedMarketItemSlot(RummiMarketItemSlotView slot) async {
    final slotFinder = find.byWidgetPredicate((widget) {
      if (widget.runtimeType.toString() != '_MarketItemGhostChip') {
        return false;
      }
      try {
        final dynamic dynamicWidget = widget;
        final dynamic widgetSlot = dynamicWidget.slot;
        return widgetSlot.contentId == slot.contentId &&
            widgetSlot.slotLabel == slot.slotLabel;
      } catch (_) {
        return false;
      }
    });
    if (slotFinder.evaluate().isEmpty) return;
    await tester.tap(slotFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 500));
  }

  Future<void> _useMarketItemIfVisible(int stage) async {
    if (!config.needsItemUse && !config.isFullRun) return;
    await _completeTutorialIfVisible(kind: _ContestTutorialKind.market);
    if (usedItem || find.text('사용').evaluate().isEmpty) return;
    await _tapText('사용');
    usedItem = true;
    _record('S$stage market: used Item');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<bool> _tryUseBattleItem({
    required CompetitionBattleAction plannedAction,
  }) async {
    if (!config.needsItemUse && !config.isFullRun) return false;
    await _completeTutorialIfVisible(kind: _ContestTutorialKind.battle);
    if (usedItem && !config.isFullRun) return false;
    final state = _tryReadGameState();
    if (state == null) return false;
    final inventory = state.runProgress!.itemInventory;
    if (inventory.quickSlotItemIds.isEmpty) return false;
    final choice = _chooseBattleItemToUse(state, plannedAction: plannedAction);
    if (choice == null) return false;
    await _tapTextIfVisible('Slots');
    final slotLabel = find.text('Q${choice.slotIndex + 1}');
    if (slotLabel.evaluate().isEmpty) return false;
    await tester.tap(slotLabel.first);
    await _pumpFor(const Duration(milliseconds: 500));
    if (find.text('사용').evaluate().isEmpty) return false;
    await _tapText('사용');
    if (choice.item.effect.op == 'peek_deck_discard_one') {
      await _resolveDeckNeedleDialog(choice, state.session!);
    }
    usedItem = true;
    _record(
      'S${state.runProgress!.stageIndex} '
      '${BlindTier.values[state.runProgress!.currentStationBlindTierIndex].name}: '
      'used battle Item ${choice.item.id} op=${choice.item.effect.op}',
    );
    await _pumpFor(const Duration(seconds: 1));
    return true;
  }

  Future<void> _resolveDeckNeedleDialog(
    _BattleItemChoice choice,
    RummiPokerGridSession session,
  ) async {
    await _pumpFor(const Duration(milliseconds: 500));
    final dialogFinder = find.byType(GameTileChoiceDialog);
    if (dialogFinder.evaluate().isEmpty) return;
    final discardIndex = _chooseDeckNeedleDiscardIndex(choice.item, session);
    if (discardIndex == null) {
      if (find.text('닫기').evaluate().isNotEmpty) {
        await _tapText('닫기');
      }
      return;
    }
    final tileFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(GameRummiTileCard),
    );
    if (tileFinder.evaluate().length <= discardIndex) {
      if (find.text('닫기').evaluate().isNotEmpty) {
        await _tapText('닫기');
      }
      return;
    }
    await tester.tap(tileFinder.at(discardIndex), warnIfMissed: false);
    _record('deck_needle: discarded top-window tile index $discardIndex');
    await _pumpFor(const Duration(milliseconds: 600));
  }

  Future<bool> _completeTutorialIfVisible({
    required _ContestTutorialKind kind,
    bool waitForAppearance = false,
  }) async {
    var sawTutorial = false;
    final maxSteps = waitForAppearance ? 24 : 8;
    for (var step = 0; step < maxSteps; step++) {
      await tester.pump(const Duration(milliseconds: 350));
      final doneFinder = _firstVisibleTutorialButton(config.tutorialDoneLabels);
      if (doneFinder != null) {
        sawTutorial = true;
        await tester.tap(doneFinder.last, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 700));
        _markTutorialCompleted(kind);
        return true;
      }
      final nextFinder = _firstVisibleTutorialButton(config.tutorialNextLabels);
      if (nextFinder != null) {
        sawTutorial = true;
        await tester.tap(nextFinder.last, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 700));
        continue;
      }
      if (!sawTutorial && !waitForAppearance) return false;
      await _pumpFor(const Duration(milliseconds: 300));
    }
    if (sawTutorial) {
      fail('tutorial did not reach Done for ${kind.name}');
    }
    if (waitForAppearance) {
      fail('expected ${kind.name} tutorial did not appear');
    }
    return false;
  }

  Finder? _firstVisibleTutorialButton(List<String> labels) {
    for (final label in labels) {
      final finder = find.widgetWithText(FilledButton, label);
      if (finder.evaluate().isNotEmpty) return finder;
    }
    return null;
  }

  void _markTutorialCompleted(_ContestTutorialKind kind) {
    switch (kind) {
      case _ContestTutorialKind.battle:
        if (battleTutorialCompleted) return;
        battleTutorialCompleted = true;
        _record('battle tutorial completed');
      case _ContestTutorialKind.market:
        if (marketTutorialCompleted) return;
        marketTutorialCompleted = true;
        _record('market tutorial completed');
    }
  }

  _BattleItemChoice? _chooseBattleItemToUse(
    GameSessionState state, {
    required CompetitionBattleAction plannedAction,
  }) {
    final catalog = itemCatalog;
    final session = state.session;
    final runProgress = state.runProgress;
    if (catalog == null || session == null || runProgress == null) return null;
    final inventory = runProgress.itemInventory;
    for (var index = 0; index < inventory.quickSlotItemIds.length; index++) {
      final itemId = inventory.quickSlotItemIds[index];
      final item = catalog.findById(itemId);
      if (item == null ||
          !_canUseBattleItemNow(
            item,
            session,
            runProgress,
            plannedAction: plannedAction,
          )) {
        continue;
      }
      return _BattleItemChoice(slotIndex: index, item: item);
    }
    return null;
  }

  bool _canUseBattleItemNow(
    ItemDefinition item,
    RummiPokerGridSession session,
    RummiRunProgress runProgress, {
    required CompetitionBattleAction plannedAction,
  }) {
    if (item.placement != ItemPlacement.quickSlot || !item.usableInBattle) {
      return false;
    }
    final hasItem = runProgress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!hasItem) return false;
    if (!contestBattleItemOpSupportsPlannedAction(
      item.effect.op,
      plannedAction.type,
    )) {
      return false;
    }

    return switch (item.effect.op) {
      'add_board_move' =>
        plannedAction.type == CompetitionBattleActionType.moveBoard &&
            (plannedAction.gain ?? 0) >= 70 &&
            _isBattleTargetLate(session),
      'mark_next_board_move_bonus' => true,
      'add_board_discard' =>
        battlePolicy.chooseScoringBoardDiscard(
              session,
              jesters: runProgress.ownedJesters,
              runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
            ) !=
            null,
      'add_hand_discard' =>
        session.hand.length >= session.maxHandSize &&
            battlePolicy.chooseHandDiscard(session) != null,
      'chips_bonus' ||
      'mult_bonus' ||
      'xmult_bonus' ||
      'temporary_overlap_cap_bonus' ||
      'add_percent_of_first_confirm_score' => _hasScoringConfirmNow(
        session,
        runProgress,
      ),
      'undo_last_board_move' => false,
      'draw_if_hand_empty' => session.hand.isEmpty && session.canDrawFromDeck,
      'increase_hand_size' => session.hand.length >= session.maxHandSize,
      'peek_deck_discard_one' =>
        _chooseDeckNeedleDiscardIndex(item, session) != null,
      _ => false,
    };
  }

  bool _isBattleTargetLate(RummiPokerGridSession session) {
    final target = session.blind.targetScore;
    if (target <= 0) return false;
    final progress = session.blind.scoreTowardBlind / target;
    final remainingScore = target - session.blind.scoreTowardBlind;
    return progress >= 0.65 ||
        remainingScore <= 300 ||
        (RummiPokerGridSession.countTilesOnBoard(session.board) >= 20 &&
            remainingScore <= 520);
  }

  bool _hasScoringConfirmNow(
    RummiPokerGridSession session,
    RummiRunProgress runProgress,
  ) {
    if (!session.canConfirmAllFullLines) return false;
    final preview = session.copySnapshot().confirmAllFullLines(
      jesters: runProgress.ownedJesters,
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      applyScoreToBlind: false,
    );
    return preview.result.lineBreakdowns.length >= 2 &&
        preview.result.scoreAdded > 0;
  }

  int? _chooseDeckNeedleDiscardIndex(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final windowSize =
        (item.effect.value('lookAt') as num?)?.toInt() ??
        (item.effect.value('peek') as num?)?.toInt() ??
        3;
    final candidates = session.peekDeckTop(windowSize);
    if (candidates.length < 2) return null;
    if (!session.canDrawFromDeck) return null;
    final policy = const CompetitionPlannerV2Policy();
    var bestScore = -1 << 30;
    var worstScore = 1 << 30;
    var worstIndex = 0;
    for (var index = 0; index < candidates.length; index++) {
      final score = policy.bestPlacementPotentialForTile(
        session,
        candidates[index],
      );
      if (score > bestScore) bestScore = score;
      if (score < worstScore) {
        worstScore = score;
        worstIndex = index;
      }
    }
    // 덱 조작 아이템은 증거용으로 소모하지 않고, 선택지 품질 차이가
    // 분명할 때만 낮은 잠재력 타일을 제거한다.
    if (bestScore - worstScore < 18 && worstScore >= 10) return null;
    return worstIndex;
  }

  bool _shouldStopAt({
    required _ContestBotScene scene,
    int? stage,
    BlindTier? tier,
  }) {
    if (config.isFullRun || scene != config.targetScene) return false;
    if (stage == null || tier == null) return true;
    return config.matchesTarget(stage: stage, tier: tier);
  }

  Future<void> _finishSubRun(String reason) async {
    await _saveBotCheckpoint();
    if (config.requiredEvidence == 'market_purchase') {
      expect(
        boughtJester,
        isTrue,
        reason: 'contest_sub_run_bot needs purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_purchase') {
      expect(
        boughtItem,
        isTrue,
        reason: 'contest_sub_run_bot needs item purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_use') {
      expect(
        usedItem,
        isTrue,
        reason: 'contest_sub_run_bot needs item use evidence',
      );
    }
    _printPassLog(reason);
  }

  Future<void> _saveBotCheckpoint() async {
    GameSessionState? state;
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(end)) {
      state = _tryReadGameState();
      if (state != null) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (state == null) return;
    final session = state.session;
    final runProgress = state.runProgress;
    final stageStartSnapshot = state.stageStartSnapshot;
    final gameView = _tryReadGameView();
    if (session == null || runProgress == null || stageStartSnapshot == null) {
      return;
    }
    final scene = find.text('Station Select').evaluate().isNotEmpty
        ? ActiveRunScene.blindSelect
        : find.text('다음 Station').evaluate().isNotEmpty
        ? ActiveRunScene.shop
        : ActiveRunScene.battle;
    final runtime = ActiveRunRuntimeState(
      activeScene: scene,
      difficulty: gameView?.difficulty ?? config.difficulty,
      runModifier: state.runModifier,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
    await ActiveRunSaveService.saveRuntimeState(runtime);
    final checkpointJson = ActiveRunSaveService.runtimeStateToJson(runtime);
    final checkpointBase64 = base64Encode(utf8.encode(checkpointJson));
    // 스크립트가 다음 resume 실행에 주입할 수 있도록 한 줄 checkpoint를 남긴다.
    debugPrint('CONTEST_BOT_CHECKPOINT_B64:$checkpointBase64');
    _record(
      'checkpoint saved scene=${scene.name} '
      'S${runProgress.stageIndex} '
      'tier=${runProgress.currentStationBlindTierIndex} '
      'gold=${runProgress.gold} '
      'jesters=${runProgress.ownedJesters.length} '
      'items=${runProgress.itemInventory.ownedItems.length} '
      'quick=${runProgress.itemInventory.quickSlotItemIds.length}',
    );
  }

  bool _shouldStopAtCurrentBattle() {
    if (config.isFullRun || config.targetScene != _ContestBotScene.battle) {
      return false;
    }
    final state = _readGameState();
    final progress = state.runProgress!;
    return config.matchesTarget(
      stage: progress.stageIndex,
      tier: BlindTier.values[progress.currentStationBlindTierIndex],
    );
  }

  void _printPassLog(String stopReason) {
    debugPrint('${config.logPrefix}_PASS');
    debugPrint('${config.logPrefix}: stop_reason=$stopReason');
    for (final entry in log) {
      debugPrint('${config.logPrefix}: $entry');
    }
  }

  void _record(String entry) {
    log.add(entry);
    debugPrint('${config.logPrefix}: $entry');
  }

  GameSessionState _readGameState() {
    final state = _tryReadGameState();
    expect(state, isNotNull);
    return state!;
  }

  GameSessionState? _tryReadGameState() {
    final gameView = _tryReadGameView();
    if (gameView == null) return null;
    final gameViewFinder = find.byType(GameView, skipOffstage: false);
    final element = tester.element(gameViewFinder.first);
    final container = ProviderScope.containerOf(element);
    final args = GameSessionArgs(
      runSeed: gameView.runSeed,
      restoredRun: gameView.restoredRun,
      debugFixtureId: gameView.debugFixtureId,
      difficulty: gameView.difficulty,
      runModifier: gameView.runModifier,
      blindTier: gameView.blindTier,
    );
    return container.read(gameSessionNotifierProvider(args));
  }

  GameView? _tryReadGameView() {
    final gameViewFinder = find.byType(GameView, skipOffstage: false);
    if (gameViewFinder.evaluate().isEmpty) return null;
    return tester.widget<GameView>(gameViewFinder.first);
  }

  Future<void> _tapHandTile(String tileKey) async {
    final finder = find.byKey(ValueKey('settled-$tileKey'));
    await _pumpUntilVisible(finder);
    await tester.tap(finder.first, warnIfMissed: false);
  }

  Future<void> _tapBoardCell(int row, int col) async {
    await tester.tap(
      find.byKey(ValueKey('board-cell-$row-$col')),
      warnIfMissed: false,
    );
  }

  Future<void> _tapText(String text) async {
    final finder = await _pumpUntilTappableText(text);
    await tester.tap(finder.last, warnIfMissed: false);
  }

  Future<void> _tapPrimaryActionUntilAnyVisible(
    String actionText,
    List<Finder> resultFinders, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (resultFinders.any((finder) => finder.evaluate().isNotEmpty)) return;

      final actionFinder = _buttonOrTextFinder(actionText);
      if (actionFinder.evaluate().isNotEmpty) {
        // 동일 라벨이 transition 뒤쪽 위젯 트리에 남는 경우가 있어 하단 주요 액션은
        // 현재 route에서 마지막으로 그려진 버튼을 우선 누른다.
        await tester.tap(actionFinder.last, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 800));
      }
    }
    fail('Timed out waiting for $resultFinders after tapping "$actionText"');
  }

  Future<void> _tapTextIfVisible(String text) async {
    final finder = _visibleButtonOrTextFinder(text);
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 500));
  }

  Future<void> _tapTextUntilState(
    String actionText,
    bool Function(GameSessionState state) predicate, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (predicate(_readGameState())) return;
      if (await _retryGameOverIfVisible()) return;

      final actionFinder = _buttonOrTextFinder(actionText);
      if (actionFinder.evaluate().isNotEmpty) {
        await tester.tap(actionFinder.first, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 700));
      }
    }
    fail('Timed out waiting for game state update after tapping "$actionText"');
  }

  Finder _buttonOrTextFinder(String text) {
    return _visibleButtonOrTextFinder(text);
  }

  Finder _visibleButtonOrTextFinder(String text) {
    final actionButton = find.widgetWithText(GameActionButton, text);
    if (actionButton.evaluate().isNotEmpty) return actionButton;
    return find.text(text);
  }

  Future<Finder> _pumpUntilTappableText(
    String text, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      final finder = _visibleButtonOrTextFinder(text);
      if (finder.evaluate().isNotEmpty) return finder;
    }
    fail('Timed out waiting for tappable text "$text"');
  }

  Future<void> _pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> _pumpFor(Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> _pumpUntilState(
    bool Function(GameSessionState state) predicate, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
      if (predicate(_readGameState())) return;
      if (await _retryGameOverIfVisible()) return;
    }
    fail('Timed out waiting for game state update');
  }
}
