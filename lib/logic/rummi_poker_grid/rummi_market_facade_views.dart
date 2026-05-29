part of 'rummi_market_facade.dart';

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
