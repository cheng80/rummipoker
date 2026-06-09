part of 'rummi_market_facade.dart';

List<RummiMarketItemOfferView> _buildItemOffers(
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
  final consumedIds = progress.marketModifiers.consumedItemOfferIds
      .map(canonicalItemId)
      .toSet();
  final pinnedKeys = progress.marketModifiers.pinnedItemOfferKeys;
  final shouldUsePinnedOffers = pinnedKeys.isNotEmpty;
  final candidates = items
      .where((item) => !consumedIds.contains(item.id))
      .where((item) => !_isExperimentalRitualItem(item))
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
  final candidatesById = {for (final item in candidates) item.id: item};
  final offers = <RummiMarketItemOfferView>[];
  final nextPinnedKeys = shouldUsePinnedOffers
      ? List<String>.from(pinnedKeys)
      : <String>[];
  var generatedMissingPinnedPlacement = false;
  for (final placement in ItemPlacement.values) {
    final pinnedKeysForPlacement = pinnedKeys
        .where(
          (key) => RummiMarketModifierState.itemOfferKeyMatchesPlacement(
            key,
            placement,
          ),
        )
        .toList(growable: false);
    if (pinnedKeysForPlacement.isNotEmpty) {
      final pinnedItems = <ItemDefinition>[];
      for (final key in pinnedKeysForPlacement) {
        final itemId = RummiMarketModifierState.itemIdFromOfferKey(key);
        final item = candidatesById[itemId];
        if (item == null || pinnedItems.any((entry) => entry.id == item.id)) {
          continue;
        }
        pinnedItems.add(item);
      }
      if (pinnedItems.isNotEmpty) {
        for (final item in pinnedItems) {
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
        continue;
      }
      generatedMissingPinnedPlacement = true;
      continue;
    }

    if (shouldUsePinnedOffers) {
      generatedMissingPinnedPlacement = true;
    }
    final pickedItems = _pickWeightedItemOffers(
      progress,
      candidates
          .where((item) => item.placement == placement)
          .where((item) => !_isExperimentalRitualItem(item))
          .toList(growable: false),
      items.where((item) => !_isExperimentalRitualItem(item)).toList(),
      placement: placement,
      pressureProfile: pressureProfile,
    );
    for (final item in pickedItems) {
      nextPinnedKeys.add(
        RummiMarketModifierState.itemOfferKey(item.placement, item.id),
      );
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
  if (!shouldUsePinnedOffers || generatedMissingPinnedPlacement) {
    progress.pinCurrentItemOfferKeys(nextPinnedKeys);
  }
  progress.recordSeenMarketItems(offers.map((offer) => offer.contentId));
  return offers;
}

bool _isExperimentalRitualItem(ItemDefinition item) {
  if (!item.tags.contains('ritual')) return false;
  return !_isActiveRitualMarketItem(item);
}

bool _isActiveRitualMarketItem(ItemDefinition item) {
  return switch (item.id) {
    'trim_rank' ||
    'line_pruner' ||
    'fate_three_kind_high' ||
    'color_concord' ||
    'step_rite' ||
    'rank_concord' ||
    'fate_full_house_low' ||
    'flush_house_fate' ||
    'flush_five_fate' ||
    'fate_flush_high' ||
    'fate_flush_low' ||
    'fate_straight_high' ||
    'fate_straight_low' ||
    'wild_thread' ||
    'off_color_rite' ||
    'number_mask' ||
    'trim_color' ||
    'deadwood_burn' ||
    'sacrifice_line' ||
    'sealed_copy' ||
    'scarce_copy' ||
    'color_echo' ||
    'rank_echo' ||
    'edge_copy' ||
    'keystone_copy' ||
    'line_memory' ||
    'bridge_rite' ||
    'diagonal_rite' ||
    'center_rite' ||
    'corner_rite' ||
    'cross_rite' ||
    'cross_memory' => true,
    _ => false,
  };
}

_CompassDiscountedOffers _applyCheapestFirstOfferDiscount(
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

bool _canAppearAsItemOffer({
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

bool _hasSellableOwnedItemInPlacement(
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

List<RummiMarketTileOfferView> _buildTileOffers(RummiRunProgress progress) {
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

List<ItemDefinition> _pickWeightedItemOffers(
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
  final missingGrowthTags = _missingGrowthTagsForMarket(progress, catalogItems);
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

ItemDefinition _pickWeightedItemFromPool({
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

int _itemOfferWeight({
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

int _itemCollectionWeightBonus(RummiRunProgress progress, ItemDefinition item) {
  var bonus = 0;
  // 개별 미수집 후보가 긴 run에서 계속 밀리지 않게 하는 약한 수집 보강.
  // 성장축 보강과 마찬가지로 등장 확률만 조정하며 직접 지급하지 않는다.
  if (!progress.boughtItemIds.contains(item.id)) bonus += 45;
  if (!progress.seenMarketItemIds.contains(item.id)) bonus += 90;
  return bonus;
}

int? _missingGrowthFocusSlot(
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
  final pressureBonus = pressureProfile == RummiMarketPressureProfile.highStakes
      ? 15
      : 0;
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

int _itemOfferSlotCount(
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

String? _itemOfferSlotBonusLabel(RummiRunProgress progress) {
  final bonusSlots = progress.marketModifiers.extraItemOfferSlots;
  if (bonusSlots <= 0) return null;
  return '렌즈 +$bonusSlots';
}

String? _jesterOfferSlotBonusLabel(RummiRunProgress progress) {
  final bonusSlots = progress.marketModifiers.extraJesterOfferSlots;
  if (bonusSlots <= 0) return null;
  return '트로피 +$bonusSlots';
}

bool _hasAnyTag(List<String> tags, Set<String> expectedTags) {
  for (final tag in tags) {
    if (expectedTags.contains(tag)) {
      return true;
    }
  }
  return false;
}

Set<String> _missingGrowthTagsForMarket(
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

int _stableMarketRoll(
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

List<RummiMarketItemSlotView> _buildItemSlots(
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
  final pendingSlotUnlocks = progress.snapshotPendingSlotUnlockPresentations();

  for (var index = 0; index < RunInventoryState.maxQuickSlotCapacity; index++) {
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
