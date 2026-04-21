import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

enum ItemType { consumable, equipment, passiveRelic, utility }

enum ItemRarity { common, uncommon, rare, legendary }

enum ItemPlacement { inventory, quickSlot, equipped, passiveRack }

class ItemEffectDefinition {
  const ItemEffectDefinition({
    required this.timing,
    required this.op,
    required this.amount,
    required this.consume,
    required this.raw,
  });

  factory ItemEffectDefinition.fromJson(Map<String, dynamic> json) {
    return ItemEffectDefinition(
      timing: json['timing'] as String? ?? '',
      op: json['op'] as String? ?? '',
      amount: json['amount'] as num?,
      consume: json['consume'] as bool? ?? false,
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final String timing;
  final String op;
  final num? amount;
  final bool consume;
  final Map<String, dynamic> raw;

  Object? value(String key) => raw[key];
}

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.displayName,
    required this.displayNameKey,
    required this.type,
    required this.rarity,
    required this.basePrice,
    required this.sellPrice,
    required this.stackable,
    required this.maxStack,
    required this.sellable,
    required this.usableInBattle,
    required this.placement,
    required this.slotHint,
    required this.effectText,
    required this.effectTextKey,
    required this.effect,
    required this.tags,
    required this.sourceNotes,
  });

  factory ItemDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    return ItemDefinition(
      id: id,
      displayName: json['displayName'] as String? ?? id,
      displayNameKey:
          json['displayNameKey'] as String? ?? 'data.items.$id.displayName',
      type: _typeFromString(json['type'] as String?),
      rarity: _rarityFromString(json['rarity'] as String?),
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toInt() ?? 0,
      stackable: json['stackable'] as bool? ?? false,
      maxStack: (json['maxStack'] as num?)?.toInt() ?? 1,
      sellable: json['sellable'] as bool? ?? true,
      usableInBattle: json['usableInBattle'] as bool? ?? false,
      placement: _placementFromString(json['placement'] as String?),
      slotHint: json['slotHint'] as String? ?? '',
      effectText: json['effectText'] as String? ?? '',
      effectTextKey:
          json['effectTextKey'] as String? ?? 'data.items.$id.effectText',
      effect: ItemEffectDefinition.fromJson(
        (json['effect'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      sourceNotes: json['sourceNotes'] as String? ?? '',
    );
  }

  final String id;
  final String displayName;
  final String displayNameKey;
  final ItemType type;
  final ItemRarity rarity;
  final int basePrice;
  final int sellPrice;
  final bool stackable;
  final int maxStack;
  final bool sellable;
  final bool usableInBattle;
  final ItemPlacement placement;
  final String slotHint;
  final String effectText;
  final String effectTextKey;
  final ItemEffectDefinition effect;
  final List<String> tags;
  final String sourceNotes;

  bool get isConsumable => type == ItemType.consumable;
  bool get isPassive => type == ItemType.passiveRelic;

  static ItemType _typeFromString(String? value) {
    return switch (value) {
      'equipment' => ItemType.equipment,
      'passive_relic' => ItemType.passiveRelic,
      'utility' => ItemType.utility,
      _ => ItemType.consumable,
    };
  }

  static ItemRarity _rarityFromString(String? value) {
    return switch (value) {
      'uncommon' => ItemRarity.uncommon,
      'rare' => ItemRarity.rare,
      'legendary' => ItemRarity.legendary,
      _ => ItemRarity.common,
    };
  }

  static ItemPlacement _placementFromString(String? value) {
    return switch (value) {
      'quickSlot' => ItemPlacement.quickSlot,
      'equipped' => ItemPlacement.equipped,
      'passiveRack' => ItemPlacement.passiveRack,
      _ => ItemPlacement.inventory,
    };
  }
}

class ItemCatalog {
  const ItemCatalog._({
    required this.schemaVersion,
    required this.catalogId,
    required this.rarityWeights,
    required List<ItemDefinition> items,
  }) : _items = items;

  factory ItemCatalog.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return ItemCatalog.fromJson(decoded);
  }

  factory ItemCatalog.fromJson(Map<String, dynamic> json) {
    final rarityWeights = <ItemRarity, int>{};
    final rawWeights =
        (json['rarityWeights'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    for (final entry in rawWeights.entries) {
      rarityWeights[ItemDefinition._rarityFromString(entry.key)] =
          (entry.value as num?)?.toInt() ?? 0;
    }

    final items = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ItemDefinition.fromJson)
        .toList(growable: false);

    return ItemCatalog._(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      catalogId: json['catalogId'] as String? ?? '',
      rarityWeights: Map<ItemRarity, int>.unmodifiable(rarityWeights),
      items: items,
    );
  }

  static Future<ItemCatalog> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return ItemCatalog.fromJsonString(jsonString);
  }

  final int schemaVersion;
  final String catalogId;
  final Map<ItemRarity, int> rarityWeights;
  final List<ItemDefinition> _items;

  List<ItemDefinition> get all => List<ItemDefinition>.unmodifiable(_items);

  ItemDefinition? findById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<ItemDefinition> byType(ItemType type) {
    return _items.where((item) => item.type == type).toList(growable: false);
  }

  List<ItemDefinition> byPlacement(ItemPlacement placement) {
    return _items
        .where((item) => item.placement == placement)
        .toList(growable: false);
  }
}

class OwnedItemEntry {
  const OwnedItemEntry({
    required this.itemId,
    required this.count,
    required this.placement,
    this.isActive = true,
  });

  factory OwnedItemEntry.fromJson(Map<String, dynamic> json) {
    return OwnedItemEntry(
      itemId: json['itemId'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      placement: ItemDefinition._placementFromString(
        json['placement'] as String?,
      ),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String itemId;
  final int count;
  final ItemPlacement placement;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'count': count,
    'placement': placement.persistenceValue,
    'isActive': isActive,
  };
}

class RunInventoryState {
  const RunInventoryState({
    this.ownedItems = const [],
    this.equippedItemIds = const [],
    this.passiveRelicIds = const [],
    this.quickSlotItemIds = const [],
  });

  factory RunInventoryState.fromJson(Map<String, dynamic> json) {
    return RunInventoryState(
      ownedItems: (json['ownedItems'] as List<dynamic>? ?? const [])
          .map(
            (value) =>
                OwnedItemEntry.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false),
      equippedItemIds: _stringListFromJson(json['equippedItemIds']),
      passiveRelicIds: _stringListFromJson(json['passiveRelicIds']),
      quickSlotItemIds: _stringListFromJson(json['quickSlotItemIds']),
    );
  }

  final List<OwnedItemEntry> ownedItems;
  final List<String> equippedItemIds;
  final List<String> passiveRelicIds;
  final List<String> quickSlotItemIds;

  bool get isEmpty =>
      ownedItems.isEmpty &&
      equippedItemIds.isEmpty &&
      passiveRelicIds.isEmpty &&
      quickSlotItemIds.isEmpty;

  bool canAcquire(ItemDefinition item) {
    final existingIndex = ownedItems.indexWhere(
      (entry) => entry.itemId == item.id,
    );
    if (existingIndex < 0) return true;
    if (!item.stackable) return false;
    return ownedItems[existingIndex].count < item.maxStack;
  }

  RunInventoryState withAcquiredItem(ItemDefinition item) {
    if (!canAcquire(item)) return this;

    final nextOwnedItems = List<OwnedItemEntry>.of(ownedItems);
    final existingIndex = nextOwnedItems.indexWhere(
      (entry) => entry.itemId == item.id,
    );
    if (existingIndex >= 0) {
      final existing = nextOwnedItems[existingIndex];
      nextOwnedItems[existingIndex] = OwnedItemEntry(
        itemId: existing.itemId,
        count: existing.count + 1,
        placement: existing.placement,
        isActive: existing.isActive,
      );
    } else {
      nextOwnedItems.add(
        OwnedItemEntry(itemId: item.id, count: 1, placement: item.placement),
      );
    }

    return RunInventoryState(
      ownedItems: List<OwnedItemEntry>.unmodifiable(nextOwnedItems),
      equippedItemIds: _idsWithPlacementItem(
        equippedItemIds,
        item,
        ItemPlacement.equipped,
      ),
      passiveRelicIds: _idsWithPlacementItem(
        passiveRelicIds,
        item,
        ItemPlacement.passiveRack,
      ),
      quickSlotItemIds: _idsWithPlacementItem(
        quickSlotItemIds,
        item,
        ItemPlacement.quickSlot,
      ),
    );
  }

  RunInventoryState withConsumedItem(String itemId) {
    final existingIndex = ownedItems.indexWhere(
      (entry) => entry.itemId == itemId,
    );
    if (existingIndex < 0) return this;

    final existing = ownedItems[existingIndex];
    final nextOwnedItems = List<OwnedItemEntry>.of(ownedItems);
    if (existing.count > 1) {
      nextOwnedItems[existingIndex] = OwnedItemEntry(
        itemId: existing.itemId,
        count: existing.count - 1,
        placement: existing.placement,
        isActive: existing.isActive,
      );
    } else {
      nextOwnedItems.removeAt(existingIndex);
    }

    final removed = existing.count <= 1;
    return RunInventoryState(
      ownedItems: List<OwnedItemEntry>.unmodifiable(nextOwnedItems),
      equippedItemIds: removed
          ? _idsWithoutItem(equippedItemIds, itemId)
          : equippedItemIds,
      passiveRelicIds: removed
          ? _idsWithoutItem(passiveRelicIds, itemId)
          : passiveRelicIds,
      quickSlotItemIds: removed
          ? _idsWithoutItem(quickSlotItemIds, itemId)
          : quickSlotItemIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownedItems': ownedItems.map((item) => item.toJson()).toList(),
    'equippedItemIds': equippedItemIds,
    'passiveRelicIds': passiveRelicIds,
    'quickSlotItemIds': quickSlotItemIds,
  };

  static List<String> _stringListFromJson(Object? value) {
    return (value as List<dynamic>? ?? const []).whereType<String>().toList(
      growable: false,
    );
  }

  static List<String> _idsWithPlacementItem(
    List<String> currentIds,
    ItemDefinition item,
    ItemPlacement placement,
  ) {
    if (item.placement != placement || currentIds.contains(item.id)) {
      return List<String>.unmodifiable(currentIds);
    }
    return List<String>.unmodifiable([...currentIds, item.id]);
  }

  static List<String> _idsWithoutItem(List<String> currentIds, String itemId) {
    return List<String>.unmodifiable(currentIds.where((id) => id != itemId));
  }
}

extension ItemPlacementPersistence on ItemPlacement {
  String get persistenceValue {
    return switch (this) {
      ItemPlacement.inventory => 'inventory',
      ItemPlacement.quickSlot => 'quickSlot',
      ItemPlacement.equipped => 'equipped',
      ItemPlacement.passiveRack => 'passiveRack',
    };
  }
}
