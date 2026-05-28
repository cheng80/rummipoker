import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../../../logic/rummi_poker_grid/boss_modifier.dart';
import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/card_emblem_assets.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../utils/common_ui.dart';
import '../game_presentation_timings.dart';
import 'game_card_metrics.dart';
import 'game_card_name_text.dart';
import 'game_ui_palette.dart';

export 'game_card_metrics.dart';

part 'game_shared_hud_widgets.dart';
part 'game_shared_item_widgets.dart';
part 'game_shared_item_overlays.dart';
part 'game_shared_item_cards.dart';
part 'game_shared_board_widgets.dart';

const Color kGameModalBarrierColor = GameUiPalette.modalBarrier;
const Color kGameFeedbackBarrierColor = GameUiPalette.feedbackBarrier;

Color gameJesterRarityColor(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.uncommon => GameUiPalette.rarityUncommon,
    RummiJesterRarity.rare => GameUiPalette.rarityRare,
    RummiJesterRarity.legendary => GameUiPalette.rarityLegendary,
    RummiJesterRarity.common => GameUiPalette.rarityCommon,
  };
}

Color gameItemRarityColor(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.uncommon => GameUiPalette.rarityUncommon,
    ItemRarity.rare => GameUiPalette.rarityRare,
    ItemRarity.legendary => GameUiPalette.rarityLegendary,
    ItemRarity.common => GameUiPalette.rarityCommon,
  };
}

LinearGradient gameItemRarityBarGradient(Color color) {
  return LinearGradient(
    colors: [
      Color.lerp(GameUiPalette.ink, color, 0.58)!,
      Color.lerp(GameUiPalette.textPrimary, color, 0.18)!,
      Color.lerp(GameUiPalette.ink, color, 0.64)!,
    ],
  );
}

const TextStyle gameHudLabelStyle = TextStyle(
  color: GameUiPalette.textSecondary,
  fontSize: 8.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.35,
);

final TextStyle gameHudValueStyle = TextStyle(
  color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
  fontWeight: FontWeight.w900,
  height: 1,
);

class GameInputBarrier extends StatelessWidget {
  const GameInputBarrier.modal({super.key}) : color = kGameModalBarrierColor;

  const GameInputBarrier.feedback({super.key})
    : color = kGameFeedbackBarrierColor;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(dismissible: false, color: color);
  }
}

const TextStyle gameHudSubStyle = TextStyle(
  color: GameUiPalette.textSecondary,
  fontSize: 9,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

/// 보드 가로 폭 기준 실제 카드 렌더 폭을 계산한다.
double boardTileVisualWidth(double boardSide) {
  final gridSide = boardSide - (kBoardFrameInset * 2);
  final cellSide = (gridSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
  return cellSide - (kBoardTileInnerPadding * 2);
}

class GameTopHud extends StatelessWidget {
  const GameTopHud({
    super.key,
    required this.station,
    required this.battle,
    required this.onOptionsTap,
    this.onTutorialTap,
    this.difficultyLabel = '표준',
    this.onBlindInfoTap,
    this.stationGoalDisplayScore,
    this.stationGoalPulse = false,
    this.stationGoalPulseTick = 0,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;
  final String difficultyLabel;
  final VoidCallback onOptionsTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onBlindInfoTap;
  final int? stationGoalDisplayScore;
  final bool stationGoalPulse;
  final int stationGoalPulseTick;

  @override
  Widget build(BuildContext context) {
    final objective = station.objective;
    final scoreTowardObjective =
        stationGoalDisplayScore ?? objective.scoreTowardObjective;
    final progress = objective.targetScore <= 0
        ? 0.0
        : (scoreTowardObjective / objective.targetScore).clamp(0.0, 1.0);
    final goalReached =
        objective.targetScore > 0 &&
        scoreTowardObjective >= objective.targetScore;
    final isEndless = BlindSelectionSetup.isEndlessStation(battle.stageIndex);
    final blindLabel = _battleBlindLabel(battle.currentBlindTierIndex);
    final blindColor = _battleBlindColor(
      battle.currentBlindTierIndex,
      isEndless: isEndless,
    );
    final bossModifier = battle.bossModifier;
    final stationLabel = isEndless
        ? '무한 S${battle.stageIndex} · $difficultyLabel'
        : 'S${battle.stageIndex} · $difficultyLabel';
    final goalLabel = isEndless ? 'ENDLESS GOAL' : 'STATION GOAL';
    final goalColor = isEndless
        ? GameUiPalette.specialGold
        : GameUiPalette.textPrimary.withValues(alpha: 0.92);
    final progressColor = isEndless
        ? GameUiPalette.specialDanger
        : GameUiPalette.actionGold;

    return SizedBox(
      height: 62,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: GestureDetector(
              key: const ValueKey('battle-blind-info-chip'),
              onTap: onBlindInfoTap,
              behavior: onBlindInfoTap == null
                  ? HitTestBehavior.deferToChild
                  : HitTestBehavior.opaque,
              child: GameHudChip(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      stationLabel,
                      style: gameHudLabelStyle.copyWith(
                        color: isEndless
                            ? GameUiPalette.specialGold
                            : gameHudLabelStyle.color,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            blindLabel,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: gameHudValueStyle.copyWith(
                              color: blindColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    if (bossModifier == null)
                      Text(
                        '보상 +${RummiRunProgress.stageClearGoldBase}',
                        style: gameHudSubStyle,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      )
                    else
                      _BossModifierHudLabel(modifier: bossModifier),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(
                stationGoalPulse ? 'goal-$stationGoalPulseTick' : 'goal-idle',
              ),
              tween: Tween<double>(begin: 0, end: stationGoalPulse ? 1 : 0),
              duration: GamePresentationTimings.hudGoalPulse,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final glow = stationGoalPulse ? sin(value * pi) : 0.0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      if (glow > 0)
                        BoxShadow(
                          color: const Color(
                            0xFFF2C14E,
                          ).withValues(alpha: 0.24 * glow),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: child,
                );
              },
              child: GameHudChip(
                key: const ValueKey('station-goal-chip'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          goalLabel,
                          style: gameHudLabelStyle.copyWith(
                            color: isEndless
                                ? GameUiPalette.specialGold
                                : gameHudLabelStyle.color,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                '$scoreTowardObjective/${objective.targetScore}',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                                style: gameHudValueStyle.copyWith(
                                  color: goalColor,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: GameUiPalette.ink.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (goalReached)
                      const Positioned(
                        key: ValueKey('station-goal-clear-badge'),
                        right: -2,
                        top: -5,
                        child: _StationGoalClearBadge(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 132,
            child: _GameGoldHudChip(
              gold: battle.currentGold,
              onOptionsTap: onOptionsTap,
              onTutorialTap: onTutorialTap,
            ),
          ),
        ],
      ),
    );
  }
}

String _battleBlindLabel(int tierIndex) {
  return switch (tierIndex) {
    1 => 'CLASH',
    2 => 'BOSS',
    _ => 'SCOUT',
  };
}

Color _battleBlindColor(int tierIndex, {bool isEndless = false}) {
  if (isEndless) {
    return switch (tierIndex) {
      1 => GameUiPalette.specialGold,
      2 => GameUiPalette.specialDanger,
      _ => GameUiPalette.specialWarning,
    };
  }
  return switch (tierIndex) {
    1 => GameUiPalette.specialBlue,
    2 => GameUiPalette.actionWarning,
    _ => GameUiPalette.specialMint,
  };
}

class GameBottomInfoRow extends StatefulWidget {
  const GameBottomInfoRow({
    super.key,
    required this.station,
    required this.battle,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;

  @override
  State<GameBottomInfoRow> createState() => _GameBottomInfoRowState();
}

class _GameBottomInfoRowState extends State<GameBottomInfoRow> {
  late _BottomInfoSignature _previousSignature;
  Set<String> _pulsingKeys = const {};
  Timer? _pulseClearTimer;

  @override
  void initState() {
    super.initState();
    _previousSignature = _BottomInfoSignature.from(
      station: widget.station,
      battle: widget.battle,
    );
  }

  @override
  void didUpdateWidget(covariant GameBottomInfoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _BottomInfoSignature.from(
      station: widget.station,
      battle: widget.battle,
    );
    final changedKeys = _previousSignature.changedKeys(nextSignature);
    _previousSignature = nextSignature;
    if (changedKeys.isEmpty) return;
    setState(() => _pulsingKeys = changedKeys);
    _pulseClearTimer?.cancel();
    _pulseClearTimer = Timer(GamePresentationTimings.bottomInfoPulseHold, () {
      if (!mounted) return;
      if (_pulsingKeys != changedKeys) return;
      setState(() => _pulsingKeys = const {});
    });
  }

  @override
  void dispose() {
    _pulseClearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resources = widget.station.resources;
    return Row(
      children: [
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'deck',
            pulsing: _pulsingKeys.contains('deck'),
            label:
                '덱 ${resources.drawPileRemaining}/${widget.battle.totalDeckSize}',
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'board-move',
            pulsing: _pulsingKeys.contains('board-move'),
            label:
                '이동 ${resources.boardMovesRemaining}/${resources.boardMovesMax}',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'board-discard',
            pulsing: _pulsingKeys.contains('board-discard'),
            label:
                '보드 버림 ${resources.boardDiscardsRemaining}/${resources.boardDiscardsMax}',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'hand',
            pulsing: _pulsingKeys.contains('hand'),
            label:
                '손패 ${widget.battle.hand.length}/${resources.maxHandSize} · 버림 ${resources.handDiscardsRemaining}/${resources.handDiscardsMax}',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _BottomInfoSignature {
  const _BottomInfoSignature({
    required this.deck,
    required this.boardMove,
    required this.boardDiscard,
    required this.hand,
  });

  final String deck;
  final String boardMove;
  final String boardDiscard;
  final String hand;

  static _BottomInfoSignature from({
    required RummiStationRuntimeFacade station,
    required RummiBattleRuntimeFacade battle,
  }) {
    final resources = station.resources;
    return _BottomInfoSignature(
      deck: '${resources.drawPileRemaining}/${battle.totalDeckSize}',
      boardMove: '${resources.boardMovesRemaining}/${resources.boardMovesMax}',
      boardDiscard:
          '${resources.boardDiscardsRemaining}/${resources.boardDiscardsMax}',
      hand:
          '${battle.hand.length}/${resources.maxHandSize}/${resources.handDiscardsRemaining}/${resources.handDiscardsMax}',
    );
  }

  Set<String> changedKeys(_BottomInfoSignature next) {
    return {
      if (deck != next.deck) 'deck',
      if (boardMove != next.boardMove) 'board-move',
      if (boardDiscard != next.boardDiscard) 'board-discard',
      if (hand != next.hand) 'hand',
    };
  }
}

class _BottomResourceText extends StatelessWidget {
  const _BottomResourceText({
    required this.pulseKey,
    required this.pulsing,
    required this.label,
    required this.textAlign,
  });

  final String pulseKey;
  final bool pulsing;
  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      textAlign: textAlign,
      style: const TextStyle(
        color: GameUiPalette.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
    if (!pulsing) return text;
    return TweenAnimationBuilder<double>(
      key: ValueKey('bottom-resource-pulse-$pulseKey'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.bottomResourcePulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final glow = sin(value * pi).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: GameUiPalette.actionGoldBright.withValues(
              alpha: 0.10 * glow,
            ),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: Color.lerp(
                GameUiPalette.textSecondary,
                GameUiPalette.actionGoldText,
                glow,
              ),
            ),
            child: child!,
          ),
        );
      },
      child: text,
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
        color: GameUiPalette.textPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
        ),
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
                color: GameUiPalette.textPrimary.withValues(alpha: 0.42),
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
                      color: GameUiPalette.actionGold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'MARKET',
                      style: TextStyle(
                        color: GameUiPalette.ink,
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
    return SizedBox(
      height: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 8),
            child: Text(
              'Hand',
              style: TextStyle(
                color: GameUiPalette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final option in const [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => onChanged(option),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: GamePresentationTimings.handCountToggle,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: value == option
                        ? GameUiPalette.debugToggleActive
                        : GameUiPalette.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$option',
                    style: TextStyle(
                      color: value == option
                          ? GameUiPalette.textPrimary
                          : GameUiPalette.textSecondary,
                      fontSize: 10,
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
        color: GameUiPalette.hudChipSurface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.boardHudBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
        child: child,
      ),
    );
  }
}

class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.onPressed,
    this.foreground = GameUiPalette.textPrimary,
    this.compact = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: GameChromeButton(
        label: label,
        backgroundColor: background,
        foregroundColor: foreground,
        onPressed: onPressed,
        height: compact ? 30 : 40,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 4 : 6,
        ),
      ),
    );
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
        colors: [
          GameUiPalette.gameTableGradientStart,
          GameUiPalette.gameTableGradientMid,
          GameUiPalette.gameTableGradientEnd,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = GameUiPalette.textPrimary.withValues(alpha: 0.035);
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = GameUiPalette.ink.withValues(alpha: 0.08);

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
        color: GameUiPalette.surfaceModal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
        ),
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
  String semanticLabel = '게임 대화상자',
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: kGameModalBarrierColor,
    routeSettings: RouteSettings(name: semanticLabel),
    builder: (dialogContext) {
      final routeLabel = semanticLabel.trim().isEmpty
          ? '게임 대화상자'
          : semanticLabel;
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: routeLabel,
        child: Dialog(
          backgroundColor: GameUiPalette.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: builder(dialogContext),
          ),
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

class GameOverInsightRewardCard extends StatelessWidget {
  const GameOverInsightRewardCard({super.key, required this.insightReward});

  final int insightReward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: GameUiPalette.gameOverRewardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.actionSuccess.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 54,
            decoration: BoxDecoration(
              color: GameUiPalette.gameOverRewardIconSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GameUiPalette.gameOverRewardAccent,
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.style_rounded,
              color: GameUiPalette.gameOverRewardAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '기억 카드 획득',
                  style: TextStyle(
                    color: GameUiPalette.gameOverRewardAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '다음 런 준비에서 새 규칙을 여는 데 사용됩니다.',
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverRunSummary {
  const GameOverRunSummary({
    required this.difficultyLabel,
    required this.stageIndex,
    required this.scoreTowardTarget,
    required this.targetScore,
    required this.seed,
    this.bestRank,
    this.bestRankScore = 0,
    this.mostPlayedRank,
    this.mostPlayedCount = 0,
    this.playedHandTotal = 0,
    this.boughtJesterCount = 0,
    this.boughtItemCount = 0,
    this.addedDeckTileCount = 0,
  });

  final String difficultyLabel;
  final int stageIndex;
  final int scoreTowardTarget;
  final int targetScore;
  final int seed;
  final RummiHandRank? bestRank;
  final int bestRankScore;
  final RummiHandRank? mostPlayedRank;
  final int mostPlayedCount;
  final int playedHandTotal;
  final int boughtJesterCount;
  final int boughtItemCount;
  final int addedDeckTileCount;
}

String gameOverTauntLineForSeed(int seed) {
  const lines = [
    '전략은 좋았어요. 결과만 빼면요.',
    '덱은 기억합니다. 이번 실수도요.',
    '한 줄만 더 만들었으면 멋졌겠네요. 만들었다면요.',
    '보드는 가득 찼고, 변명도 꽤 찼습니다.',
    '족보는 자랐습니다. 자존심은 잠시 접어 둡시다.',
    '이번 런은 교훈이 많네요. 점수 빼고요.',
    '방금 선택은 기록해 뒀습니다. 반면교사로요.',
    '운이 나빴다고 해도 됩니다. 카드가 듣지 않는다면요.',
    '다음 런에서는 이 장면을 못 본 척해 드릴게요.',
    '성장은 남았습니다. 승리는 다음에 찾죠.',
  ];
  return lines[seed.abs() % lines.length];
}

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetry]는 현재 스테이지 시작 스냅샷으로 즉시 복원한다.
/// [onNewRun]은 이번 런 기록을 남기고 새 run 준비로 이동한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required int insightReward,
  GameOverRunSummary? runSummary,
  String? tauntLine,
  required Future<void> Function() onRetry,
  required Future<void> Function() onNewRun,
  required Future<void> Function() onExit,
}) {
  final resolvedTaunt =
      tauntLine ??
      gameOverTauntLineForSeed(
        (runSummary?.seed ?? 0) +
            (runSummary?.stageIndex ?? 0) +
            (runSummary?.scoreTowardTarget ?? 0),
      );
  final text =
      '${signals.map(expirySignalLabel).join('\n')}\n\n'
      '이번 런의 기록을 남기고 새로 시작할 수 있습니다.';
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _localizedGameResultTitle(context),
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.95),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            _GameOverTauntPanel(text: resolvedTaunt),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (runSummary != null) ...[
              const SizedBox(height: 12),
              _GameOverRunSummaryCard(summary: runSummary),
            ],
            if (insightReward > 0) ...[
              const SizedBox(height: 12),
              GameOverInsightRewardCard(insightReward: insightReward),
            ],
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameActionButton(
                  label: '다시 도전',
                  background: GameUiPalette.actionGold,
                  foreground: GameUiPalette.ink,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onRetry();
                  },
                ),
                const SizedBox(height: 10),
                GameActionButton(
                  label: '새 run 준비',
                  background: GameUiPalette.actionSuccess,
                  foreground: GameUiPalette.ink,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onNewRun();
                  },
                ),
                const SizedBox(height: 10),
                GameActionButton(
                  label: _localizedDialogLabel(context, 'exit', '나가기'),
                  background: GameUiPalette.disabledControl,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onExit();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _GameOverTauntPanel extends StatelessWidget {
  const _GameOverTauntPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDanger,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.specialDangerBorder.withValues(alpha: 0.46),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.theater_comedy_rounded,
              color: GameUiPalette.specialDangerText,
              size: 24,
            ),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: const TextStyle(
                  color: GameUiPalette.specialDangerPale,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverRunSummaryCard extends StatelessWidget {
  const _GameOverRunSummaryCard({required this.summary});

  final GameOverRunSummary summary;

  @override
  Widget build(BuildContext context) {
    final scoreText = summary.targetScore <= 0
        ? '${summary.scoreTowardTarget}'
        : '${summary.scoreTowardTarget} / ${summary.targetScore}';
    final bestHand = summary.bestRank == null
        ? '없음'
        : '${_gameOverHandRankLabel(summary.bestRank!)} · 칩 ${summary.bestRankScore}';
    final mostPlayed = summary.mostPlayedRank == null
        ? '없음'
        : '${_gameOverHandRankLabel(summary.mostPlayedRank!)} (${summary.mostPlayedCount})';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceInfo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.cardFallback.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 7,
          children: [
            const Text(
              '이번 런 정산',
              style: TextStyle(
                color: GameUiPalette.specialMutedText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            _GameOverSummaryRow(
              label: '도달',
              value: 'S${summary.stageIndex} · ${summary.difficultyLabel}',
            ),
            _GameOverSummaryRow(label: '점수', value: scoreText),
            _GameOverSummaryRow(label: '베스트 족보', value: bestHand),
            _GameOverSummaryRow(label: '가장 많이 완성', value: mostPlayed),
            _GameOverSummaryRow(
              label: '완성/구매',
              value:
                  '족보 ${summary.playedHandTotal} · Jester ${summary.boughtJesterCount} · 아이템 ${summary.boughtItemCount}',
            ),
            _GameOverSummaryRow(
              label: '덱/시드',
              value: '추가 타일 ${summary.addedDeckTileCount} · ${summary.seed}',
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverSummaryRow extends StatelessWidget {
  const _GameOverSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            softWrap: true,
            style: const TextStyle(
              color: GameUiPalette.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

String _gameOverHandRankLabel(RummiHandRank rank) {
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
  };
}

String _localizedGameResultTitle(BuildContext context) {
  return _localizedDialogLabel(context, 'gameResult', '게임결과');
}

String _localizedDialogLabel(
  BuildContext context,
  String key,
  String fallback,
) {
  try {
    return context.tr(key);
  } on Object {
    return fallback;
  }
}
