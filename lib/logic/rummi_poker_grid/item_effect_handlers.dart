part of 'item_effect_runtime.dart';

ItemUseResult _applyAddBoardDiscard(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  return _applyCappedResourceIncrease(
    item: item,
    currentValue: session.blind.boardDiscardsRemaining,
    maxValue: ItemEffectRuntime.maxSupportedBoardDiscards,
    failureMessage: '보드 버림 최대치입니다.',
    eventKind: ItemEffectEventKind.boardDiscardAdded,
    applyValue: (value) => session.blind.boardDiscardsRemaining = value,
  );
}

ItemUseResult _applyMarketModifier(
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
    case 'extra_item_offer_slot':
      final appliedAmount = _availableMarketOfferSlotIncrease(
        currentSlotCount: runProgress.marketModifiers.itemOfferSlotCount,
        requestedAmount: amount,
      );
      if (appliedAmount <= 0) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: 'Item 후보 슬롯 최대치입니다.',
        );
      }
      runProgress.queueMarketModifier(
        op: item.effect.op,
        amount: appliedAmount,
        category: category,
      );
      return ItemUseResult.success(
        itemId: item.id,
        events: [
          ItemEffectEvent(
            kind: ItemEffectEventKind.marketModifierQueued,
            itemId: item.id,
            amount: appliedAmount,
            detail: category == null
                ? item.effect.op
                : '${item.effect.op}:$category',
          ),
        ],
      );
    case 'free_next_reroll':
      final discount = runProgress.effectiveRerollCost();
      runProgress.queueMarketModifier(
        op: 'discount_next_reroll',
        amount: discount,
      );
      return ItemUseResult.success(
        itemId: item.id,
        events: [
          ItemEffectEvent(
            kind: ItemEffectEventKind.marketModifierQueued,
            itemId: item.id,
            amount: discount,
            detail: item.effect.op,
          ),
        ],
      );
  }
  return _pendingHook(item, 'applyMarketModifier');
}

ItemUseResult _applyBossMarketModifier(
  ItemDefinition item,
  RummiRunProgress runProgress,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  var appliedAmount = amount;
  if (item.effect.op == 'extra_jester_offer_next_market') {
    final nextMarketJesterSlots =
        RummiEconomyConfig.shopOfferCount +
        runProgress.marketModifiers.nextMarketExtraJesterOfferSlots;
    appliedAmount = _availableMarketOfferSlotIncrease(
      currentSlotCount: nextMarketJesterSlots,
      requestedAmount: amount,
    );
    if (appliedAmount <= 0) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: 'Jester 후보 슬롯 최대치입니다.',
      );
    }
  }
  runProgress.queueMarketModifier(op: item.effect.op, amount: appliedAmount);
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.bossModifierQueued,
        itemId: item.id,
        amount: appliedAmount,
        detail: item.effect.op,
      ),
    ],
  );
}

int _availableMarketOfferSlotIncrease({
  required int currentSlotCount,
  required int requestedAmount,
}) {
  final availableAmount =
      ItemEffectRuntime.maxSupportedMarketOfferSlots - currentSlotCount;
  if (availableAmount <= 0) return 0;
  return requestedAmount > availableAmount ? availableAmount : requestedAmount;
}

ItemUseResult _applyRerollItemOffersOnly(
  ItemDefinition item,
  RummiRunProgress runProgress,
) {
  runProgress.queueMarketModifier(op: item.effect.op, amount: 1);
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.marketModifierQueued,
        itemId: item.id,
        amount: runProgress.marketModifiers.itemOfferRerollOffset,
        detail: item.effect.op,
      ),
    ],
  );
}

ItemUseResult _applySellJesterModifier(ItemDefinition item) {
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

ItemUseResult _applyExpiryGuardRescue(
  ItemDefinition item,
  RummiPokerGridSession session,
  List<RummiExpirySignal> signals,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  final canAddBoardDiscard = signals.contains(
    RummiExpirySignal.boardFullAfterDcExhausted,
  );
  final canRecycleDraw =
      signals.contains(RummiExpirySignal.drawPileExhausted) &&
      session.eliminated.isNotEmpty &&
      session.hand.length < session.maxHandSize;
  if (!canAddBoardDiscard && !canRecycleDraw) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '안전망으로 복구할 수 있는 만료 상태가 아닙니다.',
    );
  }
  if (!session.tryUseExpiryGuard()) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '이미 이번 스테이션의 안전망을 사용했습니다.',
    );
  }
  final events = <ItemEffectEvent>[
    ItemEffectEvent(
      kind: ItemEffectEventKind.expiryGuardTriggered,
      itemId: item.id,
      amount: amount,
      detail: item.effect.op,
    ),
  ];
  if (canAddBoardDiscard) {
    session.blind.boardDiscardsRemaining += amount;
    events.add(
      ItemEffectEvent(
        kind: ItemEffectEventKind.boardDiscardAdded,
        itemId: item.id,
        amount: amount,
      ),
    );
  }
  if (canRecycleDraw) {
    final drawn = session.recycleEliminatedIntoDeckAndDraw();
    if (drawn != null) {
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.tileDrawn,
          itemId: item.id,
          amount: 1,
          detail: 'recycled_eliminated',
        ),
      );
    }
  }
  return ItemUseResult.success(itemId: item.id, events: events);
}

ItemUseResult _applyGainGold(
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

ItemUseResult _applyAddHandDiscard(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  return _applyCappedResourceIncrease(
    item: item,
    currentValue: session.blind.handDiscardsRemaining,
    maxValue: ItemEffectRuntime.maxSupportedHandDiscards,
    failureMessage: '손패 버림 최대치입니다.',
    eventKind: ItemEffectEventKind.handDiscardAdded,
    applyValue: (value) => session.blind.handDiscardsRemaining = value,
  );
}

ItemUseResult _applyAddBoardMove(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  return _applyCappedResourceIncrease(
    item: item,
    currentValue: session.blind.boardMovesRemaining,
    maxValue: ItemEffectRuntime.maxSupportedBoardMoves,
    failureMessage: '보드 이동 최대치입니다.',
    eventKind: ItemEffectEventKind.boardMoveAdded,
    applyValue: (value) => session.blind.boardMovesRemaining = value,
  );
}

ItemUseResult _applyCappedResourceIncrease({
  required ItemDefinition item,
  required int currentValue,
  required int maxValue,
  required String failureMessage,
  required ItemEffectEventKind eventKind,
  required void Function(int value) applyValue,
}) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);

  final requestedValue = currentValue + amount;
  final nextValue = requestedValue > maxValue ? maxValue : requestedValue;
  final appliedAmount = nextValue - currentValue;
  if (appliedAmount <= 0) {
    return ItemUseResult.failure(itemId: item.id, message: failureMessage);
  }

  applyValue(nextValue);
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(kind: eventKind, itemId: item.id, amount: appliedAmount),
    ],
  );
}

ItemUseResult _applyMarkNextBoardMoveBonus(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  if (session.blind.boardMovesRemaining <= 0) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '사용 가능한 보드 이동이 없습니다.',
    );
  }
  if (!session.queueNextBoardMoveSlideBonus()) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '이미 다음 보드 이동 보너스가 준비되어 있습니다.',
    );
  }
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.boardMoveSlideBonusQueued,
        itemId: item.id,
        amount: 1,
        detail: 'next_board_move_slide_bonus',
      ),
    ],
  );
}

ItemUseResult _applyDrawIfHandEmpty(
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

ItemUseResult _applyUndoLastBoardMove(
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

ItemUseResult _applyIncreaseHandSize(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  final amount = _positiveIntAmount(item);
  if (amount == null) return _invalidAmount(item);
  final nextMaxHandSize = (session.maxHandSize + amount).clamp(
    session.maxHandSize,
    ItemEffectRuntime.maxSupportedHandSize,
  );
  final appliedAmount = nextMaxHandSize - session.maxHandSize;
  if (appliedAmount <= 0) {
    return ItemUseResult.failure(itemId: item.id, message: '손패 최대치입니다.');
  }
  session.maxHandSize = nextMaxHandSize;
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.maxHandSizeIncreased,
        itemId: item.id,
        amount: appliedAmount,
      ),
    ],
  );
}

ItemUseResult _applyIncreaseHandSizeWithDiscardPenalty(
  ItemDefinition item,
  RummiPokerGridSession session,
) {
  final base = _applyIncreaseHandSize(item, session);
  if (!base.isSuccess) return base;

  final events = <ItemEffectEvent>[...base.events];
  final boardPenalty = _nonNegativeIntValue(item, 'boardDiscardPenalty');
  if (boardPenalty > 0) {
    final removed = boardPenalty.clamp(0, session.blind.boardDiscardsRemaining);
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

ItemUseResult _applyAddHandRankProgress(
  ItemDefinition item,
  RummiRunProgress runProgress,
) {
  final rank = _parseRank(item.effect.value('rank'));
  final amount = _nonNegativeIntValue(item, 'amount');
  if (rank == null || amount <= 0) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '성장시킬 족보를 찾지 못했습니다.',
    );
  }
  final didApply = runProgress.addHandRankProgress(rank, amount: amount);
  if (!didApply) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '이 족보는 성장시킬 수 없습니다.',
    );
  }
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.handRankProgressAdded,
        itemId: item.id,
        amount: amount,
        detail: rank.name,
      ),
    ],
  );
}

ItemUseResult _applyAddHandRankProgressFromSelectedLine(
  ItemDefinition item,
  RummiPokerGridSession session,
  RummiRunProgress runProgress,
  LineRef lineRef,
) {
  final line = session.currentScoringLineSummaryFor(lineRef);
  final amount = _nonNegativeIntValue(item, 'amount');
  if (line == null) {
    return ItemUseResult.failure(itemId: item.id, message: '선택한 완성 줄이 없습니다.');
  }
  if (amount <= 0) return _invalidAmount(item);
  final didApply = runProgress.addHandRankProgress(line.rank, amount: amount);
  if (!didApply) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '이 족보는 성장시킬 수 없습니다.',
    );
  }
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.handRankProgressAdded,
        itemId: item.id,
        amount: amount,
        detail: '${line.rank.name}:${line.ref.kind.name}:${line.ref.index}',
      ),
    ],
  );
}

void _consumeIfNeeded(
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

String? _validateBattleUse(ItemDefinition item, RummiRunProgress runProgress) {
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

bool _isManualOneShotConfirmModifier(RummiConfirmModifier modifier) {
  return modifier.consumeOnApply && modifier.timing.startsWith('next_confirm');
}

String? _validateMarketUse(ItemDefinition item, RummiRunProgress runProgress) {
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

int? _positiveIntAmount(ItemDefinition item) {
  final amount = (item.effect.amount ?? 0).toInt();
  return amount > 0 ? amount : null;
}

int? _positiveIntValue(ItemDefinition item, String key) {
  final value = (item.effect.value(key) as num?)?.toInt() ?? 0;
  return value > 0 ? value : null;
}

int _nonNegativeIntValue(ItemDefinition item, String key) {
  final value = (item.effect.value(key) as num?)?.toInt() ?? 0;
  return value < 0 ? 0 : value;
}

ItemUseResult _invalidAmount(ItemDefinition item) {
  return ItemUseResult.failure(
    itemId: item.id,
    message: '아이템 효과 값이 올바르지 않습니다.',
  );
}

ItemUseResult _pendingHook(ItemDefinition item, String handlerName) {
  return ItemUseResult.pendingHook(
    itemId: item.id,
    message: '$handlerName 연결이 필요합니다.',
  );
}
