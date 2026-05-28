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
import '../../../resources/card_emblem_assets.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/tutorial_state_service.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/phone_frame_scaffold.dart';
import '../game_presentation_timings.dart';
import 'game_card_name_text.dart';
import 'game_jester_widgets.dart';
import 'game_market_feedback_widgets.dart';
import 'game_market_metrics.dart';
import 'game_run_info_dialog.dart';
import 'game_shared_widgets.dart';
import 'game_surface_metrics.dart';
import 'game_tutorial_overlay.dart';
import 'game_ui_palette.dart';

part 'game_shop_screen_models.dart';
part 'game_shop_detail_widgets.dart';
part 'game_shop_offer_widgets.dart';
part 'game_shop_shell_widgets.dart';
part 'game_shop_text_helpers.dart';

enum _MarketOptionsCloseAction {
  resumeGame,
  keepPaused,
  openSettings,
  openRunInfo,
  openMarketTutorial,
}

const TextStyle _marketDescriptionTextStyle = TextStyle(
  color: GameUiPalette.textSecondary,
  fontSize: kMarketDescriptionFontSize,
  fontWeight: FontWeight.w700,
  height: kMarketDescriptionLineHeight,
);

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
      await Future<void>.delayed(kMarketSlotUnlockBannerDelay);
      if (!mounted) return;
      await widget.onSlotUnlockPresentationShown?.call();
      await Future<void>.delayed(kMarketSlotUnlockBannerVisible);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialItemShopTab) {
      _shopTab = _MarketShopTab.toolsAndGear;
      _utilityOfferLane = _MarketOfferLane.tool;
      _clearMarketSelection();
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
    setState(() {
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
    setState(() {
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
    setState(() {
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
    setState(() {
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
    setState(() {
      _shopTab = tab;
      _clearMarketSelection();
    });
  }

  void _selectOfferLane(_MarketOfferLane lane) {
    setState(() {
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
    final hadCurrentLaneOfferSelection = switch (lane) {
      _MarketOfferLane.jester => _selectedOfferIndex != null,
      _MarketOfferLane.tile => _selectedTileOfferIndex >= 0,
      _ => _selectedItemOfferIndex >= 0,
    };
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
                color: GameUiPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _rerollConfirmMessage(laneLabel, rerollCost),
              style: const TextStyle(
                color: GameUiPalette.textSecondary,
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
                    background: GameUiPalette.disabledControl,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameActionButton(
                    label: _rerollConfirmActionLabel(rerollCost),
                    background: GameUiPalette.actionGold,
                    foreground: GameUiPalette.ink,
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
      _clearMarketSelection();
      if (hadCurrentLaneOfferSelection) {
        _selectFirstEntry(_offerEntriesForLane(market, lane));
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
          itemId: boughtOffer.item.id,
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
    String? itemId,
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
      itemId: itemId,
      itemPlacement: itemPlacement,
      itemRarity: itemRarity,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
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
      itemId: item.id,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
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
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
      if (!mounted || _saleFlight?.tick != tick) return;
      setState(() => _saleFlight = null);
    });
  }

  void _startMarketItemUseFlight({
    required RummiMarketItemSlotView slot,
    required ItemDefinition item,
    required int? goldGain,
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
      itemId: item.id,
    );
    Future<void>.delayed(kMarketPurchaseFlightDuration, () {
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
    final failMessage = widget.onUseMarketItem(item);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    final feedbackTick = _marketUseFeedbackTick + 1;
    final goldGain = _marketUseGoldGain(item);
    final effectPresentation = _marketUsePresentation(slot, item);
    final endOffset = goldGain == null
        ? null
        : _flightCenterForKey(_goldChipKey);
    setState(() {
      if (item.effect.op == 'reroll_item_offers_only') {
        _pinnedItemOffers = null;
      }
      _marketUseFeedbackTick = feedbackTick;
      _marketUseFeedbackLabel = '사용 완료';
      _marketUseFeedbackDelta = _marketUseFeedbackDeltaLabel(item);
      _startMarketItemUseFlight(
        slot: slot,
        item: item,
        goldGain: goldGain,
        startOffset: startOffset,
        endOffset: endOffset,
      );
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
      buttonColor: GameUiPalette.actionDanger,
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
                        color: GameUiPalette.textPrimary,
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
                              color: GameUiPalette.textPrimary.withValues(
                                alpha: 0.92,
                              ),
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
                          backgroundColor: GameUiPalette.iconButtonMuted,
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
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.92,
                          ),
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
                accentColor: GameUiPalette.actionGoldBright,
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
                accentColor: GameUiPalette.menuAccentTutorial,
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
                accentColor: GameUiPalette.menuAccentSettings,
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
                accentColor: GameUiPalette.menuAccentRestart,
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
                accentColor: GameUiPalette.menuAccentExit,
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
                                            height: kMarketOwnedCardHeight + 6,
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
                                                              slotIndex: index,
                                                            ),
                                                      extended: index == 4,
                                                      activeEffect: null,
                                                      settlementSequenceTick: 0,
                                                      selected: false,
                                                      locked: false,
                                                    ),
                                                  );

                                                  return SizedBox(
                                                    key: _jesterSlotKey(index),
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
                                            priceLabel:
                                                '${selectedOffer.price}',
                                            buttonLabel: '구매',
                                            buttonColor:
                                                GameUiPalette.actionGold,
                                            foreground: GameUiPalette.ink,
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
                                            buttonColor:
                                                GameUiPalette.actionGold,
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
                                            buttonColor:
                                                GameUiPalette.actionGold,
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
                                              rerollCost: currentRerollCost,
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
                              background: GameUiPalette.disabledControl,
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
