import '../utils/action_failure_translation.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import '../logic/rummi_poker_grid/item_presentation_event.dart';
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
import '../services/game_settings.dart';
import '../services/game_analytics_service.dart';
import '../services/in_app_review_service.dart';
import '../services/new_run_setup.dart';
import '../services/run_progression_service.dart';
import '../services/run_unlock_state_service.dart';
import '../services/tutorial_state_service.dart';
import '../utils/common_ui.dart';
import '../utils/item_presentation_translation.dart';
import '../utils/app_translation.dart';
import '../widgets/semantic_text.dart';
import 'game/game_feedback_cues.dart';
import 'game/game_presentation_timings.dart';
import 'game/game_settlement_pacing.dart';
import 'game/widgets/game_cashout_widgets.dart';
import 'game/widgets/game_hand_zone.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_market_feedback_widgets.dart';
import 'game/widgets/game_bookmark_slot_dialog.dart';
import 'game/widgets/game_boss_intro_widgets.dart';
import 'game/widgets/game_options_dialog.dart';
import 'game/widgets/game_run_info_dialog.dart';
import 'game/widgets/game_run_victory_widgets.dart';
import 'game/widgets/game_effect_overlay.dart';
import 'game/widgets/game_shop_screen.dart';
import 'game/widgets/game_shared_widgets.dart';
import 'game/widgets/game_tile_choice_dialog.dart';
import 'game/widgets/game_tutorial_overlay.dart';
import 'game/widgets/game_surface_metrics.dart';
import 'game/widgets/game_ui_palette.dart';
import '../widgets/fx/fx_ambient.dart';
import '../widgets/fx/fx_layer.dart';
import '../widgets/fx/fx_sprites.dart';
import '../widgets/fx/juice.dart';
import '../widgets/fx/motion_policy.dart';
import '../widgets/fx/presentation_clock.dart';
import '../widgets/fx/screen_shake.dart';
import '../widgets/phone_frame_scaffold.dart';
import '../utils/active_run_translation.dart';

part 'game/game_view_transition_overlays.dart';
part 'game/game_view_item_effect_widgets.dart';
part 'game/game_view_layout_widgets.dart';
part 'game/game_view_battle_widgets.dart';
part 'game/game_view_run_end_flow.dart';
part 'game/game_view_presentation_flow.dart';
part 'game/game_view_fate_selection_widgets.dart';
part 'game/game_view_fate_selection_preview.dart';
part 'game/game_view_fate_selection_layers.dart';
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
  // --- T4: Boss 인트로 배너와 제약 표시 비행 ---
  bool _bossIntroSettled = false;
  List<GameBossMarkFlight>? _bossMarkFlights;
  Timer? _bossIntroGuardTimer;
  int _bossIntroGuardRetries = 0;
  final GlobalKey _gameStackKey = GlobalKey();
  final GlobalKey _bossIntroMarksKey = GlobalKey();
  // --- T4: 런 완료 승리 장면 ---
  List<GameRunVictoryStat>? _runVictoryStats;
  Completer<void>? _runVictoryDone;
  bool _pendingLifecycleOptions = false;
  bool _pausedLifecycleDuringStageFlow = false;
  bool _optionsDialogOpen = false;
  bool _presentationPaused = false;
  bool _gameOverFadeVisible = false;
  bool _gameOverSequenceInProgress = false;
  bool _analyticsExpiredRunLogged = false;
  bool _analyticsCompletedRunLogged = false;
  Timer? _inactiveLifecycleTimer;
  bool _battleTutorialScheduled = false;
  bool _battleTutorialShouldMarkSeenOnFinish = false;
  bool _battleTutorialAlreadySeenLogged = false;
  int _battleTutorialFocusIndex = 0;
  TutorialCoachMark? _battleTutorialCoachMark;
  final GlobalKey _battleBoardTutorialKey = GlobalKey();
  final GlobalKey _battlePreviewTutorialKey = GlobalKey();
  final GlobalKey _battleActionsTutorialKey = GlobalKey();
  final GlobalKey _battleHandTutorialKey = GlobalKey();
  final GlobalKey _battleJesterZoneKey = GlobalKey();

  /// 마지막 거절 입력이 흔들 대상과 순번. 연출 전용이다.
  _BattleDenyTarget _battleDenyTarget = _BattleDenyTarget.actions;
  int _battleDenyTick = 0;

  // 한 확정의 정산 연출 전용 상태. 저장·게임 결과와 무관하다.
  bool _settlementSkipRequested = false;
  bool _settlementSlowMo = false;
  int _settlementStepCount = 0;
  int _settlementTickIndex = 0;
  int _settlementHitSerial = 0;
  int _settlementGrade = 0;

  /// 타일 tick은 매 박자 바뀌므로 화면 전체가 아니라 보드만 다시 그린다.
  final ValueNotifier<SettlementTileTicks> _settlementTicks = ValueNotifier(
    SettlementTileTicks.empty,
  );

  /// 정산·전환 연출 대기의 단일 시계. pause·정산 속도·hit-stop을 반영한다.
  late final PresentationClock _presentationClock = PresentationClock(
    tick: GamePresentationTimings.presentationPauseTick,
    speed: _presentationSpeed,
  );

  /// 설정 속도 × 자동 가속 × 피니셔 슬로모션. 탭 스킵이면 즉시.
  double _presentationSpeed() {
    if (_settlementSkipRequested) return double.infinity;
    final base = GameSettings.settlementSpeed.multiplier;
    if (base.isInfinite) return base;
    final slowMo = _settlementSlowMo
        ? GamePresentationTimings.settlementFinisherSlowMo
        : 1.0;
    return base * GameSettlementPacing.autoAccel(_settlementStepCount) * slowMo;
  }

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

  /// 자동 흐름(풀런봇·자동 cash-out 등)이나 OS 동작 줄이기에서는 흐름 연출을 건너뛴다.
  bool get _skipsFlowPresentation =>
      MotionPolicy.reduceMotion ||
      widget.autoAdvanceMarketOnLoad ||
      widget.autoEnterMarketOnCashOut ||
      widget.autoCashOutLoopOnLoad ||
      widget.debugAutoUseItemId != null;

  /// Boss 인트로 배너와 제약 표시 비행이 아직 끝나지 않았다. 자동 튜토리얼은 이 뒤에 시작한다.
  bool get _bossIntroPending =>
      !_bossIntroSettled &&
      _gameState.activeRunScene == ActiveRunScene.battle &&
      _gameState.session?.blind.bossModifier != null;

  /// 배너가 닫히고 비행이 닿기 전까지 보드·손패의 제약 표시를 숨긴다.
  bool get _bossMarksHidden => _bossIntroPending && !_skipsFlowPresentation;

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
      FxAmbient.setMood(_battleAmbientMood);
      _loadJesterCatalog();
      if (widget.debugItemCatalogOverride == null) {
        _loadItemCatalog();
      } else {
        _resumeRestoredMarketWhenCatalogsReady();
        _scheduleDebugAutoUseItem();
      }
      if (_isDebugFixtureRun && !widget.debugSuppressFixtureNotice) {
        showTopNotice(context, context.translate('battleDebugFixture'));
      }
      _showBossConstraintIntroIfNeeded();
      _showDebugGameOverOnLoadIfNeeded();
      _showDebugRunInfoOnLoadIfNeeded();
    });
  }

  @override
  void dispose() {
    _inactiveLifecycleTimer?.cancel();
    _bossIntroGuardTimer?.cancel();
    _presentationClock.dispose();
    _settlementTicks.dispose();
    SoundManager.rampGlobalPitch(1, Duration.zero);
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
          _pausedLifecycleDuringStageFlow = false;
          unawaited(_openLifecycleOptionsAfterResume());
          break;
        }
        if (_stageFlowPhase != GameStageFlowPhase.none) {
          _pausedLifecycleDuringStageFlow = false;
          _resumePresentation();
          break;
        }
        if (_pausedLifecycleDuringStageFlow || _presentationPaused) {
          _pausedLifecycleDuringStageFlow = false;
          _resumePresentation();
        }
        break;
      case AppLifecycleState.detached:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        break;
    }
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
    FxAmbient.setMood(FxAmbientMood.boss);
    Rect? marksRect;
    await _showBossConstraintInfo(
      modifier: modifier,
      buttonLabelKey: 'battleStart',
      intro: true,
      onBeforeClose: () => marksRect = _globalRectOf(_bossIntroMarksKey),
    );
    if (!mounted) return;
    await _playBossMarkFlight(marksRect);
  }

  Future<void> _openBossConstraintInfo() async {
    if (!mounted || _gameState.activeRunScene != ActiveRunScene.battle) return;
    final modifier = _gameState.session?.blind.bossModifier;
    if (modifier == null) return;
    playButtonSound();
    await _showBossConstraintInfo(
      modifier: modifier,
      buttonLabelKey: 'battleClose',
    );
  }

  Future<void> _showBossConstraintInfo({
    required RummiBossModifier modifier,
    required String buttonLabelKey,
    bool intro = false,
    VoidCallback? onBeforeClose,
  }) async {
    await showGameFramedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameBossIntroCard(
        modifier: modifier,
        buttonLabel: dialogContext.translate(buttonLabelKey),
        animate: intro && !MotionPolicy.reduceMotion,
        marksKey: intro ? _bossIntroMarksKey : null,
        maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
        onConfirm: () {
          onBeforeClose?.call();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  Rect? _globalRectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// 배너가 닫힌 뒤 제약 표시를 배너 위치에서 보드 칸으로 날려 보낸다.
  ///
  /// 상태는 바꾸지 않는다. 연출을 건너뛰는 경로에서는 곧바로 끝낸다.
  Future<void> _playBossMarkFlight(Rect? source) async {
    if (_skipsFlowPresentation || source == null) {
      _settleBossIntro();
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final stackBox = _gameStackKey.currentContext?.findRenderObject();
    final stackContext = _gameStackKey.currentContext;
    if (stackBox is! RenderBox ||
        stackContext == null ||
        !stackContext.mounted) {
      _settleBossIntro();
      return;
    }
    final targets = collectBossMarkTargets(
      stackContext,
      fallbackKey: const ValueKey('battle-blind-info-chip'),
    );
    if (targets.isEmpty) {
      _settleBossIntro();
      return;
    }
    final from = stackBox.globalToLocal(source.center);
    _startBossIntroGuard(targets.length);
    _mutate(() {
      _bossMarkFlights = [
        for (final rect in targets)
          GameBossMarkFlight(
            from: from,
            to: Rect.fromPoints(
              stackBox.globalToLocal(rect.topLeft),
              stackBox.globalToLocal(rect.bottomRight),
            ),
          ),
      ];
    });
  }

  /// 비행이 닿았다는 신호가 오지 않아도 상한 시간이 지나면 제약 표시를 드러낸다.
  ///
  /// 일시정지 중이면 몇 번 더 기다리되, 영원히 미루지는 않는다.
  void _startBossIntroGuard(int count) {
    final bound =
        GameBossMarkFlightLayer.totalDuration(count) +
        GamePresentationTimings.bossMarkFlightGuard;
    _bossIntroGuardRetries = 0;
    _scheduleBossIntroGuard(bound);
  }

  void _scheduleBossIntroGuard(Duration bound) {
    _bossIntroGuardTimer?.cancel();
    _bossIntroGuardTimer = Timer(bound, () {
      if (_bossIntroSettled || !mounted) return;
      if (_presentationPaused && _bossIntroGuardRetries < 3) {
        _bossIntroGuardRetries++;
        _scheduleBossIntroGuard(bound);
        return;
      }
      _settleBossIntro();
    });
  }

  void _onBossMarksLanded() {
    if (_bossIntroSettled) return;
    final flights = _bossMarkFlights;
    _settleBossIntro();
    final stackContext = _gameStackKey.currentContext;
    if (flights == null || stackContext == null) return;
    GameFeedback.play(GameCue.penalty);
    ScreenShake.instance.add(0.2);
    Fx.emit(stackContext, FxPresets.constraintImpact, [
      for (final flight in flights) flight.to.center,
    ]);
  }

  /// 여러 번 불려도 한 번만 동작한다. 화면이 사라진 뒤에도 잠금은 남긴다.
  void _settleBossIntro() {
    _bossIntroGuardTimer?.cancel();
    _bossIntroGuardTimer = null;
    if (_bossIntroSettled) return;
    _bossIntroSettled = true;
    if (!mounted) return;
    _mutate(() => _bossMarkFlights = null);
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
        _showSnack(
          context.translate(
            'battleDebugItemMissing',
            namedArgs: {'id': itemId},
          ),
        );
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

  void _adjustDebugGold(int delta) {
    _gameNotifier.adjustDebugGold(delta);
    _saveActiveRun();
  }

  FxAmbientMood get _battleAmbientMood {
    final tierIndex =
        _gameState.battleView?.currentBlindTierIndex ?? widget.blindTier.index;
    return tierIndex >= BlindTier.boss.index
        ? FxAmbientMood.boss
        : FxAmbientMood.battle;
  }

  /// [silent]는 호출부가 이미 자체 cue를 냈을 때 알림 등급 소리만 끈다.
  void _showSnack(
    String message, {
    bool silent = false,
    String Function(BuildContext)? messageBuilder,
  }) {
    if (!mounted) return;
    showTopNotice(
      context,
      message,
      cue: silent ? null : GameCue.noticeTop,
      messageBuilder: messageBuilder,
    );
  }

  void _schedulePendingItemPresentationFeedback(GameSessionState gameState) {
    if (gameState.activeRunScene != ActiveRunScene.battle) return;
    final events = gameState.pendingItemPresentationEvents;
    if (events.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pendingEvents = _gameState.pendingItemPresentationEvents;
      if (pendingEvents.isEmpty) return;
      _gameNotifier.clearPendingItemPresentationEvents();
      unawaited(_showPendingItemPresentationFeedback(pendingEvents));
    });
  }

  Future<void> _showPendingItemPresentationFeedback(
    List<ItemPresentationEvent> events,
  ) async {
    for (final event in events) {
      if (!mounted) return;
      _showItemEffectFeedback(
        title: event.sourceLabel,
        detail: event.resultLabel,
        titleBuilder: (context) =>
            localizedItemPresentationSource(context, event),
        detailBuilder: (context) =>
            localizedItemPresentationResult(context, event),
        sourceLabel: _itemPresentationSourceLabel(event.sourceKind),
        passive: event.sourceKind == ItemPresentationSourceKind.passive,
      );
      await Future<void>.delayed(GamePresentationTimings.itemEffectFeedback);
    }
  }

  String _itemPresentationSourceLabel(ItemPresentationSourceKind kind) {
    return switch (kind) {
      ItemPresentationSourceKind.quickSlot => 'Q-Slot',
      ItemPresentationSourceKind.passive => 'Passive',
      ItemPresentationSourceKind.tool => 'Tool',
      ItemPresentationSourceKind.gear => 'Gear',
      ItemPresentationSourceKind.jester => 'Jester',
    };
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionNotifierProvider(_gameArgs));
    if (!gameState.isReady) {
      return const PhoneFrameScaffold(
        child: Stack(
          children: [
            Positioned.fill(child: GameTableBackdrop()),
            Center(
              child: SizedBox.square(
                key: ValueKey('game-view-loading'),
                dimension: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  color: GameUiPalette.actionGoldBright,
                  backgroundColor: GameUiPalette.surfacePanel,
                ),
              ),
            ),
          ],
        ),
      );
    }
    _scheduleBattleTutorialIfNeeded();
    _schedulePendingItemPresentationFeedback(gameState);
    return PhoneFrameScaffold(
      child: Stack(
        key: _gameStackKey,
        children: [
          _GameOverSlump(
            active: _gameOverFadeVisible,
            child: GameBossMarkVeil(
              hidden: _bossMarksHidden,
              child: _GameSurface(
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
                settlementTicks: _settlementTicks,
                settlementGrade: _settlementGrade,
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
                difficulty: widget.difficulty,
                runModifier: gameState.runModifier,
                battleBoardTutorialKey: _battleBoardTutorialKey,
                battlePreviewTutorialKey: _battlePreviewTutorialKey,
                battleActionsTutorialKey: _battleActionsTutorialKey,
                battleHandTutorialKey: _battleHandTutorialKey,
                battleJesterZoneKey: _battleJesterZoneKey,
                denyTarget: _battleDenyTarget,
                denyTick: _battleDenyTick,
                onLockedSlotTap: () => _denyBattleAction(
                  context.translate('t3MarketLockedSlot'),
                  target: _BattleDenyTarget.slots,
                ),
                onOptionsTap: _openGameOptions,
                onTutorialTap: () => _startBattleTutorial(markSeen: false),
                onRunInfoTap: _openRunInfo,
                onBlindInfoTap: _battleView.bossModifier == null
                    ? null
                    : _openBossConstraintInfo,
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
                onSettlementSkip: _skipSettlementPresentation,
              ),
            ),
          ),
          if (_bossMarkFlights != null)
            Positioned.fill(
              child: GameBossMarkFlightLayer(
                flights: _bossMarkFlights!,
                onLanded: _onBossMarksLanded,
              ),
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
          if (_gameOverFadeVisible)
            const Positioned.fill(child: _GameOverFadeVeil()),
          if (_runVictoryStats != null)
            Positioned.fill(
              child: GameRunVictoryOverlay(
                stats: _runVictoryStats!,
                onDone: _onRunVictoryDone,
              ),
            ),
        ],
      ),
    );
  }
}

/// 거절 입력에서 흔들리는 영역.
enum _BattleDenyTarget { board, actions, hand, slots }

class _GameOverFadeVeil extends StatelessWidget {
  const _GameOverFadeVeil();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      key: const ValueKey('game-over-fade-veil'),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: GamePresentationTimings.gameOverFade,
        curve: Curves.easeInCubic,
        builder: (context, value, child) {
          // 채도를 빼는 ColorFiltered 대신 붉은 막 위에 어두운 막을 색 알파로 겹친다.
          return DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.specialDangerHard.withValues(
                alpha: 0.18 + (value * 0.58),
              ),
            ),
            child: ColoredBox(
              color: GameUiPalette.ink.withValues(alpha: 0.32 * value),
            ),
          );
        },
      ),
    );
  }
}

/// 게임오버 위험 fade 동안 보드가 조금씩 가라앉고 기우는 느낌을 Transform만으로 만든다.
///
/// 트리 구조는 항상 같아서 켜고 꺼도 아래 상태가 다시 만들어지지 않는다.
/// 동작 줄이기와 연출 강도 끔에서는 움직이지 않는다.
class _GameOverSlump extends StatelessWidget {
  const _GameOverSlump({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final on = active && MotionPolicy.juiceScale > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: on ? 1 : 0),
      duration: on ? GamePresentationTimings.gameOverFade : Duration.zero,
      curve: Curves.easeInCubic,
      child: child,
      builder: (context, t, child) {
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(0, 18 * t, 0, 1)
            ..rotateZ(0.02 * t)
            ..scaleByDouble(1 - 0.04 * t, 1 - 0.06 * t, 1, 1),
          child: child,
        );
      },
    );
  }
}
