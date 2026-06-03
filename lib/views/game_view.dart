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
import '../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/line_ref.dart';
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
import 'game/widgets/game_market_feedback_widgets.dart';
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
part 'game/game_view_run_end_flow.dart';
part 'game/game_view_fate_selection_widgets.dart';
part 'game/game_view_fate_selection_preview.dart';
part 'game/game_view_battle_actions.dart';
part 'game/game_view_battle_item_slots.dart';
part 'game/game_view_stage_flow.dart';
part 'game/game_view_dialog_routes.dart';

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
    this.debugItemCatalogOverride,
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
  final ItemCatalog? debugItemCatalogOverride;
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
  static const Duration _inactiveLifecycleDebounce =
      GamePresentationTimings.inactiveLifecycleDebounce;
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
  _RitualEffectFlight? _ritualEffectFlight;
  int _ritualEffectFlightTick = 0;
  bool _boardMoveMode = false;
  bool _nextStationTransitionVisible = false;
  RummiCashOutBreakdown? _settlementToMarketTransition;
  int? _pendingBoardMoveSourceRow;
  int? _pendingBoardMoveSourceCol;
  String? _boardMoveBonusTargetCellKey;
  int _boardMoveBonusFlashTick = 0;
  _FateLineSelection? _fateLineSelection;
  LineRef? _fateTransformFlashLineRef;
  int _fateTransformFlashTick = 0;
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
  RummiBattleRuntimeFacade get _battleViewWithItemSlots =>
      _resolveBattleItemSlots(
        battle: _battleView,
        catalog: _itemCatalog,
        runProgress: _gameState.runProgress,
      );

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

  void _mutate(VoidCallback fn) {
    setState(fn);
  }

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
    _itemCatalog = widget.debugItemCatalogOverride;
    // BGM·카탈로그 로드를 첫 프레임 이후로 지연 — 전환 시 프레임 드롭 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundManager.playBgm(AssetPaths.bgmMain);
      _loadJesterCatalog();
      if (widget.debugItemCatalogOverride == null) {
        _loadItemCatalog();
      } else {
        _resumeRestoredMarketWhenCatalogsReady();
        _scheduleDebugAutoUseItem();
      }
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
    if (itemId == null || _debugAutoUseItemStarted) {
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
    bool fateTransform = false,
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
        fateTransform: fateTransform,
      );
    });
    unawaited(
      Future<void>.delayed(_itemEffectFeedbackDuration, () {
        if (!mounted || _itemEffectFeedbackTick != tick) return;
        setState(() => _itemEffectFeedback = null);
      }),
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
            fateLineSelection: _fateLineSelection,
            fateTransformFlashLineRef: _fateTransformFlashLineRef,
            fateTransformFlashTick: _fateTransformFlashTick,
            selectedJesterOverlayIndex: _selectedJesterOverlayIndex,
            selectedBattleItemSlot: _selectedBattleItemSlot,
            selectedHandInfoTile: _selectedHandInfoTile,
            itemEffectFeedback: _itemEffectFeedback,
            itemEffectFeedbackTick: _itemEffectFeedbackTick,
            ritualEffectFlight: _ritualEffectFlight,
            ritualEffectFlightTick: _ritualEffectFlightTick,
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
            onFateLineTap: _selectFateLine,
            onFateTileTap: _selectFateTile,
            onFateConfirm: _confirmFateLineSelection,
            onFateCancel: _cancelFateLineSelection,
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
