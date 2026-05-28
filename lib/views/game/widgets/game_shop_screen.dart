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
part 'game_shop_setup_flow.dart';
part 'game_shop_selection_flow.dart';
part 'game_shop_purchase_flow.dart';
part 'game_shop_item_action_flow.dart';
part 'game_shop_options_flow.dart';

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

  void _mutate(VoidCallback fn) {
    setState(fn);
  }

  RummiMarketRuntimeFacade get _market {
    final market = widget.readMarketView();
    final pinnedOffers = _pinnedItemOffers;
    if (pinnedOffers == null) return market;
    return market.withItemOffers(
      _repricePinnedItemOffers(pinnedOffers, market),
    );
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
