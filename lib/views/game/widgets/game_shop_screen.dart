import '../../../utils/action_failure_translation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/hand_rank.dart';
import '../../../logic/rummi_poker_grid/rummi_settlement_facade.dart';
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
import '../../../utils/item_presentation_translation.dart';
import '../../../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../../../utils/app_translation.dart';
import '../../../widgets/semantic_text.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../../../widgets/fx/juice.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../../../widgets/fx/spring_follow.dart';
import '../../../widgets/phone_frame_scaffold.dart';
import '../game_presentation_timings.dart';
import '../game_feedback_cues.dart';
import 'game_card_name_text.dart';
import 'game_jester_widgets.dart';
import 'game_market_feedback_widgets.dart';
import 'game_market_metrics.dart';
import 'game_run_info_dialog.dart';
import 'game_shared_widgets.dart';
import 'game_surface_metrics.dart';
import 'game_tutorial_overlay.dart';
import 'game_ui_palette.dart';
import '../../../utils/active_run_translation.dart';

part 'game_shop_screen_models.dart';
part 'game_shop_detail_widgets.dart';
part 'game_shop_offer_widgets.dart';
part 'game_shop_card_face_widgets.dart';
part 'game_shop_flight_widgets.dart';
part 'game_shop_shell_widgets.dart';
part 'game_shop_feedback_widgets.dart';
part 'game_shop_section_widgets.dart';
part 'game_shop_control_widgets.dart';
part 'game_shop_slot_face_widgets.dart';
part 'game_shop_build_flow.dart';
part 'game_shop_text_helpers.dart';
part 'game_shop_setup_flow.dart';
part 'game_shop_selection_flow.dart';
part 'game_shop_purchase_flow.dart';
part 'game_shop_item_action_flow.dart';
part 'game_shop_options_flow.dart';

class GameShopScreen extends StatefulWidget {
  const GameShopScreen({
    super.key,
    required this.runSeed,
    required this.readMarketView,
    required this.onReroll,
    this.onRerollFailure,
    this.onRerollItemOffers,
    this.onRerollItemOffersFailure,
    this.onRerollTileOffers,
    this.onRerollTileOffersFailure,
    required this.onBuyOffer,
    this.onBuyOfferFailure,
    required this.onBuyItemOffer,
    this.onBuyItemOfferFailure,
    required this.onBuyTileOffer,
    this.onBuyTileOfferFailure,
    this.isFirstAcquisition,
    required this.onUseMarketItem,
    this.onUseMarketItemFailure,
    required this.onSellOwnedJester,
    required this.onSellMarketItem,
    this.autoStartTutorials = true,
    this.onSlotUnlockPresentationShown,
    required this.onStateChanged,
    required this.onOpenSettings,
    required this.onExitToTitle,
    this.onBookmarkRun,
    this.onLoadBookmarkRun,
    required this.onRestartRun,
    required this.isDebugFixtureRun,
    this.readActiveRunSaveView,
    this.initialItemShopTab = false,
    this.autoAdvanceOnLoad = false,
    this.initialItemPresentationEvents = const [],
    this.onItemPresentationEventsShown,
  });

  final int runSeed;
  final RummiMarketRuntimeFacade Function() readMarketView;
  final String? Function() onReroll;
  final ActionFailure? Function()? onRerollFailure;
  final String? Function(ItemPlacement placement)? onRerollItemOffers;
  final ActionFailure? Function(ItemPlacement placement)?
  onRerollItemOffersFailure;
  final String? Function()? onRerollTileOffers;
  final ActionFailure? Function()? onRerollTileOffersFailure;
  final String? Function(RummiMarketOfferView offer) onBuyOffer;
  final ActionFailure? Function(RummiMarketOfferView offer)? onBuyOfferFailure;
  final String? Function(RummiMarketItemOfferView offer) onBuyItemOffer;
  final ActionFailure? Function(RummiMarketItemOfferView offer)?
  onBuyItemOfferFailure;
  final String? Function(int offerIndex) onBuyTileOffer;
  final ActionFailure? Function(int offerIndex)? onBuyTileOfferFailure;
  final bool Function(String category, String contentId)? isFirstAcquisition;
  final String? Function(ItemDefinition item) onUseMarketItem;
  final ActionFailure? Function(ItemDefinition item)? onUseMarketItemFailure;
  final bool Function(int ownedIndex) onSellOwnedJester;
  final bool Function(ItemDefinition item) onSellMarketItem;
  final bool autoStartTutorials;
  final Future<void> Function()? onSlotUnlockPresentationShown;
  final Future<void> Function() onStateChanged;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onExitToTitle;
  final Future<bool> Function()? onBookmarkRun;
  final Future<bool> Function()? onLoadBookmarkRun;
  final Future<void> Function() onRestartRun;
  final bool isDebugFixtureRun;
  final RummiActiveRunSaveFacade? Function()? readActiveRunSaveView;
  final bool initialItemShopTab;
  final bool autoAdvanceOnLoad;
  final List<ItemPresentationEvent> initialItemPresentationEvents;
  final VoidCallback? onItemPresentationEventsShown;

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
  bool _marketTutorialAlreadySeenLogged = false;
  int _marketTutorialFocusIndex = 0;
  TutorialCoachMark? _marketTutorialCoachMark;
  int _marketDenyTick = 0;
  String? _marketDenyTarget;
  String? _marketDenyReason;
  String Function(BuildContext)? _marketDenyReasonBuilder;
  int _marketUseFeedbackTick = 0;
  String? _marketUseFeedbackLabel;
  ItemDefinition? _marketUseFeedbackItem;
  String? _marketUseFeedbackDelta;
  int _marketRerollFeedbackTick = 0;
  // Tutorial targets change with the tab; preserve the outgoing offer row.
  final _marketOfferSwitcherKey = GlobalKey();
  int _marketTransitionDirection = 1;
  List<RummiMarketItemOfferView>? _pinnedItemOffers;
  bool _pendingLifecycleOptions = false;
  bool _optionsDialogOpen = false;
  Timer? _inactiveLifecycleTimer;
  bool _slotUnlockPresentationScheduled = false;
  bool _slotUnlockBannerVisible = false;
  Set<RummiSlotUnlockKind> _activeSlotUnlockPresentation =
      <RummiSlotUnlockKind>{};
  int _newRevealTick = 0;
  String? _newRevealLabel;
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
      final market = _market;
      _mutate(() => _syncCurrentLaneToAvailableOffers(market));
      GameFeedback.play(GameCue.marketEntry);
      if (widget.initialItemPresentationEvents.isNotEmpty) {
        widget.onItemPresentationEventsShown?.call();
        _startEffectPresentationSummary(
          widget.initialItemPresentationEvents,
          title: context.translate('marketEntryItemsTriggered'),
        );
      }
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
    _inactiveLifecycleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _dismissMarketTutorial();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        if (!_optionsDialogOpen) {
          _pendingLifecycleOptions = true;
        }
        _dismissMarketTutorial();
        SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
        _queueStateSave();
        break;
      case AppLifecycleState.inactive:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = Timer(
          GamePresentationTimings.inactiveLifecycleDebounce,
          () {
            if (!mounted) return;
            if (!_optionsDialogOpen) {
              _pendingLifecycleOptions = true;
            }
            _dismissMarketTutorial();
            SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
            _queueStateSave();
          },
        );
        break;
      case AppLifecycleState.resumed:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
        if (_pendingLifecycleOptions) {
          _pendingLifecycleOptions = false;
          unawaited(_openLifecycleOptionsAfterResume());
        }
        break;
      case AppLifecycleState.detached:
        _inactiveLifecycleTimer?.cancel();
        _inactiveLifecycleTimer = null;
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
  Widget build(BuildContext context) => _buildMarketScreen(context);
}
