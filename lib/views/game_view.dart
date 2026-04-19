import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../providers/features/rummi_poker_grid/game_session_state.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
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
    this.autoAdvanceMarketOnLoad = false,
    this.autoEnterMarketOnCashOut = false,
    this.autoCashOutLoopOnLoad = false,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final bool autoAdvanceMarketOnLoad;
  final bool autoEnterMarketOnCashOut;
  final bool autoCashOutLoopOnLoad;

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

  GameSessionNotifier get _gameNotifier =>
      ref.read(gameSessionNotifierProvider(_gameArgs).notifier);
  GameSessionState get _gameState =>
      ref.read(gameSessionNotifierProvider(_gameArgs));
  RummiPokerGridSession get _session => _gameState.session!;
  RummiRunProgress get _runProgress => _gameState.runProgress!;
  ActiveRunStageSnapshot get _stageStartSnapshot =>
      _gameState.stageStartSnapshot!;
  RummiStationRuntimeFacade get _stationView => _gameState.stationView!;
  RummiMarketRuntimeFacade get _marketView => _gameState.marketView!;
  ActiveRunScene get _activeRunScene => _gameState.activeRunScene;
  bool get _pendingResumeShop => _gameState.pendingResumeShop;
  Tile? get _selectedHandTile => _gameState.selectedHandTile;
  int? get _selectedBoardRow => _gameState.selectedBoardRow;
  int? get _selectedBoardCol => _gameState.selectedBoardCol;
  RummiJesterCatalog? get _jesterCatalog => _gameState.jesterCatalog;
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
    );
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
      if (widget.autoCashOutLoopOnLoad &&
          _isDebugFixtureRun &&
          !_autoCashOutLoopStarted) {
        _autoCashOutLoopStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _runAutoCashOutLoopOnLoad();
        });
      }
      if (_pendingResumeShop) {
        _gameNotifier.setPendingResumeShop(false);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final nextStage = await _showShopScreen();
          if (!mounted) return;
          if (nextStage == true) {
            _gameNotifier.advanceToNextStage(widget.runSeed);
            _showSnack('Station ${_runProgress.stageIndex} 시작');
          }
          await _saveActiveRun(scene: ActiveRunScene.battle);
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
    if (_persistRetrySnapshotOnSave) {
      final retrySnapshot = ActiveRunStageSnapshot(
        session: _stageStartSnapshot.session.copySnapshot(),
        runProgress: _stageStartSnapshot.runProgress.copySnapshot(),
      );
      await ActiveRunSaveService.saveActiveRun(
        activeScene: ActiveRunScene.battle,
        session: retrySnapshot.session,
        runProgress: retrySnapshot.runProgress,
        stageStartSnapshot: retrySnapshot,
      );
      return;
    }
    await ActiveRunSaveService.saveActiveRun(
      activeScene: _activeRunScene,
      session: _session,
      runProgress: _runProgress,
      stageStartSnapshot: _stageStartSnapshot,
    );
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
    final index = _selectedJesterOverlayIndex;
    if (index == null) return;
    final ok = _gameNotifier.sellOwnedJester(index);
    if (!ok) return;
    _showSnack('제스터를 판매했습니다.');
  }

  void _toggleHandTile(Tile tile) {
    if (_isUiLocked) return;
    _gameNotifier.setSelectedHandTile(_selectedHandTile == tile ? null : tile);
  }

  Future<void> _goToTitleAfterStoppingBgm() async {
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  void _onBoardCellTap(int row, int col) async {
    if (_isUiLocked) return;
    final selectedHand = _selectedHandTile;
    if (selectedHand != null) {
      final placed = _gameNotifier.tryPlaceTile(selectedHand, row, col);
      if (!placed) {
        _showSnack('이 칸에 둘 수 없습니다.');
        return;
      }
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      await _saveActiveRun();
      return;
    }

    final session = _session;
    if (session.board.cellAt(row, col) == null) {
      return;
    }
    if (_selectedBoardRow == row && _selectedBoardCol == col) {
      _gameNotifier.setSelectedBoardCell(null, null);
    } else {
      _gameNotifier.setSelectedBoardCell(row, col);
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
    final row = _selectedBoardRow;
    final col = _selectedBoardCol;
    if (row == null || col == null) {
      _showSnack('보드에서 버릴 타일을 먼저 선택하세요.');
      return;
    }
    final failReason = _gameNotifier.discardBoardTile(row, col);
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
    final tile = _selectedHandTile;
    if (tile == null) {
      _showSnack('손패에서 버릴 카드를 먼저 선택하세요.');
      return;
    }
    final failReason = _gameNotifier.discardHandTile(tile);
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
    if (!mounted) return;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.cleared,
      stageScoreAdded: scoreAdded,
      activeSettlementLine: null,
    );

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.settlement);

    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    final breakdown = _gameNotifier.prepareCashOut();
    await _saveActiveRun();

    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);

    final enterShop = await _showCashOutSheet(breakdown);
    if (!mounted || enterShop != true) return;

    _gameNotifier.openShop();
    await _saveActiveRun(scene: ActiveRunScene.shop);

    final nextStage = await _showShopScreen();
    if (!mounted || nextStage != true) return;

    _gameNotifier.advanceToNextStage(widget.runSeed);
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _showSnack('Station ${_runProgress.stageIndex} 시작');
  }

  Future<bool?> _showCashOutSheet(RummiCashOutBreakdown breakdown) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GameCashOutSheet(
          breakdown: breakdown,
          currentGold: _marketView.gold,
          autoEnterMarketOnLoad: widget.autoEnterMarketOnCashOut,
        );
      },
    );
  }

  Future<void> _runAutoCashOutLoopOnLoad() async {
    final breakdown = _gameNotifier.prepareCashOut();
    await _saveActiveRun();

    final enterShop = await _showCashOutSheet(breakdown);
    if (!mounted || enterShop != true) return;

    _gameNotifier.openShop();
    await _saveActiveRun(scene: ActiveRunScene.shop);

    final nextStage = await _showShopScreen();
    if (!mounted || nextStage != true) return;

    _gameNotifier.advanceToNextStage(widget.runSeed);
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _showSnack('Station ${_runProgress.stageIndex} 시작');
  }

  Future<bool?> _showShopScreen() {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runProgress: _runProgress,
          catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
          rng: _session.runRandom,
          runSeed: widget.runSeed,
          onReroll: () => _gameNotifier.rerollShop(
            catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
            rng: _session.runRandom,
          ),
          onBuyOffer: _gameNotifier.buyShopOffer,
          onSellOwnedJester: _gameNotifier.sellOwnedJester,
          onStateChanged: _saveActiveRun,
          onOpenSettings: () async {
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onRestartRun: _restartCurrentRun,
          isDebugFixtureRun: _isDebugFixtureRun,
          autoAdvanceOnLoad: widget.autoAdvanceMarketOnLoad,
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
    await showGameOptionsDialog(
      context: context,
      runSeed: widget.runSeed,
      activeRunSaveView: _gameState.activeRunSaveView,
      onRestartRun: _restartCurrentRun,
      onExitToTitle: _exitToTitleWithConfirm,
      onReopenOptions: _openGameOptions,
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
        session: _session,
        runProgress: _runProgress,
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
    required this.session,
    required this.runProgress,
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

  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
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
                  session: session,
                  runProgress: runProgress,
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
                  stageIndex: runProgress.stageIndex,
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
    required this.session,
    required this.runProgress,
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

  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
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
    final scoringCells = scoringCellSet(session);
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
              runProgress: runProgress,
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
            Expanded(
              child: GameBoardGrid(
                board: session.board,
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
              session: session,
              station: station,
              hand: List<Tile>.from(session.hand),
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
