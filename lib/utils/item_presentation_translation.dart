import 'package:flutter/widgets.dart';

import '../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../logic/rummi_poker_grid/item_presentation_event.dart';
import '../resources/item_translation_scope.dart';
import '../resources/jester_translation_scope.dart';
import 'app_translation.dart';

String localizedItemPresentationSource(
  BuildContext context,
  ItemPresentationEvent event,
) {
  final ids = event.sourceItemIds;
  if (ids == null || ids.isEmpty) return event.sourceLabel;
  final translations = ItemTranslationScope.of(context);
  final names = ids.map(translations.displayName).toList();
  if (names.any((name) => name == null)) return event.sourceLabel;
  return names.cast<String>().reduce(
    (first, second) => context.translate(
      'coreItemCombinedSources',
      namedArgs: {'first': first, 'second': second},
    ),
  );
}

String localizedItemPresentationTarget(
  BuildContext context,
  ItemPresentationEvent event,
) {
  if (event.target.itemId case final String id) {
    return ItemTranslationScope.of(
      context,
    ).resolveDisplayName(id, event.target.label);
  }
  if (event.target.jesterId case final String id) {
    return JesterTranslationScope.of(
      context,
    ).resolveDisplayName(id, event.target.label);
  }
  if (!event.target.translateKind) return event.target.label;
  final name = event.target.kind.name;
  return context.translate(
    'coreItemTarget${name[0].toUpperCase()}${name.substring(1)}',
  );
}

String localizedItemPresentationResult(
  BuildContext context,
  ItemPresentationEvent event,
) {
  if (event.consumed == null) return event.resultLabel;
  final operation = event.operation;
  if (operation != null) {
    final consumed = event.consumed!;
    final key = switch (operation) {
      'free_next_reroll' =>
        consumed ? 'marketRerollFreeConsumed' : 'marketRerollFreeTriggered',
      'discount_next_reroll' =>
        consumed
            ? 'marketRerollDiscountConsumed'
            : 'marketRerollDiscountTriggered',
      'discount_next_purchase' =>
        (event.effectEvent?.amount ?? 0) > 0
            ? (consumed
                  ? 'marketPurchaseDiscountConsumed'
                  : 'marketPurchaseDiscountTriggered')
            : (consumed ? 'marketDiscountConsumed' : 'marketDiscountTriggered'),
      'reroll_item_offers_only' => 'marketOffersReplaced',
      _ => null,
    };
    if (key == null) return event.resultLabel;
    return context.translate(
      key,
      namedArgs: {'amount': '${event.effectEvent?.amount.toInt() ?? 0}'},
    );
  }
  final timing = event.activationTiming;
  if (timing != null) {
    final key = switch (timing) {
      'next_confirm' ||
      'next_confirm_if_rank' ||
      'next_confirm_if_rank_at_least' ||
      'next_confirm_per_tile_color' ||
      'next_confirm_per_repeated_rank_tile' ||
      'first_confirm_each_station' ||
      'first_scored_tile_each_station' ||
      'on_confirm_if_played_hand_size_lte' ||
      'second_confirm_each_station' => 'PendingConfirm',
      'market_buy' || 'market_buy_if_category' => 'PendingBuy',
      'market_reroll' => 'PendingReroll',
      'station_start' => 'PendingBattle',
      'enter_market' ||
      'market_build_offers' ||
      'boss_blind_clear_market' => 'PendingMarket',
      'boss_blind_clear_reward' => 'PendingBoss',
      'settlement' => 'PendingSettlement',
      _ => null,
    };
    if (key == null) return event.resultLabel;
    final effect = context.translate('coreItem$key');
    return event.consumed!
        ? context.translate(
            'coreItemPendingConsumed',
            namedArgs: {'effect': effect},
          )
        : effect;
  }
  final effect = event.effectEvent;
  if (effect == null) return event.resultLabel;
  final label = localizedItemEffectResult(context, effect);
  if (label == null) return event.resultLabel;
  final key = event.activated
      ? (event.consumed! ? 'ActivatedConsumed' : 'Activated')
      : (event.consumed! ? 'ResultConsumed' : 'Result');
  return context.translate('coreItem$key', namedArgs: {'effect': label});
}

String localizedItemPresentationSummary(
  BuildContext context,
  ItemPresentationEvent event,
) => context.translate(
  'coreItemSummary',
  namedArgs: {
    'item': localizedItemPresentationSource(context, event),
    'result': localizedItemPresentationResult(context, event),
  },
);

/// Unknown technical operations preserve the producer's fallback text.
String? localizedItemEffectResult(BuildContext context, ItemEffectEvent event) {
  var amount = event.amount.toInt();
  if (event.kind == ItemEffectEventKind.tileDrawn && amount <= 0) amount = 1;
  final number = amount == 1 ? 'One' : 'Other';
  final key = switch (event.kind) {
    ItemEffectEventKind.boardDiscardAdded => 'BoardDiscard',
    ItemEffectEventKind.handDiscardAdded => 'HandDiscard',
    ItemEffectEventKind.boardMoveAdded => 'Move',
    ItemEffectEventKind.maxHandSizeIncreased => 'HandSize',
    ItemEffectEventKind.tileDrawn => 'Draw$number',
    ItemEffectEventKind.deckTileAdded => 'Deck$number',
    ItemEffectEventKind.deckTileDiscarded => 'DeckRemoved',
    ItemEffectEventKind.goldGained => 'Gold',
    ItemEffectEventKind.nextConfirmModifierQueued => 'Confirm',
    ItemEffectEventKind.marketModifierQueued => _marketEffectKey(event, number),
    ItemEffectEventKind.settlementModifierQueued => 'Settlement',
    ItemEffectEventKind.bossModifierQueued => 'Boss',
    ItemEffectEventKind.itemConsumed => 'Consumed',
    ItemEffectEventKind.boardDiscardRemoved ||
    ItemEffectEventKind.handDiscardRemoved => 'Removed',
    ItemEffectEventKind.boardMoveSlideBonusQueued => 'Slide',
    ItemEffectEventKind.boardMoveUndone => 'Undo',
    ItemEffectEventKind.capacityModifierQueued => 'Capacity',
    ItemEffectEventKind.expiryGuardTriggered => 'Guard',
    ItemEffectEventKind.interactionRequired => 'Interaction',
    ItemEffectEventKind.handRankProgressAdded => 'Growth',
    ItemEffectEventKind.boardLineTransformed => 'Line',
  };
  return key == null
      ? null
      : context.translate('coreItem$key', namedArgs: {'count': '$amount'});
}

String? _marketEffectKey(ItemEffectEvent event, String number) {
  // The runtime detail is a technical op or timing:op token, never display text.
  final tokens = event.detail?.split(':') ?? const <String>[];
  const operations = {
    'discount_next_purchase',
    'free_next_reroll',
    'discount_next_reroll',
    'extra_item_offer',
    'extra_item_offer_slot',
    'discount_first_reroll',
    'discount_cheapest_first_offer',
    'reroll_item_offers_only',
    'extra_jester_offer',
    'extra_jester_offer_slot',
  };
  final op = tokens.where(operations.contains).firstOrNull;
  return switch (op) {
    'discount_next_purchase' || 'discount_cheapest_first_offer' => 'Purchase',
    'free_next_reroll' => 'FreeReroll',
    'discount_next_reroll' || 'discount_first_reroll' => 'Reroll',
    'extra_item_offer' || 'extra_item_offer_slot' => 'ItemOffer$number',
    'reroll_item_offers_only' => 'Replace',
    'extra_jester_offer' || 'extra_jester_offer_slot' => 'JesterOffer$number',
    _ => null,
  };
}
