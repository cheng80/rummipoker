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

String _ownedItemSlotSubtitle(RummiMarketItemSlotView slot) {
  return switch (slot.placement) {
    ItemPlacement.quickSlot => 'Q-Slot 보유',
    ItemPlacement.passiveRack => 'Passive 보유',
    ItemPlacement.inventory => 'Tool 보유',
    ItemPlacement.equipped => 'Gear 보유',
  };
}

String? _ownedItemSlotNotice(RummiMarketItemSlotView slot) {
  final item = slot.item;
  if (item == null) return null;
  return switch (item.effect.timing) {
    'use_market' || 'use_market_if_gold_lte' => '상점에서 수동 사용',
    'market_buy' => '다음 구매 시 자동 적용',
    'market_buy_if_category' => switch (item.effect.value('category')) {
      'jester' => '다음 Jester 구매 시 자동 적용',
      'item' => '다음 Item 구매 시 자동 적용',
      _ => '다음 구매 시 자동 적용',
    },
    'market_reroll' => '리롤 버튼 사용 시 자동 적용',
    'enter_market' => '다음 Market 진입 시 자동 적용',
    _ =>
      slot.placement == ItemPlacement.equipped ||
              slot.placement == ItemPlacement.passiveRack
          ? '조건 충족 시 자동 발동'
          : null,
  };
}

List<String> _jesterSynergyTags(RummiJesterCard card) {
  final tags = <String>[
    _jesterRarityTag(card.rarity),
    jesterCategoryLabel(card),
    _jesterConditionTag(card),
    _jesterEffectTag(card),
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

String _jesterConditionTag(RummiJesterCard card) {
  if (card.id == 'scholar') return 'Ace';
  if (card.id == 'supernova') return '반복 족보';
  if (card.id == 'popcorn' || card.id == 'ice_cream') return '줄어듦';
  if (card.id == 'green_jester' || card.id == 'ride_the_bus') return '성장형';

  return switch (card.conditionType) {
    'none' => '상시',
    'pair' => 'Pair',
    'two_pair' => 'Two Pair',
    'three_of_a_kind' => 'Triple',
    'straight' => 'Run',
    'flush' => 'Color',
    'tile_color_scored' => card.mappedTileColors.isEmpty ? '색상' : '색상 타일',
    'rank_scored' => '숫자 타일',
    'face_card' => 'Face',
    'other' => _otherJesterConditionTag(card.conditionValue),
    _ => '',
  };
}

String _otherJesterConditionTag(Object? value) {
  return switch (value) {
    'empty_jester_slots' => '빈 슬롯',
    'unused_discards' => '미사용 버림',
    'held_hand_size' => '손패',
    _ => '조건부',
  };
}

String _jesterEffectTag(RummiJesterCard card) {
  if (card.id == 'scholar') return '+칩/+점수%';
  if (card.id == 'ice_cream') return '+칩';
  if (card.effectType == 'stateful_growth') return '+점수%';

  return switch (card.effectType) {
    'chips_bonus' => '+칩',
    'mult_bonus' => '+점수%',
    'xmult_bonus' => '점수 x',
    'economy' => '+Gold',
    'rule_modifier' => 'Rule',
    _ => '',
  };
}

List<String> _itemSynergyTags(ItemDefinition item) {
  final tags = <String>[
    _itemRarityTag(item.rarity),
    _itemTimingTag(item.effect.timing),
    _itemEffectTag(item.effect.op),
  ].where((tag) => tag.isNotEmpty).toList();

  for (final tag in item.tags) {
    if (tags.length >= 4) break;
    final label = _catalogItemTagLabel(tag);
    if (label.isNotEmpty &&
        !_itemTypeTagLabels.contains(label) &&
        !tags.contains(label)) {
      tags.add(label);
    }
  }

  if (tags.isNotEmpty) return tags;
  return [_itemPlacementTag(item.placement)];
}

const Set<String> _itemTypeTagLabels = {'Q-Slot', 'Tool', 'Gear', 'Relic'};

String _itemRarityTag(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => 'Common',
    ItemRarity.uncommon => 'Uncommon',
    ItemRarity.rare => 'Rare',
    ItemRarity.legendary => 'Legendary',
  };
}

String _itemTimingTag(String timing) {
  return switch (timing) {
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' => '다음 확정',
    'first_confirm_each_station' => '첫 확정',
    'second_confirm_each_station' => '두번째 확정',
    'first_scored_tile_each_station' => '첫 타일',
    'use_battle' => '전투 사용',
    'use_market' || 'use_market_if_gold_lte' => '상점 사용',
    'market_buy' || 'market_buy_if_category' => '구매 연계',
    'market_reroll' => '리롤',
    'enter_market' || 'market_build_offers' => 'Market',
    'station_start' => 'Station 시작',
    'settlement' => '정산',
    'boss_blind_clear_reward' || 'boss_blind_clear_market' => 'Boss 보상',
    'inventory_capacity' => '슬롯',
    'expiry_guard' => '보호',
    'sell_jester' => '판매',
    _ => '',
  };
}

String _itemEffectTag(String op) {
  return switch (op) {
    'chips_bonus' => '+칩',
    'mult_bonus' => '+점수%',
    'xmult_bonus' => '점수 x',
    'temporary_overlap_cap_bonus' => 'Overlap',
    'gain_gold' ||
    'add_hand_rank_progress' ||
    'board_discard_reward_bonus' ||
    'hand_discard_reward_bonus' =>
      op == 'add_hand_rank_progress' ? '족보 성장' : '+Gold',
    'discount_next_purchase' ||
    'free_next_reroll' ||
    'discount_first_reroll' => 'Discount',
    'add_board_discard' || 'add_hand_discard' => '+Discard',
    'extra_item_offer_slot' || 'extra_jester_offer_next_market' => 'Offer',
    'sell_price_bonus' => '판매 보너스',
    'rescue_first_expiry_each_station' => 'Rescue',
    'add_percent_of_first_confirm_score' => 'Echo',
    'draw_if_hand_empty' => 'Create',
    'reroll_item_offers_only' => 'Item Reroll',
    'peek_deck_discard_one' => 'Deck',
    _ => '',
  };
}

String _catalogItemTagLabel(String tag) {
  return switch (tag) {
    'market' => 'Market',
    'economy' || 'gold' => '+Gold',
    'discount' => 'Discount',
    'battle' => '전투',
    'score' => 'Score',
    'chips' => '+칩',
    'mult' => '+점수%',
    'xmult' => '점수 x',
    'rank' => '족보',
    'rank_growth' || 'planet_like' => '족보 성장',
    'straight' => 'Run',
    'flush' => 'Color',
    'two_pair' => 'Two Pair',
    'overlap' => 'Overlap',
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
    'tile_color' => '색상',
    'deck' => 'Deck',
    'selection' => '선택',
    'small_hand' => '작은 손패',
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
