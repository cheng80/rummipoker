import 'jester_meta.dart';

/// V4 target-term facade over the current Jester-only shop runtime.
///
/// Important:
/// - This is a read-only adapter.
/// - It does not replace `RummiShopOffer`, `ownedJesters`, or shop logic.
/// - It lets future Market-oriented docs/UI inspect current runtime state
///   without forcing an early refactor of `jester_meta.dart`.
enum RummiMarketCategory { jester }

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
    required this.card,
  });

  factory RummiMarketOfferView.fromShopOffer(RummiShopOffer offer) {
    return RummiMarketOfferView(
      offerId: 'jester:${offer.slotIndex}:${offer.card.id}',
      slotIndex: offer.slotIndex,
      category: RummiMarketCategory.jester,
      contentId: offer.card.id,
      displayName: offer.card.displayName,
      price: offer.price,
      currency: 'gold',
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
  final RummiJesterCard card;
}

class RummiMarketRuntimeFacade {
  const RummiMarketRuntimeFacade({
    required this.gold,
    required this.rerollCost,
    required this.maxOwnedSlots,
    required this.ownedEntries,
    required this.offers,
  });

  factory RummiMarketRuntimeFacade.fromRunProgress(RummiRunProgress progress) {
    return RummiMarketRuntimeFacade(
      gold: progress.gold,
      rerollCost: progress.rerollCost,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      ownedEntries: List<RummiMarketOwnedEntryView>.generate(
        progress.ownedJesters.length,
        (index) => RummiMarketOwnedEntryView.fromRunProgress(progress, index),
        growable: false,
      ),
      offers: progress.shopOffers
          .map(RummiMarketOfferView.fromShopOffer)
          .toList(growable: false),
    );
  }

  final int gold;
  final int rerollCost;
  final int maxOwnedSlots;
  final List<RummiMarketOwnedEntryView> ownedEntries;
  final List<RummiMarketOfferView> offers;
}
