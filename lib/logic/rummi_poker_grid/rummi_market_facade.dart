import 'item_definition.dart';
import 'jester_meta.dart';
import 'models/tile.dart';
import 'owned_content_instance.dart';

/// V4 target-term facade over the current Jester-only shop runtime.
///
/// Important:
/// - This is a read-only adapter.
/// - It does not replace `RummiShopOffer`, `ownedJesters`, or shop logic.
/// - It lets future Market-oriented docs/UI inspect current runtime state
///   without forcing an early refactor of `jester_meta.dart`.
enum RummiMarketCategory { jester, item, tile }

class RummiMarketOwnedEntryView {
  const RummiMarketOwnedEntryView({
    required this.slotIndex,
    required this.category,
    required this.contentId,
    required this.displayName,
    required this.sellPrice,
    required this.card,
    this.stateValue = 0,
    this.instance,
  });

  factory RummiMarketOwnedEntryView.fromRunProgress(
    RummiRunProgress progress,
    int slotIndex, {
    ItemCatalog? itemCatalog,
  }) {
    return RummiMarketOwnedEntryView.fromJesterInstance(
      progress,
      OwnedContentInstances.jesterInstances(progress)[slotIndex],
      itemCatalog: itemCatalog,
    );
  }

  factory RummiMarketOwnedEntryView.fromJesterInstance(
    RummiRunProgress progress,
    OwnedJesterInstance instance, {
    ItemCatalog? itemCatalog,
  }) {
    return RummiMarketOwnedEntryView(
      slotIndex: instance.slotIndex,
      category: RummiMarketCategory.jester,
      contentId: instance.id,
      displayName: instance.displayName,
      stateValue: instance.stateValue,
      sellPrice: progress.sellPriceAt(
        instance.slotIndex,
        itemCatalog: itemCatalog,
      ),
      card: instance.card,
      instance: instance,
    );
  }

  final int slotIndex;
  final RummiMarketCategory category;
  final String contentId;
  final String displayName;
  final int stateValue;
  final int sellPrice;
  final RummiJesterCard card;
  final OwnedJesterInstance? instance;
}

class RummiMarketOfferView {
  const RummiMarketOfferView({
    required this.offerId,
    required this.slotIndex,
    required this.category,
    required this.contentId,
    required this.displayName,
    required this.price,
    int? originalPrice,
    required this.currency,
    required this.isAffordable,
    required this.card,
    this.discountSourceLabel,
  }) : originalPrice = originalPrice ?? price;

  factory RummiMarketOfferView.fromShopOffer(
    RummiShopOffer offer, {
    required int currentGold,
    int? price,
    int? originalPrice,
    String? discountSourceLabel,
  }) {
    final resolvedPrice = price ?? offer.price;
    final resolvedOriginalPrice = originalPrice ?? resolvedPrice;
    return RummiMarketOfferView(
      offerId: 'jester:${offer.slotIndex}:${offer.card.id}',
      slotIndex: offer.slotIndex,
      category: RummiMarketCategory.jester,
      contentId: offer.card.id,
      displayName: offer.card.displayName,
      price: resolvedPrice,
      originalPrice: resolvedOriginalPrice,
      currency: 'gold',
      isAffordable: currentGold >= resolvedPrice,
      card: offer.card,
      discountSourceLabel: discountSourceLabel,
    );
  }

  final String offerId;
  final int slotIndex;
  final RummiMarketCategory category;
  final String contentId;
  final String displayName;
  final int price;
  final int originalPrice;
  final String currency;
  final bool isAffordable;
  final RummiJesterCard card;
  final String? discountSourceLabel;

  int get discountAmount => (originalPrice - price).clamp(0, originalPrice);
  bool get hasDiscount => discountAmount > 0;
}

class RummiMarketItemOfferView {
  const RummiMarketItemOfferView({
    required this.offerId,
    required this.slotIndex,
    required this.category,
    required this.contentId,
    required this.displayName,
    required this.displayNameKey,
    required this.effectText,
    required this.effectTextKey,
    required this.price,
    int? originalPrice,
    required this.currency,
    required this.isAffordable,
    required this.item,
    this.discountSourceLabel,
  }) : originalPrice = originalPrice ?? price;

  factory RummiMarketItemOfferView.fromItemDefinition(
    ItemDefinition item, {
    required int slotIndex,
    required int currentGold,
    int? price,
    int? originalPrice,
    String? discountSourceLabel,
  }) {
    final resolvedPrice = price ?? item.basePrice;
    final resolvedOriginalPrice = originalPrice ?? resolvedPrice;
    return RummiMarketItemOfferView(
      offerId: 'item:$slotIndex:${item.id}',
      slotIndex: slotIndex,
      category: RummiMarketCategory.item,
      contentId: item.id,
      displayName: item.displayName,
      displayNameKey: item.displayNameKey,
      effectText: item.effectText,
      effectTextKey: item.effectTextKey,
      price: resolvedPrice,
      originalPrice: resolvedOriginalPrice,
      currency: 'gold',
      isAffordable: currentGold >= resolvedPrice,
      item: item,
      discountSourceLabel: discountSourceLabel,
    );
  }

  final String offerId;
  final int slotIndex;
  final RummiMarketCategory category;
  final String contentId;
  final String displayName;
  final String displayNameKey;
  final String effectText;
  final String effectTextKey;
  final int price;
  final int originalPrice;
  final String currency;
  final bool isAffordable;
  final ItemDefinition item;
  final String? discountSourceLabel;

  int get discountAmount => (originalPrice - price).clamp(0, originalPrice);
  bool get hasDiscount => discountAmount > 0;
}

class RummiMarketTileOfferView {
  const RummiMarketTileOfferView({
    required this.offerId,
    required this.slotIndex,
    required this.tile,
    required this.price,
    required this.currency,
    required this.isAffordable,
    required this.isFreeReward,
  });

  factory RummiMarketTileOfferView.fromTile(
    Tile tile, {
    required int slotIndex,
    required int currentGold,
    required int price,
    required bool isFreeReward,
  }) {
    return RummiMarketTileOfferView(
      offerId: 'tile:$slotIndex:${tile.code}',
      slotIndex: slotIndex,
      tile: tile,
      price: price,
      currency: 'gold',
      isAffordable: currentGold >= price,
      isFreeReward: isFreeReward,
    );
  }

  final String offerId;
  final int slotIndex;
  final Tile tile;
  final int price;
  final String currency;
  final bool isAffordable;
  final bool isFreeReward;
}

class RummiMarketItemSlotView {
  const RummiMarketItemSlotView({
    required this.slotIndex,
    required this.slotLabel,
    required this.placement,
    this.contentId,
    this.displayName,
    this.displayNameKey,
    this.effectText,
    this.effectTextKey,
    this.item,
    this.count = 0,
    this.locked = false,
    this.recentlyUnlocked = false,
  });

  factory RummiMarketItemSlotView.fromOwnedItem({
    required int slotIndex,
    required String slotLabel,
    required OwnedItemEntry entry,
    required ItemDefinition item,
  }) {
    return RummiMarketItemSlotView.fromInstance(
      slotIndex: slotIndex,
      slotLabel: slotLabel,
      instance: OwnedItemInstance(entry: entry, definition: item),
    );
  }

  factory RummiMarketItemSlotView.fromInstance({
    required int slotIndex,
    required String slotLabel,
    required OwnedItemInstance instance,
  }) {
    return RummiMarketItemSlotView(
      slotIndex: slotIndex,
      slotLabel: slotLabel,
      placement: instance.placement,
      contentId: instance.id,
      displayName: instance.displayName,
      displayNameKey: instance.displayNameKey,
      effectText: instance.effectText,
      effectTextKey: instance.effectTextKey,
      item: instance.definition,
      count: instance.count,
      recentlyUnlocked: false,
    );
  }

  final int slotIndex;
  final String slotLabel;
  final ItemPlacement placement;
  final String? contentId;
  final String? displayName;
  final String? displayNameKey;
  final String? effectText;
  final String? effectTextKey;
  final ItemDefinition? item;
  final int count;
  final bool locked;
  final bool recentlyUnlocked;

  bool get isEmpty => contentId == null;
}

class RummiMarketRuntimeFacade {
  const RummiMarketRuntimeFacade({
    required this.gold,
    required this.rerollCost,
    int? tileRerollCost,
    required this.maxOwnedSlots,
    required this.runtimeSnapshot,
    required this.ownedEntries,
    required this.offers,
    required this.itemOfferSlotCount,
    this.itemOfferSlotBonusLabel,
    required this.quickSlotCapacity,
    this.jesterSlotCapacity = RummiRunProgress.baseUnlockedJesterSlots,
    this.pendingSlotUnlockPresentations = const <RummiSlotUnlockKind>{},
    this.itemRerollCost = RummiRunProgress.shopBaseRerollCost,
    this.quickSlotRerollCost = RummiRunProgress.shopBaseRerollCost,
    this.passiveRerollCost = RummiRunProgress.shopBaseRerollCost,
    this.toolRerollCost = RummiRunProgress.shopBaseRerollCost,
    this.gearRerollCost = RummiRunProgress.shopBaseRerollCost,
    this.itemOffers = const [],
    this.tileOffers = const [],
    this.addedDeckTiles = const [],
    this.itemSlots = const [],
  }) : tileRerollCost = tileRerollCost ?? rerollCost;

  factory RummiMarketRuntimeFacade.fromRunProgress(
    RummiRunProgress progress, {
    ItemCatalog? itemCatalog,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final jesterOffers = [
      for (var index = 0; index < progress.shopOffers.length; index++)
        RummiMarketOfferView.fromShopOffer(
          progress.shopOffers[index],
          currentGold: progress.gold,
          price: progress.effectiveJesterOfferPrice(
            index,
            includeCheapestFirstOfferDiscount: false,
          ),
          originalPrice: progress.effectiveJesterOfferBasePrice(index),
        ),
    ];
    final itemOffers = itemCatalog == null
        ? const <RummiMarketItemOfferView>[]
        : _buildItemOffers(
            progress,
            itemCatalog,
            pressureProfile: pressureProfile,
          );
    final compassDiscountedOffers = _applyCheapestFirstOfferDiscount(
      progress,
      jesterOffers: jesterOffers,
      itemOffers: itemOffers,
    );
    return RummiMarketRuntimeFacade(
      gold: progress.gold,
      rerollCost: progress.effectiveRerollCost(),
      tileRerollCost: progress.effectiveTileRerollCost(),
      itemRerollCost: progress.effectiveItemRerollCost(),
      quickSlotRerollCost: progress.effectiveItemRerollCostFor(
        ItemPlacement.quickSlot,
      ),
      passiveRerollCost: progress.effectiveItemRerollCostFor(
        ItemPlacement.passiveRack,
      ),
      toolRerollCost: progress.effectiveItemRerollCostFor(
        ItemPlacement.inventory,
      ),
      gearRerollCost: progress.effectiveItemRerollCostFor(
        ItemPlacement.equipped,
      ),
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
      ownedEntries: OwnedContentInstances.jesterInstances(progress)
          .map(
            (instance) => RummiMarketOwnedEntryView.fromJesterInstance(
              progress,
              instance,
              itemCatalog: itemCatalog,
            ),
          )
          .toList(growable: false),
      offers: compassDiscountedOffers.jesterOffers,
      itemOfferSlotCount: _itemOfferSlotCount(
        progress,
        pressureProfile: pressureProfile,
      ),
      itemOfferSlotBonusLabel: _itemOfferSlotBonusLabel(progress),
      quickSlotCapacity: progress.quickSlotCapacity(itemCatalog: itemCatalog),
      jesterSlotCapacity: progress.jesterSlotCapacity(itemCatalog: itemCatalog),
      pendingSlotUnlockPresentations: progress
          .snapshotPendingSlotUnlockPresentations(),
      itemOffers: compassDiscountedOffers.itemOffers,
      tileOffers: _buildTileOffers(progress),
      addedDeckTiles: List<Tile>.unmodifiable(progress.addedDeckTiles),
      itemSlots: itemCatalog == null
          ? const []
          : _buildItemSlots(progress, itemCatalog),
    );
  }

  RummiMarketRuntimeFacade withItemOffers(
    List<RummiMarketItemOfferView> nextItemOffers,
  ) {
    return RummiMarketRuntimeFacade(
      gold: gold,
      rerollCost: rerollCost,
      tileRerollCost: tileRerollCost,
      itemRerollCost: itemRerollCost,
      quickSlotRerollCost: quickSlotRerollCost,
      passiveRerollCost: passiveRerollCost,
      toolRerollCost: toolRerollCost,
      gearRerollCost: gearRerollCost,
      maxOwnedSlots: maxOwnedSlots,
      runtimeSnapshot: runtimeSnapshot,
      ownedEntries: ownedEntries,
      offers: offers,
      itemOfferSlotCount: itemOfferSlotCount,
      itemOfferSlotBonusLabel: itemOfferSlotBonusLabel,
      quickSlotCapacity: quickSlotCapacity,
      jesterSlotCapacity: jesterSlotCapacity,
      pendingSlotUnlockPresentations: pendingSlotUnlockPresentations,
      itemOffers: nextItemOffers,
      tileOffers: tileOffers,
      addedDeckTiles: addedDeckTiles,
      itemSlots: itemSlots,
    );
  }

  final int gold;
  final int rerollCost;
  final int tileRerollCost;
  final int itemRerollCost;
  final int quickSlotRerollCost;
  final int passiveRerollCost;
  final int toolRerollCost;
  final int gearRerollCost;
  final int maxOwnedSlots;
  final RummiJesterRuntimeSnapshot runtimeSnapshot;
  final List<RummiMarketOwnedEntryView> ownedEntries;
  final List<RummiMarketOfferView> offers;
  final int itemOfferSlotCount;
  final String? itemOfferSlotBonusLabel;
  final int quickSlotCapacity;
  final int jesterSlotCapacity;
  final Set<RummiSlotUnlockKind> pendingSlotUnlockPresentations;
  final List<RummiMarketItemOfferView> itemOffers;
  final List<RummiMarketTileOfferView> tileOffers;
  final List<Tile> addedDeckTiles;
  final List<RummiMarketItemSlotView> itemSlots;

  int itemRerollCostFor(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => quickSlotRerollCost,
      ItemPlacement.passiveRack => passiveRerollCost,
      ItemPlacement.inventory => toolRerollCost,
      ItemPlacement.equipped => gearRerollCost,
    };
  }

  static List<RummiMarketItemOfferView> _buildItemOffers(
    RummiRunProgress progress,
    ItemCatalog catalog, {
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final items = catalog.all;
    if (items.isEmpty) return const [];
    final quickSlotCapacity = progress.quickSlotCapacity(itemCatalog: catalog);
    final passiveRelicCapacity = progress.passiveRelicCapacity(
      itemCatalog: catalog,
    );
    final consumedIds = progress.marketModifiers.consumedItemOfferIds.toSet();
    final candidates = items
        .where((item) => !consumedIds.contains(item.id))
        .where(
          (item) => _canAppearAsItemOffer(
            progress: progress,
            catalog: catalog,
            item: item,
            quickSlotCapacity: quickSlotCapacity,
            passiveRelicCapacity: passiveRelicCapacity,
          ),
        )
        .toList(growable: false);
    final offers = <RummiMarketItemOfferView>[];
    for (final placement in ItemPlacement.values) {
      final pickedItems = _pickWeightedItemOffers(
        progress,
        candidates
            .where((item) => item.placement == placement)
            .toList(growable: false),
        items,
        placement: placement,
        pressureProfile: pressureProfile,
      );
      for (final item in pickedItems) {
        offers.add(
          RummiMarketItemOfferView.fromItemDefinition(
            item,
            slotIndex: offers.length,
            currentGold: progress.gold,
            price: progress.effectiveItemPrice(
              item,
              includeCheapestFirstOfferDiscount: false,
            ),
            originalPrice: progress.effectiveItemBasePrice(item),
          ),
        );
      }
    }
    progress.recordSeenMarketItems(offers.map((offer) => offer.contentId));
    return offers;
  }

  static _CompassDiscountedOffers _applyCheapestFirstOfferDiscount(
    RummiRunProgress progress, {
    required List<RummiMarketOfferView> jesterOffers,
    required List<RummiMarketItemOfferView> itemOffers,
  }) {
    final discount = progress.marketModifiers.cheapestFirstOfferDiscount;
    if (discount <= 0) {
      return _CompassDiscountedOffers(
        jesterOffers: jesterOffers,
        itemOffers: itemOffers,
      );
    }

    var bestCategory = '';
    var bestIndex = -1;
    var bestPrice = 1 << 30;
    for (var i = 0; i < jesterOffers.length; i++) {
      final price = jesterOffers[i].price;
      if (price > 0 && price < bestPrice) {
        bestCategory = 'jester';
        bestIndex = i;
        bestPrice = price;
      }
    }
    for (var i = 0; i < itemOffers.length; i++) {
      final price = itemOffers[i].price;
      if (price > 0 && price < bestPrice) {
        bestCategory = 'item';
        bestIndex = i;
        bestPrice = price;
      }
    }
    if (bestIndex < 0) {
      return _CompassDiscountedOffers(
        jesterOffers: jesterOffers,
        itemOffers: itemOffers,
      );
    }

    final appliedDiscount = bestPrice < discount ? bestPrice : discount;
    if (bestCategory == 'jester') {
      final nextJesters = List<RummiMarketOfferView>.of(jesterOffers);
      final offer = nextJesters[bestIndex];
      nextJesters[bestIndex] = RummiMarketOfferView.fromShopOffer(
        progress.shopOffers[bestIndex],
        currentGold: progress.gold,
        price: offer.price - appliedDiscount,
        originalPrice: offer.originalPrice,
        discountSourceLabel: '나침반',
      );
      return _CompassDiscountedOffers(
        jesterOffers: List<RummiMarketOfferView>.unmodifiable(nextJesters),
        itemOffers: itemOffers,
      );
    }

    final nextItems = List<RummiMarketItemOfferView>.of(itemOffers);
    final offer = nextItems[bestIndex];
    nextItems[bestIndex] = RummiMarketItemOfferView.fromItemDefinition(
      offer.item,
      slotIndex: offer.slotIndex,
      currentGold: progress.gold,
      price: offer.price - appliedDiscount,
      originalPrice: offer.originalPrice,
      discountSourceLabel: '나침반',
    );
    return _CompassDiscountedOffers(
      jesterOffers: jesterOffers,
      itemOffers: List<RummiMarketItemOfferView>.unmodifiable(nextItems),
    );
  }

  static bool _canAppearAsItemOffer({
    required RummiRunProgress progress,
    required ItemCatalog catalog,
    required ItemDefinition item,
    required int quickSlotCapacity,
    required int passiveRelicCapacity,
  }) {
    if (progress.itemInventory.canAcquire(
      item,
      quickSlotCapacity: quickSlotCapacity,
      passiveRelicCapacity: passiveRelicCapacity,
    )) {
      return true;
    }

    final ownsSameItem = progress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id,
    );
    if (ownsSameItem) return false;

    return _hasSellableOwnedItemInPlacement(progress, catalog, item.placement);
  }

  static bool _hasSellableOwnedItemInPlacement(
    RummiRunProgress progress,
    ItemCatalog catalog,
    ItemPlacement placement,
  ) {
    for (final entry in progress.itemInventory.ownedItems) {
      if (entry.placement != placement) continue;
      final item = catalog.findById(entry.itemId);
      if (item != null && item.sellable) return true;
    }
    return false;
  }

  static List<RummiMarketTileOfferView> _buildTileOffers(
    RummiRunProgress progress,
  ) {
    return [
      for (var i = 0; i < progress.tileOffers.length; i++)
        RummiMarketTileOfferView.fromTile(
          progress.tileOffers[i],
          slotIndex: i,
          currentGold: progress.gold,
          price: progress.effectiveTileOfferPrice(i),
          isFreeReward: false,
        ),
    ];
  }

  static List<ItemDefinition> _pickWeightedItemOffers(
    RummiRunProgress progress,
    List<ItemDefinition> candidates,
    List<ItemDefinition> catalogItems, {
    required ItemPlacement placement,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    if (candidates.isEmpty) return const [];
    final policy = RummiStationBandMarketPolicy.forStage(
      progress.stageIndex,
      pressureProfile: pressureProfile,
    );
    final missingGrowthTags = _missingGrowthTagsForMarket(
      progress,
      catalogItems,
    );
    final remaining = List<ItemDefinition>.from(candidates);
    final picked = <ItemDefinition>[];
    final slotCount = _itemOfferSlotCount(
      progress,
      pressureProfile: pressureProfile,
    );
    final offset = progress.marketModifiers.itemOfferRerollOffsetFor(placement);
    final focusSlot = _missingGrowthFocusSlot(
      progress.stageIndex,
      offset,
      missingGrowthTags,
      slotCount,
      pressureProfile: pressureProfile,
    );
    for (var slot = 0; slot < slotCount && remaining.isNotEmpty; slot++) {
      final focusCandidates = slot == focusSlot
          ? remaining
                .where((item) => _hasAnyTag(item.tags, missingGrowthTags))
                .toList(growable: false)
          : const <ItemDefinition>[];
      if (focusCandidates.isNotEmpty) {
        final selected = _pickWeightedItemFromPool(
          policy: policy,
          candidates: focusCandidates,
          progress: progress,
          missingGrowthTags: missingGrowthTags,
          stageIndex: progress.stageIndex,
          offset: offset,
          slotIndex: slot,
        );
        picked.add(selected);
        remaining.remove(selected);
        continue;
      }

      final totalWeight = remaining.fold<int>(
        0,
        (sum, item) =>
            sum +
            _itemOfferWeight(
              progress: progress,
              policy: policy,
              item: item,
              missingGrowthTags: missingGrowthTags,
            ),
      );
      var roll = _stableMarketRoll(
        totalWeight,
        stageIndex: progress.stageIndex,
        offset: offset,
        slotIndex: slot,
      );
      var selectedIndex = remaining.length - 1;
      for (var index = 0; index < remaining.length; index++) {
        roll -= _itemOfferWeight(
          progress: progress,
          policy: policy,
          item: remaining[index],
          missingGrowthTags: missingGrowthTags,
        );
        if (roll < 0) {
          selectedIndex = index;
          break;
        }
      }
      picked.add(remaining.removeAt(selectedIndex));
    }
    return picked;
  }

  static ItemDefinition _pickWeightedItemFromPool({
    required RummiStationBandMarketPolicy policy,
    required List<ItemDefinition> candidates,
    required RummiRunProgress progress,
    required Set<String> missingGrowthTags,
    required int stageIndex,
    required int offset,
    required int slotIndex,
  }) {
    final totalWeight = candidates.fold<int>(
      0,
      (sum, item) =>
          sum +
          _itemOfferWeight(
            progress: progress,
            policy: policy,
            item: item,
            missingGrowthTags: missingGrowthTags,
          ),
    );
    var roll = _stableMarketRoll(
      totalWeight,
      stageIndex: stageIndex,
      offset: offset,
      slotIndex: slotIndex,
    );
    for (final item in candidates) {
      roll -= _itemOfferWeight(
        progress: progress,
        policy: policy,
        item: item,
        missingGrowthTags: missingGrowthTags,
      );
      if (roll < 0) {
        return item;
      }
    }
    return candidates.last;
  }

  static int _itemOfferWeight({
    required RummiRunProgress progress,
    required RummiStationBandMarketPolicy policy,
    required ItemDefinition item,
    required Set<String> missingGrowthTags,
  }) {
    return policy.itemOfferWeight(
      item,
      missingGrowthTags: missingGrowthTags,
      collectionWeightBonus: _itemCollectionWeightBonus(progress, item),
    );
  }

  static int _itemCollectionWeightBonus(
    RummiRunProgress progress,
    ItemDefinition item,
  ) {
    var bonus = 0;
    // 개별 미수집 후보가 긴 run에서 계속 밀리지 않게 하는 약한 수집 보강.
    // 성장축 보강과 마찬가지로 등장 확률만 조정하며 직접 지급하지 않는다.
    if (!progress.boughtItemIds.contains(item.id)) bonus += 45;
    if (!progress.seenMarketItemIds.contains(item.id)) bonus += 90;
    return bonus;
  }

  static int? _missingGrowthFocusSlot(
    int stageIndex,
    int offset,
    Set<String> missingGrowthTags,
    int slotCount, {
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    if (missingGrowthTags.isEmpty || stageIndex <= 2 || slotCount <= 0) {
      return null;
    }
    final chance = stageIndex >= 6
        ? 55
        : stageIndex >= 4
        ? 45
        : 35;
    final pressureBonus =
        pressureProfile == RummiMarketPressureProfile.highStakes ? 15 : 0;
    final roll = _stableMarketRoll(
      100,
      stageIndex: stageIndex,
      offset: offset,
      slotIndex: 97,
    );
    if (roll >= chance + pressureBonus) return null;
    return _stableMarketRoll(
      slotCount,
      stageIndex: stageIndex,
      offset: offset,
      slotIndex: 98,
    );
  }

  static int _itemOfferSlotCount(
    RummiRunProgress progress, {
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final base = progress.marketModifiers.itemOfferSlotCount;
    if (pressureProfile != RummiMarketPressureProfile.highStakes) {
      return base;
    }
    return progress.stageIndex >= 3 ? base + 1 : base;
  }

  static String? _itemOfferSlotBonusLabel(RummiRunProgress progress) {
    final bonusSlots = progress.marketModifiers.extraItemOfferSlots;
    if (bonusSlots <= 0) return null;
    return '렌즈 +$bonusSlots';
  }

  static bool _hasAnyTag(List<String> tags, Set<String> expectedTags) {
    for (final tag in tags) {
      if (expectedTags.contains(tag)) {
        return true;
      }
    }
    return false;
  }

  static Set<String> _missingGrowthTagsForMarket(
    RummiRunProgress progress,
    List<ItemDefinition> catalogItems,
  ) {
    final station = progress.stageIndex < 1 ? 1 : progress.stageIndex;
    if (station <= 2) return const {};

    final catalogById = {for (final item in catalogItems) item.id: item};
    final ownedTags = <String>{};
    for (final entry in progress.itemInventory.ownedItems) {
      final item = catalogById[entry.itemId];
      if (item != null) {
        ownedTags.addAll(item.tags);
      }
    }

    final missing = <String>{};
    final hasScoreGrowth =
        ownedTags.contains('score') ||
        ownedTags.contains('rank') ||
        ownedTags.contains('tile_color');
    if (!hasScoreGrowth) {
      missing.addAll(const ['score', 'rank', 'tile_color']);
    }

    if (station >= 4) {
      final hasTacticalResource =
          ownedTags.contains('discard') ||
          ownedTags.contains('move') ||
          ownedTags.contains('safety');
      if (!hasTacticalResource) {
        missing.addAll(const ['discard', 'move', 'safety']);
      }
    }

    if (station >= 6) {
      final hasBossGrowth =
          ownedTags.contains('boss') ||
          ownedTags.contains('xmult') ||
          ownedTags.contains('legendary');
      if (!hasBossGrowth) {
        missing.addAll(const ['boss', 'xmult', 'legendary']);
      }
    }

    return Set<String>.unmodifiable(missing);
  }

  static int _stableMarketRoll(
    int totalWeight, {
    required int stageIndex,
    required int offset,
    required int slotIndex,
  }) {
    if (totalWeight <= 0) return 0;
    final seed = '$stageIndex:$offset:$slotIndex:station_band_market_policy_v1';
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash % totalWeight;
  }

  static List<RummiMarketItemSlotView> _buildItemSlots(
    RummiRunProgress progress,
    ItemCatalog catalog,
  ) {
    final inventory = progress.itemInventory;
    final instancesById = {
      for (final instance in OwnedContentInstances.itemInstances(
        inventory: inventory,
        catalog: catalog,
      ))
        instance.id: instance,
    };
    final slots = <RummiMarketItemSlotView>[];
    var slotIndex = 0;
    final quickSlotCapacity = progress.quickSlotCapacity(itemCatalog: catalog);
    final pendingSlotUnlocks = progress
        .snapshotPendingSlotUnlockPresentations();

    for (
      var index = 0;
      index < RunInventoryState.maxQuickSlotCapacity;
      index++
    ) {
      final locked = index >= quickSlotCapacity;
      final itemId = index < inventory.quickSlotItemIds.length
          ? inventory.quickSlotItemIds[index]
          : null;
      final instance = itemId == null ? null : instancesById[itemId];
      if (instance != null && !locked) {
        slots.add(
          RummiMarketItemSlotView.fromInstance(
            slotIndex: slotIndex,
            slotLabel: 'Q${index + 1}',
            instance: instance,
          ),
        );
      } else {
        slots.add(
          RummiMarketItemSlotView(
            slotIndex: slotIndex,
            slotLabel: 'Q${index + 1}',
            placement: ItemPlacement.quickSlot,
            locked: locked,
            recentlyUnlocked:
                pendingSlotUnlocks.contains(RummiSlotUnlockKind.quickSlot) &&
                index == quickSlotCapacity - 1,
          ),
        );
      }
      slotIndex += 1;
    }

    final passiveRelicCapacity = progress.passiveRelicCapacity(
      itemCatalog: catalog,
    );
    for (
      var index = 0;
      index < RunInventoryState.maxPassiveRelicCapacity;
      index++
    ) {
      final locked = index >= passiveRelicCapacity;
      final itemId = index < inventory.passiveRelicIds.length
          ? inventory.passiveRelicIds[index]
          : null;
      final instance = itemId == null ? null : instancesById[itemId];
      if (instance != null && !locked) {
        slots.add(
          RummiMarketItemSlotView.fromInstance(
            slotIndex: slotIndex,
            slotLabel: 'P${index + 1}',
            instance: instance,
          ),
        );
      } else {
        slots.add(
          RummiMarketItemSlotView(
            slotIndex: slotIndex,
            slotLabel: 'P${index + 1}',
            placement: ItemPlacement.passiveRack,
            locked: locked,
            recentlyUnlocked:
                pendingSlotUnlocks.contains(RummiSlotUnlockKind.passiveRelic) &&
                index == passiveRelicCapacity - 1,
          ),
        );
      }
      slotIndex += 1;
    }

    var toolIndex = 0;
    for (final instance in instancesById.values.where(
      (item) => item.placement == ItemPlacement.inventory,
    )) {
      if (toolIndex >= 3) break;
      slots.add(
        RummiMarketItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'T${toolIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      toolIndex += 1;
    }
    for (; toolIndex < 3; toolIndex++) {
      slots.add(
        RummiMarketItemSlotView(
          slotIndex: slotIndex,
          slotLabel: 'T${toolIndex + 1}',
          placement: ItemPlacement.inventory,
        ),
      );
      slotIndex += 1;
    }

    var gearIndex = 0;
    for (final itemId in inventory.equippedItemIds.take(2)) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      slots.add(
        RummiMarketItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'G${gearIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      gearIndex += 1;
    }
    for (; gearIndex < 2; gearIndex++) {
      slots.add(
        RummiMarketItemSlotView(
          slotIndex: slotIndex,
          slotLabel: 'G${gearIndex + 1}',
          placement: ItemPlacement.equipped,
        ),
      );
      slotIndex += 1;
    }
    return List<RummiMarketItemSlotView>.unmodifiable(slots);
  }
}

class _CompassDiscountedOffers {
  const _CompassDiscountedOffers({
    required this.jesterOffers,
    required this.itemOffers,
  });

  final List<RummiMarketOfferView> jesterOffers;
  final List<RummiMarketItemOfferView> itemOffers;
}
