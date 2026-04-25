import 'item_definition.dart';
import 'hand_rank.dart';
import 'jester_meta.dart';
import 'models/tile.dart';
import 'rummi_poker_grid_session.dart';

enum ItemEffectApplicationStatus { applied, pendingHook, rejected }

enum ItemEffectEventKind {
  boardDiscardAdded,
  boardDiscardRemoved,
  handDiscardAdded,
  handDiscardRemoved,
  boardMoveAdded,
  boardMoveUndone,
  maxHandSizeIncreased,
  tileDrawn,
  deckTileDiscarded,
  goldGained,
  itemConsumed,
  nextConfirmModifierQueued,
  marketModifierQueued,
  settlementModifierQueued,
  capacityModifierQueued,
  bossModifierQueued,
  interactionRequired,
}

class ItemEffectEvent {
  const ItemEffectEvent({
    required this.kind,
    required this.itemId,
    this.amount = 0,
    this.detail,
  });

  final ItemEffectEventKind kind;
  final String itemId;
  final num amount;
  final String? detail;
}

class ItemUseResult {
  const ItemUseResult._({
    required this.itemId,
    required this.status,
    required this.events,
    this.failMessage,
  });

  factory ItemUseResult.success({
    required String itemId,
    required List<ItemEffectEvent> events,
  }) {
    return ItemUseResult._(
      itemId: itemId,
      status: ItemEffectApplicationStatus.applied,
      events: List<ItemEffectEvent>.unmodifiable(events),
    );
  }

  factory ItemUseResult.pendingHook({
    required String itemId,
    required String message,
    List<ItemEffectEvent> events = const [],
  }) {
    return ItemUseResult._(
      itemId: itemId,
      status: ItemEffectApplicationStatus.pendingHook,
      events: List<ItemEffectEvent>.unmodifiable(events),
      failMessage: message,
    );
  }

  factory ItemUseResult.failure({
    required String itemId,
    required String message,
  }) {
    return ItemUseResult._(
      itemId: itemId,
      status: ItemEffectApplicationStatus.rejected,
      events: const [],
      failMessage: message,
    );
  }

  final String itemId;
  final ItemEffectApplicationStatus status;
  final List<ItemEffectEvent> events;
  final String? failMessage;

  bool get isSuccess => status == ItemEffectApplicationStatus.applied;
  bool get isPending => status == ItemEffectApplicationStatus.pendingHook;
}

class ItemEffectCatalogRow {
  const ItemEffectCatalogRow({
    required this.itemId,
    required this.timing,
    required this.op,
    required this.status,
    required this.handlerName,
  });

  final String itemId;
  final String timing;
  final String op;
  final ItemEffectApplicationStatus status;
  final String handlerName;

  String get key => '$timing:$op';
}

class ItemEffectRuntime {
  const ItemEffectRuntime._();

  static List<ItemEffectCatalogRow> catalogEffectRows(ItemCatalog catalog) {
    return catalog.all.map(_catalogRowFor).toList(growable: false);
  }

  static ItemUseResult useBattleItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    final validationMessage = _validateBattleUse(item, runProgress);
    if (validationMessage != null) {
      return ItemUseResult.failure(itemId: item.id, message: validationMessage);
    }

    final events = <ItemEffectEvent>[];
    switch (item.effect.op) {
      case 'add_board_discard':
        final applied = _applyAddBoardDiscard(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'add_hand_discard':
        final applied = _applyAddHandDiscard(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'add_board_move':
        final applied = _applyAddBoardMove(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'undo_last_board_move':
        final applied = _applyUndoLastBoardMove(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'draw_if_hand_empty':
        final applied = _applyDrawIfHandEmpty(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'chips_bonus':
      case 'mult_bonus':
      case 'xmult_bonus':
      case 'temporary_overlap_cap_bonus':
      case 'add_percent_of_first_confirm_score':
        final applied = applyConfirmModifierItem(
          item: item,
          session: session,
          runProgress: runProgress,
        );
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'peek_deck_discard_one':
        return ItemUseResult.pendingHook(
          itemId: item.id,
          message: '버릴 덱 타일 선택이 필요합니다.',
          events: [
            ItemEffectEvent(
              kind: ItemEffectEventKind.interactionRequired,
              itemId: item.id,
              amount: (item.effect.value('draw') as num?) ?? 0,
              detail: 'peek_deck_discard_one',
            ),
          ],
        );
      default:
        return ItemUseResult.pendingHook(
          itemId: item.id,
          message: '아직 연결되지 않은 아이템 효과입니다.',
        );
    }

    _consumeIfNeeded(item, runProgress, events);
    return ItemUseResult.success(itemId: item.id, events: events);
  }

  static ItemUseResult applyMarketUseItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    final validationMessage = _validateMarketUse(item, runProgress);
    if (validationMessage != null) {
      return ItemUseResult.failure(itemId: item.id, message: validationMessage);
    }
    final result = switch (item.effect.op) {
      'gain_gold' => _applyGainGold(item, runProgress),
      _ => _pendingHook(item, 'applyMarketUseItem'),
    };
    if (!result.isSuccess) return result;
    final events = <ItemEffectEvent>[...result.events];
    _consumeIfNeeded(item, runProgress, events);
    return ItemUseResult.success(itemId: item.id, events: events);
  }

  static ItemUseResult useBattleDeckPeekDiscardItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required int topIndex,
  }) {
    if (item.effect.op != 'peek_deck_discard_one') {
      return ItemUseResult.failure(itemId: item.id, message: '덱 확인 아이템이 아닙니다.');
    }
    final windowSize =
        _positiveIntValue(item, 'lookAt') ??
        _positiveIntValue(item, 'peek') ??
        3;
    final discarded = session.discardFromDeckTopWindow(
      topIndex: topIndex,
      windowSize: windowSize,
    );
    if (discarded == null) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '버릴 덱 타일을 찾지 못했습니다.',
      );
    }
    final events = <ItemEffectEvent>[
      ItemEffectEvent(
        kind: ItemEffectEventKind.deckTileDiscarded,
        itemId: item.id,
        amount: 1,
        detail: discarded.code,
      ),
    ];
    return ItemUseResult.success(itemId: item.id, events: events);
  }

  static ItemUseResult consumeBattleDeckPeekItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    final validationMessage = _validateBattleUse(item, runProgress);
    if (validationMessage != null) {
      return ItemUseResult.failure(itemId: item.id, message: validationMessage);
    }
    if (item.effect.op != 'peek_deck_discard_one') {
      return ItemUseResult.failure(itemId: item.id, message: '덱 확인 아이템이 아닙니다.');
    }
    final windowSize =
        _positiveIntValue(item, 'lookAt') ??
        _positiveIntValue(item, 'peek') ??
        3;
    if (session.peekDeckTop(windowSize).isEmpty) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '덱에 확인할 타일이 없습니다.',
      );
    }
    final events = <ItemEffectEvent>[
      ItemEffectEvent(
        kind: ItemEffectEventKind.interactionRequired,
        itemId: item.id,
        amount: windowSize,
        detail: 'peek_deck_discard_one',
      ),
    ];
    _consumeIfNeeded(item, runProgress, events);
    return ItemUseResult.success(itemId: item.id, events: events);
  }

  static ItemUseResult applyMarketRerollItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    final result = _applyMarketModifier(item, runProgress);
    if (result.isSuccess) {
      final events = <ItemEffectEvent>[...result.events];
      _consumeIfNeeded(item, runProgress, events);
      return ItemUseResult.success(itemId: item.id, events: events);
    }
    return result;
  }

  static ItemUseResult applyMarketBuyItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    final result = _applyMarketModifier(item, runProgress);
    if (result.isSuccess) {
      final events = <ItemEffectEvent>[...result.events];
      _consumeIfNeeded(item, runProgress, events);
      return ItemUseResult.success(itemId: item.id, events: events);
    }
    return result;
  }

  static ItemUseResult applyStationStartItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
  }) {
    return switch (item.effect.op) {
      'add_board_discard' => _applyAddBoardDiscard(item, session),
      'add_hand_discard' => _applyAddHandDiscard(item, session),
      'add_board_move' => _applyAddBoardMove(item, session),
      'increase_hand_size_with_discard_penalty' =>
        _applyIncreaseHandSizeWithDiscardPenalty(item, session),
      _ => _pendingHook(item, 'applyStationStartItem'),
    };
  }

  static ItemUseResult applyEnterMarketItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    if (item.effect.op == 'gain_gold') {
      return _applyGainGold(item, runProgress);
    }
    return _applyMarketModifier(item, runProgress);
  }

  static ItemUseResult applySettlementItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    switch (item.effect.op) {
      case 'board_discard_reward_bonus':
      case 'hand_discard_reward_bonus':
        return ItemUseResult.success(
          itemId: item.id,
          events: [
            ItemEffectEvent(
              kind: ItemEffectEventKind.settlementModifierQueued,
              itemId: item.id,
              amount: amount,
              detail: item.effect.op,
            ),
          ],
        );
    }
    return _pendingHook(item, 'applySettlementItem');
  }

  static ItemUseResult applyConfirmModifierItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    final modifier = _buildConfirmModifier(item);
    if (modifier == null) {
      return _pendingHook(item, 'applyConfirmModifierItem');
    }
    session.addConfirmModifier(modifier);
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.nextConfirmModifierQueued,
          itemId: item.id,
          amount: modifier.amount == 0 ? modifier.percent : modifier.amount,
          detail: '${modifier.timing}:${modifier.op}',
        ),
      ],
    );
  }

  static ItemUseResult applyBossClearItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return switch (item.effect.op) {
      'gain_gold' => _applyGainGold(item, runProgress),
      _ => _pendingHook(item, 'applyBossClearItem'),
    };
  }

  static ItemUseResult applyInventoryCapacityItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    return switch (item.effect.op) {
      'increase_hand_size' => _applyIncreaseHandSize(item, session),
      'extra_quick_slot' => _applyCapacityModifier(item),
      _ => _pendingHook(item, 'applyInventoryCapacityItem'),
    };
  }

  static List<ItemUseResult> applyOwnedStationStartItems({
    required ItemCatalog catalog,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    final activeIds = <String>{
      for (final entry in runProgress.itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final results = <ItemUseResult>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null) continue;
      switch (item.effect.timing) {
        case 'station_start':
          results.add(applyStationStartItem(item: item, session: session));
          if (results.last.isSuccess && item.effect.consume) {
            runProgress.itemInventory = runProgress.itemInventory
                .withConsumedItem(item.id);
          }
          break;
        case 'inventory_capacity':
          results.add(
            applyInventoryCapacityItem(
              item: item,
              session: session,
              runProgress: runProgress,
            ),
          );
          if (results.last.isSuccess && item.effect.consume) {
            runProgress.itemInventory = runProgress.itemInventory
                .withConsumedItem(item.id);
          }
          break;
        case 'next_confirm':
        case 'next_confirm_if_rank':
        case 'next_confirm_if_rank_at_least':
        case 'next_confirm_per_tile_color':
        case 'next_confirm_per_repeated_rank_tile':
        case 'first_confirm_each_station':
        case 'first_scored_tile_each_station':
        case 'on_confirm_if_played_hand_size_lte':
        case 'second_confirm_each_station':
          if (item.placement == ItemPlacement.quickSlot) {
            break;
          }
          results.add(
            applyConfirmModifierItem(
              item: item,
              session: session,
              runProgress: runProgress,
            ),
          );
          if (results.last.isSuccess && item.effect.consume) {
            runProgress.itemInventory = runProgress.itemInventory
                .withConsumedItem(item.id);
          }
          break;
      }
    }
    return List<ItemUseResult>.unmodifiable(results);
  }

  static List<ItemUseResult> applyOwnedEnterMarketItems({
    required ItemCatalog catalog,
    required RummiRunProgress runProgress,
  }) {
    final activeIds = <String>{
      for (final entry in runProgress.itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final results = <ItemUseResult>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null) continue;
      switch (item.effect.timing) {
        case 'enter_market':
        case 'market_build_offers':
          if (item.placement == ItemPlacement.quickSlot) {
            break;
          }
          results.add(
            applyEnterMarketItem(item: item, runProgress: runProgress),
          );
          if (results.last.isSuccess && item.effect.consume) {
            runProgress.itemInventory = runProgress.itemInventory
                .withConsumedItem(item.id);
          }
          break;
      }
    }
    return List<ItemUseResult>.unmodifiable(results);
  }

  static List<ItemUseResult> applyOwnedBossClearItems({
    required ItemCatalog catalog,
    required RummiRunProgress runProgress,
  }) {
    final activeIds = <String>{
      for (final entry in runProgress.itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final results = <ItemUseResult>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null) continue;
      switch (item.effect.timing) {
        case 'boss_blind_clear_reward':
        case 'boss_blind_clear_market':
          if (item.placement == ItemPlacement.quickSlot) {
            break;
          }
          results.add(applyBossClearItem(item: item, runProgress: runProgress));
          if (results.last.isSuccess && item.effect.consume) {
            runProgress.itemInventory = runProgress.itemInventory
                .withConsumedItem(item.id);
          }
          break;
      }
    }
    return List<ItemUseResult>.unmodifiable(results);
  }

  static ItemUseResult applySellJesterItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return switch (item.effect.op) {
      'sell_price_bonus' => _applySellJesterModifier(item),
      _ => _pendingHook(item, 'applySellJesterItem'),
    };
  }

  static ItemUseResult applyFailedConfirmItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyFailedConfirmItem');
  }

  static ItemEffectCatalogRow _catalogRowFor(ItemDefinition item) {
    final timing = item.effect.timing;
    final op = item.effect.op;
    final handlerName = _handlerNameFor(timing);
    final status = switch ('$timing:$op') {
      'use_battle:add_board_discard' ||
      'use_battle:add_hand_discard' ||
      'use_battle:add_board_move' ||
      'use_battle:undo_last_board_move' ||
      'use_battle:peek_deck_discard_one' ||
      'use_battle:draw_if_hand_empty' ||
      'market_reroll:discount_next_reroll' ||
      'market_buy:discount_next_purchase' ||
      'market_buy_if_category:discount_next_purchase' ||
      'use_market:gain_gold' ||
      'use_market_if_gold_lte:gain_gold' ||
      'enter_market:gain_gold' ||
      'enter_market:discount_first_reroll' ||
      'enter_market:discount_cheapest_first_offer' ||
      'market_build_offers:extra_item_offer_slot' ||
      'market_build_offers:rarity_weight_bonus' ||
      'boss_blind_clear_reward:gain_gold' ||
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
      'inventory_capacity:extra_quick_slot' ||
      'sell_jester:sell_price_bonus' => ItemEffectApplicationStatus.applied,
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

  static RummiConfirmModifier? _buildConfirmModifier(ItemDefinition item) {
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

  static const Set<String> _supportedConfirmOps = {
    'chips_bonus',
    'mult_bonus',
    'xmult_bonus',
    'temporary_overlap_cap_bonus',
    'add_percent_of_first_confirm_score',
  };

  static const Set<String> _oneShotConfirmTimings = {
    'next_confirm',
    'next_confirm_if_rank',
    'next_confirm_if_rank_at_least',
    'next_confirm_per_tile_color',
    'next_confirm_per_repeated_rank_tile',
    'first_confirm_each_station',
    'first_scored_tile_each_station',
    'second_confirm_each_station',
  };

  static RummiHandRank? _parseRank(Object? value) {
    if (value is! String) return null;
    return switch (value) {
      'twoPair' => RummiHandRank.twoPair,
      'threeOfAKind' => RummiHandRank.threeOfAKind,
      'straight' => RummiHandRank.straight,
      'flush' => RummiHandRank.flush,
      'fullHouse' => RummiHandRank.fullHouse,
      'fourOfAKind' => RummiHandRank.fourOfAKind,
      'straightFlush' => RummiHandRank.straightFlush,
      _ => null,
    };
  }

  static TileColor? _parseTileColor(Object? value) {
    if (value is! String) return null;
    return switch (value) {
      'red' => TileColor.red,
      'blue' => TileColor.blue,
      'yellow' => TileColor.yellow,
      'black' => TileColor.black,
      _ => null,
    };
  }

  static String _handlerNameFor(String timing) {
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
      'failed_confirm' => 'applyFailedConfirmItem',
      'market_build_offers' => 'applyEnterMarketItem',
      _ => 'unassignedItemEffectHandler',
    };
  }

  static ItemUseResult _applyAddBoardDiscard(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    session.blind.boardDiscardsRemaining += amount;
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardDiscardAdded,
          itemId: item.id,
          amount: amount,
        ),
      ],
    );
  }

  static ItemUseResult _applyMarketModifier(
    ItemDefinition item,
    RummiRunProgress runProgress,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    final category = item.effect.value('category') as String?;
    switch (item.effect.op) {
      case 'discount_next_reroll':
      case 'discount_first_reroll':
      case 'discount_next_purchase':
      case 'discount_cheapest_first_offer':
      case 'extra_item_offer_slot':
      case 'rarity_weight_bonus':
        runProgress.queueMarketModifier(
          op: item.effect.op,
          amount: amount,
          category: category,
        );
        return ItemUseResult.success(
          itemId: item.id,
          events: [
            ItemEffectEvent(
              kind: ItemEffectEventKind.marketModifierQueued,
              itemId: item.id,
              amount: amount,
              detail: category == null
                  ? item.effect.op
                  : '${item.effect.op}:$category',
            ),
          ],
        );
    }
    return _pendingHook(item, 'applyMarketModifier');
  }

  static ItemUseResult _applyCapacityModifier(ItemDefinition item) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.capacityModifierQueued,
          itemId: item.id,
          amount: amount,
          detail: item.effect.op,
        ),
      ],
    );
  }

  static ItemUseResult _applySellJesterModifier(ItemDefinition item) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.marketModifierQueued,
          itemId: item.id,
          amount: amount,
          detail: item.effect.op,
        ),
      ],
    );
  }

  static ItemUseResult _applyGainGold(
    ItemDefinition item,
    RummiRunProgress runProgress,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    runProgress.gold += amount;
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.goldGained,
          itemId: item.id,
          amount: amount,
        ),
      ],
    );
  }

  static ItemUseResult _applyAddHandDiscard(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    session.blind.handDiscardsRemaining += amount;
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.handDiscardAdded,
          itemId: item.id,
          amount: amount,
        ),
      ],
    );
  }

  static ItemUseResult _applyAddBoardMove(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    session.blind.boardMovesRemaining += amount;
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardMoveAdded,
          itemId: item.id,
          amount: amount,
        ),
      ],
    );
  }

  static ItemUseResult _applyDrawIfHandEmpty(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    if (session.hand.isNotEmpty) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '손패가 비어 있을 때만 사용할 수 있습니다.',
      );
    }
    var drawn = 0;
    for (var i = 0; i < amount; i++) {
      final tile = session.drawToHand();
      if (tile == null) break;
      drawn += 1;
    }
    if (drawn <= 0) {
      return ItemUseResult.failure(itemId: item.id, message: '드로우에 실패했습니다.');
    }
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.tileDrawn,
          itemId: item.id,
          amount: drawn,
        ),
      ],
    );
  }

  static ItemUseResult _applyUndoLastBoardMove(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final fail = session.undoLastBoardMove();
    if (fail != null) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: switch (fail) {
          BoardMoveUndoFailReason.noMoveHistory => '되돌릴 보드 이동이 없습니다.',
          BoardMoveUndoFailReason.sourceOccupied => '이동 전 칸이 비어 있지 않습니다.',
          BoardMoveUndoFailReason.destinationEmpty => '이동한 타일을 찾지 못했습니다.',
        },
      );
    }
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardMoveUndone,
          itemId: item.id,
          amount: 1,
        ),
      ],
    );
  }

  static ItemUseResult _applyIncreaseHandSize(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final amount = _positiveIntAmount(item);
    if (amount == null) return _invalidAmount(item);
    session.maxHandSize += amount;
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.maxHandSizeIncreased,
          itemId: item.id,
          amount: amount,
        ),
      ],
    );
  }

  static ItemUseResult _applyIncreaseHandSizeWithDiscardPenalty(
    ItemDefinition item,
    RummiPokerGridSession session,
  ) {
    final base = _applyIncreaseHandSize(item, session);
    if (!base.isSuccess) return base;

    final events = <ItemEffectEvent>[...base.events];
    final boardPenalty = _nonNegativeIntValue(item, 'boardDiscardPenalty');
    if (boardPenalty > 0) {
      final removed = boardPenalty.clamp(
        0,
        session.blind.boardDiscardsRemaining,
      );
      session.blind.boardDiscardsRemaining -= removed;
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardDiscardRemoved,
          itemId: item.id,
          amount: removed,
        ),
      );
    }

    final handPenalty = _nonNegativeIntValue(item, 'handDiscardPenalty');
    if (handPenalty > 0) {
      final removed = handPenalty.clamp(0, session.blind.handDiscardsRemaining);
      session.blind.handDiscardsRemaining -= removed;
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.handDiscardRemoved,
          itemId: item.id,
          amount: removed,
        ),
      );
    }

    return ItemUseResult.success(itemId: item.id, events: events);
  }

  static void _consumeIfNeeded(
    ItemDefinition item,
    RummiRunProgress runProgress,
    List<ItemEffectEvent> events,
  ) {
    if (!item.effect.consume) return;
    runProgress.itemInventory = runProgress.itemInventory.withConsumedItem(
      item.id,
    );
    events.add(
      ItemEffectEvent(kind: ItemEffectEventKind.itemConsumed, itemId: item.id),
    );
  }

  static String? _validateBattleUse(
    ItemDefinition item,
    RummiRunProgress runProgress,
  ) {
    if (item.placement != ItemPlacement.quickSlot || !item.usableInBattle) {
      return '전투에서 사용할 수 없는 아이템입니다.';
    }
    if (item.effect.timing != 'use_battle' &&
        _handlerNameFor(item.effect.timing) != 'applyConfirmModifierItem') {
      return '지금 사용할 수 없는 아이템입니다.';
    }
    final hasItem = runProgress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!hasItem) {
      return '보유 중인 아이템을 찾지 못했습니다.';
    }
    return null;
  }

  static String? _validateMarketUse(
    ItemDefinition item,
    RummiRunProgress runProgress,
  ) {
    if (item.effect.timing != 'use_market' &&
        item.effect.timing != 'use_market_if_gold_lte') {
      return '상점에서 사용할 수 없는 아이템입니다.';
    }
    final hasItem = runProgress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!hasItem) {
      return '보유 중인 아이템을 찾지 못했습니다.';
    }
    if (item.effect.timing == 'use_market_if_gold_lte') {
      final threshold = (item.effect.value('threshold') as num?)?.toInt();
      if (threshold != null && runProgress.gold > threshold) {
        return '현재 골드가 사용 조건보다 많습니다.';
      }
    }
    return null;
  }

  static int? _positiveIntAmount(ItemDefinition item) {
    final amount = (item.effect.amount ?? 0).toInt();
    return amount > 0 ? amount : null;
  }

  static int? _positiveIntValue(ItemDefinition item, String key) {
    final value = (item.effect.value(key) as num?)?.toInt() ?? 0;
    return value > 0 ? value : null;
  }

  static int _nonNegativeIntValue(ItemDefinition item, String key) {
    final value = (item.effect.value(key) as num?)?.toInt() ?? 0;
    return value < 0 ? 0 : value;
  }

  static ItemUseResult _invalidAmount(ItemDefinition item) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '아이템 효과 값이 올바르지 않습니다.',
    );
  }

  static ItemUseResult _pendingHook(ItemDefinition item, String handlerName) {
    return ItemUseResult.pendingHook(
      itemId: item.id,
      message: '$handlerName 연결이 필요합니다.',
    );
  }
}
