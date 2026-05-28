import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummi_effect_game.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../providers/features/rummi_poker_grid/game_session_state.dart';
import '../game_presentation_timings.dart';
import 'game_ui_palette.dart';

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
  static const Duration _effectVisibleDuration =
      GamePresentationTimings.boardEffectVisible;
  static const int _largeScoreBurstThreshold = 100;

  late final RummiEffectGame _game;
  String? _lastEffectSignature;
  bool _visible = false;
  List<Offset> _scoreMoteCenters = const [];
  List<Offset> _lineSweepCenters = const [];
  List<Offset> _constraintImpactCenters = const [];
  Offset? _constraintImpactCenter;
  String? _constraintImpactLabel;
  Offset? _largeScoreCenter;
  String? _largeScoreLabel;
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
              if (_lineSweepCenters.isNotEmpty)
                _LineConfirmSweepLayer(
                  centers: _lineSweepCenters,
                  tick: _scoreMoteTick,
                ),
              if (_constraintImpactCenter != null &&
                  _constraintImpactLabel != null)
                _ConstraintImpactBadgeLayer(
                  centers: _constraintImpactCenters,
                  center: _constraintImpactCenter!,
                  label: _constraintImpactLabel!,
                  tick: _scoreMoteTick,
                ),
              if (_largeScoreCenter != null && _largeScoreLabel != null)
                _LargeScoreBurstBadgeLayer(
                  center: _largeScoreCenter!,
                  label: _largeScoreLabel!,
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
      final constraintImpactCenter =
          effectKind == _BoardEffectKind.constraintImpact
          ? _averageOffset(centers)
          : null;
      final constraintImpactCenters =
          effectKind == _BoardEffectKind.constraintImpact
          ? [for (final center in centers) Offset(center.x, center.y)]
          : const <Offset>[];
      final constraintImpactLabel =
          effectKind == _BoardEffectKind.constraintImpact
          ? _constraintPenaltyLabel(line)
          : null;
      final largeScoreCenter = effectKind == _BoardEffectKind.largeScore
          ? _averageOffset(centers)
          : null;
      final largeScoreLabel = effectKind == _BoardEffectKind.largeScore
          ? '+${line.finalScore}'
          : null;
      if (scoreMoteCenters.isNotEmpty ||
          _scoreMoteCenters.isNotEmpty ||
          _lineSweepCenters.isNotEmpty ||
          constraintImpactCenters.isNotEmpty ||
          _constraintImpactCenters.isNotEmpty ||
          constraintImpactCenter != null ||
          _constraintImpactCenter != null ||
          largeScoreCenter != null ||
          _largeScoreCenter != null) {
        setState(() {
          _scoreMoteCenters = scoreMoteCenters;
          _lineSweepCenters = scoreMoteCenters;
          _constraintImpactCenters = constraintImpactCenters;
          _constraintImpactCenter = constraintImpactCenter;
          _constraintImpactLabel = constraintImpactLabel;
          _largeScoreCenter = largeScoreCenter;
          _largeScoreLabel = largeScoreLabel;
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
          _lineSweepCenters = const [];
          _constraintImpactCenters = const [];
          _constraintImpactCenter = null;
          _constraintImpactLabel = null;
          _largeScoreCenter = null;
          _largeScoreLabel = null;
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

  Offset _averageOffset(List<Vector2> centers) {
    var dx = 0.0;
    var dy = 0.0;
    for (final center in centers) {
      dx += center.x;
      dy += center.y;
    }
    return Offset(dx / centers.length, dy / centers.length);
  }

  String _constraintPenaltyLabel(ConfirmedLineBreakdown line) {
    final penalty = line.constraintPenalties.first;
    if (penalty.markerText.isNotEmpty) return penalty.markerText;
    return '${penalty.scoreDelta}';
  }
}

enum _BoardEffectKind { lineConfirm, constraintImpact, largeScore }

class _LineConfirmSweepLayer extends StatelessWidget {
  const _LineConfirmSweepLayer({required this.centers, required this.tick});

  final List<Offset> centers;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('line-confirm-sweep-layer'),
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < centers.length; i++)
          _LineConfirmSweepCell(
            key: ValueKey<String>('line-confirm-sweep-$tick-$i'),
            center: centers[i],
            delay: GamePresentationCues.lineConfirmSweep.delayFor(i),
          ),
      ],
    );
  }
}

class _LineConfirmSweepCell extends StatelessWidget {
  const _LineConfirmSweepCell({
    super.key,
    required this.center,
    required this.delay,
  });

  final Offset center;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationCues.lineConfirmSweep.duration,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.lineConfirmSweep.duration.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final opacity = value < 0.72 ? 1.0 : 1.0 - ((value - 0.72) / 0.28);
        return Positioned(
          left: center.dx - 18,
          top: center.dy - 18,
          width: 36,
          height: 36,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.72 + (value * 0.34),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: GameUiPalette.actionGoldBright.withValues(
                      alpha: 0.86,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.actionGoldBright.withValues(
                        alpha: 0.34,
                      ),
                      blurRadius: 14,
                      spreadRadius: 1.2,
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

class _ConstraintImpactBadgeLayer extends StatelessWidget {
  const _ConstraintImpactBadgeLayer({
    required this.centers,
    required this.center,
    required this.label,
    required this.tick,
  });

  final List<Offset> centers;
  final Offset center;
  final String label;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('constraint-impact-badge-layer'),
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < centers.length; i++)
          _ConstraintImpactCellFlash(
            key: ValueKey<String>('constraint-impact-cell-$tick-$i'),
            center: centers[i],
            delay: GamePresentationCues.constraintCellFlash.delayFor(i),
          ),
        _ConstraintImpactBadge(
          key: ValueKey<String>('constraint-impact-badge-$tick'),
          center: center,
          label: label,
        ),
      ],
    );
  }
}

class _ConstraintImpactCellFlash extends StatelessWidget {
  const _ConstraintImpactCellFlash({
    super.key,
    required this.center,
    required this.delay,
  });

  final Offset center;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationCues.constraintCellFlash.duration,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.constraintCellFlash.duration.inMilliseconds;
        final value = ((rawValue - delayRatio) / (1 - delayRatio)).clamp(
          0.0,
          1.0,
        );
        final opacity = value < 0.72 ? 1.0 : 1.0 - ((value - 0.72) / 0.28);
        final scale = 0.72 + value * 0.42;
        return Positioned(
          left: center.dx - 20,
          top: center.dy - 20,
          width: 40,
          height: 40,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.specialDangerEffect.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: GameUiPalette.specialDangerEffectBorder.withValues(
                      alpha: 0.9,
                    ),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.specialDangerEffect.withValues(
                        alpha: 0.34,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
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

class _ConstraintImpactBadge extends StatelessWidget {
  const _ConstraintImpactBadge({
    super.key,
    required this.center,
    required this.label,
  });

  final Offset center;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.constraintImpactBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.84 ? 1.0 : 1.0 - ((value - 0.84) / 0.16);
        final dy = -12 * value;
        final scale = 0.78 + (value * 0.26);
        return Positioned(
          left: center.dx - 42,
          top: center.dy - 25 + dy,
          width: 84,
          height: 38,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.surfaceDangerDeep.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: GameUiPalette.specialDangerEffectBorder.withValues(
                      alpha: 0.95,
                    ),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.specialDangerEffectBorder.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BOSS',
                      style: TextStyle(
                        color: GameUiPalette.specialDangerSoft,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: GameUiPalette.specialDangerWarm,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
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
}

class _LargeScoreBurstBadgeLayer extends StatelessWidget {
  const _LargeScoreBurstBadgeLayer({
    required this.center,
    required this.label,
    required this.tick,
  });

  final Offset center;
  final String label;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('large-score-burst-badge-layer'),
      fit: StackFit.expand,
      children: [
        _LargeScoreBurstBadge(
          key: ValueKey<String>('large-score-burst-badge-$tick'),
          center: center,
          label: label,
        ),
      ],
    );
  }
}

class _LargeScoreBurstBadge extends StatelessWidget {
  const _LargeScoreBurstBadge({
    super.key,
    required this.center,
    required this.label,
  });

  final Offset center;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.largeScoreBurstBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.76 ? 1.0 : 1.0 - ((value - 0.76) / 0.24);
        final dy = -16 * value;
        final scale = 0.78 + (value * 0.32);
        return Positioned(
          left: center.dx - 42,
          top: center.dy - 24 + dy,
          width: 84,
          height: 38,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.stationClearSurface.withValues(
                    alpha: 0.94,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GameUiPalette.settlementActive.withValues(
                      alpha: 0.95,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.settlementActive.withValues(
                        alpha: 0.36,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1.4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: GameUiPalette.specialSuccessText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
                delay: GamePresentationCues.settlementScoreMote.delayFor(i),
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
      duration: GamePresentationCues.settlementScoreMote.duration,
      curve: Curves.easeOutCubic,
      builder: (context, rawValue, child) {
        final delayRatio =
            delay.inMilliseconds /
            GamePresentationCues.settlementScoreMote.duration.inMilliseconds;
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
                  color: GameUiPalette.actionGoldBright.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.actionGoldBright.withValues(
                        alpha: 0.42,
                      ),
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
