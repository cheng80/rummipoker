import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_settlement_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/line_ref.dart';
import '../../../providers/features/rummi_poker_grid/game_session_state.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/jester_translation_scope.dart';
import '../../../utils/common_ui.dart';
import 'game_jester_widgets.dart';

String gameHandRankLabel(RummiHandRank rank) {
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

String gameScoreBreakdownLabel(ConfirmedLineBreakdown line) {
  final parts = <String>['기본 ${line.rankBaseScore ?? line.baseScore}'];
  if (line.overlapBonus > 0) {
    parts.add('겹침 +${line.overlapBonus}');
  }
  if (line.jesterBonus > 0) {
    parts.add('제스터 +${line.jesterBonus}');
  }
  return parts.join(' · ');
}

String gameLineRefShortLabel(LineRef ref) {
  return switch (ref.kind) {
    LineKind.row => '가로',
    LineKind.col => '세로',
    LineKind.diagMain => '대각↘',
    LineKind.diagAnti => '대각↙',
  };
}

class GameStageClearOverlay extends StatelessWidget {
  const GameStageClearOverlay({
    super.key,
    required this.phase,
    required this.stageIndex,
    required this.scoreAdded,
  });

  final GameStageFlowPhase phase;
  final int stageIndex;
  final int scoreAdded;

  @override
  Widget build(BuildContext context) {
    final isSettlement = phase == GameStageFlowPhase.settlement;
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isSettlement) const _StageClearSparkField(),
              Container(
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
                      isSettlement ? 'SCORE SETTLED' : 'STATION CLEAR',
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
                      'Station $stageIndex',
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
                        'Station Goal 달성',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StageClearSparkField extends StatelessWidget {
  const _StageClearSparkField();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('stage-clear-spark-field'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: (1 - value).clamp(0.0, 1.0),
          child: CustomPaint(
            painter: _StageClearSparkPainter(progress: value),
            size: const Size(260, 150),
          ),
        );
      },
    );
  }
}

class _StageClearSparkPainter extends CustomPainter {
  const _StageClearSparkPainter({required this.progress});

  final double progress;

  static const List<Offset> _origins = [
    Offset(-90, -44),
    Offset(-54, 38),
    Offset(58, -42),
    Offset(94, 32),
    Offset(0, -64),
    Offset(10, 54),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < _origins.length; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final origin = center + _origins[i];
      final travel = 20.0 + 8.0 * (i % 2);
      final sparkCenter =
          origin + Offset(math.cos(angle), math.sin(angle)) * travel * progress;
      final arm = 5.0 + 2.0 * (1 - progress);
      paint
        ..color = const Color(
          0xFFF2C14E,
        ).withValues(alpha: 0.82 * (1 - progress))
        ..strokeWidth = 2.2 * (1 - progress * 0.45);
      canvas.drawLine(
        sparkCenter.translate(-arm, 0),
        sparkCenter.translate(arm, 0),
        paint,
      );
      canvas.drawLine(
        sparkCenter.translate(0, -arm),
        sparkCenter.translate(0, arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageClearSparkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class GameFloatingSettlementBurst extends StatelessWidget {
  const GameFloatingSettlementBurst({
    super.key,
    required this.line,
    required this.step,
    required this.effectIndex,
  });

  final ConfirmedLineBreakdown? line;
  final ScoringPresentationStep step;
  final int? effectIndex;

  @override
  Widget build(BuildContext context) {
    final currentLine = line;
    final activeEffect =
        currentLine != null &&
            effectIndex != null &&
            effectIndex! >= 0 &&
            effectIndex! < currentLine.effects.length
        ? currentLine.effects[effectIndex!]
        : null;
    final label = _settlementStepLabel(currentLine, step, activeEffect);
    final subLabel = _settlementStepSubLabel(currentLine, step, activeEffect);
    final displayedScore = _settlementStepScore(
      currentLine,
      step,
      activeEffect,
    );

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final opacity = (value / 0.65).clamp(0.0, 1.0);
          final dy = lerpDouble(10, 0, value)!;
          final scale = lerpDouble(0.96, 1, value)!;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scale: scale, child: child),
            ),
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
                  _GameOutlinedLabel(
                    label,
                    textAlign: TextAlign.center,
                    fillColor: Colors.white.withValues(alpha: 0.96),
                    strokeColor: Colors.black.withValues(alpha: 0.82),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                  const SizedBox(height: 6),
                  _GameOutlinedLabel(
                    '+$displayedScore',
                    fillColor: const Color(0xFFF2C14E),
                    strokeColor: Colors.black.withValues(alpha: 0.88),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    _GameOutlinedLabel(
                      subLabel,
                      textAlign: TextAlign.center,
                      fillColor: Colors.white.withValues(alpha: 0.78),
                      strokeColor: Colors.black.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

String _settlementStepLabel(
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return '점수 정산';
  return switch (step) {
    ScoringPresentationStep.boardLine =>
      '${gameLineRefShortLabel(line.ref)} 라인',
    ScoringPresentationStep.handRank => gameHandRankLabel(line.rank),
    ScoringPresentationStep.overlap => 'overlap bonus',
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? '제약 적용'
          : line.constraintPenalties.first.title,
    ScoringPresentationStep.jester => effect?.displayName ?? 'Jester 발동',
    ScoringPresentationStep.item => effect?.displayName ?? 'Item 발동',
    ScoringPresentationStep.finalScore => 'Station Goal',
    ScoringPresentationStep.none =>
      '${gameHandRankLabel(line.rank)} · ${gameLineRefShortLabel(line.ref)}',
  };
}

String? _settlementStepSubLabel(
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return null;
  return switch (step) {
    ScoringPresentationStep.boardLine => '보드 라인 확정',
    ScoringPresentationStep.handRank =>
      'base ${line.rankBaseScore ?? line.baseScore}',
    ScoringPresentationStep.overlap => '겹침 +${line.overlapBonus}',
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? null
          : line.constraintPenalties.first.ruleText,
    ScoringPresentationStep.jester || ScoringPresentationStep.item =>
      effect == null ? null : jesterEffectBadge(effect),
    ScoringPresentationStep.finalScore => gameScoreBreakdownLabel(line),
    ScoringPresentationStep.none => gameScoreBreakdownLabel(line),
  };
}

int _settlementStepScore(
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return 0;
  return switch (step) {
    ScoringPresentationStep.boardLine => 0,
    ScoringPresentationStep.handRank => line.rankBaseScore ?? line.baseScore,
    ScoringPresentationStep.overlap => line.overlapBonus,
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? 0
          : line.constraintPenalties.first.scoreDelta,
    ScoringPresentationStep.jester ||
    ScoringPresentationStep.item => effect?.scoreDelta ?? 0,
    ScoringPresentationStep.finalScore ||
    ScoringPresentationStep.none => line.finalScore,
  };
}

class GameCashOutSheet extends StatefulWidget {
  const GameCashOutSheet({
    super.key,
    required this.settlement,
    this.autoEnterMarketOnLoad = false,
  });

  final RummiSettlementRuntimeFacade settlement;
  final bool autoEnterMarketOnLoad;

  @override
  State<GameCashOutSheet> createState() => _GameCashOutSheetState();
}

class _GameCashOutSheetState extends State<GameCashOutSheet> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _runSteps();
  }

  Future<void> _runSteps() async {
    final stepDelay = widget.autoEnterMarketOnLoad
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 260);
    final initialDelay = widget.autoEnterMarketOnLoad
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 220);
    final autoAdvanceDelay = widget.autoEnterMarketOnLoad
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 300);

    await Future<void>.delayed(initialDelay);
    if (!mounted) return;
    setState(() => _step = 1);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _step = 2);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _step = 3);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _step = 4);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _step = 5);
    if (widget.autoEnterMarketOnLoad) {
      await Future<void>.delayed(autoAdvanceDelay);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final hasBonuses = settlement.entries.any((e) => e.isBonus);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          key: const ValueKey('cashout-sheet-frame'),
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
                _GameCashOutReveal(
                  visible: _step >= 1,
                  child: _GameCashOutLine.fromSettlementEntry(
                    settlement.entries[0],
                  ),
                ),
                const SizedBox(height: 8),
                _GameCashOutReveal(
                  visible: _step >= 2,
                  child: _GameCashOutLine.fromSettlementEntry(
                    settlement.entries[1],
                  ),
                ),
                const SizedBox(height: 8),
                _GameCashOutReveal(
                  visible: _step >= 3,
                  child: _GameCashOutLine.fromSettlementEntry(
                    settlement.entries[2],
                  ),
                ),
                if (hasBonuses) ...[
                  const SizedBox(height: 8),
                  _GameCashOutReveal(
                    visible: _step >= 4,
                    child: Column(
                      children: [
                        for (final entry in settlement.entries.where(
                          (entry) => entry.isBonus,
                        )) ...[
                          _GameCashOutLine(
                            leading: entry.leadingLabel,
                            text: _bonusEntryDescription(context, entry),
                            gold: entry.gold,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _GameCashOutReveal(
                  visible: _step >= (hasBonuses ? 5 : 4),
                  child: _GameCashOutGoldSummary(
                    currentGold: settlement.currentGold,
                    totalGold: settlement.totalGold,
                  ),
                ),
                const SizedBox(height: 14),
                GameChromeButton(
                  label: 'Market으로',
                  backgroundColor: const Color(0xFFF4A81D),
                  foregroundColor: Colors.black,
                  height: 52,
                  borderRadius: 18,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  onPressed: _step < 3
                      ? null
                      : () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCashOutGoldSummary extends StatelessWidget {
  const _GameCashOutGoldSummary({
    required this.currentGold,
    required this.totalGold,
  });

  final int currentGold;
  final int totalGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF2C14E).withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _GameCashOutGoldMetric(
              label: '보유 골드',
              value: '${currentGold}G',
              valueKey: const ValueKey('cashout-current-gold-value'),
              valueStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _GameCashOutGoldMetric(
            label: '총 획득',
            value: '+${totalGold}G',
            valueKey: const ValueKey('cashout-total-gold-value'),
            alignEnd: true,
            valueStyle: const TextStyle(
              color: Color(0xFFF2C14E),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutGoldMetric extends StatelessWidget {
  const _GameCashOutGoldMetric({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.valueStyle,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final TextStyle valueStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(value, key: valueKey, style: valueStyle),
      ],
    );
  }
}

String _bonusEntryDescription(
  BuildContext context,
  RummiSettlementEntryView entry,
) {
  final displayName = entry.displayName ?? '';
  final jesterId = entry.jesterId;
  if (jesterId != null) {
    return '${JesterTranslationScope.of(context).resolveDisplayName(jesterId, displayName)} 보너스';
  }
  final itemId = entry.itemId;
  if (itemId != null) {
    return '${ItemTranslationScope.of(context).resolveDisplayName(itemId, displayName)} 보너스';
  }
  return entry.description;
}

class _GameCashOutReveal extends StatelessWidget {
  const _GameCashOutReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

class _GameCashOutLine extends StatelessWidget {
  const _GameCashOutLine({
    required this.leading,
    required this.text,
    required this.gold,
  });

  factory _GameCashOutLine.fromSettlementEntry(RummiSettlementEntryView entry) {
    return _GameCashOutLine(
      leading: entry.leadingLabel,
      text: entry.description,
      gold: entry.gold,
    );
  }

  final String leading;
  final String text;
  final int gold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-line-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = (1 - value).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF2C14E).withValues(alpha: 0.18 * pulse),
                blurRadius: 18 * pulse,
                spreadRadius: 1.5 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
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
            _GameCashOutCollectBadge(gold: gold),
          ],
        ),
      ),
    );
  }
}

class _GameCashOutCollectBadge extends StatelessWidget {
  const _GameCashOutCollectBadge({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-collect-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final scale = lerpDouble(0.94, 1, value)!;
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _GameCashOutCoinBurst()),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2311),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF2C14E), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                '+$gold',
                style: const TextStyle(
                  color: Color(0xFFF2C14E),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutCoinBurst extends StatelessWidget {
  const _GameCashOutCoinBurst();

  static const List<Offset> _targets = [
    Offset(-18, -16),
    Offset(0, -22),
    Offset(18, -14),
    Offset(24, 4),
  ];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-coin-burst'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _targets.length; i++)
              Positioned(
                left: 18 + _targets[i].dx * value,
                top:
                    10 + _targets[i].dy * value + math.sin(value * math.pi) * 4,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.78 + 0.22 * (1 - value),
                    child: const _GameCashOutCoinSpark(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GameCashOutCoinSpark extends StatelessWidget {
  const _GameCashOutCoinSpark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2C14E),
        border: Border.all(color: const Color(0xFFFFE8A2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2C14E).withValues(alpha: 0.32),
            blurRadius: 6,
          ),
        ],
      ),
      child: const SizedBox.square(dimension: 7),
    );
  }
}

class _GameOutlinedLabel extends StatelessWidget {
  const _GameOutlinedLabel(
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
