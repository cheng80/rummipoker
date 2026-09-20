part of 'game_shop_screen.dart';

const TextStyle _marketDescriptionTextStyle = TextStyle(
  color: GameUiPalette.textSecondary,
  fontSize: kMarketDescriptionFontSize,
  fontWeight: FontWeight.w700,
  height: kMarketDescriptionLineHeight,
);

String localizedItemName(BuildContext context, RummiMarketItemOfferView offer) {
  return ItemTranslationScope.of(
    context,
  ).resolveDisplayName(offer.contentId, offer.displayName);
}

String localizedItemEffect(
  BuildContext context,
  RummiMarketItemOfferView offer,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveEffectText(offer.contentId, offer.effectText);
}

String localizedItemSlotName(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveDisplayName(slot.contentId ?? '', slot.displayName ?? '');
}

String localizedItemSlotEffect(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveEffectText(slot.contentId ?? '', slot.effectText ?? '');
}

String _ownedItemSlotSubtitle(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  return switch (slot.placement) {
    ItemPlacement.quickSlot => context.translate('marketOwnedQuick'),
    ItemPlacement.passiveRack => context.translate('marketOwnedPassive'),
    ItemPlacement.inventory => context.translate('marketOwnedTool'),
    ItemPlacement.equipped => context.translate('marketOwnedGear'),
  };
}

String? _ownedItemSlotNotice(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  final item = slot.item;
  if (item == null) return null;
  return switch (item.effect.timing) {
    'use_market' ||
    'use_market_if_gold_lte' => context.translate('marketUseMarketManual'),
    'market_buy' => context.translate('marketNextPurchaseAuto'),
    'market_buy_if_category' => switch (item.effect.value('category')) {
      'jester' => context.translate('marketNextJesterPurchaseAuto'),
      'item' => context.translate('marketNextItemPurchaseAuto'),
      _ => context.translate('marketNextPurchaseAuto'),
    },
    'market_reroll' => context.translate('marketRerollAuto'),
    'enter_market' => context.translate('marketNextMarketAuto'),
    _ =>
      slot.placement == ItemPlacement.equipped ||
              slot.placement == ItemPlacement.passiveRack
          ? context.translate('marketConditionAuto')
          : null,
  };
}

List<String> _jesterSynergyTags(BuildContext context, RummiJesterCard card) {
  final tags = <String>[
    _jesterRarityTag(card.rarity),
    jesterCategoryLabel(card, context: context),
    _jesterConditionTag(context, card),
    _jesterEffectTag(context, card),
  ].where((tag) => tag.isNotEmpty).toList(growable: false);

  if (tags.isNotEmpty) return tags;
  return const ['Jester'];
}

String _jesterRarityTag(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.common => 'Common',
    RummiJesterRarity.uncommon => 'Uncommon',
    RummiJesterRarity.rare => 'Rare',
    RummiJesterRarity.legendary => 'Legendary',
  };
}

String _jesterConditionTag(BuildContext context, RummiJesterCard card) {
  if (card.id == 'scholar') return 'Ace';
  if (card.id == 'supernova') return context.translate('marketRepeatedHand');
  if (card.id == 'popcorn' || card.id == 'ice_cream') {
    return context.translate('marketDecreasing');
  }
  if (card.id == 'green_jester' || card.id == 'ride_the_bus') {
    return context.translate('marketGrowing');
  }

  return switch (card.conditionType) {
    'none' => context.translate('marketAlways'),
    'pair' => 'Pair',
    'two_pair' => 'Two Pair',
    'three_of_a_kind' => 'Triple',
    'straight' => 'Run',
    'flush' => 'Color',
    'tile_color_scored' =>
      card.mappedTileColors.isEmpty
          ? context.translate('marketColor')
          : context.translate('marketColorTiles'),
    'rank_scored' => context.translate('marketNumberTiles'),
    'face_card' => 'Face',
    'other' => _otherJesterConditionTag(context, card.conditionValue),
    _ => '',
  };
}

String _otherJesterConditionTag(BuildContext context, Object? value) {
  return switch (value) {
    'empty_jester_slots' => context.translate('marketEmptySlots'),
    'unused_discards' => context.translate('marketUnusedDiscards'),
    'held_hand_size' => context.translate('marketHand'),
    _ => context.translate('marketConditional'),
  };
}

String _jesterEffectTag(BuildContext context, RummiJesterCard card) {
  if (card.id == 'scholar') return context.translate('marketChipsScoreTag');
  if (card.id == 'ice_cream') return context.translate('marketChipsTag');
  if (card.effectType == 'stateful_growth') {
    return context.translate('marketScorePercentTag');
  }

  return switch (card.effectType) {
    'chips_bonus' => context.translate('marketChipsTag'),
    'mult_bonus' => context.translate('marketScorePercentTag'),
    'xmult_bonus' => context.translate('marketScoreMultiplierTag'),
    'economy' => '+Gold',
    'rule_modifier' => 'Rule',
    _ => '',
  };
}

List<String> _itemSynergyTags(BuildContext context, ItemDefinition item) {
  final tags = <String>[
    _itemRarityTag(item.rarity),
    _itemTimingTag(context, item.effect.timing),
    _itemEffectTag(context, item.effect.op),
  ].where((tag) => tag.isNotEmpty).toList();

  for (final tag in item.tags) {
    if (tags.length >= 4) break;
    final label = _catalogItemTagLabel(context, tag);
    if (label.isNotEmpty &&
        !_itemTypeCatalogTags.contains(tag) &&
        !tags.contains(label)) {
      tags.add(label);
    }
  }

  if (tags.isNotEmpty) return tags;
  return [_itemPlacementTag(item.placement)];
}

const Set<String> _itemTypeCatalogTags = {
  'consumable',
  'utility',
  'equipment',
  'relic',
};

String _itemRarityTag(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => 'Common',
    ItemRarity.uncommon => 'Uncommon',
    ItemRarity.rare => 'Rare',
    ItemRarity.legendary => 'Legendary',
  };
}

String _itemTimingTag(BuildContext context, String timing) {
  return switch (timing) {
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' => context.translate(
      'marketNextConfirm',
    ),
    'first_confirm_each_station' => context.translate('marketFirstConfirm'),
    'second_confirm_each_station' => context.translate('marketSecondConfirm'),
    'first_scored_tile_each_station' => context.translate('marketFirstTile'),
    'use_battle' => context.translate('marketBattleUse'),
    'use_market' ||
    'use_market_if_gold_lte' => context.translate('marketMarketUse'),
    'market_buy' ||
    'market_buy_if_category' => context.translate('marketPurchaseLink'),
    'market_reroll' => context.translate('marketReroll'),
    'enter_market' || 'market_build_offers' => 'Market',
    'station_start' => context.translate('marketStationStart'),
    'settlement' => context.translate('marketCashout'),
    'boss_blind_clear_reward' ||
    'boss_blind_clear_market' => context.translate('marketBossReward'),
    'inventory_capacity' => context.translate('marketSlot'),
    'expiry_guard' => context.translate('marketProtection'),
    'sell_jester' => context.translate('marketSell'),
    _ => '',
  };
}

String _itemEffectTag(BuildContext context, String op) {
  return switch (op) {
    'chips_bonus' => context.translate('marketChipsTag'),
    'mult_bonus' => context.translate('marketScorePercentTag'),
    'xmult_bonus' => context.translate('marketScoreMultiplierTag'),
    'temporary_overlap_cap_bonus' => context.translate('marketOverlapTag'),
    'gain_gold' ||
    'add_hand_rank_progress' ||
    'board_discard_reward_bonus' ||
    'hand_discard_reward_bonus' =>
      op == 'add_hand_rank_progress'
          ? context.translate('marketHandGrowth')
          : '+Gold',
    'discount_next_purchase' ||
    'free_next_reroll' ||
    'discount_first_reroll' => 'Discount',
    'add_board_discard' || 'add_hand_discard' => '+Discard',
    'extra_item_offer_slot' || 'extra_jester_offer_next_market' => 'Offer',
    'sell_price_bonus' => context.translate('marketSellBonus'),
    'rescue_first_expiry_each_station' => 'Rescue',
    'add_percent_of_first_confirm_score' => 'Echo',
    'draw_if_hand_empty' => 'Create',
    'reroll_item_offers_only' => 'Item Reroll',
    'peek_deck_discard_one' => 'Deck',
    _ => '',
  };
}

String _catalogItemTagLabel(BuildContext context, String tag) {
  return switch (tag) {
    'market' => 'Market',
    'economy' || 'gold' => '+Gold',
    'discount' => 'Discount',
    'battle' => context.translate('marketBattle'),
    'score' => 'Score',
    'chips' => context.translate('marketChipsTag'),
    'mult' => context.translate('marketScorePercentTag'),
    'xmult' => context.translate('marketScoreMultiplierTag'),
    'rank' => context.translate('marketHandRank'),
    'rank_growth' || 'planet_like' => context.translate('marketHandGrowth'),
    'straight' => 'Run',
    'flush' => 'Color',
    'two_pair' => 'Two Pair',
    'overlap' => context.translate('marketOverlapTag'),
    'discard' => 'Discard',
    'draw' => 'Draw',
    'safety' => 'Safety',
    'equipment' => 'Gear',
    'station_start' => 'Station',
    'offer' => 'Offer',
    'jester' || 'tactic' => 'Jester',
    'relic' => 'Relic',
    'boss' => 'Boss',
    'capacity' => 'Slot',
    'consumable' => 'Q-Slot',
    'rarity' => 'Rarity',
    'echo' => 'Echo',
    'utility' => 'Tool',
    'item' => 'Item',
    'comeback' => 'Comeback',
    'reroll' => 'Reroll',
    'tile_color' => context.translate('marketColor'),
    'deck' => 'Deck',
    'selection' => context.translate('marketSelect'),
    'small_hand' => context.translate('marketSmallHand'),
    'legendary' => 'Legendary',
    _ => '',
  };
}

String _itemPlacementTag(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-Slot',
    ItemPlacement.passiveRack => 'Relic',
    ItemPlacement.equipped => 'Gear',
    ItemPlacement.inventory => 'Tool',
  };
}

String _itemPlacementBadge(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q',
    ItemPlacement.passiveRack => 'P',
    ItemPlacement.equipped => 'G',
    ItemPlacement.inventory => 'T',
  };
}

String _itemPlacementCardLabel(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-SLOT',
    ItemPlacement.passiveRack => 'PASSIVE',
    ItemPlacement.equipped => 'GEAR',
    ItemPlacement.inventory => 'TOOL',
  };
}

String _lockedItemSlotOrdinal(String slotLabel) {
  final match = RegExp(r'\d+').firstMatch(slotLabel);
  final value = match == null ? null : int.tryParse(match.group(0)!);
  return switch (value) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    4 => '4th',
    5 => '5th',
    _ => slotLabel,
  };
}

LinearGradient _itemPlacementBadgeGradient(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameUiPalette.itemBadgeQuickTop,
        GameUiPalette.itemBadgeQuickBottom,
      ],
    ),
    ItemPlacement.passiveRack => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameUiPalette.itemBadgePassiveTop,
        GameUiPalette.itemBadgePassiveBottom,
      ],
    ),
    ItemPlacement.equipped => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameUiPalette.itemBadgeGearTop,
        GameUiPalette.itemBadgeGearBottom,
      ],
    ),
    ItemPlacement.inventory => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameUiPalette.itemBadgeToolTop,
        GameUiPalette.itemBadgeToolBottom,
      ],
    ),
  };
}

Color _itemOfferSurface(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => GameUiPalette.marketPlacementQuickSurface,
    ItemPlacement.passiveRack => GameUiPalette.marketPlacementPassiveSurface,
    ItemPlacement.equipped => GameUiPalette.marketPlacementGearSurface,
    ItemPlacement.inventory => GameUiPalette.marketPlacementToolSurface,
  };
}

Color _itemOfferAccent(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => GameUiPalette.marketPlacementQuickAccent,
    ItemPlacement.passiveRack => GameUiPalette.marketPlacementPassiveAccent,
    ItemPlacement.equipped => GameUiPalette.marketPlacementGearAccent,
    ItemPlacement.inventory => GameUiPalette.marketPlacementToolAccent,
  };
}
