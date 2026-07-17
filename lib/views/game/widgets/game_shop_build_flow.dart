part of 'game_shop_screen.dart';

extension _GameShopBuildFlow on _GameShopScreenState {
  Widget _buildMarketScreen(BuildContext context) {
    final market = _purchaseFlight?.marketBeforePurchase ?? _market;
    final selectedOwned =
        _selectedOwnedIndex != null &&
            _selectedOwnedIndex! >= 0 &&
            _selectedOwnedIndex! < market.ownedEntries.length
        ? market.ownedEntries[_selectedOwnedIndex!]
        : null;
    final selectedOffer =
        _selectedOfferIndex != null &&
            _selectedOfferIndex! >= 0 &&
            _selectedOfferIndex! < market.offers.length
        ? market.offers[_selectedOfferIndex!]
        : null;
    final selectedItemOffer =
        _selectedItemOfferIndex >= 0 &&
            _selectedItemOfferIndex < market.itemOffers.length
        ? market.itemOffers[_selectedItemOfferIndex]
        : null;
    final selectedTileOffer =
        _selectedTileOfferIndex >= 0 &&
            _selectedTileOfferIndex < market.tileOffers.length
        ? market.tileOffers[_selectedTileOfferIndex]
        : null;
    final selectedItemSlot = _selectedItemSlotIndex < 0
        ? null
        : market.itemSlots.cast<RummiMarketItemSlotView?>().firstWhere(
            (slot) => slot?.slotIndex == _selectedItemSlotIndex,
            orElse: () => null,
          );
    final selectedOwnedItemSlot = selectedItemSlot?.item == null
        ? null
        : selectedItemSlot;
    final visibleItemSlots = _itemSlotsForTab(market, _shopTab);
    final visibleToolSlots = visibleItemSlots
        .where((slot) => slot.placement == ItemPlacement.inventory)
        .toList(growable: false);
    final visibleGearSlots = visibleItemSlots
        .where((slot) => slot.placement == ItemPlacement.equipped)
        .toList(growable: false);
    final currentOfferLane = _currentOfferLane;
    final currentOfferEntries = _offerEntriesForLane(market, currentOfferLane);
    final rawCurrentOfferPage = _offerPageFor(currentOfferLane);
    final currentOfferPage = _clampedOfferPage(
      currentOfferEntries,
      rawCurrentOfferPage,
    );
    final visibleOfferEntries = _pagedItems(
      currentOfferEntries,
      currentOfferPage,
    );
    final currentRerollQuote = _rerollCostQuoteForLane(
      market,
      currentOfferLane,
    );
    final selectedOwnedRuntimeValue = selectedOwned == null
        ? null
        : jesterRuntimeValueText(
            selectedOwned.card,
            market.runtimeSnapshot,
            slotIndex: selectedOwned.slotIndex,
          );

    _scheduleSlotUnlockPresentationIfNeeded(market);
    _scheduleMarketTutorialIfNeeded();
    return PhoneFrameScaffold(
      child: _MarketEntryMotion(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kGameSurfaceFrameRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GameUiPalette.marketFrameGradientStart,
                GameUiPalette.marketFrameGradientMid,
                GameUiPalette.marketFrameGradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GameUiPalette.ink.withValues(alpha: 0.36),
                blurRadius: kGameSurfaceShadowBlur,
                spreadRadius: kGameSurfaceShadowSpread,
              ),
            ],
            border: Border.all(
              color: GameUiPalette.marketFrameBorder.withValues(alpha: 0.55),
              width: kGameSurfaceBorderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kGameSurfaceFrameRadius),
            child: Stack(
              key: _marketSurfaceKey,
              children: [
                const Positioned.fill(child: GameTableBackdrop()),
                Padding(
                  padding: kMarketSurfacePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Market',
                              style: TextStyle(
                                color: GameUiPalette.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          KeyedSubtree(
                            key: _goldChipKey,
                            child: _MarketGoldChip(gold: market.gold),
                          ),
                          const SizedBox(width: 6),
                          GameIconButtonChip(
                            tooltip: context.tr('tutorialMarketReplayTooltip'),
                            onPressed: () =>
                                _startMarketTutorial(markSeen: false),
                            icon: Icons.help_outline_rounded,
                            foregroundColor: GameUiPalette.actionGoldBright,
                            size: 36,
                          ),
                          const SizedBox(width: 6),
                          GameIconButtonChip(
                            onPressed: _openOptions,
                            icon: Icons.more_horiz_rounded,
                            size: 36,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _MarketTabBar(
                        currentTab: _shopTab,
                        onChanged: _selectShopTab,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_shopTab ==
                                  _MarketShopTab.cardsAndQuickSlots) ...[
                                SizedBox(
                                  height: kMarketOwnedTabAreaHeight,
                                  child: _MarketTutorialTarget(
                                    showcaseKey: _marketCardsSlotsTutorialKey,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: kMarketOwnedTabSectionHeight,
                                          child: _MarketSectionBox(
                                            title: 'Jester Slots',
                                            trailing:
                                                '${market.ownedEntries.length}/${market.maxOwnedSlots}',
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              4,
                                              14,
                                              4,
                                            ),
                                            child: SizedBox(
                                              height: kMarketOwnedSlotRowHeight,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: List.generate(market.maxOwnedSlots, (
                                                    index,
                                                  ) {
                                                    final ownedEntry =
                                                        index <
                                                            market
                                                                .ownedEntries
                                                                .length
                                                        ? market
                                                              .ownedEntries[index]
                                                        : null;
                                                    final card =
                                                        ownedEntry?.card;
                                                    final selected =
                                                        _selectedOwnedIndex ==
                                                        index;
                                                    final pulse =
                                                        _purchaseFlight?.item ==
                                                            false &&
                                                        _purchaseFlight
                                                                ?.slotLabel ==
                                                            'J${index + 1}';
                                                    final locked =
                                                        index >=
                                                        market
                                                            .jesterSlotCapacity;
                                                    final recentlyUnlocked =
                                                        market
                                                            .pendingSlotUnlockPresentations
                                                            .contains(
                                                              RummiSlotUnlockKind
                                                                  .jester,
                                                            ) &&
                                                        index ==
                                                            market.jesterSlotCapacity -
                                                                1;
                                                    final child = MarketSlotPulse(
                                                      active:
                                                          pulse ||
                                                          recentlyUnlocked,
                                                      showUnlockLock:
                                                          recentlyUnlocked,
                                                      child: _MarketSelectableCardFrame(
                                                        selected: false,
                                                        width:
                                                            kMarketOwnedCardWidth,
                                                        height:
                                                            kMarketOwnedCardHeight,
                                                        child: GameJesterSlot(
                                                          card: card,
                                                          runtimeValueText:
                                                              card == null
                                                              ? null
                                                              : jesterRuntimeValueText(
                                                                  card,
                                                                  market
                                                                      .runtimeSnapshot,
                                                                  slotIndex:
                                                                      index,
                                                                ),
                                                          extended: index == 4,
                                                          activeEffect: null,
                                                          settlementSequenceTick:
                                                              0,
                                                          selected: selected,
                                                          locked: locked,
                                                        ),
                                                      ),
                                                    );
                                                    final previewCard = SizedBox(
                                                      width:
                                                          kMarketOwnedCardWidth,
                                                      height:
                                                          kMarketOwnedCardHeight,
                                                      child: GameJesterSlot(
                                                        card: card,
                                                        runtimeValueText:
                                                            card == null
                                                            ? null
                                                            : jesterRuntimeValueText(
                                                                card,
                                                                market
                                                                    .runtimeSnapshot,
                                                                slotIndex:
                                                                    index,
                                                              ),
                                                        extended: index == 4,
                                                        activeEffect: null,
                                                        settlementSequenceTick:
                                                            0,
                                                        selected: false,
                                                        locked: false,
                                                      ),
                                                    );

                                                    return SizedBox(
                                                      key: _jesterSlotKey(
                                                        index,
                                                      ),
                                                      width:
                                                          kMarketOwnedCardWidth +
                                                          (kMarketCardSelectionInset *
                                                              2),
                                                      height:
                                                          kMarketOwnedCardHeight +
                                                          (kMarketCardSelectionInset *
                                                              2),
                                                      child:
                                                          card == null || locked
                                                          ? child
                                                          : GestureDetector(
                                                              onTap: () =>
                                                                  _selectOwned(
                                                                    index,
                                                                  ),
                                                              onLongPress: () => _showMarketCardPreview(
                                                                context,
                                                                previewCard,
                                                                title:
                                                                    localizedJesterName(
                                                                      context,
                                                                      card,
                                                                    ),
                                                                effectText:
                                                                    localizedJesterEffect(
                                                                      context,
                                                                      card,
                                                                    ),
                                                                tags: [
                                                                  ..._jesterSynergyTags(
                                                                    card,
                                                                  ),
                                                                  if (jesterRuntimeValueText(
                                                                        card,
                                                                        market
                                                                            .runtimeSnapshot,
                                                                        slotIndex:
                                                                            index,
                                                                      ) !=
                                                                      null)
                                                                    jesterRuntimeValueText(
                                                                      card,
                                                                      market
                                                                          .runtimeSnapshot,
                                                                      slotIndex:
                                                                          index,
                                                                    )!,
                                                                ],
                                                              ),
                                                              child: child,
                                                            ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: kMarketOwnedTabSectionGap,
                                        ),
                                        SizedBox(
                                          height: kMarketOwnedTabSectionHeight,
                                          child:
                                              _MarketQuickPassiveSlotsSection(
                                                slots: visibleItemSlots,
                                                selectedItemSlotIndex:
                                                    _selectedItemSlotIndex,
                                                pulsingSlotLabel:
                                                    _purchaseFlight?.item ==
                                                        true
                                                    ? _purchaseFlight?.slotLabel
                                                    : null,
                                                slotKeyForLabel: _itemSlotKey,
                                                onTap: _selectItemSlot,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  height: kMarketOwnedTabAreaHeight,
                                  child: _MarketTutorialTarget(
                                    showcaseKey: _marketToolsSlotsTutorialKey,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: kMarketOwnedTabSectionHeight,
                                          child: _MarketItemSlotsSection(
                                            title: 'Tool Slots',
                                            slots: visibleToolSlots,
                                            selectedItemSlotIndex:
                                                _selectedItemSlotIndex,
                                            pulsingSlotLabel:
                                                _purchaseFlight?.item == true
                                                ? _purchaseFlight?.slotLabel
                                                : null,
                                            slotKeyForLabel: _itemSlotKey,
                                            onTap: _selectItemSlot,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: kMarketOwnedTabSectionGap,
                                        ),
                                        SizedBox(
                                          height: kMarketOwnedTabSectionHeight,
                                          child: _MarketItemSlotsSection(
                                            title: 'Gear Slots',
                                            slots: visibleGearSlots,
                                            selectedItemSlotIndex:
                                                _selectedItemSlotIndex,
                                            pulsingSlotLabel:
                                                _purchaseFlight?.item == true
                                                ? _purchaseFlight?.slotLabel
                                                : null,
                                            slotKeyForLabel: _itemSlotKey,
                                            onTap: _selectItemSlot,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              _MarketTutorialTarget(
                                showcaseKey: _activeMarketDetailTutorialKey,
                                child: _MarketSpeechPanel(
                                  title: selectedOwned != null
                                      ? localizedJesterName(
                                          context,
                                          selectedOwned.card,
                                        )
                                      : selectedOffer != null
                                      ? localizedJesterName(
                                          context,
                                          selectedOffer.card,
                                        )
                                      : selectedItemOffer != null
                                      ? localizedItemName(
                                          context,
                                          selectedItemOffer,
                                        )
                                      : selectedTileOffer != null
                                      ? _tileLabel(selectedTileOffer.tile)
                                      : selectedOwnedItemSlot != null
                                      ? localizedItemSlotName(
                                          context,
                                          selectedOwnedItemSlot,
                                        )
                                      : '선택된 카드 없음',
                                  subtitle: selectedOwned != null
                                      ? '보유 슬롯'
                                      : selectedOffer != null
                                      ? 'Jester Shop'
                                      : selectedItemOffer != null
                                      ? 'Item Shop'
                                      : selectedTileOffer != null
                                      ? selectedTileOffer.isFreeReward
                                            ? 'Boss Reward'
                                            : 'Tile Shop'
                                      : selectedOwnedItemSlot != null
                                      ? _ownedItemSlotSubtitle(
                                          selectedOwnedItemSlot,
                                        )
                                      : '카드를 선택하세요',
                                  body: selectedOwned != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _MarketDescriptionText(
                                              localizedJesterEffect(
                                                context,
                                                selectedOwned.card,
                                              ),
                                            ),
                                            if (selectedOwnedRuntimeValue !=
                                                null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                selectedOwnedRuntimeValue,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: GameUiPalette
                                                      .actionGoldBright,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ],
                                        )
                                      : selectedOffer != null
                                      ? _MarketOfferDetailBody(
                                          effectText: localizedJesterEffect(
                                            context,
                                            selectedOffer.card,
                                          ),
                                          tags: _jesterSynergyTags(
                                            selectedOffer.card,
                                          ),
                                        )
                                      : selectedItemOffer != null
                                      ? _MarketOfferDetailBody(
                                          effectText: localizedItemEffect(
                                            context,
                                            selectedItemOffer,
                                          ),
                                          tags: _itemSynergyTags(
                                            selectedItemOffer.item,
                                          ),
                                        )
                                      : selectedTileOffer != null
                                      ? _MarketOfferDetailBody(
                                          effectText: _tileOfferDetailText(
                                            selectedTileOffer.tile,
                                          ),
                                          tags: [
                                            '타일 ${_tileLabel(selectedTileOffer.tile)}',
                                            '칩 ${selectedTileOffer.tile.baseChipValue}',
                                            if (selectedTileOffer
                                                .tile
                                                .hasModifier)
                                              tileModifierSummary(
                                                selectedTileOffer.tile,
                                              ),
                                            selectedTileOffer.isFreeReward
                                                ? '무료 선택'
                                                : '덱 추가',
                                          ],
                                        )
                                      : selectedOwnedItemSlot != null
                                      ? _OwnedMarketItemBody(
                                          slot: selectedOwnedItemSlot,
                                        )
                                      : _MarketDescriptionText(
                                          '선택한 카드의 정보와 액션이 여기에 표시됩니다.',
                                          color: GameUiPalette.textPrimary
                                              .withValues(alpha: 0.68),
                                        ),
                                  trailing: selectedOwned != null
                                      ? _MarketActionPane(
                                          priceLabel:
                                              '+${selectedOwned.sellPrice}',
                                          buttonLabel: '판매',
                                          buttonColor:
                                              GameUiPalette.actionDanger,
                                          onPressed: () => _sellOwned(
                                            selectedOwned.slotIndex,
                                          ),
                                        )
                                      : selectedOffer != null
                                      ? _MarketActionPane(
                                          priceLabel: '${selectedOffer.price}',
                                          buttonLabel: '구매',
                                          buttonColor: GameUiPalette.actionGold,
                                          foreground: GameUiPalette.ink,
                                          onPressed: selectedOffer.isAffordable
                                              ? _buySelected
                                              : null,
                                          onDeniedPressed:
                                              selectedOffer.isAffordable
                                              ? null
                                              : () {
                                                  const reason = 'Gold 부족';
                                                  _startMarketDenyFeedback(
                                                    'jester-buy',
                                                    reason,
                                                  );
                                                  showBottomNotice(
                                                    context,
                                                    reason,
                                                  );
                                                },
                                          disabledReason:
                                              selectedOffer.isAffordable
                                              ? null
                                              : 'Gold 부족',
                                          denyActive:
                                              _marketDenyTarget == 'jester-buy',
                                          denyTick: _marketDenyTick,
                                          denyReason: _marketDenyReason,
                                        )
                                      : selectedItemOffer != null
                                      ? _MarketActionPane(
                                          priceLabel:
                                              '${selectedItemOffer.price}',
                                          buttonLabel: '구매',
                                          buttonColor: GameUiPalette.actionGold,
                                          foreground: GameUiPalette.ink,
                                          onPressed:
                                              selectedItemOffer.isAffordable
                                              ? _buySelectedItem
                                              : null,
                                          onDeniedPressed:
                                              selectedItemOffer.isAffordable
                                              ? null
                                              : () {
                                                  const reason = 'Gold 부족';
                                                  _startMarketDenyFeedback(
                                                    'item-buy',
                                                    reason,
                                                  );
                                                  showBottomNotice(
                                                    context,
                                                    reason,
                                                  );
                                                },
                                          disabledReason:
                                              selectedItemOffer.isAffordable
                                              ? null
                                              : 'Gold 부족',
                                          denyActive:
                                              _marketDenyTarget == 'item-buy',
                                          denyTick: _marketDenyTick,
                                          denyReason: _marketDenyReason,
                                        )
                                      : selectedTileOffer != null
                                      ? _MarketActionPane(
                                          priceLabel:
                                              selectedTileOffer.isFreeReward
                                              ? '무료'
                                              : '${selectedTileOffer.price}',
                                          buttonLabel:
                                              selectedTileOffer.isFreeReward
                                              ? '선택'
                                              : '구매',
                                          buttonColor: GameUiPalette.actionGold,
                                          foreground: GameUiPalette.ink,
                                          onPressed:
                                              selectedTileOffer.isAffordable
                                              ? _buySelectedTile
                                              : null,
                                          onDeniedPressed:
                                              selectedTileOffer.isAffordable
                                              ? null
                                              : () {
                                                  const reason = 'Gold 부족';
                                                  _startMarketDenyFeedback(
                                                    'tile-buy',
                                                    reason,
                                                  );
                                                  showBottomNotice(
                                                    context,
                                                    reason,
                                                  );
                                                },
                                          disabledReason:
                                              selectedTileOffer.isAffordable
                                              ? null
                                              : 'Gold 부족',
                                          denyActive:
                                              _marketDenyTarget == 'tile-buy',
                                          denyTick: _marketDenyTick,
                                          denyReason: _marketDenyReason,
                                        )
                                      : selectedOwnedItemSlot != null
                                      ? _ownedMarketItemActionPane(
                                          context,
                                          selectedOwnedItemSlot,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MarketOfferLaneBar(
                                lanes: _offerLanesForTab(_shopTab),
                                selectedLane: currentOfferLane,
                                onChanged: _selectOfferLane,
                              ),
                              const SizedBox(height: 6),
                              _MarketTutorialTarget(
                                showcaseKey: _activeMarketOffersTutorialKey,
                                child: _MarketSectionBox(
                                  title: null,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  child: SizedBox(
                                    height: kMarketShopPanelHeight,
                                    child: Column(
                                      children: [
                                        _MarketTutorialTarget(
                                          showcaseKey:
                                              _activeMarketRerollTutorialKey,
                                          child: _MarketPagerBar(
                                            currentPage: currentOfferPage,
                                            pageCount: _pageCount(
                                              currentOfferEntries.length,
                                            ),
                                            onPrev: () => _shiftOfferPage(-1),
                                            onNext: () => _shiftOfferPage(1),
                                            rerollQuote: currentRerollQuote,
                                            feedbackTick:
                                                _marketRerollFeedbackTick,
                                            bonusLabel: _offerLaneBonusLabel(
                                              market,
                                              currentOfferLane,
                                            ),
                                            onReroll:
                                                currentOfferLane ==
                                                    _MarketOfferLane.jester
                                                ? _reroll
                                                : currentOfferLane ==
                                                      _MarketOfferLane.tile
                                                ? widget.onRerollTileOffers !=
                                                          null
                                                      ? _reroll
                                                      : null
                                                : currentOfferLane !=
                                                          _MarketOfferLane
                                                              .tile &&
                                                      widget.onRerollItemOffers !=
                                                          null
                                                ? _reroll
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                              vertical: 2,
                                            ),
                                            child: visibleOfferEntries.isEmpty
                                                ? Center(
                                                    child: Text(
                                                      _shopTab ==
                                                              _MarketShopTab
                                                                  .cardsAndQuickSlots
                                                          ? '이번 Market에 노출된 ${_offerLaneLabel(currentOfferLane)} 후보가 없습니다.'
                                                          : '이번 Market에 노출된 ${_offerLaneLabel(currentOfferLane)} 후보가 없습니다.',
                                                      style: TextStyle(
                                                        color: GameUiPalette
                                                            .textPrimary
                                                            .withValues(
                                                              alpha: 0.68,
                                                            ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  )
                                                : _MarketOfferRow(
                                                    itemCount:
                                                        visibleOfferEntries
                                                            .length,
                                                    children: [
                                                      for (
                                                        var i = 0;
                                                        i <
                                                            visibleOfferEntries
                                                                .length;
                                                        i++
                                                      )
                                                        KeyedSubtree(
                                                          key: _offerKey(
                                                            visibleOfferEntries[i],
                                                          ),
                                                          child: _MarketOfferReveal(
                                                            index: i,
                                                            signature:
                                                                _offerEntrySignature(
                                                                  market,
                                                                  visibleOfferEntries[i],
                                                                ),
                                                            child:
                                                                _isPurchaseSourceIndex(
                                                                  i,
                                                                )
                                                                ? const _MarketEmptyOfferCard()
                                                                : switch (visibleOfferEntries[i]
                                                                      .kind) {
                                                                    _MarketOfferEntryKind.jester => _GameShopOfferCard(
                                                                      offer:
                                                                          market
                                                                              .offers[visibleOfferEntries[i]
                                                                              .jesterIndex!],
                                                                      selected:
                                                                          _selectedOfferIndex ==
                                                                          visibleOfferEntries[i]
                                                                              .jesterIndex,
                                                                      canAfford: market
                                                                          .offers[visibleOfferEntries[i]
                                                                              .jesterIndex!]
                                                                          .isAffordable,
                                                                      onTap: () => _selectOffer(
                                                                        visibleOfferEntries[i]
                                                                            .jesterIndex!,
                                                                      ),
                                                                    ),
                                                                    _MarketOfferEntryKind
                                                                        .item =>
                                                                      _MarketItemOfferCard(
                                                                        offer: market
                                                                            .itemOffers[visibleOfferEntries[i].itemIndex!],
                                                                        selected:
                                                                            _selectedItemOfferIndex ==
                                                                            visibleOfferEntries[i].itemIndex,
                                                                        onTap: () => _selectItemOffer(
                                                                          visibleOfferEntries[i]
                                                                              .itemIndex!,
                                                                        ),
                                                                      ),
                                                                    _MarketOfferEntryKind
                                                                        .tile =>
                                                                      _MarketTileOfferCard(
                                                                        offer: market
                                                                            .tileOffers[visibleOfferEntries[i].tileIndex!],
                                                                        selected:
                                                                            _selectedTileOfferIndex ==
                                                                            visibleOfferEntries[i].tileIndex,
                                                                        onTap: () => _selectTileOffer(
                                                                          visibleOfferEntries[i]
                                                                              .tileIndex!,
                                                                        ),
                                                                      ),
                                                                  },
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GameActionButton(
                              label: '메인 메뉴',
                              background: GameUiPalette.disabledControl,
                              onPressed: () async {
                                try {
                                  await _flushStateSave();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop(false);
                                  await widget.onExitToTitle();
                                } catch (_) {
                                  if (context.mounted) {
                                    showBottomNotice(
                                      context,
                                      '저장에 실패했습니다. 다시 시도해 주세요.',
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GameActionButton(
                              label: '다음 Station',
                              background: GameUiPalette.marketPositive,
                              onPressed: () async {
                                await _flushStateSave();
                                if (!context.mounted) return;
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_slotUnlockBannerVisible)
                  Positioned(
                    top: 54,
                    left: 18,
                    right: 18,
                    child: MarketSlotUnlockBanner(
                      unlocks: _activeSlotUnlockPresentation,
                    ),
                  ),
                if (_purchaseFlight != null)
                  Positioned.fill(
                    child: _MarketPurchaseFlightOverlay(
                      flight: _purchaseFlight!,
                    ),
                  ),
                if (_saleFlight != null)
                  Positioned.fill(
                    child: _MarketSaleFlightOverlay(flight: _saleFlight!),
                  ),
                if (_itemUseFlight != null)
                  Positioned.fill(
                    child: _MarketItemUseFlightOverlay(flight: _itemUseFlight!),
                  ),
                if (_marketUseFeedbackLabel != null)
                  Positioned.fill(
                    child: _MarketUseFeedbackToast(
                      label: _marketUseFeedbackLabel!,
                      deltaLabel: _marketUseFeedbackDelta,
                    ),
                  ),
                if (_effectPresentation != null)
                  Positioned.fill(
                    child: _MarketEffectPresentationToast(
                      presentation: _effectPresentation!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
