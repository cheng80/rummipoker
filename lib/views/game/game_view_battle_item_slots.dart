part of '../game_view.dart';

RummiBattleRuntimeFacade _resolveBattleItemSlots({
  required RummiBattleRuntimeFacade battle,
  required ItemCatalog? catalog,
  required RummiRunProgress? runProgress,
}) {
  final inventory = runProgress?.itemInventory;
  if (catalog == null ||
      runProgress == null ||
      inventory == null ||
      inventory.ownedItems.isEmpty) {
    return battle;
  }

  final quickSlotCapacity = runProgress.quickSlotCapacity(itemCatalog: catalog);
  final itemInstances = OwnedContentInstances.itemInstances(
    inventory: inventory,
    catalog: catalog,
  );
  final instancesById = {
    for (final instance in itemInstances) instance.id: instance,
  };
  final itemSlots = <RummiBattleItemSlotView>[];
  var slotIndex = 0;

  for (final itemId in inventory.quickSlotItemIds.take(quickSlotCapacity)) {
    final instance = instancesById[itemId];
    if (instance == null) continue;
    itemSlots.add(
      RummiBattleItemSlotView.fromInstance(
        slotIndex: slotIndex,
        slotLabel: 'Q${slotIndex + 1}',
        instance: instance,
      ),
    );
    slotIndex += 1;
  }

  var passiveSlotIndex = 0;
  for (final itemId in inventory.passiveRelicIds.take(
    kBattlePassiveSlotDisplayCount,
  )) {
    final instance = instancesById[itemId];
    if (instance == null) continue;
    itemSlots.add(
      RummiBattleItemSlotView.fromInstance(
        slotIndex: slotIndex,
        slotLabel: 'P${passiveSlotIndex + 1}',
        instance: instance,
      ),
    );
    slotIndex += 1;
    passiveSlotIndex += 1;
  }

  var toolSlotIndex = 0;
  for (final instance in itemInstances.where(
    (item) => item.placement == ItemPlacement.inventory,
  )) {
    if (toolSlotIndex >= kBattleToolSlotDisplayCount) break;
    itemSlots.add(
      RummiBattleItemSlotView.fromInstance(
        slotIndex: slotIndex,
        slotLabel: 'T${toolSlotIndex + 1}',
        instance: instance,
      ),
    );
    slotIndex += 1;
    toolSlotIndex += 1;
  }

  var gearSlotIndex = 0;
  for (final itemId in inventory.equippedItemIds.take(
    kBattleGearSlotDisplayCount,
  )) {
    final instance = instancesById[itemId];
    if (instance == null) continue;
    itemSlots.add(
      RummiBattleItemSlotView.fromInstance(
        slotIndex: slotIndex,
        slotLabel: 'G${gearSlotIndex + 1}',
        instance: instance,
      ),
    );
    slotIndex += 1;
    gearSlotIndex += 1;
  }

  return battle.withItemSlots(
    itemSlots,
    quickSlotCapacity: quickSlotCapacity,
    passiveRelicCapacity: runProgress.passiveRelicCapacity(
      itemCatalog: catalog,
    ),
  );
}
