import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/item_presentation_event.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/tutorial_state_service.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/phone_frame_scaffold.dart';
import '../game_presentation_timings.dart';
import 'game_card_name_text.dart';
import 'game_jester_widgets.dart';
import 'game_run_info_dialog.dart';
import 'game_shared_widgets.dart';
import 'game_tutorial_overlay.dart';

const double _marketOwnedCardWidth = kBattleItemSlotWidth;
const double _marketOwnedCardHeight = kBattleItemSlotHeight;
const double _marketOfferCardWidth = kBattleItemSlotWidth;
const double _marketOfferCardHeight = kBattleItemSlotHeight;
const double _marketCardSelectionInset = kJesterSelectionOutset;
const Duration _marketPurchaseFlightDuration =
    GamePresentationTimings.marketPurchaseFlight;
const double _marketShopCellWidth = 72.0;
const double _marketShopCellHeight =
    kBattleItemSlotHeight + (kJesterSelectionOutset * 2) + 16.0;
const double _marketShopPanelHeight = 168.0;
const double _marketSpeechPanelHeight = 132.0;
const double _marketDescriptionFontSize = 12.0;
const double _marketDescriptionLineHeight = 1.18;
const double _marketDescriptionMinHeight =
    _marketDescriptionFontSize * _marketDescriptionLineHeight * 2;

enum _MarketOptionsCloseAction {
  resumeGame,
  keepPaused,
  openSettings,
  openRunInfo,
  openMarketTutorial,
}

const TextStyle _marketDescriptionTextStyle = TextStyle(
  color: Colors.white70,
  fontSize: _marketDescriptionFontSize,
  fontWeight: FontWeight.w700,
  height: _marketDescriptionLineHeight,
);

enum _MarketShopTab { cardsAndQuickSlots, toolsAndGear }

enum _MarketOfferLane { jester, tile, quickSlot, passive, tool, gear }

enum _MarketOfferEntryKind { jester, item, tile }

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
  final RummiJesterCard? jesterCard;
}

class _MarketItemUseFlight {
  const _MarketItemUseFlight({
    required this.tick,
    required this.label,
    required this.goldGain,
    required this.startOffset,
    required this.endOffset,
    required this.itemPlacement,
    required this.itemRarity,
  });

  final int tick;
  final String label;
  final int goldGain;
  final Offset? startOffset;
  final Offset? endOffset;
  final ItemPlacement itemPlacement;
  final ItemRarity itemRarity;
}

class _MarketEffectPresentation {
  const _MarketEffectPresentation({required this.tick, required this.event});

  final int tick;
  final ItemPresentationEvent event;
}

class GameShopScreen extends StatefulWidget {
  const GameShopScreen({
    super.key,
    required this.runSeed,
    required this.readMarketView,
    required this.onReroll,
    this.onRerollItemOffers,
    this.onRerollTileOffers,
    required this.onBuyOffer,
    required this.onBuyItemOffer,
    required this.onBuyTileOffer,
    required this.onUseMarketItem,
    required this.onSellOwnedJester,
    required this.onSellMarketItem,
    this.autoStartTutorials = true,
    this.onSlotUnlockPresentationShown,
    required this.onStateChanged,
    required this.onOpenSettings,
    required this.onExitToTitle,
    required this.onRestartRun,
    required this.isDebugFixtureRun,
    this.readActiveRunSaveView,
    this.initialItemShopTab = false,
    this.autoAdvanceOnLoad = false,
  });

  final int runSeed;
  final RummiMarketRuntimeFacade Function() readMarketView;
  final String? Function() onReroll;
  final String? Function(ItemPlacement placement)? onRerollItemOffers;
  final String? Function()? onRerollTileOffers;
  final String? Function(RummiMarketOfferView offer) onBuyOffer;
  final String? Function(RummiMarketItemOfferView offer) onBuyItemOffer;
  final String? Function(int offerIndex) onBuyTileOffer;
  final String? Function(ItemDefinition item) onUseMarketItem;
  final bool Function(int ownedIndex) onSellOwnedJester;
  final bool Function(ItemDefinition item) onSellMarketItem;
  final bool autoStartTutorials;
  final Future<void> Function()? onSlotUnlockPresentationShown;
  final Future<void> Function() onStateChanged;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onExitToTitle;
  final Future<void> Function() onRestartRun;
  final bool isDebugFixtureRun;
  final RummiActiveRunSaveFacade? Function()? readActiveRunSaveView;
  final bool initialItemShopTab;
  final bool autoAdvanceOnLoad;

  @override
  State<GameShopScreen> createState() => _GameShopScreenState();
}

class _GameShopScreenState extends State<GameShopScreen>
    with WidgetsBindingObserver {
  int? _selectedOwnedIndex;
  int? _selectedOfferIndex;
  _MarketShopTab _shopTab = _MarketShopTab.cardsAndQuickSlots;
  _MarketOfferLane _mainOfferLane = _MarketOfferLane.jester;
  _MarketOfferLane _utilityOfferLane = _MarketOfferLane.tool;
  int _selectedItemOfferIndex = -1;
  int _selectedTileOfferIndex = -1;
  int _selectedItemSlotIndex = -1;
  final Map<_MarketOfferLane, int> _offerPages = <_MarketOfferLane, int>{};
  int _purchaseFlightTick = 0;
  _MarketPurchaseFlight? _purchaseFlight;
  int _saleFlightTick = 0;
  _MarketSaleFlight? _saleFlight;
  int _itemUseFlightTick = 0;
  _MarketItemUseFlight? _itemUseFlight;
  int _effectPresentationTick = 0;
  _MarketEffectPresentation? _effectPresentation;
  final GlobalKey _marketSurfaceKey = GlobalKey();
  final GlobalKey _goldChipKey = GlobalKey();
  final Map<String, GlobalKey> _offerKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _itemSlotKeys = <String, GlobalKey>{};
  final Map<int, GlobalKey> _jesterSlotKeys = <int, GlobalKey>{};
  final GlobalKey _marketCardsOffersTutorialKey = GlobalKey();
  final GlobalKey _marketCardsSlotsTutorialKey = GlobalKey();
  final GlobalKey _marketCardsDetailTutorialKey = GlobalKey();
  final GlobalKey _marketCardsRerollTutorialKey = GlobalKey();
  final GlobalKey _marketToolsOffersTutorialKey = GlobalKey();
  final GlobalKey _marketToolsSlotsTutorialKey = GlobalKey();
  final GlobalKey _marketToolsDetailTutorialKey = GlobalKey();
  final GlobalKey _marketToolsRerollTutorialKey = GlobalKey();
  bool _marketTutorialScheduled = false;
  bool _marketTutorialShouldMarkSeenOnFinish = false;
  int _marketTutorialFocusIndex = 0;
  TutorialCoachMark? _marketTutorialCoachMark;
  int _marketDenyTick = 0;
  String? _marketDenyTarget;
  String? _marketDenyReason;
  int _marketUseFeedbackTick = 0;
  String? _marketUseFeedbackLabel;
  String? _marketUseFeedbackDelta;
  int _marketRerollFeedbackTick = 0;
  List<RummiMarketItemOfferView>? _pinnedItemOffers;
  bool _pendingLifecycleOptions = false;
  bool _optionsDialogOpen = false;
  bool _slotUnlockPresentationScheduled = false;
  bool _slotUnlockBannerVisible = false;
  Set<RummiSlotUnlockKind> _activeSlotUnlockPresentation =
      <RummiSlotUnlockKind>{};
  Future<void> _pendingStateSave = Future<void>.value();

  RummiMarketRuntimeFacade get _market {
    final market = widget.readMarketView();
    final pinnedOffers = _pinnedItemOffers;
    if (pinnedOffers == null) return market;
    return market.withItemOffers(
      _repricePinnedItemOffers(pinnedOffers, market),
    );
  }

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
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      await widget.onSlotUnlockPresentationShown?.call();
      await Future<void>.delayed(const Duration(milliseconds: 1250));
      if (!mounted) return;
      setState(() => _slotUnlockBannerVisible = false);
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
      colorShadow: const Color(0xFF05070D),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_market.ownedEntries.isNotEmpty) {
      _selectedOwnedIndex = 0;
    } else if (_market.offers.isNotEmpty) {
      _selectedOfferIndex = 0;
    } else if (_market.tileOffers.isNotEmpty) {
      _mainOfferLane = _MarketOfferLane.tile;
      _selectedTileOfferIndex = 0;
    }
    if (widget.initialItemShopTab) {
      _shopTab = _MarketShopTab.toolsAndGear;
      _utilityOfferLane = _MarketOfferLane.tool;
      _selectedItemOfferIndex = -1;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      for (final entry in _offerEntriesForLane(_market, _utilityOfferLane)) {
        if (entry.kind == _MarketOfferEntryKind.item) {
          _selectedItemOfferIndex = entry.itemIndex ?? -1;
          break;
        }
      }
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
      _selectedTileOfferIndex = -1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _market;
      _queueStateSave();
    });
    if (widget.autoAdvanceOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(
          GamePresentationTimings.marketAutoAdvanceDelay,
        );
        if (!mounted) return;
        await _flushStateSave();
        if (!mounted) return;
        Navigator.of(context).pop(true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismissMarketTutorial();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _dismissMarketTutorial();
        SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
        if (!_optionsDialogOpen) {
          _pendingLifecycleOptions = true;
        }
        _queueStateSave();
        break;
      case AppLifecycleState.resumed:
        if (_pendingLifecycleOptions) {
          _pendingLifecycleOptions = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openOptions();
          });
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!(_marketTutorialCoachMark?.isShowing ?? false)) return;
    final focusIndex = _marketTutorialFocusIndex;
    _marketTutorialCoachMark?.removeOverlayEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _optionsDialogOpen) return;
      _startMarketTutorial(
        markSeen: _marketTutorialShouldMarkSeenOnFinish,
        initialFocus: focusIndex,
      );
    });
  }

  void _selectOwned(int index) {
    setState(() {
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
      _selectedItemOfferIndex = -1;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
    });
  }

  void _selectOffer(int index) {
    setState(() {
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
    setState(() {
      _selectedItemOfferIndex = index;
      _selectedTileOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectTileOffer(int index) {
    setState(() {
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
    setState(() {
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
    setState(() {
      _shopTab = tab;
      _selectedOwnedIndex = null;
      final entries = _offerEntriesForLane(_market, _currentOfferLane);
      _selectFirstEntry(entries);
    });
  }

  void _selectOfferLane(_MarketOfferLane lane) {
    setState(() {
      if (_shopTab == _MarketShopTab.cardsAndQuickSlots) {
        _mainOfferLane = lane;
      } else {
        _utilityOfferLane = lane;
      }
      _selectedOwnedIndex = null;
      _selectFirstEntry(_offerEntriesForLane(_market, lane));
    });
  }

  void _shiftOfferPage(int delta) {
    final lane = _currentOfferLane;
    final pageCount = _pageCount(_offerEntriesForLane(_market, lane).length);
    if (pageCount <= 1) return;
    setState(() {
      _offerPages[lane] = (_offerPageFor(lane) + delta).clamp(0, pageCount - 1);
    });
  }

  _MarketOfferLane get _currentOfferLane =>
      _shopTab == _MarketShopTab.cardsAndQuickSlots
      ? _mainOfferLane
      : _utilityOfferLane;

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

  Future<void> _reroll() async {
    final lane = _currentOfferLane;
    final laneLabel = _offerLaneLabel(lane);
    final rerollCost = _rerollCostForLane(_market, lane);
    final confirmed = await showGameFramedDialog<bool>(
      context: context,
      builder: (dialogContext) => GameModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '리롤 확인',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _rerollConfirmMessage(laneLabel, rerollCost),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GameActionButton(
                    label: '취소',
                    background: const Color(0xFF586463),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameActionButton(
                    label: _rerollConfirmActionLabel(rerollCost),
                    background: const Color(0xFFF4A81D),
                    foreground: Colors.black,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;

    final placement = _placementForOfferLane(lane);
    if (placement != null && widget.onRerollItemOffers == null) return;
    if (lane == _MarketOfferLane.tile && widget.onRerollTileOffers == null) {
      return;
    }
    final effectPresentation = _marketRerollPresentation(_market, lane);
    final failMessage = lane == _MarketOfferLane.tile
        ? widget.onRerollTileOffers!()
        : placement == null
        ? widget.onReroll()
        : widget.onRerollItemOffers!(placement);
    if (failMessage != null) {
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      if (placement != null) {
        _pinnedItemOffers = null;
      }
      final market = _market;
      _marketRerollFeedbackTick++;
      _clampOfferPageForLane(market, lane);
      _selectedOwnedIndex = null;
      _selectFirstEntry(_offerEntriesForLane(market, lane));
      if (_selectedOfferIndex == null && _selectedItemOfferIndex < 0) {
        _selectedOwnedIndex = market.ownedEntries.isEmpty ? null : 0;
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    await widget.onStateChanged();
  }

  void _buySelected() {
    final index = _selectedOfferIndex;
    if (index == null) return;
    final offers = _market.offers;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final flightLabel = localizedJesterName(context, boughtOffer.card);
    final sourceEntry = _MarketOfferEntry.jester(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final effectPresentation = _marketPurchasePresentation(
      market: _market,
      category: 'jester',
      targetLabel: flightLabel,
      discountSourceLabel: boughtOffer.discountSourceLabel,
    );
    final failMessage = widget.onBuyOffer(boughtOffer);
    if (failMessage != null) {
      _startMarketDenyFeedback('jester-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      _clampOfferPageForLane(market, _MarketOfferLane.jester);
      final purchasedSlot = _findPurchasedJesterSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        final endOffset = _flightCenterForKey(
          _jesterSlotKey(purchasedSlot.slotIndex),
        );
        _shopTab = _MarketShopTab.cardsAndQuickSlots;
        _selectedOwnedIndex = purchasedSlot.slotIndex;
        _selectedOfferIndex = null;
        _selectedItemOfferIndex = -1;
        _selectedItemSlotIndex = -1;
        _startPurchaseFlight(
          label: flightLabel,
          slotLabel: 'J${purchasedSlot.slotIndex + 1}',
          item: false,
          spentGold: _spentGoldForPurchase(
            before: marketBeforePurchase,
            after: market,
            fallback: boughtOffer.price,
          ),
          startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
          endAlignment: _jesterSlotFlightEndAlignment(purchasedSlot.slotIndex),
          marketBeforePurchase: marketBeforePurchase,
          sourceVisibleIndex: sourceIndex,
          startOffset: startOffset,
          endOffset: endOffset,
          jesterCard: boughtOffer.card,
        );
      } else if (market.ownedEntries.isNotEmpty) {
        _selectedOwnedIndex = market.ownedEntries.length - 1;
        _selectedOfferIndex = null;
      } else {
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    _queueStateSave();
  }

  void _buySelectedItem() {
    final offers = _market.itemOffers;
    final index = _selectedItemOfferIndex;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final flightLabel = localizedItemName(context, boughtOffer);
    final sourceEntry = _MarketOfferEntry.item(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final effectPresentation = _marketPurchasePresentation(
      market: _market,
      category: 'item',
      targetLabel: flightLabel,
      discountSourceLabel: boughtOffer.discountSourceLabel,
    );
    final failMessage = widget.onBuyItemOffer(boughtOffer);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      _pinnedItemOffers = null;
      final market = _market;
      _clampOfferPageForLane(market, _currentOfferLane);
      final purchasedSlot = _findPurchasedItemSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        final endOffset = _flightCenterForKey(
          _itemSlotKey(purchasedSlot.slotLabel),
        );
        _shopTab = switch (purchasedSlot.placement) {
          ItemPlacement.quickSlot ||
          ItemPlacement.passiveRack => _MarketShopTab.cardsAndQuickSlots,
          ItemPlacement.inventory ||
          ItemPlacement.equipped => _MarketShopTab.toolsAndGear,
        };
        _setOfferLaneForPlacement(purchasedSlot.placement);
        _selectedItemSlotIndex = purchasedSlot.slotIndex;
        _selectedItemOfferIndex = -1;
        _selectedOfferIndex = null;
        _selectedOwnedIndex = null;
        _startPurchaseFlight(
          label: flightLabel,
          slotLabel: purchasedSlot.slotLabel,
          item: true,
          spentGold: _spentGoldForPurchase(
            before: marketBeforePurchase,
            after: market,
            fallback: boughtOffer.price,
          ),
          startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
          endAlignment: _itemSlotFlightEndAlignment(purchasedSlot),
          marketBeforePurchase: marketBeforePurchase,
          sourceVisibleIndex: sourceIndex,
          startOffset: startOffset,
          endOffset: endOffset,
          itemPlacement: boughtOffer.item.placement,
          itemRarity: boughtOffer.item.rarity,
        );
      } else {
        final nextEntries = _offerEntriesForLane(market, _currentOfferLane);
        final stillSelected = nextEntries.any(
          (entry) =>
              entry.kind == _MarketOfferEntryKind.item &&
              entry.itemIndex == _selectedItemOfferIndex,
        );
        if (!stillSelected) {
          _selectFirstEntry(nextEntries);
        }
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    _queueStateSave();
  }

  void _buySelectedTile() {
    final offers = _market.tileOffers;
    final index = _selectedTileOfferIndex;
    if (index < 0 || index >= offers.length) return;
    final marketBeforePurchase = _market;
    final boughtOffer = offers[index];
    final sourceEntry = _MarketOfferEntry.tile(index);
    final sourceIndex = _visibleOfferLaneIndex(sourceEntry);
    final sourceCount = _visibleOfferLaneCount();
    final startOffset = _flightCenterForKey(_offerKey(sourceEntry));
    final failMessage = widget.onBuyTileOffer(index);
    if (failMessage != null) {
      _startMarketDenyFeedback('tile-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      _clampOfferPageForLane(market, _MarketOfferLane.tile);
      _selectFirstEntry(_offerEntriesForLane(market, _MarketOfferLane.tile));
      _startPurchaseFlight(
        label: _tileLabel(boughtOffer.tile),
        slotLabel: 'Deck',
        item: false,
        spentGold: boughtOffer.isFreeReward ? 0 : boughtOffer.price,
        startAlignment: _offerFlightStartAlignment(sourceIndex, sourceCount),
        endAlignment: const Alignment(1.36, -0.04),
        marketBeforePurchase: marketBeforePurchase,
        sourceVisibleIndex: sourceIndex,
        startOffset: startOffset,
        endOffset: _deckTileFlightEndOffset(),
        tile: boughtOffer.tile,
      );
    });
    _queueStateSave();
    showBottomNotice(context, '${_tileLabel(boughtOffer.tile)} 덱 추가');
  }

  RummiMarketItemSlotView? _findPurchasedItemSlot(
    RummiMarketRuntimeFacade market,
    RummiMarketItemOfferView offer,
  ) {
    for (final slot in market.itemSlots) {
      if (slot.contentId == offer.contentId &&
          slot.placement == offer.item.placement) {
        return slot;
      }
    }
    return null;
  }

  RummiMarketOwnedEntryView? _findPurchasedJesterSlot(
    RummiMarketRuntimeFacade market,
    RummiMarketOfferView offer,
  ) {
    for (final entry in market.ownedEntries.reversed) {
      if (entry.contentId == offer.contentId) {
        return entry;
      }
    }
    return null;
  }

  int _spentGoldForPurchase({
    required RummiMarketRuntimeFacade before,
    required RummiMarketRuntimeFacade after,
    required int fallback,
  }) {
    final spent = before.gold - after.gold;
    if (spent < 0) return fallback;
    return spent;
  }

  void _startPurchaseFlight({
    required String label,
    required String slotLabel,
    required bool item,
    required int spentGold,
    required Alignment startAlignment,
    required Alignment endAlignment,
    required RummiMarketRuntimeFacade marketBeforePurchase,
    required int sourceVisibleIndex,
    Offset? startOffset,
    Offset? endOffset,
    RummiJesterCard? jesterCard,
    Tile? tile,
    ItemPlacement? itemPlacement,
    ItemRarity? itemRarity,
  }) {
    final tick = _purchaseFlightTick + 1;
    _purchaseFlightTick = tick;
    _purchaseFlight = _MarketPurchaseFlight(
      tick: tick,
      label: label,
      slotLabel: slotLabel,
      item: item,
      spentGold: spentGold,
      startAlignment: startAlignment,
      endAlignment: endAlignment,
      marketBeforePurchase: marketBeforePurchase,
      sourceVisibleIndex: sourceVisibleIndex,
      startOffset: startOffset,
      endOffset: endOffset,
      jesterCard: jesterCard,
      tile: tile,
      itemPlacement: itemPlacement,
      itemRarity: itemRarity,
    );
    Future<void>.delayed(_marketPurchaseFlightDuration, () {
      if (!mounted || _purchaseFlight?.tick != tick) return;
      setState(() => _purchaseFlight = null);
    });
  }

  void _startSaleFlight({
    required RummiMarketItemSlotView slot,
    required ItemDefinition item,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _saleFlightTick + 1;
    _saleFlightTick = tick;
    _saleFlight = _MarketSaleFlight(
      tick: tick,
      label: localizedItemSlotName(context, slot),
      item: true,
      sellGold: item.sellPrice,
      startOffset: startOffset,
      endOffset: endOffset,
      itemPlacement: slot.placement,
      itemRarity: item.rarity,
    );
    Future<void>.delayed(_marketPurchaseFlightDuration, () {
      if (!mounted || _saleFlight?.tick != tick) return;
      setState(() => _saleFlight = null);
    });
  }

  void _startJesterSaleFlight({
    required RummiMarketOwnedEntryView entry,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _saleFlightTick + 1;
    _saleFlightTick = tick;
    _saleFlight = _MarketSaleFlight(
      tick: tick,
      label: localizedJesterName(context, entry.card),
      item: false,
      sellGold: entry.sellPrice,
      startOffset: startOffset,
      endOffset: endOffset,
      jesterCard: entry.card,
    );
    Future<void>.delayed(_marketPurchaseFlightDuration, () {
      if (!mounted || _saleFlight?.tick != tick) return;
      setState(() => _saleFlight = null);
    });
  }

  void _startMarketItemUseFlight({
    required RummiMarketItemSlotView slot,
    required ItemDefinition item,
    required int goldGain,
    required Offset? startOffset,
    required Offset? endOffset,
  }) {
    final tick = _itemUseFlightTick + 1;
    _itemUseFlightTick = tick;
    _itemUseFlight = _MarketItemUseFlight(
      tick: tick,
      label: localizedItemSlotName(context, slot),
      goldGain: goldGain,
      startOffset: startOffset,
      endOffset: endOffset,
      itemPlacement: slot.placement,
      itemRarity: item.rarity,
    );
    Future<void>.delayed(_marketPurchaseFlightDuration, () {
      if (!mounted || _itemUseFlight?.tick != tick) return;
      setState(() => _itemUseFlight = null);
    });
  }

  int _visibleOfferLaneCount() {
    final lane = _currentOfferLane;
    final entries = _offerEntriesForLane(_market, lane);
    final page = _offerPageFor(lane);
    return _pagedItems(entries, page).length;
  }

  int _visibleOfferLaneIndex(_MarketOfferEntry target) {
    final lane = _currentOfferLane;
    final entries = _offerEntriesForLane(_market, lane);
    final page = _offerPageFor(lane);
    final visible = _pagedItems(entries, page);
    final index = visible.indexWhere(
      (entry) =>
          entry.kind == target.kind &&
          entry.jesterIndex == target.jesterIndex &&
          entry.itemIndex == target.itemIndex &&
          entry.tileIndex == target.tileIndex,
    );
    return index < 0 ? 0 : index;
  }

  Alignment _offerFlightStartAlignment(int visibleIndex, int visibleCount) {
    if (visibleCount <= 1) return const Alignment(0, 0.64);
    if (visibleCount == 2) {
      return Alignment(visibleIndex == 0 ? -0.36 : 0.36, 0.64);
    }
    return Alignment((-0.52 + (visibleIndex.clamp(0, 2) * 0.52)), 0.64);
  }

  Alignment _jesterSlotFlightEndAlignment(int slotIndex) {
    return Alignment((-0.52 + (slotIndex.clamp(0, 4) * 0.30)), -0.48);
  }

  Alignment _itemSlotFlightEndAlignment(RummiMarketItemSlotView slot) {
    final label = slot.slotLabel;
    final number = label.length > 1 ? int.tryParse(label.substring(1)) ?? 1 : 1;
    final index = (number - 1).clamp(0, 2);
    if (label.startsWith('Q')) {
      return Alignment(-0.52 + (index * 0.30), -0.27);
    }
    if (label.startsWith('P')) {
      return Alignment(0.38 + (index.clamp(0, 1) * 0.30), -0.27);
    }
    if (label.startsWith('G')) {
      return Alignment(-0.52 + (index * 0.30), -0.12);
    }
    return Alignment(-0.52 + (index * 0.30), -0.28);
  }

  Offset? _flightCenterForKey(GlobalKey key) {
    final surfaceContext = _marketSurfaceKey.currentContext;
    final targetContext = key.currentContext;
    if (surfaceContext == null || targetContext == null) return null;
    final surfaceBox = surfaceContext.findRenderObject();
    final targetBox = targetContext.findRenderObject();
    if (surfaceBox is! RenderBox || targetBox is! RenderBox) return null;
    final targetCenter = targetBox.localToGlobal(
      targetBox.size.center(Offset.zero),
    );
    return surfaceBox.globalToLocal(targetCenter);
  }

  Offset? _deckTileFlightEndOffset() {
    final surfaceContext = _marketSurfaceKey.currentContext;
    if (surfaceContext == null) return null;
    final surfaceBox = surfaceContext.findRenderObject();
    if (surfaceBox is! RenderBox) return null;
    return Offset(surfaceBox.size.width + 54, surfaceBox.size.height * 0.46);
  }

  bool _isPurchaseSourceIndex(int visibleIndex) {
    final flight = _purchaseFlight;
    if (flight == null) return false;
    return flight.sourceVisibleIndex == visibleIndex;
  }

  void _startMarketDenyFeedback(String target, String reason) {
    final tick = _marketDenyTick + 1;
    setState(() {
      _marketDenyTick = tick;
      _marketDenyTarget = target;
      _marketDenyReason = reason;
    });
    Future<void>.delayed(GamePresentationTimings.marketDenyFeedbackHold, () {
      if (!mounted || _marketDenyTick != tick) return;
      setState(() {
        _marketDenyTarget = null;
        _marketDenyReason = null;
      });
    });
  }

  void _startEffectPresentation(ItemPresentationEvent event) {
    final tick = _effectPresentationTick + 1;
    _effectPresentationTick = tick;
    setState(() {
      _effectPresentation = _MarketEffectPresentation(tick: tick, event: event);
    });
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _effectPresentation?.tick != tick) return;
      setState(() => _effectPresentation = null);
    });
  }

  ItemPresentationEvent? _marketRerollPresentation(
    RummiMarketRuntimeFacade market,
    _MarketOfferLane lane,
  ) {
    final source = _activeItemSlotWhere(
      (item) =>
          item.effect.timing == 'market_reroll' &&
          (item.effect.op == 'free_next_reroll' ||
              item.effect.op == 'discount_next_reroll'),
    );
    if (source == null) return null;
    final item = source.item;
    if (item == null) return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: localizedItemSlotName(context, source),
      target: ItemPresentationTarget(
        kind: ItemPresentationTargetKind.marketReroll,
        label: _offerLaneLabel(lane),
      ),
      resultLabel: market.rerollCost <= 0 ? '리롤 무료 적용' : '리롤 비용 할인',
    );
  }

  ItemPresentationEvent? _marketPurchasePresentation({
    required RummiMarketRuntimeFacade market,
    required String category,
    required String targetLabel,
    required String? discountSourceLabel,
  }) {
    final purchaseSource = _activeItemSlotWhere(
      (item) =>
          item.effect.op == 'discount_next_purchase' &&
          (item.effect.timing == 'market_buy' ||
              (item.effect.timing == 'market_buy_if_category' &&
                  item.effect.value('category') == category)),
    );
    final compassSource = discountSourceLabel == '나침반'
        ? _activeItemSlotWhere((item) => item.id == 'market_compass')
        : null;
    final source = purchaseSource ?? compassSource;
    final item = source?.item;
    if (source == null || item == null) {
      if (discountSourceLabel == null) return null;
      return ItemPresentationEvent(
        itemId: discountSourceLabel == '나침반'
            ? 'market_compass'
            : discountSourceLabel,
        sourceKind: ItemPresentationSourceKind.passive,
        sourceLabel: discountSourceLabel,
        target: ItemPresentationTarget(
          kind: category == 'jester'
              ? ItemPresentationTargetKind.marketOffer
              : ItemPresentationTargetKind.itemOffer,
          label: targetLabel,
        ),
        resultLabel: '구매가 -1G',
      );
    }
    final labels = <String>[
      localizedItemSlotName(context, source),
      if (purchaseSource != null && compassSource != null)
        localizedItemSlotName(context, compassSource),
    ];
    final discount = _marketPurchaseDiscountAmount(
      item: purchaseSource?.item,
      compassActive: compassSource != null,
    );
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(source.placement),
      sourceLabel: labels.join(' + '),
      target: ItemPresentationTarget(
        kind: category == 'jester'
            ? ItemPresentationTargetKind.marketOffer
            : ItemPresentationTargetKind.itemOffer,
        label: targetLabel,
      ),
      resultLabel: discount > 0 ? '구매가 -${discount}G' : '할인 적용',
    );
  }

  int _marketPurchaseDiscountAmount({
    required ItemDefinition? item,
    required bool compassActive,
  }) {
    var total = 0;
    if (item != null) {
      total += (item.effect.value('amount') as num?)?.toInt() ?? 0;
    }
    if (compassActive) {
      total += 1;
    }
    return total;
  }

  RummiMarketItemSlotView? _activeItemSlotWhere(
    bool Function(ItemDefinition item) test,
  ) {
    for (final slot in _market.itemSlots) {
      final item = slot.item;
      if (item == null || slot.locked || slot.count <= 0) continue;
      if (test(item)) return slot;
    }
    return null;
  }

  ItemPresentationSourceKind _presentationSourceKind(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => ItemPresentationSourceKind.quickSlot,
      ItemPlacement.passiveRack => ItemPresentationSourceKind.passive,
      ItemPlacement.inventory => ItemPresentationSourceKind.tool,
      ItemPlacement.equipped => ItemPresentationSourceKind.gear,
    };
  }

  void _useSelectedMarketItem(RummiMarketItemSlotView slot) {
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final failMessage = widget.onUseMarketItem(item);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    final feedbackTick = _marketUseFeedbackTick + 1;
    final goldGain = _marketUseGoldGain(item);
    final effectPresentation = _marketUsePresentation(slot, item);
    setState(() {
      if (item.effect.op == 'reroll_item_offers_only') {
        _pinnedItemOffers = null;
      }
      _marketUseFeedbackTick = feedbackTick;
      _marketUseFeedbackLabel = '사용 완료';
      _marketUseFeedbackDelta = _marketUseFeedbackDeltaLabel(item);
      if (goldGain != null) {
        _startMarketItemUseFlight(
          slot: slot,
          item: item,
          goldGain: goldGain,
          startOffset: startOffset,
          endOffset: endOffset,
        );
      }
      final market = _market;
      final stillExists = market.itemSlots.any(
        (nextSlot) =>
            nextSlot.slotIndex == slot.slotIndex && nextSlot.item != null,
      );
      if (!stillExists) {
        _selectedItemSlotIndex = -1;
        _selectFirstEntry(_offerEntriesForLane(market, _currentOfferLane));
      }
    });
    if (effectPresentation != null) {
      _startEffectPresentation(effectPresentation);
    }
    Future<void>.delayed(GamePresentationTimings.marketUseFeedbackHold, () {
      if (!mounted || _marketUseFeedbackTick != feedbackTick) return;
      setState(() {
        _marketUseFeedbackLabel = null;
        _marketUseFeedbackDelta = null;
      });
    });
    _queueStateSave();
  }

  String? _marketUseFeedbackDeltaLabel(ItemDefinition item) {
    final amount = _marketUseGoldGain(item);
    return switch (item.effect.op) {
      'gain_gold' when amount != null => '+${amount}G',
      'reroll_item_offers_only' => 'Item 후보 교체',
      _ => null,
    };
  }

  ItemPresentationEvent? _marketUsePresentation(
    RummiMarketItemSlotView slot,
    ItemDefinition item,
  ) {
    if (item.effect.op != 'reroll_item_offers_only') return null;
    return ItemPresentationEvent(
      itemId: item.id,
      sourceKind: _presentationSourceKind(slot.placement),
      sourceLabel: localizedItemSlotName(context, slot),
      target: const ItemPresentationTarget(
        kind: ItemPresentationTargetKind.itemOffer,
        label: 'Item 후보 영역',
      ),
      resultLabel: '후보 교체 완료',
    );
  }

  int? _marketUseGoldGain(ItemDefinition item) {
    final amount = item.effect.amount;
    if (item.effect.op != 'gain_gold' || amount == null) return null;
    return amount.toInt();
  }

  Widget? _ownedMarketItemActionPane(
    BuildContext context,
    RummiMarketItemSlotView slot,
  ) {
    final item = slot.item;
    if (item == null) return null;
    final sellAction = _MarketActionPane(
      priceLabel: '+${item.sellPrice}',
      buttonLabel: '판매',
      buttonColor: const Color(0xFFB74B3B),
      onPressed: () => _sellMarketItem(slot),
    );
    if (item.effect.timing == 'use_market' ||
        item.effect.timing == 'use_market_if_gold_lte') {
      return _MarketUseSellActionPane(
        count: slot.count,
        sellPrice: item.sellPrice,
        onUse: () => _useSelectedMarketItem(slot),
        onSell: () => _sellMarketItem(slot),
        denyActive: _marketDenyTarget == 'item-use',
        denyTick: _marketDenyTick,
        denyReason: _marketDenyReason,
      );
    }
    if (item.effect.timing == 'market_buy' ||
        item.effect.timing == 'market_buy_if_category') {
      return sellAction;
    }
    return sellAction;
  }

  void _sellOwned(int index) {
    final marketBeforeSell = _market;
    if (index < 0 || index >= marketBeforeSell.ownedEntries.length) return;
    final soldEntry = marketBeforeSell.ownedEntries[index];
    final startOffset = _flightCenterForKey(_jesterSlotKey(index));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellOwnedJester(index);
    if (!ok) return;
    showBottomNotice(context, '제스터를 판매했습니다.');
    setState(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startJesterSaleFlight(
        entry: soldEntry,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      if (market.ownedEntries.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(0, market.ownedEntries.length - 1);
      }
    });
    _queueStateSave();
  }

  void _sellMarketItem(RummiMarketItemSlotView slot) {
    final marketBeforeSell = _market;
    final item = slot.item;
    if (item == null) return;
    final startOffset = _flightCenterForKey(_itemSlotKey(slot.slotLabel));
    final endOffset = _flightCenterForKey(_goldChipKey);
    final ok = widget.onSellMarketItem(item);
    if (!ok) return;
    showBottomNotice(context, '아이템을 판매했습니다.');
    setState(() {
      _pinnedItemOffers = marketBeforeSell.itemOffers;
      _startSaleFlight(
        slot: slot,
        item: item,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final market = _market;
      _selectedItemSlotIndex = -1;
      _selectFirstEntry(_offerEntriesForLane(market, _currentOfferLane));
    });
    _queueStateSave();
  }

  Future<bool> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
      message: widget.isDebugFixtureRun
          ? '디버그 픽스처 시작 상태로 다시 불러올까요?\n현재 화면에서 만든 변경 사항은 취소됩니다.'
          : '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await widget.onRestartRun();
    return true;
  }

  Future<bool> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await widget.onExitToTitle();
    return true;
  }

  Future<void> _openOptions() async {
    if (_optionsDialogOpen) return;
    _dismissMarketTutorial();
    while (mounted) {
      final activeRunSaveView = widget.readActiveRunSaveView?.call();
      _optionsDialogOpen = true;
      SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
      if (!mounted) return;
      final action = await showGameFramedDialog<_MarketOptionsCloseAction>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => GameModalCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Market 옵션',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GameIconButtonChip(
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.resumeGame),
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GameDialogSection(
                title: 'Run Seed',
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            '${widget.runSeed}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        GameIconButtonChip(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: '${widget.runSeed}'),
                            );
                            if (!mounted) return;
                            showTopNotice(context, '시드 번호를 복사했습니다.');
                          },
                          icon: Icons.copy_rounded,
                          backgroundColor: const Color(0xFF21423A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (activeRunSaveView != null)
                GameDialogSection(
                  title: 'Run Snapshot',
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeRunSummaryLabel(activeRunSaveView),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              GameMenuActionTile(
                title: context.tr('runInfoTitle'),
                subtitle: context.tr('runInfoActionSubtitle'),
                icon: Icons.bar_chart_rounded,
                accentColor: const Color(0xFFF2C14E),
                onTap: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(_MarketOptionsCloseAction.openRunInfo);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('tutorialMarketReplayTitle'),
                subtitle: context.tr('tutorialMarketReplaySubtitle'),
                icon: Icons.help_outline_rounded,
                accentColor: Colors.lightGreenAccent.shade100,
                onTap: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(_MarketOptionsCloseAction.openMarketTutorial);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('settings'),
                subtitle: '설정 화면을 열고, Market으로 다시 돌아옵니다.',
                icon: Icons.settings_rounded,
                accentColor: Colors.lightBlueAccent.shade100,
                onTap: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(_MarketOptionsCloseAction.openSettings);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: widget.isDebugFixtureRun
                    ? '디버그 픽스처 재로드'
                    : '현재 Station 재시작',
                subtitle: '현재 Station 시작 시점으로 되돌립니다.',
                icon: Icons.refresh_rounded,
                accentColor: Colors.amber.shade200,
                onTap: () async {
                  final changed = await _restartCurrentRun();
                  if (!dialogContext.mounted || !changed) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(_MarketOptionsCloseAction.resumeGame);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('exit'),
                subtitle: '현재 진행을 멈추고 메인 메뉴로 돌아갑니다.',
                icon: Icons.logout_rounded,
                accentColor: Colors.redAccent.shade100,
                onTap: () async {
                  final changed = await _exitToTitleWithConfirm();
                  if (!dialogContext.mounted || !changed) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(_MarketOptionsCloseAction.keepPaused);
                },
              ),
            ],
          ),
        ),
      );
      _optionsDialogOpen = false;
      if (!mounted) return;
      switch (action ?? _MarketOptionsCloseAction.resumeGame) {
        case _MarketOptionsCloseAction.resumeGame:
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case _MarketOptionsCloseAction.keepPaused:
          return;
        case _MarketOptionsCloseAction.openSettings:
          SoundManager.beginBgmAutoResumeBlock();
          try {
            await widget.onOpenSettings();
          } finally {
            SoundManager.endBgmAutoResumeBlock();
          }
          if (!mounted) return;
        case _MarketOptionsCloseAction.openRunInfo:
          await showGameRunInfoDialog(
            context: context,
            playedHandCounts:
                widget.readActiveRunSaveView?.call()?.currentPlayedHandCounts ??
                const {},
            handGrowthStates:
                widget.readActiveRunSaveView?.call()?.currentHandGrowthStates ??
                const {},
            addedDeckTiles: _market.addedDeckTiles,
          );
          if (!mounted) return;
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case _MarketOptionsCloseAction.openMarketTutorial:
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          await _startMarketTutorial(markSeen: false);
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final currentRerollCost = _rerollCostForLane(market, currentOfferLane);
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
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF123B32), Color(0xFF102E27), Color(0xFF0A1F1A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF507564).withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              key: _marketSurfaceKey,
              children: [
                const Positioned.fill(child: GameTableBackdrop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Market',
                              style: TextStyle(
                                color: Colors.white,
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
                            foregroundColor: const Color(0xFFF2C14E),
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
                          child: AnimatedSwitcher(
                            duration: GamePresentationTimings.marketTabSwitch,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.035, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Column(
                              key: ValueKey<_MarketShopTab>(_shopTab),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_shopTab ==
                                    _MarketShopTab.cardsAndQuickSlots) ...[
                                  _MarketTutorialTarget(
                                    showcaseKey: _marketCardsSlotsTutorialKey,
                                    child: Column(
                                      children: [
                                        _MarketSectionBox(
                                          title: 'Jester Slots',
                                          trailing:
                                              '${market.ownedEntries.length}/${market.maxOwnedSlots}',
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            8,
                                            14,
                                            8,
                                          ),
                                          child: SizedBox(
                                            height: _marketOwnedCardHeight + 6,
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
                                                  final card = ownedEntry?.card;
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
                                                      market.jesterSlotCapacity;
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
                                                  final child = _MarketSlotPulse(
                                                    active:
                                                        pulse ||
                                                        recentlyUnlocked,
                                                    showUnlockLock:
                                                        recentlyUnlocked,
                                                    child: _MarketSelectableCardFrame(
                                                      selected: false,
                                                      width:
                                                          _marketOwnedCardWidth,
                                                      height:
                                                          _marketOwnedCardHeight,
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

                                                  return SizedBox(
                                                    key: _jesterSlotKey(index),
                                                    width:
                                                        _marketOwnedCardWidth +
                                                        (_marketCardSelectionInset *
                                                            2),
                                                    height:
                                                        _marketOwnedCardHeight +
                                                        (_marketCardSelectionInset *
                                                            2),
                                                    child:
                                                        card == null || locked
                                                        ? child
                                                        : GestureDetector(
                                                            onTap: () =>
                                                                _selectOwned(
                                                                  index,
                                                                ),
                                                            child: child,
                                                          ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _MarketQuickPassiveSlotsSection(
                                          slots: visibleItemSlots,
                                          selectedItemSlotIndex:
                                              _selectedItemSlotIndex,
                                          pulsingSlotLabel:
                                              _purchaseFlight?.item == true
                                              ? _purchaseFlight?.slotLabel
                                              : null,
                                          slotKeyForLabel: _itemSlotKey,
                                          onTap: _selectItemSlot,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  _MarketTutorialTarget(
                                    showcaseKey: _marketToolsSlotsTutorialKey,
                                    child: Column(
                                      children: [
                                        _MarketItemSlotsSection(
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
                                        const SizedBox(height: 6),
                                        _MarketItemSlotsSection(
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
                                      ],
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
                                                    color: Color(0xFFF2C14E),
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
                                            effectText:
                                                '다음 블라인드부터 드로우 덱에 추가됩니다.',
                                            tags: [
                                              '타일 ${_tileLabel(selectedTileOffer.tile)}',
                                              '칩 ${selectedTileOffer.tile.baseChipValue}',
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
                                            color: Colors.white.withValues(
                                              alpha: 0.68,
                                            ),
                                          ),
                                    trailing: selectedOwned != null
                                        ? _MarketActionPane(
                                            priceLabel:
                                                '+${selectedOwned.sellPrice}',
                                            buttonLabel: '판매',
                                            buttonColor: const Color(
                                              0xFFB74B3B,
                                            ),
                                            onPressed: () => _sellOwned(
                                              selectedOwned.slotIndex,
                                            ),
                                          )
                                        : selectedOffer != null
                                        ? _MarketActionPane(
                                            priceLabel:
                                                '${selectedOffer.price}',
                                            buttonLabel: '구매',
                                            buttonColor: const Color(
                                              0xFFF4A81D,
                                            ),
                                            foreground: Colors.black,
                                            onPressed:
                                                selectedOffer.isAffordable
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
                                                _marketDenyTarget ==
                                                'jester-buy',
                                            denyTick: _marketDenyTick,
                                            denyReason: _marketDenyReason,
                                          )
                                        : selectedItemOffer != null
                                        ? _MarketActionPane(
                                            priceLabel:
                                                '${selectedItemOffer.price}',
                                            buttonLabel: '구매',
                                            buttonColor: const Color(
                                              0xFFF4A81D,
                                            ),
                                            foreground: Colors.black,
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
                                            buttonColor: const Color(
                                              0xFFF4A81D,
                                            ),
                                            foreground: Colors.black,
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
                                      height: _marketShopPanelHeight,
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
                                              rerollCost: currentRerollCost,
                                              feedbackTick:
                                                  _marketRerollFeedbackTick,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                          color: Colors.white
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
                                                                        offer: market
                                                                            .offers[visibleOfferEntries[i].jesterIndex!],
                                                                        selected:
                                                                            _selectedOfferIndex ==
                                                                            visibleOfferEntries[i].jesterIndex,
                                                                        canAfford: market
                                                                            .offers[visibleOfferEntries[i].jesterIndex!]
                                                                            .isAffordable,
                                                                        onTap: () => _selectOffer(
                                                                          visibleOfferEntries[i]
                                                                              .jesterIndex!,
                                                                        ),
                                                                      ),
                                                                      _MarketOfferEntryKind.item => _MarketItemOfferCard(
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
                                                                      _MarketOfferEntryKind.tile => _MarketTileOfferCard(
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
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GameActionButton(
                              label: '메인 메뉴',
                              background: const Color(0xFF586463),
                              onPressed: () async {
                                Navigator.of(context).pop(false);
                                await widget.onExitToTitle();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GameActionButton(
                              label: '다음 Station',
                              background: const Color(0xFF267B67),
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
                    child: _MarketSlotUnlockBanner(
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

class _MarketEntryMotion extends StatelessWidget {
  const _MarketEntryMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-entry-motion'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketEntryIntro,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = (value / 0.72).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MarketTutorialTarget extends StatelessWidget {
  const _MarketTutorialTarget({required this.showcaseKey, required this.child});

  final GlobalKey showcaseKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: showcaseKey, child: child);
  }
}

class _MarketUseFeedbackToast extends StatelessWidget {
  const _MarketUseFeedbackToast({required this.label, this.deltaLabel});

  final String label;
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.16),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('market-use-feedback'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketUseFeedbackIn,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - value)),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF183E32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF86F4C3).withValues(alpha: 0.72),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFB9F6D3),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (deltaLabel != null)
                    Text(
                      deltaLabel!,
                      style: const TextStyle(
                        color: Color(0xFFF2C14E),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketEffectPresentationToast extends StatelessWidget {
  const _MarketEffectPresentationToast({required this.presentation});

  final _MarketEffectPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final event = presentation.event;
    final accent = _effectAccent(event.sourceKind);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.68),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('market-effect-presentation-${presentation.tick}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketUseFeedbackIn,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -8 * (1 - value)),
                child: child,
              ),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1D25).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.72)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.sourceLabel,
                      key: const ValueKey('market-effect-source'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.target.label,
                            key: const ValueKey('market-effect-target'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.resultLabel,
                          key: const ValueKey('market-effect-result'),
                          maxLines: 1,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _effectAccent(ItemPresentationSourceKind kind) {
    return switch (kind) {
      ItemPresentationSourceKind.quickSlot => const Color(0xFFF4A81D),
      ItemPresentationSourceKind.passive => const Color(0xFF6EE7B7),
      ItemPresentationSourceKind.tool => const Color(0xFF86B7FF),
      ItemPresentationSourceKind.gear => const Color(0xFFFFD76B),
      ItemPresentationSourceKind.jester => const Color(0xFFFF8FA3),
    };
  }
}

class _MarketSectionBox extends StatelessWidget {
  const _MarketSectionBox({
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(8, 6, 8, 6),
  });

  final String? title;
  final String? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    if (title != null) _MarketSectionTitleBadge(label: title!),
                    const Spacer(),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: const TextStyle(
                          color: Color(0xFFF2C14E),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _MarketSectionTitleBadge extends StatelessWidget {
  const _MarketSectionTitleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final background = _marketSectionTitleBackground(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF18382D), width: 1.4),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF07110D),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

Color _marketSectionTitleBackground(String label) {
  return switch (label) {
    'Jester Slots' => const Color(0xFFEDE7DB),
    'Q-SLT' => _itemOfferSurface(ItemPlacement.quickSlot),
    'PSV' => _itemOfferSurface(ItemPlacement.passiveRack),
    'Tool Slots' => _itemOfferSurface(ItemPlacement.inventory),
    'Gear Slots' => _itemOfferSurface(ItemPlacement.equipped),
    _ => const Color(0xFFEDE7DB),
  };
}

class _MarketQuickPassiveSlotsSection extends StatelessWidget {
  const _MarketQuickPassiveSlotsSection({
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    final quickSlots = slots
        .where((slot) => slot.placement == ItemPlacement.quickSlot)
        .toList(growable: false);
    final passiveSlots = slots
        .where((slot) => slot.placement == ItemPlacement.passiveRack)
        .toList(growable: false);
    return _MarketSectionBox(
      title: null,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _MarketSlotGroup(
              label: 'Q-SLT',
              slots: quickSlots,
              selectedItemSlotIndex: selectedItemSlotIndex,
              pulsingSlotLabel: pulsingSlotLabel,
              slotKeyForLabel: slotKeyForLabel,
              onTap: onTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _MarketSlotGroup(
              label: 'PSV',
              slots: passiveSlots,
              selectedItemSlotIndex: selectedItemSlotIndex,
              pulsingSlotLabel: pulsingSlotLabel,
              slotKeyForLabel: slotKeyForLabel,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketSlotGroup extends StatelessWidget {
  const _MarketSlotGroup({
    required this.label,
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final String label;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketSectionTitleBadge(label: label),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _MarketItemGhostChip(
                key: slotKeyForLabel(slots[i].slotLabel),
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse:
                    pulsingSlotLabel == slots[i].slotLabel ||
                    slots[i].recentlyUnlocked,
                showUnlockLock: slots[i].recentlyUnlocked,
                onTap: onTap,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MarketItemSlotsSection extends StatelessWidget {
  const _MarketItemSlotsSection({
    required this.title,
    required this.slots,
    required this.selectedItemSlotIndex,
    required this.pulsingSlotLabel,
    required this.slotKeyForLabel,
    required this.onTap,
  });

  final String title;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final GlobalKey Function(String slotLabel) slotKeyForLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    return _MarketSectionBox(
      title: title,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _MarketItemGhostChip(
                key: slotKeyForLabel(slots[i].slotLabel),
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse:
                    pulsingSlotLabel == slots[i].slotLabel ||
                    slots[i].recentlyUnlocked,
                showUnlockLock: slots[i].recentlyUnlocked,
                onTap: onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketSpeechPanel extends StatelessWidget {
  const _MarketSpeechPanel({
    required this.title,
    required this.subtitle,
    required this.body,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF173126),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: _marketSpeechPanelHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(child: body),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketActionPane extends StatelessWidget {
  const _MarketActionPane({
    required this.priceLabel,
    required this.buttonLabel,
    required this.buttonColor,
    this.foreground = Colors.white,
    this.onPressed,
    this.onDeniedPressed,
    this.disabledReason,
    this.denyActive = false,
    this.denyTick = 0,
    this.denyReason,
  });

  final String priceLabel;
  final String buttonLabel;
  final Color buttonColor;
  final Color foreground;
  final VoidCallback? onPressed;
  final VoidCallback? onDeniedPressed;
  final String? disabledReason;
  final bool denyActive;
  final int denyTick;
  final String? denyReason;

  @override
  Widget build(BuildContext context) {
    final pane = Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            priceLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF2C14E),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          GameActionButton(
            label: buttonLabel,
            background: buttonColor,
            foreground: foreground,
            compact: true,
            onPressed: onPressed,
          ),
          if (disabledReason != null) ...[
            const SizedBox(height: 4),
            Text(
              disabledReason!,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF8F74),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
    final animatedPane = TweenAnimationBuilder<double>(
      key: ValueKey<int>(denyTick),
      tween: Tween<double>(begin: 0, end: denyActive ? 1 : 0),
      duration: GamePresentationTimings.marketActionDenyShake,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shake = denyActive
            ? math.sin(value * math.pi * 5) * 5 * (1 - value)
            : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: pane,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed == null ? onDeniedPressed : null,
      child: SizedBox(
        width: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            animatedPane,
            if (denyActive)
              Positioned(
                key: const ValueKey('market-deny-feedback'),
                top: -10,
                right: 0,
                child: _MarketDenyBadge(
                  label: denyReason == null || denyReason!.isEmpty
                      ? '불가'
                      : denyReason!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketUseSellActionPane extends StatelessWidget {
  const _MarketUseSellActionPane({
    required this.count,
    required this.sellPrice,
    required this.onUse,
    required this.onSell,
    required this.denyActive,
    required this.denyTick,
    required this.denyReason,
  });

  final int count;
  final int sellPrice;
  final VoidCallback onUse;
  final VoidCallback onSell;
  final bool denyActive;
  final int denyTick;
  final String? denyReason;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'x$count',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF2C14E),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              GameActionButton(
                label: '사용',
                background: const Color(0xFF2E8BC0),
                compact: true,
                onPressed: onUse,
              ),
              const SizedBox(height: 3),
              Text(
                '+$sellPrice',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF2C14E),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              GameActionButton(
                label: '판매',
                background: const Color(0xFFB74B3B),
                compact: true,
                onPressed: onSell,
              ),
            ],
          ),
          if (denyActive)
            Positioned(
              key: const ValueKey('market-deny-feedback'),
              top: -10,
              right: 0,
              child: _MarketDenyBadge(
                label: denyReason == null || denyReason!.isEmpty
                    ? '불가'
                    : denyReason!,
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketDenyBadge extends StatelessWidget {
  const _MarketDenyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketDenyBadgeIn,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF3A1714).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF8F74), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFFFB6A6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketDescriptionText extends StatelessWidget {
  const _MarketDescriptionText(this.text, {this.color = Colors.white70});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('market-description-box'),
      constraints: const BoxConstraints(minHeight: _marketDescriptionMinHeight),
      child: SingleChildScrollView(
        child: Text(
          text,
          key: const ValueKey('market-description-text'),
          maxLines: null,
          softWrap: true,
          style: _marketDescriptionTextStyle.copyWith(color: color),
        ),
      ),
    );
  }
}

class _MarketOfferDetailBody extends StatelessWidget {
  const _MarketOfferDetailBody({required this.effectText, required this.tags});

  final String effectText;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketDescriptionText(effectText),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 3),
          _MarketDetailTagWrap(tags: tags),
        ],
      ],
    );
  }
}

class _MarketDetailTagWrap extends StatelessWidget {
  const _MarketDetailTagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(4).toList(growable: false);
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final tag in visibleTags)
          _MarketSynergyChip(label: tag, dense: true),
      ],
    );
  }
}

class _OwnedMarketItemBody extends StatelessWidget {
  const _OwnedMarketItemBody({required this.slot});

  final RummiMarketItemSlotView slot;

  @override
  Widget build(BuildContext context) {
    final effect = localizedItemSlotEffect(context, slot);
    final notice = _ownedItemSlotNotice(slot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketDescriptionText(effect),
        if (notice != null) ...[
          const SizedBox(height: 4),
          Text(
            notice,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFF2C14E),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _MarketTabBar extends StatelessWidget {
  const _MarketTabBar({required this.currentTab, required this.onChanged});

  final _MarketShopTab currentTab;
  final ValueChanged<_MarketShopTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GameChromeButton(
            label: 'Jester / Slots',
            backgroundColor: currentTab == _MarketShopTab.cardsAndQuickSlots
                ? const Color(0xFFF4A81D)
                : const Color(0xFF29453A),
            foregroundColor: currentTab == _MarketShopTab.cardsAndQuickSlots
                ? Colors.black
                : Colors.white,
            onPressed: () => onChanged(_MarketShopTab.cardsAndQuickSlots),
            height: 30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GameChromeButton(
            label: 'Tool / Gear',
            backgroundColor: currentTab == _MarketShopTab.toolsAndGear
                ? const Color(0xFFF4A81D)
                : const Color(0xFF29453A),
            foregroundColor: currentTab == _MarketShopTab.toolsAndGear
                ? Colors.black
                : Colors.white,
            onPressed: () => onChanged(_MarketShopTab.toolsAndGear),
            height: 30,
          ),
        ),
      ],
    );
  }
}

class _MarketOfferLaneBar extends StatelessWidget {
  const _MarketOfferLaneBar({
    required this.lanes,
    required this.selectedLane,
    required this.onChanged,
  });

  final List<_MarketOfferLane> lanes;
  final _MarketOfferLane selectedLane;
  final ValueChanged<_MarketOfferLane> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (final lane in lanes)
          Expanded(
            child: GameActionButton(
              label: _offerLaneLabel(lane),
              background: lane == selectedLane
                  ? const Color(0xFFEDE7DB)
                  : const Color(0xFF173D35),
              foreground: lane == selectedLane
                  ? const Color(0xFF152722)
                  : Colors.white.withValues(alpha: 0.78),
              compact: true,
              onPressed: () => onChanged(lane),
            ),
          ),
      ],
    );
  }
}

String _rerollButtonLabel(int rerollCost) {
  return rerollCost <= 0 ? '첫 리롤 무료' : '리롤 $rerollCost';
}

String _rerollConfirmActionLabel(int rerollCost) {
  return rerollCost <= 0 ? '무료 리롤' : '리롤';
}

String _rerollConfirmMessage(String laneLabel, int rerollCost) {
  if (rerollCost > 0) return '$laneLabel 후보를 리롤할까요?';
  return '$laneLabel 후보를 리롤할까요?\n상점 입장 보너스로 첫 리롤은 무료입니다.';
}

class _MarketPagerBar extends StatelessWidget {
  const _MarketPagerBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
    required this.rerollCost,
    required this.feedbackTick,
    required this.onReroll,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int rerollCost;
  final int feedbackTick;
  final VoidCallback? onReroll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIconButtonChip(
          icon: Icons.chevron_left_rounded,
          onPressed: currentPage > 0 ? onPrev : null,
          size: 32,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: Text(
              '${currentPage + 1} / $pageCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 86,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GameActionButton(
                label: _rerollButtonLabel(rerollCost),
                background: const Color(0xFF2D6F9E),
                compact: true,
                onPressed: onReroll,
              ),
              if (feedbackTick > 0)
                _MarketRerollSuccessFeedback(tick: feedbackTick),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GameIconButtonChip(
          icon: Icons.chevron_right_rounded,
          onPressed: currentPage < pageCount - 1 ? onNext : null,
          size: 32,
        ),
      ],
    );
  }
}

class _MarketRerollSuccessFeedback extends StatelessWidget {
  const _MarketRerollSuccessFeedback({required this.tick});

  final int tick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey<String>('market-reroll-success-feedback'),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey<String>('market-reroll-success-feedback-$tick'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.marketRerollSuccess,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final opacity = (1 - value).clamp(0.0, 1.0);
            final scale = 1.0 + (value * 0.18);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD45A).withValues(alpha: 0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD45A).withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _offerLaneLabel(_MarketOfferLane lane) {
  return switch (lane) {
    _MarketOfferLane.jester => 'Jester',
    _MarketOfferLane.tile => 'Tile',
    _MarketOfferLane.quickSlot => 'Q-Slot',
    _MarketOfferLane.passive => 'Passive',
    _MarketOfferLane.tool => 'Tool',
    _MarketOfferLane.gear => 'Gear',
  };
}

class _MarketItemGhostChip extends StatelessWidget {
  const _MarketItemGhostChip({
    super.key,
    required this.slot,
    this.selected = false,
    this.pulse = false,
    this.showUnlockLock = false,
    this.onTap,
  });

  final RummiMarketItemSlotView slot;
  final bool selected;
  final bool pulse;
  final bool showUnlockLock;
  final ValueChanged<RummiMarketItemSlotView>? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = slot.locked;
    final label = slot.slotLabel;
    final displayName = slot.displayName == null
        ? null
        : localizedItemSlotName(context, slot);
    final occupiedCard = displayName == null || slot.item == null
        ? null
        : SizedBox(
            width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
            height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
            child: _MarketSelectableCardFrame(
              selected: selected,
              width: _marketOfferCardWidth,
              height: _marketOfferCardHeight,
              child: _MarketItemCardFace(
                label: displayName,
                placement: slot.placement,
                rarity: slot.item!.rarity,
                selected: selected,
              ),
            ),
          );
    final foreground = locked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.38),
                size: 18,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          )
        : occupiedCard ??
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              );
    final slotBox = SizedBox(
      width: _marketOwnedCardWidth + 6,
      height: _marketOwnedCardHeight + 6,
      child: occupiedCard != null
          ? Center(child: foreground)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: locked
                    ? Colors.black.withValues(alpha: 0.24)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFF4A81D)
                      : locked
                      ? Colors.white12
                      : Colors.white10,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFF4A81D,
                          ).withValues(alpha: 0.22),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Center(child: foreground),
            ),
    );
    final child = slot.count > 1 && occupiedCard != null
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              slotBox,
              Positioned(
                right: -1,
                bottom: -1,
                child: _MarketItemCountBadge(count: slot.count),
              ),
            ],
          )
        : slotBox;

    return Expanded(
      child: Center(
        child: GestureDetector(
          key: ValueKey<String>('market-item-slot-${slot.slotLabel}'),
          behavior: HitTestBehavior.opaque,
          onTap: locked || slot.item == null || onTap == null
              ? null
              : () => onTap!(slot),
          child: _MarketSlotPulse(
            active: pulse,
            showUnlockLock: showUnlockLock,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MarketItemCountBadge extends StatelessWidget {
  const _MarketItemCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF102D25).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          'x$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MarketOfferRow extends StatelessWidget {
  const _MarketOfferRow({required this.itemCount, required this.children});

  static const double _gap = 8;
  static const int _pageSlots = 3;

  final int itemCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final pageWidth =
        _marketShopCellWidth * _pageSlots + _gap * (_pageSlots - 1);
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: pageWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(width: _gap),
            ],
          ],
        ),
      ),
    );
  }
}

String _offerEntrySignature(
  RummiMarketRuntimeFacade market,
  _MarketOfferEntry entry,
) {
  return switch (entry.kind) {
    _MarketOfferEntryKind.jester =>
      'j:${entry.jesterIndex}:${market.offers[entry.jesterIndex!].contentId}:${market.offers[entry.jesterIndex!].price}',
    _MarketOfferEntryKind.item =>
      'i:${entry.itemIndex}:${market.itemOffers[entry.itemIndex!].contentId}:${market.itemOffers[entry.itemIndex!].price}',
    _MarketOfferEntryKind.tile =>
      't:${entry.tileIndex}:${market.tileOffers[entry.tileIndex!].tile.code}:${market.tileOffers[entry.tileIndex!].price}',
  };
}

class _MarketOfferReveal extends StatefulWidget {
  const _MarketOfferReveal({
    required this.index,
    required this.signature,
    required this.child,
  });

  final int index;
  final String signature;
  final Widget child;

  @override
  State<_MarketOfferReveal> createState() => _MarketOfferRevealState();
}

class _MarketOfferRevealState extends State<_MarketOfferReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GamePresentationCues.marketOfferReveal.duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _play();
  }

  @override
  void didUpdateWidget(covariant _MarketOfferReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature) {
      _play();
    }
  }

  Future<void> _play() async {
    _controller.value = 0;
    final delay = GamePresentationCues.marketOfferReveal.delayFor(widget.index);
    await Future<void>.delayed(delay);
    if (!mounted) return;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: ValueKey<String>('market-offer-stagger-${widget.index}'),
      opacity: _fade,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

String _activeRunSummaryLabel(RummiActiveRunSaveFacade summary) {
  return summary.snapshotSummaryLabel();
}

class _GameShopOfferCard extends StatelessWidget {
  const _GameShopOfferCard({
    required this.offer,
    required this.selected,
    required this.canAfford,
    required this.onTap,
  });

  final RummiMarketOfferView offer;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _marketShopCellWidth,
        height: _marketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
              height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
              child: _MarketSelectableCardFrame(
                selected: selected,
                width: _marketOfferCardWidth,
                height: _marketOfferCardHeight,
                child: GameJesterSlot(
                  card: offer.card,
                  runtimeValueText: null,
                  extended: false,
                  activeEffect: null,
                  settlementSequenceTick: 0,
                  selected: false,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MarketOfferPriceLabel(
                price: offer.price,
                originalPrice: offer.originalPrice,
                isAffordable: canAfford,
                discountSourceLabel: offer.discountSourceLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketEmptyOfferCard extends StatelessWidget {
  const _MarketEmptyOfferCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('market-purchase-source-empty'),
      width: _marketShopCellWidth,
      height: _marketShopCellHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
            height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
            child: Center(
              child: Container(
                width: _marketOfferCardWidth,
                height: _marketOfferCardHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MarketItemOfferCard extends StatelessWidget {
  const _MarketItemOfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final RummiMarketItemOfferView offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemName = localizedItemName(context, offer);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _marketShopCellWidth,
        height: _marketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
              height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
              child: _MarketSelectableCardFrame(
                selected: selected,
                width: _marketOfferCardWidth,
                height: _marketOfferCardHeight,
                child: _MarketItemCardFace(
                  label: itemName,
                  placement: offer.item.placement,
                  rarity: offer.item.rarity,
                  selected: selected,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MarketOfferPriceLabel(
                price: offer.price,
                originalPrice: offer.originalPrice,
                isAffordable: offer.isAffordable,
                discountSourceLabel: offer.discountSourceLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketOfferPriceLabel extends StatelessWidget {
  const _MarketOfferPriceLabel({
    required this.price,
    required this.originalPrice,
    required this.isAffordable,
    this.discountSourceLabel,
  });

  final int price;
  final int originalPrice;
  final bool isAffordable;
  final String? discountSourceLabel;

  @override
  Widget build(BuildContext context) {
    final priceColor = isAffordable ? const Color(0xFFF2C14E) : Colors.white38;
    if (originalPrice <= price) {
      return Text(
        '${price}G',
        maxLines: 1,
        style: TextStyle(
          color: priceColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Text(
            '${originalPrice}G',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1.0,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Text(
            '${price}G',
            maxLines: 1,
            style: TextStyle(
              color: priceColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6F9E),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              discountSourceLabel ?? '할인',
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTileOfferCard extends StatelessWidget {
  const _MarketTileOfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final RummiMarketTileOfferView offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _marketShopCellWidth,
        height: _marketShopCellHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
              height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
              child: _MarketTileFace(tile: offer.tile, selected: selected),
            ),
            const SizedBox(height: 3),
            Text(
              offer.isFreeReward
                  ? '칩 ${offer.tile.baseChipValue} · 무료'
                  : '칩 ${offer.tile.baseChipValue} · ${offer.price}G',
              maxLines: 1,
              style: TextStyle(
                color: offer.isAffordable
                    ? const Color(0xFFF2C14E)
                    : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tileLabel(Tile tile) => '${tile.color.code}${tile.number}';

class _MarketTileFace extends StatelessWidget {
  const _MarketTileFace({required this.tile, required this.selected});

  final Tile tile;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        key: const ValueKey('market-tile-face-frame'),
        dimension: _marketOfferCardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              key: const ValueKey('market-tile-face'),
              dimension: _marketOfferCardWidth - 8,
              child: GameRummiTileCard(
                tile: tile,
                selected: false,
                accent: false,
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('market-tile-selector'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        (_marketOfferCardWidth - 8) * 0.11,
                      ),
                      border: Border.all(
                        color: const Color(0xFFF2C14E),
                        width: kJesterSelectionBorderWidth,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketItemCardFace extends StatelessWidget {
  const _MarketItemCardFace({
    required this.label,
    required this.placement,
    required this.rarity,
    required this.selected,
  });

  final String label;
  final ItemPlacement placement;
  final ItemRarity rarity;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = _itemOfferAccent(placement);
    final rarityColor = gameItemRarityColor(rarity);
    return Container(
      key: const ValueKey('market-item-card-face'),
      decoration: BoxDecoration(
        color: _itemOfferSurface(placement),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.26 : 0.12),
            blurRadius: selected ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FractionallySizedBox(
              widthFactor: 0.82,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameCardNameText(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF26352F),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
            _MarketOfferBadge(
              label: _itemSlotLabelForPlacement(placement),
              accent: accent,
              textColor: _itemOfferBadgeTextColor(placement),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketOfferBadge extends StatelessWidget {
  const _MarketOfferBadge({
    required this.label,
    required this.accent,
    required this.textColor,
  });

  final String label;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: textColor,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MarketSynergyChip extends StatelessWidget {
  const _MarketSynergyChip({required this.label, required this.dense});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 3 : 5,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2C14E).withValues(alpha: dense ? 0.18 : 0.16),
        borderRadius: BorderRadius.circular(dense ? 4 : 5),
        border: Border.all(
          color: const Color(0xFFF2C14E).withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      child: Text(
        label,
        maxLines: null,
        softWrap: true,
        style: TextStyle(
          color: const Color(0xFFFFE08A),
          fontSize: dense ? 7 : 9,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MarketSelectableCardFrame extends StatelessWidget {
  const _MarketSelectableCardFrame({
    required this.selected,
    required this.width,
    required this.height,
    required this.child,
  });

  final bool selected;
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(_marketCardSelectionInset),
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFF2C14E),
                    width: kJesterSelectionBorderWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MarketPurchaseFlightOverlay extends StatelessWidget {
  const _MarketPurchaseFlightOverlay({required this.flight});

  final _MarketPurchaseFlight flight;

  @override
  Widget build(BuildContext context) {
    final start = flight.startAlignment;
    final end = flight.endAlignment;
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          if (flight.spentGold > 0)
            Positioned(
              top: 16,
              right: 42,
              child: _MarketGoldSpendBadge(spentGold: flight.spentGold),
            ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: _marketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((_marketOfferCardWidth + _marketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((_marketOfferCardHeight +
                              _marketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              final alignment = Alignment.lerp(start, end, value)!;
              return Align(alignment: alignment, child: child);
            },
            child: _MarketPurchaseFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketGoldSpendBadge extends StatelessWidget {
  const _MarketGoldSpendBadge({required this.spentGold});

  final int spentGold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-gold-spend-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketGoldBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -16 * value),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2311).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF2C14E), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '-${spentGold}G',
            style: const TextStyle(
              color: Color(0xFFFFD568),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketGoldGainBadge extends StatelessWidget {
  const _MarketGoldGainBadge({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-gold-gain-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.marketGoldBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -16 * value),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF123829).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86F4C3), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '+${gold}G',
            style: const TextStyle(
              color: Color(0xFF9FF2C2),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSlotPulse extends StatelessWidget {
  const _MarketSlotPulse({
    required this.active,
    required this.child,
    this.showUnlockLock = false,
  });

  final bool active;
  final Widget child;
  final bool showUnlockLock;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final duration = showUnlockLock
        ? const Duration(milliseconds: 1200)
        : GamePresentationTimings.marketSlotPulse;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-slot-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        final flash = showUnlockLock ? 1.0 : (1 - value).clamp(0.0, 1.0);
        final lockFadeProgress = ((value - 0.55) / 0.45).clamp(0.0, 1.0);
        final lockOpacity = 1 - lockFadeProgress;
        return Transform.scale(
          scale: 1 + (0.10 * pulse),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(
                  0xFFF2C14E,
                ).withValues(alpha: (0.34 + 0.46 * pulse).clamp(0.0, 0.82)),
                width: 1.4 + 1.8 * pulse,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFF2C14E,
                  ).withValues(alpha: 0.42 * pulse),
                  blurRadius: 22 * pulse,
                  spreadRadius: 3 * pulse,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('market-slot-pulse-flash'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(
                          0xFFF2C14E,
                        ).withValues(alpha: 0.18 * flash),
                      ),
                    ),
                  ),
                ),
                if (showUnlockLock)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, -10 * value),
                          child: Transform.scale(
                            scale: 1 + 0.38 * value,
                            child: Opacity(
                              opacity: lockOpacity,
                              child: DecoratedBox(
                                key: const ValueKey('market-slot-unlock-lock'),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF111A26,
                                  ).withValues(alpha: 0.88),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF2C14E),
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF2C14E,
                                      ).withValues(alpha: 0.38 * flash),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.lock_open_rounded,
                                    color: Color(0xFFF2C14E),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _MarketPurchaseFlightCard extends StatelessWidget {
  const _MarketPurchaseFlightCard({required this.flight});

  final _MarketPurchaseFlight flight;

  @override
  Widget build(BuildContext context) {
    final tile = flight.tile;
    if (tile != null) {
      return SizedBox(
        key: const ValueKey('market-purchase-flight'),
        width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
        height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
        child: _MarketTileFace(tile: tile, selected: true),
      );
    }

    final face = _purchaseFlightFace();
    return SizedBox(
      key: const ValueKey('market-purchase-flight'),
      width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
      height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
      child: KeyedSubtree(
        key: const ValueKey('market-purchase-flight-frame'),
        child: _MarketSelectableCardFrame(
          selected: true,
          width: _marketOfferCardWidth,
          height: _marketOfferCardHeight,
          child: face,
        ),
      ),
    );
  }

  Widget _purchaseFlightFace() {
    final jesterCard = flight.jesterCard;
    if (!flight.item && jesterCard != null) {
      return GameJesterSlot(
        card: jesterCard,
        runtimeValueText: null,
        extended: false,
        activeEffect: null,
        settlementSequenceTick: 0,
        selected: false,
      );
    }

    final placement = flight.itemPlacement;
    final rarity = flight.itemRarity;
    if (flight.item && placement != null && rarity != null) {
      return _MarketItemCardFace(
        label: flight.label,
        placement: placement,
        rarity: rarity,
        selected: true,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7E7B8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C14E), width: 1.2),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GameCardNameText(
            flight.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF26352F),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSaleFlightOverlay extends StatelessWidget {
  const _MarketSaleFlightOverlay({required this.flight});

  final _MarketSaleFlight flight;

  @override
  Widget build(BuildContext context) {
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 42,
            child: _MarketGoldGainBadge(gold: flight.sellGold),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: _marketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((_marketOfferCardWidth + _marketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((_marketOfferCardHeight +
                              _marketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              return Align(
                alignment: Alignment.lerp(
                  const Alignment(-0.48, -0.10),
                  const Alignment(0.58, -0.84),
                  value,
                )!,
                child: child,
              );
            },
            child: _MarketSaleFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketSaleFlightCard extends StatelessWidget {
  const _MarketSaleFlightCard({required this.flight});

  final _MarketSaleFlight flight;

  @override
  Widget build(BuildContext context) {
    final jesterCard = flight.jesterCard;
    if (!flight.item && jesterCard != null) {
      return SizedBox(
        key: const ValueKey('market-sale-flight'),
        width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
        height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
        child: KeyedSubtree(
          key: const ValueKey('market-sale-flight-jester-card'),
          child: _MarketSelectableCardFrame(
            selected: true,
            width: _marketOfferCardWidth,
            height: _marketOfferCardHeight,
            child: GameJesterSlot(
              card: jesterCard,
              runtimeValueText: null,
              extended: false,
              activeEffect: null,
              settlementSequenceTick: 0,
              selected: false,
            ),
          ),
        ),
      );
    }
    final placement = flight.itemPlacement;
    final rarity = flight.itemRarity;
    if (placement == null || rarity == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      key: const ValueKey('market-sale-flight'),
      width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
      height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: true,
        width: _marketOfferCardWidth,
        height: _marketOfferCardHeight,
        child: _MarketItemCardFace(
          label: flight.label,
          placement: placement,
          rarity: rarity,
          selected: true,
        ),
      ),
    );
  }
}

class _MarketItemUseFlightOverlay extends StatelessWidget {
  const _MarketItemUseFlightOverlay({required this.flight});

  final _MarketItemUseFlight flight;

  @override
  Widget build(BuildContext context) {
    final startOffset = flight.startOffset;
    final endOffset = flight.endOffset;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 42,
            child: _MarketGoldGainBadge(gold: flight.goldGain),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: _marketPurchaseFlightDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              if (startOffset != null && endOffset != null) {
                final offset = Offset.lerp(startOffset, endOffset, value)!;
                return Positioned(
                  left:
                      offset.dx -
                      ((_marketOfferCardWidth + _marketCardSelectionInset * 2) /
                          2),
                  top:
                      offset.dy -
                      ((_marketOfferCardHeight +
                              _marketCardSelectionInset * 2) /
                          2),
                  child: child!,
                );
              }
              return Align(
                alignment: Alignment.lerp(
                  const Alignment(-0.48, -0.10),
                  const Alignment(0.58, -0.84),
                  value,
                )!,
                child: child,
              );
            },
            child: _MarketItemUseFlightCard(flight: flight),
          ),
        ],
      ),
    );
  }
}

class _MarketItemUseFlightCard extends StatelessWidget {
  const _MarketItemUseFlightCard({required this.flight});

  final _MarketItemUseFlight flight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('market-item-use-flight'),
      width: _marketOfferCardWidth + (_marketCardSelectionInset * 2),
      height: _marketOfferCardHeight + (_marketCardSelectionInset * 2),
      child: _MarketSelectableCardFrame(
        selected: true,
        width: _marketOfferCardWidth,
        height: _marketOfferCardHeight,
        child: _MarketItemCardFace(
          label: flight.label,
          placement: flight.itemPlacement,
          rarity: flight.itemRarity,
          selected: true,
        ),
      ),
    );
  }
}

class _MarketGoldChip extends StatelessWidget {
  const _MarketGoldChip({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 48,
      child: GameHudChip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GOLD',
              style: gameHudLabelStyle,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Gold',
                    value: '$gold',
                    child: ExcludeSemantics(
                      child: Image.asset(
                        AssetPaths.uiGreed,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const _MarketGoldFallbackIcon(size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$gold',
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      style: gameHudValueStyle.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketGoldFallbackIcon extends StatelessWidget {
  const _MarketGoldFallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF2C14E),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          color: Color(0xFF174131),
          height: 1,
        ),
      ),
    );
  }
}

class _MarketSlotUnlockBanner extends StatelessWidget {
  const _MarketSlotUnlockBanner({required this.unlocks});

  final Set<RummiSlotUnlockKind> unlocks;

  @override
  Widget build(BuildContext context) {
    final labels = unlocks
        .map((kind) => _slotUnlockLabel(context, kind))
        .join(' · ');
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-slot-unlock-banner'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -12 * (1 - value)),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111A26).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF2C14E), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2C14E).withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFFF2C14E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  labels,
                  key: const ValueKey('market-slot-unlock-label'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _slotUnlockLabel(BuildContext context, RummiSlotUnlockKind kind) {
    return switch (kind) {
      RummiSlotUnlockKind.jester => context.tr('marketSlotUnlockJester'),
      RummiSlotUnlockKind.quickSlot => context.tr('marketSlotUnlockQuickItem'),
      RummiSlotUnlockKind.passiveRelic => context.tr('marketSlotUnlockPassive'),
    };
  }
}

String localizedItemName(BuildContext context, RummiMarketItemOfferView offer) {
  return ItemTranslationScope.of(
    context,
  ).resolveDisplayName(offer.contentId, offer.displayName);
}

String localizedItemEffect(
  BuildContext context,
  RummiMarketItemOfferView offer,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveEffectText(offer.contentId, offer.effectText);
}

String localizedItemSlotName(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveDisplayName(slot.contentId ?? '', slot.displayName ?? '');
}

String localizedItemSlotEffect(
  BuildContext context,
  RummiMarketItemSlotView slot,
) {
  return ItemTranslationScope.of(
    context,
  ).resolveEffectText(slot.contentId ?? '', slot.effectText ?? '');
}

String _ownedItemSlotSubtitle(RummiMarketItemSlotView slot) {
  return switch (slot.placement) {
    ItemPlacement.quickSlot => 'Q-Slot 보유',
    ItemPlacement.passiveRack => 'Passive 보유',
    ItemPlacement.inventory => 'Tool 보유',
    ItemPlacement.equipped => 'Gear 보유',
  };
}

String? _ownedItemSlotNotice(RummiMarketItemSlotView slot) {
  final item = slot.item;
  if (item == null) return null;
  return switch (item.effect.timing) {
    'use_market' || 'use_market_if_gold_lte' => '상점에서 수동 사용',
    'market_buy' => '다음 구매 시 자동 적용',
    'market_buy_if_category' => switch (item.effect.value('category')) {
      'jester' => '다음 Jester 구매 시 자동 적용',
      'item' => '다음 Item 구매 시 자동 적용',
      _ => '다음 구매 시 자동 적용',
    },
    'market_reroll' => '리롤 버튼 사용 시 자동 적용',
    'enter_market' => '다음 Market 진입 시 자동 적용',
    _ =>
      slot.placement == ItemPlacement.equipped ||
              slot.placement == ItemPlacement.passiveRack
          ? '조건 충족 시 자동 발동'
          : null,
  };
}

String _itemSlotLabelForPlacement(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-SLT',
    ItemPlacement.passiveRack => 'PSV',
    ItemPlacement.equipped => 'GEAR',
    ItemPlacement.inventory => 'TOOL',
  };
}

List<String> _jesterSynergyTags(RummiJesterCard card) {
  final tags = <String>[
    _jesterRarityTag(card.rarity),
    jesterCategoryLabel(card),
    _jesterConditionTag(card),
    _jesterEffectTag(card),
  ].where((tag) => tag.isNotEmpty).toList(growable: false);

  if (tags.isNotEmpty) return tags;
  return const ['Jester'];
}

String _jesterRarityTag(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.common => 'Common',
    RummiJesterRarity.uncommon => 'Uncommon',
    RummiJesterRarity.rare => 'Rare',
    RummiJesterRarity.legendary => 'Legendary',
  };
}

String _jesterConditionTag(RummiJesterCard card) {
  if (card.id == 'scholar') return 'Ace';
  if (card.id == 'supernova') return '반복 족보';
  if (card.id == 'popcorn' || card.id == 'ice_cream') return '줄어듦';
  if (card.id == 'green_jester' || card.id == 'ride_the_bus') return '성장형';

  return switch (card.conditionType) {
    'none' => '상시',
    'pair' => 'Pair',
    'two_pair' => 'Two Pair',
    'three_of_a_kind' => 'Triple',
    'straight' => 'Run',
    'flush' => 'Color',
    'tile_color_scored' => card.mappedTileColors.isEmpty ? '색상' : '색상 타일',
    'rank_scored' => '숫자 타일',
    'face_card' => 'Face',
    'other' => _otherJesterConditionTag(card.conditionValue),
    _ => '',
  };
}

String _otherJesterConditionTag(Object? value) {
  return switch (value) {
    'empty_jester_slots' => '빈 슬롯',
    'unused_discards' => '미사용 버림',
    'held_hand_size' => '손패',
    _ => '조건부',
  };
}

String _jesterEffectTag(RummiJesterCard card) {
  if (card.id == 'scholar') return '+칩/+점수%';
  if (card.id == 'ice_cream') return '+칩';
  if (card.effectType == 'stateful_growth') return '+점수%';

  return switch (card.effectType) {
    'chips_bonus' => '+칩',
    'mult_bonus' => '+점수%',
    'xmult_bonus' => '점수 x',
    'economy' => '+Gold',
    'rule_modifier' => 'Rule',
    _ => '',
  };
}

List<String> _itemSynergyTags(ItemDefinition item) {
  final tags = <String>[
    _itemRarityTag(item.rarity),
    _itemTimingTag(item.effect.timing),
    _itemEffectTag(item.effect.op),
  ].where((tag) => tag.isNotEmpty).toList();

  for (final tag in item.tags) {
    if (tags.length >= 4) break;
    final label = _catalogItemTagLabel(tag);
    if (label.isNotEmpty &&
        !_itemTypeTagLabels.contains(label) &&
        !tags.contains(label)) {
      tags.add(label);
    }
  }

  if (tags.isNotEmpty) return tags;
  return [_itemPlacementTag(item.placement)];
}

const Set<String> _itemTypeTagLabels = {'Q-Slot', 'Tool', 'Gear', 'Relic'};

String _itemRarityTag(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => 'Common',
    ItemRarity.uncommon => 'Uncommon',
    ItemRarity.rare => 'Rare',
    ItemRarity.legendary => 'Legendary',
  };
}

String _itemTimingTag(String timing) {
  return switch (timing) {
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' => '다음 확정',
    'first_confirm_each_station' => '첫 확정',
    'second_confirm_each_station' => '두번째 확정',
    'first_scored_tile_each_station' => '첫 타일',
    'use_battle' => '전투 사용',
    'use_market' || 'use_market_if_gold_lte' => '상점 사용',
    'market_buy' || 'market_buy_if_category' => '구매 연계',
    'market_reroll' => '리롤',
    'enter_market' || 'market_build_offers' => 'Market',
    'station_start' => 'Station 시작',
    'settlement' => '정산',
    'boss_blind_clear_reward' || 'boss_blind_clear_market' => 'Boss 보상',
    'inventory_capacity' => '슬롯',
    'expiry_guard' => '보호',
    'sell_jester' => '판매',
    _ => '',
  };
}

String _itemEffectTag(String op) {
  return switch (op) {
    'chips_bonus' => '+칩',
    'mult_bonus' => '+점수%',
    'xmult_bonus' => '점수 x',
    'temporary_overlap_cap_bonus' => 'Overlap',
    'gain_gold' ||
    'add_hand_rank_progress' ||
    'board_discard_reward_bonus' ||
    'hand_discard_reward_bonus' =>
      op == 'add_hand_rank_progress' ? '족보 성장' : '+Gold',
    'discount_next_purchase' ||
    'free_next_reroll' ||
    'discount_first_reroll' => 'Discount',
    'add_board_discard' || 'add_hand_discard' => '+Discard',
    'extra_item_offer_slot' || 'extra_jester_offer_next_market' => 'Offer',
    'sell_price_bonus' => '판매 보너스',
    'rescue_first_expiry_each_station' => 'Rescue',
    'add_percent_of_first_confirm_score' => 'Echo',
    'draw_if_hand_empty' => 'Draw',
    'reroll_item_offers_only' => 'Item Reroll',
    'peek_deck_discard_one' => 'Deck',
    _ => '',
  };
}

String _catalogItemTagLabel(String tag) {
  return switch (tag) {
    'market' => 'Market',
    'economy' || 'gold' => '+Gold',
    'discount' => 'Discount',
    'battle' => '전투',
    'score' => 'Score',
    'chips' => '+칩',
    'mult' => '+점수%',
    'xmult' => '점수 x',
    'rank' => '족보',
    'rank_growth' || 'planet_like' => '족보 성장',
    'straight' => 'Run',
    'flush' => 'Color',
    'two_pair' => 'Two Pair',
    'overlap' => 'Overlap',
    'discard' => 'Discard',
    'draw' => 'Draw',
    'safety' => 'Safety',
    'equipment' => 'Gear',
    'station_start' => 'Station',
    'offer' => 'Offer',
    'jester' || 'tactic' => 'Jester',
    'relic' => 'Relic',
    'boss' => 'Boss',
    'capacity' => 'Slot',
    'consumable' => 'Q-Slot',
    'rarity' => 'Rarity',
    'echo' => 'Echo',
    'utility' => 'Tool',
    'item' => 'Item',
    'comeback' => 'Comeback',
    'reroll' => 'Reroll',
    'tile_color' => '색상',
    'deck' => 'Deck',
    'selection' => '선택',
    'small_hand' => '작은 손패',
    'legendary' => 'Legendary',
    _ => '',
  };
}

String _itemPlacementTag(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-Slot',
    ItemPlacement.passiveRack => 'Relic',
    ItemPlacement.equipped => 'Gear',
    ItemPlacement.inventory => 'Tool',
  };
}

Color _itemOfferSurface(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFFC7D8FF),
    ItemPlacement.passiveRack => const Color(0xFFC9EDB1),
    ItemPlacement.equipped => const Color(0xFFF4C77F),
    ItemPlacement.inventory => const Color(0xFFC3F0EF),
  };
}

Color _itemOfferAccent(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFF4F82FF),
    ItemPlacement.passiveRack => const Color(0xFF54B85C),
    ItemPlacement.equipped => const Color(0xFFD88918),
    ItemPlacement.inventory => const Color(0xFF24B8C6),
  };
}

Color _itemOfferBadgeTextColor(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.equipped => const Color(0xFF1F1203),
    _ => const Color(0xFF07111F),
  };
}
