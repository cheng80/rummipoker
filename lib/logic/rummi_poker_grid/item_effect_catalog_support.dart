part of 'item_effect_runtime.dart';

ItemEffectCatalogRow _catalogRowFor(ItemDefinition item) {
  final timing = item.effect.timing;
  final op = item.effect.op;
  final handlerName = _handlerNameFor(timing);
  final status = switch ('$timing:$op') {
    'use_battle:add_board_discard' ||
    'use_battle:add_hand_discard' ||
    'use_battle:add_board_move' ||
    'use_battle:mark_next_board_move_bonus' ||
    'use_battle:undo_last_board_move' ||
    'use_battle:peek_deck_discard_one' ||
    'use_battle:draw_if_hand_empty' ||
    'use_battle:increase_hand_size' ||
    'use_battle:add_hand_rank_progress_from_selected_line' ||
    'use_battle:ritual_line_effect' ||
    'market_reroll:free_next_reroll' ||
    'market_reroll:discount_next_reroll' ||
    'market_buy:discount_next_purchase' ||
    'market_buy_if_category:discount_next_purchase' ||
    'use_market:gain_gold' ||
    'use_market:add_hand_rank_progress' ||
    'use_market:reroll_item_offers_only' ||
    'use_market_if_gold_lte:gain_gold' ||
    'enter_market:gain_gold' ||
    'enter_market:discount_first_reroll' ||
    'enter_market:discount_cheapest_first_offer' ||
    'market_build_offers:extra_item_offer_slot' ||
    'boss_blind_clear_reward:gain_gold' ||
    'boss_blind_clear_market:extra_jester_offer_next_market' ||
    'settlement:board_discard_reward_bonus' ||
    'settlement:hand_discard_reward_bonus' ||
    'next_confirm:chips_bonus' ||
    'next_confirm:mult_bonus' ||
    'next_confirm:xmult_bonus' ||
    'next_confirm:temporary_overlap_cap_bonus' ||
    'next_confirm_if_rank:chips_bonus' ||
    'next_confirm_if_rank_at_least:chips_bonus' ||
    'next_confirm_if_rank_at_least:mult_bonus' ||
    'next_confirm_per_tile_color:mult_bonus' ||
    'next_confirm_per_repeated_rank_tile:chips_bonus' ||
    'first_confirm_each_station:chips_bonus' ||
    'first_scored_tile_each_station:chips_bonus' ||
    'on_confirm_if_played_hand_size_lte:mult_bonus' ||
    'second_confirm_each_station:add_percent_of_first_confirm_score' ||
    'station_start:add_board_discard' ||
    'station_start:add_hand_discard' ||
    'station_start:add_board_move' ||
    'station_start:increase_hand_size_with_discard_penalty' ||
    'inventory_capacity:increase_hand_size' ||
    'sell_jester:sell_price_bonus' ||
    'expiry_guard:rescue_first_expiry_each_station' =>
      ItemEffectApplicationStatus.applied,
    _ => ItemEffectApplicationStatus.pendingHook,
  };
  return ItemEffectCatalogRow(
    itemId: item.id,
    timing: timing,
    op: op,
    status: status,
    handlerName: handlerName,
  );
}

RummiConfirmModifier? _buildConfirmModifier(ItemDefinition item) {
  final timing = item.effect.timing;
  final op = item.effect.op;
  if (_handlerNameFor(timing) != 'applyConfirmModifierItem') {
    return null;
  }
  if (!_supportedConfirmOps.contains(op)) {
    return null;
  }
  final amount = (item.effect.value('amount') as num?)?.toDouble() ?? 0;
  final percent = (item.effect.value('percent') as num?)?.toDouble() ?? 0;
  return RummiConfirmModifier(
    itemId: item.id,
    timing: timing,
    op: op,
    amount: amount,
    percent: percent,
    rank: _parseRank(item.effect.value('rank')),
    tileColor: _parseTileColor(item.effect.value('tileColor')),
    maxTiles: (item.effect.value('maxTiles') as num?)?.toInt(),
    consumeOnApply:
        item.effect.consume || _oneShotConfirmTimings.contains(timing),
  );
}

const Set<String> _supportedConfirmOps = {
  'chips_bonus',
  'mult_bonus',
  'xmult_bonus',
  'temporary_overlap_cap_bonus',
  'add_percent_of_first_confirm_score',
};

const Set<String> _oneShotConfirmTimings = {
  'next_confirm',
  'next_confirm_if_rank',
  'next_confirm_if_rank_at_least',
  'next_confirm_per_tile_color',
  'next_confirm_per_repeated_rank_tile',
  'first_confirm_each_station',
  'first_scored_tile_each_station',
  'second_confirm_each_station',
};

RummiHandRank? _parseRank(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'twoPair' => RummiHandRank.twoPair,
    'threeOfAKind' => RummiHandRank.threeOfAKind,
    'straight' => RummiHandRank.straight,
    'flush' => RummiHandRank.flush,
    'fullHouse' => RummiHandRank.fullHouse,
    'fourOfAKind' => RummiHandRank.fourOfAKind,
    'straightFlush' => RummiHandRank.straightFlush,
    'prismStraight' => RummiHandRank.prismStraight,
    'crownFourOfAKind' => RummiHandRank.crownFourOfAKind,
    'lowStraightFlush' => RummiHandRank.lowStraightFlush,
    'royalStraightFlush' => RummiHandRank.royalStraightFlush,
    'fiveOfAKind' => RummiHandRank.fiveOfAKind,
    _ => null,
  };
}

TileColor? _parseTileColor(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'red' => TileColor.red,
    'blue' => TileColor.blue,
    'yellow' => TileColor.yellow,
    'black' => TileColor.black,
    _ => null,
  };
}

String _handlerNameFor(String timing) {
  return switch (timing) {
    'use_battle' => 'useBattleItem',
    'use_market' || 'use_market_if_gold_lte' => 'applyMarketUseItem',
    'market_reroll' => 'applyMarketRerollItem',
    'market_buy' || 'market_buy_if_category' => 'applyMarketBuyItem',
    'station_start' => 'applyStationStartItem',
    'enter_market' => 'applyEnterMarketItem',
    'settlement' => 'applySettlementItem',
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' ||
    'first_confirm_each_station' ||
    'first_scored_tile_each_station' ||
    'on_confirm_if_played_hand_size_lte' ||
    'second_confirm_each_station' => 'applyConfirmModifierItem',
    'boss_blind_clear_reward' ||
    'boss_blind_clear_market' => 'applyBossClearItem',
    'inventory_capacity' => 'applyInventoryCapacityItem',
    'sell_jester' => 'applySellJesterItem',
    'expiry_guard' => 'applyExpiryGuardItem',
    'market_build_offers' => 'applyEnterMarketItem',
    _ => 'unassignedItemEffectHandler',
  };
}
