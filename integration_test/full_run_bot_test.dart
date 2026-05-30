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
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
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
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_tile_choice_dialog.dart';

import 'full_run_bot_policy.dart';
import 'full_run_bot_market_policy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'full-run bot runs through real browser UI',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      binding.shouldPropagateDevicePointerEvents = true;

      final bot = _FullRunBot(
        tester: tester,
        config: _FullRunBotConfig.fromEnvironment(),
      );
      try {
        await bot.run();
      } finally {
        await bot.flushTrace();
        binding.shouldPropagateDevicePointerEvents = false;
      }
    },
    // fresh S1~S8 full-run은 브라우저 구동과 retry 로그까지 포함해 길게 잡는다.
    timeout: const Timeout(Duration(minutes: 120)),
  );
}

enum _FullRunBotMode { full, sub }

enum _FullRunBotScene { stationSelect, battle, cashOut, market, runComplete }

enum _FullRunTutorialKind { battle, market }

class _FullRunBotConfig {
  const _FullRunBotConfig({
    required this.mode,
    required this.seed,
    required this.difficultyName,
    required this.localeName,
    required this.maxBattleActions,
    required this.maxGameOverRetries,
    required this.resumeActiveRun,
    required this.resumeSaveBase64,
    required this.challengeCarryoverBase64,
    required this.tutorialsAlreadySeen,
    required this.actionDelay,
    required this.targetStage,
    required this.targetTierName,
    required this.targetScene,
    required this.requiredEvidence,
    required this.tracePath,
  });

  factory _FullRunBotConfig.fromEnvironment() {
    const modeValue = String.fromEnvironment(
      'FULL_RUN_BOT_MODE',
      defaultValue: 'full',
    );
    return _FullRunBotConfig(
      mode: modeValue == 'sub' ? _FullRunBotMode.sub : _FullRunBotMode.full,
      seed: const int.fromEnvironment('FULL_RUN_BOT_SEED', defaultValue: 91460),
      difficultyName: const String.fromEnvironment(
        'FULL_RUN_BOT_DIFFICULTY',
        defaultValue: 'standard',
      ),
      localeName: const String.fromEnvironment(
        'FULL_RUN_BOT_LOCALE',
        defaultValue: 'ko',
      ),
      maxBattleActions: const int.fromEnvironment(
        'FULL_RUN_BOT_MAX_BATTLE_ACTIONS',
        defaultValue: 420,
      ),
      maxGameOverRetries: const int.fromEnvironment(
        'FULL_RUN_BOT_MAX_GAME_OVER_RETRIES',
        defaultValue: 24,
      ),
      resumeActiveRun: const bool.fromEnvironment(
        'FULL_RUN_BOT_RESUME_ACTIVE_RUN',
      ),
      resumeSaveBase64: const String.fromEnvironment(
        'FULL_RUN_BOT_RESUME_SAVE_B64',
      ),
      challengeCarryoverBase64: const String.fromEnvironment(
        'FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64',
      ),
      tutorialsAlreadySeen: const bool.fromEnvironment(
        'FULL_RUN_BOT_TUTORIALS_ALREADY_SEEN',
      ),
      actionDelay: Duration(
        milliseconds: const int.fromEnvironment(
          'FULL_RUN_BOT_ACTION_DELAY_MS',
          defaultValue: 250,
        ),
      ),
      targetStage: const int.fromEnvironment(
        'FULL_RUN_BOT_TARGET_STAGE',
        defaultValue: 1,
      ),
      targetTierName: const String.fromEnvironment(
        'FULL_RUN_BOT_TARGET_TIER',
        defaultValue: 'boss',
      ),
      targetScene: _parseScene(
        const String.fromEnvironment(
          'FULL_RUN_BOT_TARGET_SCENE',
          defaultValue: 'cashOut',
        ),
      ),
      requiredEvidence: const String.fromEnvironment(
        'FULL_RUN_BOT_REQUIRED_EVIDENCE',
      ),
      tracePath: const String.fromEnvironment('FULL_RUN_BOT_TRACE_PATH'),
    );
  }

  final _FullRunBotMode mode;
  final int seed;
  final String difficultyName;
  final String localeName;
  final int maxBattleActions;
  final int maxGameOverRetries;
  final bool resumeActiveRun;
  final String resumeSaveBase64;
  final String challengeCarryoverBase64;
  final bool tutorialsAlreadySeen;
  final Duration actionDelay;
  final int targetStage;
  final String targetTierName;
  final _FullRunBotScene targetScene;
  final String requiredEvidence;
  final String tracePath;

  String get logPrefix =>
      mode == _FullRunBotMode.full ? 'FULL_RUN_BOT' : 'FULL_RUN_SUB_BOT';

  bool get isFullRun => mode == _FullRunBotMode.full;

  bool get traceEnabled => tracePath.isNotEmpty;

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

  static _FullRunBotScene _parseScene(String value) {
    return switch (value) {
      'stationSelect' || 'StationSelect' => _FullRunBotScene.stationSelect,
      'battle' || 'Battle' => _FullRunBotScene.battle,
      'market' || 'Market' => _FullRunBotScene.market,
      'runComplete' || 'RunComplete' => _FullRunBotScene.runComplete,
      _ => _FullRunBotScene.cashOut,
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
class _FullRunBot {
  _FullRunBot({required this.tester, required this.config});

  final WidgetTester tester;
  final _FullRunBotConfig config;
  final FullRunPlannerV2Policy battlePolicy = const FullRunPlannerV2Policy();
  final FullRunPlannerV2Policy retryRecoveryBattlePolicy =
      const FullRunPlannerV2Policy(enableRetryRecoveryConfirmDelay: true);
  final List<String> log = <String>[];
  int traceSequence = 0;
  int traceRowCount = 0;
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
        _shouldStopAt(scene: _FullRunBotScene.stationSelect)) {
      await _finishSubRun('target station select reached');
      return;
    }

    if (find.text('다음 Station').evaluate().isNotEmpty) {
      final progress = _readGameState().runProgress!;
      await _handleMarket(stage: progress.stageIndex);
      if (find.text('Station Select').evaluate().isNotEmpty &&
          _shouldStopAt(scene: _FullRunBotScene.stationSelect)) {
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
        scene: _FullRunBotScene.cashOut,
        stage: stage,
        tier: tier,
      )) {
        await _pumpUntilCashOutReady();
        await _finishSubRun('target cash-out reached');
        return;
      }

      await _handleCashOut(stage: stage, tier: tier);
      if (_shouldStopAt(
        scene: _FullRunBotScene.market,
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

    expect(boughtJester, isTrue, reason: 'full_run_bot must buy a Jester');
    expect(boughtItem, isTrue, reason: 'full_run_bot must buy an Item');
    if (!config.resumeActiveRun && !config.tutorialsAlreadySeen) {
      expect(
        battleTutorialCompleted,
        isTrue,
        reason: 'fresh full_run_bot must complete battle tutorial',
      );
      expect(
        marketTutorialCompleted,
        isTrue,
        reason: 'fresh full_run_bot must complete market tutorial',
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
    await _restoreChallengeCarryoverIfConfigured();
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
    _trace('run_start', {
      'fresh_storage': !config.resumeActiveRun,
      'tutorials_already_seen': config.tutorialsAlreadySeen,
    });

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
        _trace('run_resumed', {
          'active_scene': resumeRuntime.activeScene.name,
          'stage': resumeRuntime.runProgress.stageIndex,
          'tier_index': resumeRuntime.runProgress.currentStationBlindTierIndex,
          'run_progress': _runProgressTrace(resumeRuntime.runProgress),
          'session': _sessionTrace(resumeRuntime.session),
        });
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
    _trace('seeded_run_opened', {
      'modifier': 'basic',
      'difficulty': config.difficulty.name,
    });
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

    await _dismissBlockingDialogsIfVisible();
    await _pumpUntilVisible(find.text('드로우'));
    await _dismissBlockingDialogsIfVisible();
    await _completeTutorialIfVisible(
      kind: _FullRunTutorialKind.battle,
      waitForAppearance:
          !config.resumeActiveRun &&
          !config.tutorialsAlreadySeen &&
          !battleTutorialCompleted,
    );
    await _pumpUntilVisible(find.text('드로우'));
    final state = _tryReadGameState();
    final progress = state?.runProgress;
    if (state?.session != null && progress != null) {
      _trace('blind_opened', {
        'stage': progress.stageIndex,
        'tier': BlindTier.values[progress.currentStationBlindTierIndex].name,
        'session': _sessionTrace(state!.session!),
        'run_progress': _runProgressTrace(progress),
      });
    }
  }

  Future<void> _playCurrentBattle() async {
    var step = 0;
    while (step < config.maxBattleActions) {
      if (await _dismissBlockingDialogsIfVisible()) {
        await _pumpUntilVisible(find.text('드로우'));
        continue;
      }
      if (await _completeTutorialIfVisible(kind: _FullRunTutorialKind.battle)) {
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
          ? FullRunPlannerV2Policy(
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
      final beforeTrace = _battleSnapshotTrace(state);
      final actionTrace = _battleActionTrace(action, session);

      if (await _tryUseBattleItem(plannedAction: action)) {
        await _pumpFor(config.actionDelay + const Duration(seconds: 2));
        continue;
      }

      _record(
        'S${runProgress.stageIndex} ${tier.name} action=$action '
        'score=${session.blind.scoreTowardBlind}/${session.blind.targetScore} '
        '${_battleTraceSuffix(session, runProgress, runtimeSnapshot)}',
      );
      currentBattleActionRouteKeys.add(fullRunBattleActionRouteKey(action));

      switch (action.type) {
        case FullRunBattleActionType.draw:
          final handCount = session.hand.length;
          await _tapTextUntilState(
            '드로우',
            (next) => next.session!.hand.length > handCount,
          );
          break;
        case FullRunBattleActionType.place:
          final tile = session.hand[action.handIndex!];
          await _tapHandTile(tile.toString());
          await _tapBoardCell(action.row!, action.col!);
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) != null,
          );
          break;
        case FullRunBattleActionType.confirm:
          final score = session.blind.scoreTowardBlind;
          final targetScore = session.blind.targetScore;
          await _tapTextUntilState(
            '확정\n하기',
            (next) =>
                _isCashOutReady() ||
                next.session!.blind.scoreTowardBlind > score,
          );
          await _pumpUntilConfirmSettlementComplete(
            previousScore: score,
            targetScore: targetScore,
          );
          if (_isCashOutReady()) return;
          break;
        case FullRunBattleActionType.discardHand:
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
        case FullRunBattleActionType.discardBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('보드\n버림');
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) == null,
          );
          discardedBoard = true;
          break;
        case FullRunBattleActionType.moveBoard:
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
        case FullRunBattleActionType.stop:
          _trace('battle_action_stop', {
            'stage': runProgress.stageIndex,
            'tier': tier.name,
            'step': step,
            'action': actionTrace,
            'before': beforeTrace,
          });
          if (await _retryGameOverAfterStop(action.reason ?? 'stop')) {
            step = 0;
            continue;
          }
          await _saveBotCheckpoint();
          fail('battle bot stopped: ${action.reason}');
      }

      final afterState = _tryReadGameState();
      _trace('battle_action', {
        'stage': runProgress.stageIndex,
        'tier': tier.name,
        'step': step,
        'policy': policy.id,
        'retry_recovery': gameOverRetries >= 2,
        'action': actionTrace,
        'before': beforeTrace,
        if (afterState != null) 'after': _battleSnapshotTrace(afterState),
      });

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
    _trace('game_over_retry', {
      'retry': gameOverRetries,
      'max_retries': config.maxGameOverRetries,
      'failed_route_keys': failedBattleActionRouteKeys.toList(),
    });
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
      _emitChallengeCarryover();
      await _tapText('런 완료');
      _record('S8 boss: run complete');
      _trace('run_complete', {
        'stage': stage,
        'tier': tier.name,
        'run_progress': _runProgressTrace(_readGameState().runProgress!),
      });
      await _pumpFor(const Duration(seconds: 3));
      return;
    }

    _resetBattleRetryLearning();
    await _tapText('Market으로');
    _record('S$stage ${tier.name}: cashout -> market');
    _trace('cashout_to_market', {
      'stage': stage,
      'tier': tier.name,
      'run_progress': _runProgressTrace(_readGameState().runProgress!),
    });
    await _pumpUntilVisible(find.text('다음 Station'));
    await _saveBotCheckpoint();
  }

  Future<void> _restoreChallengeCarryoverIfConfigured() async {
    if (config.difficulty != NewRunDifficulty.challenge ||
        config.challengeCarryoverBase64.isEmpty) {
      return;
    }
    final decoded = utf8.decode(base64Decode(config.challengeCarryoverBase64));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    await RunUnlockStateService.save(RunUnlockState.fromJson(json));
    final carryover = RunUnlockState.fromJson(json).challengeCarryover;
    _record(
      'challenge carryover restored '
      'grown=${carryover?.grownRankCount ?? 0} '
      'deck=${carryover?.addedDeckTiles.length ?? 0}',
    );
  }

  void _emitChallengeCarryover() {
    if (config.difficulty != NewRunDifficulty.standard) return;
    final progress = _readGameState().runProgress!;
    final state = RunUnlockState(
      unlockedDifficultyNames: const <String>{'challenge', 'standard'},
      clearedDifficultyNames: const <String>{'standard'},
      availableDeckIds: const <String>{'basic_deck'},
      unlockedRunModifierIds: const <String>{'basic'},
      insight: 0,
      challengeCarryover: ChallengeCarryoverSnapshot(
        playedHandCounts: progress.snapshotPlayedHandCounts(),
        handGrowthStates: progress.snapshotHandGrowthStates(),
        addedDeckTiles: List<Tile>.from(progress.addedDeckTiles),
      ),
    );
    final encoded = base64Encode(utf8.encode(jsonEncode(state.toJson())));
    debugPrint('FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64:$encoded');
    _record(
      'challenge carryover exported '
      'grown=${state.challengeCarryover?.grownRankCount ?? 0} '
      'deck=${state.challengeCarryover?.addedDeckTiles.length ?? 0}',
    );
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
    _traceMarketState('market_enter', stage);
    await _completeTutorialIfVisible(
      kind: _FullRunTutorialKind.market,
      waitForAppearance:
          !config.resumeActiveRun &&
          !config.tutorialsAlreadySeen &&
          !marketTutorialCompleted,
    );
    await _buyQuickSlotItemsIfPossible(stage);
    await _buyJestersIfPossible(stage);
    await _buyQuickSlotItemsIfPossible(stage);
    await _buyDeckTileIfPossible(stage);
    await _useMarketItemIfVisible(stage);
    _traceMarketState('market_after_evidence', stage);
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
    await _completeTutorialIfVisible(kind: _FullRunTutorialKind.market);
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Jester');

    for (var attempt = 0; attempt < 6; attempt++) {
      final state = _readGameState();
      final market = _marketViewFromState(state);
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
      _trace('market_decision', {
        'stage': stage,
        'lane': 'jester',
        'decision': 'consider_buy',
        'offer': _jesterOfferTrace(offer),
        'offer_score': offerScore,
        'market': _marketTrace(market),
      });
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
        _trace('market_decision', {
          'stage': stage,
          'lane': 'jester',
          'decision': 'sell_for_replacement',
          'owned': _ownedJesterTrace(weakest),
          'owned_score': weakestScore,
          'target_offer': _jesterOfferTrace(offer),
        });
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
      _traceMarketState('market_bought_jester', stage);
    }
  }

  int _jesterBotScore(
    RummiJesterCard card, {
    int stateValue = 0,
    int stage = 1,
  }) => fullRunBotJesterScore(card, stateValue: stateValue, stage: stage);

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
    _traceMarketState('market_sold_jester', stage);
    return true;
  }

  Future<void> _selectOwnedJesterForSale({String? contentId}) async {
    final ownedEntries = _marketViewFromState(_readGameState())?.ownedEntries;
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
    await _completeTutorialIfVisible(kind: _FullRunTutorialKind.market);
    final state = _readGameState();
    final tileOffers =
        _marketViewFromState(
          state,
        )?.tileOffers.where((offer) => offer.isAffordable).toList() ??
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
    _trace('market_decision', {
      'stage': stage,
      'lane': 'tile',
      'decision': 'consider_buy',
      'offer': _tileOfferTrace(bestOffer),
      'offer_score': _deckTileBotScore(bestOffer.tile),
    });
    if (!await _selectTileOfferByPrice(bestOffer.price)) return;
    if (find.text('구매').evaluate().isEmpty) return;
    await _tapText('구매');
    boughtDeckTile = true;
    _record('S$stage market: bought deck tile ${bestOffer.tile.code}');
    await _pumpFor(const Duration(seconds: 2));
    _traceMarketState('market_bought_deck_tile', stage);
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
    await _completeTutorialIfVisible(kind: _FullRunTutorialKind.market);
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Q-Slot');

    for (var attempt = 0; attempt < 10; attempt++) {
      final state = _readGameState();
      final market = _marketViewFromState(state);
      final progress = state.runProgress;
      if (market == null || progress == null) return;
      final quickSlotCapacity = progress.quickSlotCapacity(
        itemCatalog: itemCatalog,
      );
      final quickSlotCount = progress.itemInventory.quickSlotItemIds.length;
      final quickSlotOffers = market.itemOffers
          .where((offer) => offer.item.placement == ItemPlacement.quickSlot)
          .toList(growable: false);
      _record(
        'S$stage market Q-slot attempt=$attempt gold=${market.gold} '
        'quick=$quickSlotCount/$quickSlotCapacity '
        'itemOffers=${market.itemOffers.length} '
        'quickOffers=${quickSlotOffers.length} '
        'affordableQuick=${quickSlotOffers.where((offer) => offer.isAffordable).length}',
      );
      if (quickSlotCount >= quickSlotCapacity) {
        _record('S$stage market Q-slot skipped: slots full');
        return;
      }
      final affordableOffers = market.itemOffers
          .where(
            (offer) =>
                offer.item.placement == ItemPlacement.quickSlot &&
                offer.isAffordable,
          )
          .toList();
      if (affordableOffers.isEmpty) {
        if (!await _rerollItemOffersForPlacementIfPossible(
          ItemPlacement.quickSlot,
          market,
        )) {
          _record('S$stage market Q-slot skipped: no affordable offer/reroll');
          return;
        }
        continue;
      }
      affordableOffers.sort(
        (a, b) => fullRunBotItemScore(
          b.item,
          stage: stage,
        ).compareTo(fullRunBotItemScore(a.item, stage: stage)),
      );
      final bestOffer = affordableOffers.first;
      final offerScore = fullRunBotItemScore(bestOffer.item, stage: stage);
      _trace('market_decision', {
        'stage': stage,
        'lane': bestOffer.item.placement.name,
        'decision': 'consider_buy',
        'offer': _itemOfferTrace(bestOffer),
        'offer_score': offerScore,
        'market': _marketTrace(market),
      });
      if (quickSlotCount >= quickSlotCapacity) {
        final weakest = _weakestOwnedQuickSlotItem(market, stage: stage);
        if (weakest == null) return;
        final weakestScore = fullRunBotItemScore(weakest.item!, stage: stage);
        final canBuyAfterSelling =
            market.gold + weakest.item!.sellPrice >= bestOffer.price;
        if (!canBuyAfterSelling || offerScore <= weakestScore + 25) return;
        if (!await _sellMarketItemSlotIfVisible(stage, weakest)) return;
      }

      if (!await _selectVisibleItemOfferForPlacement(
        bestOffer.item.placement,
      )) {
        _record(
          'S$stage market Q-slot skipped: visible offer tap failed '
          'item=${bestOffer.item.id} price=${bestOffer.price}',
        );
        return;
      }
      if (find.text('구매').evaluate().isEmpty) {
        _record(
          'S$stage market Q-slot skipped: purchase button missing '
          'item=${bestOffer.item.id} price=${bestOffer.price}',
        );
        return;
      }
      await _tapText('구매');
      boughtItem = true;
      _record('S$stage market: bought Q-Slot Item');
      await _pumpFor(const Duration(seconds: 2));
      _traceMarketState('market_bought_item', stage);
    }
  }

  Future<bool> _rerollItemOffersForPlacementIfPossible(
    ItemPlacement placement,
    RummiMarketRuntimeFacade market,
  ) async {
    final rerollCost = market.itemRerollCostFor(placement);
    if (rerollCost <= 0 || market.gold < rerollCost) return false;
    await _selectItemOfferLaneForPlacement(placement);
    final rerollFinder = find.text('리롤 $rerollCost');
    if (rerollFinder.evaluate().isEmpty) return false;
    await _tapText('리롤 $rerollCost');
    await _pumpUntilVisible(find.text('리롤 확인'));
    await _tapText('리롤');
    await _pumpFor(const Duration(seconds: 1));
    _record('market: rerolled ${placement.name} Item offers');
    _trace('market_decision', {
      'lane': placement.name,
      'decision': 'reroll_item_offers',
      'cost': rerollCost,
    });
    return true;
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

  Future<bool> _selectVisibleItemOfferForPlacement(
    ItemPlacement placement,
  ) async {
    await _selectItemOfferLaneForPlacement(placement);
    final offerFinder = find.byWidgetPredicate((widget) {
      if (widget.runtimeType.toString() != '_MarketItemOfferCard') {
        return false;
      }
      return true;
    }).hitTestable();
    if (offerFinder.evaluate().isEmpty) return false;
    await tester.tap(offerFinder.first, warnIfMissed: false);
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
      (a, b) => fullRunBotItemScore(
        a.item!,
        stage: stage,
      ).compareTo(fullRunBotItemScore(b.item!, stage: stage)),
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
    _traceMarketState('market_sold_item', stage);
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
    await _completeTutorialIfVisible(kind: _FullRunTutorialKind.market);
    if (usedItem || find.text('사용').evaluate().isEmpty) return;
    await _tapText('사용');
    usedItem = true;
    _record('S$stage market: used Item');
    await _pumpFor(const Duration(seconds: 2));
    _traceMarketState('market_used_item', stage);
  }

  Future<bool> _tryUseBattleItem({
    required FullRunBattleAction plannedAction,
  }) async {
    if (!config.needsItemUse && !config.isFullRun) return false;
    await _completeTutorialIfVisible(kind: _FullRunTutorialKind.battle);
    if (usedItem && !config.isFullRun) return false;
    final state = _tryReadGameState();
    if (state == null) return false;
    final inventory = state.runProgress!.itemInventory;
    if (inventory.quickSlotItemIds.isEmpty) return false;
    final choice = _chooseBattleItemToUse(state, plannedAction: plannedAction);
    if (choice == null) return false;
    await _tapTextIfVisible('Slots');
    if (!await _selectBattleQuickSlot(choice)) return false;
    await _pumpFor(const Duration(milliseconds: 500));
    if (!_selectedBattleItemOverlayMatches(choice)) return false;
    if (find.text('사용').evaluate().isEmpty) return false;
    final beforeItemCount = _ownedItemCount(state.runProgress!, choice.item.id);
    final beforeQuickSlotIds = List<String>.of(inventory.quickSlotItemIds);
    _trace('battle_item_use_start', {
      'stage': state.runProgress!.stageIndex,
      'tier': BlindTier
          .values[state.runProgress!.currentStationBlindTierIndex]
          .name,
      'planned_action': _battleActionTrace(plannedAction, state.session!),
      'slot_index': choice.slotIndex,
      'item': _itemTrace(choice.item),
      'before': _battleSnapshotTrace(state),
    });
    await _tapText('사용');
    if (choice.item.effect.op == 'peek_deck_discard_one') {
      await _resolveDeckNeedleDialog(choice, state.session!);
    }
    if (!await _waitForBattleItemUseApplied(
      choice,
      beforeItemCount: beforeItemCount,
      beforeQuickSlotIds: beforeQuickSlotIds,
    )) {
      return false;
    }
    usedItem = true;
    _record(
      'S${state.runProgress!.stageIndex} '
      '${BlindTier.values[state.runProgress!.currentStationBlindTierIndex].name}: '
      'used battle Item ${choice.item.id} op=${choice.item.effect.op}',
    );
    final afterState = _tryReadGameState();
    _trace('battle_item_use_applied', {
      'stage': state.runProgress!.stageIndex,
      'tier': BlindTier
          .values[state.runProgress!.currentStationBlindTierIndex]
          .name,
      'slot_index': choice.slotIndex,
      'item': _itemTrace(choice.item),
      if (afterState != null) 'after': _battleSnapshotTrace(afterState),
    });
    await _pumpFor(const Duration(seconds: 1));
    return true;
  }

  Future<bool> _selectBattleQuickSlot(_BattleItemChoice choice) async {
    final slotFinder = find.byWidgetPredicate((widget) {
      if (widget.runtimeType.toString() != '_GameItemPocketChip') {
        return false;
      }
      try {
        final dynamic dynamicWidget = widget;
        final dynamic itemSlot = dynamicWidget.itemSlot;
        return dynamicWidget.label == 'Q${choice.slotIndex + 1}' &&
            itemSlot != null &&
            itemSlot.slotIndex == choice.slotIndex &&
            itemSlot.contentId == choice.item.id;
      } catch (_) {
        return false;
      }
    });
    if (slotFinder.evaluate().isEmpty) return false;
    await tester.tap(slotFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 500));
    return true;
  }

  bool _selectedBattleItemOverlayMatches(_BattleItemChoice choice) {
    final overlayFinder = find.byWidgetPredicate((widget) {
      if (widget is! GameBattleItemInfoOverlay) return false;
      return widget.itemSlot.slotIndex == choice.slotIndex &&
          widget.itemSlot.contentId == choice.item.id;
    });
    return overlayFinder.evaluate().isNotEmpty;
  }

  int _ownedItemCount(RummiRunProgress runProgress, String itemId) {
    return runProgress.itemInventory.ownedItems
        .where((entry) => entry.itemId == itemId)
        .fold<int>(0, (sum, entry) => sum + entry.count);
  }

  Future<bool> _waitForBattleItemUseApplied(
    _BattleItemChoice choice, {
    required int beforeItemCount,
    required List<String> beforeQuickSlotIds,
  }) async {
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      final next = _tryReadGameState();
      final progress = next?.runProgress;
      if (progress == null) continue;
      final nextItemCount = _ownedItemCount(progress, choice.item.id);
      final nextQuickSlotIds = progress.itemInventory.quickSlotItemIds;
      if (nextItemCount < beforeItemCount ||
          !_sameStringList(nextQuickSlotIds, beforeQuickSlotIds)) {
        return true;
      }
    }
    _record(
      'battle Item ${choice.item.id} use skipped: no inventory state change',
    );
    return false;
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
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
    _trace('battle_item_dialog_choice', {
      'item_id': choice.item.id,
      'dialog': 'deck_needle',
      'discard_index': discardIndex,
      'candidates': session
          .peekDeckTop(
            (choice.item.effect.value('lookAt') as num?)?.toInt() ??
                (choice.item.effect.value('peek') as num?)?.toInt() ??
                3,
          )
          .map(_tileTrace)
          .toList(),
    });
    await _pumpFor(const Duration(milliseconds: 600));
  }

  Future<bool> _completeTutorialIfVisible({
    required _FullRunTutorialKind kind,
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

  void _markTutorialCompleted(_FullRunTutorialKind kind) {
    switch (kind) {
      case _FullRunTutorialKind.battle:
        if (battleTutorialCompleted) return;
        battleTutorialCompleted = true;
        _record('battle tutorial completed');
        _trace('tutorial_completed', {'kind': 'battle'});
      case _FullRunTutorialKind.market:
        if (marketTutorialCompleted) return;
        marketTutorialCompleted = true;
        _record('market tutorial completed');
        _trace('tutorial_completed', {'kind': 'market'});
    }
  }

  _BattleItemChoice? _chooseBattleItemToUse(
    GameSessionState state, {
    required FullRunBattleAction plannedAction,
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
            pendingConfirmItemCount:
                state.battleView?.pendingConfirmItemCount ?? 0,
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
    required int pendingConfirmItemCount,
    required FullRunBattleAction plannedAction,
  }) {
    if (item.placement != ItemPlacement.quickSlot || !item.usableInBattle) {
      return false;
    }
    final hasItem = runProgress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!hasItem) return false;
    if (!fullRunBattleItemOpSupportsPlannedAction(
      item.effect.op,
      plannedAction.type,
    )) {
      return false;
    }

    return switch (item.effect.op) {
      'add_board_move' =>
        plannedAction.type == FullRunBattleActionType.moveBoard &&
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
      'add_percent_of_first_confirm_score' =>
        _hasScoringConfirmNow(session, runProgress) &&
            pendingConfirmItemCount == 0,
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
    final policy = const FullRunPlannerV2Policy();
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
    required _FullRunBotScene scene,
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
        reason: 'sub_run_bot needs purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_purchase') {
      expect(
        boughtItem,
        isTrue,
        reason: 'sub_run_bot needs item purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_use') {
      expect(usedItem, isTrue, reason: 'sub_run_bot needs item use evidence');
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
    debugPrint('FULL_RUN_BOT_CHECKPOINT_B64:$checkpointBase64');
    _record(
      'checkpoint saved scene=${scene.name} '
      'S${runProgress.stageIndex} '
      'tier=${runProgress.currentStationBlindTierIndex} '
      'gold=${runProgress.gold} '
      'jesters=${runProgress.ownedJesters.length} '
      'items=${runProgress.itemInventory.ownedItems.length} '
      'quick=${runProgress.itemInventory.quickSlotItemIds.length}',
    );
    _trace('checkpoint_saved', {
      'scene': scene.name,
      'run_progress': _runProgressTrace(runProgress),
      'session': _sessionTrace(session),
    });
  }

  bool _shouldStopAtCurrentBattle() {
    if (config.isFullRun || config.targetScene != _FullRunBotScene.battle) {
      return false;
    }
    final state = _readGameState();
    final progress = state.runProgress!;
    return config.matchesTarget(
      stage: progress.stageIndex,
      tier: BlindTier.values[progress.currentStationBlindTierIndex],
    );
  }

  Future<void> flushTrace() async {
    if (!config.traceEnabled || traceRowCount == 0) return;
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['full_run_trace_path'] = config.tracePath;
    binding.reportData!['full_run_trace_rows'] = traceRowCount;
    debugPrint(
      '${config.logPrefix}: trace_path=${config.tracePath} '
      'trace_rows=$traceRowCount',
    );
  }

  void _trace(String eventType, Map<String, Object?> payload) {
    if (!config.traceEnabled) return;
    final sequence = traceSequence++;
    final row = <String, Object?>{
      'schema_version': 1,
      'row_type': 'full_run_trace_event',
      'sequence': sequence,
      'event_type': eventType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'mode': config.mode.name,
      'seed': config.seed,
      'difficulty': config.difficulty.name,
      'locale': config.localeName,
      ...payload,
    };
    final encoded = base64Encode(utf8.encode(jsonEncode(row)));
    const chunkSize = 700;
    final chunkCount = (encoded.length / chunkSize).ceil();
    for (var index = 0; index < chunkCount; index += 1) {
      final start = index * chunkSize;
      final proposedEnd = start + chunkSize;
      final end = proposedEnd > encoded.length ? encoded.length : proposedEnd;
      debugPrint(
        'FULL_RUN_BOT_TRACE_CHUNK:$sequence:$index:$chunkCount:'
        '${encoded.substring(start, end)}',
        wrapWidth: 1024,
      );
    }
    traceRowCount += 1;
  }

  void _traceMarketState(String eventType, int stage) {
    if (!config.traceEnabled) return;
    final state = _tryReadGameState();
    final progress = state?.runProgress;
    final market = state == null ? null : _marketViewFromState(state);
    _trace(eventType, {
      'stage': stage,
      if (progress != null) 'run_progress': _runProgressTrace(progress),
      if (market != null) 'market': _marketTrace(market),
    });
  }

  Map<String, Object?> _battleSnapshotTrace(GameSessionState state) {
    final session = state.session;
    final progress = state.runProgress;
    return {
      'stage_flow_phase': state.stageFlowPhase.name,
      if (session != null) 'session': _sessionTrace(session),
      if (progress != null) 'run_progress': _runProgressTrace(progress),
      if (session != null && progress != null)
        'confirm_preview': _confirmPreviewTrace(session, progress),
    };
  }

  Map<String, Object?> _sessionTrace(RummiPokerGridSession session) {
    return {
      'score': session.blind.scoreTowardBlind,
      'target_score': session.blind.targetScore,
      'deck_remaining': session.deck.remaining,
      'max_hand_size': session.maxHandSize,
      'hand': session.hand.map(_tileTrace).toList(),
      'deck_top_5': session.peekDeckTop(5).map(_tileTrace).toList(),
      'board_occupied': RummiPokerGridSession.countTilesOnBoard(session.board),
      'board': _boardTrace(session),
      'resources': {
        'hand_discards_remaining': session.blind.handDiscardsRemaining,
        'hand_discards_max': session.blind.handDiscardsMax,
        'board_discards_remaining': session.blind.boardDiscardsRemaining,
        'board_discards_max': session.blind.boardDiscardsMax,
        'board_moves_remaining': session.blind.boardMovesRemaining,
        'board_moves_max': session.blind.boardMovesMax,
      },
    };
  }

  List<Map<String, Object?>> _boardTrace(RummiPokerGridSession session) {
    final cells = <Map<String, Object?>>[];
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        final tile = session.board.cellAt(row, col);
        if (tile == null) continue;
        cells.add({'row': row, 'col': col, 'tile': _tileTrace(tile)});
      }
    }
    return cells;
  }

  Map<String, Object?> _runProgressTrace(RummiRunProgress progress) {
    return {
      'stage': progress.stageIndex,
      'tier_index': progress.currentStationBlindTierIndex,
      'gold': progress.gold,
      'jester_slots': {
        'used': progress.ownedJesters.length,
        'capacity': progress.jesterSlotCapacity(itemCatalog: itemCatalog),
      },
      'item_slots': {
        'quick_used': progress.itemInventory.quickSlotItemIds.length,
        'quick_capacity': progress.quickSlotCapacity(itemCatalog: itemCatalog),
        'owned_count': progress.itemInventory.ownedItems.length,
      },
      'owned_jesters': progress.ownedJesters.map(_jesterCardTrace).toList(),
      'owned_items': progress.itemInventory.ownedItems
          .map((entry) => {'item_id': entry.itemId, 'count': entry.count})
          .toList(),
      'quick_slot_items': progress.itemInventory.quickSlotItemIds,
      'added_deck_tiles': progress.addedDeckTiles.map(_tileTrace).toList(),
      'played_hand_counts': progress.snapshotPlayedHandCounts().map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  Map<String, Object?>? _confirmPreviewTrace(
    RummiPokerGridSession session,
    RummiRunProgress progress,
  ) {
    if (!session.canConfirmAllFullLines) return null;
    final preview = session.copySnapshot().confirmAllFullLines(
      jesters: progress.ownedJesters,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
      applyScoreToBlind: false,
    );
    final result = preview.result;
    return {
      'ok': result.ok,
      'score_added': result.scoreAdded,
      'base_score': result.baseScore,
      'jester_bonus': result.jesterBonus,
      'line_count': result.lineBreakdowns.length,
      'lines': result.lineBreakdowns.map(_lineBreakdownTrace).toList(),
    };
  }

  Map<String, Object?> _lineBreakdownTrace(ConfirmedLineBreakdown line) {
    return {
      'line': {'kind': line.ref.kind.name, 'index': line.ref.index},
      'rank': line.rank.name,
      'base_score': line.baseScore,
      'final_score': line.finalScore,
      'jester_bonus': line.jesterBonus,
      'growth_level': line.growthLevel,
      'growth_bonus': line.growthBonus,
      'overlap_multiplier': line.overlapMultiplier,
      'overlap_bonus': line.overlapBonus,
      'tile_gold_bonus': line.tileGoldBonus,
      'bonus_rank_progress': line.bonusRankProgress,
      'destroyed_tiles': line.destroyedTiles.map(_tileTrace).toList(),
      'contributing_cells': line.contributingCells
          .map((cell) => {'row': cell.$1, 'col': cell.$2})
          .toList(),
      'constraint_penalties': line.constraintPenalties
          .map(
            (penalty) => {
              'modifier_id': penalty.modifierId,
              'title': penalty.title,
              'rule_text': penalty.ruleText,
              'marker_text': penalty.markerText,
              'score_delta': penalty.scoreDelta,
              'score_multiplier': penalty.scoreMultiplier,
              'affected_tile_colors': penalty.affectedTileColors
                  .map((color) => color.name)
                  .toList(),
              'affected_line_kinds': penalty.affectedLineKinds
                  .map((kind) => kind.name)
                  .toList(),
            },
          )
          .toList(),
    };
  }

  Map<String, Object?> _battleActionTrace(
    FullRunBattleAction action,
    RummiPokerGridSession session,
  ) {
    Tile? selectedHandTile;
    if (action.handIndex != null &&
        action.handIndex! >= 0 &&
        action.handIndex! < session.hand.length) {
      selectedHandTile = session.hand[action.handIndex!];
    }
    final selectedBoardTile = action.row == null || action.col == null
        ? null
        : session.board.cellAt(action.row!, action.col!);
    return {
      'type': action.type.name,
      if (action.handIndex != null) 'hand_index': action.handIndex,
      if (selectedHandTile != null) 'hand_tile': _tileTrace(selectedHandTile),
      if (action.row != null) 'row': action.row,
      if (action.col != null) 'col': action.col,
      if (selectedBoardTile != null)
        'board_tile': _tileTrace(selectedBoardTile),
      if (action.toRow != null) 'to_row': action.toRow,
      if (action.toCol != null) 'to_col': action.toCol,
      if (action.gain != null) 'gain': action.gain,
      if (action.reason != null) 'reason': action.reason,
    };
  }

  Map<String, Object?> _marketTrace(RummiMarketRuntimeFacade market) {
    return {
      'gold': market.gold,
      'reroll_costs': {
        'jester': market.rerollCost,
        'tile': market.tileRerollCost,
        'quick': market.quickSlotRerollCost,
        'passive': market.passiveRerollCost,
        'tool': market.toolRerollCost,
        'gear': market.gearRerollCost,
      },
      'jester_slots': {
        'used': market.ownedEntries.length,
        'capacity': market.jesterSlotCapacity,
        'max': market.maxOwnedSlots,
      },
      'quick_slot_capacity': market.quickSlotCapacity,
      'owned_jesters': market.ownedEntries.map(_ownedJesterTrace).toList(),
      'jester_offers': market.offers.map(_jesterOfferTrace).toList(),
      'item_offers': market.itemOffers.map(_itemOfferTrace).toList(),
      'tile_offers': market.tileOffers.map(_tileOfferTrace).toList(),
      'item_slots': market.itemSlots.map(_itemSlotTrace).toList(),
      'added_deck_tiles': market.addedDeckTiles.map(_tileTrace).toList(),
    };
  }

  Map<String, Object?> _ownedJesterTrace(RummiMarketOwnedEntryView entry) => {
    'slot_index': entry.slotIndex,
    'content_id': entry.contentId,
    'display_name': entry.displayName,
    'state_value': entry.stateValue,
    'sell_price': entry.sellPrice,
    'card': _jesterCardTrace(entry.card),
  };

  Map<String, Object?> _jesterOfferTrace(RummiMarketOfferView offer) => {
    'offer_id': offer.offerId,
    'slot_index': offer.slotIndex,
    'content_id': offer.contentId,
    'display_name': offer.displayName,
    'price': offer.price,
    'original_price': offer.originalPrice,
    'currency': offer.currency,
    'is_affordable': offer.isAffordable,
    'discount_source_label': offer.discountSourceLabel,
    'card': _jesterCardTrace(offer.card),
  };

  Map<String, Object?> _itemOfferTrace(RummiMarketItemOfferView offer) => {
    'offer_id': offer.offerId,
    'slot_index': offer.slotIndex,
    'content_id': offer.contentId,
    'display_name': offer.displayName,
    'display_name_key': offer.displayNameKey,
    'effect_text_key': offer.effectTextKey,
    'price': offer.price,
    'original_price': offer.originalPrice,
    'currency': offer.currency,
    'is_affordable': offer.isAffordable,
    'discount_source_label': offer.discountSourceLabel,
    'item': _itemTrace(offer.item),
  };

  Map<String, Object?> _tileOfferTrace(RummiMarketTileOfferView offer) => {
    'offer_id': offer.offerId,
    'slot_index': offer.slotIndex,
    'tile': _tileTrace(offer.tile),
    'price': offer.price,
    'currency': offer.currency,
    'is_affordable': offer.isAffordable,
    'is_free_reward': offer.isFreeReward,
  };

  Map<String, Object?> _itemSlotTrace(RummiMarketItemSlotView slot) => {
    'slot_index': slot.slotIndex,
    'slot_label': slot.slotLabel,
    'placement': slot.placement.name,
    'content_id': slot.contentId,
    'display_name': slot.displayName,
    'display_name_key': slot.displayNameKey,
    'count': slot.count,
    'locked': slot.locked,
    'recently_unlocked': slot.recentlyUnlocked,
    if (slot.item != null) 'item': _itemTrace(slot.item!),
  };

  Map<String, Object?> _jesterCardTrace(RummiJesterCard card) => {
    'id': card.id,
    'name': card.displayName,
    'rarity': card.rarity.name,
    'effect_type': card.effectType,
    'trigger': card.trigger,
    'condition_type': card.conditionType,
    'condition_value': card.conditionValue?.toString(),
    'value': card.value,
    'x_value': card.xValue,
  };

  Map<String, Object?> _itemTrace(ItemDefinition item) => {
    'id': item.id,
    'display_name': item.displayName,
    'display_name_key': item.displayNameKey,
    'placement': item.placement.name,
    'rarity': item.rarity.name,
    'base_price': item.basePrice,
    'sell_price': item.sellPrice,
    'usable_in_battle': item.usableInBattle,
    'effect': item.effect.raw,
  };

  Map<String, Object?> _tileTrace(Tile tile) => {
    'code': tile.code,
    'color': tile.color.name,
    'number': tile.number,
    'id': tile.id,
    'base_chip_value': tile.baseChipValue,
    'enhancement': tile.enhancement?.persistenceValue,
    'seal': tile.seal?.persistenceValue,
    'edition': tile.edition?.persistenceValue,
  };

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

  RummiMarketRuntimeFacade? _marketViewFromState(GameSessionState state) {
    final progress = state.runProgress;
    if (progress == null) return state.marketView;
    return RummiMarketRuntimeFacade.fromRunProgress(
      progress,
      itemCatalog: itemCatalog,
      pressureProfile: state.runModifier == NewRunModifier.highStakes
          ? RummiMarketPressureProfile.highStakes
          : RummiMarketPressureProfile.standard,
    );
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
      challengeCarryover: gameView.challengeCarryover,
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
    await tester.tap(finder.last);
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
        await tester.tap(actionFinder.last);
        await _pumpFor(const Duration(milliseconds: 800));
      }
    }
    fail('Timed out waiting for $resultFinders after tapping "$actionText"');
  }

  Future<void> _tapTextIfVisible(String text) async {
    final finder = _visibleButtonOrTextFinder(text);
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.last);
    await _pumpFor(const Duration(milliseconds: 500));
  }

  Future<bool> _dismissBlockingDialogsIfVisible() async {
    if (find.byType(Dialog).evaluate().isEmpty &&
        find.byType(GameModalCard).evaluate().isEmpty) {
      return false;
    }
    for (final label in const ['전투 시작', '확인', '닫기']) {
      final buttonFinder = find
          .widgetWithText(GameChromeButton, label)
          .hitTestable();
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder.last);
        await _pumpFor(const Duration(seconds: 1));
        return true;
      }
      final textFinder = find.text(label).hitTestable();
      if (textFinder.evaluate().isNotEmpty) {
        await tester.tap(textFinder.last);
        await _pumpFor(const Duration(seconds: 1));
        return true;
      }
    }
    return false;
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
      await _dismissBlockingDialogsIfVisible();

      final actionFinder = _buttonOrTextFinder(actionText);
      if (actionFinder.evaluate().isNotEmpty) {
        await tester.tap(actionFinder.last);
        await _pumpFor(const Duration(milliseconds: 700));
      }
    }
    fail('Timed out waiting for game state update after tapping "$actionText"');
  }

  Future<void> _pumpUntilConfirmSettlementComplete({
    required int previousScore,
    required int targetScore,
  }) async {
    var sawSettlementPhase = false;
    final end = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (await _retryGameOverIfVisible()) return;
      if (_isCashOutReady()) {
        await _pumpUntilCashOutReady();
        return;
      }
      final state = _readGameState();
      final currentScore = state.session!.blind.scoreTowardBlind;
      if (state.stageFlowPhase != GameStageFlowPhase.none) {
        sawSettlementPhase = true;
      }
      if (currentScore >= targetScore) {
        await _pumpUntilCashOutReady();
        return;
      }
      if (currentScore > previousScore &&
          sawSettlementPhase &&
          state.stageFlowPhase == GameStageFlowPhase.none) {
        return;
      }
    }
    fail('Timed out waiting for confirm settlement presentation to complete');
  }

  Finder _buttonOrTextFinder(String text) {
    final finder = _visibleButtonOrTextFinder(text).hitTestable();
    if (finder.evaluate().isNotEmpty) return finder;
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
      final tappable = finder.hitTestable();
      if (tappable.evaluate().isNotEmpty) return tappable;
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
