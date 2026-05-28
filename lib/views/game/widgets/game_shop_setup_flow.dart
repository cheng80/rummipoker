part of 'game_shop_screen.dart';

extension _GameShopSetupFlow on _GameShopScreenState {
  List<RummiMarketItemOfferView> _repricePinnedItemOffers(
    List<RummiMarketItemOfferView> offers,
    RummiMarketRuntimeFacade market,
  ) {
    return [
      for (final offer in offers)
        RummiMarketItemOfferView.fromItemDefinition(
          offer.item,
          slotIndex: offer.slotIndex,
          currentGold: market.gold,
          price: offer.price,
          originalPrice: offer.originalPrice,
        ),
    ];
  }

  GlobalKey get _activeMarketOffersTutorialKey =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _marketCardsOffersTutorialKey
      : _marketToolsOffersTutorialKey;

  GlobalKey get _activeMarketSlotsTutorialKey =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _marketCardsSlotsTutorialKey
      : _marketToolsSlotsTutorialKey;

  GlobalKey get _activeMarketDetailTutorialKey =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _marketCardsDetailTutorialKey
      : _marketToolsDetailTutorialKey;

  GlobalKey get _activeMarketRerollTutorialKey =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _marketCardsRerollTutorialKey
      : _marketToolsRerollTutorialKey;

  void _queueStateSave() {
    _pendingStateSave = _pendingStateSave.then((_) => widget.onStateChanged());
  }

  Future<void> _flushStateSave() => _pendingStateSave;

  void _scheduleSlotUnlockPresentationIfNeeded(
    RummiMarketRuntimeFacade market,
  ) {
    if (_slotUnlockPresentationScheduled ||
        market.pendingSlotUnlockPresentations.isEmpty) {
      return;
    }
    _slotUnlockPresentationScheduled = true;
    _activeSlotUnlockPresentation = market.pendingSlotUnlockPresentations;
    _slotUnlockBannerVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(kMarketSlotUnlockBannerDelay);
      if (!mounted) return;
      await widget.onSlotUnlockPresentationShown?.call();
      await Future<void>.delayed(kMarketSlotUnlockBannerVisible);
      if (!mounted) return;
      _mutate(() => _slotUnlockBannerVisible = false);
    });
  }

  void _scheduleMarketTutorialIfNeeded() {
    if (_marketTutorialScheduled ||
        !widget.autoStartTutorials ||
        _optionsDialogOpen ||
        widget.autoAdvanceOnLoad ||
        TutorialStateService.marketIntroSeen) {
      return;
    }
    _marketTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _waitForMarketTutorialLayout();
      if (!mounted ||
          _optionsDialogOpen ||
          !widget.autoStartTutorials ||
          widget.autoAdvanceOnLoad ||
          TutorialStateService.marketIntroSeen) {
        _marketTutorialScheduled = false;
        return;
      }
      await _startMarketTutorial(markSeen: true);
    });
  }

  Future<void> _waitForMarketTutorialLayout() async {
    await Future<void>.delayed(
      GamePresentationTimings.marketEntryIntro +
          GamePresentationTimings.marketTabSwitch,
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _startMarketTutorial({
    required bool markSeen,
    int initialFocus = 0,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _marketTutorialFocusIndex = initialFocus.clamp(0, 3);
    if (markSeen) {
      _marketTutorialShouldMarkSeenOnFinish = true;
    } else {
      _marketTutorialShouldMarkSeenOnFinish = false;
    }
    _marketTutorialCoachMark?.removeOverlayEntry();
    _marketTutorialCoachMark = TutorialCoachMark(
      targets: buildGameTutorialTargets(
        context: context,
        steps: [
          GameTutorialStep(
            targetKey: _activeMarketSlotsTutorialKey,
            title: context.tr('tutorialMarketSlotsTitle'),
            description: context.tr('tutorialMarketSlotsDesc'),
            align: ContentAlign.bottom,
          ),
          GameTutorialStep(
            targetKey: _activeMarketDetailTutorialKey,
            title: context.tr('tutorialMarketDetailTitle'),
            description: context.tr('tutorialMarketDetailDesc'),
            align: ContentAlign.bottom,
          ),
          GameTutorialStep(
            targetKey: _activeMarketRerollTutorialKey,
            title: context.tr('tutorialMarketRerollTitle'),
            description: context.tr('tutorialMarketRerollDesc'),
            align: ContentAlign.top,
          ),
          GameTutorialStep(
            targetKey: _activeMarketOffersTutorialKey,
            title: context.tr('tutorialMarketOffersTitle'),
            description: context.tr('tutorialMarketOffersDesc'),
            align: ContentAlign.top,
            keepBubbleAboveTarget: true,
          ),
        ],
        nextLabel: context.tr('tutorialNext'),
        doneLabel: context.tr('tutorialDone'),
        skipLabel: context.tr('tutorialSkip'),
        onStepAdvanced: (index) {
          _marketTutorialFocusIndex = index.clamp(0, 3);
        },
      ),
      colorShadow: GameUiPalette.tutorialShadow,
      opacityShadow: 0.62,
      pulseEnable: false,
      paddingFocus: 6,
      alignSkip: Alignment.topRight,
      skipWidget: buildGameTutorialSkipButton(context.tr('tutorialSkip')),
      initialFocus: _marketTutorialFocusIndex,
      onFinish: _markMarketTutorialSeenOnFinish,
      onSkip: () {
        TutorialStateService.markMarketIntroSeen();
        _marketTutorialShouldMarkSeenOnFinish = false;
        _marketTutorialScheduled = false;
        _marketTutorialFocusIndex = 0;
        return true;
      },
    )..show(context: context);
  }

  void _dismissMarketTutorial() {
    if (!(_marketTutorialCoachMark?.isShowing ?? false)) return;
    _marketTutorialCoachMark?.removeOverlayEntry();
    _marketTutorialScheduled = false;
    _marketTutorialShouldMarkSeenOnFinish = false;
    _marketTutorialFocusIndex = 0;
  }

  void _markMarketTutorialSeenOnFinish() {
    _marketTutorialFocusIndex = 0;
    if (!_marketTutorialShouldMarkSeenOnFinish) return;
    _marketTutorialShouldMarkSeenOnFinish = false;
    TutorialStateService.markMarketIntroSeen();
  }

  GlobalKey _offerKey(_MarketOfferEntry entry) {
    final key = switch (entry.kind) {
      _MarketOfferEntryKind.jester => 'j:${entry.jesterIndex}',
      _MarketOfferEntryKind.item => 'i:${entry.itemIndex}',
      _MarketOfferEntryKind.tile => 't:${entry.tileIndex}',
    };
    return _offerKeys.putIfAbsent(key, GlobalKey.new);
  }

  GlobalKey _itemSlotKey(String slotLabel) {
    return _itemSlotKeys.putIfAbsent(slotLabel, GlobalKey.new);
  }

  GlobalKey _jesterSlotKey(int slotIndex) {
    return _jesterSlotKeys.putIfAbsent(slotIndex, GlobalKey.new);
  }
}
