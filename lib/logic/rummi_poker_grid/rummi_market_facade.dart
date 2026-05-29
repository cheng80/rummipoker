import 'item_definition.dart';
import 'jester_meta.dart';
import 'models/tile.dart';
import 'owned_content_instance.dart';

part 'rummi_market_facade_views.dart';
part 'rummi_market_facade_builders.dart';

/// V4 target-term facade over the current Jester-only shop runtime.
///
/// Important:
/// - This is a read-only adapter.
/// - It does not replace `RummiShopOffer`, `ownedJesters`, or shop logic.
/// - It lets future Market-oriented docs/UI inspect current runtime state
///   without forcing an early refactor of `jester_meta.dart`.
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
    this.jesterOfferSlotBonusLabel,
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
      jesterOfferSlotBonusLabel: _jesterOfferSlotBonusLabel(progress),
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
      jesterOfferSlotBonusLabel: jesterOfferSlotBonusLabel,
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
  final String? jesterOfferSlotBonusLabel;
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
}

class _CompassDiscountedOffers {
  const _CompassDiscountedOffers({
    required this.jesterOffers,
    required this.itemOffers,
  });

  final List<RummiMarketOfferView> jesterOffers;
  final List<RummiMarketItemOfferView> itemOffers;
}
