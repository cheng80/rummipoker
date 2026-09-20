part of '../archive_view.dart';

class _ArchiveDetailHost extends StatelessWidget {
  const _ArchiveDetailHost({
    required this.open,
    required this.onClose,
    required this.child,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 160),
      crossFadeState: open
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _ArchiveDetailCard(onClose: onClose, child: child),
      ),
    );
  }
}

class _ArchiveDetailCard extends StatelessWidget {
  const _ArchiveDetailCard({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: GameUiPalette.archiveSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.gameOverRewardAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: withButtonSound(onClose),
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            color: GameUiPalette.textPrimary.withValues(alpha: 0.66),
            tooltip: context.translate('menuCollapse'),
          ),
        ],
      ),
    );
  }
}

class _ArchiveMemoryCardDetail extends StatelessWidget {
  const _ArchiveMemoryCardDetail({required this.card, required this.status});

  final _ArchiveMemoryCardDefinition card;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected
          ? card.localizedTitle(context)
          : context.translate('menuMemoryUnknown'),
      subtitle: context.translate(
        'menuMemoryStatus',
        namedArgs: {'status': context.translate(status.labelKey)},
      ),
      body: collected
          ? context.translate('menuMemoryDetail')
          : context.translate('menuMemoryEmpty'),
    );
  }
}

class _ArchiveJesterDetail extends StatelessWidget {
  const _ArchiveJesterDetail({required this.card, required this.status});

  final RummiJesterCard card;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected
          ? localizedJesterName(context, card)
          : context.translate('menuJesterUnknown'),
      subtitle: collected
          ? '${context.translate(status.labelKey)} · ${context.translate(_archiveJesterRarityKey(card.rarity))}'
          : '${context.translate(status.labelKey)} · Jester',
      body: collected
          ? localizedJesterEffect(context, card)
          : context.translate('menuJesterEmpty'),
    );
  }
}

class _ArchiveItemDetail extends StatelessWidget {
  const _ArchiveItemDetail({required this.item, required this.status});

  final ItemDefinition item;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected
          ? ItemTranslationScope.of(
              context,
            ).resolveDisplayName(item.id, item.displayName)
          : context.translate('menuItemUnknown'),
      subtitle: collected
          ? '${context.translate(status.labelKey)} · ${_archiveItemSlotLabel(item.placement)} · ${context.translate(_archiveItemRarityKey(item.rarity))}'
          : '${context.translate(status.labelKey)} · Item',
      body: collected
          ? ItemTranslationScope.of(
              context,
            ).resolveEffectText(item.id, item.effectText)
          : context.translate('menuItemEmpty'),
    );
  }
}

class _ArchiveDetailText extends StatelessWidget {
  const _ArchiveDetailText({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: TextStyle(
            color: GameUiPalette.gameOverRewardAccent.withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: GameUiPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 7),
        SemanticText(
          body,
          style: TextStyle(
            color: GameUiPalette.textPrimary.withValues(alpha: 0.76),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ArchiveSelectableCard extends StatelessWidget {
  const _ArchiveSelectableCard({
    super.key,
    required this.width,
    required this.height,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.child,
    this.isNew = false,
    this.flipTick = 0,
  });

  final double width;
  final double height;
  final _ArchiveCollectionStatus status;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// 마지막으로 확인한 뒤 새로 발견한 항목.
  final bool isNew;

  /// 바뀌면 카드가 한 번 뒤집히며 공개된다.
  final int flipTick;

  static const double _labelGap = 4;
  static const double _labelHeight = _ArchiveStatusBadge.height;
  static const double _outerPadding = 2;
  static const double _borderWidth = 2;
  static const double _labelHorizontalInset = 6;

  static double totalHeight(double cardHeight) =>
      cardHeight +
      _labelGap +
      _labelHeight +
      (_outerPadding * 2) +
      (_borderWidth * 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: totalHeight(height),
      child: Column(
        children: [
          PressFeedback(
            onTap: _handleTap,
            haptic: null,
            playSound: false,
            builder: (context, onTap) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AnimatedContainer(
                duration: GamePresentationTimings.choiceSelect,
                width: width,
                height: height + ((_outerPadding + _borderWidth) * 2),
                padding: const EdgeInsets.all(_outerPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? GameUiPalette.gameOverRewardAccent
                        : GameUiPalette.transparent,
                    width: _borderWidth,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: _ArchiveFlipReveal(tick: flipTick, child: child),
                      ),
                      if (isNew)
                        const Positioned(
                          top: -4,
                          right: -4,
                          child: _ArchiveNewTag(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _labelGap),
          Center(
            child: _ArchiveStatusBadge(
              status: status,
              width: width - (_labelHorizontalInset * 2),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap() {
    GameFeedback.play(GameCue.choiceSelect);
    onTap();
  }
}

class _ArchiveStatusBadge extends StatelessWidget {
  const _ArchiveStatusBadge({required this.status, required this.width});

  final _ArchiveCollectionStatus status;
  final double width;

  static const double height = 14;

  @override
  Widget build(BuildContext context) {
    // 상태마다 등장 결을 다르게 한다. 미발견은 그대로, 발견은 아래에서 올라오고,
    // 획득·클리어는 튀어나오듯 커진다.
    final badge = _badge(context);
    return switch (status) {
      _ArchiveCollectionStatus.undiscovered => badge,
      _ArchiveCollectionStatus.discovered => EntranceIn(
        duration: GamePresentationTimings.flowEntranceIn,
        offset: const Offset(0, 0.8),
        child: badge,
      ),
      _ => EntranceIn(
        duration: GamePresentationTimings.flowEntranceIn,
        offset: Offset.zero,
        scaleFrom: 0.5,
        curve: Curves.easeOutBack,
        child: badge,
      ),
    };
  }

  Widget _badge(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: GameUiPalette.ink.withValues(alpha: 0.16)),
      ),
      child: Text(
        context.translate(status.labelKey),
        style: const TextStyle(
          color: GameUiPalette.ink,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ArchiveEmptyCard extends StatelessWidget {
  const _ArchiveEmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameUiPalette.archiveDarkSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.16),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: GameUiPalette.textPrimary.withValues(alpha: 0.26),
              size: 19,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.30),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveMemoryCardFace extends StatelessWidget {
  const _ArchiveMemoryCardFace({required this.card});

  final _ArchiveMemoryCardDefinition card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameUiPalette.gameOverRewardIconSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.gameOverRewardAccent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.actionSuccess.withValues(alpha: 0.16),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
        child: Column(
          children: [
            const Icon(
              Icons.style_rounded,
              color: GameUiPalette.gameOverRewardAccent,
              size: 20,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  card.localizedTitle(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameUiPalette.archiveRewardText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
            _ArchiveItemBadge(label: context.translate(card.badgeKey)),
          ],
        ),
      ),
    );
  }
}

class _ArchiveItemCardFace extends StatelessWidget {
  const _ArchiveItemCardFace({required this.item});

  final ItemDefinition item;

  @override
  Widget build(BuildContext context) {
    final accent = _archiveItemAccent(item.placement);
    return Container(
      decoration: BoxDecoration(
        color: _archiveItemSurface(item.placement),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            FractionallySizedBox(
              widthFactor: 0.82,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: gameItemRarityColor(item.rarity),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameCardNameText(
                  ItemTranslationScope.of(
                    context,
                  ).resolveDisplayName(item.id, item.displayName),
                  style: const TextStyle(
                    color: GameUiPalette.specialGoldCardText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
            _ArchiveItemBadge(label: _archiveItemSlotLabel(item.placement)),
          ],
        ),
      ),
    );
  }
}

class _ArchiveItemBadge extends StatelessWidget {
  const _ArchiveItemBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: GameUiPalette.ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: GameUiPalette.specialGoldCardText,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

Color _archiveItemSurface(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => GameUiPalette.marketPlacementQuickSurface,
    ItemPlacement.passiveRack => GameUiPalette.marketPlacementPassiveSurface,
    ItemPlacement.inventory => GameUiPalette.specialGoldCard,
    ItemPlacement.equipped => GameUiPalette.titleDebugPurpleDark,
  };
}

Color _archiveItemAccent(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => GameUiPalette.marketPlacementQuickAccent,
    ItemPlacement.passiveRack => GameUiPalette.marketPlacementPassiveAccent,
    ItemPlacement.inventory => GameUiPalette.marketPlacementGearAccent,
    ItemPlacement.equipped => GameUiPalette.titleDebugPurple,
  };
}

String _archiveItemSlotLabel(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-SLT',
    ItemPlacement.passiveRack => 'PSV',
    ItemPlacement.inventory => 'Tool',
    ItemPlacement.equipped => 'Gear',
  };
}

String _archiveJesterRarityKey(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.common => 'menuRarityCommon',
    RummiJesterRarity.uncommon => 'menuRarityUncommon',
    RummiJesterRarity.rare => 'menuRarityRare',
    RummiJesterRarity.legendary => 'menuRarityLegendary',
  };
}

String _archiveItemRarityKey(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => 'menuRarityCommon',
    ItemRarity.uncommon => 'menuRarityUncommon',
    ItemRarity.rare => 'menuRarityRare',
    ItemRarity.legendary => 'menuRarityLegendary',
  };
}

class _ArchiveNewTag extends StatelessWidget {
  const _ArchiveNewTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('archive-new-tag'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: GameUiPalette.actionGoldBright,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: GameUiPalette.ink.withValues(alpha: 0.4)),
      ),
      child: Text(
        context.translate('flowArchiveNew'),
        style: const TextStyle(
          color: GameUiPalette.ink,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

/// [tick]이 바뀌면 카드가 옆면(90도)에서 앞면으로 한 번 돌아 공개된다.
class _ArchiveFlipReveal extends StatefulWidget {
  const _ArchiveFlipReveal({required this.tick, required this.child});

  final int tick;
  final Widget child;

  @override
  State<_ArchiveFlipReveal> createState() => _ArchiveFlipRevealState();
}

class _ArchiveFlipRevealState extends State<_ArchiveFlipReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: GamePresentationTimings.archiveNewReveal,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant _ArchiveFlipReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick &&
        widget.tick > 0 &&
        MotionPolicy.juiceScale > 0) {
      _flip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_flip.value);
        return Transform(
          key: const ValueKey('archive-flip-reveal'),
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY((1 - t) * math.pi / 2),
          child: child,
        );
      },
    );
  }
}
