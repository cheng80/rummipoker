import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../../../logic/rummi_poker_grid/boss_modifier.dart';
import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/line_ref.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_settlement_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/card_emblem_assets.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../services/new_run_setup.dart';
import '../../../utils/active_run_translation.dart';
import '../../../utils/common_ui.dart';
import '../../../utils/app_translation.dart';
import '../../../widgets/semantic_text.dart';
import '../../../services/game_settings.dart';
import '../../../widgets/fx/fx_layer.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../../../widgets/fx/juice.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../game_feedback_cues.dart';
import '../game_presentation_timings.dart';
import 'game_boss_intro_widgets.dart';
import 'game_card_metrics.dart';
import 'game_card_name_text.dart';
import 'game_ui_palette.dart';

export 'game_card_metrics.dart';

part 'game_shared_hud_widgets.dart';
part 'game_shared_battle_hud_widgets.dart';
part 'game_shared_item_widgets.dart';
part 'game_shared_item_overlays.dart';
part 'game_shared_item_cards.dart';
part 'game_shared_board_widgets.dart';
part 'game_shared_board_motion_widgets.dart';
part 'game_shared_board_remove_motion_widgets.dart';
part 'game_shared_tile_widgets.dart';
part 'game_shared_game_over_widgets.dart';
part 'game_shared_modal_widgets.dart';

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
            warning: resources.drawPileRemaining == 0,
            label: context.translate(
              'battleWidgetsDeckResource',
              namedArgs: {
                'remaining': '${resources.drawPileRemaining}',
                'total': '${widget.battle.totalDeckSize}',
              },
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'board-move',
            pulsing: _pulsingKeys.contains('board-move'),
            warning: resources.boardMovesRemaining == 1,
            label: context.translate(
              'battleWidgetsMoveResource',
              namedArgs: {
                'remaining': '${resources.boardMovesRemaining}',
                'total': '${resources.boardMovesMax}',
              },
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'board-discard',
            pulsing: _pulsingKeys.contains('board-discard'),
            warning: resources.boardDiscardsRemaining == 1,
            label: context.translate(
              'battleWidgetsBoardDiscardResource',
              namedArgs: {
                'remaining': '${resources.boardDiscardsRemaining}',
                'total': '${resources.boardDiscardsMax}',
              },
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _BottomResourceText(
            pulseKey: 'hand',
            pulsing: _pulsingKeys.contains('hand'),
            warning: resources.handDiscardsRemaining == 1,
            label: context.translate(
              'battleWidgetsHandResource',
              namedArgs: {
                'count': '${widget.battle.hand.length}',
                'max': '${resources.maxHandSize}',
                'remaining': '${resources.handDiscardsRemaining}',
                'total': '${resources.handDiscardsMax}',
              },
            ),
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
    this.warning = false,
  });

  final String pulseKey;
  final bool pulsing;
  final String label;
  final TextAlign textAlign;

  /// 마지막 이동·마지막 버림·덱 0. 경고 색과 테두리로 바뀐다.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    Widget text = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: switch (textAlign) {
        TextAlign.left => Alignment.centerLeft,
        TextAlign.right => Alignment.centerRight,
        _ => Alignment.center,
      },
      child: Text(
        label,
        maxLines: 1,
        textAlign: textAlign,
        style: TextStyle(
          color: warning
              ? GameUiPalette.specialDangerBright
              : GameUiPalette.textSecondary,
          fontSize: 9,
          fontWeight: warning ? FontWeight.w900 : FontWeight.w800,
        ),
      ),
    );
    if (warning) {
      text = DecoratedBox(
        key: ValueKey('bottom-resource-warning-$pulseKey'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: GameUiPalette.specialDangerBright.withValues(alpha: 0.1),
          border: Border.all(
            color: GameUiPalette.specialDangerBright.withValues(alpha: 0.55),
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: text,
        ),
      );
    }
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
        borderRadius: BorderRadius.circular(kGameHudRadius),
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

String expirySignalLabel(RummiExpirySignal signal, {BuildContext? context}) {
  return switch (signal) {
    RummiExpirySignal.boardFullAfterDcExhausted => _battleWidgetTranslation(
      context,
      'battleWidgetsExpiryBoard',
    ),
    RummiExpirySignal.drawPileExhausted => _battleWidgetTranslation(
      context,
      'battleWidgetsExpiryDeck',
    ),
  };
}

/// 거절 입력에 좌우로 짧게 흔들린다. 상점 거절 흔들림과 같은 길이다.
///
/// [tick]이 바뀔 때마다 한 번 흔들리고, 동작 줄이기에서는 움직이지 않는다.
class GameDenyShake extends StatelessWidget {
  const GameDenyShake({super.key, required this.tick, required this.child});

  final int tick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strength = MotionPolicy.juiceScale;
    if (tick == 0 || strength <= 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey('game-deny-shake-$tick'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketActionDenyShake,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(sin(t * pi * 6) * (1 - t) * 6 * strength, 0),
        child: child,
      ),
      child: child,
    );
  }
}

// Compatibility for existing callers until their owning track passes context.
// All localized screen builds in this library supply their BuildContext.
String _battleWidgetTranslation(
  BuildContext? context,
  String key, {
  Map<String, String>? namedArgs,
}) {
  return context?.translate(key, namedArgs: namedArgs) ??
      key.tr(namedArgs: namedArgs);
}
