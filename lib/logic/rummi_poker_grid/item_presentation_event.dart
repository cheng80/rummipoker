import 'item_effect_runtime.dart';

enum ItemPresentationSourceKind { quickSlot, passive, tool, gear, jester }

enum ItemPresentationTargetKind {
  gold,
  marketOffer,
  marketReroll,
  itemOffer,
  confirm,
  boardResource,
  hand,
  deck,
  settlement,
  bossReward,
}

class ItemPresentationTarget {
  const ItemPresentationTarget({
    required this.kind,
    required this.label,
    this.key,
  });

  final ItemPresentationTargetKind kind;
  final String label;
  final String? key;
}

class ItemPresentationEvent {
  const ItemPresentationEvent({
    required this.itemId,
    required this.sourceKind,
    required this.sourceLabel,
    required this.target,
    required this.resultLabel,
    this.effectEvent,
  });

  final String itemId;
  final ItemPresentationSourceKind sourceKind;
  final String sourceLabel;
  final ItemPresentationTarget target;
  final String resultLabel;
  final ItemEffectEvent? effectEvent;
}
