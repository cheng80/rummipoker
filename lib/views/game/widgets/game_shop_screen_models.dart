part of 'game_shop_screen.dart';

enum _MarketShopTab { cardsAndQuickSlots, toolsAndGear }

enum _MarketOfferLane { jester, tile, quickSlot, passive, tool, gear }

enum _MarketOfferEntryKind { jester, item, tile }

enum _MarketOptionsCloseAction {
  resumeGame,
  keepPaused,
  openSettings,
  openRunInfo,
  openMarketTutorial,
}

class _MarketOfferEntry {
  const _MarketOfferEntry.jester(this.jesterIndex)
    : kind = _MarketOfferEntryKind.jester,
      itemIndex = null,
      tileIndex = null;

  const _MarketOfferEntry.item(this.itemIndex)
    : kind = _MarketOfferEntryKind.item,
      jesterIndex = null,
      tileIndex = null;

  const _MarketOfferEntry.tile(this.tileIndex)
    : kind = _MarketOfferEntryKind.tile,
      jesterIndex = null,
      itemIndex = null;

  final _MarketOfferEntryKind kind;
  final int? jesterIndex;
  final int? itemIndex;
  final int? tileIndex;
}

class _MarketPurchaseFlight {
  const _MarketPurchaseFlight({
    required this.tick,
    required this.label,
    required this.slotLabel,
    required this.item,
    required this.spentGold,
    required this.startAlignment,
    required this.endAlignment,
    required this.marketBeforePurchase,
    required this.sourceVisibleIndex,
    this.startOffset,
    this.endOffset,
    this.jesterCard,
    this.tile,
    this.itemId,
    this.itemPlacement,
    this.itemRarity,
  });

  final int tick;
  final String label;
  final String slotLabel;
  final bool item;
  final int spentGold;
  final Alignment startAlignment;
  final Alignment endAlignment;
  final RummiMarketRuntimeFacade marketBeforePurchase;
  final int sourceVisibleIndex;
  final Offset? startOffset;
  final Offset? endOffset;
  final RummiJesterCard? jesterCard;
  final Tile? tile;
  final String? itemId;
  final ItemPlacement? itemPlacement;
  final ItemRarity? itemRarity;
}

class _MarketSaleFlight {
  const _MarketSaleFlight({
    required this.tick,
    required this.label,
    required this.item,
    required this.sellGold,
    required this.startOffset,
    required this.endOffset,
    this.itemPlacement,
    this.itemRarity,
    this.itemId,
    this.jesterCard,
  });

  final int tick;
  final String label;
  final bool item;
  final int sellGold;
  final Offset? startOffset;
  final Offset? endOffset;
  final ItemPlacement? itemPlacement;
  final ItemRarity? itemRarity;
  final String? itemId;
  final RummiJesterCard? jesterCard;
}

class _MarketItemUseFlight {
  const _MarketItemUseFlight({
    required this.tick,
    required this.label,
    this.goldGain,
    required this.startOffset,
    required this.endOffset,
    required this.itemPlacement,
    required this.itemRarity,
    required this.itemId,
  });

  final int tick;
  final String label;
  final int? goldGain;
  final Offset? startOffset;
  final Offset? endOffset;
  final ItemPlacement itemPlacement;
  final ItemRarity itemRarity;
  final String itemId;
}

class _MarketEffectPresentation {
  const _MarketEffectPresentation({
    required this.tick,
    required this.events,
    this.title,
  });

  factory _MarketEffectPresentation.single({
    required int tick,
    required ItemPresentationEvent event,
  }) {
    return _MarketEffectPresentation(tick: tick, events: [event]);
  }

  final int tick;
  final List<ItemPresentationEvent> events;
  final String? title;

  ItemPresentationEvent get event => events.first;
  bool get isSummary => events.length > 1;
}
