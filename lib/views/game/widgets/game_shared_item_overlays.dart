part of 'game_shared_widgets.dart';

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
    final previewMaxHeight = min(
      MediaQuery.sizeOf(context).height - 96,
      620.0,
    ).clamp(420.0, 620.0);
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
      color: GameUiPalette.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.surfaceModalInner.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: previewMaxHeight),
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
                            color: GameUiPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: GameUiPalette.textPrimary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Center(
                    child: SizedBox(
                      width: kBattleItemSlotWidth * 3,
                      height: kBattleItemSlotHeight * 3,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: kBattleItemSlotWidth,
                          height: kBattleItemSlotHeight,
                          child: Padding(
                            padding: const EdgeInsets.all(kBattleSlotCardInset),
                            child: _GameBattleItemCardFace(
                              itemSlot: itemSlot,
                              itemName: name,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    effectText,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
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
                        background: GameUiPalette.actionGold,
                        foreground: GameUiPalette.ink,
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
        color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.14),
        ),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '상점용 도구 · Market에서 조건에 따라 사용',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameUiPalette.textSecondary,
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
        color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.14),
        ),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '패시브 효과 · 조건 충족 시 자동 발동',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameUiPalette.textSecondary,
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

class GameHandTileInfoOverlay extends StatelessWidget {
  const GameHandTileInfoOverlay({
    super.key,
    required this.tile,
    required this.constrained,
    required this.bossModifier,
    required this.onClose,
  });

  final Tile tile;
  final bool constrained;
  final RummiBossModifier? bossModifier;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final modifierSummary = tileModifierSummary(tile);
    final modifierEffectText = tileModifierBadgeDescriptionText(tile);
    final hasModifier = modifierSummary.isNotEmpty;
    final baseInfoText =
        '${tileColorDisplayName(tile.color)} ${tile.number} · 기준 칩 ${tile.baseChipValue}';
    return Material(
      color: GameUiPalette.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.surfaceModalInner.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.28),
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
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: GameRummiTileCard(
                      tile: tile,
                      selected: false,
                      accent: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tile.code,
                          maxLines: 1,
                          style: const TextStyle(
                            color: GameUiPalette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasModifier ? modifierSummary : baseInfoText,
                          maxLines: 2,
                          style: TextStyle(
                            color: hasModifier
                                ? GameUiPalette.specialScoreText
                                : GameUiPalette.textPrimary.withValues(
                                    alpha: 0.62,
                                  ),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: GameUiPalette.textPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (hasModifier)
                Text(
                  modifierEffectText,
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.84),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                )
              else
                Text(
                  '$baseInfoText\n확정 점수는 완성한 족보의 기본 칩을 기준으로 계산됩니다.',
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              if (constrained && bossModifier != null) ...[
                const SizedBox(height: 10),
                _GameTileInfoConstraintCallout(modifier: bossModifier!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTileInfoConstraintCallout extends StatelessWidget {
  const _GameTileInfoConstraintCallout({required this.modifier});

  final RummiBossModifier modifier;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.bossConstraintSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GameUiPalette.actionWarning.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GameUiPalette.actionWarning.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                modifier.markerText,
                style: const TextStyle(
                  color: GameUiPalette.textOnWarm,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${modifier.title}: ${modifier.ruleText}',
                style: const TextStyle(
                  color: GameUiPalette.actionWarningText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
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
        color: GameUiPalette.ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: GameUiPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
