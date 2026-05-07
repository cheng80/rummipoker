import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/main.dart' as app;
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/router.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/views/game_view.dart';

import 'competition_bot_policy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'competition bot clears S1-S8 through real browser UI',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

      final bot = _CompetitionFullPlayBot(
        tester: tester,
        seed: 91460,
        maxBattleActions: 420,
      );
      await bot.run();
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

/// 공모전 full-play gate용 실제 UI 조작 bot.
///
/// 판단은 `planner_v2`가 맡고, 전투/마켓/정산 진행은 Flutter Chrome 화면의
/// 버튼과 카드만 눌러 수행한다. debug fixture와 즉시 클리어 경로는 쓰지 않는다.
class _CompetitionFullPlayBot {
  _CompetitionFullPlayBot({
    required this.tester,
    required this.seed,
    required this.maxBattleActions,
  });

  final WidgetTester tester;
  final int seed;
  final int maxBattleActions;
  final CompetitionPlannerV2Policy battlePolicy =
      const CompetitionPlannerV2Policy();
  final List<String> log = <String>[];

  bool boughtJester = false;
  bool boughtItem = false;
  bool usedItem = false;

  Future<void> run() async {
    await _startSeededRun();
    await _chooseOpenBlind();

    while (true) {
      await _playCurrentBattle();

      final state = _readGameState();
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      final stage = runProgress.stageIndex;

      await _handleCashOut(stage: stage, tier: tier);
      if (stage == 8 && tier == BlindTier.boss) {
        break;
      }

      await _handleMarket(stage: stage);
      await _chooseOpenBlind();
    }

    expect(boughtJester, isTrue, reason: 'full-play bot must buy a Jester');
    expect(boughtItem, isTrue, reason: 'full-play bot must buy an Item');
    expect(usedItem, isTrue, reason: 'full-play bot must use an Item');

    debugPrint('COMPETITION_FULL_PLAY_BOT_PASS');
    for (final entry in log) {
      debugPrint('COMPETITION_FULL_PLAY_BOT: $entry');
    }
  }

  Future<void> _startSeededRun() async {
    app.main();
    await _pumpFor(const Duration(seconds: 5));
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;

    appRouter.go(
      '${RoutePaths.blindSelect}?seed=$seed&difficulty=standard&modifier=basic',
    );
    await _pumpUntilVisible(find.text('Station Select'));
    log.add('seed=$seed difficulty=standard modifier=basic');
  }

  Future<void> _chooseOpenBlind() async {
    await _pumpUntilVisible(find.text('Station Select'));
    final openButton = find.byIcon(Icons.play_arrow_rounded).first;
    await tester.tap(openButton);
    await _pumpFor(const Duration(seconds: 2));

    if (find.text('전투 시작').evaluate().isNotEmpty) {
      await tester.tap(find.text('전투 시작'));
      await _pumpFor(const Duration(seconds: 1));
    }
    await _pumpUntilVisible(find.text('드로우'));
  }

  Future<void> _playCurrentBattle() async {
    for (var step = 0; step < maxBattleActions; step++) {
      if (find.text('정산 완료').evaluate().isNotEmpty) {
        return;
      }

      await _tryUseBattleItem();

      final state = _readGameState();
      final session = state.session!;
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      final action = battlePolicy.chooseAction(
        session,
        jesters: runProgress.ownedJesters,
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      );

      log.add(
        'S${runProgress.stageIndex} ${tier.name} action=$action '
        'score=${session.blind.scoreTowardBlind}/${session.blind.targetScore}',
      );

      switch (action.type) {
        case CompetitionBattleActionType.draw:
          await _tapText('드로우');
          break;
        case CompetitionBattleActionType.place:
          final tile = session.hand[action.handIndex!];
          await _tapHandTile(tile.toString());
          await _tapBoardCell(action.row!, action.col!);
          break;
        case CompetitionBattleActionType.confirm:
          await _tapText('확정\n하기');
          break;
        case CompetitionBattleActionType.discardBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('보드\n버림');
          break;
        case CompetitionBattleActionType.stop:
          fail('battle bot stopped: ${action.reason}');
      }

      await _pumpFor(const Duration(milliseconds: 900));
    }

    final state = _readGameState();
    final progress = state.runProgress!;
    fail(
      'battle action cap reached at '
      'S${progress.stageIndex} '
      '${BlindTier.values[progress.currentStationBlindTierIndex].name}',
    );
  }

  Future<void> _handleCashOut({
    required int stage,
    required BlindTier tier,
  }) async {
    await _pumpUntilVisible(find.text('정산 완료'));
    await _pumpFor(const Duration(seconds: 3));

    if (stage == 8 && tier == BlindTier.boss) {
      await _tapText('런 완료');
      log.add('S8 boss: run complete');
      await _pumpFor(const Duration(seconds: 3));
      return;
    }

    await _tapText('Market으로');
    log.add('S$stage ${tier.name}: cashout -> market');
    await _pumpUntilVisible(find.text('다음 Station'));
  }

  Future<void> _handleMarket({required int stage}) async {
    await _buyJesterIfNeeded(stage);
    await _buyQuickSlotItemIfNeeded(stage);
    await _useMarketItemIfVisible(stage);

    await _tapText('다음 Station');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<void> _buyJesterIfNeeded(int stage) async {
    if (boughtJester || find.text('구매').evaluate().isEmpty) return;
    await _tapText('구매');
    boughtJester = true;
    log.add('S$stage market: bought Jester');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<void> _buyQuickSlotItemIfNeeded(int stage) async {
    if (boughtItem) return;
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Q-Slot');
    if (find.text('구매').evaluate().isEmpty) return;
    await _tapText('구매');
    boughtItem = true;
    log.add('S$stage market: bought Item');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<void> _useMarketItemIfVisible(int stage) async {
    if (usedItem || find.text('사용').evaluate().isEmpty) return;
    await _tapText('사용');
    usedItem = true;
    log.add('S$stage market: used Item');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<void> _tryUseBattleItem() async {
    if (usedItem) return;
    final state = _readGameState();
    final inventory = state.runProgress!.itemInventory;
    if (inventory.quickSlotItemIds.isEmpty) return;

    await _tapTextIfVisible('Slots');
    final slotLabel = find.text('Q1');
    if (slotLabel.evaluate().isEmpty) return;
    await tester.tap(slotLabel.first);
    await _pumpFor(const Duration(milliseconds: 500));
    if (find.text('사용').evaluate().isEmpty) return;
    await _tapText('사용');
    usedItem = true;
    log.add(
      'S${state.runProgress!.stageIndex} '
      '${BlindTier.values[state.runProgress!.currentStationBlindTierIndex].name}: '
      'used battle Item ${inventory.quickSlotItemIds.first}',
    );
    await _pumpFor(const Duration(seconds: 1));
  }

  GameSessionState _readGameState() {
    final gameViewFinder = find.byType(GameView, skipOffstage: false);
    expect(gameViewFinder, findsWidgets);
    final gameView = tester.widget<GameView>(gameViewFinder.first);
    final element = tester.element(gameViewFinder.first);
    final container = ProviderScope.containerOf(element);
    final args = GameSessionArgs(
      runSeed: gameView.runSeed,
      restoredRun: gameView.restoredRun,
      debugFixtureId: gameView.debugFixtureId,
      difficulty: gameView.difficulty,
      runModifier: gameView.runModifier,
      blindTier: gameView.blindTier,
    );
    return container.read(gameSessionNotifierProvider(args));
  }

  Future<void> _tapHandTile(String tileKey) async {
    final finder = find.byKey(ValueKey('settled-$tileKey'));
    await _pumpUntilVisible(finder);
    await tester.tap(finder.first);
  }

  Future<void> _tapBoardCell(int row, int col) async {
    await tester.tap(find.byKey(ValueKey('board-cell-$row-$col')));
  }

  Future<void> _tapText(String text) async {
    final finder = find.text(text);
    await _pumpUntilVisible(finder);
    await tester.tap(finder.first);
  }

  Future<void> _tapTextIfVisible(String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.first);
    await _pumpFor(const Duration(milliseconds: 500));
  }

  Future<void> _pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 18),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> _pumpFor(Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}
