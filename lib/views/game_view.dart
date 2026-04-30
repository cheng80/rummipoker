import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/item_catalog_loader.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/owned_content_instance.dart';
import '../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../logic/rummi_poker_grid/rummi_settlement_facade.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../providers/features/rummi_poker_grid/game_session_state.dart';
import '../resources/asset_paths.dart';
import '../resources/item_translation_scope.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/blind_selection_setup.dart';
import '../services/new_run_setup.dart';
import '../services/run_progression_service.dart';
import '../utils/common_ui.dart';
import 'game/widgets/game_cashout_widgets.dart';
import 'game/widgets/game_hand_zone.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_options_dialog.dart';
import 'game/widgets/game_shop_screen.dart';
import 'game/widgets/game_shared_widgets.dart';
import 'game/widgets/game_tile_choice_dialog.dart';
import '../widgets/phone_frame_scaffold.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.runSeed,
    this.restoredRun,
    this.debugFixtureId,
    this.difficulty = NewRunDifficulty.standard,
    this.blindTier = BlindTier.small,
    this.autoAdvanceMarketOnLoad = false,
    this.autoEnterMarketOnCashOut = false,
    this.autoCashOutLoopOnLoad = false,
    this.debugCompleteRunOnClear = false,
    this.debugCompleteRunOnLoad = false,
    this.debugAutoUseItemId,
    this.debugStartItemShop = false,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final NewRunDifficulty difficulty;
  final BlindTier blindTier;
  final bool autoAdvanceMarketOnLoad;
  final bool autoEnterMarketOnCashOut;
  final bool autoCashOutLoopOnLoad;
  final bool debugCompleteRunOnClear;
  final bool debugCompleteRunOnLoad;
  final String? debugAutoUseItemId;
  final bool debugStartItemShop;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with WidgetsBindingObserver {
  static const Duration _itemEffectFeedbackDuration = Duration(seconds: 2);

  static const List<String> _shopInspectOfferIds = [
    'green_jester',
    'popcorn',
    'ice_cream',
    'supernova',
    'ride_the_bus',
    'golden_jester',
    'egg',
    'delayed_gratification',
  ];

  late final GameSessionArgs _gameArgs;
  bool _persistRetrySnapshotOnSave = false;
  bool _autoCashOutLoopStarted = false;
  bool _debugAutoUseItemStarted = false;
  late bool _shouldResumeMarketOnCatalogLoad;
  ItemCatalog? _itemCatalog;
  RummiBattleItemSlotView? _selectedBattleItemSlot;
  _ItemEffectFeedback? _itemEffectFeedback;
  int _itemEffectFeedbackTick = 0;
  bool _boardMoveMode = false;
  bool _nextStationTransitionVisible = false;
  RummiCashOutBreakdown? _settlementToMarketTransition;
  int? _pendingBoardMoveSourceRow;
  int? _pendingBoardMoveSourceCol;
  bool _bossConstraintIntroShown = false;

  GameSessionNotifier get _gameNotifier =>
      ref.read(gameSessionNotifierProvider(_gameArgs).notifier);
  GameSessionState get _gameState =>
      ref.read(gameSessionNotifierProvider(_gameArgs));
  RummiBattleRuntimeFacade get _battleView => _gameState.battleView!;
  RummiBattleRuntimeFacade get _battleViewWithItemSlots {
    final battle = _battleView;
    final catalog = _itemCatalog;
    final runProgress = _gameState.runProgress;
    final inventory = runProgress?.itemInventory;
    if (catalog == null ||
        runProgress == null ||
        inventory == null ||
        inventory.ownedItems.isEmpty) {
      return battle;
    }
    final quickSlotCapacity = runProgress.quickSlotCapacity(
      itemCatalog: catalog,
    );

    final itemInstances = OwnedContentInstances.itemInstances(
      inventory: inventory,
      catalog: catalog,
    );
    final instancesById = {
      for (final instance in itemInstances) instance.id: instance,
    };
    final itemSlots = <RummiBattleItemSlotView>[];
    var slotIndex = 0;

    for (final itemId in inventory.quickSlotItemIds.take(quickSlotCapacity)) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'Q${slotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
    }

    var passiveSlotIndex = 0;
    for (final itemId in inventory.passiveRelicIds.take(
      kBattlePassiveSlotDisplayCount,
    )) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'P${passiveSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      passiveSlotIndex += 1;
    }

    var toolSlotIndex = 0;
    for (final instance in itemInstances.where(
      (item) => item.placement == ItemPlacement.inventory,
    )) {
      if (toolSlotIndex >= kBattleToolSlotDisplayCount) break;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'T${toolSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      toolSlotIndex += 1;
    }

    var gearSlotIndex = 0;
    for (final itemId in inventory.equippedItemIds.take(
      kBattleGearSlotDisplayCount,
    )) {
      final instance = instancesById[itemId];
      if (instance == null) continue;
      itemSlots.add(
        RummiBattleItemSlotView.fromInstance(
          slotIndex: slotIndex,
          slotLabel: 'G${gearSlotIndex + 1}',
          instance: instance,
        ),
      );
      slotIndex += 1;
      gearSlotIndex += 1;
    }

    return battle.withItemSlots(itemSlots);
  }

  RummiStationRuntimeFacade get _stationView => _gameState.stationView!;
  RummiMarketRuntimeFacade get _marketView => _gameState.marketView!;
  Tile? get _selectedHandTile => _gameState.selectedHandTile;
  int? get _selectedBoardRow => _gameState.selectedBoardRow;
  int? get _selectedBoardCol => _gameState.selectedBoardCol;
  int? get _selectedJesterOverlayIndex => _gameState.selectedJesterOverlayIndex;
  GameStageFlowPhase get _stageFlowPhase => _gameState.stageFlowPhase;
  int get _stageScoreAdded => _gameState.stageScoreAdded;
  ConfirmedLineBreakdown? get _activeSettlementLine =>
      _gameState.activeSettlementLine;
  ScoringPresentationStep get _activeSettlementStep =>
      _gameState.activeSettlementStep;
  int? get _activeSettlementEffectIndex =>
      _gameState.activeSettlementEffectIndex;
  List<int> get _activeSettlementEffectIndexes =>
      _gameState.activeSettlementEffectIndexes;
  int? get _settlementGoalDisplayScore => _gameState.settlementGoalDisplayScore;
  Map<String, Tile> get _settlementBoardSnapshot =>
      _gameState.settlementBoardSnapshot;
  int get _settlementSequenceTick => _gameState.settlementSequenceTick;
  bool get _isUiLocked => _gameState.isUiLocked;
  bool get _isDebugFixtureRun => _gameState.debugFixtureId != null;
  bool get _isBattleInputLocked => _isUiLocked || _boardMoveMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameArgs = GameSessionArgs(
      runSeed: widget.runSeed,
      restoredRun: widget.restoredRun,
      debugFixtureId: widget.debugFixtureId,
      difficulty: widget.difficulty,
      blindTier: widget.blindTier,
    );
    _shouldResumeMarketOnCatalogLoad =
        widget.restoredRun?.activeScene == ActiveRunScene.shop;
    // BGM·카탈로그 로드를 첫 프레임 이후로 지연 — 전환 시 프레임 드롭 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundManager.playBgm(AssetPaths.bgmMain);
      _loadJesterCatalog();
      _loadItemCatalog();
      if (_isDebugFixtureRun) {
        showTopNotice(context, '디버그 픽스처 모드: 이어하기 저장은 남기지 않습니다.');
      }
      _showBossConstraintIntroIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _saveActiveRun();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.resumed:
        break;
    }
  }

  Future<void> _loadJesterCatalog() async {
    try {
      final catalog = await RummiJesterCatalogLoader.loadFromAsset(
        AssetPaths.jestersCommon,
      );
      if (!mounted) return;
      _gameNotifier.setJesterCatalog(catalog);
      await _saveActiveRun();
      if (widget.debugCompleteRunOnLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _completeRunAndReturnToTitle();
        });
        return;
      }
      if (widget.autoCashOutLoopOnLoad &&
          _isDebugFixtureRun &&
          !_autoCashOutLoopStarted) {
        _autoCashOutLoopStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _runAutoCashOutLoopOnLoad();
        });
      }
      if (_shouldResumeMarketOnCatalogLoad) {
        _shouldResumeMarketOnCatalogLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final nextStage = await _showShopScreen();
          if (!mounted) return;
          if (nextStage == true) {
            await _goToNextStationBlindSelect();
            return;
          }
          await _saveActiveRun();
          _gameNotifier.markDirty();
        });
      }
    } catch (_) {
      if (!mounted) return;
      _gameNotifier.setJesterCatalog(null);
    }
  }

  Future<void> _loadItemCatalog() async {
    try {
      final catalog = await ItemCatalogLoader.loadFromAsset(
        AssetPaths.itemsCommon,
      );
      if (!mounted) return;
      setState(() => _itemCatalog = catalog);
      _scheduleDebugAutoUseItem();
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemCatalog = null);
    }
  }

  Future<void> _showBossConstraintIntroIfNeeded() async {
    if (_bossConstraintIntroShown || !mounted) return;
    if (_gameState.activeRunScene != ActiveRunScene.battle) return;
    final modifier = _gameState.session?.blind.bossModifier;
    if (modifier == null) return;
    _bossConstraintIntroShown = true;
    await showGameFramedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD34E4E),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFFD0C8).withValues(alpha: 0.88),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    modifier.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      color: Colors.white.withValues(alpha: 0.96),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              modifier.ruleText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            GameChromeButton(
              label: '전투 시작',
              backgroundColor: const Color(0xFFF4A81D),
              foregroundColor: const Color(0xFF173126),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleDebugAutoUseItem() {
    final itemId = widget.debugAutoUseItemId;
    if (itemId == null || !_isDebugFixtureRun || _debugAutoUseItemStarted) {
      return;
    }
    _debugAutoUseItemStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RummiBattleItemSlotView? slot;
      for (final candidate in _battleViewWithItemSlots.itemSlots) {
        if (candidate.contentId == itemId) {
          slot = candidate;
          break;
        }
      }
      if (slot == null) {
        _showSnack('디버그 아이템을 찾지 못했습니다: $itemId');
        return;
      }
      _useBattleItem(slot);
    });
  }

  RummiMarketRuntimeFacade _readMarketViewWithItemOffers() {
    final catalog = _itemCatalog;
    final state = ref.read(gameSessionNotifierProvider(_gameArgs));
    final progress = state.runProgress;
    return progress == null
        ? state.marketView!
        : RummiMarketRuntimeFacade.fromRunProgress(
            progress,
            itemCatalog: catalog,
          );
  }

  Future<void> _saveActiveRun({ActiveRunScene? scene}) async {
    if (_isDebugFixtureRun) {
      return;
    }
    if (scene == null && _stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    if (scene != null) {
      _gameNotifier.setActiveRunScene(scene);
    }
    final runtime = _gameNotifier.buildSaveRuntimeState(
      scene: scene,
      difficulty: widget.difficulty,
      useStageStartSnapshotAsCurrent: _persistRetrySnapshotOnSave,
    );
    await ActiveRunSaveService.saveRuntimeState(runtime);
  }

  void _setDebugMaxHandSize(int value) {
    _gameNotifier.setDebugMaxHandSize(value);
    _saveActiveRun();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showTopNotice(context, message);
  }

  void _showItemEffectFeedback({
    required String title,
    required String detail,
    bool passive = false,
  }) {
    if (!mounted) return;
    final tick = _itemEffectFeedbackTick + 1;
    setState(() {
      _itemEffectFeedbackTick = tick;
      _itemEffectFeedback = _ItemEffectFeedback(
        title: title,
        detail: detail,
        passive: passive,
      );
    });
    unawaited(
      Future<void>.delayed(_itemEffectFeedbackDuration, () {
        if (!mounted || _itemEffectFeedbackTick != tick) return;
        setState(() => _itemEffectFeedback = null);
      }),
    );
  }

  Future<void> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '현재 Station 재시작',
      message:
          '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _restartFromStageSnapshot();
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
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _restartFromStageSnapshot() async {
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _exitAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await RunProgressionService.handleRunEnded(
      RunEndSummary(
        result: RunEndResult.expired,
        difficulty: widget.difficulty,
        reachedStageIndex: _battleView.stageIndex,
      ),
    );
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _completeRunAndReturnToTitle() async {
    _persistRetrySnapshotOnSave = false;
    await RunProgressionService.handleRunEnded(
      RunEndSummary(
        result: RunEndResult.completed,
        difficulty: widget.difficulty,
        reachedStageIndex: _battleView.stageIndex,
      ),
    );
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  void _showGameOver(List<RummiExpirySignal> signals) {
    if (!mounted) return;
    showGameOverDialog(
      context: context,
      signals: signals,
      onRetry: _restartFromStageSnapshot,
      onExit: _exitAfterGameOver,
    );
  }

  Future<bool> _afterAction() async {
    if (_stageFlowPhase != GameStageFlowPhase.none ||
        _stationView.objective.isMet) {
      return false;
    }
    if (await _tryApplyExpiryGuard()) {
      return false;
    }
    final signals = _gameNotifier.evaluateExpiry();
    if (signals.isEmpty) return false;
    _persistRetrySnapshotOnSave = true;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    if (!mounted) return true;
    _showGameOver(signals);
    return true;
  }

  Future<bool> _tryApplyExpiryGuard() async {
    final guardResult = _gameNotifier.applyExpiryGuard(
      itemCatalog: _itemCatalog,
    );
    if (guardResult == null) return false;
    _showSnack(guardResult.message);
    _showItemEffectFeedback(
      title: '안전망 발동',
      detail: guardResult.feedbackDetail,
      passive: true,
    );
    await _saveActiveRun(scene: ActiveRunScene.battle);
    return true;
  }

  void _clearSelections() {
    setState(() {
      _boardMoveMode = false;
      _pendingBoardMoveSourceRow = null;
      _pendingBoardMoveSourceCol = null;
    });
    _gameNotifier.clearSelections();
  }

  void _openJesterOverlay(int index) {
    if (_isBattleInputLocked) return;
    setState(() => _selectedBattleItemSlot = null);
    _gameNotifier.setSelectedJesterOverlayIndex(index);
  }

  void _closeJesterOverlay() {
    if (!mounted) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
  }

  void _sellOwnedJesterFromOverlay() {
    final ok = _gameNotifier.sellSelectedJesterOverlayFromState();
    if (!ok) return;
    _showSnack('제스터를 판매했습니다.');
  }

  void _openBattleItemOverlay(RummiBattleItemSlotView slot) {
    if (_isBattleInputLocked) return;
    _gameNotifier.setSelectedJesterOverlayIndex(null);
    setState(() => _selectedBattleItemSlot = slot);
  }

  void _closeBattleItemOverlay() {
    if (!mounted) return;
    setState(() => _selectedBattleItemSlot = null);
  }

  void _toggleHandTile(Tile tile) {
    if (_isBattleInputLocked) return;
    _gameNotifier.toggleSelectedHandTile(tile);
  }

  Future<void> _goToTitleAfterStoppingBgm() async {
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  void _onBoardCellTap(int row, int col) async {
    if (_isUiLocked) return;
    if (_boardMoveMode) {
      await _handleBoardMoveModeTap(row, col);
      return;
    }
    final result = _gameNotifier.tapBoardCell(row, col);
    if (result.failMessage != null) {
      _showSnack(result.failMessage!);
      return;
    }
    if (result.didPlaceTile) {
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      await _saveActiveRun();
    }
  }

  void _drawTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.drawTile();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedBoardTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedBoardTileFromState();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _discardSelectedHandTile() async {
    if (_isBattleInputLocked) return;
    final failReason = _gameNotifier.discardSelectedHandTileFromState();
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final didGameOver = await _afterAction();
    if (didGameOver) return;
    await _saveActiveRun();
  }

  void _useBattleItem(RummiBattleItemSlotView slot) async {
    if (_isBattleInputLocked) return;
    if (slot.item.effect.op == 'peek_deck_discard_one') {
      await _useDeckNeedleItem(slot);
      return;
    }
    final failReason = _gameNotifier.useBattleItem(slot.item);
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    _showSnack('$itemName 사용');
    _showItemEffectFeedback(
      title: itemName,
      detail: _battleItemFeedbackDetail(slot.item),
    );
    if (mounted) {
      setState(() => _selectedBattleItemSlot = null);
    }
    await _saveActiveRun();
  }

  Future<void> _useDeckNeedleItem(RummiBattleItemSlotView slot) async {
    final useResult = _gameNotifier.consumeBattleDeckPeekItem(slot.item);
    if (!useResult.isSuccess) {
      _showSnack(useResult.failMessage ?? '아이템을 사용할 수 없습니다.');
      return;
    }
    final itemName = ItemTranslationScope.of(
      context,
    ).resolveDisplayName(slot.contentId, slot.displayName);
    if (mounted) {
      setState(() => _selectedBattleItemSlot = null);
    }
    await _saveActiveRun();
    if (!mounted) return;

    final selectedIndex = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameTileChoiceDialog(
        title: '덱 확인',
        message: '선택한 한 장을 버리거나, 버림 없이 닫을 수 있습니다.',
        tiles: useResult.candidates,
        closeLabel: '닫기',
      ),
    );
    if (!mounted) return;
    if (selectedIndex == null) {
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      _showSnack('$itemName 사용');
      _showItemEffectFeedback(title: itemName, detail: '덱 확인');
      return;
    }

    final failReason = _gameNotifier.useBattleDeckPeekDiscardItem(
      slot.item,
      selectedIndex,
    );
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _showSnack('$itemName 사용');
    _showItemEffectFeedback(title: itemName, detail: '덱 타일 1장 제거');
    await _saveActiveRun();
  }

  String _battleItemFeedbackDetail(ItemDefinition item) {
    return switch (item.effect.op) {
      'add_board_discard' => '보드 버림 +${item.effect.value('amount') ?? 1}',
      'add_hand_discard' => '손패 버림 +${item.effect.value('amount') ?? 1}',
      'add_board_move' => '타일 이동 +${item.effect.value('amount') ?? 1}',
      'mark_next_board_move_bonus' => '다음 보드 이동 보너스 준비',
      'undo_last_board_move' => '마지막 이동 되돌림',
      'draw_if_hand_empty' => '타일 1장 드로우',
      'chips_bonus' => '다음 확정 Chips 보너스',
      'mult_bonus' => '다음 확정 Mult 보너스',
      'xmult_bonus' => '다음 확정 XMult 보너스',
      'temporary_overlap_cap_bonus' => '다음 확정 overlap 보너스',
      _ => '효과 적용',
    };
  }

  void _confirmLines() async {
    if (_isBattleInputLocked) return;
    final result = _gameNotifier.confirmLines();
    if (result == null) {
      if (await _tryApplyExpiryGuard()) return;
      final didGameOver = await _afterAction();
      if (didGameOver) return;
      _showSnack('확정할 족보 줄이 없습니다.');
      return;
    }
    final settlementGoalBaseScore = _stationView.objective.scoreTowardObjective;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.none,
      settlementGoalDisplayScore: settlementGoalBaseScore,
    );
    _gameNotifier.applyConfirmedScore(result.totalScore);
    await _saveActiveRun(scene: ActiveRunScene.battle);
    if (!mounted) return;

    await _runSettlementSequence(
      lines: result.lineBreakdowns,
      totalScore: result.totalScore,
      shouldClearAfter: result.stageCleared,
      settlementGoalBaseScore: settlementGoalBaseScore,
    );
    if (result.stageCleared) {
      return;
    }
    await _afterAction();
  }

  void _startBoardMoveMode() {
    if (_isUiLocked) return;
    final row = _selectedBoardRow;
    final col = _selectedBoardCol;
    if (row == null || col == null) {
      _showSnack('이동할 보드 타일을 먼저 선택하세요.');
      return;
    }
    if (_stationView.resources.boardMovesRemaining <= 0) {
      _showSnack('보드 이동 횟수가 없습니다.');
      return;
    }
    setState(() {
      _selectedBattleItemSlot = null;
      _boardMoveMode = true;
      _pendingBoardMoveSourceRow = row;
      _pendingBoardMoveSourceCol = col;
    });
  }

  void _cancelBoardMoveMode() {
    if (!mounted) return;
    setState(() {
      _boardMoveMode = false;
      _pendingBoardMoveSourceRow = null;
      _pendingBoardMoveSourceCol = null;
    });
  }

  Future<void> _handleBoardMoveModeTap(int row, int col) async {
    final fromRow = _pendingBoardMoveSourceRow;
    final fromCol = _pendingBoardMoveSourceCol;
    if (fromRow == null || fromCol == null) {
      _cancelBoardMoveMode();
      return;
    }
    if (row == fromRow && col == fromCol) {
      _cancelBoardMoveMode();
      return;
    }
    if (_battleView.board.cellAt(row, col) != null) {
      _showSnack('빈 칸으로만 이동할 수 있습니다.');
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: '보드 이동',
      message: '선택한 타일을 빈 칸으로 이동합니다.\n이동 횟수 1회를 사용합니다.',
      cancelLabel: '취소',
      confirmLabel: '이동',
      barrierDismissible: false,
    );
    if (!confirmed || !mounted) return;

    final hadSlideBonus =
        _gameState.session?.nextBoardMoveSlideBonusQueued ?? false;
    final failReason = _gameNotifier.moveBoardTile(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: row,
      toCol: col,
    );
    if (failReason != null) {
      _showSnack(failReason);
      return;
    }
    _cancelBoardMoveMode();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    _showSnack(hadSlideBonus ? '보드 이동 보너스가 발동했습니다.' : '타일을 이동했습니다.');
    if (hadSlideBonus) {
      _showItemEffectFeedback(title: 'Slide Wax', detail: '보드 이동 보너스 발동');
    }
    await _saveActiveRun();
  }

  Future<void> _runSettlementSequence({
    required List<ConfirmedLineBreakdown> lines,
    required int totalScore,
    required bool shouldClearAfter,
    required int settlementGoalBaseScore,
    int settlementGoalAppliedScore = 0,
    int index = 0,
  }) async {
    if (!mounted) return;
    if (lines.isEmpty || index >= lines.length) {
      _gameNotifier.setStageFlow(
        phase: GameStageFlowPhase.none,
        activeSettlementLine: null,
        activeSettlementStep: ScoringPresentationStep.none,
        activeSettlementEffectIndex: null,
        settlementGoalDisplayScore: null,
        settlementBoardSnapshot: const {},
      );
      if (shouldClearAfter) {
        SoundManager.playSfx(AssetPaths.sfxClear);
        await _runStageClearFlow(totalScore);
      } else {
        await _saveActiveRun(scene: ActiveRunScene.battle);
      }
      return;
    }

    final line = lines[index];
    final lineGoalStartScore =
        settlementGoalBaseScore + settlementGoalAppliedScore;
    final lineGoalDisplayScore =
        settlementGoalBaseScore + settlementGoalAppliedScore + line.finalScore;
    final jesterIds = {
      for (final entry in _marketView.ownedEntries) entry.card.id,
    };
    final jesterEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (jesterIds.contains(line.effects[i].jesterId)) i,
    ];
    final itemEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (!jesterIds.contains(line.effects[i].jesterId)) i,
    ];

    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.boardLine,
      settlementGoalDisplayScore: lineGoalStartScore,
      bump: true,
      delay: const Duration(milliseconds: 560),
    );
    if (!mounted) return;
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.handRank,
      settlementGoalDisplayScore: lineGoalStartScore,
      delay: const Duration(milliseconds: 720),
    );
    if (!mounted) return;
    if (line.overlapBonus > 0) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.overlap,
        settlementGoalDisplayScore: lineGoalStartScore,
        delay: const Duration(milliseconds: 680),
      );
      if (!mounted) return;
    }
    if (line.constraintPenalties.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.constraint,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: const Duration(milliseconds: 760),
      );
      if (!mounted) return;
    }
    if (jesterEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.jester,
        effectIndexes: jesterEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: const Duration(milliseconds: 820),
      );
      if (!mounted) return;
    }
    if (itemEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.item,
        effectIndexes: itemEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: const Duration(milliseconds: 820),
      );
      if (!mounted) return;
    }
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.finalScore,
      settlementGoalDisplayScore: lineGoalDisplayScore,
      delay: const Duration(milliseconds: 920),
    );
    if (!mounted) return;

    SoundManager.playSfx(AssetPaths.sfxCollect);
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _runSettlementSequence(
      lines: lines,
      totalScore: totalScore,
      shouldClearAfter: shouldClearAfter,
      settlementGoalBaseScore: settlementGoalBaseScore,
      settlementGoalAppliedScore: settlementGoalAppliedScore + line.finalScore,
      index: index + 1,
    );
  }

  Future<void> _showSettlementStep({
    required int totalScore,
    required ConfirmedLineBreakdown line,
    required ScoringPresentationStep step,
    required Duration delay,
    int? effectIndex,
    List<int> effectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    bool bump = false,
  }) async {
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.confirmSettlement,
      stageScoreAdded: totalScore,
      activeSettlementLine: line,
      activeSettlementStep: step,
      activeSettlementEffectIndex: effectIndex,
      activeSettlementEffectIndexes: effectIndexes,
      settlementGoalDisplayScore: settlementGoalDisplayScore,
      bumpSettlementSequence: bump,
    );
    await Future<void>.delayed(delay);
  }

  Future<void> _runStageClearFlow(int scoreAdded) async {
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    if (widget.debugCompleteRunOnClear) {
      await _completeRunAndReturnToTitle();
      return;
    }
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _debugForceBlindClear() async {
    if (!kDebugMode || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear();
    await _runStageClearFlow(scoreAdded);
  }

  Future<void> _debugForceBossClearToNextBlindSelect() async {
    if (!kDebugMode || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear(
      overrideTier: BlindTier.boss,
    );
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(
      breakdown,
      autoEnterMarketOnLoad: true,
      autoAdvanceMarketOnLoad: true,
    );
  }

  Future<bool> _runStageClearPresentation(int scoreAdded) async {
    if (!mounted) return false;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.cleared,
      stageScoreAdded: scoreAdded,
      activeSettlementLine: null,
    );

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return false;
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.settlement);

    await Future<void>.delayed(const Duration(milliseconds: 950));
    return mounted;
  }

  Future<bool?> _showCashOutSheet(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
  }) {
    final settlementView = RummiSettlementRuntimeFacade.fromCashOut(
      breakdown: breakdown,
      currentGold: _marketView.gold,
    );
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GameCashOutSheet(
          settlement: settlementView,
          autoEnterMarketOnLoad:
              autoEnterMarketOnLoad || widget.autoEnterMarketOnCashOut,
        );
      },
    );
  }

  Future<void> _runAutoCashOutLoopOnLoad() async {
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _runSettlementToNextStationLoop(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool autoAdvanceMarketOnLoad = false,
  }) async {
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);
    await _saveActiveRun(scene: ActiveRunScene.battle);

    final enterShop = await _showCashOutSheet(
      breakdown,
      autoEnterMarketOnLoad: autoEnterMarketOnLoad,
    );
    if (!mounted || enterShop != true) return;

    _gameNotifier.enterMarketAfterCashOut(itemCatalog: _itemCatalog);
    await _saveActiveRun();
    if (!mounted) return;
    await _playSettlementToMarketTransition(breakdown);
    if (!mounted) return;

    final nextStage = await _showShopScreen(
      autoAdvanceOnLoad: autoAdvanceMarketOnLoad,
    );
    if (!mounted || nextStage != true) return;

    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<void> _playSettlementToMarketTransition(
    RummiCashOutBreakdown breakdown,
  ) async {
    if (!mounted) return;
    setState(() => _settlementToMarketTransition = breakdown);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() => _settlementToMarketTransition = null);
  }

  Future<void> _goToNextStationBlindSelect() async {
    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<void> _playNextStationTransition() async {
    if (!mounted) return;
    setState(() => _nextStationTransitionVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() => _nextStationTransitionVisible = false);
  }

  Future<bool?> _showShopScreen({bool autoAdvanceOnLoad = false}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runSeed: widget.runSeed,
          readMarketView: _readMarketViewWithItemOffers,
          onReroll: () =>
              _gameNotifier.rerollShopFromState(itemCatalog: _itemCatalog),
          onBuyOffer: (index) =>
              _gameNotifier.buyShopOffer(index, itemCatalog: _itemCatalog),
          onBuyItemOffer: (offer) =>
              _gameNotifier.buyItemOffer(offer, itemCatalog: _itemCatalog),
          onUseMarketItem: _gameNotifier.useMarketItem,
          onSellOwnedJester: (index) =>
              _gameNotifier.sellOwnedJester(index, itemCatalog: _itemCatalog),
          onStateChanged: _saveActiveRun,
          readActiveRunSaveView: () => ref
              .read(gameSessionNotifierProvider(_gameArgs))
              .activeRunSaveView,
          onOpenSettings: () async {
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onRestartRun: _restartCurrentRun,
          isDebugFixtureRun: _isDebugFixtureRun,
          initialItemShopTab: widget.debugStartItemShop,
          autoAdvanceOnLoad:
              autoAdvanceOnLoad || widget.autoAdvanceMarketOnLoad,
        ),
      ),
    );
  }

  Future<void> _openShopForTest() async {
    if (_isUiLocked) return;
    _gameNotifier.openShopForTest(preferredOfferIds: _shopInspectOfferIds);
    await _saveActiveRun(scene: ActiveRunScene.shop);
    _showSnack('검사용 Market 오퍼 ${_shopInspectOfferIds.length}장 표시');
    await _showShopScreen();
    if (!mounted) return;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _gameNotifier.markDirty();
  }

  Future<void> _openGameOptions(BuildContext context) async {
    if (_stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    await showGameOptionsDialog(
      context: context,
      runSeed: widget.runSeed,
      activeRunSaveView: _gameState.activeRunSaveView,
      onRestartRun: _restartCurrentRun,
      onExitToTitle: _exitToTitleWithConfirm,
      onReopenOptions: _openGameOptions,
      isDebugFixtureRun: _isDebugFixtureRun,
    );
  }

  Future<void> _openDebugBottomSheet(BuildContext context) async {
    if (!kDebugMode || _stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        var handSize = _stationView.resources.maxHandSize;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: FractionallySizedBox(
                heightFactor: 0.72,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: GameModalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'DEBUG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            GameIconButtonChip(
                              tooltip: '닫기',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: Icons.close_rounded,
                              size: 34,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 108,
                              child: GameActionButton(
                                label: 'MARKET',
                                background: const Color(0xFFF4A81D),
                                foreground: Colors.black,
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await WidgetsBinding.instance.endOfFrame;
                                  await _openShopForTest();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 228,
                                  height: 40,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: GameDebugHandSizeSegment(
                                      value: handSize,
                                      onChanged: (value) {
                                        setModalState(() => handSize = value);
                                        _setDebugMaxHandSize(value);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                GameMenuActionTile(
                                  title: '현재 Blind 즉시 클리어',
                                  subtitle: '현재 선택된 블라인드를 즉시 정산 완료 상태로 넘깁니다.',
                                  icon: Icons.bug_report_rounded,
                                  accentColor: Colors.orange.shade200,
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await WidgetsBinding.instance.endOfFrame;
                                    await _debugForceBlindClear();
                                  },
                                ),
                                const SizedBox(height: 8),
                                GameMenuActionTile(
                                  title: '보스 클리어 후 다음 Blind Select',
                                  subtitle: '다음 스테이션의 블라인드 선택으로 바로 이행합니다.',
                                  icon: Icons.skip_next_rounded,
                                  accentColor: Colors.lightGreenAccent.shade100,
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await WidgetsBinding.instance.endOfFrame;
                                    await _debugForceBossClearToNextBlindSelect();
                                  },
                                ),
                              ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionNotifierProvider(_gameArgs));
    if (!gameState.isReady) {
      return const PhoneFrameScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return PhoneFrameScaffold(
      child: Stack(
        children: [
          _GameSurface(
            battle: _battleViewWithItemSlots,
            station: _stationView,
            market: _marketView,
            stageFlowPhase: _stageFlowPhase,
            stageScoreAdded: _stageScoreAdded,
            activeSettlementLine: _activeSettlementLine,
            activeSettlementStep: _activeSettlementStep,
            activeSettlementEffectIndex: _activeSettlementEffectIndex,
            activeSettlementEffectIndexes: _activeSettlementEffectIndexes,
            settlementGoalDisplayScore: _settlementGoalDisplayScore,
            settlementSequenceTick: _settlementSequenceTick,
            settlementBoardSnapshot: _settlementBoardSnapshot,
            selectedHandTile: _selectedHandTile,
            selectedBoardRow: _selectedBoardRow,
            selectedBoardCol: _selectedBoardCol,
            boardMoveMode: _boardMoveMode,
            pendingBoardMoveSourceRow: _pendingBoardMoveSourceRow,
            pendingBoardMoveSourceCol: _pendingBoardMoveSourceCol,
            selectedJesterOverlayIndex: _selectedJesterOverlayIndex,
            selectedBattleItemSlot: _selectedBattleItemSlot,
            itemEffectFeedback: _itemEffectFeedback,
            itemEffectFeedbackTick: _itemEffectFeedbackTick,
            onOptionsTap: () => _openGameOptions(context),
            onDebugTap: () => _openDebugBottomSheet(context),
            onJesterTap: _openJesterOverlay,
            onHandTileTap: _toggleHandTile,
            onBoardCellTap: _onBoardCellTap,
            onDraw: _drawTile,
            onBoardDiscard: _discardSelectedBoardTile,
            onHandDiscard: _discardSelectedHandTile,
            onStartBoardMove: _startBoardMoveMode,
            onBattleItemTap: _openBattleItemOverlay,
            onConfirm: _confirmLines,
            onClearSelection: _clearSelections,
            onJesterSell: _sellOwnedJesterFromOverlay,
            onJesterOverlayClose: _closeJesterOverlay,
            onBattleItemUse: _useBattleItem,
            onBattleItemOverlayClose: _closeBattleItemOverlay,
          ),
          if (_settlementToMarketTransition != null)
            Positioned.fill(
              child: _SettlementToMarketTransitionOverlay(
                breakdown: _settlementToMarketTransition!,
              ),
            ),
          if (_nextStationTransitionVisible)
            const Positioned.fill(child: _NextStationTransitionOverlay()),
        ],
      ),
    );
  }
}

class _SettlementToMarketTransitionOverlay extends StatelessWidget {
  const _SettlementToMarketTransitionOverlay({required this.breakdown});

  final RummiCashOutBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.50)),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 282,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF102D25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF4C64F).withValues(alpha: 0.66),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFFF4C64F),
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Market 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '정산 보상 +${breakdown.totalGold} Gold',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF4C64F),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStationTransitionOverlay extends StatelessWidget {
  const _NextStationTransitionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.54)),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 280,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF102D25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF4C64F).withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: Color(0xFFF4C64F),
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '다음 Station 준비',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Blind 선택으로 이동',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF4C64F),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemEffectFeedback {
  const _ItemEffectFeedback({
    required this.title,
    required this.detail,
    required this.passive,
  });

  final String title;
  final String detail;
  final bool passive;
}

class _ItemEffectFeedbackToast extends StatelessWidget {
  const _ItemEffectFeedbackToast({super.key, required this.feedback});

  final _ItemEffectFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final accent = feedback.passive
        ? const Color(0xFF6EE7B7)
        : const Color(0xFFF4A81D);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.15 ? value / 0.15 : 1.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F2B23).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                feedback.passive ? Icons.shield_rounded : Icons.bolt_rounded,
                color: accent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      feedback.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (feedback.passive)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      '패시브',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameSurface extends StatelessWidget {
  const _GameSurface({
    required this.battle,
    required this.station,
    required this.market,
    required this.stageFlowPhase,
    required this.stageScoreAdded,
    required this.activeSettlementLine,
    required this.activeSettlementStep,
    required this.activeSettlementEffectIndex,
    required this.activeSettlementEffectIndexes,
    required this.settlementGoalDisplayScore,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.boardMoveMode,
    required this.pendingBoardMoveSourceRow,
    required this.pendingBoardMoveSourceCol,
    required this.selectedJesterOverlayIndex,
    required this.selectedBattleItemSlot,
    required this.itemEffectFeedback,
    required this.itemEffectFeedbackTick,
    required this.onOptionsTap,
    required this.onDebugTap,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onStartBoardMove,
    required this.onBattleItemTap,
    required this.onConfirm,
    required this.onClearSelection,
    required this.onJesterSell,
    required this.onJesterOverlayClose,
    required this.onBattleItemUse,
    required this.onBattleItemOverlayClose,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final GameStageFlowPhase stageFlowPhase;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final List<int> activeSettlementEffectIndexes;
  final int? settlementGoalDisplayScore;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final bool boardMoveMode;
  final int? pendingBoardMoveSourceRow;
  final int? pendingBoardMoveSourceCol;
  final int? selectedJesterOverlayIndex;
  final RummiBattleItemSlotView? selectedBattleItemSlot;
  final _ItemEffectFeedback? itemEffectFeedback;
  final int itemEffectFeedbackTick;
  final VoidCallback onOptionsTap;
  final VoidCallback onDebugTap;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onStartBoardMove;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemTap;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;
  final VoidCallback onJesterSell;
  final VoidCallback onJesterOverlayClose;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemUse;
  final VoidCallback onBattleItemOverlayClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4B3C), Color(0xFF12392E), Color(0xFF0B251F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
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
            const Positioned.fill(child: GameTableBackdrop()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: _GameLayout(
                  battle: battle,
                  station: station,
                  market: market,
                  activeSettlementEffects:
                      activeSettlementLine?.effects ?? const [],
                  activeSettlementStep: activeSettlementStep,
                  activeSettlementEffectIndex: activeSettlementEffectIndex,
                  activeSettlementEffectIndexes: activeSettlementEffectIndexes,
                  settlementGoalDisplayScore: settlementGoalDisplayScore,
                  activeSettlementLine: activeSettlementLine,
                  settlementSequenceTick: settlementSequenceTick,
                  settlementBoardSnapshot: settlementBoardSnapshot,
                  selectedHandTile: selectedHandTile,
                  selectedBoardRow: selectedBoardRow,
                  selectedBoardCol: selectedBoardCol,
                  boardMoveMode: boardMoveMode,
                  pendingBoardMoveSourceRow: pendingBoardMoveSourceRow,
                  pendingBoardMoveSourceCol: pendingBoardMoveSourceCol,
                  selectedJesterOverlayIndex: selectedJesterOverlayIndex,
                  selectedBattleItemSlot: selectedBattleItemSlot,
                  onOptionsTap: onOptionsTap,
                  onDebugTap: onDebugTap,
                  onJesterTap: onJesterTap,
                  onHandTileTap: onHandTileTap,
                  onBoardCellTap: onBoardCellTap,
                  onDraw: onDraw,
                  onBoardDiscard: onBoardDiscard,
                  onHandDiscard: onHandDiscard,
                  onStartBoardMove: onStartBoardMove,
                  onBattleItemTap: onBattleItemTap,
                  onConfirm: onConfirm,
                  onClearSelection: onClearSelection,
                ),
              ),
            ),
            if (stageFlowPhase == GameStageFlowPhase.confirmSettlement)
              if (activeSettlementStep == ScoringPresentationStep.finalScore)
                Positioned.fill(
                  child: GameFloatingSettlementBurst(
                    key: ValueKey(
                      'settlement-$settlementSequenceTick-$activeSettlementStep-$activeSettlementEffectIndex',
                    ),
                    line: activeSettlementLine,
                    step: activeSettlementStep,
                    effectIndex: activeSettlementEffectIndex,
                  ),
                ),
            if (stageFlowPhase == GameStageFlowPhase.cleared ||
                stageFlowPhase == GameStageFlowPhase.settlement)
              Positioned.fill(
                child: GameStageClearOverlay(
                  phase: stageFlowPhase,
                  stageIndex: battle.stageIndex,
                  scoreAdded: stageScoreAdded,
                ),
              ),
            if (itemEffectFeedback != null)
              const Positioned.fill(child: GameInputBarrier.feedback()),
            if (itemEffectFeedback != null)
              Positioned(
                left: 22,
                right: 22,
                bottom: 238,
                child: _ItemEffectFeedbackToast(
                  key: ValueKey('item-effect-$itemEffectFeedbackTick'),
                  feedback: itemEffectFeedback!,
                ),
              ),
            if (selectedJesterOverlayIndex != null &&
                selectedJesterOverlayIndex! < market.ownedEntries.length)
              Positioned.fill(
                child: Stack(
                  children: [
                    const GameInputBarrier.modal(),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameJesterInfoOverlay(
                        card: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .card,
                        runtimeValueText: jesterRuntimeValueText(
                          market.ownedEntries[selectedJesterOverlayIndex!].card,
                          market.runtimeSnapshot,
                          slotIndex: selectedJesterOverlayIndex!,
                        ),
                        sellGold: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .sellPrice,
                        onSell: onJesterSell,
                        onClose: onJesterOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedBattleItemSlot != null)
              Positioned.fill(
                child: Stack(
                  children: [
                    const GameInputBarrier.modal(),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameBattleItemInfoOverlay(
                        itemSlot: selectedBattleItemSlot!,
                        onUse: () => onBattleItemUse(selectedBattleItemSlot!),
                        onClose: onBattleItemOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  const _GameLayout({
    required this.battle,
    required this.station,
    required this.market,
    required this.activeSettlementEffects,
    required this.activeSettlementStep,
    required this.activeSettlementEffectIndex,
    required this.activeSettlementEffectIndexes,
    required this.settlementGoalDisplayScore,
    required this.activeSettlementLine,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.boardMoveMode,
    required this.pendingBoardMoveSourceRow,
    required this.pendingBoardMoveSourceCol,
    required this.selectedJesterOverlayIndex,
    required this.selectedBattleItemSlot,
    required this.onOptionsTap,
    required this.onDebugTap,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onStartBoardMove,
    required this.onBattleItemTap,
    required this.onConfirm,
    required this.onClearSelection,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeSettlementEffects;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final List<int> activeSettlementEffectIndexes;
  final int? settlementGoalDisplayScore;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final bool boardMoveMode;
  final int? pendingBoardMoveSourceRow;
  final int? pendingBoardMoveSourceCol;
  final int? selectedJesterOverlayIndex;
  final RummiBattleItemSlotView? selectedBattleItemSlot;
  final VoidCallback onOptionsTap;
  final VoidCallback onDebugTap;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onStartBoardMove;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemTap;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final scoringCells = battle.scoringCellKeys;
    final constrainedCells = <String>{
      for (var row = 0; row < kBoardSize; row++)
        for (var col = 0; col < kBoardSize; col++)
          if (battle.board.cellAt(row, col) != null &&
              battle.isTileConstrained(battle.board.cellAt(row, col)!))
            '$row:$col',
    };
    final activeSettlementCells = activeSettlementLine == null
        ? <String>{}
        : {
            for (final (row, col) in activeSettlementLine!.contributingCells)
              '$row:$col',
          };
    final visibleSettlementEffects = _visibleSettlementEffects(
      activeSettlementEffects,
      activeSettlementStep,
      activeSettlementEffectIndex,
      activeSettlementEffectIndexes,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileWidth = boardTileVisualWidth(boardSide);

        return Column(
          children: [
            GameTopHud(
              station: station,
              battle: battle,
              onOptionsTap: onOptionsTap,
              stationGoalDisplayScore: settlementGoalDisplayScore,
              stationGoalPulse:
                  activeSettlementStep == ScoringPresentationStep.finalScore,
              stationGoalPulseTick: settlementSequenceTick,
            ),
            const SizedBox(height: 6),
            GameJesterZone(
              market: market,
              activeEffects: visibleSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              selectedIndex: selectedJesterOverlayIndex,
              onTapCard: onJesterTap,
            ),
            const SizedBox(height: 6),
            GameItemZoneSkeleton(
              battle: battle,
              activeEffects: visibleSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              selectedSlotIndex: selectedBattleItemSlot?.slotIndex,
              onItemSlotTap: onBattleItemTap,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameBoardGrid(
                      board: battle.board,
                      scoringCells: scoringCells,
                      constrainedCells: constrainedCells,
                      activeSettlementCells: activeSettlementCells,
                      settlementBoardSnapshot: settlementBoardSnapshot,
                      selectedRow: selectedBoardRow,
                      selectedCol: selectedBoardCol,
                      boardMoveMode: boardMoveMode,
                      moveSourceRow: pendingBoardMoveSourceRow,
                      moveSourceCol: pendingBoardMoveSourceCol,
                      onTapCell: onBoardCellTap,
                    ),
                  ),
                  if (_showsBoardScoringCallout(activeSettlementStep) &&
                      activeSettlementLine != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 10,
                      child: _BoardScoringCallout(
                        key: ValueKey(
                          'board-score-$settlementSequenceTick-$activeSettlementStep',
                        ),
                        line: activeSettlementLine!,
                        step: activeSettlementStep,
                      ),
                    ),
                  if (kDebugMode)
                    Positioned(
                      right: 0,
                      bottom: 16,
                      child: GameIconButtonChip(
                        tooltip: '디버그',
                        size: 34,
                        icon: Icons.bug_report_rounded,
                        iconSize: 16,
                        borderRadius: 8,
                        backgroundColor: const Color(0xFF29453A),
                        onPressed: onDebugTap,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _ScoringPreviewChip(preview: battle.scoringPreview),
            const SizedBox(height: 4),
            _BattleActionBar(
              scoringPreview: battle.scoringPreview,
              canStartBoardMove:
                  !boardMoveMode &&
                  selectedBoardRow != null &&
                  selectedBoardCol != null &&
                  station.resources.boardMovesRemaining > 0,
              onConfirm: onConfirm,
              onClearSelection: onClearSelection,
              onStartBoardMove: onStartBoardMove,
              onBoardDiscard: onBoardDiscard,
              onHandDiscard: onHandDiscard,
              confirmEnabled: !boardMoveMode,
              utilityEnabled: !boardMoveMode,
            ),
            if (boardMoveMode) ...[
              const SizedBox(height: 4),
              Text(
                '빈 칸을 선택해 이동을 확정하세요. 원본 타일을 누르면 취소됩니다.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 6),
            GameHandZone(
              battle: battle,
              station: station,
              hand: battle.hand,
              selectedHandTile: selectedHandTile,
              onHandTileTap: onHandTileTap,
              onDraw: onDraw,
              tileWidth: tileWidth,
            ),
          ],
        );
      },
    );
  }
}

List<RummiJesterEffectBreakdown> _visibleSettlementEffects(
  List<RummiJesterEffectBreakdown> effects,
  ScoringPresentationStep step,
  int? effectIndex,
  List<int> effectIndexes,
) {
  if (step != ScoringPresentationStep.jester &&
      step != ScoringPresentationStep.item) {
    return const [];
  }
  if (effectIndexes.isNotEmpty) {
    return [
      for (final index in effectIndexes)
        if (index >= 0 && index < effects.length) effects[index],
    ];
  }
  if (effectIndex == null || effectIndex < 0 || effectIndex >= effects.length) {
    return const [];
  }
  return [effects[effectIndex]];
}

bool _showsBoardScoringCallout(ScoringPresentationStep step) {
  return step == ScoringPresentationStep.boardLine ||
      step == ScoringPresentationStep.handRank ||
      step == ScoringPresentationStep.overlap ||
      step == ScoringPresentationStep.constraint;
}

class _BoardScoringCallout extends StatelessWidget {
  const _BoardScoringCallout({
    super.key,
    required this.line,
    required this.step,
  });

  final ConfirmedLineBreakdown line;
  final ScoringPresentationStep step;

  @override
  Widget build(BuildContext context) {
    final (title, value, detail) = switch (step) {
      ScoringPresentationStep.boardLine => (
        '${gameLineRefShortLabel(line.ref)} 라인',
        '확정',
        '하이라이트된 타일이 점수 라인입니다',
      ),
      ScoringPresentationStep.handRank => (
        gameHandRankLabel(line.rank),
        '+${line.rankBaseScore ?? line.baseScore}',
        '족보 base score',
      ),
      ScoringPresentationStep.overlap => (
        'overlap',
        '+${line.overlapBonus}',
        '겹친 타일 보너스',
      ),
      ScoringPresentationStep.constraint => (
        line.constraintPenalties.first.title,
        line.constraintPenalties.first.markerText,
        line.constraintPenalties.first.ruleText,
      ),
      _ => ('점수', '+0', ''),
    };
    final valueColor = step == ScoringPresentationStep.constraint
        ? const Color(0xFFFF8E7E)
        : const Color(0xFFF2C14E);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final dy = (1 - value) * 10;
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE6153C31),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF2C14E).withValues(alpha: 0.78),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2C14E).withValues(alpha: 0.16),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleActionBar extends StatelessWidget {
  const _BattleActionBar({
    required this.scoringPreview,
    required this.canStartBoardMove,
    required this.onConfirm,
    required this.onClearSelection,
    required this.onStartBoardMove,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.confirmEnabled,
    required this.utilityEnabled,
  });

  final RummiScoringPreview? scoringPreview;
  final bool canStartBoardMove;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;
  final VoidCallback onStartBoardMove;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final bool confirmEnabled;
  final bool utilityEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        const confirmGap = 18.0;
        const buttonSide = 42.0;
        final confirmReady = scoringPreview != null;

        return SizedBox(
          height: buttonSide,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BattleRailButton(
                tooltip: '선택 해제',
                label: '선택\n해제',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: const Color(0xFF4C5A55),
                onPressed: utilityEnabled ? onClearSelection : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '이동',
                label: '타일\n이동',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: const Color(0xFF315F68),
                onPressed: canStartBoardMove ? onStartBoardMove : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '보드 버림',
                label: '보드\n버림',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: const Color(0xFF44554C),
                onPressed: utilityEnabled ? onBoardDiscard : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '손패 버림',
                label: '손패\n버림',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: const Color(0xFF5B4D33),
                onPressed: utilityEnabled ? onHandDiscard : null,
              ),
              const SizedBox(width: confirmGap),
              _BattleRailButton(
                tooltip: '확정',
                label: '확정\n하기',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: confirmReady
                    ? const Color(0xFFF4A81D)
                    : const Color(0xFF5A5D54),
                foregroundColor: confirmReady ? Colors.black : Colors.white54,
                onPressed: confirmEnabled ? onConfirm : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoringPreviewChip extends StatelessWidget {
  const _ScoringPreviewChip({required this.preview});

  final RummiScoringPreview? preview;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;
    final accent = preview == null
        ? Colors.white.withValues(alpha: 0.34)
        : const Color(0xFFF4A81D);
    final label = preview == null
        ? '확정 가능 줄 없음'
        : '${preview.lineCount}줄 · ${gameHandRankLabel(preview.representativeRank)} · 예상 +${preview.expectedScore}';
    final detail = preview == null
        ? '족보 줄을 만들면 빌드 효과가 미리 표시됩니다'
        : 'Base ${preview.baseScore}'
              '${preview.overlapBonus > 0 ? ' · overlap +${preview.overlapBonus}' : ''}'
              ' · J${preview.expectedJesterEffectCount}/I${preview.expectedItemEffectCount}';
    return SizedBox(
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Icon(
                preview == null
                    ? Icons.info_outline_rounded
                    : Icons.auto_awesome_rounded,
                color: accent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: preview == null ? Colors.white54 : Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleRailButton extends StatelessWidget {
  const _BattleRailButton({
    required this.tooltip,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = Colors.white,
    this.size = 58,
    this.borderRadius = 9,
  });

  final String tooltip;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final baseColor = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.34);
    final textColor = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.58);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isEnabled
                    ? foregroundColor.withValues(alpha: 0.28)
                    : foregroundColor.withValues(alpha: 0.12),
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
