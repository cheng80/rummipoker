import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummi_effect_game.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../providers/features/rummi_poker_grid/game_session_state.dart';

/// Flutter 보드 위에 얹는 투명 Flame 이펙트 레이어.
///
/// 좌표 변환과 파티클 발화만 담당하며, save/continue 기준 상태는 보관하지 않는다.
class GameBoardEffectOverlay extends StatefulWidget {
  const GameBoardEffectOverlay({
    super.key,
    required this.activeSettlementLine,
    required this.activeSettlementStep,
    required this.settlementSequenceTick,
    required this.frameInset,
    required this.gridGap,
  });

  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int settlementSequenceTick;
  final double frameInset;
  final double gridGap;

  @override
  State<GameBoardEffectOverlay> createState() => _GameBoardEffectOverlayState();
}

class _GameBoardEffectOverlayState extends State<GameBoardEffectOverlay> {
  static const Duration _effectVisibleDuration = Duration(milliseconds: 1050);
  static const int _largeScoreBurstThreshold = 100;

  late final RummiEffectGame _game;
  String? _lastEffectSignature;
  bool _visible = false;
  List<Offset> _scoreMoteCenters = const [];
  int _scoreMoteTick = 0;

  @override
  void initState() {
    super.initState();
    _game = RummiEffectGame();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _scheduleBoardEffect(constraints);
          if (!_visible) return const SizedBox.expand();
          return Stack(
            fit: StackFit.expand,
            children: [
              GameWidget<RummiEffectGame>(game: _game),
              if (_scoreMoteCenters.isNotEmpty)
                _SettlementScoreMoteLayer(
                  centers: _scoreMoteCenters,
                  tick: _scoreMoteTick,
                ),
            ],
          );
        },
      ),
    );
  }

  void _scheduleBoardEffect(BoxConstraints constraints) {
    final line = widget.activeSettlementLine;
    if (line == null) return;

    final effectKind = switch (widget.activeSettlementStep) {
      ScoringPresentationStep.boardLine => _BoardEffectKind.lineConfirm,
      ScoringPresentationStep.constraint
          when line.constraintPenalties.isNotEmpty =>
        _BoardEffectKind.constraintImpact,
      ScoringPresentationStep.finalScore
          when line.finalScore >= _largeScoreBurstThreshold =>
        _BoardEffectKind.largeScore,
      _ => null,
    };
    if (effectKind == null) return;

    final signature = [
      widget.settlementSequenceTick,
      effectKind.name,
      line.ref,
      line.contributingCells.join('|'),
      line.finalScore,
      if (effectKind == _BoardEffectKind.constraintImpact)
        line.constraintPenalties.map((penalty) => penalty.modifierId).join('|'),
    ].join('-');
    if (_lastEffectSignature == signature) return;
    _lastEffectSignature = signature;

    final centers = _cellCentersForLine(line, constraints);
    if (centers.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_visible) {
        setState(() => _visible = true);
      }
      final scoreMoteCenters = effectKind == _BoardEffectKind.lineConfirm
          ? [for (final center in centers) Offset(center.x, center.y)]
          : const <Offset>[];
      if (scoreMoteCenters.isNotEmpty || _scoreMoteCenters.isNotEmpty) {
        setState(() {
          _scoreMoteCenters = scoreMoteCenters;
          _scoreMoteTick = widget.settlementSequenceTick;
        });
      }
      switch (effectKind) {
        case _BoardEffectKind.lineConfirm:
          _game.spawnLineConfirmBurst(centers);
        case _BoardEffectKind.constraintImpact:
          _game.spawnConstraintImpactBurst(centers);
        case _BoardEffectKind.largeScore:
          _game.spawnLargeScoreBurst(centers);
      }
      Future<void>.delayed(_effectVisibleDuration, () {
        if (!mounted) return;
        if (_lastEffectSignature != signature) return;
        setState(() {
          _visible = false;
          _scoreMoteCenters = const [];
        });
      });
    });
  }

  List<Vector2> _cellCentersForLine(
    ConfirmedLineBreakdown line,
    BoxConstraints constraints,
  ) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return const [];
    }

    final boardSide = width < height ? width : height;
    final boardLeft = (width - boardSide) / 2;
    final boardTop = (height - boardSide) / 2;
    final innerSide = boardSide - widget.frameInset * 2;
    if (innerSide <= 0) return const [];

    final tileSide =
        (innerSide - widget.gridGap * (kBoardSize - 1)) / kBoardSize;
    if (tileSide <= 0) return const [];

    return [
      for (final (row, col) in line.contributingCells)
        if (row >= 0 && row < kBoardSize && col >= 0 && col < kBoardSize)
          Vector2(
            boardLeft +
                widget.frameInset +
                col * (tileSide + widget.gridGap) +
                tileSide / 2,
            boardTop +
                widget.frameInset +
                row * (tileSide + widget.gridGap) +
                tileSide / 2,
          ),
    ];
  }
}

enum _BoardEffectKind { lineConfirm, constraintImpact, largeScore }

class _SettlementScoreMoteLayer extends StatelessWidget {
  const _SettlementScoreMoteLayer({required this.centers, required this.tick});

  final List<Offset> centers;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('settlement-score-mote-layer'),
      builder: (context, constraints) {
        final target = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight * 0.12,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < centers.length; i++)
              _SettlementScoreMote(
                key: ValueKey<String>('settlement-score-mote-$tick-$i'),
                start: centers[i],
                target: target,
                delay: Duration(milliseconds: i * 34),
              ),
          ],
        );
      },
    );
  }
}

class _SettlementScoreMote extends StatelessWidget {
  const _SettlementScoreMote({
    super.key,
    required this.start,
    required this.target,
    required this.delay,
  });

  final Offset start;
  final Offset target;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio = delay.inMilliseconds / 620;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final position = Offset.lerp(start, target, value)!;
        final opacity = value < 0.82 ? 1.0 : 1.0 - ((value - 0.82) / 0.18);
        final scale = 1.0 - (value * 0.22);
        return Positioned(
          left: position.dx - 4,
          top: position.dy - 4,
          width: 8,
          height: 8,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF2C14E).withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF2C14E).withValues(alpha: 0.42),
                      blurRadius: 9,
                      spreadRadius: 1,
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
}
