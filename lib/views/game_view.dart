import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/line_ref.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../resources/asset_paths.dart';
import '../resources/jester_translation_scope.dart';
import '../resources/sound_manager.dart';
import '../widgets/phone_frame_scaffold.dart';

enum _StageFlowPhase { none, confirmSettlement, cleared, settlement }

class GameView extends StatefulWidget {
  const GameView({super.key, required this.runSeed});

  final int runSeed;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
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

  late final RummiPokerGridSession _session;
  final RummiRunProgress _runProgress = RummiRunProgress();

  Tile? _selectedHandTile;
  int? _selectedBoardRow;
  int? _selectedBoardCol;
  RummiJesterCatalog? _jesterCatalog;
  int? _selectedJesterOverlayIndex;
  _StageFlowPhase _stageFlowPhase = _StageFlowPhase.none;
  int _stageScoreAdded = 0;
  ConfirmedLineBreakdown? _activeSettlementLine;
  Map<String, Tile> _settlementBoardSnapshot = const {};
  int _settlementSequenceTick = 0;

  bool get _isUiLocked => _stageFlowPhase != _StageFlowPhase.none;

  @override
  void initState() {
    super.initState();
    SoundManager.playBgm(AssetPaths.bgmMain);
    _session = RummiPokerGridSession(runSeed: widget.runSeed);
    _loadJesterCatalog();
  }

  Future<void> _loadJesterCatalog() async {
    try {
      final catalog = await RummiJesterCatalog.loadFromAsset(
        AssetPaths.jestersCommon,
      );
      if (!mounted) return;
      setState(() {
        _jesterCatalog = catalog;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _jesterCatalog = null;
      });
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  void _setDebugMaxHandSize(int value) {
    setState(() {
      _session.setDebugMaxHandSize(value);
      if (_selectedHandTile != null && !_session.hand.contains(_selectedHandTile)) {
        _selectedHandTile = null;
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              onPressed: () {
                Navigator.of(ctx).pop();
                SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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
    _selectedHandTile = null;
    _selectedBoardRow = null;
    _selectedBoardCol = null;
  }

  void _openJesterOverlay(int index) {
    if (_isUiLocked) return;
    setState(() {
      _selectedJesterOverlayIndex = index;
    });
  }

  void _closeJesterOverlay() {
    if (!mounted) return;
    setState(() {
      _selectedJesterOverlayIndex = null;
    });
  }

  void _sellOwnedJesterFromOverlay() {
    final index = _selectedJesterOverlayIndex;
    if (index == null) return;
    final ok = _runProgress.sellOwnedJester(index);
    if (!ok) return;
    _showSnack('제스터를 판매했습니다.');
    setState(() {
      if (_runProgress.ownedJesters.isEmpty) {
        _selectedJesterOverlayIndex = null;
      } else {
        _selectedJesterOverlayIndex = index.clamp(
          0,
          _runProgress.ownedJesters.length - 1,
        );
      }
    });
  }

  void _toggleHandTile(Tile tile) {
    if (_isUiLocked) return;
    setState(() {
      if (_selectedHandTile == tile) {
        _selectedHandTile = null;
      } else {
        _selectedHandTile = tile;
        _selectedBoardRow = null;
        _selectedBoardCol = null;
      }
    });
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
      setState(_clearSelections);
      _afterAction();
      return;
    }

    if (_session.board.cellAt(row, col) == null) {
      return;
    }
    setState(() {
      if (_selectedBoardRow == row && _selectedBoardCol == col) {
        _selectedBoardRow = null;
        _selectedBoardCol = null;
      } else {
        _selectedBoardRow = row;
        _selectedBoardCol = col;
        _selectedHandTile = null;
      }
    });
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
    _refresh();
    _afterAction();
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
    setState(_clearSelections);
    _afterAction();
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
    setState(_clearSelections);
    _afterAction();
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
    setState(() {
      _clearSelections();
      _settlementBoardSnapshot = settlementSnapshot;
    });
    SoundManager.playSfx(AssetPaths.sfxCollect);
    _runConfirmSettlementFlow(
      totalScore: out.result.scoreAdded,
      lineBreakdowns: out.result.lineBreakdowns,
      shouldClearAfter: out.cleared != null,
    );
    _afterAction();
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
      setState(() {
        _activeSettlementLine = null;
        _settlementBoardSnapshot = const {};
        _stageFlowPhase = _StageFlowPhase.none;
      });
      if (shouldClearAfter) {
        SoundManager.playSfx(AssetPaths.sfxClear);
        await _runStageClearFlow(totalScore);
      }
      return;
    }

    setState(() {
      _stageScoreAdded = totalScore;
      _activeSettlementLine = lines[index];
      _settlementSequenceTick += 1;
      _stageFlowPhase = _StageFlowPhase.confirmSettlement;
    });

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
    setState(() {
      _stageScoreAdded = scoreAdded;
      _activeSettlementLine = null;
      _stageFlowPhase = _StageFlowPhase.cleared;
    });

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() {
      _stageFlowPhase = _StageFlowPhase.settlement;
    });

    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    _session.discardStageRemainder();
    final breakdown = _runProgress.buildCashOutBreakdown(_session);
    _runProgress.applyCashOut(breakdown);

    setState(() {
      _stageFlowPhase = _StageFlowPhase.none;
    });

    final enterShop = await _showCashOutSheet(breakdown);
    if (!mounted || enterShop != true) return;

    _runProgress.openShop(
      catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: _session.runRandom,
    );
    _refresh();

    final nextStage = await _showShopScreen();
    if (!mounted || nextStage != true) return;

    setState(() {
      _runProgress.advanceStage(_session, runSeed: widget.runSeed);
      _clearSelections();
    });
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
        return _CashOutSheet(
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
        builder: (context) => _ShopScreen(
          runProgress: _runProgress,
          catalog: _jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[],
          rng: _session.runRandom,
          runSeed: widget.runSeed,
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
    _refresh();
    _showSnack('검사용 상점 오퍼 ${_shopInspectOfferIds.length}장 표시');
    await _showShopScreen();
    if (!mounted) return;
    _refresh();
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('시드 번호를 복사했습니다.')),
                          );
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
                SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                await _goToTitleAfterStoppingBgm();
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
                  onClearSelection: () => setState(_clearSelections),
                ),
              ),
            ),
            if (_stageFlowPhase == _StageFlowPhase.confirmSettlement)
              Positioned.fill(
                child: _FloatingSettlementBurst(
                  key: ValueKey('settlement-$_settlementSequenceTick'),
                  line: _activeSettlementLine,
                ),
              ),
            if (_stageFlowPhase == _StageFlowPhase.cleared ||
                _stageFlowPhase == _StageFlowPhase.settlement)
              Positioned.fill(
                child: _StageClearOverlay(
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
                      child: _JesterInfoOverlay(
                        card: _runProgress
                            .ownedJesters[_selectedJesterOverlayIndex!],
                        runtimeValueText: _jesterRuntimeValueText(
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
    final scoringCells = _scoringCellSet(session);
    final activeSettlementCells = activeSettlementLine == null
        ? <String>{}
        : {
            for (final (row, col) in activeSettlementLine!.ref.cells())
              '$row:$col',
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileWidth = _boardTileVisualWidth(boardSide);

        return Column(
          children: [
            _TopHud(
              session: session,
              runProgress: runProgress,
              onOptionsTap: onOptionsTap,
              onShopTestTap: onShopTestTap,
            ),
            const SizedBox(height: 12),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${runProgress.ownedJesters.length}/${RummiRunProgress.maxJesterSlots}',
                          style: _hudSubStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onShopTestTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4A81D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'SHOP',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _DebugHandSizeSegment(
                    value: session.maxHandSize,
                    onChanged: onDebugHandSizeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _JesterStrip(
              cards: runProgress.ownedJesters,
              runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
              activeEffects: activeSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              onTapCard: onJesterTap,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _BoardGrid(
                board: session.board,
                scoringCells: scoringCells,
                activeSettlementCells: activeSettlementCells,
                settlementBoardSnapshot: settlementBoardSnapshot,
                selectedRow: selectedBoardRow,
                selectedCol: selectedBoardCol,
                onTapCell: onBoardCellTap,
              ),
            ),
            const SizedBox(height: 8),
            _HandZone(
              session: session,
              hand: List<Tile>.from(session.hand),
              selectedHandTile: selectedHandTile,
              onHandTileTap: onHandTileTap,
              onDraw: onDraw,
              tileWidth: tileWidth,
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '보드패 버림',
                        background: const Color(0xFF44554C),
                        onPressed: onBoardDiscard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: '손패 버림',
                        background: const Color(0xFF5B4D33),
                        onPressed: onHandDiscard,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        label: '줄 확정',
                        background: const Color(0xFFF4A81D),
                        foreground: Colors.black,
                        onPressed: onConfirm,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: '선택 해제',
                        background: const Color(0xFF44554C),
                        onPressed: onClearSelection,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.session,
    required this.runProgress,
    required this.onOptionsTap,
    required this.onShopTestTap,
  });

  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
  final VoidCallback onOptionsTap;
  final VoidCallback onShopTestTap;

  @override
  Widget build(BuildContext context) {
    final blind = session.blind;
    final progress = blind.targetScore <= 0
        ? 0.0
        : (blind.scoreTowardBlind / blind.targetScore).clamp(0.0, 1.0);

    return SizedBox(
      height: 84,
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: _HudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STAGE',
                    style: _hudLabelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${runProgress.stageIndex}',
                          maxLines: 1,
                          style: _hudValueStyle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '보상 +${RummiRunProgress.stageClearGoldBase}',
                    style: _hudSubStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 14,
            child: _HudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'BLIND SCORE',
                          style: _hudLabelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${blind.scoreTowardBlind} / ${blind.targetScore}',
                          maxLines: 1,
                          style: _hudValueStyle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF4A81D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: _HudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'GOLD',
                          style: _hudLabelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onOptionsTap,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withValues(alpha: 0.88),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${runProgress.gold}',
                          maxLines: 1,
                          style: _hudValueStyle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _hudLabelStyle = TextStyle(
  color: Colors.white70,
  fontSize: 9,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.35,
);

final TextStyle _hudValueStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.96),
  fontWeight: FontWeight.w900,
  height: 1,
);

const TextStyle _hudSubStyle = TextStyle(
  color: Colors.white70,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

class _BottomInfoRow extends StatelessWidget {
  const _BottomInfoRow({required this.session});

  final RummiPokerGridSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '덱 ${session.deck.remaining}/${session.totalDeckSize}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '보드패 버림 ${session.blind.boardDiscardsRemaining}/${session.blind.boardDiscardsMax}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '손패 ${session.hand.length}/${session.maxHandSize} · 버림 ${session.blind.handDiscardsRemaining}/${session.blind.handDiscardsMax}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugHandSizeSegment extends StatelessWidget {
  const _DebugHandSizeSegment({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 6),
            child: Text(
              'Hand',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final option in const [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: GestureDetector(
                onTap: () => onChanged(option),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: value == option
                        ? const Color(0xFF4AA78D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$option',
                    style: TextStyle(
                      color: value == option ? Colors.white : Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A4D3C).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6A8E7C).withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
        child: child,
      ),
    );
  }
}

class _JesterStrip extends StatelessWidget {
  const _JesterStrip({
    required this.cards,
    required this.runtimeSnapshot,
    required this.activeEffects,
    required this.settlementSequenceTick,
    required this.onTapCard,
  });

  final List<RummiJesterCard> cards;
  final RummiJesterRuntimeSnapshot runtimeSnapshot;
  final List<RummiJesterEffectBreakdown> activeEffects;
  final int settlementSequenceTick;
  final ValueChanged<int> onTapCard;

  @override
  Widget build(BuildContext context) {
    final effectById = <String, RummiJesterEffectBreakdown>{};
    for (final effect in activeEffects) {
      effectById[effect.jesterId] = effect;
    }
    return SizedBox(
      height: _kJesterCardHeight + 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          return SizedBox(
            width: _kJesterCardWidth,
            height: _kJesterCardHeight,
            child: _JesterSlot(
              card: index < cards.length ? cards[index] : null,
              runtimeValueText: index < cards.length
                  ? _jesterRuntimeValueText(
                      cards[index],
                      runtimeSnapshot,
                      slotIndex: index,
                    )
                  : null,
              extended: index == 4,
              activeEffect: index < cards.length
                  ? effectById[cards[index].id]
                  : null,
              settlementSequenceTick: settlementSequenceTick,
              onTap: index < cards.length ? () => onTapCard(index) : null,
            ),
          );
        }),
      ),
    );
  }
}

class _JesterSlot extends StatelessWidget {
  const _JesterSlot({
    required this.card,
    required this.runtimeValueText,
    required this.extended,
    required this.activeEffect,
    required this.settlementSequenceTick,
    this.onTap,
  });

  final RummiJesterCard? card;
  final String? runtimeValueText;
  final bool extended;
  final RummiJesterEffectBreakdown? activeEffect;
  final int settlementSequenceTick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF183E32).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                extended ? 'EXT' : 'JESTER',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.55,
                ),
              ),
              const Spacer(),
              Center(
                child: Icon(
                  extended ? Icons.add_box_outlined : Icons.style_outlined,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  extended ? '5th' : '+',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rarityColor = switch (card?.rarity) {
      RummiJesterRarity.uncommon => const Color(0xFF6CD19B),
      RummiJesterRarity.rare => const Color(0xFF67B7FF),
      RummiJesterRarity.legendary => const Color(0xFFF2C14E),
      _ => Colors.white70,
    };
    final isActive = activeEffect != null;
    final displayName = _localizedJesterName(context, card!);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7DB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFF2C14E)
                    : rarityColor.withValues(alpha: 0.72),
                width: isActive ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFF2C14E).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: isActive ? 12 : 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: card == null
                          ? const Color(0xFF385248)
                          : rarityColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF20312B).withValues(alpha: 0.92),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      height: 1.05,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20312B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _jesterCategoryLabel(card!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1B3A31),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (activeEffect != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4A3B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _jesterEffectBadge(activeEffect!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (activeEffect != null)
            Positioned(
              left: 4,
              right: 4,
              top: -16,
              child: _JesterEffectBurst(
                key: ValueKey(
                  'jester-burst-${activeEffect!.jesterId}-$settlementSequenceTick',
                ),
                effect: activeEffect!,
              ),
            ),
        ],
      ),
    );
  }
}

class _JesterEffectBurst extends StatelessWidget {
  const _JesterEffectBurst({super.key, required this.effect});

  final RummiJesterEffectBreakdown effect;

  @override
  Widget build(BuildContext context) {
    final label = effect.displayToken;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      builder: (context, value, child) {
        final fade = value < 0.18
            ? value / 0.18
            : value > 0.76
            ? (1 - value) / 0.24
            : 1.0;
        final dy = lerpDouble(10, -12, Curves.easeOut.transform(value))!;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8143C31),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFF2C14E).withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF2C14E).withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _OutlinedLabel(
              label,
              fillColor: const Color(0xFFFFF4CF),
              strokeColor: const Color(0xFF173126),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _JesterInfoOverlay extends StatelessWidget {
  const _JesterInfoOverlay({
    required this.card,
    this.runtimeValueText,
    required this.sellGold,
    required this.onSell,
    required this.onClose,
  });

  final RummiJesterCard card;
  final String? runtimeValueText;
  final int sellGold;
  final VoidCallback onSell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final notes = JesterTranslationScope.of(context).notes(card.id);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF123126).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _localizedJesterName(context, card),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                _localizedJesterEffect(context, card),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (runtimeValueText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    runtimeValueText!,
                    style: const TextStyle(
                      color: Color(0xFFF4E6B1),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              if (notes != null && notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  notes,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSell,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB74B3B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '판매 +$sellGold Gold',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.board,
    required this.scoringCells,
    required this.activeSettlementCells,
    required this.settlementBoardSnapshot,
    required this.selectedRow,
    required this.selectedCol,
    required this.onTapCell,
  });

  final RummiBoard board;
  final Set<String> scoringCells;
  final Set<String> activeSettlementCells;
  final Map<String, Tile> settlementBoardSnapshot;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onTapCell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        const frameInset = 10.0;
        const gridGap = 1.5;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A4B3A).withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF739785).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(frameInset),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kBoardSize,
                    mainAxisSpacing: gridGap,
                    crossAxisSpacing: gridGap,
                  ),
                  itemCount: kBoardSize * kBoardSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ kBoardSize;
                    final col = index % kBoardSize;
                    final tile =
                        board.cellAt(row, col) ??
                        settlementBoardSnapshot['$row:$col'];
                    final selected = selectedRow == row && selectedCol == col;
                    final scoring = scoringCells.contains('$row:$col');
                    final settlementActive = activeSettlementCells.contains(
                      '$row:$col',
                    );
                    return _BoardCell(
                      tile: tile,
                      selected: selected,
                      scoring: scoring,
                      settlementActive: settlementActive,
                      onTap: () => onTapCell(row, col),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.tile,
    required this.selected,
    required this.scoring,
    required this.settlementActive,
    required this.onTap,
  });

  final Tile? tile;
  final bool selected;
  final bool scoring;
  final bool settlementActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFF76D5E)
        : settlementActive
        ? const Color(0xFF86F4C3)
        : scoring
        ? const Color(0xFFF4C45A)
        : Colors.white.withValues(alpha: 0.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final cornerRadius = rummikubTileCornerRadiusForSide(side);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2A3B34)
                    : settlementActive
                    ? const Color(0xFF285A49)
                    : const Color(0xFF204E3C).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(cornerRadius),
                border: Border.all(
                  color: borderColor,
                  width: selected || settlementActive ? 2 : 1,
                ),
                boxShadow: settlementActive
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF86F4C3,
                          ).withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: tile == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: _RummiTileCard(
                        tile: tile!,
                        selected: selected,
                        accent: false,
                        aspectRatio: _kTileAspectRatio,
                      ),
                    ),
            ),
          ),
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
        _BottomInfoRow(session: widget.session),
        const SizedBox(height: 6),
        SizedBox(
          height: 88,
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: _ActionButton(
                  label: '드로우',
                  background: const Color(0xFF267B67),
                  onPressed: widget.onDraw,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
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
          child: _RummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: _kTileAspectRatio,
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
          child: _RummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: _kTileAspectRatio,
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

const double _kTileAspectRatio = 1.0;
const double _kJesterCardWidth = 58.0;
const double _kJesterCardHeight = 78.0;
const double _kBoardFrameInset = 10.0;
const double _kBoardGridGap = 1.5;
const double _kBoardTileInnerPadding = 2.0;

double _boardTileVisualWidth(double boardSide) {
  final gridSide = boardSide - (_kBoardFrameInset * 2);
  final cellSide =
      (gridSide - (_kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
  return cellSide - (_kBoardTileInnerPadding * 2);
}

List<_HandSlotLayout> _buildHandSlotLayouts(
  Size size, {
  required double tileWidth,
  required int cardCount,
}) {
  final slotCount = cardCount.clamp(1, 3);
  final cardWidth = tileWidth;
  final cardHeight = cardWidth / _kTileAspectRatio;
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

class _StageClearOverlay extends StatelessWidget {
  const _StageClearOverlay({
    required this.phase,
    required this.stageIndex,
    required this.scoreAdded,
  });

  final _StageFlowPhase phase;
  final int stageIndex;
  final int scoreAdded;

  @override
  Widget build(BuildContext context) {
    final isSettlement = phase == _StageFlowPhase.settlement;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xFF153C31),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF2C14E).withValues(alpha: 0.72),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSettlement ? 'SCORE SETTLED' : 'STAGE CLEAR',
                  style: TextStyle(
                    color: isSettlement
                        ? Colors.white.withValues(alpha: 0.78)
                        : const Color(0xFFF2C14E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '스테이지 $stageIndex',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (isSettlement)
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: scoreAdded),
                    duration: const Duration(milliseconds: 720),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        '+$value',
                        style: const TextStyle(
                          color: Color(0xFFF2C14E),
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      );
                    },
                  )
                else
                  Text(
                    '목표 점수 달성',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  isSettlement ? '이번 확정으로 +$scoreAdded' : '정산 중...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingSettlementBurst extends StatelessWidget {
  const _FloatingSettlementBurst({super.key, required this.line});

  final ConfirmedLineBreakdown? line;

  @override
  Widget build(BuildContext context) {
    final currentLine = line;
    final label = currentLine == null
        ? '점수 정산'
        : '${handRankLabel(currentLine.rank)} · ${_lineRefShortLabel(currentLine.ref)}';
    final subLabel = currentLine == null
        ? null
        : currentLine.jesterBonus > 0
        ? '기본 ${currentLine.baseScore} + 가중 ${currentLine.jesterBonus}'
        : '기본 ${currentLine.baseScore}';
    final displayedScore = currentLine?.finalScore ?? 0;
    final jesterLabel = currentLine == null
        ? null
        : _settlementJesterNames(currentLine);

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 980),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final fadeIn = (value / 0.18).clamp(0.0, 1.0);
          final fadeOut = ((1 - value) / 0.28).clamp(0.0, 1.0);
          final opacity = value < 0.72 ? fadeIn : fadeOut;
          final dy = lerpDouble(22, -42, value)!;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: Align(
          alignment: const Alignment(0, -0.18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OutlinedLabel(
                    label,
                    textAlign: TextAlign.center,
                    fillColor: Colors.white.withValues(alpha: 0.96),
                    strokeColor: Colors.black.withValues(alpha: 0.82),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                  const SizedBox(height: 6),
                  _OutlinedLabel(
                    '+$displayedScore',
                    fillColor: const Color(0xFFF2C14E),
                    strokeColor: Colors.black.withValues(alpha: 0.88),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    _OutlinedLabel(
                      subLabel,
                      textAlign: TextAlign.center,
                      fillColor: Colors.white.withValues(alpha: 0.78),
                      strokeColor: Colors.black.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    if (jesterLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        jesterLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedLabel extends StatelessWidget {
  const _OutlinedLabel(
    this.text, {
    this.textAlign,
    required this.fillColor,
    required this.strokeColor,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
    this.height,
  });

  final String text;
  final TextAlign? textAlign;
  final Color fillColor;
  final Color strokeColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = strokeColor;

    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            foreground: strokePaint,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            height: height,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            color: fillColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            height: height,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CashOutSheet extends StatefulWidget {
  const _CashOutSheet({required this.breakdown, required this.currentGold});

  final RummiCashOutBreakdown breakdown;
  final int currentGold;

  @override
  State<_CashOutSheet> createState() => _CashOutSheetState();
}

class _CashOutSheetState extends State<_CashOutSheet> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _runSteps();
  }

  Future<void> _runSteps() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _step = 1);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _step = 2);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _step = 3);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _step = 4);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _step = 5);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF102D25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '정산 완료',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedOpacity(
                  opacity: _step >= 1 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _CashOutLine(
                    leading: 'Stage ${b.stageIndex}',
                    text: '목표 ${b.targetScore} 달성 보상',
                    gold: b.blindReward,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _step >= 2 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _CashOutLine(
                    leading: '${b.remainingBoardDiscards}',
                    text:
                        '남은 보드 버림 ${b.remainingBoardDiscards}회 x ${b.perBoardDiscardBonus}',
                    gold: b.boardDiscardGold,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _step >= 3 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _CashOutLine(
                    leading: '${b.remainingHandDiscards}',
                    text:
                        '남은 손패 버림 ${b.remainingHandDiscards}회 x ${b.perHandDiscardBonus}',
                    gold: b.handDiscardGold,
                  ),
                ),
                if (b.economyBonuses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _step >= 4 ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Column(
                      children: [
                        for (final bonus in b.economyBonuses) ...[
                          _CashOutLine(
                            leading: 'J',
                            text:
                                '${JesterTranslationScope.of(context).resolveDisplayName(bonus.jesterId, bonus.displayName)} 보너스',
                            gold: bonus.gold,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _step >= (b.economyBonuses.isNotEmpty ? 5 : 4) ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '보유 골드 ${widget.currentGold}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '+${b.totalGold}',
                          style: const TextStyle(
                            color: Color(0xFFF2C14E),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _step < 3
                      ? null
                      : () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A81D),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '상점으로',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashOutLine extends StatelessWidget {
  const _CashOutLine({
    required this.leading,
    required this.text,
    required this.gold,
  });

  final String leading;
  final String text;
  final int gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF183E32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              leading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '+$gold',
            style: const TextStyle(
              color: Color(0xFFF2C14E),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopScreen extends StatefulWidget {
  const _ShopScreen({
    required this.runProgress,
    required this.catalog,
    required this.rng,
    required this.runSeed,
  });

  final RummiRunProgress runProgress;
  final List<RummiJesterCard> catalog;
  final Random rng;
  final int runSeed;

  @override
  State<_ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<_ShopScreen> {
  int? _selectedOwnedIndex;
  int? _selectedOfferIndex;
  bool _sellTargetActive = false;
  int? _draggingOwnedIndex;

  Future<void> _goToTitleAfterStoppingBgm() async {
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  @override
  void initState() {
    super.initState();
    if (widget.runProgress.ownedJesters.isNotEmpty) {
      _selectedOwnedIndex = 0;
    } else if (widget.runProgress.shopOffers.isNotEmpty) {
      _selectedOfferIndex = 0;
    }
  }

  void _selectOwned(int index) {
    setState(() {
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
    });
  }

  Future<void> _showOwnedJesterDetail(int index) async {
    if (index < 0 || index >= widget.runProgress.ownedJesters.length) return;
    final card = widget.runProgress.ownedJesters[index];
    final notes = JesterTranslationScope.of(context).notes(card.id);
    final sellGold = widget.runProgress.sellPriceAt(index);
    final runtimeValueText = _jesterRuntimeValueText(
      card,
      widget.runProgress.buildRuntimeSnapshot(),
      slotIndex: index,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102D25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _localizedJesterName(context, card),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 100,
                          child: _JesterSlot(
                            card: card,
                            runtimeValueText: runtimeValueText,
                            extended: false,
                            activeEffect: null,
                            settlementSequenceTick: 0,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localizedJesterEffect(context, card),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              if (runtimeValueText != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    runtimeValueText,
                                    style: const TextStyle(
                                      color: Color(0xFFF4E6B1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              if (notes != null && notes.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _sellOwned(index);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB74B3B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '판매 +$sellGold Gold',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectOffer(int index) {
    setState(() {
      _selectedOfferIndex = index;
      _selectedOwnedIndex = null;
    });
  }

  Future<void> _reroll() async {
    final confirmed = await _showFramedDialog<bool>(
      context: context,
      builder: (dialogContext) => _ModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '리롤 확인',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '정말 리롤할까요?',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A81D),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      '리롤',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;

    final ok = widget.runProgress.rerollShop(
      catalog: widget.catalog,
      rng: widget.rng,
    );
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리롤 골드가 부족합니다.')));
      return;
    }
    setState(() {
      _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      _selectedOwnedIndex ??= widget.runProgress.ownedJesters.isEmpty
          ? null
          : 0;
    });
  }

  void _buySelected() {
    final index = _selectedOfferIndex;
    if (index == null) return;
    final ok = widget.runProgress.buyOffer(index);
    if (!ok) {
      final text =
          widget.runProgress.ownedJesters.length >=
              RummiRunProgress.maxJesterSlots
          ? '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.'
          : '골드가 부족합니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    setState(() {
      if (widget.runProgress.ownedJesters.isNotEmpty) {
        _selectedOwnedIndex = widget.runProgress.ownedJesters.length - 1;
        _selectedOfferIndex = null;
      } else {
        _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      }
    });
  }

  void _sellOwned(int index) {
    final ok = widget.runProgress.sellOwnedJester(index);
    if (!ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('제스터를 판매했습니다.')));
    setState(() {
      if (widget.runProgress.ownedJesters.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(
          0,
          widget.runProgress.ownedJesters.length - 1,
        );
      }
    });
  }

  Future<void> _openOptions() async {
    await _showFramedDialog<void>(
      context: context,
      builder: (dialogContext) => _ModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '상점 옵션',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                    'Run Seed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: '${widget.runSeed}'),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('시드 번호를 복사했습니다.')),
                          );
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
                Icons.settings_rounded,
                color: Colors.lightBlueAccent.shade100,
              ),
              title: Text(
                context.tr('settings'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await context.push(RoutePaths.setting);
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
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(false);
                await _goToTitleAfterStoppingBgm();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingSellIndex = _draggingOwnedIndex ?? _selectedOwnedIndex;
    final pendingSellPrice =
        pendingSellIndex != null &&
            pendingSellIndex >= 0 &&
            pendingSellIndex < widget.runProgress.ownedJesters.length
        ? widget.runProgress.sellPriceAt(pendingSellIndex)
        : null;

    return PhoneFrameScaffold(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF123B32), Color(0xFF102E27), Color(0xFF0A1F1A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jester Shop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            'Gold ${widget.runProgress.gold}',
                            style: const TextStyle(
                              color: Color(0xFFF2C14E),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _openOptions,
                          icon: const Icon(Icons.more_horiz_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '보유 Jester 5슬롯',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: _kJesterCardHeight + 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          RummiRunProgress.maxJesterSlots,
                          (index) {
                            final card =
                                index < widget.runProgress.ownedJesters.length
                                ? widget.runProgress.ownedJesters[index]
                                : null;
                            final selected = _selectedOwnedIndex == index;
                            final child = Padding(
                              padding: const EdgeInsets.all(3),
                              child: Stack(
                                children: [
                                  if (selected)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              17,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFF2C14E),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: _JesterSlot(
                                      card: card,
                                      runtimeValueText: card == null
                                          ? null
                                          : _jesterRuntimeValueText(
                                              card,
                                              widget.runProgress
                                                  .buildRuntimeSnapshot(),
                                              slotIndex: index,
                                            ),
                                      extended: index == 4,
                                      activeEffect: null,
                                      settlementSequenceTick: 0,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            return SizedBox(
                              width: _kJesterCardWidth + 6,
                              height: _kJesterCardHeight + 6,
                              child: card == null
                                  ? child
                                  : LongPressDraggable<int>(
                                      data: index,
                                      onDragStarted: () {
                                        setState(() {
                                          _sellTargetActive = true;
                                          _draggingOwnedIndex = index;
                                        });
                                      },
                                      onDragEnd: (_) {
                                        if (mounted) {
                                          setState(() {
                                            _sellTargetActive = false;
                                            _draggingOwnedIndex = null;
                                          });
                                        }
                                      },
                                      feedback: SizedBox(
                                        width: _kJesterCardWidth + 6,
                                        height: _kJesterCardHeight + 6,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: _JesterSlot(
                                              card: card,
                                              runtimeValueText:
                                                  _jesterRuntimeValueText(
                                                    card,
                                                    widget.runProgress
                                                        .buildRuntimeSnapshot(),
                                                    slotIndex: index,
                                                  ),
                                              extended: index == 4,
                                              activeEffect: null,
                                              settlementSequenceTick: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _selectOwned(index);
                                          _showOwnedJesterDetail(index);
                                        },
                                        child: child,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DragTarget<int>(
                      onWillAcceptWithDetails: (_) {
                        setState(() => _sellTargetActive = true);
                        return true;
                      },
                      onLeave: (_) {
                        setState(() {
                          _sellTargetActive = false;
                        });
                      },
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _sellTargetActive = false;
                          _draggingOwnedIndex = null;
                        });
                        _sellOwned(details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final active =
                            _sellTargetActive || candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF5A1E1E)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFFFF8A65)
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            active
                                ? pendingSellPrice == null
                                      ? '여기에 놓으면 판매'
                                      : '여기에 놓으면 판매 +$pendingSellPrice Gold'
                                : pendingSellPrice == null
                                ? '보유 Jester를 길게 눌러 여기로 드래그하면 판매'
                                : '길게 눌러 드래그 판매 가능 · 예상 판매가 +$pendingSellPrice Gold',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '오퍼 목록',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _reroll,
                          child: Text(
                            '리롤 ${widget.runProgress.rerollCost}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: widget.runProgress.shopOffers.isEmpty
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  '이번 상점에 노출된 Jester가 없습니다.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: widget.runProgress.shopOffers.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final offer =
                                    widget.runProgress.shopOffers[index];
                                return _ShopOfferCard(
                                  offer: offer,
                                  selected: _selectedOfferIndex == index,
                                  canAfford: widget.runProgress.canAfford(
                                    offer.price,
                                  ),
                                  onTap: () => _selectOffer(index),
                                  onBuy: () {
                                    _selectOffer(index);
                                    _buySelected();
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop(false);
                              await _goToTitleAfterStoppingBgm();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '메인 메뉴',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF267B67),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '다음 스테이지',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopOfferCard extends StatelessWidget {
  const _ShopOfferCard({
    required this.offer,
    required this.selected,
    required this.canAfford,
    required this.onTap,
    required this.onBuy,
  });

  final RummiShopOffer offer;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFF2C14E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF173C31)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _kJesterCardWidth,
                      height: _kJesterCardHeight,
                      child: _JesterSlot(
                        card: offer.card,
                        runtimeValueText: null,
                        extended: false,
                        activeEffect: null,
                        settlementSequenceTick: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizedJesterName(context, offer.card),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizedJesterEffect(context, offer.card),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer.price}',
                          style: TextStyle(
                            color: canAfford
                                ? const Color(0xFFF2C14E)
                                : Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          child: FilledButton(
                            onPressed: canAfford ? onBuy : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              backgroundColor: const Color(0xFFF4A81D),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '구매',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.onPressed,
    this.foreground = Colors.white,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class _RummiTileCard extends StatelessWidget {
  const _RummiTileCard({
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = _kTileAspectRatio,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: _RummiTilePainter(
          tile: tile,
          selected: selected,
          accent: accent,
        ),
      ),
    );
  }
}

class _RummiTilePainter extends CustomPainter {
  const _RummiTilePainter({
    required this.tile,
    required this.selected,
    required this.accent,
  });

  final Tile tile;
  final bool selected;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintRummikubTile(
      canvas,
      rect,
      tile,
      selected: selected,
      shadowElevation: selected ? 4 : 2.4,
    );

    if (!accent) return;
    final accentRect = rect.deflate(3.5);
    final rr = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF2C14E).withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _RummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
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

Set<String> _scoringCellSet(RummiPokerGridSession session) {
  final cells = <String>{};
  final lines = session.engine.listFullLines(session.board);
  for (final line in lines) {
    if (line.report.evaluation.isDeadLine) continue;
    final refs = line.ref.cells();
    for (final index in line.report.evaluation.contributingIndexes) {
      if (index < 0 || index >= refs.length) continue;
      final (row, col) = refs[index];
      cells.add('$row:$col');
    }
  }
  return cells;
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

String _lineRefShortLabel(LineRef ref) {
  return switch (ref.kind) {
    LineKind.row => '가로',
    LineKind.col => '세로',
    LineKind.diagMain => '대각↘',
    LineKind.diagAnti => '대각↙',
  };
}

String _localizedJesterName(BuildContext context, RummiJesterCard card) {
  final translations = JesterTranslationScope.of(context);
  return translations.resolveDisplayName(card.id, card.displayName);
}

String _localizedJesterEffect(BuildContext context, RummiJesterCard card) {
  final translations = JesterTranslationScope.of(context);
  return translations.resolveEffectText(card.id, card.effectText);
}

String _jesterCategoryLabel(RummiJesterCard card) {
  return switch (card.effectType) {
    'economy' => '경제형',
    'stateful_growth' => '상태형',
    'chips_bonus' || 'mult_bonus' || 'xmult_bonus' || 'other' => '점수형',
    _ => '기타',
  };
}

String? _jesterRuntimeValueText(
  RummiJesterCard card,
  RummiJesterRuntimeSnapshot snapshot, {
  required int slotIndex,
}) {
  final stateValue = snapshot.stateValueForSlot(slotIndex);
  final playedHandTotal = snapshot.playedHandCounts.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  return switch (card.id) {
    'green_jester' => '현재 ${_signedValueToken(stateValue, "Mult")}',
    'popcorn' => '현재 +$stateValue Mult',
    'ice_cream' => '현재 +$stateValue Chips',
    'supernova' => '누적 확정 $playedHandTotal회',
    'ride_the_bus' => '현재 ${_signedValueToken(stateValue, "Mult")}',
    _ => null,
  };
}

String _signedValueToken(int value, String suffix) {
  if (value >= 0) {
    return '+$value $suffix';
  }
  return '$value $suffix';
}

String? _settlementJesterNames(ConfirmedLineBreakdown line) {
  if (line.effects.isEmpty) return null;
  final names = <String>[];
  for (final effect in line.effects) {
    if (!names.contains(effect.displayName)) {
      names.add(effect.displayName);
    }
    if (names.length >= 2) break;
  }
  if (names.isEmpty) return null;
  return names.join(' · ');
}

String _jesterEffectBadge(RummiJesterEffectBreakdown effect) {
  final suffix = effect.displaySuffix;
  if (suffix.isEmpty) {
    return effect.displayToken;
  }
  return '${effect.displayToken} $suffix';
}
