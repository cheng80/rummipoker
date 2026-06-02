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
import '../game_presentation_timings.dart';
import 'game_jester_widgets.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

part 'game_cashout_presentation_widgets.dart';
part 'game_cashout_sheet_widgets.dart';

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
    RummiHandRank.prismStraight => '프리즘 스트레이트',
    RummiHandRank.crownFourOfAKind => '크라운 포카드',
    RummiHandRank.lowStraightFlush => '로우 스티플',
    RummiHandRank.royalStraightFlush => '로열 스티플',
    RummiHandRank.fiveOfAKind => '파이브 카드',
    RummiHandRank.flushHouse => '플러시 하우스',
    RummiHandRank.flushFive => '플러시 파이브',
  };
}

String gameScoreBreakdownLabel(ConfirmedLineBreakdown line) {
  final parts = <String>['칩 ${line.rankBaseScore ?? line.baseScore}'];
  if (line.growthBonus > 0) {
    parts.add('성장 칩 +${line.growthBonus}');
  }
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

class GameCashOutSheet extends StatefulWidget {
  const GameCashOutSheet({
    super.key,
    required this.settlement,
    this.autoEnterMarketOnLoad = false,
    this.completesRun = false,
    this.insightReward = 0,
    this.showsChallengeCarryoverNotice = false,
  });

  final RummiSettlementRuntimeFacade settlement;
  final bool autoEnterMarketOnLoad;
  final bool completesRun;
  final int insightReward;
  final bool showsChallengeCarryoverNotice;

  @override
  State<GameCashOutSheet> createState() => _GameCashOutSheetState();
}

enum GameCashOutAction { enterMarket, completeRun, continueEndless }

class _GameCashOutSheetState extends State<GameCashOutSheet> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _runSteps();
  }

  Future<void> _runSteps() async {
    final stepDelay = widget.autoEnterMarketOnLoad
        ? GamePresentationTimings.cashOutAutoStepDelay
        : GamePresentationTimings.cashOutStepDelay;
    final initialDelay = widget.autoEnterMarketOnLoad
        ? GamePresentationTimings.cashOutAutoInitialDelay
        : GamePresentationTimings.cashOutInitialDelay;
    final autoAdvanceDelay = widget.autoEnterMarketOnLoad
        ? GamePresentationTimings.cashOutAutoAdvanceDelay
        : GamePresentationTimings.cashOutAdvanceDelay;

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
    if (widget.autoEnterMarketOnLoad && !widget.completesRun) {
      await Future<void>.delayed(autoAdvanceDelay);
      if (!mounted) return;
      _closeWith(GameCashOutAction.enterMarket);
    }
  }

  void _closeWith(GameCashOutAction action) {
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final hasBonuses = settlement.entries.any((e) => e.isBonus);
    final deckRewardEntries = settlement.entries
        .where((entry) => entry.isDeckTileReward)
        .toList(growable: false);
    final hasDeckRewards = deckRewardEntries.isNotEmpty;
    final finalStepVisible = _step >= (hasBonuses || hasDeckRewards ? 5 : 4);
    // 상위 라우트/오버레이의 텍스트 장식이 정산 UI로 새어 들어오지 않게 막는다.
    final baseTextStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(decoration: TextDecoration.none);
    return DefaultTextStyle(
      style: baseTextStyle,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (constraints.maxHeight - 12).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: DecoratedBox(
                  key: const ValueKey('cashout-sheet-frame'),
                  decoration: BoxDecoration(
                    color: GameUiPalette.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
                    ),
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
                            color: GameUiPalette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: SingleChildScrollView(
                            key: const ValueKey('cashout-sheet-scroll-body'),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _GameCashOutReveal(
                                  visible: _step >= 1,
                                  child: _GameCashOutLine.fromSettlementEntry(
                                    settlement.entries[0],
                                    isEndless: settlement.isEndless,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _GameCashOutReveal(
                                  visible: _step >= 2,
                                  child: _GameCashOutLine.fromSettlementEntry(
                                    settlement.entries[1],
                                    isEndless: settlement.isEndless,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _GameCashOutReveal(
                                  visible: _step >= 3,
                                  child: _GameCashOutLine.fromSettlementEntry(
                                    settlement.entries[2],
                                    isEndless: settlement.isEndless,
                                  ),
                                ),
                                if (hasBonuses) ...[
                                  const SizedBox(height: 8),
                                  _GameCashOutReveal(
                                    visible: _step >= 4,
                                    child: Column(
                                      children: [
                                        for (final entry
                                            in settlement.entries.where(
                                              (entry) => entry.isBonus,
                                            )) ...[
                                          _GameCashOutLine(
                                            leading: entry.leadingLabel,
                                            text: _bonusEntryDescription(
                                              context,
                                              entry,
                                            ),
                                            gold: entry.gold,
                                            isEndless: settlement.isEndless,
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                if (hasDeckRewards) ...[
                                  const SizedBox(height: 8),
                                  _GameCashOutReveal(
                                    visible: _step >= (hasBonuses ? 5 : 4),
                                    child: Column(
                                      children: [
                                        for (final entry
                                            in deckRewardEntries) ...[
                                          _GameCashOutTileRewardLine(
                                            entry: entry,
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _GameCashOutReveal(
                                  visible: finalStepVisible,
                                  child: _GameCashOutGoldSummary(
                                    currentGold: settlement.currentGold,
                                    totalGold: settlement.totalGold,
                                  ),
                                ),
                                if (widget.completesRun &&
                                    widget.insightReward > 0) ...[
                                  const SizedBox(height: 12),
                                  _GameCashOutReveal(
                                    visible: finalStepVisible,
                                    child: GameOverInsightRewardCard(
                                      insightReward: widget.insightReward,
                                    ),
                                  ),
                                ],
                                if (widget.completesRun) ...[
                                  const SizedBox(height: 10),
                                  _GameCashOutReveal(
                                    visible: finalStepVisible,
                                    child: const _GameCashOutEndlessNotice(),
                                  ),
                                ],
                                if (widget.showsChallengeCarryoverNotice) ...[
                                  const SizedBox(height: 10),
                                  _GameCashOutReveal(
                                    visible: finalStepVisible,
                                    child:
                                        const _GameCashOutChallengeCarryoverNotice(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (widget.completesRun) ...[
                          GameChromeButton(
                            label: '무한 도전 진입',
                            backgroundColor: GameUiPalette.actionInfoBlue,
                            foregroundColor: GameUiPalette.textPrimary,
                            height: 50,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () => _closeWith(
                                    GameCashOutAction.continueEndless,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          GameChromeButton(
                            label: '런 완료',
                            backgroundColor: GameUiPalette.actionGold,
                            foregroundColor: GameUiPalette.ink,
                            height: 50,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () =>
                                      _closeWith(GameCashOutAction.completeRun),
                          ),
                        ] else
                          GameChromeButton(
                            label: 'Market으로',
                            backgroundColor: GameUiPalette.actionGold,
                            foregroundColor: GameUiPalette.ink,
                            height: 52,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () =>
                                      _closeWith(GameCashOutAction.enterMarket),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
