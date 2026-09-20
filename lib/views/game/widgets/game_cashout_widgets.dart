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
import '../../../utils/app_translation.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/semantic_text.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../game_presentation_timings.dart';
import '../game_feedback_cues.dart';
import 'game_jester_widgets.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

part 'game_cashout_presentation_widgets.dart';
part 'game_cashout_sheet_widgets.dart';

/// Omit [context] only for legacy consumers awaiting migration.
String gameHandRankLabel(RummiHandRank rank, {BuildContext? context}) =>
    context == null
    ? rummiHandRankLabel(rank)
    : context.translate(rummiHandRankKey(rank));

String gameScoreBreakdownLabel(
  ConfirmedLineBreakdown line, {
  required BuildContext context,
}) {
  final parts = <String>[
    context.translate(
      'marketBaseChips',
      namedArgs: {'count': '${line.rankBaseScore ?? line.baseScore}'},
    ),
  ];
  if (line.growthBonus > 0) {
    parts.add(
      context.translate(
        'marketGrowthChips',
        namedArgs: {'count': '${line.growthBonus}'},
      ),
    );
  }
  if (line.overlapBonus > 0) {
    parts.add(
      context.translate(
        'marketOverlapBonus',
        namedArgs: {'count': '${line.overlapBonus}'},
      ),
    );
  }
  if (line.jesterBonus > 0) {
    parts.add(
      context.translate(
        'marketJesterBonus',
        namedArgs: {'count': '${line.jesterBonus}'},
      ),
    );
  }
  return parts.join(' · ');
}

String gameLineRefShortLabel(LineRef ref, {BuildContext? context}) {
  if (context != null) return localizedGameLineRefShortLabel(context, ref);
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
    _setStep(1);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    _setStep(2);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    _setStep(3);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    _setStep(4);
    await Future<void>.delayed(stepDelay);
    if (!mounted) return;
    _setStep(5);
    if (widget.autoEnterMarketOnLoad && !widget.completesRun) {
      await Future<void>.delayed(autoAdvanceDelay);
      if (!mounted) return;
      _closeWith(GameCashOutAction.enterMarket);
    }
  }

  void _setStep(int step) {
    if (!mounted) return;
    setState(() => _step = step);
    GameFeedback.play(GameCue.cashOutCollect, pitch: 1 + (0.04 * (step - 1)));
  }

  void _closeWithFeedback(GameCashOutAction action) {
    if (_closeWith(action)) GameFeedback.play(GameCue.buttonTap);
  }

  bool _closeWith(GameCashOutAction action) {
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return false;
    Navigator.of(context).pop(action);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final bonusEntries = settlement.entries
        .where((entry) => entry.isBonus)
        .toList(growable: false);
    final growthEntries = bonusEntries
        .where((entry) => entry.isOverkillGrowthBonus)
        .toList(growable: false);
    final otherBonusEntries = bonusEntries
        .where((entry) => !entry.isOverkillGrowthBonus)
        .toList(growable: false);
    final hasBonuses = bonusEntries.isNotEmpty;
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
                        Text(
                          context.translate('marketCashoutComplete'),
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
                                        if (growthEntries.isNotEmpty) ...[
                                          _GameCashOutGrowthRewardSection(
                                            entries: growthEntries,
                                          ),
                                          if (otherBonusEntries.isNotEmpty)
                                            const SizedBox(height: 8),
                                        ],
                                        for (final entry
                                            in otherBonusEntries) ...[
                                          _GameCashOutLine(
                                            leading: localizedSettlementLeading(
                                              context,
                                              entry,
                                            ),
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
                            label: context.translate('marketEnterEndless'),
                            backgroundColor: GameUiPalette.actionInfoBlue,
                            foregroundColor: GameUiPalette.textPrimary,
                            height: 50,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () => _closeWithFeedback(
                                    GameCashOutAction.continueEndless,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          GameChromeButton(
                            label: context.translate('marketCompleteRun'),
                            backgroundColor: GameUiPalette.actionGold,
                            foregroundColor: GameUiPalette.ink,
                            height: 50,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () => _closeWithFeedback(
                                    GameCashOutAction.completeRun,
                                  ),
                          ),
                        ] else
                          GameChromeButton(
                            label: context.translate('marketEnterMarket'),
                            backgroundColor: GameUiPalette.actionGold,
                            foregroundColor: GameUiPalette.ink,
                            height: 52,
                            borderRadius: 18,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            onPressed: _step < 3
                                ? null
                                : () => _closeWithFeedback(
                                    GameCashOutAction.enterMarket,
                                  ),
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

String localizedGameLineRefShortLabel(BuildContext context, LineRef ref) =>
    context.translate(switch (ref.kind) {
      LineKind.row => 'marketLineRow',
      LineKind.col => 'marketLineCol',
      LineKind.diagMain => 'marketLineDiagMain',
      LineKind.diagAnti => 'marketLineDiagAnti',
    });

/// Resolve only explicit metadata. Custom/manual descriptions remain verbatim.
String localizedSettlementDescription(
  BuildContext context,
  RummiSettlementEntryView entry,
) {
  final key = entry.descriptionKey;
  if (key == null) return entry.description;
  return context.translate(
    key,
    namedArgs: {
      ...entry.descriptionArgs,
      if (entry.growthRank != null)
        'rank': context.translate(rummiHandRankKey(entry.growthRank!)),
    },
  );
}

String localizedSettlementLeading(
  BuildContext context,
  RummiSettlementEntryView entry,
) {
  final key = entry.leadingKey;
  return key == null
      ? entry.leadingLabel
      : context.translate(key, namedArgs: entry.leadingArgs);
}

String localizedSettlementTileEffectName(
  BuildContext context,
  RummiJesterEffectBreakdown effect,
) {
  final key = switch (effect.jesterId) {
    'tile:chip_inlaid' => 'coreSettlementTileChipInlaid',
    'tile:score_gilded' => 'coreSettlementTileScoreGilded',
    'tile:gold_tile' => 'coreSettlementTileGoldTile',
    'tile:glass_tile' => 'coreSettlementTileGlassTile',
    'tile_edition:silver_edition' => 'battleWidgetsTileEditionSilver',
    'tile_edition:glow_edition' => 'battleWidgetsTileEditionGlow',
    'tile_edition:prism_edition' => 'battleWidgetsTileEditionPrism',
    'tile_seal:blue_seal' => 'battleWidgetsTileSealBlue',
    'tile_seal:red_seal' => 'battleWidgetsTileSealRed',
    'tile_seal:line_mark' => 'battleWidgetsTileSealLine',
    'tile_seal:growth_seal' => 'battleWidgetsTileSealGrowth',
    'tile_seal:gold_seal' => 'battleWidgetsTileSealGold',
    'tile_seal:echo_seal' => 'battleWidgetsTileSealEcho',
    'tile_seal:anchor_seal' => 'battleWidgetsTileSealAnchor',
    'tile_seal:fracture_seal' => 'battleWidgetsTileSealFracture',
    'tile_seal:cross_memory' => 'battleWidgetsTileSealCross',
    'tile_seal:bridge_seal' => 'battleWidgetsTileSealBridge',
    _ => null,
  };
  return key == null ? effect.displayName : context.translate(key);
}
