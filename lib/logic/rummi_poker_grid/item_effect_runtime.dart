import 'item_definition.dart';
import 'jester_meta.dart';
import 'rummi_poker_grid_session.dart';

enum ItemEffectApplicationStatus { applied, pendingHook, rejected }

enum ItemEffectEventKind {
  boardDiscardAdded,
  handDiscardAdded,
  boardMoveAdded,
  tileDrawn,
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
      case 'draw_if_hand_empty':
        final applied = _applyDrawIfHandEmpty(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'peek_deck_discard_one':
        return ItemUseResult.pendingHook(
          itemId: item.id,
          message: '덱 확인/버림 선택 UI 연결이 필요합니다.',
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
    return _pendingHook(item, 'applyMarketUseItem');
  }

  static ItemUseResult applyMarketRerollItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyMarketRerollItem');
  }

  static ItemUseResult applyMarketBuyItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyMarketBuyItem');
  }

  static ItemUseResult applyStationStartItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
  }) {
    return _pendingHook(item, 'applyStationStartItem');
  }

  static ItemUseResult applyEnterMarketItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyEnterMarketItem');
  }

  static ItemUseResult applySettlementItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applySettlementItem');
  }

  static ItemUseResult applyConfirmModifierItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyConfirmModifierItem');
  }

  static ItemUseResult applyBossClearItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyBossClearItem');
  }

  static ItemUseResult applyInventoryCapacityItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applyInventoryCapacityItem');
  }

  static ItemUseResult applySellJesterItem({
    required ItemDefinition item,
    required RummiRunProgress runProgress,
  }) {
    return _pendingHook(item, 'applySellJesterItem');
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
      'use_battle:draw_if_hand_empty' => ItemEffectApplicationStatus.applied,
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
    if (item.effect.timing != 'use_battle') {
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

  static int? _positiveIntAmount(ItemDefinition item) {
    final amount = (item.effect.amount ?? 0).toInt();
    return amount > 0 ? amount : null;
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
