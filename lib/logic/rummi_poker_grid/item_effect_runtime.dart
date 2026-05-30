import 'item_definition.dart';
import 'hand_rank.dart';
import 'jester_meta.dart';
import 'line_ref.dart';
import 'models/tile.dart';
import 'rummi_poker_grid_session.dart';

part 'item_effect_catalog_support.dart';
part 'item_effect_handlers.dart';

enum ItemEffectApplicationStatus { applied, pendingHook, rejected }

enum ItemEffectEventKind {
  boardDiscardAdded,
  boardDiscardRemoved,
  handDiscardAdded,
  handDiscardRemoved,
  boardMoveAdded,
  boardMoveSlideBonusQueued,
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
  expiryGuardTriggered,
  interactionRequired,
  handRankProgressAdded,
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

  static const int maxSupportedHandSize = 5;
  static const int maxSupportedBoardDiscards = 6;
  static const int maxSupportedHandDiscards = 4;
  static const int maxSupportedBoardMoves = 5;
  static const int maxSupportedMarketOfferSlots = 4;

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
      case 'mark_next_board_move_bonus':
        final applied = _applyMarkNextBoardMoveBonus(item, session);
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
      case 'increase_hand_size':
        final applied = _applyIncreaseHandSize(item, session);
        if (!applied.isSuccess) return applied;
        events.addAll(applied.events);
        break;
      case 'add_hand_rank_progress_from_selected_line':
        return ItemUseResult.pendingHook(
          itemId: item.id,
          message: '성장시킬 완성 줄 선택이 필요합니다.',
          events: [
            ItemEffectEvent(
              kind: ItemEffectEventKind.interactionRequired,
              itemId: item.id,
              amount: 1,
              detail: 'select_scoring_line',
            ),
          ],
        );
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

  static ItemUseResult useBattleItemOnLine({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required LineRef lineRef,
  }) {
    final validationMessage = _validateBattleUse(item, runProgress);
    if (validationMessage != null) {
      return ItemUseResult.failure(itemId: item.id, message: validationMessage);
    }
    if (item.effect.op != 'add_hand_rank_progress_from_selected_line') {
      return ItemUseResult.failure(itemId: item.id, message: '줄 선택 아이템이 아닙니다.');
    }
    final applied = _applyAddHandRankProgressFromSelectedLine(
      item,
      session,
      runProgress,
      lineRef,
    );
    if (!applied.isSuccess) return applied;
    final events = <ItemEffectEvent>[...applied.events];
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
      'add_hand_rank_progress' => _applyAddHandRankProgress(item, runProgress),
      'reroll_item_offers_only' => _applyRerollItemOffersOnly(
        item,
        runProgress,
      ),
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
    if (_isManualOneShotConfirmModifier(modifier) &&
        session.confirmModifiers.any(_isManualOneShotConfirmModifier)) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '이미 다음 확정 보너스가 준비되어 있습니다.',
      );
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
      'extra_jester_offer_next_market' => _applyBossMarketModifier(
        item,
        runProgress,
      ),
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

  static ItemUseResult applyExpiryGuardItem({
    required ItemDefinition item,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required List<RummiExpirySignal> signals,
  }) {
    return switch (item.effect.op) {
      'rescue_first_expiry_each_station' => _applyExpiryGuardRescue(
        item,
        session,
        signals,
      ),
      _ => _pendingHook(item, 'applyExpiryGuardItem'),
    };
  }

  static List<ItemUseResult> applyOwnedExpiryGuardItems({
    required ItemCatalog catalog,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required List<RummiExpirySignal> signals,
  }) {
    if (signals.isEmpty) return const [];
    final activeIds = <String>{
      for (final entry in runProgress.itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final results = <ItemUseResult>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null || item.effect.timing != 'expiry_guard') continue;
      if (item.placement == ItemPlacement.quickSlot) continue;
      final result = applyExpiryGuardItem(
        item: item,
        session: session,
        runProgress: runProgress,
        signals: signals,
      );
      results.add(result);
      if (result.isSuccess && item.effect.consume) {
        runProgress.itemInventory = runProgress.itemInventory.withConsumedItem(
          item.id,
        );
      }
    }
    return List<ItemUseResult>.unmodifiable(results);
  }
}
