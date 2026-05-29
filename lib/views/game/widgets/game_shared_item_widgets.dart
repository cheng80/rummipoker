part of 'game_shared_widgets.dart';

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
      battle.quickSlotCapacity,
    );
    final unlockedPassiveSlots = max(
      kBattleBaseUnlockedPassiveSlots,
      battle.passiveRelicCapacity,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfacePanel.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        ),
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
            if (battle.pendingConfirmItemCount > 0) ...[
              const SizedBox(height: 4),
              _GameItemQueuedBadge(count: battle.pendingConfirmItemCount),
            ],
            if (battle.pendingBoardMoveSlideBonus) ...[
              const SizedBox(height: 4),
              const _GameItemBoardMoveQueuedBadge(),
            ],
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
                          accent: GameUiPalette.marketPositive,
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
                          accent: GameUiPalette.passiveSlotAccent,
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
                          accent: GameUiPalette.toolSlotAccent,
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
                          accent: GameUiPalette.gearSlotAccent,
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

class _GameItemQueuedBadge extends StatelessWidget {
  const _GameItemQueuedBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('battle-item-confirm-queued-pulse-$count'),
        tween: Tween<double>(begin: 0, end: 1),
        duration: GamePresentationTimings.itemEffectSparkBurst,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final glow = sin(pi * value).clamp(0.0, 1.0);
          return DecoratedBox(
            key: const ValueKey('battle-item-confirm-queued-badge'),
            decoration: BoxDecoration(
              color: GameUiPalette.actionGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GameUiPalette.actionGold.withValues(alpha: 0.58),
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.specialScoreText.withValues(
                    alpha: 0.32 * glow,
                  ),
                  blurRadius: 14 * glow,
                  spreadRadius: 1.2 * glow,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            '확정 대기 $count',
            maxLines: 1,
            style: const TextStyle(
              color: GameUiPalette.specialScoreText,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameItemBoardMoveQueuedBadge extends StatelessWidget {
  const _GameItemBoardMoveQueuedBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        key: const ValueKey('battle-item-board-move-queued-badge'),
        decoration: BoxDecoration(
          color: GameUiPalette.specialSoftMint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GameUiPalette.specialSoftMint.withValues(alpha: 0.54),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '이동 보너스 대기',
                maxLines: 1,
                style: TextStyle(
                  color: GameUiPalette.specialSoftMintText,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(width: 3),
              _GameItemBoardMoveQueuedMotion(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameItemBoardMoveQueuedMotion extends StatelessWidget {
  const _GameItemBoardMoveQueuedMotion();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('battle-item-board-move-queued-motion'),
      width: 18,
      height: 10,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.itemEffectSparkBurst,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Stack(
              children: [
                Positioned(
                  left: -8 + (12 * value),
                  top: -3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(2, (index) {
                      return Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: const Color(
                          0xFF9AF0CB,
                        ).withValues(alpha: 0.54 + index * 0.24),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
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
            ? GameUiPalette.actionGold
            : GameUiPalette.ink.withValues(alpha: 0.16),
        foregroundColor: selected
            ? GameUiPalette.ink
            : GameUiPalette.textSecondary,
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
    final hasItem = itemSlot != null;
    final isActive = activeEffect != null;
    return GestureDetector(
      key: ValueKey('battle-item-slot-$label'),
      behavior: HitTestBehavior.opaque,
      onTap: locked || itemSlot == null || onTap == null
          ? null
          : () => onTap!(itemSlot),
      child: Stack(
        children: [
          const SizedBox(
            width: kBattleItemSlotWidth,
            height: kBattleItemSlotHeight,
          ),
          if (selected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kRuntimeCardOuterRadius + 2,
                  ),
                  border: Border.all(
                    color: GameUiPalette.userSelection,
                    width: 2.2,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kBattleSlotCardInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiPalette.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: GameUiPalette.actionGoldBright.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : hasItem
                      ? [
                          BoxShadow(
                            color: GameUiPalette.ink.withValues(alpha: 0.18),
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: itemSlot == null || locked
                      ? _GameBattleEmptyItemSlotFace(
                          label: label,
                          locked: locked,
                        )
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: _GameBattleItemCardFace(
                                itemSlot: itemSlot,
                                itemName: itemName!,
                              ),
                            ),
                            if (activeEffect != null)
                              Positioned(
                                left: 4,
                                right: 4,
                                top: 20,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1E4A3B,
                                    ).withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: GameUiPalette.actionGoldBright,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    _itemEffectBadge(activeEffect!),
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
                    color: GameUiPalette.ink.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    child: Text(
                      'x${itemSlot.count}',
                      style: const TextStyle(
                        color: GameUiPalette.textPrimary,
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
    return '점수 x${effect.xmultBonus.round()}';
  }
  if (effect.chipsBonus > 0) {
    return '+칩 ${effect.chipsBonus}';
  }
  if (effect.multBonus > 0) {
    return '점수 +${effect.multPercentBonus}%';
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
            color: GameUiPalette.settlementEffectSurface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: GameUiPalette.actionGoldBright.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: GameUiPalette.actionGoldBright.withValues(alpha: 0.18),
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
                Container(
                  width: 3,
                  height: 30,
                  color: GameUiPalette.actionGoldBright,
                ),
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
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.92,
                          ),
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
                          color: GameUiPalette.textWarmPale,
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
