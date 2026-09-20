part of 'game_shop_screen.dart';

extension _GameShopItemActionFlow on _GameShopScreenState {
  void _startNewAcquisitionReveal(String label) {
    final tick = _newRevealTick + 1;
    _newRevealTick = tick;
    _mutate(() => _newRevealLabel = label);
    Future<void>.delayed(GamePresentationTimings.marketNewReveal, () {
      if (!mounted || _newRevealTick != tick) return;
      _mutate(() => _newRevealLabel = null);
    });
    GameFeedback.play(GameCue.newReveal);
  }

  ActionFailure? _invokeMarketFailure(
    ActionFailure? Function()? typed,
    String? Function() legacy,
  ) {
    if (typed != null) return typed();
    final message = legacy();
    return message == null ? null : ActionFailure(null, message);
  }

  void _startMarketDenyFeedback(
    String target,
    String reason, {
    ActionFailure? failure,
  }) {
    final tick = _marketDenyTick + 1;
    _mutate(() {
      _marketDenyTick = tick;
      _marketDenyTarget = target;
      _marketDenyReason = reason;
      _marketDenyReasonBuilder = failure == null
          ? null
          : (context) => actionFailureLabel(context, failure);
    });
    Future<void>.delayed(GamePresentationTimings.marketDenyFeedbackHold, () {
      if (!mounted || _marketDenyTick != tick) return;
      _mutate(() {
        _marketDenyTarget = null;
        _marketDenyReason = null;
        _marketDenyReasonBuilder = null;
      });
    });
    GameFeedback.play(GameCue.deny);
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
      sourceItemIds: [item.id],
      consumed: item.effect.consume,
      activated: true,
      operation: market.rerollCost <= 0
          ? 'free_next_reroll'
          : 'discount_next_reroll',
      target: ItemPresentationTarget(
        kind: ItemPresentationTargetKind.marketReroll,
        label: _offerLaneLabel(lane),
      ),
      resultLabel: context.translate(
        market.rerollCost <= 0
            ? (item.effect.consume
                  ? 'marketRerollFreeConsumed'
                  : 'marketRerollFreeTriggered')
            : (item.effect.consume
                  ? 'marketRerollDiscountConsumed'
                  : 'marketRerollDiscountTriggered'),
      ),
    );
  }

  ItemPresentationEvent? _marketPurchasePresentation({
    required RummiMarketRuntimeFacade market,
    required String category,
    required String targetLabel,
    String? targetId,
    required String? discountSourceLabel,
    required bool isCompassDiscounted,
  }) {
    final purchaseSource = _activeItemSlotWhere(
      (item) =>
          item.effect.op == 'discount_next_purchase' &&
          (item.effect.timing == 'market_buy' ||
              (item.effect.timing == 'market_buy_if_category' &&
                  item.effect.value('category') == category)),
    );
    final compassSource = isCompassDiscounted
        ? _activeItemSlotWhere((item) => item.id == 'market_compass')
        : null;
    final source = purchaseSource ?? compassSource;
    final item = source?.item;
    if (source == null || item == null) {
      if (discountSourceLabel == null) return null;
      return ItemPresentationEvent(
        itemId: isCompassDiscounted ? 'market_compass' : 'market_discount',
        sourceKind: ItemPresentationSourceKind.passive,
        sourceLabel: isCompassDiscounted
            ? ItemTranslationScope.of(
                context,
              ).resolveDisplayName('market_compass', discountSourceLabel)
            : discountSourceLabel,
        target: ItemPresentationTarget(
          kind: category == 'jester'
              ? ItemPresentationTargetKind.marketOffer
              : ItemPresentationTargetKind.itemOffer,
          label: targetLabel,
          itemId: category == 'item' ? targetId : null,
          jesterId: category == 'jester' ? targetId : null,
        ),
        sourceItemIds: isCompassDiscounted ? const ['market_compass'] : null,
        consumed: false,
        activated: true,
        operation: 'discount_next_purchase',
        effectEvent: ItemEffectEvent(
          kind: ItemEffectEventKind.marketModifierQueued,
          itemId: isCompassDiscounted ? 'market_compass' : 'market_discount',
          amount: 1,
          detail: 'discount_next_purchase',
        ),
        resultLabel: context.translate(
          'marketPurchaseDiscountTriggered',
          namedArgs: {'amount': '1'},
        ),
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
      sourceItemIds: [
        item.id,
        if (purchaseSource != null && compassSource != null)
          compassSource.item!.id,
      ],
      consumed: purchaseSource?.item?.effect.consume ?? false,
      activated: true,
      operation: 'discount_next_purchase',
      effectEvent: ItemEffectEvent(
        kind: ItemEffectEventKind.marketModifierQueued,
        itemId: item.id,
        amount: discount,
        detail: 'discount_next_purchase',
      ),
      target: ItemPresentationTarget(
        kind: category == 'jester'
            ? ItemPresentationTargetKind.marketOffer
            : ItemPresentationTargetKind.itemOffer,
        label: targetLabel,
        itemId: category == 'item' ? targetId : null,
        jesterId: category == 'jester' ? targetId : null,
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
    if (discount > 0) {
      return context.translate(
        consumed
            ? 'marketPurchaseDiscountConsumed'
            : 'marketPurchaseDiscountTriggered',
        namedArgs: {'amount': '$discount'},
      );
    }
    return context.translate(
      consumed ? 'marketDiscountConsumed' : 'marketDiscountTriggered',
    );
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
    final failure = _invokeMarketFailure(
      widget.onUseMarketItemFailure == null
          ? null
          : () => widget.onUseMarketItemFailure!(item),
      () => widget.onUseMarketItem(item),
    );
    final failMessage = failure?.legacyMessage;
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage, failure: failure);
      showBottomNotice(
        context,
        failMessage,
        cue: null,
        messageBuilder: (context) => actionFailureLabel(context, failure!),
      );
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
      _marketUseFeedbackItem = item;
      _marketUseFeedbackDelta = _marketUseFeedbackDeltaLabel(context, item);
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
        _marketUseFeedbackItem = null;
        _marketUseFeedbackDelta = null;
      });
    });
    _queueStateSave();
    GameFeedback.play(GameCue.itemUse);
  }

  String? _marketUseFeedbackDeltaLabel(
    BuildContext context,
    ItemDefinition item,
  ) {
    final amount = _marketUseGoldGain(item);
    return switch (item.effect.op) {
      'gain_gold' when amount != null => '+${amount}G',
      'add_hand_rank_progress' => _marketUseRankGrowthLabel(context, item),
      'reroll_item_offers_only' => context.translate(
        'marketItemOffersReplaced',
      ),
      _ => null,
    };
  }

  String? _marketUseRankGrowthLabel(BuildContext context, ItemDefinition item) {
    final rank = item.effect.value('rank');
    final amount = item.effect.amount?.toInt();
    if (rank is! String || amount == null || amount <= 0) return null;
    final label = switch (rank) {
      'twoPair' => context.translate(rummiHandRankKey(RummiHandRank.twoPair)),
      'threeOfAKind' => context.translate(
        rummiHandRankKey(RummiHandRank.threeOfAKind),
      ),
      'straight' => context.translate(rummiHandRankKey(RummiHandRank.straight)),
      'flush' => context.translate(rummiHandRankKey(RummiHandRank.flush)),
      'fullHouse' => context.translate(
        rummiHandRankKey(RummiHandRank.fullHouse),
      ),
      'fourOfAKind' => context.translate(
        rummiHandRankKey(RummiHandRank.fourOfAKind),
      ),
      'straightFlush' => context.translate(
        rummiHandRankKey(RummiHandRank.straightFlush),
      ),
      'prismStraight' => context.translate(
        rummiHandRankKey(RummiHandRank.prismStraight),
      ),
      'crownFourOfAKind' => context.translate(
        rummiHandRankKey(RummiHandRank.crownFourOfAKind),
      ),
      'lowStraightFlush' => context.translate(
        rummiHandRankKey(RummiHandRank.lowStraightFlush),
      ),
      'royalStraightFlush' => context.translate(
        rummiHandRankKey(RummiHandRank.royalStraightFlush),
      ),
      'fiveOfAKind' => context.translate(
        rummiHandRankKey(RummiHandRank.fiveOfAKind),
      ),
      'flushHouse' => context.translate(
        rummiHandRankKey(RummiHandRank.flushHouse),
      ),
      'flushFive' => context.translate(
        rummiHandRankKey(RummiHandRank.flushFive),
      ),
      _ => null,
    };
    if (label == null) return null;
    return context.translate(
      'marketRankGrowth',
      namedArgs: {'rank': label, 'amount': '$amount'},
    );
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
      sourceItemIds: [item.id],
      consumed: item.effect.consume,
      operation: item.effect.op,
      target: ItemPresentationTarget(
        translateKind: true,
        kind: ItemPresentationTargetKind.itemOffer,
        label: context.translate('marketItemOfferArea'),
      ),
      resultLabel: context.translate('marketOffersReplaced'),
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
      buttonLabel: context.translate('marketSell'),
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
        denyReason:
            _marketDenyReasonBuilder?.call(context) ?? _marketDenyReason,
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
    showBottomNotice(
      context,
      context.translate('marketJesterSold'),
      cue: null,
      messageBuilder: (context) => context.translate('marketJesterSold'),
    );
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
    GameFeedback.play(GameCue.sell);
  }

  void _sellMarketItem(RummiMarketItemSlotView slot) {
    final marketBeforeSell = _market;
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellMarketItem(item);
    if (!ok) return;
    showBottomNotice(
      context,
      context.translate('marketItemSold'),
      cue: null,
      messageBuilder: (context) => context.translate('marketItemSold'),
    );
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
    GameFeedback.play(GameCue.sell);
  }
}
