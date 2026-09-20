import 'package:flutter/material.dart';

import '../../../utils/app_translation.dart';
import '../../../logic/rummi_poker_grid/boss_modifier.dart';

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
    this.settlementGrade = 0,
    required this.frameInset,
    required this.gridGap,
  });

  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int settlementSequenceTick;

  /// 현재 줄의 점수 등급(0~3). 상위 2단계만 큰 점수 burst를 쓴다.
  final int settlementGrade;
  final double frameInset;
  final double gridGap;

  @override
  State<GameBoardEffectOverlay> createState() => _GameBoardEffectOverlayState();
}

class _GameBoardEffectOverlayState extends State<GameBoardEffectOverlay> {
  static const Duration _effectVisibleDuration =
      GamePresentationTimings.boardEffectVisible;
  static const int _largeScoreBurstGrade = 2;

  String? _lastEffectSignature;
  bool _visible = false;
  List<Offset> _scoreMoteCenters = const [];
  List<Offset> _lineSweepCenters = const [];
  List<Offset> _constraintImpactCenters = const [];
  Offset? _constraintImpactCenter;
  RummiConstraintPenaltyBreakdown? _constraintImpactPenalty;
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
                    _constraintImpactPenalty != null)
                  _ConstraintImpactBadgeLayer(
                    centers: _constraintImpactCenters,
                    center: _constraintImpactCenter!,
                    label: _constraintPenaltyLabel(_constraintImpactPenalty!),
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
          when widget.settlementGrade >= _largeScoreBurstGrade =>
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
      final constraintImpactPenalty =
          effectKind == _BoardEffectKind.constraintImpact
          ? line.constraintPenalties.first
          : null;
      if (scoreMoteCenters.isNotEmpty ||
          _scoreMoteCenters.isNotEmpty ||
          _lineSweepCenters.isNotEmpty ||
          constraintImpactCenters.isNotEmpty ||
          _constraintImpactCenters.isNotEmpty ||
          constraintImpactCenter != null ||
          _constraintImpactCenter != null) {
        setState(() {
          _scoreMoteCenters = scoreMoteCenters;
          _lineSweepCenters = scoreMoteCenters;
          _constraintImpactCenters = constraintImpactCenters;
          _constraintImpactCenter = constraintImpactCenter;
          _constraintImpactPenalty = constraintImpactPenalty;
          _scoreMoteTick = widget.settlementSequenceTick;
        });
      }
      // 큰 점수는 파티클만 낸다. 합계 `+점수`는 채점 줄을 피한 등급 callout이 보여 준다.
      Fx.emit(context, switch (effectKind) {
        // 타일 modifier와 Item은 Jester(금색)와 다른 색·모양으로 구분한다.
        _BoardEffectKind.lineConfirm
            when widget.activeSettlementStep == ScoringPresentationStep.tile =>
          FxPresets.sparks.copyWith(color: GameUiPalette.specialMint),
        _BoardEffectKind.lineConfirm
            when widget.activeSettlementStep == ScoringPresentationStep.item =>
          FxPresets.burst.copyWith(color: GameUiPalette.specialBlue),
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
          _constraintImpactPenalty = null;
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

  String _constraintPenaltyLabel(RummiConstraintPenaltyBreakdown penalty) {
    final marker = penalty.displayKeys == null
        ? penalty.markerText
        : context.translate(penalty.displayKeys!.markerTextKey);
    if (marker.isNotEmpty) return marker;
    return '${penalty.scoreDelta}';
  }
}

enum _BoardEffectKind { lineConfirm, constraintImpact, largeScore }
