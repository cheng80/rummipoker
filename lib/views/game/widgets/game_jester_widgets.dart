import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../resources/card_emblem_assets.dart';
import '../../../resources/jester_translation_scope.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

export 'game_card_metrics.dart';

part 'game_jester_effect_widgets.dart';
part 'game_jester_info_overlay.dart';

LinearGradient gameCardRarityBarGradient(Color color) {
  return LinearGradient(
    colors: [
      Color.lerp(GameUiPalette.ink, color, 0.58)!,
      Color.lerp(GameUiPalette.textPrimary, color, 0.18)!,
      Color.lerp(GameUiPalette.ink, color, 0.64)!,
    ],
  );
}

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
    'green_jester' => '현재 점수 ${_signedMultPercentToken(stateValue)}',
    'popcorn' => '현재 점수 +${stateValue * 5}%',
    'ice_cream' => '현재 +$stateValue 칩',
    'supernova' => '누적 확정 $playedHandTotal회',
    'ride_the_bus' => '현재 점수 ${_signedMultPercentToken(stateValue)}',
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

String _signedMultPercentToken(int value) {
  final percent = value * 5;
  if (percent >= 0) {
    return '+$percent%';
  }
  return '$percent%';
}

class GameJesterStrip extends StatelessWidget {
  const GameJesterStrip({
    super.key,
    required this.market,
    required this.activeEffects,
    required this.settlementSequenceTick,
    required this.selectedIndex,
    required this.onTapCard,
  });

  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeEffects;
  final int settlementSequenceTick;
  final int? selectedIndex;
  final ValueChanged<int> onTapCard;

  @override
  Widget build(BuildContext context) {
    final effectById = <String, RummiJesterEffectBreakdown>{};
    for (final effect in activeEffects) {
      effectById[effect.jesterId] = effect;
    }
    return SizedBox(
      height: kBattleItemSlotHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final ownedEntry = index < market.ownedEntries.length
              ? market.ownedEntries[index]
              : null;
          final card = ownedEntry?.card;
          final locked = index >= RummiRunProgress.baseUnlockedJesterSlots;
          return SizedBox(
            width: kBattleItemSlotWidth,
            height: kBattleItemSlotHeight,
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
              selected: selectedIndex == index,
              locked: locked,
              onTap: card != null && !locked ? () => onTapCard(index) : null,
            ),
          );
        }),
      ),
    );
  }
}

class GameJesterZone extends StatelessWidget {
  const GameJesterZone({
    super.key,
    required this.market,
    required this.activeEffects,
    required this.settlementSequenceTick,
    required this.selectedIndex,
    required this.onTapCard,
  });

  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeEffects;
  final int settlementSequenceTick;
  final int? selectedIndex;
  final ValueChanged<int> onTapCard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfacePanel.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${market.ownedEntries.length}/${market.maxOwnedSlots}',
              style: gameHudSubStyle.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 3),
            GameJesterStrip(
              market: market,
              activeEffects: activeEffects,
              settlementSequenceTick: settlementSequenceTick,
              selectedIndex: selectedIndex,
              onTapCard: onTapCard,
            ),
          ],
        ),
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
    this.selected = false,
    this.locked = false,
    this.surfaceColor,
    this.onTap,
  });

  final RummiJesterCard? card;
  final String? runtimeValueText;
  final bool extended;
  final RummiJesterEffectBreakdown? activeEffect;
  final int settlementSequenceTick;
  final bool selected;
  final bool locked;
  final Color? surfaceColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final frameColor = selected
        ? GameUiPalette.userSelection
        : GameUiPalette.textPrimary.withValues(alpha: 0.22);
    final frameWidth = selected ? 2.2 : 1.1;
    if (card == null) {
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
                  border: Border.all(color: frameColor, width: frameWidth),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kBattleSlotCardInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.cardEmptyFace.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(kRuntimeCardInnerRadius),
                  border: Border.all(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        locked
                            ? 'LOCKED'
                            : extended
                            ? 'EXT'
                            : 'JESTER',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: locked ? 0.46 : 0.62,
                          ),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.55,
                          height: 1,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Icon(
                          locked
                              ? Icons.lock_rounded
                              : extended
                              ? Icons.add_box_outlined
                              : Icons.style_outlined,
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: locked ? 0.36 : 0.28,
                          ),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          locked
                              ? (extended ? '5th' : '잠김')
                              : extended
                              ? '5th'
                              : '+',
                          maxLines: 1,
                          style: TextStyle(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: locked ? 0.48 : 0.42,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final rarityColor = gameJesterRarityColor(card!.rarity);
    final isActive = activeEffect != null;
    final displayName = localizedJesterName(context, card!);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRuntimeCardOuterRadius),
                  border: Border.all(color: frameColor, width: frameWidth),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kBattleSlotCardInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor ?? GameUiPalette.cardFace,
                  borderRadius: BorderRadius.circular(kRuntimeCardInnerRadius),
                  border: Border.all(
                    color: isActive
                        ? GameUiPalette.actionGoldBright
                        : rarityColor.withValues(alpha: 0.72),
                    width: isActive ? 2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? GameUiPalette.actionGoldBright.withValues(
                              alpha: 0.3,
                            )
                          : GameUiPalette.ink.withValues(alpha: 0.18),
                      blurRadius: isActive ? 12 : 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showInlineEffectBadge =
                        activeEffect != null && constraints.maxHeight >= 76;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(3.5, 3, 3.5, 3.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: kRuntimeCardBarHeight,
                                  decoration: BoxDecoration(
                                    gradient: gameCardRarityBarGradient(
                                      rarityColor,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      kRuntimeCardSmallRadius,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: GameUiPalette.textPrimary
                                            .withValues(alpha: 0.18),
                                        blurRadius: 0,
                                        spreadRadius: 0.4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              _GameCardTypeBadge(
                                label: 'J',
                                color: rarityColor,
                                textColor: GameUiPalette.cardBadgeText,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.5),
                          _GameCardEmblemImage(
                            assetPath: CardEmblemAssets.jester(card!.id),
                          ),
                          const SizedBox(height: 2.5),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _RuntimeCardNameText(
                                displayName,
                                style: const TextStyle(
                                  color: GameUiPalette.cardName,
                                  fontSize: 5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                            ),
                          ),
                          if (showInlineEffectBadge) ...[
                            const SizedBox(height: 3),
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: GameUiPalette.surfacePanel,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                jesterEffectBadge(activeEffect!),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameUiPalette.textPrimary,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
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
                sourceName: displayName,
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCardEmblemImage extends StatelessWidget {
  const _GameCardEmblemImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: kRuntimeCardArtWidth,
        height: kRuntimeCardArtHeight,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: GameUiPalette.cardArtSurface,
          borderRadius: BorderRadius.circular(kRuntimeCardArtRadius),
          border: Border.all(
            color: GameUiPalette.cardArtBorder.withValues(alpha: 0.28),
            width: 0.8,
          ),
        ),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRuntimeCardArtRadius - 2),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return const _GameCardEmblemFallback();
              },
              errorBuilder: (_, _, _) => const _GameCardEmblemFallback(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCardEmblemFallback extends StatelessWidget {
  const _GameCardEmblemFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: GameUiPalette.cardFallback.withValues(alpha: 0.48),
      ),
    );
  }
}

class _GameCardTypeBadge extends StatelessWidget {
  const _GameCardTypeBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kRuntimeCardTypeBadgeWidth,
      height: kRuntimeCardTypeBadgeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(GameUiPalette.textPrimary, color, 0.18)!,
            Color.lerp(GameUiPalette.ink, color, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(kRuntimeCardSmallRadius),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: textColor,
          fontSize: 3.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _RuntimeCardNameText extends StatelessWidget {
  const _RuntimeCardNameText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      softWrap: true,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class GameJesterHeaderRow extends StatelessWidget {
  const GameJesterHeaderRow({
    super.key,
    required this.station,
    required this.market,
  });

  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${market.ownedEntries.length}/${market.maxOwnedSlots}',
          style: gameHudSubStyle.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
