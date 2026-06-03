import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('battle item use feedback covers failure and success paths', (
    tester,
  ) async {
    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem('undo_seal'),
      debugFixtureId: 'test_failed_undo_item',
      debugAutoUseItemId: 'undo_seal',
    );

    await _pumpUntilText(tester, '되돌릴 보드 이동이 없습니다.');

    expect(find.text('되돌릴 보드 이동이 없습니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('item-effect-spark-burst')), findsNothing);

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem(
        'emergency_draw',
        hand: const [Tile(color: TileColor.red, number: 7)],
      ),
      debugFixtureId: 'test_failed_emergency_draw_item',
      debugAutoUseItemId: 'emergency_draw',
    );

    await _pumpUntilText(tester, '손패가 비어 있을 때만 사용할 수 있습니다.');

    expect(find.text('손패가 비어 있을 때만 사용할 수 있습니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('item-effect-spark-burst')), findsNothing);

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem('emergency_draw', clearHand: true),
      debugFixtureId: 'test_success_emergency_draw_item',
      debugAutoUseItemId: 'emergency_draw',
    );

    await _pumpUntilText(tester, '타일 1장 드로우');

    expect(find.text('타일 1장 드로우'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bottom-resource-pulse-deck')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-resource-pulse-hand')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('item-effect-spark-burst')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('item-effect-source-label')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('item-effect-source-result-trail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('item-effect-result-label')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _twoPairPreviewFixtureWithQuickItem('straight_oil'),
      debugFixtureId: 'test_pending_confirm_condition_preview',
      debugAutoUseItemId: 'straight_oil',
    );

    await _pumpUntilText(tester, '아이템 조건 미충족 0/1');

    expect(find.text('아이템 조건 미충족 0/1'), findsOneWidget);
    expect(find.text('확정 대기 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scoring-preview-item-link-flash')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle-item-confirm-queued-badge')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    final deckNeedleFixture = DebugRunFixtureService.build(
      DebugRunFixtureService.deckNeedleBattle,
    );
    expect(deckNeedleFixture, isNotNull);

    await _pumpGameView(
      tester,
      restoredRun: deckNeedleFixture!,
      debugFixtureId: DebugRunFixtureService.deckNeedleBattle,
      debugAutoUseItemId: 'deck_needle',
    );

    await _pumpUntilText(tester, '덱 위 3장 중 버릴 타일을 선택합니다.');

    expect(find.text('후보 1'), findsOneWidget);
    expect(find.text('후보 2'), findsOneWidget);
    expect(find.text('후보 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tile-choice-0')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('tile-choice-selected-feedback-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tile-choice-discard-result-0')),
      findsOneWidget,
    );
    await _pumpUntilText(tester, 'R1 제거');

    expect(find.text('R1 제거'), findsWidgets);
    expect(
      find.byKey(const ValueKey('item-effect-spark-burst')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _boardMoveFixtureWithQuickItem('slide_wax'),
      debugFixtureId: 'test_slide_wax_board_move_bonus',
      debugAutoUseItemId: 'slide_wax',
    );

    await _pumpUntilText(tester, '다음 보드 이동 보너스 준비');

    expect(find.text('이동 보너스 대기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('battle-item-board-move-queued-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle-item-board-move-queued-motion')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const ValueKey('board-cell-0-0')));
    await tester.pump();
    await tester.tap(find.text('타일\n이동'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('board-cell-0-1')));
    await _pumpUntilText(tester, '보드 이동');
    await tester.tap(find.text('이동').last);
    await tester.pump();
    await _pumpUntilText(tester, '이동 보너스 발동');

    expect(find.text('이동 보너스 대기'), findsNothing);
    expect(find.text('슬라이드 왁스'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('board-move-bonus-flash')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('item-effect-spark-burst')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.animationEffectsEyeCheck,
    );
    expect(fixture, isNotNull);

    await _pumpGameView(
      tester,
      restoredRun: fixture!,
      debugFixtureId: DebugRunFixtureService.animationEffectsEyeCheck,
      debugAutoUseItemId: 'board_scrap',
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('item-effect-spark-burst'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey('item-effect-spark-burst')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('item-effect-source-label')),
        matching: find.text('Q1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-resource-pulse-board-discard')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem('hand_scrap'),
      debugFixtureId: 'test_hand_scrap_resource_feedback',
      debugAutoUseItemId: 'hand_scrap',
    );

    await _pumpUntilText(tester, '손패 버림 +1');

    expect(
      find.byKey(const ValueKey('bottom-resource-pulse-hand')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem('move_token'),
      debugFixtureId: 'test_move_token_resource_feedback',
      debugAutoUseItemId: 'move_token',
    );

    await _pumpUntilText(tester, '타일 이동 +1');

    expect(
      find.byKey(const ValueKey('bottom-resource-pulse-board-move')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _fixtureWithQuickItem('battle_pouch'),
      debugFixtureId: 'test_battle_pouch_capacity_feedback',
      debugAutoUseItemId: 'battle_pouch',
    );

    await _pumpUntilText(tester, '손패 최대치 +1');

    expect(
      find.byKey(const ValueKey('hand-capacity-gain-badge')),
      findsOneWidget,
    );

    await _disposeGameView(tester);

    await _pumpGameView(
      tester,
      restoredRun: _undoSuccessFixture(),
      debugFixtureId: 'test_success_undo_item',
      debugAutoUseItemId: 'undo_seal',
    );

    await _pumpUntilText(tester, '마지막 이동 되돌림');

    expect(
      find.byKey(const ValueKey('board-move-bonus-flash')),
      findsOneWidget,
    );

    await _disposeGameView(tester);
  });
}

Future<void> _pumpGameView(
  WidgetTester tester, {
  required ActiveRunRuntimeState restoredRun,
  required String debugFixtureId,
  String? debugAutoUseItemId,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) {
          return ProviderScope(
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: JesterTranslationScope(
                child: ItemTranslationScope(
                  child: GameView(
                    runSeed: 901,
                    restoredRun: restoredRun,
                    debugFixtureId: debugFixtureId,
                    debugAutoUseItemId: debugAutoUseItemId,
                    debugItemCatalogOverride: ItemCatalog.fromJsonString(
                      File(
                        'data/common/items_common_v1.json',
                      ).readAsStringSync(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

ActiveRunRuntimeState _fixtureWithQuickItem(
  String itemId, {
  List<Tile> hand = const [],
  bool clearHand = false,
}) {
  final base = DebugRunFixtureService.build(
    DebugRunFixtureService.stage2ScoringSnapshot,
  );
  expect(base, isNotNull);

  final session = base!.session.copySnapshot();
  if (clearHand || hand.isNotEmpty) {
    session.hand
      ..clear()
      ..addAll(hand);
  }

  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: itemId,
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: [itemId],
    );

  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: base.difficulty,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

ActiveRunRuntimeState _twoPairPreviewFixtureWithQuickItem(String itemId) {
  final base = DebugRunFixtureService.build(
    DebugRunFixtureService.stage2ScoringSnapshot,
  );
  expect(base, isNotNull);

  final session = RummiPokerGridSession(
    runSeed: base!.session.runSeed,
    blind: RummiBlindState(targetScore: 999),
  );
  session.board
    ..setCell(0, 0, const Tile(color: TileColor.red, number: 2))
    ..setCell(0, 1, const Tile(color: TileColor.blue, number: 2))
    ..setCell(0, 2, const Tile(color: TileColor.red, number: 3))
    ..setCell(0, 3, const Tile(color: TileColor.blue, number: 3))
    ..setCell(0, 4, const Tile(color: TileColor.black, number: 5));

  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: itemId,
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: [itemId],
    );

  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: base.difficulty,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

ActiveRunRuntimeState _boardMoveFixtureWithQuickItem(String itemId) {
  final base = DebugRunFixtureService.build(
    DebugRunFixtureService.stage2ScoringSnapshot,
  );
  expect(base, isNotNull);

  final session = RummiPokerGridSession(
    runSeed: base!.session.runSeed,
    blind: RummiBlindState(targetScore: 999, boardMovesRemaining: 3),
  );
  session.board.setCell(0, 0, const Tile(color: TileColor.red, number: 7));

  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: itemId,
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: [itemId],
    );

  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: base.difficulty,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

ActiveRunRuntimeState _undoSuccessFixture() {
  final base = DebugRunFixtureService.build(
    DebugRunFixtureService.stage2ScoringSnapshot,
  );
  expect(base, isNotNull);

  final session = RummiPokerGridSession(
    runSeed: base!.session.runSeed,
    blind: RummiBlindState(targetScore: 999, boardMovesRemaining: 3),
  );
  session.board.setCell(0, 0, const Tile(color: TileColor.red, number: 7));
  final moveFail = session.tryMoveBoardTile(
    fromRow: 0,
    fromCol: 0,
    toRow: 0,
    toCol: 1,
  );
  expect(moveFail, isNull);

  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'undo_seal',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: ['undo_seal'],
    );

  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.battle,
    difficulty: base.difficulty,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    ),
  );
}

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(text).evaluate().isNotEmpty) return;
  }
  final visibleTexts = find
      .byType(Text)
      .evaluate()
      .map((element) {
        final widget = element.widget as Text;
        return widget.data ?? widget.textSpan?.toPlainText() ?? '';
      })
      .where((value) => value.isNotEmpty)
      .join(' | ');
  final exception = tester.takeException();
  fail(
    'Expected to find "$text". Visible text: $visibleTexts'
    '${exception == null ? '' : '\nPending exception: $exception'}',
  );
}

Future<void> _disposeGameView(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}
