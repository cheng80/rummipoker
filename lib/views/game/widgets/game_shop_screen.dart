import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../resources/jester_translation_scope.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/phone_frame_scaffold.dart';
import 'game_jester_widgets.dart';

class GameShopScreen extends StatefulWidget {
  const GameShopScreen({
    super.key,
    required this.runProgress,
    required this.catalog,
    required this.rng,
    required this.runSeed,
    required this.onStateChanged,
    required this.onOpenSettings,
    required this.onExitToTitle,
    required this.onRestartRun,
  });

  final RummiRunProgress runProgress;
  final List<RummiJesterCard> catalog;
  final Random rng;
  final int runSeed;
  final Future<void> Function() onStateChanged;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onExitToTitle;
  final Future<void> Function() onRestartRun;

  @override
  State<GameShopScreen> createState() => _GameShopScreenState();
}

class _GameShopScreenState extends State<GameShopScreen> {
  int? _selectedOwnedIndex;
  int? _selectedOfferIndex;
  bool _sellTargetActive = false;
  int? _draggingOwnedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.runProgress.ownedJesters.isNotEmpty) {
      _selectedOwnedIndex = 0;
    } else if (widget.runProgress.shopOffers.isNotEmpty) {
      _selectedOfferIndex = 0;
    }
  }

  void _selectOwned(int index) {
    setState(() {
      _selectedOwnedIndex = index;
      _selectedOfferIndex = null;
    });
  }

  Future<void> _showOwnedJesterDetail(int index) async {
    if (index < 0 || index >= widget.runProgress.ownedJesters.length) return;
    final card = widget.runProgress.ownedJesters[index];
    final notes = JesterTranslationScope.of(context).notes(card.id);
    final sellGold = widget.runProgress.sellPriceAt(index);
    final runtimeValueText = jesterRuntimeValueText(
      card,
      widget.runProgress.buildRuntimeSnapshot(),
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
                          width: 74,
                          height: 100,
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
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _sellOwned(index);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB74B3B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '판매 +$sellGold Gold',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

  void _selectOffer(int index) {
    setState(() {
      _selectedOfferIndex = index;
      _selectedOwnedIndex = null;
    });
  }

  Future<void> _reroll() async {
    final confirmed = await _showShopDialog<bool>(
      context: context,
      builder: (dialogContext) => _ShopModalCard(
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
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A81D),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      '리롤',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;

    final ok = widget.runProgress.rerollShop(
      catalog: widget.catalog,
      rng: widget.rng,
    );
    if (!ok) {
      showBottomNotice(context, '리롤 골드가 부족합니다.');
      return;
    }
    setState(() {
      _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      _selectedOwnedIndex ??= widget.runProgress.ownedJesters.isEmpty
          ? null
          : 0;
    });
    await widget.onStateChanged();
  }

  void _buySelected() {
    final index = _selectedOfferIndex;
    if (index == null) return;
    final ok = widget.runProgress.buyOffer(index);
    if (!ok) {
      final text =
          widget.runProgress.ownedJesters.length >=
              RummiRunProgress.maxJesterSlots
          ? '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.'
          : '골드가 부족합니다.';
      showBottomNotice(context, text);
      return;
    }
    setState(() {
      if (widget.runProgress.ownedJesters.isNotEmpty) {
        _selectedOwnedIndex = widget.runProgress.ownedJesters.length - 1;
        _selectedOfferIndex = null;
      } else {
        _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      }
    });
    widget.onStateChanged();
  }

  void _sellOwned(int index) {
    final ok = widget.runProgress.sellOwnedJester(index);
    if (!ok) return;
    showTopNotice(context, '제스터를 판매했습니다.');
    setState(() {
      if (widget.runProgress.ownedJesters.isEmpty) {
        _selectedOwnedIndex = null;
        _selectedOfferIndex = widget.runProgress.shopOffers.isEmpty ? null : 0;
      } else {
        _selectedOwnedIndex = index.clamp(
          0,
          widget.runProgress.ownedJesters.length - 1,
        );
      }
    });
    widget.onStateChanged();
  }

  Future<void> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '재시작',
      message: '현재 진행 상황을 버리고 같은 시드로 처음부터 다시 시작할까요?',
      cancelLabel: '취소',
      confirmLabel: '재시작',
    );
    if (!mounted || !confirmed) return;

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

    Navigator.of(context).pop(false);
    await widget.onExitToTitle();
  }

  Future<void> _openOptions() async {
    await _showShopDialog<void>(
      context: context,
      builder: (dialogContext) => _ShopModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '상점 옵션',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run Seed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: '${widget.runSeed}'),
                          );
                          if (!mounted) return;
                          showTopNotice(context, '시드 번호를 복사했습니다.');
                        },
                        icon: const Icon(Icons.copy_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: Colors.lightBlueAccent.shade100,
              ),
              title: Text(
                context.tr('settings'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await widget.onOpenSettings();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.refresh_rounded,
                color: Colors.amber.shade200,
              ),
              title: Text(
                '재시작',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await _restartCurrentRun();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Colors.redAccent.shade100,
              ),
              title: Text(
                context.tr('exit'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    final pendingSellIndex = _draggingOwnedIndex ?? _selectedOwnedIndex;
    final pendingSellPrice =
        pendingSellIndex != null &&
            pendingSellIndex >= 0 &&
            pendingSellIndex < widget.runProgress.ownedJesters.length
        ? widget.runProgress.sellPriceAt(pendingSellIndex)
        : null;

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
              const Positioned.fill(child: _ShopTableBackdrop()),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jester Shop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            'Gold ${widget.runProgress.gold}',
                            style: const TextStyle(
                              color: Color(0xFFF2C14E),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _openOptions,
                          icon: const Icon(Icons.more_horiz_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '보유 Jester 5슬롯',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: kJesterCardHeight + 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          RummiRunProgress.maxJesterSlots,
                          (index) {
                            final card =
                                index < widget.runProgress.ownedJesters.length
                                ? widget.runProgress.ownedJesters[index]
                                : null;
                            final selected = _selectedOwnedIndex == index;
                            final child = Padding(
                              padding: const EdgeInsets.all(3),
                              child: Stack(
                                children: [
                                  if (selected)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(17),
                                            border: Border.all(
                                              color: const Color(0xFFF2C14E),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: GameJesterSlot(
                                      card: card,
                                      runtimeValueText: card == null
                                          ? null
                                          : jesterRuntimeValueText(
                                              card,
                                              widget.runProgress.buildRuntimeSnapshot(),
                                              slotIndex: index,
                                            ),
                                      extended: index == 4,
                                      activeEffect: null,
                                      settlementSequenceTick: 0,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            return SizedBox(
                              width: kJesterCardWidth + 6,
                              height: kJesterCardHeight + 6,
                              child: card == null
                                  ? child
                                  : LongPressDraggable<int>(
                                      data: index,
                                      onDragStarted: () {
                                        setState(() {
                                          _sellTargetActive = true;
                                          _draggingOwnedIndex = index;
                                        });
                                      },
                                      onDragEnd: (_) {
                                        if (mounted) {
                                          setState(() {
                                            _sellTargetActive = false;
                                            _draggingOwnedIndex = null;
                                          });
                                        }
                                      },
                                      feedback: SizedBox(
                                        width: kJesterCardWidth + 6,
                                        height: kJesterCardHeight + 6,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: GameJesterSlot(
                                              card: card,
                                              runtimeValueText: jesterRuntimeValueText(
                                                card,
                                                widget.runProgress.buildRuntimeSnapshot(),
                                                slotIndex: index,
                                              ),
                                              extended: index == 4,
                                              activeEffect: null,
                                              settlementSequenceTick: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _selectOwned(index);
                                          _showOwnedJesterDetail(index);
                                        },
                                        child: child,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DragTarget<int>(
                      onWillAcceptWithDetails: (_) {
                        setState(() => _sellTargetActive = true);
                        return true;
                      },
                      onLeave: (_) {
                        setState(() {
                          _sellTargetActive = false;
                        });
                      },
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _sellTargetActive = false;
                          _draggingOwnedIndex = null;
                        });
                        _sellOwned(details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final active =
                            _sellTargetActive || candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF5A1E1E)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFFFF8A65)
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            active
                                ? pendingSellPrice == null
                                    ? '여기에 놓으면 판매'
                                    : '여기에 놓으면 판매 +$pendingSellPrice Gold'
                                : pendingSellPrice == null
                                    ? '보유 Jester를 길게 눌러 여기로 드래그하면 판매'
                                    : '길게 눌러 드래그 판매 가능 · 예상 판매가 +$pendingSellPrice Gold',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '오퍼 목록',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _reroll,
                          child: Text(
                            '리롤 ${widget.runProgress.rerollCost}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: widget.runProgress.shopOffers.isEmpty
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  '이번 상점에 노출된 Jester가 없습니다.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: widget.runProgress.shopOffers.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final offer = widget.runProgress.shopOffers[index];
                                return _GameShopOfferCard(
                                  offer: offer,
                                  selected: _selectedOfferIndex == index,
                                  canAfford: widget.runProgress.canAfford(
                                    offer.price,
                                  ),
                                  onTap: () => _selectOffer(index),
                                  onBuy: () {
                                    _selectOffer(index);
                                    _buySelected();
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop(false);
                              await widget.onExitToTitle();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '메인 메뉴',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF267B67),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '다음 스테이지',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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

class _GameShopOfferCard extends StatelessWidget {
  const _GameShopOfferCard({
    required this.offer,
    required this.selected,
    required this.canAfford,
    required this.onTap,
    required this.onBuy,
  });

  final RummiShopOffer offer;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFF2C14E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF173C31)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: kJesterCardWidth,
                        height: kJesterCardHeight,
                        child: GameJesterSlot(
                          card: offer.card,
                          runtimeValueText: null,
                          extended: false,
                          activeEffect: null,
                          settlementSequenceTick: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedJesterName(context, offer.card),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizedJesterEffect(context, offer.card),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${offer.price}',
                            style: TextStyle(
                              color: canAfford
                                  ? const Color(0xFFF2C14E)
                                  : Colors.white38,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: FilledButton(
                              onPressed: canAfford ? onBuy : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: const Color(0xFFF4A81D),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '구매',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

Future<T?> _showShopDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

class _ShopModalCard extends StatelessWidget {
  const _ShopModalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: child,
      ),
    );
  }
}

class _ShopTableBackdrop extends StatelessWidget {
  const _ShopTableBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ShopTableBackdropPainter());
  }
}

class _ShopTableBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5644), Color(0xFF12392E), Color(0xFF0A211B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white.withValues(alpha: 0.035);
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.08);

    final seeds = [
      Offset(size.width * 0.18, size.height * 0.16),
      Offset(size.width * 0.82, size.height * 0.2),
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.72, size.height * 0.62),
      Offset(size.width * 0.22, size.height * 0.82),
    ];

    for (final center in seeds) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * 0.22,
        height: size.width * 0.22,
      );
      canvas.drawOval(rect.shift(const Offset(16, 12)), shadowPaint);
      canvas.drawOval(rect, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
