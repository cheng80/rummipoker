import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/sound_manager.dart';

const double kGameTileAspectRatio = 1.0;
const double kBoardFrameInset = 10.0;
const double kBoardGridGap = 1.5;
const double kBoardTileInnerPadding = 2.0;

const TextStyle gameHudLabelStyle = TextStyle(
  color: Colors.white70,
  fontSize: 9,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.35,
);

final TextStyle gameHudValueStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.96),
  fontWeight: FontWeight.w900,
  height: 1,
);

const TextStyle gameHudSubStyle = TextStyle(
  color: Colors.white70,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

/// 보드 가로 폭 기준 실제 카드 렌더 폭을 계산한다.
double boardTileVisualWidth(double boardSide) {
  final gridSide = boardSide - (kBoardFrameInset * 2);
  final cellSide = (gridSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
  return cellSide - (kBoardTileInnerPadding * 2);
}

/// 확정 가능한 족보 줄에 실제 기여하는 셀만 강조 대상으로 반환한다.
Set<String> scoringCellSet(RummiPokerGridSession session) {
  final cells = <String>{};
  final lines = session.engine.listEvaluatedLines(session.board);
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

class GameTopHud extends StatelessWidget {
  const GameTopHud({
    super.key,
    required this.session,
    required this.runProgress,
    required this.onOptionsTap,
  });

  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final blind = session.blind;
    final progress = blind.targetScore <= 0
        ? 0.0
        : (blind.scoreTowardBlind / blind.targetScore).clamp(0.0, 1.0);

    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: GameHudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATION',
                    style: gameHudLabelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${runProgress.stageIndex}',
                          maxLines: 1,
                          style: gameHudValueStyle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '보상 +${RummiRunProgress.stageClearGoldBase}',
                    style: gameHudSubStyle,
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
            child: GameHudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'STATION GOAL',
                          style: gameHudLabelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${blind.scoreTowardBlind} / ${blind.targetScore}',
                          maxLines: 1,
                          style: gameHudValueStyle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
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
            child: GameHudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'GOLD',
                          style: gameHudLabelStyle,
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
                          style: gameHudValueStyle.copyWith(fontSize: 22),
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

class GameBottomInfoRow extends StatelessWidget {
  const GameBottomInfoRow({super.key, required this.session});

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
              fontSize: 9,
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
              fontSize: 9,
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
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class GameDebugShopHandCluster extends StatelessWidget {
  const GameDebugShopHandCluster({
    super.key,
    required this.onShopTap,
    required this.handSize,
    required this.onHandSizeChanged,
  });

  final VoidCallback onShopTap;
  final int handSize;
  final ValueChanged<int> onHandSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DEBUG',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                GestureDetector(
                  onTap: onShopTap,
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
                      'MARKET',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GameDebugHandSizeSegment(
                  value: handSize,
                  onChanged: onHandSizeChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameDebugHandSizeSegment extends StatelessWidget {
  const GameDebugHandSizeSegment({
    super.key,
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

class GameHudChip extends StatelessWidget {
  const GameHudChip({super.key, required this.child});

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

class GameBoardGrid extends StatelessWidget {
  const GameBoardGrid({
    super.key,
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
                padding: const EdgeInsets.all(kBoardFrameInset),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kBoardSize,
                    mainAxisSpacing: kBoardGridGap,
                    crossAxisSpacing: kBoardGridGap,
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
                    return GameBoardCell(
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

class GameBoardCell extends StatelessWidget {
  const GameBoardCell({
    super.key,
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
                      child: GameRummiTileCard(
                        tile: tile!,
                        selected: selected,
                        accent: false,
                        aspectRatio: kGameTileAspectRatio,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.onPressed,
    this.foreground = Colors.white,
    this.compact = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 34 : 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 4 : 7,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
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
        painter: _GameRummiTilePainter(
          tile: tile,
          selected: selected,
          accent: accent,
        ),
      ),
    );
  }
}

class _GameRummiTilePainter extends CustomPainter {
  const _GameRummiTilePainter({
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
  bool shouldRepaint(covariant _GameRummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
}

/// 게임·상점 화면 공통 테이블 배경. 정적이므로 repaint 없음.
class GameTableBackdrop extends StatelessWidget {
  const GameTableBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GameTableBackdropPainter());
  }
}

class _GameTableBackdropPainter extends CustomPainter {
  const _GameTableBackdropPainter();

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

/// 게임·상점 다이얼로그 공통 카드 컨테이너.
class GameModalCard extends StatelessWidget {
  const GameModalCard({super.key, required this.child});

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

/// 게임·상점 다이얼로그를 표시한다. barrierDismissible 기본 true.
Future<T?> showGameFramedDialog<T>({
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

String expirySignalLabel(RummiExpirySignal signal) {
  return switch (signal) {
    RummiExpirySignal.boardFullAfterDcExhausted =>
      '버림이 모두 소진된 상태에서 보드 25칸이 가득 찼습니다.',
    RummiExpirySignal.drawPileExhausted =>
      '드로우 덱이 소진되었고 더 이상 사용할 손패나 확정할 줄이 없습니다.',
  };
}

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetry]는 현재 스테이지 시작 스냅샷으로 즉시 복원한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required Future<void> Function() onRetry,
  required Future<void> Function() onExit,
}) {
  final text =
      '${signals.map(expirySignalLabel).join('\n')}\n\n'
      '현재 스테이지 시작 상태로 다시 시도하거나 종료할 수 있습니다.';
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
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
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onRetry();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A81D),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('다시하기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onExit();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5D6B68),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(context.tr('exit')),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
