part of 'game_shop_screen.dart';

extension _GameShopSelectionFlow on _GameShopScreenState {
  void _selectOwned(int index) {
    _mutate(() {
      if (_selectedOwnedIndex == index) {
        _clearMarketSelection();
        return;
      }
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
      _selectedItemOfferIndex = -1;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
    });
  }

  void _selectOffer(int index) {
    _mutate(() {
      if (_selectedOfferIndex == index) {
        _clearMarketSelection();
        return;
      }
      _shopTab = _MarketShopTab.cardsAndQuickSlots;
      _mainOfferLane = _MarketOfferLane.jester;
      _selectedOfferIndex = index;
      _selectedItemOfferIndex = -1;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      _selectedOwnedIndex = null;
    });
  }

  void _selectItemOffer(int index) {
    _mutate(() {
      if (_selectedItemOfferIndex == index) {
        _clearMarketSelection();
        return;
      }
      _selectedItemOfferIndex = index;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectTileOffer(int index) {
    _mutate(() {
      if (_selectedTileOfferIndex == index) {
        _clearMarketSelection();
        return;
      }
      _shopTab = _MarketShopTab.cardsAndQuickSlots;
      _mainOfferLane = _MarketOfferLane.tile;
      _selectedTileOfferIndex = index;
      _selectedItemOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectItemSlot(RummiMarketItemSlotView slot) {
    if (slot.locked || slot.item == null) return;
    _mutate(() {
      if (_selectedItemSlotIndex == slot.slotIndex) {
        _clearMarketSelection();
        return;
      }
      _shopTab = switch (slot.placement) {
        ItemPlacement.quickSlot ||
        ItemPlacement.passiveRack => _MarketShopTab.cardsAndQuickSlots,
        ItemPlacement.inventory ||
        ItemPlacement.equipped => _MarketShopTab.toolsAndGear,
      };
      _setOfferLaneForPlacement(slot.placement);
      _selectedItemSlotIndex = slot.slotIndex;
      _selectedItemOfferIndex = -1;
      _selectedTileOfferIndex = -1;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectShopTab(_MarketShopTab tab) {
    _mutate(() {
      _shopTab = tab;
      _clearMarketSelection();
    });
  }

  void _selectOfferLane(_MarketOfferLane lane) {
    _mutate(() {
      if (_shopTab == _MarketShopTab.cardsAndQuickSlots) {
        _mainOfferLane = lane;
      } else {
        _utilityOfferLane = lane;
      }
      _clearMarketSelection();
    });
  }

  void _clearMarketSelection() {
    _selectedOwnedIndex = null;
    _selectedOfferIndex = null;
    _selectedItemOfferIndex = -1;
    _selectedTileOfferIndex = -1;
    _selectedItemSlotIndex = -1;
  }

  void _shiftOfferPage(int delta) {
    final lane = _currentOfferLane;
    final pageCount = _pageCount(_offerEntriesForLane(_market, lane).length);
    if (pageCount <= 1) return;
    _mutate(() {
      _offerPages[lane] = (_offerPageFor(lane) + delta).clamp(0, pageCount - 1);
    });
  }

  _MarketOfferLane get _currentOfferLane =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _mainOfferLane
      : _utilityOfferLane;

  void _syncCurrentLaneToAvailableOffers(RummiMarketRuntimeFacade market) {
    final currentLane = _currentOfferLane;
    if (_offerEntriesForLane(market, currentLane).isNotEmpty) return;
    final fallbackLane = _firstAvailableLaneForCurrentTab(market);
    if (fallbackLane == null || fallbackLane == currentLane) return;
    if (_shopTab == _MarketShopTab.cardsAndQuickSlots) {
      _mainOfferLane = fallbackLane;
    } else {
      _utilityOfferLane = fallbackLane;
    }
    _clearMarketSelection();
    _clampOfferPageForLane(market, fallbackLane);
  }

  _MarketOfferLane? _firstAvailableLaneForCurrentTab(
    RummiMarketRuntimeFacade market,
  ) {
    for (final lane in _offerLanesForTab(_shopTab)) {
      if (_offerEntriesForLane(market, lane).isNotEmpty) return lane;
    }
    return null;
  }

  void _setOfferLaneForPlacement(ItemPlacement placement) {
    switch (placement) {
      case ItemPlacement.quickSlot:
        _mainOfferLane = _MarketOfferLane.quickSlot;
      case ItemPlacement.passiveRack:
        _mainOfferLane = _MarketOfferLane.passive;
      case ItemPlacement.inventory:
        _utilityOfferLane = _MarketOfferLane.tool;
      case ItemPlacement.equipped:
        _utilityOfferLane = _MarketOfferLane.gear;
    }
  }

  List<_MarketOfferLane> _offerLanesForTab(_MarketShopTab tab) {
    return tab == _MarketShopTab.cardsAndQuickSlots
        ? const [
            _MarketOfferLane.jester,
            _MarketOfferLane.tile,
            _MarketOfferLane.quickSlot,
            _MarketOfferLane.passive,
          ]
        : const [_MarketOfferLane.tool, _MarketOfferLane.gear];
  }

  int _offerPageFor(_MarketOfferLane lane) => _offerPages[lane] ?? 0;

  List<_MarketOfferEntry> _offerEntriesForLane(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final entries = <_MarketOfferEntry>[];
    if (lane == _MarketOfferLane.jester) {
      for (var i = 0; i < market.offers.length; i++) {
        entries.add(_MarketOfferEntry.jester(i));
      }
      return entries;
    }
    if (lane == _MarketOfferLane.tile) {
      for (var i = 0; i < market.tileOffers.length; i++) {
        entries.add(_MarketOfferEntry.tile(i));
      }
      return entries;
    }
    for (var i = 0; i < market.itemOffers.length; i++) {
      final placement = market.itemOffers[i].item.placement;
      if (_offerLaneForPlacement(placement) == lane) {
        entries.add(_MarketOfferEntry.item(i));
      }
    }
    return entries;
  }

  _MarketOfferLane _offerLaneForPlacement(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => _MarketOfferLane.quickSlot,
      ItemPlacement.passiveRack => _MarketOfferLane.passive,
      ItemPlacement.inventory => _MarketOfferLane.tool,
      ItemPlacement.equipped => _MarketOfferLane.gear,
    };
  }

  List<RummiMarketItemSlotView> _itemSlotsForTab(
    RummiMarketRuntimeFacade market,
    _MarketShopTab tab,
  ) {
    final placements = tab == _MarketShopTab.cardsAndQuickSlots
        ? const {ItemPlacement.quickSlot, ItemPlacement.passiveRack}
        : const {ItemPlacement.inventory, ItemPlacement.equipped};
    return market.itemSlots
        .where((slot) => placements.contains(slot.placement))
        .toList(growable: false);
  }

  void _selectFirstEntry(List<_MarketOfferEntry> entries) {
    _selectedOfferIndex = null;
    _selectedItemOfferIndex = -1;
    _selectedTileOfferIndex = -1;
    _selectedItemSlotIndex = -1;
    if (entries.isEmpty) return;
    final entry = entries.first;
    switch (entry.kind) {
      case _MarketOfferEntryKind.jester:
        _selectedOfferIndex = entry.jesterIndex;
      case _MarketOfferEntryKind.item:
        _selectedItemOfferIndex = entry.itemIndex ?? -1;
      case _MarketOfferEntryKind.tile:
        _selectedTileOfferIndex = entry.tileIndex ?? -1;
    }
  }

  int _pageCount(int total) => total == 0 ? 1 : ((total - 1) ~/ 3) + 1;

  List<T> _pagedItems<T>(List<T> items, int page) {
    final start = (page * 3).clamp(0, items.length);
    final end = (start + 3).clamp(0, items.length);
    return items.sublist(start, end);
  }

  int _clampedOfferPage(List<_MarketOfferEntry> entries, int page) {
    return page.clamp(0, _pageCount(entries.length) - 1);
  }

  void _clampOfferPageForLane(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final entries = _offerEntriesForLane(market, lane);
    _offerPages[lane] = _clampedOfferPage(entries, _offerPageFor(lane));
  }

  ItemPlacement? _placementForOfferLane(_MarketOfferLane lane) {
    return switch (lane) {
      _MarketOfferLane.jester => null,
      _MarketOfferLane.tile => null,
      _MarketOfferLane.quickSlot => ItemPlacement.quickSlot,
      _MarketOfferLane.passive => ItemPlacement.passiveRack,
      _MarketOfferLane.tool => ItemPlacement.inventory,
      _MarketOfferLane.gear => ItemPlacement.equipped,
    };
  }

  int _rerollCostForLane(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final placement = _placementForOfferLane(lane);
    if (lane == _MarketOfferLane.tile) return market.tileRerollCost;
    return placement == null
        ? market.rerollCost
        : market.itemRerollCostFor(placement);
  }

  int _originalRerollCostForLane(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final placement = _placementForOfferLane(lane);
    if (lane == _MarketOfferLane.tile) return market.originalTileRerollCost;
    return placement == null
        ? market.originalRerollCost
        : market.originalItemRerollCostFor(placement);
  }

  _MarketRerollCostQuote _rerollCostQuoteForLane(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    return _MarketRerollCostQuote(
      cost: _rerollCostForLane(market, lane),
      originalCost: _originalRerollCostForLane(market, lane),
    );
  }
}
