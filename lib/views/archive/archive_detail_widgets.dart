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
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            color: GameUiPalette.textPrimary.withValues(alpha: 0.66),
            tooltip: '접기',
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
      title: collected ? card.title : '아직 얻지 못한 기억 카드',
      subtitle: '${status.label} · 기억 카드',
      body: collected
          ? '게임오버나 런 완료 후 얻는 보상 카드입니다. 다음 런 준비에서 새 규칙을 여는 데 사용됩니다.'
          : '이 칸은 아직 비어 있습니다. 런을 더 진행하면 기억 카드가 여기에 채워집니다.',
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
      title: collected ? card.displayName : '아직 만나지 못한 Jester',
      subtitle: collected
          ? '${status.label} · ${_archiveJesterRarityLabel(card.rarity)}'
          : '${status.label} · Jester',
      body: collected
          ? card.effectText
          : '이 칸은 아직 비어 있습니다. 마켓에서 만나거나 구매한 Jester가 여기에 채워집니다.',
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
      title: collected ? item.displayName : '아직 만나지 못한 Item',
      subtitle: collected
          ? '${status.label} · ${_archiveItemSlotLabel(item.placement)} · ${_archiveItemRarityLabel(item.rarity)}'
          : '${status.label} · Item',
      body: collected
          ? item.effectText
          : '이 칸은 아직 비어 있습니다. 마켓에서 만나거나 구매한 아이템이 여기에 채워집니다.',
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
        Text(
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
    required this.width,
    required this.height,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final _ArchiveCollectionStatus status;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
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
                child: child,
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
}

class _ArchiveStatusBadge extends StatelessWidget {
  const _ArchiveStatusBadge({required this.status, required this.width});

  final _ArchiveCollectionStatus status;
  final double width;

  static const double height = 14;

  @override
  Widget build(BuildContext context) {
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
        status.label,
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
                  card.title,
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
            _ArchiveItemBadge(label: card.badge),
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
                  item.displayName,
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

String _archiveJesterRarityLabel(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.common => '일반',
    RummiJesterRarity.uncommon => '희귀',
    RummiJesterRarity.rare => '레어',
    RummiJesterRarity.legendary => '전설',
  };
}

String _archiveItemRarityLabel(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => '일반',
    ItemRarity.uncommon => '희귀',
    ItemRarity.rare => '레어',
    ItemRarity.legendary => '전설',
  };
}
