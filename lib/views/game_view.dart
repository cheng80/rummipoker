import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../providers/features/rummi_poker_grid/game_session_state.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../utils/common_ui.dart';
import 'game/widgets/game_cashout_widgets.dart';
import 'game/widgets/game_hand_zone.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_shop_screen.dart';
import 'game/widgets/game_shared_widgets.dart';
import '../widgets/phone_frame_scaffold.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.runSeed,
    this.restoredRun,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;

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

  GameSessionNotifier get _gameNotifier =>
      ref.read(gameSessionNotifierProvider(_gameArgs).notifier);
  GameSessionState get _gameState => ref.read(gameSessionNotifierProvider(_gameArgs));
  RummiPokerGridSession get _session => _gameState.session!;
  RummiRunProgress get _runProgress => _gameState.runProgress!;
  ActiveRunStageSnapshot get _stageStartSnapshot =>
      _gameState.stageStartSnapshot!;
  ActiveRunScene get _activeRunScene => _gameState.activeRunScene;
  bool get _pendingResumeShop => _gameState.pendingResumeShop;
  Tile? get _selectedHandTile => _gameState.selectedHandTile;
  int? get _selectedBoardRow => _gameState.selectedBoardRow;
  int? get _selectedBoardCol => _gameState.selectedBoardCol;
  RummiJesterCatalog? get _jesterCatalog => _gameState.jesterCatalog;
  int? get _selectedJesterOverlayIndex =>
      _gameState.selectedJesterOverlayIndex;
  GameStageFlowPhase get _stageFlowPhase => _gameState.stageFlowPhase;
  int get _stageScoreAdded => _gameState.stageScoreAdded;
  ConfirmedLineBreakdown? get _activeSettlementLine =>
      _gameState.activeSettlementLine;
  Map<String, Tile> get _settlementBoardSnapshot =>
      _gameState.settlementBoardSnapshot;
  int get _settlementSequenceTick => _gameState.settlementSequenceTick;
  bool get _isUiLocked => _gameState.isUiLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundManager.playBgm(AssetPaths.bgmMain);
    _gameArgs = GameSessionArgs(
      runSeed: widget.runSeed,
      restoredRun: widget.restoredRun,
    );
    _loadJesterCatalog();
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
      if (_pendingResumeShop) {
        _gameNotifier.setPendingResumeShop(false);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final nextStage = await _showShopScreen();
          if (!mounted) return;
          if (nextStage == true) {
            _runProgress.advanceStage(_session, runSeed: widget.runSeed);
            _clearSelections();
            _gameNotifier.setStageStartSnapshot(
              ActiveRunSaveService.captureStageStartSnapshot(
                session: _session,
                runProgress: _runProgress,
              ),
            );
            _gameNotifier.markDirty();
            _showSnack('스테이지 ${_runProgress.stageIndex} 시작');
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

  void _refresh() {
    if (!mounted) return;
    _gameNotifier.markDirty();
  }

  Future<void> _saveActiveRun({ActiveRunScene? scene}) async {
    if (scene != null) {
      _gameNotifier.setActiveRunScene(scene);
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
      title: '재시작',
      message: '현재 스테이지 시작 시점으로 되돌릴까요?\n이 스테이지에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '재시작',
    );
    if (!mounted || !confirmed) return;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final restoredSession = _stageStartSnapshot.session.copySnapshot();
    final restoredRunProgress = _stageStartSnapshot.runProgress.copySnapshot();
    final refreshedSnapshot = ActiveRunSaveService.captureStageStartSnapshot(
      session: restoredSession,
      runProgress: restoredRunProgress,
    );
    _gameNotifier.replaceRuntimeState(
      session: restoredSession,
      runProgress: restoredRunProgress,
      stageStartSnapshot: refreshedSnapshot,
      activeRunScene: ActiveRunScene.battle,
    );
    await _saveActiveRun(scene: ActiveRunScene.battle);
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

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _goToTitleAfterStoppingBgm();
  }

  void _showGameOver(List<RummiExpirySignal> signals) {
    if (!mounted) return;
    final text = signals.map(_expiryLabel).join('\n');
    _showFramedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('gameResult'),
              style: TextStyle(
                fontFamily: AssetPaths.fontAngduIpsul140,
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                await ActiveRunSaveService.clearActiveRun();
                if (!mounted) return;
                context.go(RoutePaths.title);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF4A81D),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(context.tr('exit')),
            ),
          ],
        ),
      ),
    );
  }

  String _expiryLabel(RummiExpirySignal s) {
    return switch (s) {
      RummiExpirySignal.boardFullAfterDcExhausted =>
        '버림이 모두 소진된 상태에서 보드 25칸이 가득 찼습니다.',
      RummiExpirySignal.drawPileExhausted => '드로우 덱이 소진되었습니다.',
    };
  }

  void _afterAction() {
    final signals = _session.evaluateExpirySignals();
    if (signals.isNotEmpty) {
      _showGameOver(signals);
    }
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
    final ok = _runProgress.sellOwnedJester(index);
    if (!ok) return;
    _showSnack('제스터를 판매했습니다.');
    _gameNotifier.setSelectedJesterOverlayIndex(
      _runProgress.ownedJesters.isEmpty
          ? null
          : index.clamp(0, _runProgress.ownedJesters.length - 1),
    );
    _gameNotifier.markDirty();
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

  void _onBoardCellTap(int row, int col) {
    if (_isUiLocked) return;
    final selectedHand = _selectedHandTile;
    if (selectedHand != null) {
      final placed = _session.tryPlaceFromHand(selectedHand, row, col);
      if (!placed) {
        _showSnack('이 칸에 둘 수 없습니다.');
        return;
      }
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      _clearSelections();
      _gameNotifier.markDirty();
      _afterAction();
      _saveActiveRun();
      return;
    }

    if (_session.board.cellAt(row, col) == null) {
      return;
    }
    if (_selectedBoardRow == row && _selectedBoardCol == col) {
      _gameNotifier.setSelectedBoardCell(null, null);
    } else {
      _gameNotifier.setSelectedBoardCell(row, col);
    }
  }

  void _drawTile() {
    if (_isUiLocked) return;
    if (!_session.canDrawFromDeck) {
      if (_session.deck.isEmpty) {
        _showSnack('덱이 비었습니다.');
      } else {
        _showSnack('손패는 최대 ${_session.maxHandSize}장입니다.');
      }
      return;
    }
    final drawn = _session.drawToHand();
    if (drawn == null) return;
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _gameNotifier.markDirty();
    _afterAction();
    _saveActiveRun();
  }

  void _discardSelectedBoardTile() {
    if (_isUiLocked) return;
    final row = _selectedBoardRow;
    final col = _selectedBoardCol;
    if (row == null || col == null) {
      _showSnack('보드에서 버릴 타일을 먼저 선택하세요.');
      return;
    }
    final result = _session.tryDiscardFromBoard(row, col);
    if (result.fail != null) {
      _showSnack(switch (result.fail!) {
        DiscardFailReason.noBoardDiscardsLeft => '보드패 버림 횟수가 없습니다.',
        DiscardFailReason.noHandDiscardsLeft => '손패 버림 횟수가 없습니다.',
        DiscardFailReason.cellEmpty => '해당 칸이 비어 있습니다.',
        DiscardFailReason.tileNotInHand => '손패에서 버릴 카드를 찾지 못했습니다.',
      });
      return;
    }
    _runProgress.onDiscardUsed();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _clearSelections();
    _gameNotifier.markDirty();
    _afterAction();
    _saveActiveRun();
  }

  void _discardSelectedHandTile() {
    if (_isUiLocked) return;
    final tile = _selectedHandTile;
    if (tile == null) {
      _showSnack('손패에서 버릴 카드를 먼저 선택하세요.');
      return;
    }
    final result = _session.tryDiscardFromHand(tile);
    if (result.fail != null) {
      _showSnack(switch (result.fail!) {
        DiscardFailReason.noBoardDiscardsLeft => '보드패 버림 횟수가 없습니다.',
        DiscardFailReason.noHandDiscardsLeft => '손패 버림 횟수가 없습니다.',
        DiscardFailReason.cellEmpty => '해당 칸이 비어 있습니다.',
        DiscardFailReason.tileNotInHand => '손패에서 버릴 카드를 찾지 못했습니다.',
      });
      return;
    }
    _runProgress.onDiscardUsed();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _clearSelections();
    _gameNotifier.markDirty();
    _afterAction();
    _saveActiveRun();
  }

  void _confirmLines() {
    if (_isUiLocked) return;
    final settlementSnapshot = <String, Tile>{};
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        final tile = _session.board.cellAt(row, col);
        if (tile != null) {
          settlementSnapshot['$row:$col'] = tile;
        }
      }
    }
    final out = _session.confirmAllFullLines(
      jesters: _runProgress.ownedJesters,
      runtimeSnapshot: _runProgress.buildRuntimeSnapshot(),
    );
    if (!out.result.ok) {
      _showSnack('확정할 족보 줄이 없습니다.');
      return;
    }
    _runProgress.onConfirmedLines(out.result.lineBreakdowns);
    _clearSelections();
    _gameNotifier.setSettlementBoardSnapshot(settlementSnapshot);
    SoundManager.playSfx(AssetPaths.sfxCollect);
    _runConfirmSettlementFlow(
      totalScore: out.result.scoreAdded,
      lineBreakdowns: out.result.lineBreakdowns,
      shouldClearAfter: out.cleared != null,
    );
    _afterAction();
    _saveActiveRun();
  }

  Future<void> _runConfirmSettlementFlow({
    required int totalScore,
    required List<ConfirmedLineBreakdown> lineBreakdowns,
    required bool shouldClearAfter,
  }) async {
    final lines = List<ConfirmedLineBreakdown>.from(lineBreakdowns);
    await _playSettlementSequence(
      lines,
      totalScore: totalScore,
      shouldClearAfter: shouldClearAfter,
    );
  }

  Future<void> _playSettlementSequence(
    List<ConfirmedLineBreakdown> lines, {
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

    await Future<void>.delayed(const Duration(milliseconds: 1080));
    if (!mounted) return;
    await _playSettlementSequence(
      lines,
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

    _session.discardStageRemainder();
    final breakdown = _runProgress.buildCashOutBreakdown(_session);
    _runProgress.applyCashOut(breakdown);
    await _saveActiveRun();

    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);

    final enterShop = await _showCashOutSheet(breakdown);
    if (!mounted || enterShop != true) return;

    _runProgress.openShop(
      catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: _session.runRandom,
    );
    await _saveActiveRun(scene: ActiveRunScene.shop);
    _refresh();

    final nextStage = await _showShopScreen();
    if (!mounted || nextStage != true) return;

    _runProgress.advanceStage(_session, runSeed: widget.runSeed);
    _clearSelections();
    _gameNotifier.setStageStartSnapshot(
      ActiveRunSaveService.captureStageStartSnapshot(
        session: _session,
        runProgress: _runProgress,
      ),
    );
    _gameNotifier.markDirty();
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _showSnack('스테이지 ${_runProgress.stageIndex} 시작');
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
          currentGold: _runProgress.gold,
        );
      },
    );
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
          onStateChanged: _saveActiveRun,
          onOpenSettings: () async {
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onRestartRun: _restartCurrentRun,
        ),
      ),
    );
  }

  Future<void> _openShopForTest() async {
    if (_isUiLocked) return;
    _runProgress.openShop(
      catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: _session.runRandom,
      preferredOfferIds: _shopInspectOfferIds,
      offerCountOverride: _shopInspectOfferIds.length,
    );
    await _saveActiveRun(scene: ActiveRunScene.shop);
    _gameNotifier.markDirty();
    _showSnack('검사용 상점 오퍼 ${_shopInspectOfferIds.length}장 표시');
    await _showShopScreen();
    if (!mounted) return;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _gameNotifier.markDirty();
  }

  Future<void> _openGameOptions(BuildContext context) async {
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _showFramedDialog<void>(
      context: context,
      builder: (dialogContext) => _ModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('gameOptions'),
                    style: TextStyle(
                      fontFamily: AssetPaths.fontAngduIpsul140,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('cancel'),
                  onPressed: () {
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('runSeedLabel'),
                    style: TextStyle(
                      fontFamily: AssetPaths.fontAngduIpsul140,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          '${widget.runSeed}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('copy'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: '${widget.runSeed}'),
                          );
                          if (!context.mounted) return;
                          showTopNotice(context, '시드 번호를 복사했습니다.');
                        },
                        icon: const Icon(Icons.copy_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.refresh_rounded,
                color: Colors.amber.shade200,
              ),
              title: Text(
                '재시작',
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await _restartCurrentRun();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Colors.redAccent.shade100,
              ),
              title: Text(
                context.tr('exit'),
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await _exitToTitleWithConfirm();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: Colors.lightBlueAccent.shade100,
              ),
              title: Text(
                context.tr('settings'),
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                await context.push(RoutePaths.setting);
                if (!mounted) return;
                await _openGameOptions(this.context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSurface() {
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
            const Positioned.fill(child: _TableBackdrop()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: _GameLayout(
                  session: _session,
                  runProgress: _runProgress,
                  activeSettlementEffects:
                      _activeSettlementLine?.effects ?? const [],
                  activeSettlementLine: _activeSettlementLine,
                  settlementSequenceTick: _settlementSequenceTick,
                  settlementBoardSnapshot: _settlementBoardSnapshot,
                  selectedHandTile: _selectedHandTile,
                  selectedBoardRow: _selectedBoardRow,
                  selectedBoardCol: _selectedBoardCol,
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
                ),
              ),
            ),
            if (_stageFlowPhase == GameStageFlowPhase.confirmSettlement)
              Positioned.fill(
                child: GameFloatingSettlementBurst(
                  key: ValueKey('settlement-$_settlementSequenceTick'),
                  line: _activeSettlementLine,
                ),
              ),
            if (_stageFlowPhase == GameStageFlowPhase.cleared ||
                _stageFlowPhase == GameStageFlowPhase.settlement)
              Positioned.fill(
                child: GameStageClearOverlay(
                  phase: _stageFlowPhase,
                  stageIndex: _runProgress.stageIndex,
                  scoreAdded: _stageScoreAdded,
                ),
              ),
            if (_selectedJesterOverlayIndex != null &&
                _selectedJesterOverlayIndex! < _runProgress.ownedJesters.length)
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
                        card: _runProgress
                            .ownedJesters[_selectedJesterOverlayIndex!],
                        runtimeValueText: jesterRuntimeValueText(
                          _runProgress
                              .ownedJesters[_selectedJesterOverlayIndex!],
                          _runProgress.buildRuntimeSnapshot(),
                          slotIndex: _selectedJesterOverlayIndex!,
                        ),
                        sellGold: _runProgress.sellPriceAt(
                          _selectedJesterOverlayIndex!,
                        ),
                        onSell: _sellOwnedJesterFromOverlay,
                        onClose: _closeJesterOverlay,
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionNotifierProvider(_gameArgs));
    if (!gameState.isReady) {
      return const PhoneFrameScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return PhoneFrameScaffold(child: _buildGameSurface());
  }
}

Future<T?> _showFramedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

class _ModalCard extends StatelessWidget {
  const _ModalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: child,
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  const _GameLayout({
    required this.session,
    required this.runProgress,
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
            for (final (row, col) in activeSettlementLine!.ref.cells())
              '$row:$col',
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileWidth = boardTileVisualWidth(boardSide);

        return Column(
          children: [
            GameTopHud(
              session: session,
              runProgress: runProgress,
              onOptionsTap: onOptionsTap,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'JESTER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.85,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${runProgress.ownedJesters.length}/${RummiRunProgress.maxJesterSlots}',
                          style: gameHudSubStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GameDebugShopHandCluster(
                    onShopTap: onShopTestTap,
                    handSize: session.maxHandSize,
                    onHandSizeChanged: onDebugHandSizeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            GameJesterStrip(
              cards: runProgress.ownedJesters,
              runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
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
                    label: '줄 확정',
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

class _HandZone extends StatefulWidget {
  const _HandZone({
    required this.session,
    required this.hand,
    required this.selectedHandTile,
    required this.onHandTileTap,
    required this.onDraw,
    required this.tileWidth,
  });

  final RummiPokerGridSession session;
  final List<Tile> hand;
  final Tile? selectedHandTile;
  final ValueChanged<Tile> onHandTileTap;
  final VoidCallback onDraw;
  final double tileWidth;

  @override
  State<_HandZone> createState() => _HandZoneState();
}

class _HandZoneState extends State<_HandZone>
    with SingleTickerProviderStateMixin {
  static const Duration _handAnimDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  List<Tile> _settledHand = <Tile>[];
  List<Tile> _fromHand = <Tile>[];
  List<Tile> _toHand = <Tile>[];
  Tile? _incomingTile;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _settledHand = List<Tile>.from(widget.hand);
    _controller = AnimationController(vsync: this, duration: _handAnimDuration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        setState(() {
          _settledHand = List<Tile>.from(_toHand);
          _fromHand = List<Tile>.from(_toHand);
          _incomingTile = null;
          _animating = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HandZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameTileKeys(oldWidget.hand, widget.hand)) {
      return;
    }

    final oldKeys = oldWidget.hand.map(_handTileKey).toSet();
    final newKeys = widget.hand.map(_handTileKey).toSet();
    final addedKeys = newKeys.difference(oldKeys);
    final removedKeys = oldKeys.difference(newKeys);
    final isSimpleAppend =
        widget.hand.length == oldWidget.hand.length + 1 &&
        addedKeys.length == 1;
    final isOneForOneReplacement =
        widget.hand.length == oldWidget.hand.length &&
        addedKeys.length == 1 &&
        removedKeys.length == 1;

    if (!isSimpleAppend && !isOneForOneReplacement) {
      _controller.stop();
      setState(() {
        _settledHand = List<Tile>.from(widget.hand);
        _fromHand = List<Tile>.from(widget.hand);
        _toHand = List<Tile>.from(widget.hand);
        _incomingTile = null;
        _animating = false;
      });
      return;
    }

    final incoming = widget.hand.firstWhere(
      (tile) => addedKeys.contains(_handTileKey(tile)),
    );

    _controller
      ..stop()
      ..value = 0;

    setState(() {
      _fromHand = isOneForOneReplacement
          ? oldWidget.hand
                .where((tile) => !removedKeys.contains(_handTileKey(tile)))
                .toList(growable: false)
          : List<Tile>.from(oldWidget.hand);
      _toHand = List<Tile>.from(widget.hand);
      _incomingTile = incoming;
      _animating = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final displayedHand = _animating ? _fromHand : _settledHand;
    return Column(
      children: [
        GameBottomInfoRow(session: widget.session),
        const SizedBox(height: 4),
        SizedBox(
          height: 76,
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: GameActionButton(
                  label: '드로우',
                  background: const Color(0xFF267B67),
                  onPressed: widget.onDraw,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fromLayouts = _layoutByKey(
                        _fromHand,
                        size: constraints.biggest,
                        tileWidth: widget.tileWidth,
                      );
                      final toLayouts = _layoutByKey(
                        _toHand.isEmpty ? displayedHand : _toHand,
                        size: constraints.biggest,
                        tileWidth: widget.tileWidth,
                      );
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final t = _animating ? _controller.value : 1.0;
                          // Stack은 뒤에 온 자식이 위에 그려짐 — 선택 패를 마지막에 두어 겹침에서 앞으로.
                          final sel = widget.selectedHandTile;
                          final handPaintOrder = <Tile>[
                            for (final tile in displayedHand)
                              if (sel == null || tile != sel) tile,
                            if (sel != null && displayedHand.contains(sel)) sel,
                          ];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final tile in handPaintOrder)
                                _buildSettledTile(
                                  tile,
                                  fromLayouts: fromLayouts,
                                  toLayouts: toLayouts,
                                  areaSize: constraints.biggest,
                                  t: t,
                                ),
                              if (_incomingTile != null)
                                _buildIncomingTile(
                                  _incomingTile!,
                                  toLayouts: toLayouts,
                                  areaSize: constraints.biggest,
                                  t: t,
                                ),
                              if (displayedHand.isEmpty &&
                                  _incomingTile == null)
                                Center(
                                  child: Text(
                                    '손패 비어 있음',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.38,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettledTile(
    Tile tile, {
    required Map<String, _HandSlotLayout> fromLayouts,
    required Map<String, _HandSlotLayout> toLayouts,
    required Size areaSize,
    required double t,
  }) {
    final key = _handTileKey(tile);
    final from = fromLayouts[key] ?? toLayouts[key];
    final to = toLayouts[key] ?? fromLayouts[key];
    if (from == null || to == null) {
      return const SizedBox.shrink();
    }
    final left = lerpDouble(from.left, to.left, t)!;
    final top = lerpDouble(from.top, to.top, t)!;
    final angle = lerpDouble(from.angle, to.angle, t)!;

    return Positioned(
      key: ValueKey('settled-$key'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: () => widget.onHandTileTap(tile),
          child: GameRummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: kGameTileAspectRatio,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingTile(
    Tile tile, {
    required Map<String, _HandSlotLayout> toLayouts,
    required Size areaSize,
    required double t,
  }) {
    final to = toLayouts[_handTileKey(tile)];
    if (to == null) {
      return const SizedBox.shrink();
    }
    final startLeft = areaSize.width + 12;
    final startTop = (areaSize.height - to.height) / 2;
    final left = lerpDouble(startLeft, to.left, t)!;
    final top = lerpDouble(startTop, to.top, t)!;
    final angle = lerpDouble(0.18, to.angle, t)!;

    return Positioned(
      key: ValueKey('incoming-${_handTileKey(tile)}'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: () => widget.onHandTileTap(tile),
          child: GameRummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: kGameTileAspectRatio,
          ),
        ),
      ),
    );
  }
}

class _HandSlotLayout {
  const _HandSlotLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
}


List<_HandSlotLayout> _buildHandSlotLayouts(
  Size size, {
  required double tileWidth,
  required int cardCount,
}) {
  final slotCount = cardCount.clamp(1, 3);
  final cardWidth = tileWidth;
  final cardHeight = cardWidth / kGameTileAspectRatio;
  final step = cardWidth * 0.88;
  final usedWidth = cardWidth + step * (slotCount - 1);
  final startLeft = (size.width - usedWidth) / 2;
  final centerY = (size.height - cardHeight) / 2;
  final mid = (slotCount - 1) / 2;

  return List<_HandSlotLayout>.generate(slotCount, (index) {
    final delta = index - mid;
    final angle = delta * 0.055;
    final lift = delta.abs() * 3.0;
    return _HandSlotLayout(
      left: startLeft + step * index,
      top: centerY + lift,
      width: cardWidth,
      height: cardHeight,
      angle: angle,
    );
  });
}

String _handTileKey(Tile tile) => tile.toString();

bool _sameTileKeys(List<Tile> a, List<Tile> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (_handTileKey(a[i]) != _handTileKey(b[i])) return false;
  }
  return true;
}

Map<String, _HandSlotLayout> _layoutByKey(
  List<Tile> hand, {
  required Size size,
  required double tileWidth,
}) {
  final layouts = _buildHandSlotLayouts(
    size,
    tileWidth: tileWidth,
    cardCount: hand.length,
  );
  final out = <String, _HandSlotLayout>{};
  for (var i = 0; i < hand.length && i < layouts.length; i++) {
    out[_handTileKey(hand[i])] = layouts[i];
  }
  return out;
}


class _TableBackdrop extends StatelessWidget {
  const _TableBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TableBackdropPainter());
  }
}

class _TableBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5644), Color(0xFF12392E), Color(0xFF0A211B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withValues(alpha: 0.035);
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.08);

    final seeds = [
      Offset(size.width * 0.18, size.height * 0.16),
      Offset(size.width * 0.82, size.height * 0.2),
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.72, size.height * 0.62),
      Offset(size.width * 0.22, size.height * 0.82),
    ];

    for (final center in seeds) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * 0.22,
        height: size.width * 0.22,
      );
      canvas.drawOval(rect.shift(const Offset(16, 12)), shadowPaint);
      canvas.drawOval(rect, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String handRankLabel(RummiHandRank rank) {
  return switch (rank) {
    RummiHandRank.highCard => '하이',
    RummiHandRank.onePair => '원페어',
    RummiHandRank.twoPair => '투페어',
    RummiHandRank.threeOfAKind => '트리플',
    RummiHandRank.straight => '스트레이트',
    RummiHandRank.flush => '플러시',
    RummiHandRank.fullHouse => '풀하우스',
    RummiHandRank.fourOfAKind => '포카드',
    RummiHandRank.straightFlush => '스티플',
  };
}
