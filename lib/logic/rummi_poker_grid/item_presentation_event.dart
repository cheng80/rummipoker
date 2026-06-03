import 'item_definition.dart';
import 'item_effect_runtime.dart';

enum ItemPresentationSourceKind { quickSlot, passive, tool, gear, jester }

ItemPresentationSourceKind itemPresentationSourceKindForPlacement(
  ItemPlacement placement,
) {
  return switch (placement) {
    ItemPlacement.quickSlot => ItemPresentationSourceKind.quickSlot,
    ItemPlacement.passiveRack => ItemPresentationSourceKind.passive,
    ItemPlacement.inventory => ItemPresentationSourceKind.tool,
    ItemPlacement.equipped => ItemPresentationSourceKind.gear,
  };
}

enum ItemPresentationTargetKind {
  gold,
  marketOffer,
  marketReroll,
  itemOffer,
  confirm,
  boardResource,
  hand,
  deck,
  settlement,
  bossReward,
}

class ItemPresentationTarget {
  const ItemPresentationTarget({
    required this.kind,
    required this.label,
    this.key,
  });

  final ItemPresentationTargetKind kind;
  final String label;
  final String? key;
}

class ItemPresentationEvent {
  const ItemPresentationEvent({
    required this.itemId,
    required this.sourceKind,
    required this.sourceLabel,
    required this.target,
    required this.resultLabel,
    this.effectEvent,
  });

  final String itemId;
  final ItemPresentationSourceKind sourceKind;
  final String sourceLabel;
  final ItemPresentationTarget target;
  final String resultLabel;
  final ItemEffectEvent? effectEvent;
}

bool isDelayedItemActivation(ItemDefinition item) {
  return switch (item.effect.timing) {
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' ||
    'first_confirm_each_station' ||
    'first_scored_tile_each_station' ||
    'on_confirm_if_played_hand_size_lte' ||
    'second_confirm_each_station' ||
    'market_buy' ||
    'market_buy_if_category' ||
    'market_reroll' ||
    'station_start' ||
    'enter_market' ||
    'market_build_offers' ||
    'boss_blind_clear_market' ||
    'boss_blind_clear_reward' ||
    'settlement' => true,
    _ => false,
  };
}

String delayedItemActivationTimingLabel(ItemDefinition item) {
  return switch (item.effect.timing) {
    'next_confirm' ||
    'next_confirm_if_rank' ||
    'next_confirm_if_rank_at_least' ||
    'next_confirm_per_tile_color' ||
    'next_confirm_per_repeated_rank_tile' ||
    'first_confirm_each_station' ||
    'first_scored_tile_each_station' ||
    'on_confirm_if_played_hand_size_lte' ||
    'second_confirm_each_station' => '다음 확정에서 발동합니다.',
    'market_buy' || 'market_buy_if_category' => '다음 구매에서 발동합니다.',
    'market_reroll' => '다음 리롤에서 발동합니다.',
    'station_start' => '다음 전투 시작 시 발동합니다.',
    'enter_market' ||
    'market_build_offers' ||
    'boss_blind_clear_market' => '다음 Market에서 발동합니다.',
    'boss_blind_clear_reward' => '보스 클리어 보상에서 발동합니다.',
    'settlement' => '정산 시 발동합니다.',
    _ => '효과가 예약되었습니다.',
  };
}

String delayedItemConsumedTimingLabel(ItemDefinition item) {
  final prefix = item.effect.consume ? '소모됨 · ' : '';
  return '$prefix${delayedItemActivationTimingLabel(item)}';
}

String itemEffectEventResultLabel(ItemEffectEvent event) {
  final amount = event.amount.toInt();
  return switch (event.kind) {
    ItemEffectEventKind.boardDiscardAdded => '보드 버림 +$amount',
    ItemEffectEventKind.handDiscardAdded => '손패 버림 +$amount',
    ItemEffectEventKind.boardMoveAdded => '타일 이동 +$amount',
    ItemEffectEventKind.maxHandSizeIncreased => '손패 최대치 +$amount',
    ItemEffectEventKind.tileDrawn => '타일 ${amount <= 0 ? 1 : amount}장 생성',
    ItemEffectEventKind.deckTileAdded => '덱 타일 +$amount',
    ItemEffectEventKind.deckTileDiscarded => '덱 타일 제거',
    ItemEffectEventKind.goldGained => '+${amount}G',
    ItemEffectEventKind.nextConfirmModifierQueued => '확정 보너스 예약',
    ItemEffectEventKind.marketModifierQueued => _marketModifierEventLabel(
      event,
    ),
    ItemEffectEventKind.settlementModifierQueued => '정산 보너스 예약',
    ItemEffectEventKind.bossModifierQueued => '보스 보상 예약',
    ItemEffectEventKind.itemConsumed => '아이템 소모됨',
    ItemEffectEventKind.boardDiscardRemoved ||
    ItemEffectEventKind.handDiscardRemoved => '사용 횟수 차감',
    ItemEffectEventKind.boardMoveSlideBonusQueued => '이동 보너스 예약',
    ItemEffectEventKind.boardMoveUndone => '이동 되돌림',
    ItemEffectEventKind.capacityModifierQueued => '보유 효과 예약',
    ItemEffectEventKind.expiryGuardTriggered => '안전망 발동',
    ItemEffectEventKind.interactionRequired => '선택 필요',
    ItemEffectEventKind.handRankProgressAdded => '족보 성장 +$amount',
    ItemEffectEventKind.boardLineTransformed => '줄 효과 적용',
  };
}

String itemUseResultPresentationLabel(ItemUseResult result) {
  final effect = result.events.firstWhere(
    (event) => event.kind != ItemEffectEventKind.itemConsumed,
    orElse: () => result.events.isEmpty
        ? ItemEffectEvent(
            kind: ItemEffectEventKind.itemConsumed,
            itemId: result.itemId,
          )
        : result.events.first,
  );
  final effectLabel = itemEffectEventResultLabel(effect);
  final consumed = result.events.any(
    (event) => event.kind == ItemEffectEventKind.itemConsumed,
  );
  return consumed ? '$effectLabel · 소모됨' : effectLabel;
}

ItemPresentationTarget itemPresentationTargetForEvent(
  ItemDefinition item,
  ItemEffectEvent event,
) {
  return switch (event.kind) {
    ItemEffectEventKind.boardDiscardAdded ||
    ItemEffectEventKind.handDiscardAdded ||
    ItemEffectEventKind.boardMoveAdded ||
    ItemEffectEventKind.boardDiscardRemoved ||
    ItemEffectEventKind.handDiscardRemoved ||
    ItemEffectEventKind.boardMoveSlideBonusQueued ||
    ItemEffectEventKind.boardMoveUndone => const ItemPresentationTarget(
      kind: ItemPresentationTargetKind.boardResource,
      label: '전투 행동',
    ),
    ItemEffectEventKind.maxHandSizeIncreased ||
    ItemEffectEventKind.tileDrawn => const ItemPresentationTarget(
      kind: ItemPresentationTargetKind.hand,
      label: '손패',
    ),
    ItemEffectEventKind.deckTileAdded ||
    ItemEffectEventKind.deckTileDiscarded => const ItemPresentationTarget(
      kind: ItemPresentationTargetKind.deck,
      label: '덱',
    ),
    ItemEffectEventKind.goldGained => const ItemPresentationTarget(
      kind: ItemPresentationTargetKind.gold,
      label: 'Gold',
    ),
    ItemEffectEventKind.nextConfirmModifierQueued =>
      const ItemPresentationTarget(
        kind: ItemPresentationTargetKind.confirm,
        label: '다음 확정',
      ),
    ItemEffectEventKind.marketModifierQueued => ItemPresentationTarget(
      kind: item.effect.timing == 'market_reroll'
          ? ItemPresentationTargetKind.marketReroll
          : ItemPresentationTargetKind.marketOffer,
      label: item.effect.timing == 'market_reroll' ? '다음 리롤' : 'Market',
    ),
    ItemEffectEventKind.settlementModifierQueued =>
      const ItemPresentationTarget(
        kind: ItemPresentationTargetKind.settlement,
        label: '정산',
      ),
    ItemEffectEventKind.bossModifierQueued => const ItemPresentationTarget(
      kind: ItemPresentationTargetKind.bossReward,
      label: '보스 보상',
    ),
    _ => ItemPresentationTarget(
      kind: ItemPresentationTargetKind.confirm,
      label: delayedItemActivationTimingLabel(item).replaceAll('합니다.', ''),
    ),
  };
}

String _marketModifierEventLabel(ItemEffectEvent event) {
  final detail = event.detail ?? '';
  final amount = event.amount.toInt();
  if (detail.contains('discount_next_purchase')) return '구매가 -${amount}G';
  if (detail.contains('free_next_reroll')) return '리롤 무료 예약';
  if (detail.contains('discount_next_reroll')) return '리롤 비용 -${amount}G';
  if (detail.contains('extra_item_offer')) return 'Item 후보 +$amount';
  if (detail.contains('reroll_item_offers_only')) return 'Item 후보 교체';
  if (detail.contains('extra_jester_offer')) return 'Jester 후보 +$amount';
  return 'Market 효과 예약';
}
