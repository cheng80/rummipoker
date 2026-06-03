part of 'game_session_notifier.dart';

mixin GameSessionNotifierMarketCommands
    on FamilyNotifier<GameSessionState, GameSessionArgs> {
  void _replaceState(GameSessionState next);
  RummiMarketPressureProfile _marketPressureProfileFor(NewRunModifier modifier);

  /// 상점 열기: 오퍼 생성.
  void openShop({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    final catalog = state.jesterCatalog;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    if (itemCatalog != null) {
      final results = ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: itemCatalog,
        runProgress: runProgress,
      );
      final pendingItemPresentationEvents = [
        ...state.pendingItemPresentationEvents,
        ..._itemPresentationEventsForMarketResults(
          catalog: itemCatalog,
          results: results,
        ),
      ];
      _replaceState(
        state.copyWith(
          pendingItemPresentationEvents: pendingItemPresentationEvents,
          revision: state.revision + 1,
        ),
      );
      return;
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 캐시아웃 뒤 market 진입 준비를 notifier 경계에서 처리한다.
  void enterMarketAfterCashOut({ItemCatalog? itemCatalog}) {
    openShop(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.market,
        activeRunScene: ActiveRunScene.shop,
        revision: state.revision + 1,
      ),
    );
  }

  void markSlotUnlockPresentationShown() {
    final runProgress = state.runProgress;
    if (runProgress == null ||
        runProgress.snapshotPendingSlotUnlockPresentations().isEmpty) {
      return;
    }
    runProgress.clearPendingSlotUnlockPresentations();
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  String? rerollShopFromState({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final catalog =
        state.jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[];
    return rerollShop(
      catalog: catalog,
      rng: session.runRandom,
      itemCatalog: itemCatalog,
    );
  }

  String? rerollItemOffersFromState({
    ItemCatalog? itemCatalog,
    ItemPlacement placement = ItemPlacement.inventory,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      itemRerollPlacement: placement,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollItemOffers(placement: placement);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? rerollTileOffersFromState({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollTileOffers(rng: session.runRandom);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollShop(
      catalog: catalog,
      rng: rng,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketRerollItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
    ItemPlacement? itemRerollPlacement,
  }) {
    final cost = itemRerollPlacement != null
        ? runProgress.effectiveItemRerollCostFor(itemRerollPlacement)
        : runProgress.effectiveRerollCost();
    if (catalog == null || cost <= 0) {
      return null;
    }
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null) continue;
      if (item.effect.timing == 'market_reroll' &&
          (item.effect.op == 'free_next_reroll' ||
              item.effect.op == 'discount_next_reroll') &&
          item.effect.consume) {
        return item;
      }
    }
    return null;
  }

  List<ItemPresentationEvent> _itemPresentationEventsForMarketResults({
    required ItemCatalog catalog,
    required List<ItemUseResult> results,
  }) {
    final events = <ItemPresentationEvent>[];
    for (final result in results) {
      if (!result.isSuccess || result.events.isEmpty) continue;
      final item = catalog.findById(result.itemId);
      if (item == null) continue;
      final effectEvent = result.events.firstWhere(
        (event) => event.kind != ItemEffectEventKind.itemConsumed,
        orElse: () => result.events.first,
      );
      events.add(
        ItemPresentationEvent(
          itemId: item.id,
          sourceKind: itemPresentationSourceKindForPlacement(item.placement),
          sourceLabel: item.displayName,
          target: itemPresentationTargetForEvent(item, effectEvent),
          resultLabel: '발동: ${itemUseResultPresentationLabel(result)}',
          effectEvent: effectEvent,
        ),
      );
    }
    return List<ItemPresentationEvent>.unmodifiable(events);
  }

  String? buyShopOffer(int offerIndex, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.shopOffers.length) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= runProgress.jesterSlotCapacity()) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'jester',
    );
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final price = runProgress.effectiveJesterOfferPrice(offerIndex);
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(offerIndex);
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyShopOfferView(
    RummiMarketOfferView offer, {
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final offerIndex = runProgress.shopOffers.indexWhere(
      (entry) => entry.card.id == offer.contentId,
    );
    if (offerIndex < 0) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= runProgress.jesterSlotCapacity()) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'jester',
    );
    var price = offer.price;
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
      price = runProgress.effectiveJesterOfferPrice(
        offerIndex,
        includeCheapestFirstOfferDiscount: false,
      );
      if (offer.discountSourceLabel == '나침반') {
        price = max(
          0,
          price - runProgress.marketModifiers.cheapestFirstOfferDiscount,
        );
      }
    }
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(
      offerIndex,
      price: price,
      consumeCheapestFirstOfferDiscount: offer.discountSourceLabel == '나침반',
    );
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyItemOffer(
    RummiMarketItemOfferView offer, {
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final quickSlotCapacity = runProgress.quickSlotCapacity(
      itemCatalog: itemCatalog,
    );
    if (!runProgress.itemInventory.canAcquire(
      offer.item,
      quickSlotCapacity: quickSlotCapacity,
      passiveRelicCapacity: runProgress.passiveRelicCapacity(
        itemCatalog: itemCatalog,
      ),
    )) {
      return '이미 보유 한도에 도달한 아이템입니다.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'item',
    );
    var price = offer.price;
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
      price = runProgress.effectiveItemPrice(
        offer.item,
        includeCheapestFirstOfferDiscount: false,
      );
      if (offer.discountSourceLabel == '나침반') {
        price = max(
          0,
          price - runProgress.marketModifiers.cheapestFirstOfferDiscount,
        );
      }
    }
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyItem(
      offer.item,
      price: price,
      itemCatalog: itemCatalog,
      consumeCheapestFirstOfferDiscount: offer.discountSourceLabel == '나침반',
    );
    if (!ok) {
      return '아이템 구매 처리에 실패했습니다.';
    }
    runProgress.markItemOfferConsumed(offer.contentId);
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyTileOffer(int offerIndex) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.tileOffers.length) {
      return '구매할 타일을 찾지 못했습니다.';
    }
    final ok = runProgress.buyTileOffer(offerIndex);
    if (!ok) {
      return '골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketBuyItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
    required String category,
  }) {
    if (catalog == null) return null;
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null || item.effect.op != 'discount_next_purchase') {
        continue;
      }
      if (item.effect.timing == 'market_buy') {
        return item;
      }
      if (item.effect.timing == 'market_buy_if_category' &&
          item.effect.value('category') == category) {
        return item;
      }
    }
    return null;
  }

  String? useMarketItem(ItemDefinition item) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';

    final result = ItemEffectRuntime.applyMarketUseItem(
      item: item,
      runProgress: runProgress,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  bool sellMarketItem(ItemDefinition item) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedItem(item);
    if (!ok) return false;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return true;
  }

  /// 장착 제스터 판매. 성공 시 true.
  bool sellOwnedJester(int index, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedJester(index, itemCatalog: itemCatalog);
    if (!ok) return false;
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: null,
        revision: state.revision + 1,
      ),
    );
    return true;
  }

  bool sellSelectedJesterOverlayFromState() {
    final index = state.selectedJesterOverlayIndex;
    if (index == null) return false;
    return sellOwnedJester(index);
  }

  /// 검사용 상점 열기 (특정 오퍼 ID 지정).
  void openShopForTest({required List<String> preferredOfferIds}) {
    final session = state.session;
    final runProgress = state.runProgress;
    final catalog = state.jesterCatalog;
    if (session == null || runProgress == null) return;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: preferredOfferIds.length,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    _replaceState(state.copyWith(revision: state.revision + 1));
  }
}
