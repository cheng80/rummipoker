import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../providers/features/rummi_poker_grid/game_session_state.dart';
import '../../../widgets/fx/fx_layer.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../game_presentation_timings.dart';
import 'game_ui_palette.dart';

part 'game_effect_overlay_layers.dart';
part 'game_effect_overlay_settlement_effect_layers.dart';

/// Flutter 보드 위에 얹는 정산 이펙트 레이어.
///
/// 좌표 변환과 발화만 담당한다. 파티클은 앱 전역 [FxLayer]가 그리며, save/continue 기준 상태는 보관하지 않는다.
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
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _scheduleBoardEffect(constraints);
          if (!_visible) return const SizedBox.expand();
          return RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                if (_lineSweepCenters.isNotEmpty &&
                    _showsSettlementEffectLinePulse(
                      widget.activeSettlementStep,
                    ))
                  _SettlementEffectLinePulseLayer(
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
            ),
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
      ScoringPresentationStep.jester ||
      ScoringPresentationStep.tile ||
      ScoringPresentationStep.item when line.effects.isNotEmpty =>
        _BoardEffectKind.lineConfirm,
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
          ? centers
          : const <Offset>[];
      final constraintImpactCenter =
          effectKind == _BoardEffectKind.constraintImpact
          ? _averageOffset(centers)
          : null;
      final constraintImpactCenters =
          effectKind == _BoardEffectKind.constraintImpact
          ? centers
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
      Fx.emit(context, switch (effectKind) {
        _BoardEffectKind.lineConfirm => FxPresets.lineConfirm,
        _BoardEffectKind.constraintImpact => FxPresets.constraintImpact,
        _BoardEffectKind.largeScore => FxPresets.largeScore,
      }, centers);
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

  List<Offset> _cellCentersForLine(
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
          Offset(
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

  Offset _averageOffset(List<Offset> centers) {
    var dx = 0.0;
    var dy = 0.0;
    for (final center in centers) {
      dx += center.dx;
      dy += center.dy;
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
