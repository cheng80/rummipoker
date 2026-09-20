import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

void main() {
  late ProviderContainer container;
  late GameSessionNotifier notifier;
  const args = GameSessionArgs(runSeed: 4147);
  setUp(() {
    container = ProviderContainer();
    notifier = container.read(gameSessionNotifierProvider(args).notifier);
  });
  tearDown(() => container.dispose());
  Map<String, dynamic> save() =>
      (jsonDecode(
              ActiveRunSaveService.runtimeStateToJson(
                notifier.buildSaveRuntimeState(difficulty: args.difficulty),
              ),
            )
            as Map<String, dynamic>)
        ..remove('savedAt');

  test('legacy custom failure and pending preserve messages and events', () {
    for (final result in [
      ItemUseResult.failure(itemId: 'custom', message: 'custom user text'),
      ItemUseResult.pendingHook(itemId: 'custom', message: 'custom user text'),
    ]) {
      expect(result.failure, isNull);
      expect(result.failMessage, 'custom user text');
      expect(result.events, isEmpty);
    }
  });
  test('rejected target preserves save JSON and reports stable reason', () {
    final before = save();
    final failure = notifier.discardSelectedBoardTileFromStateFailure();
    expect(failure!.reason, ActionFailureReason.selectBoardDiscard);
    expect(notifier.discardSelectedBoardTileFromState(), failure.legacyMessage);
    expect(save(), before);
  });
  test('successful typed draw executes once and legacy wrapper matches save', () {
    final initial = notifier.buildSaveRuntimeState(difficulty: args.difficulty);
    final beforeCount = initial.session.deck.remaining;
    expect(notifier.drawTileFailure(), isNull);
    final typed = save();
    expect(
      notifier
          .buildSaveRuntimeState(difficulty: args.difficulty)
          .session
          .deck
          .remaining,
      beforeCount - 1,
    );
    final second = ProviderContainer();
    addTearDown(second.dispose);
    final legacy = second.read(gameSessionNotifierProvider(args).notifier);
    expect(legacy.drawTile(), isNull);
    final legacySave =
        (jsonDecode(
                ActiveRunSaveService.runtimeStateToJson(
                  legacy.buildSaveRuntimeState(difficulty: args.difficulty),
                ),
              )
              as Map<String, dynamic>)
          ..remove('savedAt');
    // New-run claim IDs are generated independently; use the original snapshots for comparison below.
    expect(typed['session'], legacySave['session']);
  });
  test('hand cap has args and rejected draw leaves save unchanged', () {
    final session = notifier
        .buildSaveRuntimeState(difficulty: args.difficulty)
        .session;
    while (session.canDrawFromDeck) {
      notifier.drawTileFailure();
    }
    final before = save();
    final failure = notifier.drawTileFailure()!;
    expect(failure.reason, ActionFailureReason.handFull);
    expect(failure.args, {'count': '${session.maxHandSize}'});
    expect(notifier.drawTile(), failure.legacyMessage);
    expect(save(), before);
  });
  test('item cap and pending preserve inventory RNG and save', () {
    final runtime = notifier.buildSaveRuntimeState(difficulty: args.difficulty);
    final item = _item('cap', 'add_board_discard');
    runtime.runProgress.itemInventory = const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'cap',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: ['cap'],
    );
    runtime.session.blind.boardDiscardsRemaining =
        ItemEffectRuntime.maxSupportedBoardDiscards;
    final before = save();
    final result = ItemEffectRuntime.useBattleItem(
      item: item,
      session: runtime.session,
      runProgress: runtime.runProgress,
    );
    expect(result.failure!.reason, ActionFailureReason.boardDiscardCap);
    expect(result.failMessage, '보드 버림 최대치입니다.');
    expect(result.events, isEmpty);
    expect(save(), before);
    final pending = ItemEffectRuntime.useBattleItem(
      item: _item('cap', 'ritual_line_effect'),
      session: runtime.session,
      runProgress: runtime.runProgress,
    );
    expect(pending.isPending, isTrue);
    expect(pending.failure!.reason, ActionFailureReason.selectRitualTarget);
    expect(pending.events.single.kind, ItemEffectEventKind.interactionRequired);
    expect(save(), before);
  });
  test(
    'typed free reroll executes once then rejected paid reroll preserves save',
    () {
      notifier.openShop();
      final runtime = notifier.buildSaveRuntimeState(
        difficulty: args.difficulty,
      );
      runtime.runProgress.gold = 0;
      expect(notifier.rerollTileOffersFromStateFailure(), isNull);
      final before = save();
      final failure = notifier.rerollTileOffersFromStateFailure();
      expect(failure!.reason, ActionFailureReason.rerollGold);
      expect(notifier.rerollTileOffersFromState(), failure.legacyMessage);
      expect(save(), before);
    },
  );
  test('analytics classification is independent of legacy text', () {
    expect(
      const ActionFailure(
        ActionFailureReason.insufficientGold,
        '任意',
      ).analyticsCode,
      'not_enough_gold',
    );
    expect(
      const ActionFailure(
        ActionFailureReason.jesterSlotsFull,
        'custom',
      ).analyticsCode,
      'no_space',
    );
    expect(const ActionFailure(null, '골드 슬롯 공간').analyticsCode, 'denied');
  });
}

ItemDefinition _item(String id, String op) => ItemDefinition.fromJson({
  'id': id,
  'displayName': id,
  'displayNameKey': id,
  'type': 'consumable',
  'rarity': 'common',
  'basePrice': 4,
  'sellPrice': 2,
  'stackable': true,
  'maxStack': 2,
  'sellable': true,
  'usableInBattle': true,
  'placement': 'quickSlot',
  'slotHint': 'q',
  'effectText': 'test',
  'effectTextKey': 'test',
  'effect': {'timing': 'use_battle', 'op': op, 'amount': 1, 'consume': true},
  'tags': <String>[],
  'sourceNotes': 'test',
});
