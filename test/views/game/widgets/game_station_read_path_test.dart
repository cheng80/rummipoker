import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_station_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  testWidgets('GameTopHud renders station facade objective values', (
    tester,
  ) async {
    const station = RummiStationRuntimeFacade(
      stationType: RummiStationType.currentStage,
      objective: RummiStationObjectiveView(
        targetScore: 900,
        scoreTowardObjective: 360,
      ),
      resources: RummiStationResourceView(
        boardDiscardsRemaining: 2,
        boardDiscardsMax: 4,
        handDiscardsRemaining: 1,
        handDiscardsMax: 2,
        boardMovesRemaining: 3,
        boardMovesMax: 3,
        maxHandSize: 3,
        drawPileRemaining: 18,
      ),
    );
    final battle = RummiBattleRuntimeFacade(
      stageIndex: 4,
      currentGold: 27,
      totalDeckSize: 52,
      board: RummiBoard(),
      hand: [],
      scoringCellKeys: {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameTopHud(
            station: station,
            battle: battle,
            onOptionsTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('360 / 900'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('GameBottomInfoRow renders station facade resource values', (
    tester,
  ) async {
    const station = RummiStationRuntimeFacade(
      stationType: RummiStationType.currentStage,
      objective: RummiStationObjectiveView(
        targetScore: 900,
        scoreTowardObjective: 360,
      ),
      resources: RummiStationResourceView(
        boardDiscardsRemaining: 3,
        boardDiscardsMax: 4,
        handDiscardsRemaining: 1,
        handDiscardsMax: 2,
        boardMovesRemaining: 3,
        boardMovesMax: 3,
        maxHandSize: 3,
        drawPileRemaining: 14,
      ),
    );
    final battle = RummiBattleRuntimeFacade(
      stageIndex: 4,
      currentGold: 27,
      totalDeckSize: 52,
      board: RummiBoard(),
      hand: [
        Tile(id: 1, color: TileColor.red, number: 1),
        Tile(id: 2, color: TileColor.blue, number: 2),
      ],
      scoringCellKeys: {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameBottomInfoRow(station: station, battle: battle),
        ),
      ),
    );

    expect(find.text('덱 14/52'), findsOneWidget);
    expect(find.text('이동 3/3'), findsOneWidget);
    expect(find.text('보드 버림 3/4'), findsOneWidget);
    expect(find.text('손패 2/3 · 버림 1/2'), findsOneWidget);
  });

  testWidgets(
    'GameBoardGrid marks source, locked cells, and empty move targets',
    (tester) async {
      final board = RummiBoard();
      board.setCell(0, 0, Tile(id: 1, color: TileColor.red, number: 7));
      board.setCell(1, 1, Tile(id: 2, color: TileColor.blue, number: 8));
      final taps = <(int, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 320,
              child: GameBoardGrid(
                board: board,
                scoringCells: const {},
                activeSettlementCells: const {},
                settlementBoardSnapshot: const {},
                selectedRow: 0,
                selectedCol: 0,
                boardMoveMode: true,
                moveSourceRow: 0,
                moveSourceCol: 0,
                onTapCell: (row, col) => taps.add((row, col)),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.open_with_rounded), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('board-cell-0-0')));
      await tester.tap(find.byKey(const ValueKey('board-cell-2-2')));

      expect(taps, <(int, int)>[(0, 0), (2, 2)]);
    },
  );

  testWidgets('GameItemZoneSkeleton renders owned battle item slots', (
    tester,
  ) async {
    final item = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'board_scrap',
      'displayName': 'Board Scrap',
      'displayNameKey': 'data.items.board_scrap.displayName',
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
      'effectText': 'Gain +1 board discard for this Station.',
      'effectTextKey': 'data.items.board_scrap.effectText',
      'effect': <String, dynamic>{
        'timing': 'use_battle',
        'op': 'add_board_discard',
        'amount': 1,
        'consume': true,
      },
      'tags': <String>['battle', 'discard', 'safety'],
      'sourceNotes': 'Test fixture.',
    });
    final battle = RummiBattleRuntimeFacade(
      stageIndex: 4,
      currentGold: 27,
      totalDeckSize: 52,
      board: RummiBoard(),
      hand: [],
      scoringCellKeys: {},
      itemSlots: [
        RummiBattleItemSlotView.fromOwnedItem(
          slotIndex: 0,
          slotLabel: 'Q1',
          entry: const OwnedItemEntry(
            itemId: 'board_scrap',
            count: 2,
            placement: ItemPlacement.quickSlot,
          ),
          item: item,
        ),
      ],
    );

    RummiBattleItemSlotView? tappedSlot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameItemZoneSkeleton(
            battle: battle,
            onItemSlotTap: (slot) => tappedSlot = slot,
          ),
        ),
      ),
    );

    expect(find.text('Board\nScrap'), findsOneWidget);
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('Q2'), findsOneWidget);
    expect(find.text('Q3'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('P2'), findsOneWidget);

    await tester.tap(find.text('Board\nScrap'));
    expect(tappedSlot?.contentId, 'board_scrap');
  });

  testWidgets('GameItemZoneSkeleton keeps passive items in passive slots', (
    tester,
  ) async {
    final safetyNet = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'safety_net',
      'displayName': 'Safety Net',
      'displayNameKey': 'data.items.safety_net.displayName',
      'type': 'utility',
      'rarity': 'common',
      'basePrice': 4,
      'sellPrice': 2,
      'stackable': false,
      'maxStack': 1,
      'sellable': true,
      'usableInBattle': false,
      'placement': 'passiveRack',
      'slotHint': 'passive',
      'effectText':
          'Prevent the first run-ending combat lock once per Station.',
      'effectTextKey': 'data.items.safety_net.effectText',
      'effect': <String, dynamic>{
        'timing': 'expiry_guard',
        'op': 'rescue_first_expiry_each_station',
        'amount': 1,
      },
      'tags': <String>['battle', 'safety'],
      'sourceNotes': 'Test fixture.',
    });
    final battle = RummiBattleRuntimeFacade(
      stageIndex: 4,
      currentGold: 27,
      totalDeckSize: 52,
      board: RummiBoard(),
      hand: [],
      scoringCellKeys: {},
      itemSlots: [
        RummiBattleItemSlotView.fromOwnedItem(
          slotIndex: 0,
          slotLabel: 'P1',
          entry: const OwnedItemEntry(
            itemId: 'safety_net',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
          item: safetyNet,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameItemZoneSkeleton(battle: battle)),
      ),
    );

    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('Q2'), findsOneWidget);
    expect(find.text('Q3'), findsOneWidget);
    expect(find.text('Safety\nNet'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Safety\nNet')).dx,
      greaterThan(tester.getCenter(find.text('Q3')).dx),
    );
  });

  testWidgets('GameBattleItemInfoOverlay confirms use from explicit button', (
    tester,
  ) async {
    final item = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'board_scrap',
      'displayName': 'Board Scrap',
      'displayNameKey': 'data.items.board_scrap.displayName',
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
      'effectText': 'Gain +1 board discard for this Station.',
      'effectTextKey': 'data.items.board_scrap.effectText',
      'effect': <String, dynamic>{
        'timing': 'use_battle',
        'op': 'add_board_discard',
        'amount': 1,
        'consume': true,
      },
      'tags': <String>['battle', 'discard', 'safety'],
      'sourceNotes': 'Test fixture.',
    });
    final itemSlot = RummiBattleItemSlotView.fromOwnedItem(
      slotIndex: 0,
      slotLabel: 'Q1',
      entry: const OwnedItemEntry(
        itemId: 'board_scrap',
        count: 1,
        placement: ItemPlacement.quickSlot,
      ),
      item: item,
    );
    var useCount = 0;
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameBattleItemInfoOverlay(
            itemSlot: itemSlot,
            onUse: () => useCount += 1,
            onClose: () => closeCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Board Scrap'), findsOneWidget);
    expect(
      find.text('Gain +1 board discard for this Station.'),
      findsOneWidget,
    );
    expect(useCount, 0);

    await tester.tap(find.text('사용'));
    expect(useCount, 1);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closeCount, 1);
  });

  testWidgets('GameBattleItemInfoOverlay marks passive items as auto effects', (
    tester,
  ) async {
    final item = ItemDefinition.fromJson(const <String, dynamic>{
      'id': 'safety_net',
      'displayName': 'Safety Net',
      'displayNameKey': 'data.items.safety_net.displayName',
      'type': 'utility',
      'rarity': 'common',
      'basePrice': 4,
      'sellPrice': 2,
      'stackable': false,
      'maxStack': 1,
      'sellable': true,
      'usableInBattle': false,
      'placement': 'passiveRack',
      'slotHint': 'passive',
      'effectText':
          'Prevent the first run-ending combat lock once per Station.',
      'effectTextKey': 'data.items.safety_net.effectText',
      'effect': <String, dynamic>{
        'timing': 'expiry_guard',
        'op': 'rescue_first_expiry_each_station',
        'amount': 1,
      },
      'tags': <String>['battle', 'safety'],
      'sourceNotes': 'Test fixture.',
    });
    final itemSlot = RummiBattleItemSlotView.fromOwnedItem(
      slotIndex: 0,
      slotLabel: 'P1',
      entry: const OwnedItemEntry(
        itemId: 'safety_net',
        count: 1,
        placement: ItemPlacement.passiveRack,
      ),
      item: item,
    );
    var useCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameBattleItemInfoOverlay(
            itemSlot: itemSlot,
            onUse: () => useCount += 1,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Safety Net'), findsOneWidget);
    expect(find.text('패시브'), findsOneWidget);
    expect(find.text('자동 발동'), findsOneWidget);
    expect(find.text('패시브 효과 · 조건 충족 시 자동 발동'), findsOneWidget);
    expect(find.text('사용'), findsNothing);
    expect(useCount, 0);
  });
}
