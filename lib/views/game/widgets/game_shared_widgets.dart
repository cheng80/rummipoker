import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../game/rummi_poker_grid/rummikub_tile_canvas.dart';
import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/item_translation_scope.dart';
import '../../../resources/sound_manager.dart';
import '../../../utils/common_ui.dart';

const double kGameTileAspectRatio = 1.0;
const double kBoardFrameInset = 10.0;
const double kBoardGridGap = 1.5;
const double kBoardTileInnerPadding = 2.0;
const double kBattleItemSlotWidth = 58.0;
const double kBattleItemSlotHeight = 78.0;
const int kBattleQuickSlotDisplayCount = 3;
const int kBattlePassiveSlotDisplayCount = 2;
const int kBattleToolSlotDisplayCount = 3;
const int kBattleGearSlotDisplayCount = 2;
const int kBattleBaseUnlockedQuickSlots = 2;
const int kBattleBaseUnlockedPassiveSlots = 1;
const Color kGameModalBarrierColor = Color(0x70000000);
const Color kGameFeedbackBarrierColor = Color(0x22000000);

const TextStyle gameHudLabelStyle = TextStyle(
  color: Colors.white70,
  fontSize: 9,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.35,
);

final TextStyle gameHudValueStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.96),
  fontWeight: FontWeight.w900,
  height: 1,
);

class GameInputBarrier extends StatelessWidget {
  const GameInputBarrier.modal({super.key}) : color = kGameModalBarrierColor;

  const GameInputBarrier.feedback({super.key})
    : color = kGameFeedbackBarrierColor;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(dismissible: false, color: color);
  }
}

const TextStyle gameHudSubStyle = TextStyle(
  color: Colors.white70,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

/// 보드 가로 폭 기준 실제 카드 렌더 폭을 계산한다.
double boardTileVisualWidth(double boardSide) {
  final gridSide = boardSide - (kBoardFrameInset * 2);
  final cellSide = (gridSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
  return cellSide - (kBoardTileInnerPadding * 2);
}

class GameTopHud extends StatelessWidget {
  const GameTopHud({
    super.key,
    required this.station,
    required this.battle,
    required this.onOptionsTap,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final objective = station.objective;
    final progress = objective.targetScore <= 0
        ? 0.0
        : (objective.scoreTowardObjective / objective.targetScore).clamp(
            0.0,
            1.0,
          );
    final goldDisplayValue = '${battle.currentGold}';

    return SizedBox(
      height: 76,
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: GameHudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'STATION',
                    style: gameHudLabelStyle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          '${battle.stageIndex}',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: gameHudValueStyle.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '보상 +${RummiRunProgress.stageClearGoldBase}',
                    style: gameHudSubStyle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GameHudChip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'STATION GOAL',
                    style: gameHudLabelStyle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${objective.scoreTowardObjective}',
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.clip,
                              style: gameHudValueStyle.copyWith(fontSize: 20),
                            ),
                          ),
                          Text(
                            '/',
                            maxLines: 1,
                            style: gameHudValueStyle.copyWith(fontSize: 20),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${objective.targetScore}',
                              maxLines: 1,
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.clip,
                              style: gameHudValueStyle.copyWith(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF4A81D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 142,
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
                  const SizedBox(height: 2),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Gold',
                            value: goldDisplayValue,
                            child: ExcludeSemantics(
                              child: Image.asset(
                                AssetPaths.uiGreed,
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                goldDisplayValue,
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.clip,
                                style: gameHudValueStyle.copyWith(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          GestureDetector(
                            onTap: onOptionsTap,
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 18,
                              height: 22,
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white.withValues(alpha: 0.88),
                                size: 18,
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
        ],
      ),
    );
  }
}

class GameBottomInfoRow extends StatelessWidget {
  const GameBottomInfoRow({
    super.key,
    required this.station,
    required this.battle,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;

  @override
  Widget build(BuildContext context) {
    final resources = station.resources;
    return Row(
      children: [
        Expanded(
          child: Text(
            '덱 ${resources.drawPileRemaining}/${battle.totalDeckSize}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '이동 ${resources.boardMovesRemaining}/${resources.boardMovesMax}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '보드 버림 ${resources.boardDiscardsRemaining}/${resources.boardDiscardsMax}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '손패 ${battle.hand.length}/${resources.maxHandSize} · 버림 ${resources.handDiscardsRemaining}/${resources.handDiscardsMax}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

enum _GameItemZoneTab { slots, tools }

class GameItemZoneSkeleton extends StatefulWidget {
  const GameItemZoneSkeleton({
    super.key,
    required this.battle,
    this.onItemSlotTap,
  });

  final RummiBattleRuntimeFacade battle;
  final ValueChanged<RummiBattleItemSlotView>? onItemSlotTap;

  @override
  State<GameItemZoneSkeleton> createState() => _GameItemZoneSkeletonState();
}

class _GameItemZoneSkeletonState extends State<GameItemZoneSkeleton> {
  _GameItemZoneTab _tab = _GameItemZoneTab.slots;

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final quickSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.quickSlot)
        .toList(growable: false);
    final passiveSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.passiveRack)
        .toList(growable: false);
    final toolSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.inventory)
        .take(kBattleToolSlotDisplayCount)
        .toList(growable: false);
    final gearSlots = battle.itemSlots
        .where((slot) => slot.placement == ItemPlacement.equipped)
        .take(kBattleGearSlotDisplayCount)
        .toList(growable: false);
    final unlockedQuickSlots = max(
      kBattleBaseUnlockedQuickSlots,
      quickSlots.length,
    );
    final unlockedPassiveSlots = max(
      kBattleBaseUnlockedPassiveSlots,
      passiveSlots.length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF173126).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GameItemZoneTabBar(
              currentTab: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _tab == _GameItemZoneTab.slots
                  ? [
                      for (
                        var index = 0;
                        index < kBattleQuickSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'Q${index + 1}',
                          accent: const Color(0xFF267B67),
                          itemSlot: index < quickSlots.length
                              ? quickSlots[index]
                              : null,
                          locked: index >= unlockedQuickSlots,
                          onTap: widget.onItemSlotTap,
                        ),
                      for (
                        var index = 0;
                        index < kBattlePassiveSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'P${index + 1}',
                          accent: const Color(0xFF4C5A55),
                          itemSlot: index < passiveSlots.length
                              ? passiveSlots[index]
                              : null,
                          locked: index >= unlockedPassiveSlots,
                          onTap: widget.onItemSlotTap,
                        ),
                    ]
                  : [
                      for (
                        var index = 0;
                        index < kBattleToolSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'T${index + 1}',
                          accent: const Color(0xFF2D7FA2),
                          itemSlot: index < toolSlots.length
                              ? toolSlots[index]
                              : null,
                          onTap: widget.onItemSlotTap,
                        ),
                      for (
                        var index = 0;
                        index < kBattleGearSlotDisplayCount;
                        index++
                      )
                        _GameItemPocketChip(
                          label: 'G${index + 1}',
                          accent: const Color(0xFFB88735),
                          itemSlot: index < gearSlots.length
                              ? gearSlots[index]
                              : null,
                          onTap: widget.onItemSlotTap,
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameItemZoneTabBar extends StatelessWidget {
  const _GameItemZoneTabBar({
    required this.currentTab,
    required this.onChanged,
  });

  final _GameItemZoneTab currentTab;
  final ValueChanged<_GameItemZoneTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: _GameItemZoneTabButton(
              label: 'Slots',
              selected: currentTab == _GameItemZoneTab.slots,
              onPressed: () => onChanged(_GameItemZoneTab.slots),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _GameItemZoneTabButton(
              label: 'Tool / Gear',
              selected: currentTab == _GameItemZoneTab.tools,
              onPressed: () => onChanged(_GameItemZoneTab.tools),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameItemZoneTabButton extends StatelessWidget {
  const _GameItemZoneTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: selected
            ? const Color(0xFFF4A81D)
            : Colors.black.withValues(alpha: 0.16),
        foregroundColor: selected ? Colors.black : Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class GameBattleItemInfoOverlay extends StatelessWidget {
  const GameBattleItemInfoOverlay({
    super.key,
    required this.itemSlot,
    required this.onUse,
    required this.onClose,
  });

  final RummiBattleItemSlotView itemSlot;
  final VoidCallback onUse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final translations = ItemTranslationScope.of(context);
    final name = translations.resolveDisplayName(
      itemSlot.contentId,
      itemSlot.displayName,
    );
    final effectText = translations.resolveEffectText(
      itemSlot.contentId,
      itemSlot.effectText,
    );
    final canUseInBattle =
        itemSlot.placement == ItemPlacement.quickSlot &&
        itemSlot.usableInBattle;
    final isPassive =
        itemSlot.placement == ItemPlacement.passiveRack ||
        itemSlot.placement == ItemPlacement.equipped;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF123126).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                effectText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _GameItemOverlayTag(text: itemSlot.slotLabel),
                  const SizedBox(width: 8),
                  _GameItemOverlayTag(text: 'x${itemSlot.count}'),
                  if (isPassive) ...[
                    const SizedBox(width: 8),
                    _GameItemOverlayTag(
                      text: itemSlot.placement == ItemPlacement.equipped
                          ? '기어'
                          : '패시브',
                    ),
                    const SizedBox(width: 8),
                    const _GameItemOverlayTag(text: '자동 발동'),
                  ],
                ],
              ),
              if (canUseInBattle) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GameActionButton(
                    label: '사용',
                    background: const Color(0xFFF4A81D),
                    foreground: Colors.black,
                    onPressed: onUse,
                  ),
                ),
              ] else if (isPassive) ...[
                const SizedBox(height: 12),
                const _GamePassiveItemNotice(),
              ] else if (itemSlot.placement == ItemPlacement.inventory) ...[
                const SizedBox(height: 12),
                const _GameToolItemNotice(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameToolItemNotice extends StatelessWidget {
  const _GameToolItemNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '상점용 도구 · Market에서 조건에 따라 사용',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePassiveItemNotice extends StatelessWidget {
  const _GamePassiveItemNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Text(
            '패시브 효과 · 조건 충족 시 자동 발동',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameItemOverlayTag extends StatelessWidget {
  const _GameItemOverlayTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _GameItemPocketChip extends StatelessWidget {
  const _GameItemPocketChip({
    required this.label,
    required this.accent,
    this.locked = false,
    this.itemSlot,
    this.onTap,
  });

  final String label;
  final Color accent;
  final bool locked;
  final RummiBattleItemSlotView? itemSlot;
  final ValueChanged<RummiBattleItemSlotView>? onTap;

  @override
  Widget build(BuildContext context) {
    final itemSlot = this.itemSlot;
    final itemName = itemSlot == null
        ? null
        : ItemTranslationScope.of(
            context,
          ).resolveDisplayName(itemSlot.contentId, itemSlot.displayName);
    final compactItemName = itemName?.replaceFirst(' ', '\n');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked || itemSlot == null || onTap == null
          ? null
          : () => onTap!(itemSlot),
      child: Stack(
        children: [
          Container(
            width: kBattleItemSlotWidth,
            height: kBattleItemSlotHeight,
            decoration: BoxDecoration(
              color: locked
                  ? Colors.black.withValues(alpha: 0.26)
                  : itemSlot == null
                  ? Colors.black.withValues(alpha: 0.16)
                  : accent.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: locked
                    ? Colors.white.withValues(alpha: 0.14)
                    : itemSlot == null
                    ? accent.withValues(alpha: 0.48)
                    : accent.withValues(alpha: 0.82),
                width: itemSlot == null ? 1 : 1.3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
              child: locked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white.withValues(alpha: 0.40),
                          size: 22,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : itemSlot == null
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          itemSlot.slotLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Center(
                            child: Text(
                              compactItemName!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (itemSlot != null && itemSlot.count > 1)
            Positioned(
              right: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  child: Text(
                    'x${itemSlot.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GameDebugShopHandCluster extends StatelessWidget {
  const GameDebugShopHandCluster({
    super.key,
    required this.onShopTap,
    required this.handSize,
    required this.onHandSizeChanged,
  });

  final VoidCallback onShopTap;
  final int handSize;
  final ValueChanged<int> onHandSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DEBUG',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                GestureDetector(
                  onTap: onShopTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A81D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'MARKET',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GameDebugHandSizeSegment(
                  value: handSize,
                  onChanged: onHandSizeChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameDebugHandSizeSegment extends StatelessWidget {
  const GameDebugHandSizeSegment({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 8),
            child: Text(
              'Hand',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final option in const [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => onChanged(option),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: value == option
                        ? const Color(0xFF4AA78D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$option',
                    style: TextStyle(
                      color: value == option ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GameHudChip extends StatelessWidget {
  const GameHudChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A4D3C).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6A8E7C).withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
        child: child,
      ),
    );
  }
}

class GameBoardGrid extends StatelessWidget {
  const GameBoardGrid({
    super.key,
    required this.board,
    required this.scoringCells,
    required this.activeSettlementCells,
    required this.settlementBoardSnapshot,
    required this.selectedRow,
    required this.selectedCol,
    required this.boardMoveMode,
    required this.moveSourceRow,
    required this.moveSourceCol,
    required this.onTapCell,
    this.alignment = Alignment.center,
  });

  final RummiBoard board;
  final Set<String> scoringCells;
  final Set<String> activeSettlementCells;
  final Map<String, Tile> settlementBoardSnapshot;
  final int? selectedRow;
  final int? selectedCol;
  final bool boardMoveMode;
  final int? moveSourceRow;
  final int? moveSourceCol;
  final void Function(int row, int col) onTapCell;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A4B3A).withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF739785).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kBoardFrameInset),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kBoardSize,
                    mainAxisSpacing: kBoardGridGap,
                    crossAxisSpacing: kBoardGridGap,
                  ),
                  itemCount: kBoardSize * kBoardSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ kBoardSize;
                    final col = index % kBoardSize;
                    final tile =
                        board.cellAt(row, col) ??
                        settlementBoardSnapshot['$row:$col'];
                    final selected = selectedRow == row && selectedCol == col;
                    final scoring = scoringCells.contains('$row:$col');
                    final settlementActive = activeSettlementCells.contains(
                      '$row:$col',
                    );
                    final isMoveSource =
                        boardMoveMode &&
                        moveSourceRow == row &&
                        moveSourceCol == col;
                    final isMoveAvailable = boardMoveMode && tile == null;
                    final isMoveLocked =
                        boardMoveMode && tile != null && !isMoveSource;
                    return GameBoardCell(
                      key: ValueKey('board-cell-$row-$col'),
                      tile: tile,
                      selected: selected,
                      scoring: scoring,
                      settlementActive: settlementActive,
                      moveSource: isMoveSource,
                      moveAvailable: isMoveAvailable,
                      moveLocked: isMoveLocked,
                      onTap: () => onTapCell(row, col),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameBoardCell extends StatelessWidget {
  const GameBoardCell({
    super.key,
    required this.tile,
    required this.selected,
    required this.scoring,
    required this.settlementActive,
    required this.moveSource,
    required this.moveAvailable,
    required this.moveLocked,
    required this.onTap,
  });

  final Tile? tile;
  final bool selected;
  final bool scoring;
  final bool settlementActive;
  final bool moveSource;
  final bool moveAvailable;
  final bool moveLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = moveSource
        ? const Color(0xFF5EE7F7)
        : moveAvailable
        ? const Color(0xFF85E9B8)
        : moveLocked
        ? Colors.white.withValues(alpha: 0.18)
        : selected
        ? const Color(0xFFF76D5E)
        : settlementActive
        ? const Color(0xFF86F4C3)
        : scoring
        ? const Color(0xFFF4C45A)
        : Colors.white.withValues(alpha: 0.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final cornerRadius = rummikubTileCornerRadiusForSide(side);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2A3B34)
                    : moveAvailable
                    ? const Color(0xFF23654A).withValues(alpha: 0.86)
                    : moveLocked
                    ? const Color(0xFF24312D).withValues(alpha: 0.78)
                    : settlementActive
                    ? const Color(0xFF285A49)
                    : const Color(0xFF204E3C).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(cornerRadius),
                border: Border.all(
                  color: borderColor,
                  width:
                      selected ||
                          settlementActive ||
                          moveSource ||
                          moveAvailable
                      ? 2
                      : 1,
                ),
                boxShadow: settlementActive
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF86F4C3,
                          ).withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: tile == null
                  ? moveAvailable
                        ? Center(
                            child: Icon(
                              Icons.open_with_rounded,
                              color: Colors.white.withValues(alpha: 0.58),
                              size: side * 0.32,
                            ),
                          )
                        : null
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: Opacity(
                        opacity: moveLocked ? 0.42 : 1,
                        child: GameRummiTileCard(
                          tile: tile!,
                          selected: selected || moveSource,
                          accent: false,
                          aspectRatio: kGameTileAspectRatio,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.onPressed,
    this.foreground = Colors.white,
    this.compact = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: GameChromeButton(
        label: label,
        backgroundColor: background,
        foregroundColor: foreground,
        onPressed: onPressed,
        height: compact ? 30 : 40,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 4 : 6,
        ),
      ),
    );
  }
}

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: _GameRummiTilePainter(
          tile: tile,
          selected: selected,
          accent: accent,
        ),
      ),
    );
  }
}

class _GameRummiTilePainter extends CustomPainter {
  const _GameRummiTilePainter({
    required this.tile,
    required this.selected,
    required this.accent,
  });

  final Tile tile;
  final bool selected;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintRummikubTile(
      canvas,
      rect,
      tile,
      selected: selected,
      shadowElevation: selected ? 4 : 2.4,
    );

    if (!accent) return;
    final accentRect = rect.deflate(3.5);
    final rr = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF2C14E).withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _GameRummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
}

/// 게임·상점 화면 공통 테이블 배경. 정적이므로 repaint 없음.
class GameTableBackdrop extends StatelessWidget {
  const GameTableBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GameTableBackdropPainter());
  }
}

class _GameTableBackdropPainter extends CustomPainter {
  const _GameTableBackdropPainter();

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

/// 게임·상점 다이얼로그 공통 카드 컨테이너.
class GameModalCard extends StatelessWidget {
  const GameModalCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: child,
      ),
    );
  }
}

/// 게임·상점 다이얼로그를 표시한다. barrierDismissible 기본 true.
Future<T?> showGameFramedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: kGameModalBarrierColor,
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

String expirySignalLabel(RummiExpirySignal signal) {
  return switch (signal) {
    RummiExpirySignal.boardFullAfterDcExhausted =>
      '버림이 모두 소진된 상태에서 보드 25칸이 가득 찼습니다.',
    RummiExpirySignal.drawPileExhausted =>
      '드로우 덱이 소진되었고 더 이상 사용할 손패나 확정할 줄이 없습니다.',
  };
}

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetry]는 현재 스테이지 시작 스냅샷으로 즉시 복원한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required Future<void> Function() onRetry,
  required Future<void> Function() onExit,
}) {
  final text =
      '${signals.map(expirySignalLabel).join('\n')}\n\n'
      '현재 스테이지 시작 상태로 다시 시도하거나 종료할 수 있습니다.';
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('gameResult'),
            style: TextStyle(
              fontFamily: AssetPaths.fontNexonLv2Gothic,
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GameActionButton(
                  label: '다시하기',
                  background: const Color(0xFFF4A81D),
                  foreground: Colors.black,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onRetry();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameActionButton(
                  label: context.tr('exit'),
                  background: const Color(0xFF5D6B68),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onExit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
