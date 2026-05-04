import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/jester_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/phone_frame_scaffold.dart';
import 'game_jester_widgets.dart';
import 'game_shared_widgets.dart';

const double _marketOwnedCardWidth = kBattleItemSlotWidth;
const double _marketOwnedCardHeight = kBattleItemSlotHeight;
const double _marketOfferCardWidth = kBattleItemSlotWidth;
const double _marketOfferCardHeight = kBattleItemSlotHeight;
const double _marketCardSelectionInset = kJesterSelectionOutset;
const double _marketShopCellWidth = 72.0;
const double _marketShopCellHeight =
    kBattleItemSlotHeight + (kJesterSelectionOutset * 2) + 16.0;
const double _marketShopPanelHeight = 156.0;
const double _marketSpeechPanelHeight = 144.0;
const double _marketDescriptionFontSize = 12.0;
const double _marketDescriptionLineHeight = 1.18;
const double _marketDescriptionMinHeight =
    _marketDescriptionFontSize * _marketDescriptionLineHeight * 2;

enum _MarketOptionsCloseAction { resumeGame, keepPaused, openSettings }

const TextStyle _marketDescriptionTextStyle = TextStyle(
  color: Colors.white70,
  fontSize: _marketDescriptionFontSize,
  fontWeight: FontWeight.w700,
  height: _marketDescriptionLineHeight,
);

enum _MarketShopTab { cardsAndQuickSlots, toolsAndGear }

enum _MarketOfferEntryKind { jester, item }

class _MarketOfferEntry {
  const _MarketOfferEntry.jester(this.jesterIndex)
    : kind = _MarketOfferEntryKind.jester,
      itemIndex = null;

  const _MarketOfferEntry.item(this.itemIndex)
    : kind = _MarketOfferEntryKind.item,
      jesterIndex = null;

  final _MarketOfferEntryKind kind;
  final int? jesterIndex;
  final int? itemIndex;
}

class _MarketPurchaseFlight {
  const _MarketPurchaseFlight({
    required this.tick,
    required this.label,
    required this.slotLabel,
    required this.item,
    required this.spentGold,
  });

  final int tick;
  final String label;
  final String slotLabel;
  final bool item;
  final int spentGold;
}

class GameShopScreen extends StatefulWidget {
  const GameShopScreen({
    super.key,
    required this.runSeed,
    required this.readMarketView,
    required this.onReroll,
    required this.onBuyOffer,
    required this.onBuyItemOffer,
    required this.onUseMarketItem,
    required this.onSellOwnedJester,
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
  final String? Function(int offerIndex) onBuyOffer;
  final String? Function(RummiMarketItemOfferView offer) onBuyItemOffer;
  final String? Function(ItemDefinition item) onUseMarketItem;
  final bool Function(int ownedIndex) onSellOwnedJester;
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
  int _selectedItemOfferIndex = -1;
  int _selectedItemSlotIndex = -1;
  int _mainOfferPage = 0;
  int _utilityOfferPage = 0;
  int _purchaseFlightTick = 0;
  _MarketPurchaseFlight? _purchaseFlight;
  int _marketDenyTick = 0;
  String? _marketDenyTarget;
  String? _marketDenyReason;
  int _marketUseFeedbackTick = 0;
  String? _marketUseFeedbackLabel;
  bool _pendingLifecycleOptions = false;
  bool _optionsDialogOpen = false;

  RummiMarketRuntimeFacade get _market => widget.readMarketView();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_market.ownedEntries.isNotEmpty) {
      _selectedOwnedIndex = 0;
    } else if (_market.offers.isNotEmpty) {
      _selectedOfferIndex = 0;
    }
    if (widget.initialItemShopTab) {
      final utilityEntries = _offerEntriesForTab(
        _market,
        _MarketShopTab.toolsAndGear,
      );
      _shopTab = _MarketShopTab.toolsAndGear;
      _selectedItemOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      for (final entry in utilityEntries) {
        if (entry.kind == _MarketOfferEntryKind.item) {
          _selectedItemOfferIndex = entry.itemIndex ?? -1;
          break;
        }
      }
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    }
    if (widget.autoAdvanceOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
        if (!_optionsDialogOpen) {
          _pendingLifecycleOptions = true;
        }
        unawaited(widget.onStateChanged());
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

  void _selectOwned(int index) {
    setState(() {
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
      _selectedItemOfferIndex = -1;
      _selectedItemSlotIndex = -1;
    });
  }

  void _selectOffer(int index) {
    setState(() {
      _shopTab = _MarketShopTab.cardsAndQuickSlots;
      _selectedOfferIndex = index;
      _selectedItemOfferIndex = -1;
      _selectedItemSlotIndex = -1;
      _selectedOwnedIndex = null;
    });
  }

  void _selectItemOffer(int index) {
    setState(() {
      _selectedItemOfferIndex = index;
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
      _selectedItemSlotIndex = slot.slotIndex;
      _selectedItemOfferIndex = -1;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectShopTab(_MarketShopTab tab) {
    setState(() {
      _shopTab = tab;
      _selectedOwnedIndex = null;
      final entries = _offerEntriesForTab(_market, tab);
      _selectFirstEntry(entries);
    });
  }

  void _shiftMainOfferPage(int delta) {
    final pageCount = _pageCount(
      _offerEntriesForTab(_market, _MarketShopTab.cardsAndQuickSlots).length,
    );
    if (pageCount <= 1) return;
    setState(() {
      _mainOfferPage = (_mainOfferPage + delta).clamp(0, pageCount - 1);
    });
  }

  void _shiftUtilityOfferPage(int delta) {
    final pageCount = _pageCount(
      _offerEntriesForTab(_market, _MarketShopTab.toolsAndGear).length,
    );
    if (pageCount <= 1) return;
    setState(() {
      _utilityOfferPage = (_utilityOfferPage + delta).clamp(0, pageCount - 1);
    });
  }

  List<_MarketOfferEntry> _offerEntriesForTab(
    RummiMarketRuntimeFacade market,
    _MarketShopTab tab,
  ) {
    final entries = <_MarketOfferEntry>[];
    if (tab == _MarketShopTab.cardsAndQuickSlots) {
      for (var i = 0; i < market.offers.length; i++) {
        entries.add(_MarketOfferEntry.jester(i));
      }
    }
    for (var i = 0; i < market.itemOffers.length; i++) {
      final placement = market.itemOffers[i].item.placement;
      final belongsToMain =
          placement == ItemPlacement.quickSlot ||
          placement == ItemPlacement.passiveRack;
      if ((tab == _MarketShopTab.cardsAndQuickSlots && belongsToMain) ||
          (tab == _MarketShopTab.toolsAndGear && !belongsToMain)) {
        entries.add(_MarketOfferEntry.item(i));
      }
    }
    return entries;
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
    _selectedItemSlotIndex = -1;
    if (entries.isEmpty) return;
    final entry = entries.first;
    switch (entry.kind) {
      case _MarketOfferEntryKind.jester:
        _selectedOfferIndex = entry.jesterIndex;
      case _MarketOfferEntryKind.item:
        _selectedItemOfferIndex = entry.itemIndex ?? -1;
    }
  }

  int _pageCount(int total) => total == 0 ? 1 : ((total - 1) ~/ 3) + 1;

  List<T> _pagedItems<T>(List<T> items, int page) {
    final start = (page * 3).clamp(0, items.length);
    final end = (start + 3).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Future<void> _showOwnedJesterDetail(int index) async {
    if (index < 0 || index >= _market.ownedEntries.length) return;
    final ownedEntry = _market.ownedEntries[index];
    final card = ownedEntry.card;
    final notes = JesterTranslationScope.of(context).notes(card.id);
    final sellGold = ownedEntry.sellPrice;
    final runtimeValueText = jesterRuntimeValueText(
      card,
      _market.runtimeSnapshot,
      slotIndex: index,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102D25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedJesterName(context, card),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 92,
                          child: GameJesterSlot(
                            card: card,
                            runtimeValueText: runtimeValueText,
                            extended: false,
                            activeEffect: null,
                            settlementSequenceTick: 0,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizedJesterEffect(context, card),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              if (runtimeValueText != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    runtimeValueText,
                                    style: const TextStyle(
                                      color: Color(0xFFF4E6B1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              if (notes != null && notes.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GameActionButton(
                        label: '판매 +$sellGold Gold',
                        background: const Color(0xFFB74B3B),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _sellOwned(index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reroll() async {
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
            const Text(
              '정말 리롤할까요?',
              style: TextStyle(
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
                    label: '리롤',
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

    final failMessage = widget.onReroll();
    if (failMessage != null) {
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      _selectedOwnedIndex ??= market.ownedEntries.isEmpty ? null : 0;
    });
    await widget.onStateChanged();
  }

  void _buySelected() {
    final index = _selectedOfferIndex;
    if (index == null) return;
    final offers = _market.offers;
    if (index < 0 || index >= offers.length) return;
    final boughtOffer = offers[index];
    final failMessage = widget.onBuyOffer(index);
    if (failMessage != null) {
      _startMarketDenyFeedback('jester-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      final purchasedSlot = _findPurchasedJesterSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        _shopTab = _MarketShopTab.cardsAndQuickSlots;
        _selectedOwnedIndex = purchasedSlot.slotIndex;
        _selectedOfferIndex = null;
        _selectedItemOfferIndex = -1;
        _selectedItemSlotIndex = -1;
        _startPurchaseFlight(
          label: boughtOffer.displayName,
          slotLabel: 'J${purchasedSlot.slotIndex + 1}',
          item: false,
          spentGold: boughtOffer.price,
        );
      } else if (market.ownedEntries.isNotEmpty) {
        _selectedOwnedIndex = market.ownedEntries.length - 1;
        _selectedOfferIndex = null;
      } else {
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      }
    });
    widget.onStateChanged();
  }

  void _buySelectedItem() {
    final offers = _market.itemOffers;
    final index = _selectedItemOfferIndex;
    if (index < 0 || index >= offers.length) return;
    final boughtOffer = offers[index];
    final failMessage = widget.onBuyItemOffer(boughtOffer);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-buy', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      final purchasedSlot = _findPurchasedItemSlot(market, boughtOffer);
      if (purchasedSlot != null) {
        _shopTab = switch (purchasedSlot.placement) {
          ItemPlacement.quickSlot ||
          ItemPlacement.passiveRack => _MarketShopTab.cardsAndQuickSlots,
          ItemPlacement.inventory ||
          ItemPlacement.equipped => _MarketShopTab.toolsAndGear,
        };
        _selectedItemSlotIndex = purchasedSlot.slotIndex;
        _selectedItemOfferIndex = -1;
        _selectedOfferIndex = null;
        _selectedOwnedIndex = null;
        _startPurchaseFlight(
          label: boughtOffer.displayName,
          slotLabel: purchasedSlot.slotLabel,
          item: true,
          spentGold: boughtOffer.price,
        );
      } else {
        final nextEntries = _offerEntriesForTab(market, _shopTab);
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
    widget.onStateChanged();
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

  void _startPurchaseFlight({
    required String label,
    required String slotLabel,
    required bool item,
    required int spentGold,
  }) {
    final tick = _purchaseFlightTick + 1;
    _purchaseFlightTick = tick;
    _purchaseFlight = _MarketPurchaseFlight(
      tick: tick,
      label: label,
      slotLabel: slotLabel,
      item: item,
      spentGold: spentGold,
    );
    Future<void>.delayed(const Duration(milliseconds: 760), () {
      if (!mounted || _purchaseFlight?.tick != tick) return;
      setState(() => _purchaseFlight = null);
    });
  }

  void _startMarketDenyFeedback(String target, String reason) {
    final tick = _marketDenyTick + 1;
    setState(() {
      _marketDenyTick = tick;
      _marketDenyTarget = target;
      _marketDenyReason = reason;
    });
    Future<void>.delayed(const Duration(milliseconds: 560), () {
      if (!mounted || _marketDenyTick != tick) return;
      setState(() {
        _marketDenyTarget = null;
        _marketDenyReason = null;
      });
    });
  }

  void _useSelectedMarketItem(RummiMarketItemSlotView slot) {
    final item = slot.item;
    if (item == null) return;
    final failMessage = widget.onUseMarketItem(item);
    if (failMessage != null) {
      _startMarketDenyFeedback('item-use', failMessage);
      showBottomNotice(context, failMessage);
      return;
    }
    final feedbackTick = _marketUseFeedbackTick + 1;
    setState(() {
      _marketUseFeedbackTick = feedbackTick;
      _marketUseFeedbackLabel = '사용 완료';
      final market = _market;
      final stillExists = market.itemSlots.any(
        (nextSlot) =>
            nextSlot.slotIndex == slot.slotIndex && nextSlot.item != null,
      );
      if (!stillExists) {
        _selectedItemSlotIndex = -1;
        _selectFirstEntry(_offerEntriesForTab(market, _shopTab));
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (!mounted || _marketUseFeedbackTick != feedbackTick) return;
      setState(() => _marketUseFeedbackLabel = null);
    });
    widget.onStateChanged();
  }

  _MarketActionPane? _ownedMarketItemActionPane(
    BuildContext context,
    RummiMarketItemSlotView slot,
  ) {
    final item = slot.item;
    if (item == null) return null;
    if (item.effect.timing == 'use_market' ||
        item.effect.timing == 'use_market_if_gold_lte') {
      return _MarketActionPane(
        priceLabel: 'x${slot.count}',
        buttonLabel: '사용',
        buttonColor: const Color(0xFF2E8BC0),
        onPressed: () => _useSelectedMarketItem(slot),
        denyActive: _marketDenyTarget == 'item-use',
        denyTick: _marketDenyTick,
        denyReason: _marketDenyReason,
      );
    }
    if (item.effect.timing == 'market_buy' ||
        item.effect.timing == 'market_buy_if_category') {
      return _MarketActionPane(
        priceLabel: 'x${slot.count}',
        buttonLabel: '자동 적용',
        buttonColor: const Color(0xFF41584F),
        onPressed: null,
      );
    }
    return null;
  }

  void _sellOwned(int index) {
    final ok = widget.onSellOwnedJester(index);
    if (!ok) return;
    showTopNotice(context, '제스터를 판매했습니다.');
    setState(() {
      final market = _market;
      if (market.ownedEntries.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = market.offers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(0, market.ownedEntries.length - 1);
      }
    });
    widget.onStateChanged();
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
    while (mounted) {
      final activeRunSaveView = widget.readActiveRunSaveView?.call();
      _optionsDialogOpen = true;
      SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
      final action = await showGameFramedDialog<_MarketOptionsCloseAction>(
        context: context,
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = _market;
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
    final currentOfferEntries = _offerEntriesForTab(market, _shopTab);
    final currentOfferPage = _shopTab == _MarketShopTab.cardsAndQuickSlots
        ? _mainOfferPage
        : _utilityOfferPage;
    final visibleOfferEntries = _pagedItems(
      currentOfferEntries,
      currentOfferPage,
    );
    final selectedOwnedRuntimeValue = selectedOwned == null
        ? null
        : jesterRuntimeValueText(
            selectedOwned.card,
            market.runtimeSnapshot,
            slotIndex: selectedOwned.slotIndex,
          );

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
                          _MarketGoldChip(gold: market.gold),
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        market.maxOwnedSlots,
                                        (index) {
                                          final ownedEntry =
                                              index < market.ownedEntries.length
                                              ? market.ownedEntries[index]
                                              : null;
                                          final card = ownedEntry?.card;
                                          final selected =
                                              _selectedOwnedIndex == index;
                                          final pulse =
                                              _purchaseFlight?.item == false &&
                                              _purchaseFlight?.slotLabel ==
                                                  'J${index + 1}';
                                          final locked =
                                              index >=
                                              RummiRunProgress
                                                  .baseUnlockedJesterSlots;
                                          final child = _MarketSlotPulse(
                                            active: pulse,
                                            child: _MarketSelectableCardFrame(
                                              selected: false,
                                              width: _marketOwnedCardWidth,
                                              height: _marketOwnedCardHeight,
                                              child: GameJesterSlot(
                                                card: card,
                                                runtimeValueText: card == null
                                                    ? null
                                                    : jesterRuntimeValueText(
                                                        card,
                                                        market.runtimeSnapshot,
                                                        slotIndex: index,
                                                      ),
                                                extended: index == 4,
                                                activeEffect: null,
                                                settlementSequenceTick: 0,
                                                selected: selected,
                                                locked: locked,
                                              ),
                                            ),
                                          );

                                          return SizedBox(
                                            width:
                                                _marketOwnedCardWidth +
                                                (_marketCardSelectionInset * 2),
                                            height:
                                                _marketOwnedCardHeight +
                                                (_marketCardSelectionInset * 2),
                                            child: card == null || locked
                                                ? child
                                                : GestureDetector(
                                                    onTap: () =>
                                                        _selectOwned(index),
                                                    onLongPress: () =>
                                                        _showOwnedJesterDetail(
                                                          index,
                                                        ),
                                                    child: child,
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MarketQuickPassiveSlotsSection(
                                slots: visibleItemSlots,
                                selectedItemSlotIndex: _selectedItemSlotIndex,
                                pulsingSlotLabel: _purchaseFlight?.item == true
                                    ? _purchaseFlight?.slotLabel
                                    : null,
                                onTap: _selectItemSlot,
                              ),
                            ] else ...[
                              _MarketItemSlotsSection(
                                title: 'Tool Slots',
                                slots: visibleToolSlots,
                                selectedItemSlotIndex: _selectedItemSlotIndex,
                                pulsingSlotLabel: _purchaseFlight?.item == true
                                    ? _purchaseFlight?.slotLabel
                                    : null,
                                onTap: _selectItemSlot,
                              ),
                              const SizedBox(height: 6),
                              _MarketItemSlotsSection(
                                title: 'Gear Slots',
                                slots: visibleGearSlots,
                                selectedItemSlotIndex: _selectedItemSlotIndex,
                                pulsingSlotLabel: _purchaseFlight?.item == true
                                    ? _purchaseFlight?.slotLabel
                                    : null,
                                onTap: _selectItemSlot,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _MarketSpeechPanel(
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
                                          maxLines: 2,
                                        ),
                                        if (selectedOwnedRuntimeValue !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedOwnedRuntimeValue,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                  : selectedOwnedItemSlot != null
                                  ? _OwnedMarketItemBody(
                                      slot: selectedOwnedItemSlot,
                                    )
                                  : _MarketDescriptionText(
                                      '선택한 카드의 정보와 액션이 여기에 표시됩니다.',
                                      maxLines: 3,
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                    ),
                              trailing: selectedOwned != null
                                  ? _MarketActionPane(
                                      priceLabel: '+${selectedOwned.sellPrice}',
                                      buttonLabel: '판매',
                                      buttonColor: const Color(0xFFB74B3B),
                                      onPressed: () =>
                                          _sellOwned(selectedOwned.slotIndex),
                                    )
                                  : selectedOffer != null
                                  ? _MarketActionPane(
                                      priceLabel: '${selectedOffer.price}',
                                      buttonLabel: '구매',
                                      buttonColor: const Color(0xFFF4A81D),
                                      foreground: Colors.black,
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
                                              showBottomNotice(context, reason);
                                            },
                                      disabledReason: selectedOffer.isAffordable
                                          ? null
                                          : 'Gold 부족',
                                      denyActive:
                                          _marketDenyTarget == 'jester-buy',
                                      denyTick: _marketDenyTick,
                                      denyReason: _marketDenyReason,
                                    )
                                  : selectedItemOffer != null
                                  ? _MarketActionPane(
                                      priceLabel: '${selectedItemOffer.price}',
                                      buttonLabel: '구매',
                                      buttonColor: const Color(0xFFF4A81D),
                                      foreground: Colors.black,
                                      onPressed: selectedItemOffer.isAffordable
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
                                              showBottomNotice(context, reason);
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
                                  : selectedOwnedItemSlot != null
                                  ? _ownedMarketItemActionPane(
                                      context,
                                      selectedOwnedItemSlot,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            _MarketSectionBox(
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
                                    _MarketPagerBar(
                                      currentPage: currentOfferPage,
                                      pageCount: _pageCount(
                                        currentOfferEntries.length,
                                      ),
                                      onPrev:
                                          _shopTab ==
                                              _MarketShopTab.cardsAndQuickSlots
                                          ? () => _shiftMainOfferPage(-1)
                                          : () => _shiftUtilityOfferPage(-1),
                                      onNext:
                                          _shopTab ==
                                              _MarketShopTab.cardsAndQuickSlots
                                          ? () => _shiftMainOfferPage(1)
                                          : () => _shiftUtilityOfferPage(1),
                                      rerollCost: market.rerollCost,
                                      onReroll:
                                          _shopTab ==
                                              _MarketShopTab.cardsAndQuickSlots
                                          ? _reroll
                                          : null,
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
                                                      ? '이번 Market에 노출된 카드/Q-Slot이 없습니다.'
                                                      : '이번 Market에 노출된 Tool/Gear가 없습니다.',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.68,
                                                        ),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              )
                                            : _MarketOfferLane(
                                                itemCount:
                                                    visibleOfferEntries.length,
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i <
                                                        visibleOfferEntries
                                                            .length;
                                                    i++
                                                  )
                                                    _MarketOfferReveal(
                                                      index: i,
                                                      signature:
                                                          _offerEntrySignature(
                                                            market,
                                                            visibleOfferEntries[i],
                                                          ),
                                                      child: switch (visibleOfferEntries[i]
                                                          .kind) {
                                                        _MarketOfferEntryKind
                                                            .jester =>
                                                          _GameShopOfferCard(
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
                                                            offer:
                                                                market
                                                                    .itemOffers[visibleOfferEntries[i]
                                                                    .itemIndex!],
                                                            selected:
                                                                _selectedItemOfferIndex ==
                                                                visibleOfferEntries[i]
                                                                    .itemIndex,
                                                            onTap: () =>
                                                                _selectItemOffer(
                                                                  visibleOfferEntries[i]
                                                                      .itemIndex!,
                                                                ),
                                                          ),
                                                      },
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_purchaseFlight != null)
                  Positioned.fill(
                    child: _MarketPurchaseFlightOverlay(
                      flight: _purchaseFlight!,
                    ),
                  ),
                if (_marketUseFeedbackLabel != null)
                  Positioned.fill(
                    child: _MarketUseFeedbackToast(
                      label: _marketUseFeedbackLabel!,
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
      duration: const Duration(milliseconds: 220),
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

class _MarketUseFeedbackToast extends StatelessWidget {
  const _MarketUseFeedbackToast({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.16),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('market-use-feedback'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
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
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB9F6D3),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        overflow: TextOverflow.clip,
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
    required this.onTap,
  });

  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
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
    required this.onTap,
  });

  final String label;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
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
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse: pulsingSlotLabel == slots[i].slotLabel,
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
    required this.onTap,
  });

  final String title;
  final List<RummiMarketItemSlotView> slots;
  final int selectedItemSlotIndex;
  final String? pulsingSlotLabel;
  final ValueChanged<RummiMarketItemSlotView> onTap;

  @override
  Widget build(BuildContext context) {
    return _MarketSectionBox(
      title: title,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _MarketItemGhostChip(
                slot: slots[i],
                selected: selectedItemSlotIndex == slots[i].slotIndex,
                pulse: pulsingSlotLabel == slots[i].slotLabel,
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
                      overflow: TextOverflow.clip,
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
                      overflow: TextOverflow.clip,
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
            overflow: TextOverflow.clip,
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
              overflow: TextOverflow.clip,
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
      duration: const Duration(milliseconds: 360),
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

class _MarketDenyBadge extends StatelessWidget {
  const _MarketDenyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
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
            overflow: TextOverflow.clip,
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
  const _MarketDescriptionText(
    this.text, {
    required this.maxLines,
    this.color = Colors.white70,
  });

  final String text;
  final int maxLines;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('market-description-box'),
      constraints: const BoxConstraints(minHeight: _marketDescriptionMinHeight),
      child: Text(
        text,
        key: const ValueKey('market-description-text'),
        maxLines: maxLines,
        overflow: TextOverflow.clip,
        style: _marketDescriptionTextStyle.copyWith(color: color),
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
        _MarketDescriptionText(effectText, maxLines: tags.isEmpty ? 5 : 4),
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
        _MarketDescriptionText(effect, maxLines: 2),
        if (notice != null) ...[
          const SizedBox(height: 4),
          Text(
            notice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _MarketPagerBar extends StatelessWidget {
  const _MarketPagerBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
    required this.rerollCost,
    required this.onReroll,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int rerollCost;
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
          child: GameActionButton(
            label: '리롤 $rerollCost',
            background: const Color(0xFF2D6F9E),
            compact: true,
            onPressed: onReroll,
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

class _MarketItemGhostChip extends StatelessWidget {
  const _MarketItemGhostChip({
    required this.slot,
    this.selected = false,
    this.pulse = false,
    this.onTap,
  });

  final RummiMarketItemSlotView slot;
  final bool selected;
  final bool pulse;
  final ValueChanged<RummiMarketItemSlotView>? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = slot.locked;
    final label = slot.slotLabel;
    final displayName = slot.displayName;
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
        : displayName == null
        ? Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _itemSlotAccent(slot.placement),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                if (slot.count > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'x${slot.count}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          );
    final slotBox = SizedBox(
      width: _marketOwnedCardWidth + 6,
      height: _marketOwnedCardHeight + 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: locked
              ? Colors.black.withValues(alpha: 0.24)
              : displayName != null
              ? _itemSlotBackground(slot.placement)
              : Colors.black.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFF4A81D)
                : locked
                ? Colors.white12
                : displayName != null
                ? _itemSlotAccent(slot.placement).withValues(alpha: 0.6)
                : Colors.white10,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF4A81D).withValues(alpha: 0.22),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Center(child: foreground),
      ),
    );

    return Expanded(
      child: Center(
        child: GestureDetector(
          key: ValueKey<String>('market-item-slot-${slot.slotLabel}'),
          behavior: HitTestBehavior.opaque,
          onTap: locked || slot.item == null || onTap == null
              ? null
              : () => onTap!(slot),
          child: _MarketSlotPulse(active: pulse, child: slotBox),
        ),
      ),
    );
  }
}

Color _itemSlotBackground(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFF263A77),
    ItemPlacement.passiveRack => const Color(0xFF2D5B49),
    ItemPlacement.equipped => const Color(0xFF5B4D33),
    ItemPlacement.inventory => const Color(0xFF34423D),
  };
}

Color _itemSlotAccent(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFF78A6FF),
    ItemPlacement.passiveRack => const Color(0xFF8BE0B9),
    ItemPlacement.equipped => const Color(0xFFF2C14E),
    ItemPlacement.inventory => Colors.white70,
  };
}

class _MarketOfferLane extends StatelessWidget {
  const _MarketOfferLane({required this.itemCount, required this.children});

  final int itemCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (itemCount <= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: Center(child: children[i])),
            if (i < children.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
      duration: const Duration(milliseconds: 180),
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
    final delay = Duration(milliseconds: widget.index * 42);
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
              child: Text(
                '${offer.price}G',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: canAfford ? const Color(0xFFF2C14E) : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
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
    final accent = _itemOfferAccent(offer.item.placement);
    final rarityColor = gameItemRarityColor(offer.item.rarity);
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
                child: Container(
                  decoration: BoxDecoration(
                    color: _itemOfferSurface(offer.item.placement),
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
                            child: Text(
                              itemName,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.clip,
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
                          label: _itemSlotLabel(offer),
                          accent: accent,
                          textColor: _itemOfferBadgeTextColor(
                            offer.item.placement,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${offer.price}G',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: offer.isAffordable
                      ? const Color(0xFFF2C14E)
                      : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
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
        overflow: TextOverflow.clip,
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
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
    final start = flight.item
        ? const Alignment(0.52, 0.64)
        : const Alignment(-0.42, 0.64);
    final end = flight.item
        ? const Alignment(-0.52, -0.22)
        : const Alignment(-0.42, -0.48);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 42,
            child: _MarketGoldSpendBadge(spentGold: flight.spentGold),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              final alignment = Alignment.lerp(start, end, value)!;
              final lift = -22 * math.sin(math.pi * value);
              final scale = 0.88 + (0.16 * math.sin(math.pi * value));
              final opacity = value < 0.82 ? 1.0 : (1 - value) / 0.18;
              return Align(
                alignment: alignment,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              );
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
      duration: const Duration(milliseconds: 460),
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

class _MarketSlotPulse extends StatelessWidget {
  const _MarketSlotPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('market-slot-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = math.sin(math.pi * value);
        return Transform.scale(
          scale: 1 + (0.08 * pulse),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFF2C14E,
                  ).withValues(alpha: 0.34 * pulse),
                  blurRadius: 18 * pulse,
                  spreadRadius: 2 * pulse,
                ),
              ],
            ),
            child: child,
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
    return DecoratedBox(
      key: const ValueKey('market-purchase-flight'),
      decoration: BoxDecoration(
        color: flight.item ? const Color(0xFFE9F6EF) : const Color(0xFFF7E7B8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2C14E), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2C14E).withValues(alpha: 0.32),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        width: 78,
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              Text(
                flight.slotLabel,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Color(0xFF26352F),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                flight.label,
                maxLines: 2,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF26352F),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ],
          ),
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
              overflow: TextOverflow.ellipsis,
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$gold',
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.clip,
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

String _itemSlotLabel(RummiMarketItemOfferView offer) {
  return switch (offer.item.placement) {
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
  if (card.id == 'popcorn' || card.id == 'ice_cream') return '감쇠형';
  if (card.id == 'green_jester' || card.id == 'ride_the_bus') return '성장형';

  return switch (card.conditionType) {
    'none' => '상시',
    'pair' => 'Pair',
    'two_pair' => 'Two Pair',
    'three_of_a_kind' => 'Triple',
    'straight' => 'Straight',
    'flush' => 'Flush',
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
  if (card.id == 'scholar') return '+Chips/+Mult';
  if (card.id == 'ice_cream') return '+Chips';
  if (card.effectType == 'stateful_growth') return '+Mult';

  return switch (card.effectType) {
    'chips_bonus' => '+Chips',
    'mult_bonus' => '+Mult',
    'xmult_bonus' => 'xMult',
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
    'chips_bonus' => '+Chips',
    'mult_bonus' => '+Mult',
    'xmult_bonus' => 'xMult',
    'temporary_overlap_cap_bonus' => 'Overlap',
    'gain_gold' ||
    'board_discard_reward_bonus' ||
    'hand_discard_reward_bonus' => '+Gold',
    'discount_next_purchase' ||
    'free_next_reroll' ||
    'discount_first_reroll' => 'Discount',
    'add_board_discard' || 'add_hand_discard' => '+Discard',
    'extra_item_offer_slot' ||
    'extra_jester_offer_next_market' ||
    'rarity_weight_bonus' => 'Offer',
    'extra_quick_slot' => '+Slot',
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
    'chips' => '+Chips',
    'mult' => '+Mult',
    'xmult' => 'xMult',
    'rank' => '족보',
    'straight' => 'Straight',
    'flush' => 'Flush',
    'two_pair' => 'Two Pair',
    'overlap' => 'Overlap',
    'discard' => 'Discard',
    'draw' => 'Draw',
    'safety' => 'Safety',
    'equipment' => 'Gear',
    'station_start' => 'Station',
    'offer' => 'Offer',
    'jester' => 'Jester',
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
