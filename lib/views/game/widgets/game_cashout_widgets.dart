import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/line_ref.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../providers/features/rummi_poker_grid/game_session_state.dart';
import '../../../resources/jester_translation_scope.dart';
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
        ),
      ),
    );
  }
}

class GameFloatingSettlementBurst extends StatelessWidget {
  const GameFloatingSettlementBurst({super.key, required this.line});

  final ConfirmedLineBreakdown? line;

  @override
  Widget build(BuildContext context) {
    final currentLine = line;
    final label = currentLine == null
        ? '점수 정산'
        : '${gameHandRankLabel(currentLine.rank)} · ${gameLineRefShortLabel(currentLine.ref)}';
    final subLabel = currentLine == null
        ? null
        : gameScoreBreakdownLabel(currentLine);
    final displayedScore = currentLine?.finalScore ?? 0;
    final jesterLabel = currentLine == null
        ? null
        : settlementJesterNames(currentLine);

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

class GameCashOutSheet extends StatefulWidget {
  const GameCashOutSheet({
    super.key,
    required this.breakdown,
    required this.currentGold,
  });

  final RummiCashOutBreakdown breakdown;
  final int currentGold;

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
                  child: _GameCashOutLine(
                    leading: 'Station ${b.stageIndex}',
                    text: 'Station Goal ${b.targetScore} 달성 보상',
                    gold: b.blindReward,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _step >= 2 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _GameCashOutLine(
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
                  child: _GameCashOutLine(
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
                          _GameCashOutLine(
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
                  opacity: _step >= (b.economyBonuses.isNotEmpty ? 5 : 4)
                      ? 1
                      : 0,
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
                    'Market으로',
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

class _GameCashOutLine extends StatelessWidget {
  const _GameCashOutLine({
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
