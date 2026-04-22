import 'item_definition.dart';
import 'jester_meta.dart';

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
  });

  factory RummiMarketOwnedEntryView.fromRunProgress(
    RummiRunProgress progress,
    int slotIndex,
  ) {
    final card = progress.ownedJesters[slotIndex];
    return RummiMarketOwnedEntryView(
      slotIndex: slotIndex,
      category: RummiMarketCategory.jester,
      contentId: card.id,
      displayName: card.displayName,
      sellPrice: progress.sellPriceAt(slotIndex),
      card: card,
    );
  }

  final int slotIndex;
  final RummiMarketCategory category;
  final String contentId;
  final String displayName;
  final int sellPrice;
  final RummiJesterCard card;
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

class RummiMarketRuntimeFacade {
  const RummiMarketRuntimeFacade({
    required this.gold,
    required this.rerollCost,
    required this.maxOwnedSlots,
    required this.runtimeSnapshot,
    required this.ownedEntries,
    required this.offers,
    required this.itemOfferSlotCount,
    this.itemOffers = const [],
  });

  factory RummiMarketRuntimeFacade.fromRunProgress(RummiRunProgress progress) {
    return RummiMarketRuntimeFacade(
      gold: progress.gold,
      rerollCost: progress.effectiveRerollCost(),
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: progress.buildRuntimeSnapshot(),
      ownedEntries: List<RummiMarketOwnedEntryView>.generate(
        progress.ownedJesters.length,
        (index) => RummiMarketOwnedEntryView.fromRunProgress(progress, index),
        growable: false,
      ),
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
      itemOffers: const [],
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
      itemOffers: nextItemOffers,
    );
  }

  final int gold;
  final int rerollCost;
  final int maxOwnedSlots;
  final RummiJesterRuntimeSnapshot runtimeSnapshot;
  final List<RummiMarketOwnedEntryView> ownedEntries;
  final List<RummiMarketOfferView> offers;
  final int itemOfferSlotCount;
  final List<RummiMarketItemOfferView> itemOffers;
}
