import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../../../logic/rummi_poker_grid/boss_modifier.dart';
import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../utils/common_ui.dart';
import '../game_presentation_timings.dart';
import 'game_card_name_text.dart';

const double kGameTileAspectRatio = 1.0;
const double kBoardFrameInset = 10.0;
const double kBoardGridGap = 1.5;
const double kBoardTileInnerPadding = 2.0;
const double kBattleItemSlotWidth = 54.0;
const double kBattleItemSlotHeight = 70.0;
const double kBattleSlotCardInset = 2.0;
const int kBattleQuickSlotDisplayCount = 3;
const int kBattlePassiveSlotDisplayCount = 2;
const int kBattleToolSlotDisplayCount = 3;
const int kBattleGearSlotDisplayCount = 2;
const int kBattleBaseUnlockedQuickSlots = 2;
const int kBattleBaseUnlockedPassiveSlots = 1;
const Color kGameModalBarrierColor = Color(0x70000000);
const Color kGameFeedbackBarrierColor = Color(0x22000000);

Color gameJesterRarityColor(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.uncommon => const Color(0xFF35C96F),
    RummiJesterRarity.rare => const Color(0xFF2F8CFF),
    RummiJesterRarity.legendary => const Color(0xFFFFB12B),
    RummiJesterRarity.common => const Color(0xFF8FAFA4),
  };
}

Color gameItemRarityColor(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.uncommon => const Color(0xFF35C96F),
    ItemRarity.rare => const Color(0xFF2F8CFF),
    ItemRarity.legendary => const Color(0xFFFFB12B),
    ItemRarity.common => const Color(0xFF8FAFA4),
  };
}

const TextStyle gameHudLabelStyle = TextStyle(
  color: Colors.white70,
  fontSize: 8.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.35,
);

final TextStyle gameHudValueStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.96),
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
  color: Colors.white70,
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
    this.onBlindInfoTap,
    this.stationGoalDisplayScore,
    this.stationGoalPulse = false,
    this.stationGoalPulseTick = 0,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;
  final VoidCallback onOptionsTap;
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
    final blindLabel = _battleBlindLabel(battle.currentBlindTierIndex);
    final blindColor = _battleBlindColor(battle.currentBlindTierIndex);
    final bossModifier = battle.bossModifier;

    return SizedBox(
      height: 62,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: GestureDetector(
              onTap: onBlindInfoTap,
              behavior: onBlindInfoTap == null
                  ? HitTestBehavior.deferToChild
                  : HitTestBehavior.opaque,
              child: GameHudChip(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'STATION ${battle.stageIndex}',
                      style: gameHudLabelStyle,
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
                        const Text(
                          'STATION GOAL',
                          style: gameHudLabelStyle,
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
                                style: gameHudValueStyle.copyWith(fontSize: 17),
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
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF4A81D),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _GameGoldHudChip extends StatefulWidget {
  const _GameGoldHudChip({required this.gold, required this.onOptionsTap});

  final int gold;
  final VoidCallback onOptionsTap;

  @override
  State<_GameGoldHudChip> createState() => _GameGoldHudChipState();
}

class _GameGoldHudChipState extends State<_GameGoldHudChip> {
  late int _previousGold;
  int _pulseTick = 0;

  @override
  void initState() {
    super.initState();
    _previousGold = widget.gold;
  }

  @override
  void didUpdateWidget(covariant _GameGoldHudChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previousGold == widget.gold) return;
    _previousGold = widget.gold;
    setState(() => _pulseTick++);
  }

  @override
  Widget build(BuildContext context) {
    final goldDisplayValue = '${widget.gold}';
    return TweenAnimationBuilder<double>(
      key: ValueKey('game-gold-pulse-$_pulseTick'),
      tween: Tween<double>(begin: 0, end: _pulseTick > 0 ? 1 : 0),
      duration: GamePresentationTimings.hudGoldPulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final glow = _pulseTick > 0 ? sin(value * pi) : 0.0;
        return DecoratedBox(
          key: _pulseTick > 0 ? const ValueKey('game-gold-pulse') : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (glow > 0)
                BoxShadow(
                  color: const Color(0xFFF2C14E).withValues(alpha: 0.26 * glow),
                  blurRadius: 14,
                  spreadRadius: 1.4,
                ),
            ],
          ),
          child: child,
        );
      },
      child: GameHudChip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GOLD',
              style: gameHudLabelStyle,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Gold',
                      value: goldDisplayValue,
                      child: ExcludeSemantics(
                        child: Image.asset(
                          AssetPaths.uiGreed,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const _GoldAssetFallbackIcon(size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          goldDisplayValue,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: gameHudValueStyle.copyWith(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: widget.onOptionsTap,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 18,
                        height: 22,
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withValues(alpha: 0.88),
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldAssetFallbackIcon extends StatelessWidget {
  const _GoldAssetFallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF2C14E),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          color: Color(0xFF174131),
          height: 1,
        ),
      ),
    );
  }
}

class _StationGoalClearBadge extends StatelessWidget {
  const _StationGoalClearBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF113B31).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF86F4C3).withValues(alpha: 0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86F4C3).withValues(alpha: 0.24),
            blurRadius: 8,
            spreadRadius: 0.7,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          'CLEAR',
          style: TextStyle(
            color: Color(0xFFE8FFF4),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BossModifierHudLabel extends StatelessWidget {
  const _BossModifierHudLabel({required this.modifier});

  final RummiBossModifier modifier;

  @override
  Widget build(BuildContext context) {
    final compactLabel = _bossModifierCompactHudLabel(modifier);
    return SizedBox(
      height: 13,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 12,
            constraints: const BoxConstraints(minWidth: 18),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A5B).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 0.7,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                modifier.markerText,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF24120D),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                compactLabel,
                maxLines: 1,
                style: gameHudSubStyle.copyWith(
                  color: const Color(0xFFFFD8CC),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _bossModifierCompactHudLabel(RummiBossModifier modifier) {
  return switch (modifier.category) {
    RummiBossModifierCategory.tileColorWeaken => '타일',
    RummiBossModifierCategory.lineKindWeaken => '라인',
    RummiBossModifierCategory.faceTileWeaken => '그림',
    RummiBossModifierCategory.allScoreWeaken => '전체',
    RummiBossModifierCategory.firstConfirmWeaken => '첫 확정',
    RummiBossModifierCategory.confirmCountWeaken => '확정',
    RummiBossModifierCategory.repeatHandRankWeaken => '반복',
    RummiBossModifierCategory.singleHandRankPressure => '첫 족보',
  };
}

String _battleBlindLabel(int tierIndex) {
  return switch (tierIndex) {
    1 => 'CLASH',
    2 => 'BOSS',
    _ => 'SCOUT',
  };
}

Color _battleBlindColor(int tierIndex) {
  return switch (tierIndex) {
    1 => const Color(0xFF72C7FF),
    2 => const Color(0xFFFF8A5B),
    _ => const Color(0xFF8BE0B9),
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
        color: Colors.white70,
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
            color: const Color(0xFFF2C14E).withValues(alpha: 0.10 * glow),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: Color.lerp(Colors.white70, const Color(0xFFFFE08A), glow),
            ),
            child: child!,
          ),
        );
      },
      child: text,
    );
  }
}

enum _GameItemZoneTab { slots, tools }

class GameItemZoneSkeleton extends StatefulWidget {
  const GameItemZoneSkeleton({
    super.key,
    required this.battle,
    required this.activeEffects,
    required this.settlementSequenceTick,
    this.selectedSlotIndex,
    this.onItemSlotTap,
  });

  final RummiBattleRuntimeFacade battle;
  final List<RummiJesterEffectBreakdown> activeEffects;
  final int settlementSequenceTick;
  final int? selectedSlotIndex;
  final ValueChanged<RummiBattleItemSlotView>? onItemSlotTap;

  @override
  State<GameItemZoneSkeleton> createState() => _GameItemZoneSkeletonState();
}

class _GameItemZoneSkeletonState extends State<GameItemZoneSkeleton> {
  _GameItemZoneTab _tab = _GameItemZoneTab.slots;

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final quickSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.quickSlot)
        .toList(growable: false);
    final passiveSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.passiveRack)
        .toList(growable: false);
    final toolSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.inventory)
        .take(kBattleToolSlotDisplayCount)
        .toList(growable: false);
    final gearSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.equipped)
        .take(kBattleGearSlotDisplayCount)
        .toList(growable: false);
    final activeEffectByItemId = <String, RummiJesterEffectBreakdown>{};
    for (final effect in widget.activeEffects) {
      activeEffectByItemId[effect.jesterId] = effect;
    }
    final activeToolOrGearEffect = [
      ...toolSlots,
      ...gearSlots,
    ].any((slot) => activeEffectByItemId.containsKey(slot.contentId));
    final activeSlotEffect = [
      ...quickSlots,
      ...passiveSlots,
    ].any((slot) => activeEffectByItemId.containsKey(slot.contentId));
    final visibleTab = activeToolOrGearEffect
        ? _GameItemZoneTab.tools
        : activeSlotEffect
        ? _GameItemZoneTab.slots
        : _tab;
    final unlockedQuickSlots = max(
      kBattleBaseUnlockedQuickSlots,
      quickSlots.length,
    );
    final unlockedPassiveSlots = max(
      kBattleBaseUnlockedPassiveSlots,
      passiveSlots.length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF173126).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GameItemZoneTabBar(
              currentTab: visibleTab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: visibleTab == _GameItemZoneTab.slots
                  ? [
                      for (
                        var index = 0;
                        index < kBattleQuickSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'Q${index + 1}',
                          accent: const Color(0xFF267B67),
                          itemSlot: index < quickSlots.length
                              ? quickSlots[index]
                              : null,
                          activeEffect: index < quickSlots.length
                              ? activeEffectByItemId[quickSlots[index]
                                    .contentId]
                              : null,
                          settlementSequenceTick: widget.settlementSequenceTick,
                          selected:
                              index < quickSlots.length &&
                              quickSlots[index].slotIndex ==
                                  widget.selectedSlotIndex,
                          locked: index >= unlockedQuickSlots,
                          onTap: widget.onItemSlotTap,
                        ),
                      for (
                        var index = 0;
                        index < kBattlePassiveSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'P${index + 1}',
                          accent: const Color(0xFF4C5A55),
                          itemSlot: index < passiveSlots.length
                              ? passiveSlots[index]
                              : null,
                          activeEffect: index < passiveSlots.length
                              ? activeEffectByItemId[passiveSlots[index]
                                    .contentId]
                              : null,
                          settlementSequenceTick: widget.settlementSequenceTick,
                          selected:
                              index < passiveSlots.length &&
                              passiveSlots[index].slotIndex ==
                                  widget.selectedSlotIndex,
                          locked: index >= unlockedPassiveSlots,
                          onTap: widget.onItemSlotTap,
                        ),
                    ]
                  : [
                      for (
                        var index = 0;
                        index < kBattleToolSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'T${index + 1}',
                          accent: const Color(0xFF2D7FA2),
                          itemSlot: index < toolSlots.length
                              ? toolSlots[index]
                              : null,
                          activeEffect: index < toolSlots.length
                              ? activeEffectByItemId[toolSlots[index].contentId]
                              : null,
                          settlementSequenceTick: widget.settlementSequenceTick,
                          selected:
                              index < toolSlots.length &&
                              toolSlots[index].slotIndex ==
                                  widget.selectedSlotIndex,
                          onTap: widget.onItemSlotTap,
                        ),
                      for (
                        var index = 0;
                        index < kBattleGearSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'G${index + 1}',
                          accent: const Color(0xFFB88735),
                          itemSlot: index < gearSlots.length
                              ? gearSlots[index]
                              : null,
                          activeEffect: index < gearSlots.length
                              ? activeEffectByItemId[gearSlots[index].contentId]
                              : null,
                          settlementSequenceTick: widget.settlementSequenceTick,
                          selected:
                              index < gearSlots.length &&
                              gearSlots[index].slotIndex ==
                                  widget.selectedSlotIndex,
                          onTap: widget.onItemSlotTap,
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameItemZoneTabBar extends StatelessWidget {
  const _GameItemZoneTabBar({
    required this.currentTab,
    required this.onChanged,
  });

  final _GameItemZoneTab currentTab;
  final ValueChanged<_GameItemZoneTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: _GameItemZoneTabButton(
              label: 'Slots',
              selected: currentTab == _GameItemZoneTab.slots,
              onPressed: () => onChanged(_GameItemZoneTab.slots),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _GameItemZoneTabButton(
              label: 'Tool / Gear',
              selected: currentTab == _GameItemZoneTab.tools,
              onPressed: () => onChanged(_GameItemZoneTab.tools),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameItemZoneTabButton extends StatelessWidget {
  const _GameItemZoneTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: selected
            ? const Color(0xFFF4A81D)
            : Colors.black.withValues(alpha: 0.16),
        foregroundColor: selected ? Colors.black : Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class GameBattleItemInfoOverlay extends StatelessWidget {
  const GameBattleItemInfoOverlay({
    super.key,
    required this.itemSlot,
    required this.onUse,
    required this.onClose,
  });

  final RummiBattleItemSlotView itemSlot;
  final VoidCallback onUse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final translations = ItemTranslationScope.of(context);
    final name = translations.resolveDisplayName(
      itemSlot.contentId,
      itemSlot.displayName,
    );
    final effectText = translations.resolveEffectText(
      itemSlot.contentId,
      itemSlot.effectText,
    );
    final canUseInBattle =
        itemSlot.placement == ItemPlacement.quickSlot &&
        itemSlot.usableInBattle;
    final isPassive =
        itemSlot.placement == ItemPlacement.passiveRack ||
        itemSlot.placement == ItemPlacement.equipped;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF123126).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GameCardNameText(
                          name,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    effectText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _GameItemOverlayTag(text: itemSlot.slotLabel),
                      _GameItemOverlayTag(text: 'x${itemSlot.count}'),
                      if (isPassive) ...[
                        _GameItemOverlayTag(
                          text: itemSlot.placement == ItemPlacement.equipped
                              ? '기어'
                              : '패시브',
                        ),
                        const _GameItemOverlayTag(text: '자동 발동'),
                      ],
                    ],
                  ),
                  if (canUseInBattle) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GameActionButton(
                        label: '사용',
                        background: const Color(0xFFF4A81D),
                        foreground: Colors.black,
                        onPressed: onUse,
                      ),
                    ),
                  ] else if (isPassive) ...[
                    const SizedBox(height: 12),
                    const _GamePassiveItemNotice(),
                  ] else if (itemSlot.placement == ItemPlacement.inventory) ...[
                    const SizedBox(height: 12),
                    const _GameToolItemNotice(),
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

class _GameToolItemNotice extends StatelessWidget {
  const _GameToolItemNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '상점용 도구 · Market에서 조건에 따라 사용',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePassiveItemNotice extends StatelessWidget {
  const _GamePassiveItemNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '패시브 효과 · 조건 충족 시 자동 발동',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameItemOverlayTag extends StatelessWidget {
  const _GameItemOverlayTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _GameItemPocketChip extends StatelessWidget {
  const _GameItemPocketChip({
    required this.label,
    required this.accent,
    this.locked = false,
    this.selected = false,
    this.itemSlot,
    this.activeEffect,
    required this.settlementSequenceTick,
    this.onTap,
  });

  final String label;
  final Color accent;
  final bool locked;
  final bool selected;
  final RummiBattleItemSlotView? itemSlot;
  final RummiJesterEffectBreakdown? activeEffect;
  final int settlementSequenceTick;
  final ValueChanged<RummiBattleItemSlotView>? onTap;

  @override
  Widget build(BuildContext context) {
    final itemSlot = this.itemSlot;
    final itemName = itemSlot == null
        ? null
        : ItemTranslationScope.of(
            context,
          ).resolveDisplayName(itemSlot.contentId, itemSlot.displayName);
    final frameColor = selected
        ? const Color(0xFFF2C14E)
        : Colors.white.withValues(alpha: 0.22);
    final frameWidth = selected ? 2.2 : 1.1;
    final hasItem = itemSlot != null;
    final itemRarityColor = hasItem
        ? gameItemRarityColor(itemSlot.item.rarity)
        : accent;
    final isActive = activeEffect != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked || itemSlot == null || onTap == null
          ? null
          : () => onTap!(itemSlot),
      child: Stack(
        children: [
          SizedBox(
            width: kBattleItemSlotWidth,
            height: kBattleItemSlotHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: frameColor, width: frameWidth),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kBattleSlotCardInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: locked
                      ? Colors.black.withValues(alpha: 0.26)
                      : itemSlot == null
                      ? Colors.black.withValues(alpha: 0.16)
                      : const Color(0xFFDDE9E4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFF2C14E)
                        : locked
                        ? Colors.white.withValues(alpha: 0.14)
                        : itemSlot == null
                        ? accent.withValues(alpha: 0.48)
                        : itemRarityColor.withValues(alpha: 0.88),
                    width: isActive
                        ? 2
                        : itemSlot == null
                        ? 1
                        : 1.2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFF2C14E,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : hasItem
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
                  child: locked
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.white.withValues(alpha: 0.40),
                              size: 22,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              label,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.48),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ],
                        )
                      : itemSlot == null
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.82,
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: itemRarityColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (activeEffect != null) ...[
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E4A3B),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _itemEffectBadge(activeEffect!),
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              itemSlot.slotLabel,
                              maxLines: 1,
                              style: TextStyle(
                                color: const Color(
                                  0xFF26352F,
                                ).withValues(alpha: 0.72),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: Center(
                                child: GameCardNameText(
                                  itemName!,
                                  style: const TextStyle(
                                    color: Color(0xFF26352F),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          if (activeEffect != null)
            Positioned(
              left: -4,
              right: -4,
              top: -15,
              child: _GameItemEffectBurst(
                key: ValueKey(
                  'item-burst-${itemSlot!.contentId}-$settlementSequenceTick',
                ),
                effect: activeEffect!,
                sourceName: itemName!,
              ),
            ),
          if (itemSlot != null && itemSlot.count > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    child: Text(
                      'x${itemSlot.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
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

String _itemEffectBadge(RummiJesterEffectBreakdown effect) {
  if (effect.hasIntegerMultiplierToken) {
    return 'xMult ${effect.xmultBonus.round()}x';
  }
  if (effect.chipsBonus > 0) {
    return '+Chips ${effect.chipsBonus}';
  }
  if (effect.multBonus > 0) {
    return '+Mult ${effect.multBonus}';
  }
  return '+Score ${effect.scoreDelta}';
}

class _GameItemEffectBurst extends StatelessWidget {
  const _GameItemEffectBurst({
    super.key,
    required this.effect,
    required this.sourceName,
  });

  final RummiJesterEffectBreakdown effect;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.settlementEffectBurst,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final fade = value < 0.18
            ? value / 0.18
            : value > 0.82
            ? (1 - value) / 0.18
            : 1.0;
        final dy = -6 * value;
        final scale = 0.88 + value * 0.12;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE6143C31),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFF2C14E).withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF2C14E).withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 8, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 3, height: 30, color: const Color(0xFFF2C14E)),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceName,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _itemEffectBadge(effect),
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFFFFF4CF),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                color: Colors.white.withValues(alpha: 0.42),
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
                      color: const Color(0xFFF4A81D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'MARKET',
                      style: TextStyle(
                        color: Colors.black,
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
                color: Colors.white70,
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
                        ? const Color(0xFF4AA78D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$option',
                    style: TextStyle(
                      color: value == option ? Colors.white : Colors.white70,
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
        color: const Color(0xFF1A4D3C).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6A8E7C).withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
        child: child,
      ),
    );
  }
}

class GameBoardGrid extends StatefulWidget {
  const GameBoardGrid({
    super.key,
    required this.board,
    required this.scoringCells,
    required this.constrainedScoringCells,
    required this.activeSettlementCells,
    required this.settlementBoardSnapshot,
    required this.selectedRow,
    required this.selectedCol,
    required this.boardMoveMode,
    required this.moveSourceRow,
    required this.moveSourceCol,
    required this.onTapCell,
    this.constrainedCells = const {},
    this.alignment = Alignment.center,
  });

  final RummiBoard board;
  final Set<String> scoringCells;
  final Set<String> constrainedScoringCells;
  final Set<String> constrainedCells;
  final Set<String> activeSettlementCells;
  final Map<String, Tile> settlementBoardSnapshot;
  final int? selectedRow;
  final int? selectedCol;
  final bool boardMoveMode;
  final int? moveSourceRow;
  final int? moveSourceCol;
  final void Function(int row, int col) onTapCell;
  final AlignmentGeometry alignment;

  @override
  State<GameBoardGrid> createState() => _GameBoardGridState();
}

class _GameBoardGridState extends State<GameBoardGrid> {
  late Map<String, String?> _previousTileKeys;
  late Map<String, Tile?> _previousTiles;
  Set<String> _appearingCells = const {};
  _BoardMoveFlight? _moveFlight;
  _BoardRemoveFlight? _removeFlight;
  int _moveFlightTick = 0;
  int _removeFlightTick = 0;

  @override
  void initState() {
    super.initState();
    _previousTileKeys = _tileKeysForBoard(widget.board);
    _previousTiles = _tilesForBoard(widget.board);
  }

  @override
  void didUpdateWidget(covariant GameBoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTileKeys = _tileKeysForBoard(widget.board);
    final appearingCells = <String>{};
    final removedCells = <String>[];
    final appearedCells = <String>[];
    for (final entry in currentTileKeys.entries) {
      final previous = _previousTileKeys[entry.key];
      if (previous == null && entry.value != null) {
        appearingCells.add(entry.key);
        appearedCells.add(entry.key);
      } else if (previous != null && entry.value == null) {
        removedCells.add(entry.key);
      }
    }
    _startBoardMoveFlightIfNeeded(
      removedCells: removedCells,
      appearedCells: appearedCells,
      previousTileKeys: _previousTileKeys,
      currentTileKeys: currentTileKeys,
    );
    _startBoardRemoveFlightIfNeeded(
      removedCells: removedCells,
      appearedCells: appearedCells,
      previousTiles: _previousTiles,
    );
    _previousTileKeys = currentTileKeys;
    _previousTiles = _tilesForBoard(widget.board);
    _appearingCells = _moveFlight == null
        ? appearingCells
        : appearingCells.difference({_moveFlight!.toCellKey});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A4B3A).withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF739785).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kBoardFrameInset),
                child: Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: kBoardSize,
                            mainAxisSpacing: kBoardGridGap,
                            crossAxisSpacing: kBoardGridGap,
                          ),
                      itemCount: kBoardSize * kBoardSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ kBoardSize;
                        final col = index % kBoardSize;
                        final cellKey = '$row:$col';
                        final tile = cellKey == _moveFlight?.toCellKey
                            ? null
                            : widget.board.cellAt(row, col) ??
                                  widget.settlementBoardSnapshot['$row:$col'];
                        final selected =
                            widget.selectedRow == row &&
                            widget.selectedCol == col;
                        final scoring = widget.scoringCells.contains(cellKey);
                        final constrainedScoring = widget
                            .constrainedScoringCells
                            .contains(cellKey);
                        final constrained = widget.constrainedCells.contains(
                          cellKey,
                        );
                        final settlementActive = widget.activeSettlementCells
                            .contains(cellKey);
                        final isMoveSource =
                            widget.boardMoveMode &&
                            widget.moveSourceRow == row &&
                            widget.moveSourceCol == col;
                        final isMoveAvailable =
                            widget.boardMoveMode && tile == null;
                        final isMoveLocked =
                            widget.boardMoveMode &&
                            tile != null &&
                            !isMoveSource;
                        final child = GameBoardCell(
                          key: ValueKey('board-cell-$row-$col'),
                          tile: tile,
                          selected: selected,
                          scoring: scoring,
                          constrainedScoring: constrainedScoring,
                          constrained: constrained,
                          settlementActive: settlementActive,
                          moveSource: isMoveSource,
                          moveAvailable: isMoveAvailable,
                          moveLocked: isMoveLocked,
                          onTap: () => widget.onTapCell(row, col),
                        );
                        if (!_appearingCells.contains(cellKey)) {
                          return child;
                        }
                        return _BoardPlacePop(child: child);
                      },
                    ),
                    if (_moveFlight != null)
                      _BoardMoveFlightOverlay(flight: _moveFlight!),
                    if (_removeFlight != null)
                      _BoardRemoveFlightOverlay(flight: _removeFlight!),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startBoardMoveFlightIfNeeded({
    required List<String> removedCells,
    required List<String> appearedCells,
    required Map<String, String?> previousTileKeys,
    required Map<String, String?> currentTileKeys,
  }) {
    if (removedCells.length != 1 || appearedCells.length != 1) {
      _moveFlight = null;
      return;
    }
    final fromCellKey = removedCells.single;
    final toCellKey = appearedCells.single;
    if (previousTileKeys[fromCellKey] != currentTileKeys[toCellKey]) {
      _moveFlight = null;
      return;
    }
    final (toRow, toCol) = _parseBoardCellKey(toCellKey);
    final tile = widget.board.cellAt(toRow, toCol);
    if (tile == null) {
      _moveFlight = null;
      return;
    }
    final tick = _moveFlightTick + 1;
    _moveFlightTick = tick;
    _moveFlight = _BoardMoveFlight(
      tick: tick,
      tile: tile,
      fromCellKey: fromCellKey,
      toCellKey: toCellKey,
    );
    Future<void>.delayed(GamePresentationTimings.boardTileMoveFlight, () {
      if (!mounted || _moveFlight?.tick != tick) return;
      setState(() => _moveFlight = null);
    });
  }

  void _startBoardRemoveFlightIfNeeded({
    required List<String> removedCells,
    required List<String> appearedCells,
    required Map<String, Tile?> previousTiles,
  }) {
    if (removedCells.length != 1 || appearedCells.isNotEmpty) {
      _removeFlight = null;
      return;
    }
    final cellKey = removedCells.single;
    final tile = previousTiles[cellKey];
    if (tile == null) {
      _removeFlight = null;
      return;
    }
    final tick = _removeFlightTick + 1;
    _removeFlightTick = tick;
    _removeFlight = _BoardRemoveFlight(
      tick: tick,
      tile: tile,
      cellKey: cellKey,
    );
    Future<void>.delayed(GamePresentationTimings.boardTileRemoveFlight, () {
      if (!mounted || _removeFlight?.tick != tick) return;
      setState(() => _removeFlight = null);
    });
  }
}

class _BoardMoveFlight {
  const _BoardMoveFlight({
    required this.tick,
    required this.tile,
    required this.fromCellKey,
    required this.toCellKey,
  });

  final int tick;
  final Tile tile;
  final String fromCellKey;
  final String toCellKey;
}

class _BoardRemoveFlight {
  const _BoardRemoveFlight({
    required this.tick,
    required this.tile,
    required this.cellKey,
  });

  final int tick;
  final Tile tile;
  final String cellKey;
}

Map<String, Tile?> _tilesForBoard(RummiBoard board) {
  return {
    for (var row = 0; row < kBoardSize; row++)
      for (var col = 0; col < kBoardSize; col++)
        '$row:$col': board.cellAt(row, col),
  };
}

Map<String, String?> _tileKeysForBoard(RummiBoard board) {
  return {
    for (var row = 0; row < kBoardSize; row++)
      for (var col = 0; col < kBoardSize; col++)
        '$row:$col': _boardTileKey(board.cellAt(row, col)),
  };
}

String? _boardTileKey(Tile? tile) => tile?.toString();

(int, int) _parseBoardCellKey(String key) {
  final parts = key.split(':');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

class _BoardMoveFlightOverlay extends StatelessWidget {
  const _BoardMoveFlightOverlay({required this.flight});

  final _BoardMoveFlight flight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSide = min(constraints.maxWidth, constraints.maxHeight);
          final tileSide =
              (contentSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
          final fromOffset = _cellOffset(flight.fromCellKey, tileSide);
          final toOffset = _cellOffset(flight.toCellKey, tileSide);
          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.boardTileMoveFlight,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              final offset = Offset.lerp(fromOffset, toOffset, value)!;
              final arc = sin(pi * value) * -10;
              final pulse = sin(pi * value);
              return Stack(
                children: [
                  Positioned(
                    key: const ValueKey('board-move-flight'),
                    left: offset.dx,
                    top: offset.dy + arc,
                    width: tileSide,
                    height: tileSide,
                    child: Transform.scale(
                      scale: 1 + (0.05 * pulse),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF86F4C3,
                              ).withValues(alpha: 0.22 * pulse),
                              blurRadius: 14 * pulse,
                              spreadRadius: 1.2 * pulse,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IgnorePointer(
                child: GameRummiTileCard(
                  tile: flight.tile,
                  selected: true,
                  accent: false,
                  aspectRatio: kGameTileAspectRatio,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _cellOffset(String cellKey, double tileSide) {
    final (row, col) = _parseBoardCellKey(cellKey);
    return Offset(
      col * (tileSide + kBoardGridGap),
      row * (tileSide + kBoardGridGap),
    );
  }
}

class _BoardRemoveFlightOverlay extends StatelessWidget {
  const _BoardRemoveFlightOverlay({required this.flight});

  final _BoardRemoveFlight flight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSide = min(constraints.maxWidth, constraints.maxHeight);
          final tileSide =
              (contentSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
          final offset = _cellOffset(flight.cellKey, tileSide);
          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.boardTileRemoveFlight,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final rise = value * 20;
              final opacity = (1 - value).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Positioned(
                    key: const ValueKey('board-remove-flight'),
                    left: offset.dx,
                    top: offset.dy - rise,
                    width: tileSide,
                    height: tileSide,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 1 - (0.08 * value),
                        child: Transform.rotate(
                          angle: -0.08 * value,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IgnorePointer(
                child: GameRummiTileCard(
                  tile: flight.tile,
                  selected: true,
                  accent: false,
                  aspectRatio: kGameTileAspectRatio,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _cellOffset(String cellKey, double tileSide) {
    final (row, col) = _parseBoardCellKey(cellKey);
    return Offset(
      col * (tileSide + kBoardGridGap),
      row * (tileSide + kBoardGridGap),
    );
  }
}

class _BoardPlacePop extends StatelessWidget {
  const _BoardPlacePop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('board-place-pop'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.boardTilePlacePop,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final glow = (1 - value).clamp(0.0, 1.0);
        final progress = value.clamp(0.0, 1.0);
        final travel = (1 - Curves.easeOutCubic.transform(progress)) * 18;
        return Transform.translate(
          key: const ValueKey('board-place-flight'),
          offset: Offset(0, travel),
          child: Opacity(
            opacity: (0.72 + (progress * 0.28)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.9 + (value * 0.1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFF2C14E,
                      ).withValues(alpha: 0.24 * glow),
                      blurRadius: 16 * glow,
                      spreadRadius: 1.5 * glow,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class GameBoardCell extends StatelessWidget {
  const GameBoardCell({
    super.key,
    required this.tile,
    required this.selected,
    required this.scoring,
    required this.constrainedScoring,
    required this.constrained,
    required this.settlementActive,
    required this.moveSource,
    required this.moveAvailable,
    required this.moveLocked,
    required this.onTap,
  });

  final Tile? tile;
  final bool selected;
  final bool scoring;
  final bool constrainedScoring;
  final bool constrained;
  final bool settlementActive;
  final bool moveSource;
  final bool moveAvailable;
  final bool moveLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = moveSource
        ? const Color(0xFF5EE7F7)
        : moveAvailable
        ? const Color(0xFF85E9B8)
        : moveLocked
        ? Colors.white.withValues(alpha: 0.18)
        : selected
        ? const Color(0xFFF76D5E)
        : settlementActive
        ? const Color(0xFF86F4C3)
        : constrainedScoring
        ? const Color(0xFFE45A5F)
        : scoring
        ? const Color(0xFFF4C45A)
        : Colors.white.withValues(alpha: 0.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final cornerRadius = rummikubTileCornerRadiusForSide(side);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius),
            child: AnimatedContainer(
              duration: GamePresentationTimings.boardTileState,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2A3B34)
                    : moveAvailable
                    ? const Color(0xFF23654A).withValues(alpha: 0.86)
                    : moveLocked
                    ? const Color(0xFF24312D).withValues(alpha: 0.78)
                    : settlementActive
                    ? const Color(0xFF285A49)
                    : const Color(0xFF204E3C).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(cornerRadius),
                border: Border.all(
                  color: borderColor,
                  width:
                      selected ||
                          settlementActive ||
                          constrainedScoring ||
                          moveSource ||
                          moveAvailable
                      ? 2
                      : 1,
                ),
                boxShadow: settlementActive
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF86F4C3,
                          ).withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: tile == null
                  ? moveAvailable
                        ? Center(
                            child: Icon(
                              Icons.open_with_rounded,
                              color: Colors.white.withValues(alpha: 0.58),
                              size: side * 0.32,
                            ),
                          )
                        : null
                  : _SettlementTileLift(
                      active: settlementActive,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Opacity(
                              opacity: moveLocked ? 0.42 : 1,
                              child: GameRummiTileCard(
                                tile: tile!,
                                selected: selected || moveSource,
                                accent: false,
                                aspectRatio: kGameTileAspectRatio,
                              ),
                            ),
                          ),
                          if (constrained)
                            Positioned(
                              left: 4,
                              top: 4,
                              right: 4,
                              bottom: 4,
                              child: GameConstraintBadge(side: side),
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

class _SettlementTileLift extends StatelessWidget {
  const _SettlementTileLift({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('settlement-tile-lift'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.settlementTileLift,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final lift = sin(pi * value);
        return Transform.translate(
          offset: Offset(0, -6 * lift),
          child: Transform.scale(scale: 1 + (0.035 * lift), child: child),
        );
      },
      child: child,
    );
  }
}

class GameConstraintBadge extends StatelessWidget {
  const GameConstraintBadge({super.key, required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pad = width * 0.06;
        final innerWidth = width - (pad * 2);
        final innerHeight = height - (pad * 2);
        final barHeight = innerHeight * 0.24;
        final fontSize = barHeight * 0.98;

        return IgnorePointer(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: innerWidth,
                height: barHeight,
                child: Center(
                  child: Text(
                    'X',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.96),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.36),
                          blurRadius: 1.7,
                          offset: const Offset(0, 0.9),
                        ),
                      ],
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

class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.onPressed,
    this.foreground = Colors.white,
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

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: _GameRummiTilePainter(
          tile: tile,
          selected: selected,
          accent: accent,
        ),
      ),
    );
  }
}

class _GameRummiTilePainter extends CustomPainter {
  const _GameRummiTilePainter({
    required this.tile,
    required this.selected,
    required this.accent,
  });

  final Tile tile;
  final bool selected;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintRummikubTile(
      canvas,
      rect,
      tile,
      selected: selected,
      shadowElevation: selected ? 4 : 2.4,
    );

    if (!accent) return;
    final accentRect = rect.deflate(3.5);
    final rr = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF2C14E).withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _GameRummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
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
        colors: [Color(0xFF1B5644), Color(0xFF12392E), Color(0xFF0A211B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withValues(alpha: 0.035);
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.08);

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
        color: const Color(0xFF1A2E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
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
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: kGameModalBarrierColor,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: builder(dialogContext),
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
        color: const Color(0xFF233D38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF64D8A4).withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF132520),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF9DF0BE), width: 1.4),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.style_rounded,
              color: Color(0xFF9DF0BE),
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
                    color: Color(0xFF9DF0BE),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '다음 런 준비에서 새 규칙을 여는 데 사용됩니다.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
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

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetry]는 현재 스테이지 시작 스냅샷으로 즉시 복원한다.
/// [onNewRun]은 이번 런 기록을 남기고 새 run 준비로 이동한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required int insightReward,
  required Future<void> Function() onRetry,
  required Future<void> Function() onNewRun,
  required Future<void> Function() onExit,
}) {
  final text =
      '${signals.map(expirySignalLabel).join('\n')}\n\n'
      '이번 런의 기록을 남기고 새로 시작할 수 있습니다.';
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('gameResult'),
            style: TextStyle(
              fontFamily: AssetPaths.fontNexonLv2Gothic,
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
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
                background: const Color(0xFFF4A81D),
                foreground: Colors.black,
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
                background: const Color(0xFF64D8A4),
                foreground: Colors.black,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await WidgetsBinding.instance.endOfFrame;
                  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                  await onNewRun();
                },
              ),
              const SizedBox(height: 10),
              GameActionButton(
                label: context.tr('exit'),
                background: const Color(0xFF5D6B68),
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
  );
}
