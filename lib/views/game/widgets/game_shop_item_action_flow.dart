part of 'game_shop_screen.dart';

extension _GameShopItemActionFlow on _GameShopScreenState {
  void _startMarketDenyFeedback(String target, String reason) {
    final tick = _marketDenyTick + 1;
    _mutate(() {
      _marketDenyTick = tick;
      _marketDenyTarget = target;
      _marketDenyReason = reason;
    });
    Future<void>.delayed(GamePresentationTimings.marketDenyFeedbackHold, () {
      if (!mounted || _marketDenyTick != tick) return;
      _mutate(() {
        _marketDenyTarget = null;
        _marketDenyReason = null;
      });
    });
  }

  void _startEffectPresentation(ItemPresentationEvent event) {
    final tick = _effectPresentationTick + 1;
    _effectPresentationTick = tick;
    _mutate(() {
      _effectPresentation = _MarketEffectPresentation.single(
        tick: tick,
        event: event,
      );
    });
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _effectPresentation?.tick != tick) return;
      _mutate(() => _effectPresentation = null);
    });
  }

  void _startEffectPresentationSummary(
    List<ItemPresentationEvent> events, {
    required String title,
  }) {
    if (events.isEmpty) return;
    if (events.length == 1) {
      _startEffectPresentation(events.single);
      return;
    }
    final tick = _effectPresentationTick + 1;
    _effectPresentationTick = tick;
    _mutate(() {
      _effectPresentation = _MarketEffectPresentation(
        tick: tick,
        events: events,
        title: title,
      );
    });
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _effectPresentation?.tick != tick) return;
      _mutate(() => _effectPresentation = null);
    });
  }

  ItemPresentationEvent? _marketRerollPresentation(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final source = _activeItemSlotWhere(
      (item) =>
          item.effect.timing == 'market_reroll' &&
          (item.effect.op == 'free_next_reroll' ||
              item.effect.op == 'discount_next_reroll'),
    );
    if (source == null) return null;
    final item = source.item;
    if (item == null) return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: localizedItemSlotName(context, source),
      target: ItemPresentationTarget(
        kind: ItemPresentationTargetKind.marketReroll,
        label: _offerLaneLabel(lane),
      ),
      resultLabel: item.effect.consume
          ? '${market.rerollCost <= 0 ? '발동: 리롤 무료' : '발동: 리롤 비용 할인'} · 소모됨'
          : market.rerollCost <= 0
          ? '발동: 리롤 무료'
          : '발동: 리롤 비용 할인',
    );
  }

  ItemPresentationEvent? _marketPurchasePresentation({
    required RummiMarketRuntimeFacade market,
    required String category,
    required String targetLabel,
    required String? discountSourceLabel,
  }) {
    final purchaseSource = _activeItemSlotWhere(
      (item) =>
          item.effect.op == 'discount_next_purchase' &&
          (item.effect.timing == 'market_buy' ||
              (item.effect.timing == 'market_buy_if_category' &&
                  item.effect.value('category') == category)),
    );
    final compassSource = discountSourceLabel == '나침반'
        ? _activeItemSlotWhere((item) => item.id == 'market_compass')
        : null;
    final source = purchaseSource ?? compassSource;
    final item = source?.item;
    if (source == null || item == null) {
      if (discountSourceLabel == null) return null;
      return ItemPresentationEvent(
        itemId: discountSourceLabel == '나침반'
            ? 'market_compass'
            : discountSourceLabel,
        sourceKind: ItemPresentationSourceKind.passive,
        sourceLabel: discountSourceLabel,
        target: ItemPresentationTarget(
          kind: category == 'jester'
              ? ItemPresentationTargetKind.marketOffer
              : ItemPresentationTargetKind.itemOffer,
          label: targetLabel,
        ),
        resultLabel: '발동: 구매가 -1G',
      );
    }
    final labels = <String>[
      localizedItemSlotName(context, source),
      if (purchaseSource != null && compassSource != null)
        localizedItemSlotName(context, compassSource),
    ];
    final discount = _marketPurchaseDiscountAmount(
      item: purchaseSource?.item,
      compassActive: compassSource != null,
    );
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: labels.join(' + '),
      target: ItemPresentationTarget(
        kind: category == 'jester'
            ? ItemPresentationTargetKind.marketOffer
            : ItemPresentationTargetKind.itemOffer,
        label: targetLabel,
      ),
      resultLabel: _marketPurchaseResultLabel(
        discount: discount,
        consumed: purchaseSource?.item?.effect.consume ?? false,
      ),
    );
  }

  String _marketPurchaseResultLabel({
    required int discount,
    required bool consumed,
  }) {
    final effectLabel = discount > 0 ? '구매가 -${discount}G' : '할인 적용';
    return consumed ? '발동: $effectLabel · 소모됨' : '발동: $effectLabel';
  }

  int _marketPurchaseDiscountAmount({
    required ItemDefinition? item,
    required bool compassActive,
  }) {
    var total = 0;
    if (item != null) {
      total += (item.effect.value('amount') as num?)?.toInt() ?? 0;
    }
    if (compassActive) {
      total += 1;
    }
    return total;
  }

  RummiMarketItemSlotView? _activeItemSlotWhere(
    bool Function(ItemDefinition item) test,
  ) {
    for (final slot in _market.itemSlots) {
      final item = slot.item;
      if (item == null || slot.locked || slot.count <= 0) continue;
      if (test(item)) return slot;
    }
    return null;
  }

  ItemPresentationSourceKind _presentationSourceKind(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => ItemPresentationSourceKind.quickSlot,
      ItemPlacement.passiveRack => ItemPresentationSourceKind.passive,
      ItemPlacement.inventory => ItemPresentationSourceKind.tool,
      ItemPlacement.equipped => ItemPresentationSourceKind.gear,
    };
  }

  void _useSelectedMarketItem(RummiMarketItemSlotView slot) {
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final failMessage = widget.onUseMarketItem(item);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    final feedbackTick = _marketUseFeedbackTick + 1;
    final goldGain = _marketUseGoldGain(item);
    final effectPresentation = _marketUsePresentation(slot, item);
    final endOffset = goldGain == null
        ? null
        : _flightCenterForKey(_goldChipKey);
    _mutate(() {
      if (item.effect.op == 'reroll_item_offers_only') {
        _pinnedItemOffers = null;
      }
      _marketUseFeedbackTick = feedbackTick;
      _marketUseFeedbackLabel = localizedItemSlotName(context, slot);
      _marketUseFeedbackDelta = _marketUseFeedbackDeltaLabel(item);
      _startMarketItemUseFlight(
        slot: slot,
        item: item,
        goldGain: goldGain,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      _clearMarketSelection();
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _marketUseFeedbackTick != feedbackTick) return;
      _mutate(() {
        _marketUseFeedbackLabel = null;
        _marketUseFeedbackDelta = null;
      });
    });
    _queueStateSave();
  }

  String? _marketUseFeedbackDeltaLabel(ItemDefinition item) {
    final amount = _marketUseGoldGain(item);
    return switch (item.effect.op) {
      'gain_gold' when amount != null => '+${amount}G',
      'add_hand_rank_progress' => _marketUseRankGrowthLabel(item),
      'reroll_item_offers_only' => 'Item 후보 교체',
      _ => null,
    };
  }

  String? _marketUseRankGrowthLabel(ItemDefinition item) {
    final rank = item.effect.value('rank');
    final amount = item.effect.amount?.toInt();
    if (rank is! String || amount == null || amount <= 0) return null;
    final label = switch (rank) {
      'twoPair' => '투페어',
      'threeOfAKind' => '트리플',
      'straight' => '스트레이트',
      'flush' => '플러시',
      'fullHouse' => '풀하우스',
      'fourOfAKind' => '포카드',
      'straightFlush' => '스티플',
      'prismStraight' => '프리즘 스트레이트',
      'crownFourOfAKind' => '크라운 포카드',
      'lowStraightFlush' => '로우 스티플',
      'royalStraightFlush' => '로열 스티플',
      'fiveOfAKind' => '파이브 카드',
      'flushHouse' => '플러시 하우스',
      'flushFive' => '플러시 파이브',
      _ => null,
    };
    if (label == null) return null;
    return '$label 성장 +$amount';
  }

  ItemPresentationEvent? _marketUsePresentation(
    RummiMarketItemSlotView slot,
    ItemDefinition item,
  ) {
    if (item.effect.op != 'reroll_item_offers_only') return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(slot.placement),
      sourceLabel: localizedItemSlotName(context, slot),
      target: const ItemPresentationTarget(
        kind: ItemPresentationTargetKind.itemOffer,
        label: 'Item 후보 영역',
      ),
      resultLabel: '후보 교체 완료',
    );
  }

  int? _marketUseGoldGain(ItemDefinition item) {
    final amount = item.effect.amount;
    if (item.effect.op != 'gain_gold' || amount == null) return null;
    return amount.toInt();
  }

  Widget? _ownedMarketItemActionPane(
    BuildContext context,
    RummiMarketItemSlotView slot,
  ) {
    final item = slot.item;
    if (item == null) return null;
    final sellAction = _MarketActionPane(
      priceLabel: '+${item.sellPrice}',
      buttonLabel: '판매',
      buttonColor: GameUiPalette.actionDanger,
      onPressed: () => _sellMarketItem(slot),
    );
    if (item.effect.timing == 'use_market' ||
        item.effect.timing == 'use_market_if_gold_lte') {
      return _MarketUseSellActionPane(
        count: slot.count,
        sellPrice: item.sellPrice,
        onUse: () => _useSelectedMarketItem(slot),
        onSell: () => _sellMarketItem(slot),
        denyActive: _marketDenyTarget == 'item-use',
        denyTick: _marketDenyTick,
        denyReason: _marketDenyReason,
      );
    }
    if (item.effect.timing == 'market_buy' ||
        item.effect.timing == 'market_buy_if_category') {
      return sellAction;
    }
    return sellAction;
  }

  void _sellOwned(int index) {
    final marketBeforeSell = _market;
    if (index < 0 || index >= marketBeforeSell.ownedEntries.length) return;
    final soldEntry = marketBeforeSell.ownedEntries[index];
    final startOffset = _flightCenterForKey(_jesterSlotKey(index));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellOwnedJester(index);
    if (!ok) return;
    showBottomNotice(context, '제스터를 판매했습니다.');
    _mutate(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startJesterSaleFlight(
        entry: soldEntry,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      if (market.ownedEntries.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(0, market.ownedEntries.length - 1);
      }
    });
    _queueStateSave();
  }

  void _sellMarketItem(RummiMarketItemSlotView slot) {
    final marketBeforeSell = _market;
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellMarketItem(item);
    if (!ok) return;
    showBottomNotice(context, '아이템을 판매했습니다.');
    _mutate(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startSaleFlight(
        slot: slot,
        item: item,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      _selectedItemSlotIndex = -1;
      _selectFirstEntry(_offerEntriesForLane(market, _currentOfferLane));
    });
    _queueStateSave();
  }
}
