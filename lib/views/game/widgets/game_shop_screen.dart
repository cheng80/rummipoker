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
      final market = _market;
      _mutate(() => _syncCurrentLaneToAvailableOffers(market));
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
  Widget build(BuildContext context) => _buildMarketScreen(context);
}
