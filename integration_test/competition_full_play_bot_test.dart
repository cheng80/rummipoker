import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/main.dart' as app;
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_catalog_loader.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/router.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/views/game_view.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

import 'competition_bot_policy.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'competition bot runs through real browser UI',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

      final bot = _CompetitionFullPlayBot(
        tester: tester,
        config: _ContestBotConfig.fromEnvironment(),
      );
      await bot.run();
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

enum _ContestBotMode { full, sub }

enum _ContestBotScene { stationSelect, battle, cashOut, market, runComplete }

class _ContestBotConfig {
  const _ContestBotConfig({
    required this.mode,
    required this.seed,
    required this.maxBattleActions,
    required this.maxGameOverRetries,
    required this.resumeActiveRun,
    required this.resumeSaveBase64,
    required this.actionDelay,
    required this.targetStage,
    required this.targetTierName,
    required this.targetScene,
    required this.requiredEvidence,
  });

  factory _ContestBotConfig.fromEnvironment() {
    const modeValue = String.fromEnvironment(
      'CONTEST_BOT_MODE',
      defaultValue: 'full',
    );
    return _ContestBotConfig(
      mode: modeValue == 'sub' ? _ContestBotMode.sub : _ContestBotMode.full,
      seed: const int.fromEnvironment('CONTEST_BOT_SEED', defaultValue: 91460),
      maxBattleActions: const int.fromEnvironment(
        'CONTEST_BOT_MAX_BATTLE_ACTIONS',
        defaultValue: 420,
      ),
      maxGameOverRetries: const int.fromEnvironment(
        'CONTEST_BOT_MAX_GAME_OVER_RETRIES',
        defaultValue: 24,
      ),
      resumeActiveRun: const bool.fromEnvironment(
        'CONTEST_BOT_RESUME_ACTIVE_RUN',
      ),
      resumeSaveBase64: const String.fromEnvironment(
        'CONTEST_BOT_RESUME_SAVE_B64',
      ),
      actionDelay: Duration(
        milliseconds: const int.fromEnvironment(
          'CONTEST_BOT_ACTION_DELAY_MS',
          defaultValue: 250,
        ),
      ),
      targetStage: const int.fromEnvironment(
        'CONTEST_SUB_TARGET_STAGE',
        defaultValue: 1,
      ),
      targetTierName: const String.fromEnvironment(
        'CONTEST_SUB_TARGET_TIER',
        defaultValue: 'boss',
      ),
      targetScene: _parseScene(
        const String.fromEnvironment(
          'CONTEST_SUB_TARGET_SCENE',
          defaultValue: 'cashOut',
        ),
      ),
      requiredEvidence: const String.fromEnvironment(
        'CONTEST_SUB_REQUIRED_EVIDENCE',
      ),
    );
  }

  final _ContestBotMode mode;
  final int seed;
  final int maxBattleActions;
  final int maxGameOverRetries;
  final bool resumeActiveRun;
  final String resumeSaveBase64;
  final Duration actionDelay;
  final int targetStage;
  final String targetTierName;
  final _ContestBotScene targetScene;
  final String requiredEvidence;

  String get logPrefix => mode == _ContestBotMode.full
      ? 'CONTEST_FULL_RUN_BOT'
      : 'CONTEST_SUB_RUN_BOT';

  bool get isFullRun => mode == _ContestBotMode.full;

  bool get needsMarketPurchase =>
      isFullRun || requiredEvidence == 'market_purchase';

  bool get needsItemPurchase =>
      isFullRun || requiredEvidence == 'item_purchase';

  bool get needsItemUse => isFullRun || requiredEvidence == 'item_use';

  BlindTier get targetTier => switch (targetTierName) {
    'small' => BlindTier.small,
    'big' => BlindTier.big,
    'boss' => BlindTier.boss,
    _ => BlindTier.boss,
  };

  bool matchesTarget({required int stage, required BlindTier tier}) {
    if (isFullRun) return stage == 8 && tier == BlindTier.boss;
    return stage >= targetStage && tier == targetTier;
  }

  static _ContestBotScene _parseScene(String value) {
    return switch (value) {
      'stationSelect' || 'StationSelect' => _ContestBotScene.stationSelect,
      'battle' || 'Battle' => _ContestBotScene.battle,
      'market' || 'Market' => _ContestBotScene.market,
      'runComplete' || 'RunComplete' => _ContestBotScene.runComplete,
      _ => _ContestBotScene.cashOut,
    };
  }
}

class _BattleItemChoice {
  const _BattleItemChoice({required this.slotIndex, required this.item});

  final int slotIndex;
  final ItemDefinition item;
}

/// 공모전 full-play gate용 실제 UI 조작 bot.
///
/// 판단은 `planner_v2`가 맡고, 전투/마켓/정산 진행은 Flutter Chrome 화면의
/// 버튼과 카드만 눌러 수행한다. debug fixture와 즉시 클리어 경로는 쓰지 않는다.
class _CompetitionFullPlayBot {
  _CompetitionFullPlayBot({required this.tester, required this.config});

  final WidgetTester tester;
  final _ContestBotConfig config;
  final CompetitionPlannerV2Policy battlePolicy =
      const CompetitionPlannerV2Policy();
  final List<String> log = <String>[];
  ItemCatalog? itemCatalog;

  bool boughtJester = false;
  bool boughtItem = false;
  bool usedItem = false;
  bool discardedHand = false;
  bool discardedBoard = false;
  bool movedBoard = false;
  int gameOverRetries = 0;

  Future<void> run() async {
    itemCatalog = await ItemCatalogLoader.loadFromAsset(AssetPaths.itemsCommon);
    await _startSeededRun();
    _syncEvidenceFromState();
    if (find.text('Station Select').evaluate().isNotEmpty &&
        _shouldStopAt(scene: _ContestBotScene.stationSelect)) {
      await _finishSubRun('target station select reached');
      return;
    }

    if (find.text('다음 Station').evaluate().isNotEmpty) {
      final progress = _readGameState().runProgress!;
      await _handleMarket(stage: progress.stageIndex);
      if (find.text('Station Select').evaluate().isNotEmpty &&
          _shouldStopAt(scene: _ContestBotScene.stationSelect)) {
        await _finishSubRun('target station select reached');
        return;
      }
    }

    if (find.text('드로우').evaluate().isEmpty) {
      await _chooseOpenBlind();
    }
    if (_shouldStopAtCurrentBattle()) {
      await _finishSubRun('target battle reached');
      return;
    }

    while (true) {
      await _playCurrentBattle();

      final state = _readGameState();
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      final stage = runProgress.stageIndex;

      if (_shouldStopAt(
        scene: _ContestBotScene.cashOut,
        stage: stage,
        tier: tier,
      )) {
        await _pumpUntilCashOutReady();
        await _finishSubRun('target cash-out reached');
        return;
      }

      await _handleCashOut(stage: stage, tier: tier);
      if (_shouldStopAt(
        scene: _ContestBotScene.market,
        stage: stage,
        tier: tier,
      )) {
        await _handleMarketEvidenceOnly(stage: stage);
        await _finishSubRun('target market reached');
        return;
      }

      if (config.isFullRun && stage == 8 && tier == BlindTier.boss) {
        break;
      }

      await _handleMarket(stage: stage);

      await _chooseOpenBlind();
      if (_shouldStopAtCurrentBattle()) {
        await _finishSubRun('target battle reached');
        return;
      }
    }

    expect(
      boughtJester,
      isTrue,
      reason: 'contest_full_run_bot must buy a Jester',
    );
    expect(boughtItem, isTrue, reason: 'contest_full_run_bot must buy an Item');
    expect(usedItem, isTrue, reason: 'contest_full_run_bot must use an Item');
    expect(
      discardedHand,
      isTrue,
      reason: 'contest_full_run_bot must discard a hand tile',
    );
    expect(
      discardedBoard,
      isTrue,
      reason: 'contest_full_run_bot must discard a board tile',
    );
    expect(
      movedBoard,
      isTrue,
      reason: 'contest_full_run_bot must move a board tile',
    );

    _printPassLog('S8 boss full run complete');
  }

  Future<void> _startSeededRun() async {
    app.main();
    await _pumpFor(const Duration(seconds: 5));
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;

    if (config.resumeActiveRun) {
      final restored = await _loadResumeRuntime();
      if (restored != null) {
        final route = restored.activeScene == ActiveRunScene.blindSelect
            ? RoutePaths.blindSelect
            : RoutePaths.game;
        appRouter.go(
          '$route?difficulty=${restored.difficulty.name}'
          '&modifier=${restored.runModifier.id}',
          extra: restored,
        );
        await _pumpFor(const Duration(seconds: 2));
        _record(
          'resumed active run '
          'scene=${restored.activeScene.name} '
          'S${restored.runProgress.stageIndex} '
          'tier=${restored.runProgress.currentStationBlindTierIndex}',
        );
        if (restored.activeScene == ActiveRunScene.shop) {
          await _pumpUntilVisible(find.text('다음 Station'));
          return;
        }
        if (restored.activeScene == ActiveRunScene.blindSelect) {
          await _pumpUntilVisible(find.text('Station Select'));
          return;
        }
        if (_isCashOutReady()) return;
        await _pumpUntilVisible(find.text('드로우'));
        return;
      }
      _record(
        'resume requested but no active run save found; starting seeded run',
      );
    }

    appRouter.go(
      '${RoutePaths.blindSelect}?seed=${config.seed}'
      '&difficulty=standard&modifier=basic',
    );
    await _pumpUntilVisible(find.text('Station Select'));
    log.add(
      'seed=${config.seed} difficulty=standard modifier=basic '
      'mode=${config.mode.name}',
    );
  }

  Future<ActiveRunRuntimeState?> _loadResumeRuntime() async {
    if (config.resumeSaveBase64.isNotEmpty) {
      final jsonString = utf8.decode(base64Decode(config.resumeSaveBase64));
      return ActiveRunSaveService.runtimeStateFromJson(jsonString);
    }
    return ActiveRunSaveService.loadActiveRun();
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
    for (var step = 0; step < config.maxBattleActions; step++) {
      if (_isCashOutReady()) {
        return;
      }
      if (await _retryGameOverIfVisible()) {
        continue;
      }

      if (await _tryUseBattleItem()) {
        await _pumpFor(config.actionDelay + const Duration(seconds: 2));
        continue;
      }

      final state = _readGameState();
      final session = state.session!;
      if (session.blind.scoreTowardBlind >= session.blind.targetScore) {
        await _pumpUntilCashOutReady();
        return;
      }
      final runProgress = state.runProgress!;
      final tier = BlindTier.values[runProgress.currentStationBlindTierIndex];
      if (await _tryExerciseBattleUtilityActions(session, runProgress, tier)) {
        await _pumpFor(config.actionDelay);
        continue;
      }

      final action = battlePolicy.chooseAction(
        session,
        jesters: runProgress.ownedJesters,
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      );

      _record(
        'S${runProgress.stageIndex} ${tier.name} action=$action '
        'score=${session.blind.scoreTowardBlind}/${session.blind.targetScore}',
      );

      switch (action.type) {
        case CompetitionBattleActionType.draw:
          final handCount = session.hand.length;
          await _tapText('드로우');
          await _pumpUntilState(
            (next) => next.session!.hand.length > handCount,
          );
          break;
        case CompetitionBattleActionType.place:
          final tile = session.hand[action.handIndex!];
          await _tapHandTile(tile.toString());
          await _tapBoardCell(action.row!, action.col!);
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) != null,
          );
          break;
        case CompetitionBattleActionType.confirm:
          final score = session.blind.scoreTowardBlind;
          final targetScore = session.blind.targetScore;
          await _tapTextUntilState(
            '확정\n하기',
            (next) =>
                _isCashOutReady() ||
                next.session!.blind.scoreTowardBlind > score,
          );
          if (_readGameState().session!.blind.scoreTowardBlind >= targetScore) {
            await _pumpUntilCashOutReady();
            return;
          }
          if (!_isCashOutReady()) {
            await _pumpUntilState(
              (next) => next.stageFlowPhase == GameStageFlowPhase.none,
            );
          }
          break;
        case CompetitionBattleActionType.discardHand:
          final tile = session.hand[action.handIndex!];
          final handCount = session.hand.length;
          final handDiscards = session.blind.handDiscardsRemaining;
          await _tapHandTile(tile.toString());
          await _tapText('손패\n버림');
          await _pumpUntilState(
            (next) =>
                next.session!.blind.handDiscardsRemaining < handDiscards ||
                next.session!.hand.length != handCount,
          );
          discardedHand = true;
          break;
        case CompetitionBattleActionType.discardBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('보드\n버림');
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) == null,
          );
          discardedBoard = true;
          break;
        case CompetitionBattleActionType.moveBoard:
          await _tapBoardCell(action.row!, action.col!);
          await _tapText('타일\n이동');
          await _tapBoardCell(action.toRow!, action.toCol!);
          await _pumpUntilVisible(find.text('보드 이동'));
          await _tapText('이동');
          await _pumpUntilState(
            (next) =>
                next.session!.board.cellAt(action.row!, action.col!) == null &&
                next.session!.board.cellAt(action.toRow!, action.toCol!) !=
                    null,
          );
          movedBoard = true;
          break;
        case CompetitionBattleActionType.stop:
          if (await _retryGameOverAfterStop(action.reason ?? 'stop')) {
            continue;
          }
          fail('battle bot stopped: ${action.reason}');
      }

      await _pumpFor(config.actionDelay);
    }

    final state = _readGameState();
    final progress = state.runProgress!;
    fail(
      'battle action cap reached at '
      'S${progress.stageIndex} '
      '${BlindTier.values[progress.currentStationBlindTierIndex].name}',
    );
  }

  Future<bool> _retryGameOverIfVisible() async {
    if (find.text('다시 도전').evaluate().isEmpty) return false;
    gameOverRetries++;
    if (gameOverRetries > config.maxGameOverRetries) {
      fail(
        'game over retry cap reached: '
        '$gameOverRetries/${config.maxGameOverRetries}',
      );
    }
    _record('game over -> retry $gameOverRetries/${config.maxGameOverRetries}');
    await _tapText('다시 도전');
    await _pumpUntilVisible(find.text('드로우'));
    return true;
  }

  Future<bool> _retryGameOverAfterStop(String reason) async {
    await _pumpFor(const Duration(seconds: 2));
    if (await _retryGameOverIfVisible()) return true;
    if (_isCashOutReady()) return true;
    return false;
  }

  Future<bool> _tryExerciseBattleUtilityActions(
    RummiPokerGridSession session,
    RummiRunProgress runProgress,
    BlindTier tier,
  ) async {
    if (!config.isFullRun) return false;
    if (!discardedHand) {
      final action = battlePolicy.chooseHandDiscard(session);
      if (action != null) {
        _record('S${runProgress.stageIndex} ${tier.name} utility=$action');
        final tile = session.hand[action.handIndex!];
        final handDiscards = session.blind.handDiscardsRemaining;
        await _tapHandTile(tile.toString());
        await _tapText('손패\n버림');
        await _pumpUntilState(
          (next) => next.session!.blind.handDiscardsRemaining < handDiscards,
        );
        discardedHand = true;
        return true;
      }
    }

    if (!movedBoard) {
      final action = battlePolicy.chooseBoardMove(session);
      if (action != null) {
        _record('S${runProgress.stageIndex} ${tier.name} utility=$action');
        await _tapBoardCell(action.row!, action.col!);
        await _tapText('타일\n이동');
        await _tapBoardCell(action.toRow!, action.toCol!);
        await _pumpUntilVisible(find.text('보드 이동'));
        await _tapText('이동');
        await _pumpUntilState(
          (next) =>
              next.session!.board.cellAt(action.row!, action.col!) == null &&
              next.session!.board.cellAt(action.toRow!, action.toCol!) != null,
        );
        movedBoard = true;
        return true;
      }
    }

    if (!discardedBoard) {
      final action = battlePolicy.chooseBoardDiscard(
        session,
        minOccupancy: kBoardSize * 2,
      );
      if (action != null) {
        _record('S${runProgress.stageIndex} ${tier.name} utility=$action');
        await _tapBoardCell(action.row!, action.col!);
        await _tapText('보드\n버림');
        await _pumpUntilState(
          (next) =>
              next.session!.board.cellAt(action.row!, action.col!) == null,
        );
        discardedBoard = true;
        return true;
      }
    }

    return false;
  }

  Future<void> _handleCashOut({
    required int stage,
    required BlindTier tier,
  }) async {
    await _pumpUntilCashOutReady();
    await _pumpFor(const Duration(seconds: 3));

    if (stage == 8 && tier == BlindTier.boss) {
      await _tapText('런 완료');
      _record('S8 boss: run complete');
      await _pumpFor(const Duration(seconds: 3));
      return;
    }

    await _tapText('Market으로');
    _record('S$stage ${tier.name}: cashout -> market');
    await _pumpUntilVisible(find.text('다음 Station'));
  }

  bool _isCashOutReady() {
    return find.text('정산 완료').evaluate().isNotEmpty ||
        find.text('Market으로').evaluate().isNotEmpty ||
        find.text('런 완료').evaluate().isNotEmpty;
  }

  Future<void> _pumpUntilCashOutReady({
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (_isCashOutReady()) return;
      if (await _retryGameOverIfVisible()) return;
    }
    final state = _tryReadGameState();
    final session = state?.session;
    fail(
      'Timed out waiting for cash-out UI '
      '(phase=${state?.stageFlowPhase}, '
      'score=${session?.blind.scoreTowardBlind}/${session?.blind.targetScore})',
    );
  }

  Future<void> _handleMarket({required int stage}) async {
    await _handleMarketEvidenceOnly(stage: stage);

    await _tapPrimaryActionUntilAnyVisible('다음 Station', [
      find.text('Station Select'),
    ]);
  }

  Future<void> _handleMarketEvidenceOnly({required int stage}) async {
    await _buyJestersIfPossible(stage);
    await _buyQuickSlotItemIfNeeded(stage);
    await _useMarketItemIfVisible(stage);
  }

  void _syncEvidenceFromState() {
    final state = _tryReadGameState();
    if (state == null) return;
    final progress = state.runProgress;
    if (progress == null) return;
    boughtJester = boughtJester || progress.boughtJesterIds.isNotEmpty;
    boughtItem = boughtItem || progress.boughtItemIds.isNotEmpty;
  }

  Future<void> _buyJestersIfPossible(int stage) async {
    if (!config.needsMarketPurchase && !config.isFullRun) return;
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Jester');

    for (var attempt = 0; attempt < 6; attempt++) {
      final state = _readGameState();
      final market = state.marketView;
      final progress = state.runProgress;
      if (market == null || progress == null || market.offers.isEmpty) return;

      final offerIndex = market.offers.indexWhere(
        (offer) => offer.isAffordable,
      );
      if (offerIndex < 0) return;
      final offer = market.offers[offerIndex];
      final jesterSlotsFull =
          market.ownedEntries.length >= progress.jesterSlotCapacity();
      if (jesterSlotsFull) {
        final canBuyAfterSelling = market.ownedEntries.any(
          (entry) => market.gold + entry.sellPrice >= offer.price,
        );
        if (!canBuyAfterSelling) return;
        if (!await _sellSelectedJesterIfVisible(stage)) return;
      }

      if (!await _selectJesterOfferByPrice(offer.price)) return;
      if (find.text('구매').evaluate().isEmpty) return;
      await _tapText('구매');
      boughtJester = true;
      _record('S$stage market: bought Jester');
      await _pumpFor(const Duration(seconds: 2));
    }
  }

  Future<bool> _sellSelectedJesterIfVisible(int stage) async {
    if (find.text('판매').evaluate().isEmpty) return false;
    await _tapText('판매');
    _record('S$stage market: sold Jester for slot');
    await _pumpFor(const Duration(seconds: 2));
    return true;
  }

  Future<bool> _selectJesterOfferByPrice(int price) async {
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Jester');
    final priceFinder = find.text('${price}G');
    if (priceFinder.evaluate().isEmpty) return false;
    await tester.tap(priceFinder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 600));
    return true;
  }

  Future<void> _buyQuickSlotItemIfNeeded(int stage) async {
    if (!config.needsItemPurchase && !config.isFullRun) return;
    if (boughtItem) return;
    await _tapTextIfVisible('Jester / Slots');
    await _tapTextIfVisible('Q-Slot');
    if (find.text('구매').evaluate().isEmpty) return;
    await _tapText('구매');
    boughtItem = true;
    _record('S$stage market: bought Item');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<void> _useMarketItemIfVisible(int stage) async {
    if (!config.needsItemUse && !config.isFullRun) return;
    if (usedItem || find.text('사용').evaluate().isEmpty) return;
    await _tapText('사용');
    usedItem = true;
    _record('S$stage market: used Item');
    await _pumpFor(const Duration(seconds: 2));
  }

  Future<bool> _tryUseBattleItem() async {
    if (!config.needsItemUse && !config.isFullRun) return false;
    if (usedItem) return false;
    final state = _readGameState();
    final inventory = state.runProgress!.itemInventory;
    if (inventory.quickSlotItemIds.isEmpty) return false;
    final choice = _chooseBattleItemToUse(state);
    if (choice == null) return false;

    await _tapTextIfVisible('Slots');
    final slotLabel = find.text('Q${choice.slotIndex + 1}');
    if (slotLabel.evaluate().isEmpty) return false;
    await tester.tap(slotLabel.first);
    await _pumpFor(const Duration(milliseconds: 500));
    if (find.text('사용').evaluate().isEmpty) return false;
    await _tapText('사용');
    usedItem = true;
    _record(
      'S${state.runProgress!.stageIndex} '
      '${BlindTier.values[state.runProgress!.currentStationBlindTierIndex].name}: '
      'used battle Item ${choice.item.id} op=${choice.item.effect.op}',
    );
    await _pumpFor(const Duration(seconds: 1));
    return true;
  }

  _BattleItemChoice? _chooseBattleItemToUse(GameSessionState state) {
    final catalog = itemCatalog;
    final session = state.session;
    final runProgress = state.runProgress;
    if (catalog == null || session == null || runProgress == null) return null;
    final inventory = runProgress.itemInventory;
    for (var index = 0; index < inventory.quickSlotItemIds.length; index++) {
      final itemId = inventory.quickSlotItemIds[index];
      final item = catalog.findById(itemId);
      if (item == null || !_canUseBattleItemNow(item, session, runProgress)) {
        continue;
      }
      return _BattleItemChoice(slotIndex: index, item: item);
    }
    return null;
  }

  bool _canUseBattleItemNow(
    ItemDefinition item,
    RummiPokerGridSession session,
    RummiRunProgress runProgress,
  ) {
    if (item.placement != ItemPlacement.quickSlot || !item.usableInBattle) {
      return false;
    }
    final hasItem = runProgress.itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!hasItem) return false;

    return switch (item.effect.op) {
      'add_board_discard' ||
      'add_hand_discard' ||
      'add_board_move' ||
      'chips_bonus' ||
      'mult_bonus' ||
      'xmult_bonus' ||
      'temporary_overlap_cap_bonus' ||
      'add_percent_of_first_confirm_score' => true,
      'mark_next_board_move_bonus' => session.blind.boardMovesRemaining > 0,
      'undo_last_board_move' => session.boardMoveHistory.isNotEmpty,
      'draw_if_hand_empty' => session.hand.isEmpty && session.canDrawFromDeck,
      _ => false,
    };
  }

  bool _shouldStopAt({
    required _ContestBotScene scene,
    int? stage,
    BlindTier? tier,
  }) {
    if (config.isFullRun || scene != config.targetScene) return false;
    if (stage == null || tier == null) return true;
    return config.matchesTarget(stage: stage, tier: tier);
  }

  Future<void> _finishSubRun(String reason) async {
    await _saveBotCheckpoint();
    if (config.requiredEvidence == 'market_purchase') {
      expect(
        boughtJester,
        isTrue,
        reason: 'contest_sub_run_bot needs purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_purchase') {
      expect(
        boughtItem,
        isTrue,
        reason: 'contest_sub_run_bot needs item purchase evidence',
      );
    }
    if (config.requiredEvidence == 'item_use') {
      expect(
        usedItem,
        isTrue,
        reason: 'contest_sub_run_bot needs item use evidence',
      );
    }
    _printPassLog(reason);
  }

  Future<void> _saveBotCheckpoint() async {
    final state = _readGameState();
    final session = state.session;
    final runProgress = state.runProgress;
    final stageStartSnapshot = state.stageStartSnapshot;
    if (session == null || runProgress == null || stageStartSnapshot == null) {
      return;
    }
    final scene = find.text('Station Select').evaluate().isNotEmpty
        ? ActiveRunScene.blindSelect
        : find.text('다음 Station').evaluate().isNotEmpty
        ? ActiveRunScene.shop
        : ActiveRunScene.battle;
    final runtime = ActiveRunRuntimeState(
      activeScene: scene,
      difficulty: NewRunDifficulty.standard,
      runModifier: state.runModifier,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
    await ActiveRunSaveService.saveRuntimeState(runtime);
    final checkpointJson = ActiveRunSaveService.runtimeStateToJson(runtime);
    final checkpointBase64 = base64Encode(utf8.encode(checkpointJson));
    // 스크립트가 다음 resume 실행에 주입할 수 있도록 한 줄 checkpoint를 남긴다.
    debugPrint('CONTEST_BOT_CHECKPOINT_B64:$checkpointBase64');
    _record(
      'checkpoint saved scene=${scene.name} '
      'S${runProgress.stageIndex} '
      'tier=${runProgress.currentStationBlindTierIndex}',
    );
  }

  bool _shouldStopAtCurrentBattle() {
    if (config.isFullRun || config.targetScene != _ContestBotScene.battle) {
      return false;
    }
    final state = _readGameState();
    final progress = state.runProgress!;
    return config.matchesTarget(
      stage: progress.stageIndex,
      tier: BlindTier.values[progress.currentStationBlindTierIndex],
    );
  }

  void _printPassLog(String stopReason) {
    debugPrint('${config.logPrefix}_PASS');
    debugPrint('${config.logPrefix}: stop_reason=$stopReason');
    for (final entry in log) {
      debugPrint('${config.logPrefix}: $entry');
    }
  }

  void _record(String entry) {
    log.add(entry);
    debugPrint('${config.logPrefix}: $entry');
  }

  GameSessionState _readGameState() {
    final state = _tryReadGameState();
    expect(state, isNotNull);
    return state!;
  }

  GameSessionState? _tryReadGameState() {
    final gameViewFinder = find.byType(GameView, skipOffstage: false);
    if (gameViewFinder.evaluate().isEmpty) return null;
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
    await tester.tap(finder.first, warnIfMissed: false);
  }

  Future<void> _tapBoardCell(int row, int col) async {
    await tester.tap(
      find.byKey(ValueKey('board-cell-$row-$col')),
      warnIfMissed: false,
    );
  }

  Future<void> _tapText(String text) async {
    final finder = _buttonOrTextFinder(text);
    await _pumpUntilVisible(finder);
    await tester.tap(finder.first, warnIfMissed: false);
  }

  Future<void> _tapPrimaryActionUntilAnyVisible(
    String actionText,
    List<Finder> resultFinders, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (resultFinders.any((finder) => finder.evaluate().isNotEmpty)) return;

      final actionFinder = _buttonOrTextFinder(actionText);
      if (actionFinder.evaluate().isNotEmpty) {
        // 동일 라벨이 transition 뒤쪽 위젯 트리에 남는 경우가 있어 하단 주요 액션은
        // 현재 route에서 마지막으로 그려진 버튼을 우선 누른다.
        await tester.tap(actionFinder.last, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 800));
      }
    }
    fail('Timed out waiting for $resultFinders after tapping "$actionText"');
  }

  Future<void> _tapTextIfVisible(String text) async {
    final finder = _buttonOrTextFinder(text);
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.first, warnIfMissed: false);
    await _pumpFor(const Duration(milliseconds: 500));
  }

  Future<void> _tapTextUntilState(
    String actionText,
    bool Function(GameSessionState state) predicate, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (predicate(_readGameState())) return;
      if (await _retryGameOverIfVisible()) return;

      final actionFinder = _buttonOrTextFinder(actionText);
      if (actionFinder.evaluate().isNotEmpty) {
        await tester.tap(actionFinder.first, warnIfMissed: false);
        await _pumpFor(const Duration(milliseconds: 700));
      }
    }
    fail('Timed out waiting for game state update after tapping "$actionText"');
  }

  Finder _buttonOrTextFinder(String text) {
    final actionButton = find.widgetWithText(GameActionButton, text);
    if (actionButton.evaluate().isNotEmpty) return actionButton;
    return find.text(text);
  }

  Future<void> _pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(minutes: 2),
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

  Future<void> _pumpUntilState(
    bool Function(GameSessionState state) predicate, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
      if (predicate(_readGameState())) return;
      if (await _retryGameOverIfVisible()) return;
    }
    fail('Timed out waiting for game state update');
  }
}
