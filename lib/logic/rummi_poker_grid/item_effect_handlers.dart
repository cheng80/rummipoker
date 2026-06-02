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

ItemUseResult _applyRitualLineEffect(
  ItemDefinition item,
  RummiPokerGridSession session,
  RummiRunProgress runProgress,
  LineRef lineRef,
  int? tileIndex,
) {
  final line = session.currentBoardLineSummaryFor(lineRef);
  if (line == null) {
    return ItemUseResult.failure(
      itemId: item.id,
      message: '선택한 보드 선이 비어 있습니다.',
    );
  }
  final action = item.effect.value('ritualAction') as String? ?? '';
  final amount = _nonNegativeIntValue(item, 'amount');
  final selectedTile = _selectedRitualTile(line, tileIndex);
  final events = <ItemEffectEvent>[];

  ItemUseResult growSelectedLine(int growthAmount) {
    if (!line.isScoringLine) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '성장시킬 완성 족보가 없습니다.',
      );
    }
    if (growthAmount <= 0) return _invalidAmount(item);
    final didApply = runProgress.addHandRankProgress(
      line.rank,
      amount: growthAmount,
    );
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
          amount: growthAmount,
          detail: '${line.rank.name}:${line.ref.kind.name}:${line.ref.index}',
        ),
      ],
    );
  }

  ItemUseResult forceLineRank(RummiHandRank rank) {
    if (line.occupiedCount < 3) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '족보 치환은 타일이 3개 이상 있는 선에만 사용할 수 있습니다.',
      );
    }
    return _queueLineRankOverride(item, session, line.ref, rank);
  }

  ItemUseResult transformLineToFateSet(String fateAction) {
    if (line.occupiedCount <= 0) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '운명 변환은 기준 타일이 있는 선에만 사용할 수 있습니다.',
      );
    }
    final transformed = _buildFateLineTiles(line, fateAction);
    if (transformed == null) {
      return ItemUseResult.failure(
        itemId: item.id,
        message: '이 선에서는 해당 운명 세트를 만들 수 없습니다.',
      );
    }
    final cells = line.ref.cells();
    for (var i = 0; i < cells.length; i++) {
      final (row, col) = cells[i];
      session.board.setCell(row, col, transformed[i]);
    }
    return ItemUseResult.success(
      itemId: item.id,
      events: [
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardLineTransformed,
          itemId: item.id,
          amount: 1,
          detail: '$fateAction:${line.ref.kind.name}:${line.ref.index}',
        ),
      ],
    );
  }

  switch (action) {
    case 'growth':
    case 'center_growth':
      return growSelectedLine(amount);
    case 'growth_marker':
      final result = growSelectedLine(amount);
      if (!result.isSuccess || selectedTile == null) return result;
      _applySealToBoardTile(session, selectedTile, TileSeal.crossMemory);
      return ItemUseResult.success(
        itemId: item.id,
        events: [
          ...result.events,
          ItemEffectEvent(
            kind: ItemEffectEventKind.settlementModifierQueued,
            itemId: item.id,
            amount: 1,
            detail: 'cross_memory',
          ),
        ],
      );
    case 'boss_growth':
      if (session.blind.bossModifier == null) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '보스전에서만 사용할 수 있습니다.',
        );
      }
      return growSelectedLine(amount);
    case 'thin_growth':
      if (line.scoringTiles.length > 4) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '3~4타일 scoring 줄에만 사용할 수 있습니다.',
        );
      }
      final result = growSelectedLine(amount);
      if (!result.isSuccess) return result;
      _queueLineScoreMultiplier(item, session, line.ref, 0.9);
      return ItemUseResult.success(
        itemId: item.id,
        events: [
          ...result.events,
          ItemEffectEvent(
            kind: ItemEffectEventKind.nextConfirmModifierQueued,
            itemId: item.id,
            amount: -10,
            detail: 'line_score_multiplier:0.9',
          ),
        ],
      );
    case 'growth_risk':
      final result = growSelectedLine(amount);
      if (!result.isSuccess) return result;
      _queueLineScoreMultiplier(item, session, line.ref, 0.75);
      return ItemUseResult.success(
        itemId: item.id,
        events: [
          ...result.events,
          ItemEffectEvent(
            kind: ItemEffectEventKind.nextConfirmModifierQueued,
            itemId: item.id,
            amount: -25,
            detail: 'line_score_multiplier:0.75',
          ),
        ],
      );
    case 'copy_center':
      final center = _centerTileForLine(line);
      if (center == null) return _noTileTarget(item);
      final added = runProgress.addDeckTile(center);
      events.add(_deckAddEvent(item, added));
      break;
    case 'copy_endpoint':
      final tile = _endpointTileForLine(line) ?? selectedTile;
      if (tile == null) return _noTileTarget(item);
      final added = runProgress.addDeckTile(tile);
      events.add(_deckAddEvent(item, added));
      break;
    case 'copy_selected':
      if (selectedTile == null) return _noTileTarget(item);
      final added = runProgress.addDeckTile(selectedTile);
      events.add(_deckAddEvent(item, added));
      break;
    case 'copy_rank':
      if (selectedTile == null) return _noTileTarget(item);
      final color =
          TileColor.values[session.runRandom.nextInt(TileColor.values.length)];
      final added = runProgress.addDeckTile(
        Tile(color: color, number: selectedTile.number),
      );
      events.add(_deckAddEvent(item, added));
      break;
    case 'copy_color':
      if (selectedTile == null) return _noTileTarget(item);
      final number = session.runRandom.nextInt(13) + 1;
      final added = runProgress.addDeckTile(
        Tile(color: selectedTile.color, number: number),
      );
      events.add(_deckAddEvent(item, added));
      break;
    case 'seal_line_mark':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.lineMark);
    case 'seal_growth':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.growthSeal);
    case 'seal_gold':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.goldSeal);
    case 'seal_echo':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.echoSeal);
    case 'seal_anchor':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.anchorSeal);
    case 'seal_risk':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.riskSeal);
    case 'seal_bridge':
      return _applyRitualSeal(item, session, selectedTile, TileSeal.bridgeSeal);
    case 'override_three_kind':
      return forceLineRank(RummiHandRank.threeOfAKind);
    case 'override_straight':
      return forceLineRank(RummiHandRank.straight);
    case 'override_flush':
      return forceLineRank(RummiHandRank.flush);
    case 'override_full_house':
      return forceLineRank(RummiHandRank.fullHouse);
    case 'override_four_kind':
      return forceLineRank(RummiHandRank.fourOfAKind);
    case 'override_five_kind':
      return forceLineRank(RummiHandRank.fiveOfAKind);
    case 'fate_royal_flush':
    case 'fate_straight_flush_high':
    case 'fate_straight_flush_low':
    case 'fate_four_kind_high':
    case 'fate_four_kind_low':
    case 'fate_full_house_high':
    case 'fate_full_house_low':
    case 'fate_flush_high':
    case 'fate_flush_low':
    case 'fate_straight_high':
    case 'fate_straight_low':
    case 'fate_three_kind_high':
    case 'fate_three_kind_low':
    case 'fate_two_pair_high':
      return transformLineToFateSet(action);
    case 'line_bonus_25':
      if (!line.isScoringLine) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '보너스를 적용할 완성 족보가 없습니다.',
        );
      }
      _queueLineScoreMultiplier(item, session, line.ref, 1.25);
      events.add(_lineMultiplierEvent(item, 25));
      break;
    case 'line_bonus_35':
      if (!line.isScoringLine) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '보너스를 적용할 완성 족보가 없습니다.',
        );
      }
      _queueLineScoreMultiplier(item, session, line.ref, 1.35);
      events.add(_lineMultiplierEvent(item, 35));
      break;
    case 'remove_same_tile':
      if (selectedTile == null) return _noTileTarget(item);
      final removed = session.removeDeckTileMatching(
        (tile) =>
            tile.color == selectedTile.color &&
            tile.number == selectedTile.number,
      );
      if (removed == null) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '덱에서 같은 타일을 찾지 못했습니다.',
        );
      }
      runProgress.gold += 2;
      events
        ..add(
          ItemEffectEvent(
            kind: ItemEffectEventKind.deckTileDiscarded,
            itemId: item.id,
            amount: 1,
            detail: removed.code,
          ),
        )
        ..add(
          ItemEffectEvent(
            kind: ItemEffectEventKind.goldGained,
            itemId: item.id,
            amount: 2,
            detail: selectedTile.code,
          ),
        );
      break;
    case 'remove_same_color':
      if (selectedTile == null) return _noTileTarget(item);
      final removedColor = session.removeDeckTileMatching(
        (tile) => tile.color == selectedTile.color,
      );
      if (removedColor == null) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '덱에서 같은 색 타일을 찾지 못했습니다.',
        );
      }
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.deckTileDiscarded,
          itemId: item.id,
          amount: 1,
          detail: removedColor.code,
        ),
      );
      break;
    case 'remove_same_rank':
      if (selectedTile == null) return _noTileTarget(item);
      final removedRank = session.removeDeckTileMatching(
        (tile) => tile.number == selectedTile.number,
      );
      if (removedRank == null) {
        return ItemUseResult.failure(
          itemId: item.id,
          message: '덱에서 같은 숫자 타일을 찾지 못했습니다.',
        );
      }
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.deckTileDiscarded,
          itemId: item.id,
          amount: 1,
          detail: removedRank.code,
        ),
      );
      break;
    case 'burn_line':
      final removed = session.clearLine(line.ref);
      runProgress.gold += 3;
      events
        ..add(
          ItemEffectEvent(
            kind: ItemEffectEventKind.boardDiscardRemoved,
            itemId: item.id,
            amount: removed,
            detail: 'burn_line',
          ),
        )
        ..add(
          ItemEffectEvent(
            kind: ItemEffectEventKind.goldGained,
            itemId: item.id,
            amount: 3,
          ),
        );
      break;
    case 'sacrifice_line':
      for (final tile in line.scoringTiles.take(2)) {
        events.add(_deckAddEvent(item, runProgress.addDeckTile(tile)));
      }
      final removed = session.clearLine(line.ref);
      events.add(
        ItemEffectEvent(
          kind: ItemEffectEventKind.boardDiscardRemoved,
          itemId: item.id,
          amount: removed,
          detail: 'sacrifice_line',
        ),
      );
      break;
    default:
      return ItemUseResult.failure(
        itemId: item.id,
        message: '알 수 없는 의식 효과입니다.',
      );
  }
  return ItemUseResult.success(itemId: item.id, events: events);
}

List<Tile>? _buildFateLineTiles(RummiScoringLineSummary line, String action) {
  final tiles = line.lineTiles;
  if (tiles.isEmpty) return null;
  final highTile = _tileByNumber(tiles, preferHigh: true);
  final lowTile = _tileByNumber(tiles, preferHigh: false);
  final uniqueNumbers = _uniqueSortedNumbers(tiles);

  switch (action) {
    case 'fate_royal_flush':
      return _sameColorTiles(highTile.color, const [9, 10, 11, 12, 13]);
    case 'fate_straight_flush_high':
      return _sameColorTiles(
        highTile.color,
        _straightSequenceContaining(highTile.number, preferHigh: true),
      );
    case 'fate_straight_flush_low':
      return _sameColorTiles(
        lowTile.color,
        _straightSequenceContaining(lowTile.number, preferHigh: false),
      );
    case 'fate_four_kind_high':
      return _fourKindSet(highTile.number, highTile.color);
    case 'fate_four_kind_low':
      return _fourKindSet(lowTile.number, lowTile.color);
    case 'fate_full_house_high':
      return _fullHouseSet(
        tripleNumber: uniqueNumbers.last,
        pairNumber: _nextLowerDistinct(uniqueNumbers.last, uniqueNumbers),
        color: highTile.color,
      );
    case 'fate_full_house_low':
      final triple = _secondLowestOrFallback(uniqueNumbers);
      return _fullHouseSet(
        tripleNumber: triple,
        pairNumber: _highestDistinct(triple, uniqueNumbers),
        color: lowTile.color,
      );
    case 'fate_flush_high':
      return _flushSet(highTile.number, highTile.color);
    case 'fate_flush_low':
      return _flushSet(lowTile.number, lowTile.color);
    case 'fate_straight_high':
      return _straightSet(
        _straightSequenceContaining(highTile.number, preferHigh: true),
        baseColor: highTile.color,
        offColorNumber: highTile.number,
      );
    case 'fate_straight_low':
      return _straightSet(
        _straightSequenceContaining(lowTile.number, preferHigh: false),
        baseColor: lowTile.color,
        offColorNumber: lowTile.number,
      );
    case 'fate_three_kind_high':
      return _threeKindSet(highTile.number, highTile.color);
    case 'fate_three_kind_low':
      return _threeKindSet(
        _secondLowestOrFallback(uniqueNumbers),
        lowTile.color,
      );
    case 'fate_two_pair_high':
      return _twoPairSet(
        highPairNumber: uniqueNumbers.last,
        lowPairNumber: _nextLowerDistinct(uniqueNumbers.last, uniqueNumbers),
        color: highTile.color,
      );
    default:
      return null;
  }
}

Tile _tileByNumber(List<Tile> tiles, {required bool preferHigh}) {
  return tiles.reduce((a, b) {
    final compare = a.number.compareTo(b.number);
    if (compare == 0) return a;
    return preferHigh ? (compare > 0 ? a : b) : (compare < 0 ? a : b);
  });
}

List<int> _uniqueSortedNumbers(List<Tile> tiles) {
  return tiles.map((tile) => tile.number).toSet().toList()..sort();
}

int _nextLowerDistinct(int number, List<int> sortedNumbers) {
  for (final candidate in sortedNumbers.reversed) {
    if (candidate != number) return candidate;
  }
  return _fallbackDistinctNumber(number, preferHigh: false);
}

int _highestDistinct(int number, List<int> sortedNumbers) {
  for (final candidate in sortedNumbers.reversed) {
    if (candidate != number) return candidate;
  }
  return _fallbackDistinctNumber(number, preferHigh: true);
}

int _secondLowestOrFallback(List<int> sortedNumbers) {
  if (sortedNumbers.length >= 2) return sortedNumbers[1];
  return _fallbackDistinctNumber(sortedNumbers.single, preferHigh: false);
}

int _fallbackDistinctNumber(int number, {required bool preferHigh}) {
  if (preferHigh) return number == 13 ? 12 : 13;
  return number == 1 ? 2 : 1;
}

List<int> _straightSequenceContaining(int number, {required bool preferHigh}) {
  const sequences = <List<int>>[
    [1, 2, 3, 4, 5],
    [2, 3, 4, 5, 6],
    [3, 4, 5, 6, 7],
    [4, 5, 6, 7, 8],
    [5, 6, 7, 8, 9],
    [6, 7, 8, 9, 10],
    [7, 8, 9, 10, 11],
    [8, 9, 10, 11, 12],
    [10, 11, 12, 13, 1],
  ];
  final candidates = [
    for (final sequence in sequences)
      if (sequence.contains(number)) sequence,
  ];
  if (candidates.isEmpty) return const [1, 2, 3, 4, 5];
  return preferHigh ? candidates.last : candidates.first;
}

List<Tile> _sameColorTiles(TileColor color, List<int> numbers) {
  return [for (final number in numbers) Tile(color: color, number: number)];
}

List<Tile> _fourKindSet(int number, TileColor color) {
  final kicker = _fallbackDistinctNumber(number, preferHigh: number < 7);
  return [
    for (final tileColor in TileColor.values)
      Tile(color: tileColor, number: number),
    Tile(color: color, number: kicker),
  ];
}

List<Tile> _fullHouseSet({
  required int tripleNumber,
  required int pairNumber,
  required TileColor color,
}) {
  if (pairNumber == tripleNumber) {
    pairNumber = _fallbackDistinctNumber(tripleNumber, preferHigh: false);
  }
  return [
    Tile(color: color, number: tripleNumber),
    Tile(color: _nextColor(color), number: tripleNumber),
    Tile(color: _thirdColor(color), number: tripleNumber),
    Tile(color: color, number: pairNumber),
    Tile(color: _nextColor(color), number: pairNumber),
  ];
}

List<Tile> _flushSet(int anchorNumber, TileColor color) {
  final numbers = <int>[anchorNumber];
  for (final number in const [1, 3, 5, 8, 11, 13, 2, 6, 10]) {
    if (numbers.length >= 5) break;
    if (number != anchorNumber) numbers.add(number);
  }
  return _sameColorTiles(color, numbers);
}

List<Tile> _straightSet(
  List<int> numbers, {
  required TileColor baseColor,
  required int offColorNumber,
}) {
  final offColor = _nextColor(baseColor);
  return [
    for (final number in numbers)
      Tile(
        color: number == offColorNumber ? offColor : baseColor,
        number: number,
      ),
  ];
}

List<Tile> _threeKindSet(int tripleNumber, TileColor color) {
  final kickers = _kickersExcluding(tripleNumber, count: 2);
  return [
    Tile(color: color, number: tripleNumber),
    Tile(color: _nextColor(color), number: tripleNumber),
    Tile(color: _thirdColor(color), number: tripleNumber),
    Tile(color: color, number: kickers[0]),
    Tile(color: _nextColor(color), number: kickers[1]),
  ];
}

List<Tile> _twoPairSet({
  required int highPairNumber,
  required int lowPairNumber,
  required TileColor color,
}) {
  if (lowPairNumber == highPairNumber) {
    lowPairNumber = _fallbackDistinctNumber(highPairNumber, preferHigh: false);
  }
  final kicker = _kickersExcluding(
    highPairNumber,
    alsoExclude: lowPairNumber,
    count: 1,
  ).single;
  return [
    Tile(color: color, number: highPairNumber),
    Tile(color: _nextColor(color), number: highPairNumber),
    Tile(color: color, number: lowPairNumber),
    Tile(color: _nextColor(color), number: lowPairNumber),
    Tile(color: _thirdColor(color), number: kicker),
  ];
}

List<int> _kickersExcluding(
  int number, {
  int? alsoExclude,
  required int count,
}) {
  final out = <int>[];
  for (final candidate in const [1, 13, 2, 12, 3, 11, 4, 10, 5, 9, 6, 8, 7]) {
    if (candidate == number || candidate == alsoExclude) continue;
    out.add(candidate);
    if (out.length >= count) break;
  }
  return out;
}

TileColor _nextColor(TileColor color) {
  return TileColor.values[(color.index + 1) % TileColor.values.length];
}

TileColor _thirdColor(TileColor color) {
  return TileColor.values[(color.index + 2) % TileColor.values.length];
}

Tile? _selectedRitualTile(RummiScoringLineSummary line, int? tileIndex) {
  if (line.scoringTiles.isEmpty) return null;
  if (tileIndex == null) return line.scoringTiles.first;
  if (tileIndex < 0 || tileIndex >= line.scoringTiles.length) return null;
  return line.scoringTiles[tileIndex];
}

Tile? _centerTileForLine(RummiScoringLineSummary line) {
  final centerCell = line.ref.cells()[2];
  final index = line.contributingCells.indexWhere((cell) => cell == centerCell);
  return index >= 0 && index < line.scoringTiles.length
      ? line.scoringTiles[index]
      : null;
}

Tile? _endpointTileForLine(RummiScoringLineSummary line) {
  final cells = line.ref.cells();
  for (final endpoint in [cells.first, cells.last]) {
    final index = line.contributingCells.indexWhere((cell) => cell == endpoint);
    if (index >= 0 && index < line.scoringTiles.length) {
      return line.scoringTiles[index];
    }
  }
  return null;
}

ItemUseResult _applyRitualSeal(
  ItemDefinition item,
  RummiPokerGridSession session,
  Tile? tile,
  TileSeal seal,
) {
  if (tile == null) return _noTileTarget(item);
  final applied = _applySealToBoardTile(session, tile, seal);
  if (!applied) {
    return ItemUseResult.failure(itemId: item.id, message: '선택 타일을 찾지 못했습니다.');
  }
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.settlementModifierQueued,
        itemId: item.id,
        amount: 1,
        detail: seal.persistenceValue,
      ),
    ],
  );
}

bool _applySealToBoardTile(
  RummiPokerGridSession session,
  Tile tile,
  TileSeal seal,
) {
  return session.replaceBoardTile(tile, tile.copyWith(seal: seal));
}

ItemUseResult _queueLineRankOverride(
  ItemDefinition item,
  RummiPokerGridSession session,
  LineRef lineRef,
  RummiHandRank rank,
) {
  session.addConfirmModifier(
    RummiConfirmModifier(
      itemId: item.id,
      timing: 'next_confirm',
      op: 'line_hand_rank_override',
      rank: rank,
      consumeOnApply: true,
      lineRef: lineRef,
    ),
  );
  return ItemUseResult.success(
    itemId: item.id,
    events: [
      ItemEffectEvent(
        kind: ItemEffectEventKind.nextConfirmModifierQueued,
        itemId: item.id,
        amount: 1,
        detail: 'override:${rank.name}',
      ),
    ],
  );
}

void _queueLineScoreMultiplier(
  ItemDefinition item,
  RummiPokerGridSession session,
  LineRef lineRef,
  double multiplier,
) {
  session.addConfirmModifier(
    RummiConfirmModifier(
      itemId: item.id,
      timing: 'next_confirm',
      op: 'line_score_multiplier',
      amount: multiplier,
      scoreMultiplier: multiplier,
      consumeOnApply: true,
      lineRef: lineRef,
    ),
  );
}

ItemEffectEvent _deckAddEvent(ItemDefinition item, Tile tile) {
  return ItemEffectEvent(
    kind: ItemEffectEventKind.tileDrawn,
    itemId: item.id,
    amount: 1,
    detail: 'deck_add:${tile.code}',
  );
}

ItemEffectEvent _lineMultiplierEvent(ItemDefinition item, int percent) {
  return ItemEffectEvent(
    kind: ItemEffectEventKind.nextConfirmModifierQueued,
    itemId: item.id,
    amount: percent,
    detail: 'line_score_multiplier',
  );
}

ItemUseResult _noTileTarget(ItemDefinition item) {
  return ItemUseResult.failure(itemId: item.id, message: '선택할 타일이 없습니다.');
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
