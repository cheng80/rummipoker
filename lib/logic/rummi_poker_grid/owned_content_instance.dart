import 'item_definition.dart';
import 'jester_meta.dart';

class OwnedItemInstance {
  const OwnedItemInstance({required this.entry, required this.definition});

  final OwnedItemEntry entry;
  final ItemDefinition definition;

  String get id => definition.id;
  int get count => entry.count;
  ItemPlacement get placement => entry.placement;
  bool get isActive => entry.isActive;
  bool get usableInBattle => definition.usableInBattle;
  String get displayName => definition.displayName;
  String get displayNameKey => definition.displayNameKey;
  String get effectText => definition.effectText;
  String get effectTextKey => definition.effectTextKey;
}

class OwnedJesterInstance {
  const OwnedJesterInstance({
    required this.slotIndex,
    required this.card,
    required this.stateValue,
  });

  final int slotIndex;
  final RummiJesterCard card;
  final int stateValue;

  String get id => card.id;
  String get displayName => card.displayName;
}

class OwnedContentInstances {
  const OwnedContentInstances._();

  static List<OwnedItemInstance> itemInstances({
    required RunInventoryState inventory,
    required ItemCatalog catalog,
  }) {
    final instances = <OwnedItemInstance>[];
    for (final entry in inventory.ownedItems) {
      final definition = catalog.findById(entry.itemId);
      if (definition == null) continue;
      instances.add(OwnedItemInstance(entry: entry, definition: definition));
    }
    return List<OwnedItemInstance>.unmodifiable(instances);
  }

  static List<OwnedJesterInstance> jesterInstances(RummiRunProgress progress) {
    final snapshot = progress.buildRuntimeSnapshot();
    return List<OwnedJesterInstance>.unmodifiable(
      List<OwnedJesterInstance>.generate(
        progress.ownedJesters.length,
        (slotIndex) => OwnedJesterInstance(
          slotIndex: slotIndex,
          card: progress.ownedJesters[slotIndex],
          stateValue: snapshot.stateValueForSlot(slotIndex),
        ),
        growable: false,
      ),
    );
  }
}
