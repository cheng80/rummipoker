import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/boss_modifier.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/item_catalog_loader.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/owned_content_instance.dart';
import '../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../logic/rummi_poker_grid/rummi_hand_growth.dart';
import '../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../logic/rummi_poker_grid/rummi_settlement_facade.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../providers/features/rummi_poker_grid/game_session_state.dart';
import '../resources/asset_paths.dart';
import '../resources/item_translation_scope.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/blind_selection_setup.dart';
import '../services/debug_run_fixture_service.dart';
import '../services/new_run_setup.dart';
import '../services/run_progression_service.dart';
import '../services/run_unlock_state_service.dart';
import '../services/tutorial_state_service.dart';
import '../utils/common_ui.dart';
import 'game/game_presentation_timings.dart';
import 'game/widgets/game_cashout_widgets.dart';
import 'game/widgets/game_hand_zone.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_options_dialog.dart';
import 'game/widgets/game_run_info_dialog.dart';
import 'game/widgets/game_effect_overlay.dart';
import 'game/widgets/game_shop_screen.dart';
import 'game/widgets/game_shared_widgets.dart';
import 'game/widgets/game_tile_choice_dialog.dart';
import 'game/widgets/game_tutorial_overlay.dart';
import 'game/widgets/game_surface_metrics.dart';
import 'game/widgets/game_ui_palette.dart';
import '../widgets/phone_frame_scaffold.dart';

part 'game/game_view_transition_overlays.dart';
part 'game/game_view_item_effect_widgets.dart';
part 'game/game_view_layout_widgets.dart';
part 'game/game_view_battle_widgets.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.runSeed,
    this.restoredRun,
    this.debugFixtureId,
    this.difficulty = NewRunDifficulty.standard,
    this.challengeCarryover,
    this.runModifier = NewRunModifier.basic,
    this.blindTier = BlindTier.small,
    this.autoAdvanceMarketOnLoad = false,
    this.autoEnterMarketOnCashOut = false,
    this.autoCashOutLoopOnLoad = false,
    this.debugCompleteRunOnClear = false,
    this.debugCompleteRunOnLoad = false,
    this.debugAutoUseItemId,
    this.debugStartItemShop = false,
    this.debugShowGameOverOnLoad = false,
    this.debugOpenRunInfoOnLoad = false,
    this.debugSuppressFixtureNotice = false,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final NewRunDifficulty difficulty;
  final ChallengeCarryoverSnapshot? challengeCarryover;
  final NewRunModifier runModifier;
  final BlindTier blindTier;
  final bool autoAdvanceMarketOnLoad;
  final bool autoEnterMarketOnCashOut;
  final bool autoCashOutLoopOnLoad;
  final bool debugCompleteRunOnClear;
  final bool debugCompleteRunOnLoad;
  final String? debugAutoUseItemId;
  final bool debugStartItemShop;
  final bool debugShowGameOverOnLoad;
  final bool debugOpenRunInfoOnLoad;
  final bool debugSuppressFixtureNotice;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with WidgetsBindingObserver {
  static const Duration _itemEffectFeedbackDuration =
      GamePresentationTimings.itemEffectFeedback;
  static const Duration _inactiveLifecycleDebounce = Duration(
    milliseconds: 250,
  );
  static const int _finalStationIndex = 8;

  static const List<String> _shopInspectOfferIds = [
    'green_jester',
    'popcorn',
    'ice_cream',
    'supernova',
    'ride_the_bus',
    'golden_jester',
    'egg',
    'delayed_gratification',
  ];

  late final GameSessionArgs _gameArgs;
  bool _persistRetrySnapshotOnSave = false;
  bool _autoCashOutLoopStarted = false;
  bool _debugAutoUseItemStarted = false;
  bool _debugGameOverDialogShown = false;
  late final bool _shouldAutoCashOutRestoredBattleOnLoad;
  late bool _shouldResumeMarketOnCatalogLoad;
  ItemCatalog? _itemCatalog;
  RummiBattleItemSlotView? _selectedBattleItemSlot;
  Tile? _selectedHandInfoTile;
  _ItemEffectFeedback? _itemEffectFeedback;
  int _itemEffectFeedbackTick = 0;
  bool _boardMoveMode = false;
  bool _nextStationTransitionVisible = false;
  RummiCashOutBreakdown? _settlementToMarketTransition;
  int? _pendingBoardMoveSourceRow;
  int? _pendingBoardMoveSourceCol;
  String? _boardMoveBonusTargetCellKey;
  int _boardMoveBonusFlashTick = 0;
  bool _bossConstraintIntroShown = false;
  bool _pendingLifecycleOptions = false;
  bool _pausedLifecycleDuringStageFlow = false;
  bool _optionsDialogOpen = false;
  bool _presentationPaused = false;
  Timer? _inactiveLifecycleTimer;
  bool _battleTutorialScheduled = false;
  bool _battleTutorialShouldMarkSeenOnFinish = false;
  int _battleTutorialFocusIndex = 0;
  TutorialCoachMark? _battleTutorialCoachMark;
  final GlobalKey _battleBoardTutorialKey = GlobalKey();
  final GlobalKey _battlePreviewTutorialKey = GlobalKey();
  final GlobalKey _battleActionsTutorialKey = GlobalKey();
  final GlobalKey _battleHandTutorialKey = GlobalKey();
  Completer<void>? _presentationResumeCompleter;

  GameSessionNotifier get _gameNotifier =>
      ref.read(gameSessionNotifierProvider(_gameArgs).notifier);
  GameSessionState get _gameState =>
      ref.read(gameSessionNotifierProvider(_gameArgs));
  RummiBattleRuntimeFacade get _battleView => _gameState.battleView!;
  RummiBattleRuntimeFacade get _battleViewWithItemSlots {
    final battle = _battleView;
    final catalog = _itemCatalog;
    final runProgress = _gameState.runProgress;
    final inventory = runProgress?.itemInventory;
    if (catalog == null ||
        runProgress == null ||
        inventory == null ||
        inventory.ownedItems.isEmpty) {
      return battle;
    }
    final quickSlotCapacity = runProgress.quickSlotCapacity(
      itemCatalog: catalog,
    );

    final itemInstances = OwnedContentInstances.itemInstances(
      inventory: inventory,
      catalog: catalog,
    );
    final instancesById = {
      for (final instance in itemInstances) instance.id: instance,
    };
    final itemSlots = <RummiBattleItemSlotView>[];
    var slotIndex = 0;

    for (final itemId in inventory.quickSlotItemIds.take(quickSlotCapacity)) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'Q${slotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
    }

    var passiveSlotIndex = 0;
    for (final itemId in inventory.passiveRelicIds.take(
      kBattlePassiveSlotDisplayCount,
    )) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'P${passiveSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      passiveSlotIndex += 1;
    }

    var toolSlotIndex = 0;
    for (final instance in itemInstances.where(
      (item) => item.placement == ItemPlacement.inventory,
    )) {
      if (toolSlotIndex >= kBattleToolSlotDisplayCount) break;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'T${toolSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      toolSlotIndex += 1;
    }

    var gearSlotIndex = 0;
    for (final itemId in inventory.equippedItemIds.take(
      kBattleGearSlotDisplayCount,
    )) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'G${gearSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      gearSlotIndex += 1;
    }

    return battle.withItemSlots(
      itemSlots,
      quickSlotCapacity: quickSlotCapacity,
      passiveRelicCapacity: runProgress.passiveRelicCapacity(
        itemCatalog: catalog,
      ),
    );
  }

  RummiStationRuntimeFacade get _stationView => _gameState.stationView!;
  RummiMarketRuntimeFacade get _marketView => _gameState.marketView!;
  Tile? get _selectedHandTile => _gameState.selectedHandTile;
  int? get _selectedBoardRow => _gameState.selectedBoardRow;
  int? get _selectedBoardCol => _gameState.selectedBoardCol;
  int? get _selectedJesterOverlayIndex => _gameState.selectedJesterOverlayIndex;
  GameStageFlowPhase get _stageFlowPhase => _gameState.stageFlowPhase;
  int get _stageScoreAdded => _gameState.stageScoreAdded;
  ConfirmedLineBreakdown? get _activeSettlementLine =>
      _gameState.activeSettlementLine;
  ScoringPresentationStep get _activeSettlementStep =>
      _gameState.activeSettlementStep;
  int? get _activeSettlementEffectIndex =>
      _gameState.activeSettlementEffectIndex;
  List<int> get _activeSettlementEffectIndexes =>
      _gameState.activeSettlementEffectIndexes;
  int? get _settlementGoalDisplayScore => _gameState.settlementGoalDisplayScore;
  Map<String, Tile> get _settlementBoardSnapshot =>
      _gameState.settlementBoardSnapshot;
  int get _settlementSequenceTick => _gameState.settlementSequenceTick;
  bool get _isUiLocked => _gameState.isUiLocked;
  bool get _isDebugFixtureRun => _gameState.debugFixtureId != null;
  bool get _shouldAutoStartTutorials =>
      DebugRunFixtureService.shouldAutoStartTutorials(
        _gameState.debugFixtureId,
      );
  bool get _isBattleInputLocked =>
      _isUiLocked ||
      _boardMoveMode ||
      _stageFlowPhase != GameStageFlowPhase.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameArgs = GameSessionArgs(
      runSeed: widget.runSeed,
      restoredRun: widget.restoredRun,
      debugFixtureId: widget.debugFixtureId,
      difficulty: widget.difficulty,
      challengeCarryover: widget.challengeCarryover,
      runModifier: widget.runModifier,
      blindTier: widget.blindTier,
    );
    _shouldAutoCashOutRestoredBattleOnLoad = _restoredBattleNeedsCashOut(
      widget.restoredRun,
    );
    _shouldResumeMarketOnCatalogLoad =
        widget.restoredRun?.activeScene == ActiveRunScene.shop;
    // BGM·카탈로그 로드를 첫 프레임 이후로 지연 — 전환 시 프레임 드롭 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundManager.playBgm(AssetPaths.bgmMain);
      _loadJesterCatalog();
      _loadItemCatalog();
      if (_isDebugFixtureRun && !widget.debugSuppressFixtureNotice) {
        showTopNotice(context, '디버그 픽스처 모드: 이어하기 저장은 남기지 않습니다.');
      }
      _showBossConstraintIntroIfNeeded();
      _showDebugGameOverOnLoadIfNeeded();
      _showDebugRunInfoOnLoadIfNeeded();
    });
  }

  @override
  void dispose() {
    _inactiveLifecycleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _dismissBattleTutorial();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        _handleLifecyclePause();
        break;
      case AppLifecycleState.inactive:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = Timer(_inactiveLifecycleDebounce, () {
          if (!mounted) return;
          _handleLifecyclePause();
        });
        break;
      case AppLifecycleState.resumed:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        if (_gameState.activeRunScene == ActiveRunScene.shop) {
          _pendingLifecycleOptions = false;
          _pausedLifecycleDuringStageFlow = false;
          break;
        }
        if (_pendingLifecycleOptions) {
          _pendingLifecycleOptions = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openGameOptions(allowDuringStageFlow: true);
          });
        } else if (_pausedLifecycleDuringStageFlow) {
          _pausedLifecycleDuringStageFlow = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openGameOptions(allowDuringStageFlow: true);
          });
        }
        break;
      case AppLifecycleState.detached:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        break;
    }
  }

  void _handleLifecyclePause() {
    _dismissBattleTutorial();
    final isShopScene = _gameState.activeRunScene == ActiveRunScene.shop;
    if (!isShopScene) {
      _pausePresentation();
    }
    SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
    if (!isShopScene && !_optionsDialogOpen) {
      _pendingLifecycleOptions = true;
    } else if (!isShopScene && _stageFlowPhase != GameStageFlowPhase.none) {
      _pausedLifecycleDuringStageFlow = true;
    }
    _saveActiveRun();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!(_battleTutorialCoachMark?.isShowing ?? false)) return;
    final focusIndex = _battleTutorialFocusIndex;
    _battleTutorialCoachMark?.removeOverlayEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _optionsDialogOpen) return;
      _startBattleTutorial(
        markSeen: _battleTutorialShouldMarkSeenOnFinish,
        initialFocus: focusIndex,
      );
    });
  }

  void _pausePresentation() {
    if (_presentationPaused) return;
    _removeBattleTutorialForPause();
    setState(() {
      _presentationPaused = true;
    });
    _presentationResumeCompleter ??= Completer<void>();
  }

  void _resumePresentation() {
    if (!_presentationPaused) return;
    setState(() {
      _presentationPaused = false;
    });
    final completer = _presentationResumeCompleter;
    _presentationResumeCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitWhilePresentationPaused() async {
    while (mounted && _presentationPaused) {
      final completer = _presentationResumeCompleter;
      if (completer == null) return;
      await completer.future;
    }
  }

  void _scheduleBattleTutorialIfNeeded() {
    if (_battleTutorialScheduled ||
        !_shouldAutoStartTutorials ||
        _optionsDialogOpen ||
        _presentationPaused ||
        _gameState.activeRunScene != ActiveRunScene.battle ||
        _stageFlowPhase != GameStageFlowPhase.none ||
        TutorialStateService.battleIntroSeen) {
      return;
    }
    _battleTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _waitForBattleTutorialLayout();
      if (!mounted ||
          _optionsDialogOpen ||
          !_shouldAutoStartTutorials ||
          _presentationPaused ||
          _gameState.activeRunScene != ActiveRunScene.battle ||
          _stageFlowPhase != GameStageFlowPhase.none ||
          TutorialStateService.battleIntroSeen) {
        _battleTutorialScheduled = false;
        return;
      }
      await _startBattleTutorial(markSeen: true);
    });
  }

  Future<void> _waitForBattleTutorialLayout() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(GamePresentationTimings.scoringPreviewFadeIn);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _startBattleTutorial({
    required bool markSeen,
    int initialFocus = 0,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_presentationPaused ||
        _optionsDialogOpen ||
        _gameState.activeRunScene != ActiveRunScene.battle) {
      _battleTutorialScheduled = false;
      _battleTutorialShouldMarkSeenOnFinish = false;
      _battleTutorialFocusIndex = 0;
      return;
    }
    _battleTutorialFocusIndex = initialFocus.clamp(0, 3);
    if (markSeen) {
      _battleTutorialShouldMarkSeenOnFinish = true;
    } else {
      _battleTutorialShouldMarkSeenOnFinish = false;
    }
    _battleTutorialCoachMark?.removeOverlayEntry();
    _battleTutorialCoachMark = TutorialCoachMark(
      targets: buildGameTutorialTargets(
        context: context,
        steps: [
          GameTutorialStep(
            targetKey: _battleBoardTutorialKey,
            title: context.tr('tutorialBattleBoardTitle'),
            description: context.tr('tutorialBattleBoardDesc'),
            align: ContentAlign.bottom,
          ),
          GameTutorialStep(
            targetKey: _battlePreviewTutorialKey,
            title: context.tr('tutorialBattlePreviewTitle'),
            description: context.tr('tutorialBattlePreviewDesc'),
            align: ContentAlign.top,
          ),
          GameTutorialStep(
            targetKey: _battleActionsTutorialKey,
            title: context.tr('tutorialBattleActionsTitle'),
            description: context.tr('tutorialBattleActionsDesc'),
            align: ContentAlign.top,
          ),
          GameTutorialStep(
            targetKey: _battleHandTutorialKey,
            title: context.tr('tutorialBattleHandTitle'),
            description: context.tr('tutorialBattleHandDesc'),
            align: ContentAlign.top,
          ),
        ],
        nextLabel: context.tr('tutorialNext'),
        doneLabel: context.tr('tutorialDone'),
        skipLabel: context.tr('tutorialSkip'),
        onStepAdvanced: (index) {
          _battleTutorialFocusIndex = index.clamp(0, 3);
        },
      ),
      colorShadow: GameUiPalette.tutorialShadow,
      opacityShadow: 0.62,
      pulseEnable: false,
      paddingFocus: 6,
      alignSkip: Alignment.topRight,
      skipWidget: buildGameTutorialSkipButton(context.tr('tutorialSkip')),
      initialFocus: _battleTutorialFocusIndex,
      onFinish: _markBattleTutorialSeenOnFinish,
      onSkip: () {
        TutorialStateService.markBattleIntroSeen();
        _battleTutorialShouldMarkSeenOnFinish = false;
        _battleTutorialScheduled = false;
        _battleTutorialFocusIndex = 0;
        return true;
      },
    )..show(context: context);
  }

  void _dismissBattleTutorial() {
    if (!(_battleTutorialCoachMark?.isShowing ?? false)) return;
    _battleTutorialCoachMark?.removeOverlayEntry();
    _battleTutorialScheduled = false;
    _battleTutorialShouldMarkSeenOnFinish = false;
    _battleTutorialFocusIndex = 0;
  }

  void _removeBattleTutorialForPause() {
    if (_battleTutorialCoachMark?.isShowing ?? false) {
      _battleTutorialCoachMark?.removeOverlayEntry();
    }
    _battleTutorialScheduled = false;
    _battleTutorialShouldMarkSeenOnFinish = false;
    _battleTutorialFocusIndex = 0;
  }

  void _markBattleTutorialSeenOnFinish() {
    _battleTutorialFocusIndex = 0;
    if (!_battleTutorialShouldMarkSeenOnFinish) return;
    _battleTutorialShouldMarkSeenOnFinish = false;
    TutorialStateService.markBattleIntroSeen();
  }

  Future<void> _presentationDelay(Duration duration) async {
    var remaining = duration;
    const tick = GamePresentationTimings.presentationPauseTick;
    while (mounted && remaining > Duration.zero) {
      await _waitWhilePresentationPaused();
      if (!mounted) return;
      final chunk = remaining < tick ? remaining : tick;
      await Future<void>.delayed(chunk);
      if (!_presentationPaused) {
        remaining -= chunk;
      }
    }
  }

  Future<void> _loadJesterCatalog() async {
    try {
      final catalog = await RummiJesterCatalogLoader.loadFromAsset(
        AssetPaths.jestersCommon,
      );
      if (!mounted) return;
      _gameNotifier.setJesterCatalog(catalog);
      await _saveActiveRun();
      if (widget.debugCompleteRunOnLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _completeRunAndReturnToTitle();
        });
        return;
      }
      if (widget.autoCashOutLoopOnLoad &&
          _isDebugFixtureRun &&
          !_autoCashOutLoopStarted) {
        _scheduleAutoCashOutLoopOnLoad();
      }
      _resumeRestoredMarketWhenCatalogsReady();
    } catch (_) {
      if (!mounted) return;
      _gameNotifier.setJesterCatalog(null);
    }
  }

  bool _restoredBattleNeedsCashOut(ActiveRunRuntimeState? restoredRun) {
    if (restoredRun == null ||
        restoredRun.activeScene != ActiveRunScene.battle) {
      return false;
    }
    final blind = restoredRun.session.blind;
    return blind.scoreTowardBlind >= blind.targetScore;
  }

  void _scheduleAutoCashOutLoopOnLoad() {
    if (_autoCashOutLoopStarted) return;
    _autoCashOutLoopStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _runAutoCashOutLoopOnLoad();
    });
  }

  Future<void> _loadItemCatalog() async {
    try {
      final catalog = await ItemCatalogLoader.loadFromAsset(
        AssetPaths.itemsCommon,
      );
      if (!mounted) return;
      setState(() => _itemCatalog = catalog);
      _resumeRestoredMarketWhenCatalogsReady();
      if (_shouldAutoCashOutRestoredBattleOnLoad) {
        _scheduleAutoCashOutLoopOnLoad();
      }
      _scheduleDebugAutoUseItem();
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemCatalog = null);
    }
  }

  void _resumeRestoredMarketWhenCatalogsReady() {
    if (!_shouldResumeMarketOnCatalogLoad || _itemCatalog == null) {
      return;
    }
    _shouldResumeMarketOnCatalogLoad = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nextStage = await _showShopScreen();
      if (!mounted) return;
      if (nextStage == true) {
        await _goToNextStationBlindSelect();
        return;
      }
      await _saveActiveRun();
      _gameNotifier.markDirty();
    });
  }

  Future<void> _showBossConstraintIntroIfNeeded() async {
    if (_bossConstraintIntroShown || !mounted) return;
    if (_gameState.activeRunScene != ActiveRunScene.battle) return;
    final modifier = _gameState.session?.blind.bossModifier;
    if (modifier == null) return;
    _bossConstraintIntroShown = true;
    await _showBossConstraintInfo(modifier: modifier, buttonLabel: '전투 시작');
  }

  Future<void> _openBossConstraintInfo() async {
    if (!mounted || _gameState.activeRunScene != ActiveRunScene.battle) return;
    final modifier = _gameState.session?.blind.bossModifier;
    if (modifier == null) return;
    await _showBossConstraintInfo(modifier: modifier, buttonLabel: '닫기');
  }

  Future<void> _showBossConstraintInfo({
    required RummiBossModifier modifier,
    required String buttonLabel,
  }) async {
    await showGameFramedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameModalCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: GameUiPalette.specialDangerNotice,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: GameUiPalette.specialDangerNoticeText.withValues(
                          alpha: 0.88,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: GameUiPalette.textPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      modifier.title,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.96,
                        ),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('boss-constraint-rule-scroll'),
                  child: Text(
                    modifier.ruleText,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GameChromeButton(
                label: buttonLabel,
                backgroundColor: GameUiPalette.actionGold,
                foregroundColor: GameUiPalette.surfacePanel,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleDebugAutoUseItem() {
    final itemId = widget.debugAutoUseItemId;
    if (itemId == null || !_isDebugFixtureRun || _debugAutoUseItemStarted) {
      return;
    }
    _debugAutoUseItemStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RummiBattleItemSlotView? slot;
      for (final candidate in _battleViewWithItemSlots.itemSlots) {
        if (candidate.contentId == itemId) {
          slot = candidate;
          break;
        }
      }
      if (slot == null) {
        _showSnack('디버그 아이템을 찾지 못했습니다: $itemId');
        return;
      }
      _useBattleItem(slot);
    });
  }

  RummiMarketRuntimeFacade _readMarketViewWithItemOffers() {
    final catalog = _itemCatalog;
    final state = ref.read(gameSessionNotifierProvider(_gameArgs));
    final progress = state.runProgress;
    return progress == null
        ? state.marketView!
        : RummiMarketRuntimeFacade.fromRunProgress(
            progress,
            itemCatalog: catalog,
            pressureProfile: state.runModifier == NewRunModifier.highStakes
                ? RummiMarketPressureProfile.highStakes
                : RummiMarketPressureProfile.standard,
          );
  }

  Future<void> _saveActiveRun({ActiveRunScene? scene}) async {
    if (_isDebugFixtureRun) {
      return;
    }
    if (scene == null && _stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    if (scene != null) {
      _gameNotifier.setActiveRunScene(scene);
    }
    final runtime = _gameNotifier.buildSaveRuntimeState(
      scene: scene,
      difficulty: widget.difficulty,
      useStageStartSnapshotAsCurrent: _persistRetrySnapshotOnSave,
    );
    await ActiveRunSaveService.saveRuntimeState(runtime);
  }

  void _setDebugMaxHandSize(int value) {
    _gameNotifier.setDebugMaxHandSize(value);
    _saveActiveRun();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showTopNotice(context, message);
  }

  void _showItemEffectFeedback({
    required String title,
    required String detail,
    String? sourceLabel,
    bool passive = false,
  }) {
    if (!mounted) return;
    final tick = _itemEffectFeedbackTick + 1;
    setState(() {
      _itemEffectFeedbackTick = tick;
      _itemEffectFeedback = _ItemEffectFeedback(
        title: title,
        detail: detail,
        sourceLabel: sourceLabel,
        passive: passive,
      );
    });
    unawaited(
      Future<void>.delayed(_itemEffectFeedbackDuration, () {
        if (!mounted || _itemEffectFeedbackTick != tick) return;
        setState(() => _itemEffectFeedback = null);
      }),
    );
  }

  Future<bool> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '현재 Station 재시작',
      message:
          '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _restartFromStageSnapshot();
    return true;
  }

  Future<bool> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _goToTitleAfterStoppingBgm();
    return true;
  }

  Future<void> _restartFromStageSnapshot() async {
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _exitAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_expiredRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _startNewRunAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_expiredRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.newRun);
  }

  Future<void> _completeRunAndReturnToTitle() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_completedRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _recordRunEndIfNeeded(RunEndSummary summary) async {
    // 디버그 fixture는 눈검증용이므로 보상/도감 저장 상태를 바꾸지 않는다.
    if (_isDebugFixtureRun) return;
    await RunProgressionService.handleRunEnded(summary);
  }

  RunEndSummary _expiredRunSummary() {
    return RunEndSummary(
      result: RunEndResult.expired,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: false),
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

  int _defeatedBossCountForRunEnd({required bool completed}) {
    final stageIndex = _battleView.stageIndex;
    if (stageIndex <= 0) return 0;
    return completed ? stageIndex : math.max(0, stageIndex - 1);
  }

  void _showGameOver(List<RummiExpirySignal> signals) {
    if (!mounted) return;
    final summary = RunEndSummary(
      result: RunEndResult.expired,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: false),
    );
    showGameOverDialog(
      context: context,
      signals: signals,
      insightReward: RunProgressionService.calculateInsightReward(summary),
      runSummary: _gameOverRunSummary(),
      onRetry: _restartFromStageSnapshot,
      onNewRun: _startNewRunAfterGameOver,
      onExit: _exitAfterGameOver,
    );
  }

  GameOverRunSummary _gameOverRunSummary() {
    final session = _gameState.session;
    final counts = _runProgressCollection.snapshotPlayedHandCounts();
    final growthStates = _runProgressCollection.snapshotHandGrowthStates();
    RummiHandRank? bestRank;
    var bestRankScore = 0;
    RummiHandRank? mostPlayedRank;
    var mostPlayedCount = 0;
    var playedHandTotal = 0;

    for (final entry in counts.entries) {
      final count = entry.value < 0 ? 0 : entry.value;
      playedHandTotal += count;
      if (count > mostPlayedCount) {
        mostPlayedRank = entry.key;
        mostPlayedCount = count;
      }
      final growthState =
          growthStates[entry.key] ??
          RummiHandGrowthState.fromCompletedCount(entry.key, count);
      final score = RummiHandGrowth.grownBaseScoreForState(
        rank: entry.key,
        baseScore: gddBaseScore(entry.key),
        state: growthState,
      );
      if (score > bestRankScore) {
        bestRank = entry.key;
        bestRankScore = score;
      }
    }

    return GameOverRunSummary(
      difficultyLabel: NewRunSetup(
        difficulty: widget.difficulty,
      ).difficultyLabel,
      stageIndex: _battleView.stageIndex,
      scoreTowardTarget: session?.blind.scoreTowardBlind ?? 0,
      targetScore: session?.blind.targetScore ?? 0,
      seed: session?.runSeed ?? widget.runSeed,
      bestRank: bestRank,
      bestRankScore: bestRankScore,
      mostPlayedRank: mostPlayedRank,
      mostPlayedCount: mostPlayedCount,
      playedHandTotal: playedHandTotal,
      boughtJesterCount: _runProgressCollection.boughtJesterIds.length,
      boughtItemCount: _runProgressCollection.boughtItemIds.length,
      addedDeckTileCount: _runProgressCollection.addedDeckTiles.length,
    );
  }

  void _showDebugGameOverOnLoadIfNeeded() {
    if (!AppConfig.showDebugFixtures ||
        !widget.debugShowGameOverOnLoad ||
        _debugGameOverDialogShown) {
      return;
    }
    _debugGameOverDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      final signals = _gameNotifier.evaluateExpiry();
      _showGameOver(
        signals.isEmpty
            ? const [RummiExpirySignal.boardFullAfterDcExhausted]
            : signals,
      );
    });
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
    setState(() {
      _boardMoveMode = false;
      _pendingBoardMoveSourceRow = null;
      _pendingBoardMoveSourceCol = null;
    });
    _gameNotifier.clearSelections();
  }

  void _openJesterOverlay(int index) {
    if (_isBattleInputLocked) return;
    setState(() {
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
    setState(() {
      _selectedBattleItemSlot = slot;
      _selectedHandInfoTile = null;
    });
  }

  void _closeBattleItemOverlay() {
    if (!mounted) return;
    setState(() => _selectedBattleItemSlot = null);
  }

  void _toggleHandTile(Tile tile) {
    if (_isBattleInputLocked) return;
    _gameNotifier.toggleSelectedHandTile(tile);
  }

  void _openHandTileInfoOverlay(Tile tile) {
    if (_isBattleInputLocked) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
    setState(() {
      _selectedBattleItemSlot = null;
      _selectedHandInfoTile = tile;
    });
  }

  void _closeHandTileInfoOverlay() {
    if (!mounted) return;
    setState(() => _selectedHandInfoTile = null);
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
      setState(() => _selectedBattleItemSlot = null);
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
      setState(() => _selectedBattleItemSlot = null);
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
    setState(() {
      _selectedBattleItemSlot = null;
      _boardMoveMode = true;
      _pendingBoardMoveSourceRow = row;
      _pendingBoardMoveSourceCol = col;
    });
  }

  void _cancelBoardMoveMode() {
    if (!mounted) return;
    setState(() {
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
    setState(() {
      _boardMoveBonusFlashTick = tick;
      _boardMoveBonusTargetCellKey = '$row:$col';
    });
    unawaited(
      Future<void>.delayed(GamePresentationTimings.boardMoveBonusFlash, () {
        if (!mounted || _boardMoveBonusFlashTick != tick) return;
        setState(() => _boardMoveBonusTargetCellKey = null);
      }),
    );
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
    if (lines.isEmpty || index >= lines.length) {
      await _waitWhilePresentationPaused();
      if (!mounted) return;
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
    final jesterIds = {
      for (final entry in _marketView.ownedEntries) entry.card.id,
    };
    final jesterEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (jesterIds.contains(line.effects[i].jesterId)) i,
    ];
    final itemEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (!jesterIds.contains(line.effects[i].jesterId)) i,
    ];

    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.boardLine,
      settlementGoalDisplayScore: lineGoalStartScore,
      bump: true,
      delay: GamePresentationTimings.settlementBoardLineStep,
    );
    if (!mounted) return;
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.handRank,
      settlementGoalDisplayScore: lineGoalStartScore,
      delay: GamePresentationTimings.settlementHandRankStep,
    );
    if (!mounted) return;
    if (line.overlapBonus > 0) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.overlap,
        settlementGoalDisplayScore: lineGoalStartScore,
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
        delay: GamePresentationTimings.settlementConstraintStep,
      );
      if (!mounted) return;
    }
    if (jesterEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.jester,
        effectIndexes: jesterEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
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
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.finalScore,
      settlementGoalDisplayScore: lineGoalDisplayScore,
      delay: GamePresentationTimings.settlementFinalScoreStep,
    );
    if (!mounted) return;

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

  Future<void> _showSettlementStep({
    required int totalScore,
    required ConfirmedLineBreakdown line,
    required ScoringPresentationStep step,
    required Duration delay,
    int? effectIndex,
    List<int> effectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    bool bump = false,
  }) async {
    await _waitWhilePresentationPaused();
    if (!mounted) return;
    SoundManager.playSfx(AssetPaths.sfxCollect);
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

  Future<void> _runStageClearFlow(int scoreAdded) async {
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
      transitionDuration: Duration.zero,
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

    final nextStage = await _showShopScreen(
      autoAdvanceOnLoad: autoAdvanceMarketOnLoad,
    );
    if (!mounted || nextStage != true) return;

    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  bool get _isFinalBossCleared {
    return _battleView.stageIndex == _finalStationIndex &&
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
    );
  }

  RummiRunProgress get _runProgressCollection {
    return _gameState.runProgress ?? RummiRunProgress();
  }

  Future<void> _playSettlementToMarketTransition(
    RummiCashOutBreakdown breakdown,
  ) async {
    if (!mounted) return;
    setState(() => _settlementToMarketTransition = breakdown);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    setState(() => _settlementToMarketTransition = null);
  }

  Future<void> _goToNextStationBlindSelect() async {
    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<void> _playNextStationTransition() async {
    if (!mounted) return;
    setState(() => _nextStationTransitionVisible = true);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    setState(() => _nextStationTransitionVisible = false);
  }

  Future<bool?> _showShopScreen({bool autoAdvanceOnLoad = false}) {
    _removeBattleTutorialForPause();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runSeed: widget.runSeed,
          readMarketView: _readMarketViewWithItemOffers,
          onReroll: () =>
              _gameNotifier.rerollShopFromState(itemCatalog: _itemCatalog),
          onRerollItemOffers: (placement) =>
              _gameNotifier.rerollItemOffersFromState(
                itemCatalog: _itemCatalog,
                placement: placement,
              ),
          onRerollTileOffers: () => _gameNotifier.rerollTileOffersFromState(
            itemCatalog: _itemCatalog,
          ),
          onBuyOffer: (offer) =>
              _gameNotifier.buyShopOfferView(offer, itemCatalog: _itemCatalog),
          onBuyItemOffer: (offer) =>
              _gameNotifier.buyItemOffer(offer, itemCatalog: _itemCatalog),
          onBuyTileOffer: _gameNotifier.buyTileOffer,
          onUseMarketItem: _gameNotifier.useMarketItem,
          onSellOwnedJester: (index) =>
              _gameNotifier.sellOwnedJester(index, itemCatalog: _itemCatalog),
          onSellMarketItem: _gameNotifier.sellMarketItem,
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
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onRestartRun: _restartCurrentRun,
          isDebugFixtureRun: _isDebugFixtureRun,
          initialItemShopTab: widget.debugStartItemShop,
          autoAdvanceOnLoad:
              autoAdvanceOnLoad || widget.autoAdvanceMarketOnLoad,
        ),
      ),
    );
  }

  Future<void> _openShopForTest() async {
    if (_isUiLocked) return;
    _gameNotifier.openShopForTest(preferredOfferIds: _shopInspectOfferIds);
    await _saveActiveRun(scene: ActiveRunScene.shop);
    _showSnack('검사용 Market 오퍼 ${_shopInspectOfferIds.length}장 표시');
    await _showShopScreen();
    if (!mounted) return;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _gameNotifier.markDirty();
  }

  Future<void> _openGameOptions({bool allowDuringStageFlow = false}) async {
    if ((!allowDuringStageFlow && _stageFlowPhase != GameStageFlowPhase.none) ||
        _optionsDialogOpen) {
      return;
    }
    _dismissBattleTutorial();
    while (mounted) {
      _optionsDialogOpen = true;
      SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
      if (!mounted) return;
      final action = await showGameOptionsDialog(
        context: context,
        runSeed: widget.runSeed,
        activeRunSaveView: _gameState.activeRunSaveView,
        onRestartRun: _restartCurrentRun,
        onExitToTitle: _exitToTitleWithConfirm,
        isDebugFixtureRun: _isDebugFixtureRun,
      );
      _optionsDialogOpen = false;
      if (!mounted) return;
      switch (action) {
        case GameOptionsCloseAction.resumeGame:
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case GameOptionsCloseAction.keepPaused:
          return;
        case GameOptionsCloseAction.openSettings:
          SoundManager.beginBgmAutoResumeBlock();
          try {
            SoundManager.playSfx(AssetPaths.sfxBtnSnd);
            await context.push(RoutePaths.setting);
          } finally {
            SoundManager.endBgmAutoResumeBlock();
          }
          if (!mounted ||
              (!allowDuringStageFlow &&
                  _stageFlowPhase != GameStageFlowPhase.none)) {
            return;
          }
        case GameOptionsCloseAction.openRunInfo:
          await _openRunInfo();
          if (!mounted) return;
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case GameOptionsCloseAction.openBattleTutorial:
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          await _startBattleTutorial(markSeen: false);
          return;
      }
    }
  }

  Future<void> _openRunInfo() async {
    if (_optionsDialogOpen) return;
    await showGameRunInfoDialog(
      context: context,
      playedHandCounts:
          _gameState.activeRunSaveView?.currentPlayedHandCounts ?? const {},
      handGrowthStates:
          _gameState.runProgress?.snapshotHandGrowthStates() ?? const {},
      addedDeckTiles: _gameState.runProgress?.addedDeckTiles ?? const [],
    );
  }

  void _showDebugRunInfoOnLoadIfNeeded() {
    if (!AppConfig.showDebugFixtures ||
        !widget.debugOpenRunInfoOnLoad ||
        !_isDebugFixtureRun) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openRunInfo();
    });
  }

  Future<void> _openDebugBottomSheet(BuildContext context) async {
    if (!AppConfig.showDebugFixtures ||
        _stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameUiPalette.transparent,
      isScrollControlled: true,
      barrierLabel: '디버그 설정',
      routeSettings: const RouteSettings(name: '디버그 설정'),
      builder: (sheetContext) {
        var handSize = _stationView.resources.maxHandSize;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Semantics(
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: '디버그 설정',
              child: SafeArea(
                top: false,
                child: FractionallySizedBox(
                  heightFactor: 0.72,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GameModalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'DEBUG',
                                  style: TextStyle(
                                    color: GameUiPalette.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              GameIconButtonChip(
                                tooltip: '닫기',
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: Icons.close_rounded,
                                size: 34,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 108,
                                child: GameActionButton(
                                  label: 'MARKET',
                                  background: GameUiPalette.actionGold,
                                  foreground: GameUiPalette.ink,
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();
                                    await WidgetsBinding.instance.endOfFrame;
                                    await _openShopForTest();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 228,
                                    height: 40,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GameUiPalette.textPrimary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: GameUiPalette.textPrimary
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: GameDebugHandSizeSegment(
                                        value: handSize,
                                        onChanged: (value) {
                                          setModalState(() => handSize = value);
                                          _setDebugMaxHandSize(value);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  GameMenuActionTile(
                                    title: '현재 구간 즉시 클리어',
                                    subtitle: '현재 선택된 구간을 즉시 정산 완료 상태로 넘깁니다.',
                                    icon: Icons.bug_report_rounded,
                                    accentColor:
                                        GameUiPalette.menuAccentRestart,
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await WidgetsBinding.instance.endOfFrame;
                                      await _debugForceBlindClear();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  GameMenuActionTile(
                                    title: 'Boss 클리어 후 다음 Station Select',
                                    subtitle: '다음 Station Select로 바로 이행합니다.',
                                    icon: Icons.skip_next_rounded,
                                    accentColor:
                                        GameUiPalette.menuAccentTutorial,
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await WidgetsBinding.instance.endOfFrame;
                                      await _debugForceBossClearToNextBlindSelect();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionNotifierProvider(_gameArgs));
    if (!gameState.isReady) {
      return const PhoneFrameScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    _scheduleBattleTutorialIfNeeded();
    return PhoneFrameScaffold(
      child: Stack(
        children: [
          _GameSurface(
            battle: _battleViewWithItemSlots,
            station: _stationView,
            market: _marketView,
            stageFlowPhase: _stageFlowPhase,
            presentationPaused: _presentationPaused,
            stageScoreAdded: _stageScoreAdded,
            activeSettlementLine: _activeSettlementLine,
            activeSettlementStep: _activeSettlementStep,
            activeSettlementEffectIndex: _activeSettlementEffectIndex,
            activeSettlementEffectIndexes: _activeSettlementEffectIndexes,
            settlementGoalDisplayScore: _settlementGoalDisplayScore,
            settlementSequenceTick: _settlementSequenceTick,
            settlementBoardSnapshot: _settlementBoardSnapshot,
            selectedHandTile: _selectedHandTile,
            selectedBoardRow: _selectedBoardRow,
            selectedBoardCol: _selectedBoardCol,
            boardMoveMode: _boardMoveMode,
            pendingBoardMoveSourceRow: _pendingBoardMoveSourceRow,
            pendingBoardMoveSourceCol: _pendingBoardMoveSourceCol,
            boardMoveBonusTargetCellKey: _boardMoveBonusTargetCellKey,
            boardMoveBonusFlashTick: _boardMoveBonusFlashTick,
            selectedJesterOverlayIndex: _selectedJesterOverlayIndex,
            selectedBattleItemSlot: _selectedBattleItemSlot,
            selectedHandInfoTile: _selectedHandInfoTile,
            itemEffectFeedback: _itemEffectFeedback,
            itemEffectFeedbackTick: _itemEffectFeedbackTick,
            suppressDebugChrome: widget.debugSuppressFixtureNotice,
            difficultyLabel: NewRunSetup(
              difficulty: widget.difficulty,
            ).difficultyLabel,
            battleBoardTutorialKey: _battleBoardTutorialKey,
            battlePreviewTutorialKey: _battlePreviewTutorialKey,
            battleActionsTutorialKey: _battleActionsTutorialKey,
            battleHandTutorialKey: _battleHandTutorialKey,
            onOptionsTap: _openGameOptions,
            onTutorialTap: () => _startBattleTutorial(markSeen: false),
            onRunInfoTap: _openRunInfo,
            onBlindInfoTap: _openBossConstraintInfo,
            onDebugTap: () => _openDebugBottomSheet(context),
            onJesterTap: _openJesterOverlay,
            onHandTileTap: _toggleHandTile,
            onHandTileLongPress: _openHandTileInfoOverlay,
            onBoardCellTap: _onBoardCellTap,
            onDraw: _drawTile,
            onBoardDiscard: _discardSelectedBoardTile,
            onHandDiscard: _discardSelectedHandTile,
            onStartBoardMove: _startBoardMoveMode,
            onBattleItemTap: _openBattleItemOverlay,
            onConfirm: _confirmLines,
            onClearSelection: _clearSelections,
            onJesterSell: _sellOwnedJesterFromOverlay,
            onJesterOverlayClose: _closeJesterOverlay,
            onBattleItemUse: _useBattleItem,
            onBattleItemOverlayClose: _closeBattleItemOverlay,
            onHandTileInfoOverlayClose: _closeHandTileInfoOverlay,
          ),
          if (_settlementToMarketTransition != null)
            Positioned.fill(
              child: _SettlementToMarketTransitionOverlay(
                breakdown: _settlementToMarketTransition!,
              ),
            ),
          if (_nextStationTransitionVisible)
            const Positioned.fill(child: _NextStationTransitionOverlay()),
          if (_presentationPaused)
            const Positioned.fill(child: _GamePresentationPauseVeil()),
        ],
      ),
    );
  }
}
