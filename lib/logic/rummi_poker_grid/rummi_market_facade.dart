import 'item_definition.dart';
import 'jester_meta.dart';
import 'owned_content_instance.dart';

/// V4 target-term facade over the current Jester-only shop runtime.
///
/// Important:
/// - This is a read-only adapter.
/// - It does not replace `RummiShopOffer`, `ownedJesters`, or shop logic.
/// - It lets future Market-oriented docs/UI inspect current runtime state
///   without forcing an early refactor of `jester_meta.dart`.
enum RummiMarketCategory { jester, item }

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
    required this.currency,
    required this.isAffordable,
    required this.card,
  });

  factory RummiMarketOfferView.fromShopOffer(
    RummiShopOffer offer, {
    required int currentGold,
    int? price,
  }) {
    final resolvedPrice = price ?? offer.price;
    return RummiMarketOfferView(
      offerId: 'jester:${offer.slotIndex}:${offer.card.id}',
      slotIndex: offer.slotIndex,
      category: RummiMarketCategory.jester,
      contentId: offer.card.id,
      displayName: offer.card.displayName,
      price: resolvedPrice,
      currency: 'gold',
      isAffordable: currentGold >= resolvedPrice,
      card: offer.card,
    );
  }

  final String offerId;
  final int slotIndex;
  final RummiMarketCategory category;
  final String contentId;
  final String displayName;
  final int price;
  final String currency;
  final bool isAffordable;
  final RummiJesterCard card;
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
    required this.currency,
    required this.isAffordable,
    required this.item,
  });

  factory RummiMarketItemOfferView.fromItemDefinition(
    ItemDefinition item, {
    required int slotIndex,
    required int currentGold,
    int? price,
  }) {
    final resolvedPrice = price ?? item.basePrice;
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
      currency: 'gold',
      isAffordable: currentGold >= resolvedPrice,
      item: item,
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
  final String currency;
  final bool isAffordable;
  final ItemDefinition item;
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

  bool get isEmpty => contentId == null;
}

class RummiMarketRuntimeFacade {
  const RummiMarketRuntimeFacade({
    required this.gold,
    required this.rerollCost,
    required this.maxOwnedSlots,
    required this.runtimeSnapshot,
    required this.ownedEntries,
    required this.offers,
    required this.itemOfferSlotCount,
    required this.quickSlotCapacity,
    this.itemOffers = const [],
    this.itemSlots = const [],
  });

  factory RummiMarketRuntimeFacade.fromRunProgress(
    RummiRunProgress progress, {
    ItemCatalog? itemCatalog,
  }) {
    return RummiMarketRuntimeFacade(
      gold: progress.gold,
      rerollCost: progress.effectiveRerollCost(),
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
      offers: progress.shopOffers
          .map(
            (offer) => RummiMarketOfferView.fromShopOffer(
              offer,
              currentGold: progress.gold,
              price: progress.effectiveJesterOfferPrice(offer.slotIndex),
            ),
          )
          .toList(growable: false),
      itemOfferSlotCount: progress.marketModifiers.itemOfferSlotCount,
      quickSlotCapacity: progress.quickSlotCapacity(itemCatalog: itemCatalog),
      itemOffers: itemCatalog == null
          ? const []
          : _buildItemOffers(progress, itemCatalog),
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
      maxOwnedSlots: maxOwnedSlots,
      runtimeSnapshot: runtimeSnapshot,
      ownedEntries: ownedEntries,
      offers: offers,
      itemOfferSlotCount: itemOfferSlotCount,
      quickSlotCapacity: quickSlotCapacity,
      itemOffers: nextItemOffers,
      itemSlots: itemSlots,
    );
  }

  final int gold;
  final int rerollCost;
  final int maxOwnedSlots;
  final RummiJesterRuntimeSnapshot runtimeSnapshot;
  final List<RummiMarketOwnedEntryView> ownedEntries;
  final List<RummiMarketOfferView> offers;
  final int itemOfferSlotCount;
  final int quickSlotCapacity;
  final List<RummiMarketItemOfferView> itemOffers;
  final List<RummiMarketItemSlotView> itemSlots;

  static List<RummiMarketItemOfferView> _buildItemOffers(
    RummiRunProgress progress,
    ItemCatalog catalog,
  ) {
    final items = catalog.all;
    if (items.isEmpty) return const [];
    final offset =
        progress.marketModifiers.itemOfferRerollOffset % items.length;
    final rotatedItems = offset == 0
        ? items
        : <ItemDefinition>[...items.skip(offset), ...items.take(offset)];
    final quickSlotCapacity = progress.quickSlotCapacity(itemCatalog: catalog);
    final passiveRelicCapacity = progress.passiveRelicCapacity(
      itemCatalog: catalog,
    );
    final consumedIds = progress.marketModifiers.consumedItemOfferIds.toSet();
    final candidates = rotatedItems
        .where((item) => !consumedIds.contains(item.id))
        .where(
          (item) => progress.itemInventory.canAcquire(
            item,
            quickSlotCapacity: quickSlotCapacity,
            passiveRelicCapacity: passiveRelicCapacity,
          ),
        )
        .take(progress.marketModifiers.itemOfferSlotCount)
        .toList(growable: false);
    return candidates
        .asMap()
        .entries
        .map(
          (entry) => RummiMarketItemOfferView.fromItemDefinition(
            entry.value,
            slotIndex: entry.key,
            currentGold: progress.gold,
            price: progress.effectiveItemPrice(entry.value),
          ),
        )
        .toList(growable: false);
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
