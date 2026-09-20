import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final market in [false, true]) {
    for (final consumed in [false, true]) {
      test(
        '${market ? 'market' : 'station'} reports actual hook consumption $consumed and drains once',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          const args = GameSessionArgs(runSeed: 12345);
          final notifier = container.read(
            gameSessionNotifierProvider(args).notifier,
          );
          final before = container.read(gameSessionNotifierProvider(args));
          final catalog = ItemCatalog.fromJson({
            'items': [
              {
                'id': 'trigger',
                'displayName': 'Trigger',
                'type': 'utility',
                'rarity': 'common',
                'basePrice': 1,
                'sellPrice': 1,
                'stackable': true,
                'maxStack': 3,
                'sellable': true,
                'usableInBattle': false,
                'placement': 'inventory',
                'slotHint': 'utility',
                'effectText': '',
                'effect': {
                  'timing': market ? 'enter_market' : 'station_start',
                  'op': market ? 'gain_gold' : 'add_board_move',
                  'amount': 2,
                  'consume': consumed,
                },
              },
            ],
          });
          before.runProgress!.itemInventory = const RunInventoryState(
            ownedItems: [
              OwnedItemEntry(
                itemId: 'trigger',
                count: 1,
                placement: ItemPlacement.inventory,
              ),
            ],
          );
          if (market) {
            notifier.openShop(itemCatalog: catalog);
          } else {
            notifier.advanceToNextStage(12345, itemCatalog: catalog);
          }
          final after = container.read(gameSessionNotifierProvider(args));
          final event = after.pendingItemPresentationEvents.single;
          expect(event.consumed, consumed);
          expect(event.activated, true);
          expect(event.sourceItemIds, ['trigger']);
          expect(
            event.effectEvent!.kind,
            market
                ? ItemEffectEventKind.goldGained
                : ItemEffectEventKind.boardMoveAdded,
          );
          expect(event.effectEvent!.amount, 2);
          expect(after.runProgress!.itemInventory.ownedItems.isEmpty, consumed);
          final revision = after.revision;
          notifier.clearPendingItemPresentationEvents();
          expect(
            container
                .read(gameSessionNotifierProvider(args))
                .pendingItemPresentationEvents,
            isEmpty,
          );
          notifier.clearPendingItemPresentationEvents();
          expect(
            container
                .read(gameSessionNotifierProvider(args))
                .pendingItemPresentationEvents,
            isEmpty,
          );
          expect(
            container.read(gameSessionNotifierProvider(args)).revision,
            greaterThanOrEqualTo(revision),
          );
        },
      );
    }
  }
}
