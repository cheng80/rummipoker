import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../resources/jester_translation_scope.dart';
import 'game_shared_widgets.dart';

const double kJesterCardWidth = 58.0;
const double kJesterCardHeight = 78.0;

String localizedJesterName(BuildContext context, RummiJesterCard card) {
  final translations = JesterTranslationScope.of(context);
  return translations.resolveDisplayName(card.id, card.displayName);
}

String localizedJesterEffect(BuildContext context, RummiJesterCard card) {
  final translations = JesterTranslationScope.of(context);
  return translations.resolveEffectText(card.id, card.effectText);
}

String jesterCategoryLabel(RummiJesterCard card) {
  return switch (card.effectType) {
    'economy' => '경제형',
    'stateful_growth' => '상태형',
    'chips_bonus' || 'mult_bonus' || 'xmult_bonus' || 'other' => '점수형',
    _ => '기타',
  };
}

String? jesterRuntimeValueText(
  RummiJesterCard card,
  RummiJesterRuntimeSnapshot snapshot, {
  required int slotIndex,
}) {
  final stateValue = snapshot.stateValueForSlot(slotIndex);
  final playedHandTotal = snapshot.playedHandCounts.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  return switch (card.id) {
    'green_jester' => '현재 ${_signedValueToken(stateValue, "Mult")}',
    'popcorn' => '현재 +$stateValue Mult',
    'ice_cream' => '현재 +$stateValue Chips',
    'supernova' => '누적 확정 $playedHandTotal회',
    'ride_the_bus' => '현재 ${_signedValueToken(stateValue, "Mult")}',
    _ => null,
  };
}

String jesterEffectBadge(RummiJesterEffectBreakdown effect) {
  final suffix = effect.displaySuffix;
  if (suffix.isEmpty) {
    return effect.displayToken;
  }
  return '${effect.displayToken} $suffix';
}

String? settlementJesterNames(ConfirmedLineBreakdown line) {
  if (line.effects.isEmpty) return null;
  final names = <String>[];
  for (final effect in line.effects) {
    if (!names.contains(effect.displayName)) {
      names.add(effect.displayName);
    }
    if (names.length >= 2) break;
  }
  if (names.isEmpty) return null;
  return names.join(' · ');
}

String _signedValueToken(int value, String suffix) {
  if (value >= 0) {
    return '+$value $suffix';
  }
  return '$value $suffix';
}

class GameJesterStrip extends StatelessWidget {
  const GameJesterStrip({
    super.key,
    required this.market,
    required this.activeEffects,
    required this.settlementSequenceTick,
    required this.onTapCard,
  });

  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeEffects;
  final int settlementSequenceTick;
  final ValueChanged<int> onTapCard;

  @override
  Widget build(BuildContext context) {
    final effectById = <String, RummiJesterEffectBreakdown>{};
    for (final effect in activeEffects) {
      effectById[effect.jesterId] = effect;
    }
    return SizedBox(
      height: kJesterCardHeight + 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final ownedEntry = index < market.ownedEntries.length
              ? market.ownedEntries[index]
              : null;
          final card = ownedEntry?.card;
          return SizedBox(
            width: kJesterCardWidth,
            height: kJesterCardHeight,
            child: GameJesterSlot(
              card: card,
              runtimeValueText: card != null
                  ? jesterRuntimeValueText(
                      card,
                      market.runtimeSnapshot,
                      slotIndex: index,
                    )
                  : null,
              extended: index == 4,
              activeEffect: card != null ? effectById[card.id] : null,
              settlementSequenceTick: settlementSequenceTick,
              onTap: card != null ? () => onTapCard(index) : null,
            ),
          );
        }),
      ),
    );
  }
}

class GameJesterSlot extends StatelessWidget {
  const GameJesterSlot({
    super.key,
    required this.card,
    required this.runtimeValueText,
    required this.extended,
    required this.activeEffect,
    required this.settlementSequenceTick,
    this.onTap,
  });

  final RummiJesterCard? card;
  final String? runtimeValueText;
  final bool extended;
  final RummiJesterEffectBreakdown? activeEffect;
  final int settlementSequenceTick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF183E32).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                extended ? 'EXT' : 'JESTER',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.55,
                ),
              ),
              const Spacer(),
              Center(
                child: Icon(
                  extended ? Icons.add_box_outlined : Icons.style_outlined,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  extended ? '5th' : '+',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rarityColor = switch (card?.rarity) {
      RummiJesterRarity.uncommon => const Color(0xFF6CD19B),
      RummiJesterRarity.rare => const Color(0xFF67B7FF),
      RummiJesterRarity.legendary => const Color(0xFFF2C14E),
      _ => Colors.white70,
    };
    final isActive = activeEffect != null;
    final displayName = localizedJesterName(context, card!);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7DB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFF2C14E)
                    : rarityColor.withValues(alpha: 0.72),
                width: isActive ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFF2C14E).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: isActive ? 12 : 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: card == null
                          ? const Color(0xFF385248)
                          : rarityColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(
                            0xFF20312B,
                          ).withValues(alpha: 0.92),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.15,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20312B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      jesterCategoryLabel(card!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1B3A31),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (activeEffect != null) ...[
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4A3B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          jesterEffectBadge(activeEffect!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (activeEffect != null)
            Positioned(
              left: 4,
              right: 4,
              top: -16,
              child: GameJesterEffectBurst(
                key: ValueKey(
                  'jester-burst-${activeEffect!.jesterId}-$settlementSequenceTick',
                ),
                effect: activeEffect!,
              ),
            ),
        ],
      ),
    );
  }
}

class GameJesterEffectBurst extends StatelessWidget {
  const GameJesterEffectBurst({super.key, required this.effect});

  final RummiJesterEffectBreakdown effect;

  @override
  Widget build(BuildContext context) {
    final label = effect.displayToken;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      builder: (context, value, child) {
        final fade = value < 0.18
            ? value / 0.18
            : value > 0.76
            ? (1 - value) / 0.24
            : 1.0;
        final dy = lerpDouble(10, -12, Curves.easeOut.transform(value))!;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8143C31),
            borderRadius: BorderRadius.circular(999),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _GameOutlinedLabel(
              label,
              fillColor: const Color(0xFFFFF4CF),
              strokeColor: const Color(0xFF173126),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class GameJesterInfoOverlay extends StatelessWidget {
  const GameJesterInfoOverlay({
    super.key,
    required this.card,
    this.runtimeValueText,
    required this.sellGold,
    required this.onSell,
    required this.onClose,
  });

  final RummiJesterCard card;
  final String? runtimeValueText;
  final int sellGold;
  final VoidCallback onSell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final notes = JesterTranslationScope.of(context).notes(card.id);
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizedJesterName(context, card),
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
                localizedJesterEffect(context, card),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (runtimeValueText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    runtimeValueText!,
                    style: const TextStyle(
                      color: Color(0xFFF4E6B1),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              if (notes != null && notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  notes,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GameActionButton(
                  label: '판매 +$sellGold Gold',
                  background: const Color(0xFFB74B3B),
                  onPressed: onSell,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOutlinedLabel extends StatelessWidget {
  const _GameOutlinedLabel(
    this.text, {
    required this.fillColor,
    required this.strokeColor,
    required this.fontSize,
    required this.fontWeight,
  });

  final String text;
  final Color fillColor;
  final Color strokeColor;
  final double fontSize;
  final FontWeight fontWeight;

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
          style: TextStyle(
            foreground: strokePaint,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: fillColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
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

class GameJesterHeaderRow extends StatelessWidget {
  const GameJesterHeaderRow({
    super.key,
    required this.station,
    required this.market,
    required this.onShopTap,
    required this.onHandSizeChanged,
  });

  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final VoidCallback onShopTap;
  final ValueChanged<int> onHandSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Text(
                  'JESTER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.85,
                    height: 1.05,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${market.ownedEntries.length}/${market.maxOwnedSlots}',
                  style: gameHudSubStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GameDebugShopHandCluster(
            onShopTap: onShopTap,
            handSize: station.resources.maxHandSize,
            onHandSizeChanged: onHandSizeChanged,
          ),
        ],
      ),
    );
  }
}
