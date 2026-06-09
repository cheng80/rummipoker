import 'dart:math';

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
    int? originalRerollCost,
    int? tileRerollCost,
    int? originalTileRerollCost,
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
    int? originalItemRerollCost,
    this.quickSlotRerollCost = RummiRunProgress.shopBaseRerollCost,
    int? originalQuickSlotRerollCost,
    this.passiveRerollCost = RummiRunProgress.shopBaseRerollCost,
    int? originalPassiveRerollCost,
    this.toolRerollCost = RummiRunProgress.shopBaseRerollCost,
    int? originalToolRerollCost,
    this.gearRerollCost = RummiRunProgress.shopBaseRerollCost,
    int? originalGearRerollCost,
    this.itemOffers = const [],
    this.tileOffers = const [],
    this.addedDeckTiles = const [],
    this.itemSlots = const [],
  }) : originalRerollCost = originalRerollCost ?? rerollCost,
       tileRerollCost = tileRerollCost ?? rerollCost,
       originalTileRerollCost =
           originalTileRerollCost ?? tileRerollCost ?? rerollCost,
       originalItemRerollCost = originalItemRerollCost ?? itemRerollCost,
       originalQuickSlotRerollCost =
           originalQuickSlotRerollCost ?? quickSlotRerollCost,
       originalPassiveRerollCost =
           originalPassiveRerollCost ?? passiveRerollCost,
       originalToolRerollCost = originalToolRerollCost ?? toolRerollCost,
       originalGearRerollCost = originalGearRerollCost ?? gearRerollCost;

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
    final effectiveJesterRerollCost = progress.effectiveRerollCost();
    final effectiveTileRerollCost = progress.effectiveTileRerollCost();
    final effectiveItemRerollCost = progress.effectiveItemRerollCost();
    final effectiveQuickSlotRerollCost = progress.effectiveItemRerollCostFor(
      ItemPlacement.quickSlot,
    );
    final effectivePassiveRerollCost = progress.effectiveItemRerollCostFor(
      ItemPlacement.passiveRack,
    );
    final effectiveToolRerollCost = progress.effectiveItemRerollCostFor(
      ItemPlacement.inventory,
    );
    final effectiveGearRerollCost = progress.effectiveItemRerollCostFor(
      ItemPlacement.equipped,
    );
    final pendingRerollDiscount = _pendingOwnedMarketRerollDiscount(
      progress,
      itemCatalog,
    );
    return RummiMarketRuntimeFacade(
      gold: progress.gold,
      rerollCost: _applyPendingRerollDiscount(
        effectiveJesterRerollCost,
        pendingRerollDiscount,
      ),
      originalRerollCost: progress.rerollCost,
      tileRerollCost: _applyPendingRerollDiscount(
        effectiveTileRerollCost,
        pendingRerollDiscount,
      ),
      originalTileRerollCost: progress.tileRerollCost,
      itemRerollCost: _applyPendingRerollDiscount(
        effectiveItemRerollCost,
        pendingRerollDiscount,
      ),
      originalItemRerollCost: progress.itemRerollCost,
      quickSlotRerollCost: _applyPendingRerollDiscount(
        effectiveQuickSlotRerollCost,
        pendingRerollDiscount,
      ),
      originalQuickSlotRerollCost: progress.quickSlotRerollCost,
      passiveRerollCost: _applyPendingRerollDiscount(
        effectivePassiveRerollCost,
        pendingRerollDiscount,
      ),
      originalPassiveRerollCost: progress.passiveRerollCost,
      toolRerollCost: _applyPendingRerollDiscount(
        effectiveToolRerollCost,
        pendingRerollDiscount,
      ),
      originalToolRerollCost: progress.toolRerollCost,
      gearRerollCost: _applyPendingRerollDiscount(
        effectiveGearRerollCost,
        pendingRerollDiscount,
      ),
      originalGearRerollCost: progress.gearRerollCost,
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
      originalRerollCost: originalRerollCost,
      tileRerollCost: tileRerollCost,
      originalTileRerollCost: originalTileRerollCost,
      itemRerollCost: itemRerollCost,
      originalItemRerollCost: originalItemRerollCost,
      quickSlotRerollCost: quickSlotRerollCost,
      originalQuickSlotRerollCost: originalQuickSlotRerollCost,
      passiveRerollCost: passiveRerollCost,
      originalPassiveRerollCost: originalPassiveRerollCost,
      toolRerollCost: toolRerollCost,
      originalToolRerollCost: originalToolRerollCost,
      gearRerollCost: gearRerollCost,
      originalGearRerollCost: originalGearRerollCost,
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
  final int originalRerollCost;
  final int tileRerollCost;
  final int originalTileRerollCost;
  final int itemRerollCost;
  final int originalItemRerollCost;
  final int quickSlotRerollCost;
  final int originalQuickSlotRerollCost;
  final int passiveRerollCost;
  final int originalPassiveRerollCost;
  final int toolRerollCost;
  final int originalToolRerollCost;
  final int gearRerollCost;
  final int originalGearRerollCost;
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

  int originalItemRerollCostFor(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => originalQuickSlotRerollCost,
      ItemPlacement.passiveRack => originalPassiveRerollCost,
      ItemPlacement.inventory => originalToolRerollCost,
      ItemPlacement.equipped => originalGearRerollCost,
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

int _applyPendingRerollDiscount(int cost, int discount) {
  if (cost <= 0 || discount <= 0) return cost;
  return max(0, cost - discount);
}

int _pendingOwnedMarketRerollDiscount(
  RummiRunProgress progress,
  ItemCatalog? catalog,
) {
  if (catalog == null) return 0;
  for (final entry in progress.itemInventory.ownedItems) {
    if (entry.count <= 0 || !entry.isActive) continue;
    final item = catalog.findById(entry.itemId);
    if (item == null ||
        item.effect.timing != 'market_reroll' ||
        !item.effect.consume) {
      continue;
    }
    return switch (item.effect.op) {
      'free_next_reroll' => RummiRunProgress.shopBaseRerollCost,
      'discount_next_reroll' => item.effect.amount?.toInt() ?? 0,
      _ => 0,
    };
  }
  return 0;
}
