import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../logic/rummi_poker_grid/rummi_settlement_facade.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../providers/features/rummi_poker_grid/game_session_state.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/blind_selection_setup.dart';
import '../services/new_run_setup.dart';
import '../services/run_progression_service.dart';
import '../utils/common_ui.dart';
import 'game/widgets/game_cashout_widgets.dart';
import 'game/widgets/game_hand_zone.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_options_dialog.dart';
import 'game/widgets/game_shop_screen.dart';
import 'game/widgets/game_shared_widgets.dart';
import '../widgets/phone_frame_scaffold.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.runSeed,
    this.restoredRun,
    this.debugFixtureId,
    this.difficulty = NewRunDifficulty.standard,
    this.blindTier = BlindTier.small,
    this.autoAdvanceMarketOnLoad = false,
    this.autoEnterMarketOnCashOut = false,
    this.autoCashOutLoopOnLoad = false,
    this.debugCompleteRunOnClear = false,
    this.debugCompleteRunOnLoad = false,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final NewRunDifficulty difficulty;
  final BlindTier blindTier;
  final bool autoAdvanceMarketOnLoad;
  final bool autoEnterMarketOnCashOut;
  final bool autoCashOutLoopOnLoad;
  final bool debugCompleteRunOnClear;
  final bool debugCompleteRunOnLoad;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with WidgetsBindingObserver {
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
  late bool _shouldResumeMarketOnCatalogLoad;

  GameSessionNotifier get _gameNotifier =>
      ref.read(gameSessionNotifierProvider(_gameArgs).notifier);
  GameSessionState get _gameState =>
      ref.read(gameSessionNotifierProvider(_gameArgs));
  RummiBattleRuntimeFacade get _battleView => _gameState.battleView!;
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
  Map<String, Tile> get _settlementBoardSnapshot =>
      _gameState.settlementBoardSnapshot;
  int get _settlementSequenceTick => _gameState.settlementSequenceTick;
  bool get _isUiLocked => _gameState.isUiLocked;
  bool get _isDebugFixtureRun => _gameState.debugFixtureId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameArgs = GameSessionArgs(
      runSeed: widget.runSeed,
      restoredRun: widget.restoredRun,
      debugFixtureId: widget.debugFixtureId,
      difficulty: widget.difficulty,
      blindTier: widget.blindTier,
    );
    _shouldResumeMarketOnCatalogLoad =
        widget.restoredRun?.activeScene == ActiveRunScene.shop;
    // BGM·카탈로그 로드를 첫 프레임 이후로 지연 — 전환 시 프레임 드롭 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundManager.playBgm(AssetPaths.bgmMain);
      _loadJesterCatalog();
      if (_isDebugFixtureRun) {
        showTopNotice(context, '디버그 픽스처 모드: 이어하기 저장은 남기지 않습니다.');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _saveActiveRun();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.resumed:
        break;
    }
  }

  Future<void> _loadJesterCatalog() async {
    try {
      final catalog = await RummiJesterCatalog.loadFromAsset(
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
        _autoCashOutLoopStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _runAutoCashOutLoopOnLoad();
        });
      }
      if (_shouldResumeMarketOnCatalogLoad) {
        _shouldResumeMarketOnCatalogLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final nextStage = await _showShopScreen();
          if (!mounted) return;
          if (nextStage == true) {
            _gameNotifier.advanceToNextStation(widget.runSeed);
            _showSnack('Station ${_battleView.stageIndex} 시작');
          }
          await _saveActiveRun();
          _gameNotifier.markDirty();
        });
      }
    } catch (_) {
      if (!mounted) return;
      _gameNotifier.setJesterCatalog(null);
    }
  }

  Future<void> _saveActiveRun({ActiveRunScene? scene}) async {
    if (_isDebugFixtureRun) {
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

  Future<void> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '현재 Station 재시작',
      message:
          '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _restartFromStageSnapshot();
  }

  Future<void> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _restartFromStageSnapshot() async {
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _exitAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await RunProgressionService.handleRunEnded(
      RunEndSummary(
        result: RunEndResult.expired,
        difficulty: widget.difficulty,
        reachedStageIndex: _battleView.stageIndex,
      ),
    );
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _completeRunAndReturnToTitle() async {
    _persistRetrySnapshotOnSave = false;
    await RunProgressionService.handleRunEnded(
      RunEndSummary(
        result: RunEndResult.completed,
        difficulty: widget.difficulty,
        reachedStageIndex: _battleView.stageIndex,
      ),
    );
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  void _showGameOver(List<RummiExpirySignal> signals) {
    if (!mounted) return;
    showGameOverDialog(
      context: context,
      signals: signals,
      onRetry: _restartFromStageSnapshot,
      onExit: _exitAfterGameOver,
    );
  }

  Future<bool> _afterAction() async {
    if (_stageFlowPhase != GameStageFlowPhase.none ||
        _stationView.objective.isMet) {
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

  void _clearSelections() {
    _gameNotifier.clearSelections();
  }

  void _openJesterOverlay(int index) {
    if (_isUiLocked) return;
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

  void _toggleHandTile(Tile tile) {
    if (_isUiLocked) return;
    _gameNotifier.toggleSelectedHandTile(tile);
  }

  Future<void> _goToTitleAfterStoppingBgm() async {
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  void _onBoardCellTap(int row, int col) async {
    if (_isUiLocked) return;
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
    if (_isUiLocked) return;
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
    if (_isUiLocked) return;
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
    if (_isUiLocked) return;
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

  void _confirmLines() async {
    if (_isUiLocked) return;
    final result = _gameNotifier.confirmLines();
    if (result == null) {
      _showSnack('확정할 족보 줄이 없습니다.');
      return;
    }
    _runSettlementSequence(
      lines: result.lineBreakdowns,
      totalScore: result.totalScore,
      shouldClearAfter: result.stageCleared,
    );
    if (result.stageCleared) {
      return;
    }
    await _afterAction();
  }

  Future<void> _runSettlementSequence({
    required List<ConfirmedLineBreakdown> lines,
    required int totalScore,
    required bool shouldClearAfter,
    int index = 0,
  }) async {
    if (!mounted) return;
    if (lines.isEmpty || index >= lines.length) {
      _gameNotifier.setStageFlow(
        phase: GameStageFlowPhase.none,
        activeSettlementLine: null,
        settlementBoardSnapshot: const {},
      );
      if (shouldClearAfter) {
        SoundManager.playSfx(AssetPaths.sfxClear);
        await _runStageClearFlow(totalScore);
      }
      return;
    }

    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.confirmSettlement,
      stageScoreAdded: totalScore,
      activeSettlementLine: lines[index],
      bumpSettlementSequence: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 780));
    if (!mounted) return;

    final lineScore = lines[index].finalScore;
    _gameNotifier.applyConfirmedLineScore(lineScore);
    SoundManager.playSfx(AssetPaths.sfxCollect);
    await _saveActiveRun();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _runSettlementSequence(
      lines: lines,
      totalScore: totalScore,
      shouldClearAfter: shouldClearAfter,
      index: index + 1,
    );
  }

  Future<void> _runStageClearFlow(int scoreAdded) async {
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    if (widget.debugCompleteRunOnClear) {
      await _completeRunAndReturnToTitle();
      return;
    }
    final breakdown = _gameNotifier.prepareSettlementAndCashOut();
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _debugForceBlindClear() async {
    if (!kDebugMode || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear();
    await _runStageClearFlow(scoreAdded);
  }

  Future<void> _debugForceBossClearToNextBlindSelect() async {
    if (!kDebugMode || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear(
      overrideTier: BlindTier.boss,
    );
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    final breakdown = _gameNotifier.prepareSettlementAndCashOut();
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

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return false;
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.settlement);

    await Future<void>.delayed(const Duration(milliseconds: 950));
    return mounted;
  }

  Future<bool?> _showCashOutSheet(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
  }) {
    final settlementView = RummiSettlementRuntimeFacade.fromCashOut(
      breakdown: breakdown,
      currentGold: _marketView.gold,
    );
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GameCashOutSheet(
          settlement: settlementView,
          autoEnterMarketOnLoad:
              autoEnterMarketOnLoad || widget.autoEnterMarketOnCashOut,
        );
      },
    );
  }

  Future<void> _runAutoCashOutLoopOnLoad() async {
    final breakdown = _gameNotifier.prepareSettlementAndCashOut();
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _runSettlementToNextStationLoop(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool autoAdvanceMarketOnLoad = false,
  }) async {
    await _saveActiveRun();

    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);

    final enterShop = await _showCashOutSheet(
      breakdown,
      autoEnterMarketOnLoad: autoEnterMarketOnLoad,
    );
    if (!mounted || enterShop != true) return;

    _gameNotifier.enterMarketAfterCashOut();
    await _saveActiveRun();

    final nextStage = await _showShopScreen(
      autoAdvanceOnLoad: autoAdvanceMarketOnLoad,
    );
    if (!mounted || nextStage != true) return;

    _gameNotifier.beginNextStationTransition();
    final blindSelectRuntime = BlindSelectionSetup.prepareRuntimeForBlindSelect(
      runtime: _gameNotifier.buildSaveRuntimeState(
        scene: ActiveRunScene.blindSelect,
        difficulty: widget.difficulty,
      ),
    );
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<bool?> _showShopScreen({bool autoAdvanceOnLoad = false}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runSeed: widget.runSeed,
          readMarketView: () =>
              ref.read(gameSessionNotifierProvider(_gameArgs)).marketView!,
          onReroll: _gameNotifier.rerollShopFromState,
          onBuyOffer: _gameNotifier.buyShopOffer,
          onSellOwnedJester: _gameNotifier.sellOwnedJester,
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

  Future<void> _openGameOptions(BuildContext context) async {
    if (_stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    await showGameOptionsDialog(
      context: context,
      runSeed: widget.runSeed,
      activeRunSaveView: _gameState.activeRunSaveView,
      onRestartRun: _restartCurrentRun,
      onExitToTitle: _exitToTitleWithConfirm,
      onReopenOptions: _openGameOptions,
      onDebugForceBlindClear: _debugForceBlindClear,
      onDebugForceBossClearToNextBlindSelect:
          _debugForceBossClearToNextBlindSelect,
      isDebugFixtureRun: _isDebugFixtureRun,
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
    return PhoneFrameScaffold(
      child: _GameSurface(
        battle: _battleView,
        station: _stationView,
        market: _marketView,
        stageFlowPhase: _stageFlowPhase,
        stageScoreAdded: _stageScoreAdded,
        activeSettlementLine: _activeSettlementLine,
        settlementSequenceTick: _settlementSequenceTick,
        settlementBoardSnapshot: _settlementBoardSnapshot,
        selectedHandTile: _selectedHandTile,
        selectedBoardRow: _selectedBoardRow,
        selectedBoardCol: _selectedBoardCol,
        selectedJesterOverlayIndex: _selectedJesterOverlayIndex,
        onOptionsTap: () => _openGameOptions(context),
        onShopTestTap: _openShopForTest,
        onDebugHandSizeChanged: _setDebugMaxHandSize,
        onJesterTap: _openJesterOverlay,
        onHandTileTap: _toggleHandTile,
        onBoardCellTap: _onBoardCellTap,
        onDraw: _drawTile,
        onBoardDiscard: _discardSelectedBoardTile,
        onHandDiscard: _discardSelectedHandTile,
        onConfirm: _confirmLines,
        onClearSelection: _clearSelections,
        onJesterSell: _sellOwnedJesterFromOverlay,
        onJesterOverlayClose: _closeJesterOverlay,
      ),
    );
  }
}

class _GameSurface extends StatelessWidget {
  const _GameSurface({
    required this.battle,
    required this.station,
    required this.market,
    required this.stageFlowPhase,
    required this.stageScoreAdded,
    required this.activeSettlementLine,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.selectedJesterOverlayIndex,
    required this.onOptionsTap,
    required this.onShopTestTap,
    required this.onDebugHandSizeChanged,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onConfirm,
    required this.onClearSelection,
    required this.onJesterSell,
    required this.onJesterOverlayClose,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final GameStageFlowPhase stageFlowPhase;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final int? selectedJesterOverlayIndex;
  final VoidCallback onOptionsTap;
  final VoidCallback onShopTestTap;
  final ValueChanged<int> onDebugHandSizeChanged;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;
  final VoidCallback onJesterSell;
  final VoidCallback onJesterOverlayClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4B3C), Color(0xFF12392E), Color(0xFF0B251F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF507564).withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(child: GameTableBackdrop()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: _GameLayout(
                  battle: battle,
                  station: station,
                  market: market,
                  activeSettlementEffects:
                      activeSettlementLine?.effects ?? const [],
                  activeSettlementLine: activeSettlementLine,
                  settlementSequenceTick: settlementSequenceTick,
                  settlementBoardSnapshot: settlementBoardSnapshot,
                  selectedHandTile: selectedHandTile,
                  selectedBoardRow: selectedBoardRow,
                  selectedBoardCol: selectedBoardCol,
                  onOptionsTap: onOptionsTap,
                  onShopTestTap: onShopTestTap,
                  onDebugHandSizeChanged: onDebugHandSizeChanged,
                  onJesterTap: onJesterTap,
                  onHandTileTap: onHandTileTap,
                  onBoardCellTap: onBoardCellTap,
                  onDraw: onDraw,
                  onBoardDiscard: onBoardDiscard,
                  onHandDiscard: onHandDiscard,
                  onConfirm: onConfirm,
                  onClearSelection: onClearSelection,
                ),
              ),
            ),
            if (stageFlowPhase == GameStageFlowPhase.confirmSettlement)
              Positioned.fill(
                child: GameFloatingSettlementBurst(
                  key: ValueKey('settlement-$settlementSequenceTick'),
                  line: activeSettlementLine,
                ),
              ),
            if (stageFlowPhase == GameStageFlowPhase.cleared ||
                stageFlowPhase == GameStageFlowPhase.settlement)
              Positioned.fill(
                child: GameStageClearOverlay(
                  phase: stageFlowPhase,
                  stageIndex: battle.stageIndex,
                  scoreAdded: stageScoreAdded,
                ),
              ),
            if (selectedJesterOverlayIndex != null &&
                selectedJesterOverlayIndex! < market.ownedEntries.length)
              Positioned.fill(
                child: Stack(
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Color(0x70000000),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameJesterInfoOverlay(
                        card: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .card,
                        runtimeValueText: jesterRuntimeValueText(
                          market.ownedEntries[selectedJesterOverlayIndex!].card,
                          market.runtimeSnapshot,
                          slotIndex: selectedJesterOverlayIndex!,
                        ),
                        sellGold: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .sellPrice,
                        onSell: onJesterSell,
                        onClose: onJesterOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  const _GameLayout({
    required this.battle,
    required this.station,
    required this.market,
    required this.activeSettlementEffects,
    required this.activeSettlementLine,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.onOptionsTap,
    required this.onShopTestTap,
    required this.onDebugHandSizeChanged,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onConfirm,
    required this.onClearSelection,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeSettlementEffects;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final VoidCallback onOptionsTap;
  final VoidCallback onShopTestTap;
  final ValueChanged<int> onDebugHandSizeChanged;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final scoringCells = battle.scoringCellKeys;
    final activeSettlementCells = activeSettlementLine == null
        ? <String>{}
        : {
            for (final (row, col) in activeSettlementLine!.contributingCells)
              '$row:$col',
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileWidth = boardTileVisualWidth(boardSide);

        return Column(
          children: [
            GameTopHud(
              station: station,
              battle: battle,
              onOptionsTap: onOptionsTap,
            ),
            const SizedBox(height: 8),
            GameJesterHeaderRow(
              station: station,
              market: market,
              onShopTap: onShopTestTap,
              onHandSizeChanged: onDebugHandSizeChanged,
            ),
            const SizedBox(height: 2),
            GameJesterStrip(
              market: market,
              activeEffects: activeSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              onTapCard: onJesterTap,
            ),
            const SizedBox(height: 8),
            const GameItemZoneSkeleton(),
            const SizedBox(height: 8),
            Expanded(
              child: GameBoardGrid(
                board: battle.board,
                scoringCells: scoringCells,
                activeSettlementCells: activeSettlementCells,
                settlementBoardSnapshot: settlementBoardSnapshot,
                selectedRow: selectedBoardRow,
                selectedCol: selectedBoardCol,
                onTapCell: onBoardCellTap,
              ),
            ),
            const SizedBox(height: 6),
            GameHandZone(
              battle: battle,
              station: station,
              hand: battle.hand,
              selectedHandTile: selectedHandTile,
              onHandTileTap: onHandTileTap,
              onDraw: onDraw,
              tileWidth: tileWidth,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GameActionButton(
                    label: '확정',
                    background: const Color(0xFFF4A81D),
                    foreground: Colors.black,
                    onPressed: onConfirm,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GameActionButton(
                    label: '보드 버림',
                    background: const Color(0xFF44554C),
                    onPressed: onBoardDiscard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GameActionButton(
                    label: '손패 버림',
                    background: const Color(0xFF5B4D33),
                    onPressed: onHandDiscard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GameActionButton(
                    label: '선택 해제',
                    background: const Color(0xFF4C5A55),
                    onPressed: onClearSelection,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
