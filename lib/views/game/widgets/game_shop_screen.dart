import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/jester_translation_scope.dart';
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
const double _marketShopPanelHeight = 184.0;
const double _marketSpeechPanelHeight = 116.0;

enum _MarketShopTab { jesters, items }

class GameShopScreen extends StatefulWidget {
  const GameShopScreen({
    super.key,
    required this.runSeed,
    required this.readMarketView,
    required this.onReroll,
    required this.onBuyOffer,
    required this.onBuyItemOffer,
    required this.onSellOwnedJester,
    required this.onStateChanged,
    required this.onOpenSettings,
    required this.onExitToTitle,
    required this.onRestartRun,
    required this.isDebugFixtureRun,
    this.readActiveRunSaveView,
    this.autoAdvanceOnLoad = false,
  });

  final int runSeed;
  final RummiMarketRuntimeFacade Function() readMarketView;
  final String? Function() onReroll;
  final String? Function(int offerIndex) onBuyOffer;
  final String? Function(RummiMarketItemOfferView offer) onBuyItemOffer;
  final bool Function(int ownedIndex) onSellOwnedJester;
  final Future<void> Function() onStateChanged;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onExitToTitle;
  final Future<void> Function() onRestartRun;
  final bool isDebugFixtureRun;
  final RummiActiveRunSaveFacade? Function()? readActiveRunSaveView;
  final bool autoAdvanceOnLoad;

  @override
  State<GameShopScreen> createState() => _GameShopScreenState();
}

class _GameShopScreenState extends State<GameShopScreen> {
  int? _selectedOwnedIndex;
  int? _selectedOfferIndex;
  _MarketShopTab _shopTab = _MarketShopTab.jesters;
  int _selectedItemOfferIndex = 0;
  int _jesterOfferPage = 0;
  int _itemOfferPage = 0;

  RummiMarketRuntimeFacade get _market => widget.readMarketView();

  @override
  void initState() {
    super.initState();
    if (_market.ownedEntries.isNotEmpty) {
      _selectedOwnedIndex = 0;
    } else if (_market.offers.isNotEmpty) {
      _selectedOfferIndex = 0;
    }
    if (widget.autoAdvanceOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      });
    }
  }

  void _selectOwned(int index) {
    setState(() {
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
    });
  }

  void _selectOffer(int index) {
    setState(() {
      _shopTab = _MarketShopTab.jesters;
      _selectedOfferIndex = index;
      _selectedOwnedIndex = null;
    });
  }

  void _selectItemOffer(int index) {
    setState(() {
      _shopTab = _MarketShopTab.items;
      _selectedItemOfferIndex = index;
      _selectedOwnedIndex = null;
      _selectedOfferIndex = null;
    });
  }

  void _selectShopTab(_MarketShopTab tab) {
    setState(() {
      _shopTab = tab;
      _selectedOwnedIndex = null;
      if (tab == _MarketShopTab.jesters) {
        _selectedOfferIndex ??= _market.offers.isEmpty ? null : 0;
      }
    });
  }

  void _shiftJesterOfferPage(int delta) {
    final pageCount = _pageCount(_market.offers.length);
    if (pageCount <= 1) return;
    setState(() {
      _jesterOfferPage = (_jesterOfferPage + delta).clamp(0, pageCount - 1);
    });
  }

  void _shiftItemOfferPage(int delta) {
    final pageCount = _pageCount(_market.itemOffers.length);
    if (pageCount <= 1) return;
    setState(() {
      _itemOfferPage = (_itemOfferPage + delta).clamp(0, pageCount - 1);
    });
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
    final failMessage = widget.onBuyOffer(index);
    if (failMessage != null) {
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final market = _market;
      if (market.ownedEntries.isNotEmpty) {
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
    final failMessage = widget.onBuyItemOffer(offers[index]);
    if (failMessage != null) {
      showBottomNotice(context, failMessage);
      return;
    }
    setState(() {
      final nextOffers = _market.itemOffers;
      if (nextOffers.isEmpty) {
        _selectedItemOfferIndex = 0;
      } else if (_selectedItemOfferIndex >= nextOffers.length) {
        _selectedItemOfferIndex = nextOffers.length - 1;
      }
    });
    widget.onStateChanged();
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

  Future<void> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
      message: widget.isDebugFixtureRun
          ? '디버그 픽스처 시작 상태로 다시 불러올까요?\n현재 화면에서 만든 변경 사항은 취소됩니다.'
          : '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    Navigator.of(context).pop(false);
    await widget.onRestartRun();
  }

  Future<void> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    Navigator.of(context).pop(false);
    await widget.onExitToTitle();
  }

  Future<void> _openOptions() async {
    final activeRunSaveView = widget.readActiveRunSaveView?.call();
    await showGameFramedDialog<void>(
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                Navigator.of(dialogContext).pop();
                await widget.onOpenSettings();
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
                Navigator.of(dialogContext).pop();
                await _restartCurrentRun();
              },
            ),
            const SizedBox(height: 8),
            GameMenuActionTile(
              title: context.tr('exit'),
              subtitle: '현재 진행을 멈추고 메인 메뉴로 돌아갑니다.',
              icon: Icons.logout_rounded,
              accentColor: Colors.redAccent.shade100,
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await _exitToTitleWithConfirm();
              },
            ),
          ],
        ),
      ),
    );
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
        _shopTab == _MarketShopTab.jesters &&
            _selectedOfferIndex != null &&
            _selectedOfferIndex! >= 0 &&
            _selectedOfferIndex! < market.offers.length
        ? market.offers[_selectedOfferIndex!]
        : null;
    final selectedItemOffer =
        _shopTab == _MarketShopTab.items &&
            _selectedItemOfferIndex >= 0 &&
            _selectedItemOfferIndex < market.itemOffers.length
        ? market.itemOffers[_selectedItemOfferIndex]
        : null;
    final visibleJesterOffers = _pagedItems(market.offers, _jesterOfferPage);
    final visibleItemOffers = _pagedItems(market.itemOffers, _itemOfferPage);
    final selectedOwnedRuntimeValue = selectedOwned == null
        ? null
        : jesterRuntimeValueText(
            selectedOwned.card,
            market.runtimeSnapshot,
            slotIndex: selectedOwned.slotIndex,
          );

    return PhoneFrameScaffold(
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
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jester Market',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            'Gold ${market.gold}',
                            style: const TextStyle(
                              color: Color(0xFFF2C14E),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
                    _MarketSectionBox(
                      title: 'Jester Slots',
                      trailing:
                          '${market.ownedEntries.length}/${market.maxOwnedSlots}',
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: SizedBox(
                        height: _marketOwnedCardHeight + 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(market.maxOwnedSlots, (
                            index,
                          ) {
                            final ownedEntry =
                                index < market.ownedEntries.length
                                ? market.ownedEntries[index]
                                : null;
                            final card = ownedEntry?.card;
                            final selected = _selectedOwnedIndex == index;
                            final child = _MarketSelectableCardFrame(
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
                              ),
                            );

                            return SizedBox(
                              width:
                                  _marketOwnedCardWidth +
                                  (_marketCardSelectionInset * 2),
                              height:
                                  _marketOwnedCardHeight +
                                  (_marketCardSelectionInset * 2),
                              child: card == null
                                  ? child
                                  : GestureDetector(
                                      onTap: () => _selectOwned(index),
                                      onLongPress: () =>
                                          _showOwnedJesterDetail(index),
                                      child: child,
                                    ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MarketSectionBox(
                      title: 'Item Slots',
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: const [
                          _MarketItemGhostChip(label: 'Q1'),
                          SizedBox(width: 8),
                          _MarketItemGhostChip(label: 'Q2'),
                          SizedBox(width: 8),
                          _MarketItemGhostChip(label: 'Passive'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MarketSpeechPanel(
                      title: selectedOwned != null
                          ? localizedJesterName(context, selectedOwned.card)
                          : selectedOffer != null
                          ? localizedJesterName(context, selectedOffer.card)
                          : selectedItemOffer != null
                          ? localizedItemName(context, selectedItemOffer)
                          : '선택된 카드 없음',
                      subtitle: selectedOwned != null
                          ? '보유 슬롯'
                          : selectedOffer != null
                          ? 'Jester Shop'
                          : selectedItemOffer != null
                          ? 'Item Shop'
                          : '카드를 선택하세요',
                      body: selectedOwned != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizedJesterEffect(
                                    context,
                                    selectedOwned.card,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.18,
                                  ),
                                ),
                                if (selectedOwnedRuntimeValue != null) ...[
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
                          ? Text(
                              localizedJesterEffect(
                                context,
                                selectedOffer.card,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                              ),
                            )
                          : selectedItemOffer != null
                          ? Text(
                              localizedItemEffect(context, selectedItemOffer),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                              ),
                            )
                          : Text(
                              '선택한 카드의 정보와 액션이 여기에 표시됩니다.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
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
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _MarketSectionBox(
                      title: null,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: SizedBox(
                        height: _marketShopPanelHeight,
                        child: Column(
                          children: [
                            _MarketTabBar(
                              currentTab: _shopTab,
                              onChanged: _selectShopTab,
                            ),
                            const SizedBox(height: 8),
                            _MarketPagerBar(
                              currentPage: _shopTab == _MarketShopTab.jesters
                                  ? _jesterOfferPage
                                  : _itemOfferPage,
                              pageCount: _shopTab == _MarketShopTab.jesters
                                  ? _pageCount(market.offers.length)
                                  : _pageCount(market.itemOffers.length),
                              onPrev: _shopTab == _MarketShopTab.jesters
                                  ? () => _shiftJesterOfferPage(-1)
                                  : () => _shiftItemOfferPage(-1),
                              onNext: _shopTab == _MarketShopTab.jesters
                                  ? () => _shiftJesterOfferPage(1)
                                  : () => _shiftItemOfferPage(1),
                              rerollCost: market.rerollCost,
                              onReroll: _shopTab == _MarketShopTab.jesters
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
                                child: _shopTab == _MarketShopTab.jesters
                                    ? (visibleJesterOffers.isEmpty
                                          ? Center(
                                              child: Text(
                                                '이번 Market에 노출된 Jester가 없습니다.',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.68),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            )
                                          : _MarketOfferLane(
                                              itemCount:
                                                  visibleJesterOffers.length,
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i <
                                                      visibleJesterOffers
                                                          .length;
                                                  i++
                                                )
                                                  _GameShopOfferCard(
                                                    offer:
                                                        visibleJesterOffers[i],
                                                    selected:
                                                        _selectedOfferIndex ==
                                                        market.offers.indexOf(
                                                          visibleJesterOffers[i],
                                                        ),
                                                    canAfford:
                                                        visibleJesterOffers[i]
                                                            .isAffordable,
                                                    onTap: () => _selectOffer(
                                                      market.offers.indexOf(
                                                        visibleJesterOffers[i],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ))
                                    : _MarketOfferLane(
                                        itemCount: visibleItemOffers.length,
                                        children: [
                                          for (
                                            var i = 0;
                                            i < visibleItemOffers.length;
                                            i++
                                          )
                                            _MarketItemOfferCard(
                                              offer: visibleItemOffers[i],
                                              selected:
                                                  _selectedItemOfferIndex ==
                                                  market.itemOffers.indexOf(
                                                    visibleItemOffers[i],
                                                  ),
                                              onTap: () => _selectItemOffer(
                                                market.itemOffers.indexOf(
                                                  visibleItemOffers[i],
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
            ],
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
              Row(
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
              const SizedBox(height: 4),
            ],
            child,
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
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
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
                      overflow: TextOverflow.ellipsis,
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
                      overflow: TextOverflow.ellipsis,
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
  });

  final String priceLabel;
  final String buttonLabel;
  final Color buttonColor;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            priceLabel,
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
        ],
      ),
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
            label: 'Jester Shop',
            backgroundColor: currentTab == _MarketShopTab.jesters
                ? const Color(0xFFF4A81D)
                : const Color(0xFF29453A),
            foregroundColor: currentTab == _MarketShopTab.jesters
                ? Colors.black
                : Colors.white,
            onPressed: () => onChanged(_MarketShopTab.jesters),
            height: 30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GameChromeButton(
            label: 'Item Shop',
            backgroundColor: currentTab == _MarketShopTab.items
                ? const Color(0xFFF4A81D)
                : const Color(0xFF29453A),
            foregroundColor: currentTab == _MarketShopTab.items
                ? Colors.black
                : Colors.white,
            onPressed: () => onChanged(_MarketShopTab.items),
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
  const _MarketItemGhostChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: _marketOwnedCardWidth + 6,
          height: _marketOwnedCardHeight + 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                selected: false,
                width: _marketOfferCardWidth,
                height: _marketOfferCardHeight,
                child: GameJesterSlot(
                  card: offer.card,
                  runtimeValueText: null,
                  extended: false,
                  activeEffect: null,
                  settlementSequenceTick: 0,
                  selected: selected,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${offer.price}G',
              style: TextStyle(
                color: canAfford ? const Color(0xFFF2C14E) : Colors.white38,
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
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      _itemSlotLabel(offer),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${offer.price}G',
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

String _itemSlotLabel(RummiMarketItemOfferView offer) {
  return switch (offer.item.placement) {
    ItemPlacement.quickSlot => 'Q',
    ItemPlacement.passiveRack => 'PASS',
    ItemPlacement.equipped => 'GEAR',
    ItemPlacement.inventory => 'UTIL',
  };
}
