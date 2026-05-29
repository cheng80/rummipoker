import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/poker_deck.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../services/new_run_setup.dart';
import '../../../services/run_unlock_state_service.dart';
import 'game_session_state.dart';

part 'game_session_notifier_models.dart';
part 'game_session_notifier_bootstrap.dart';
part 'game_session_notifier_save_commands.dart';
part 'game_session_notifier_battle_commands.dart';

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<
      GameSessionNotifier,
      GameSessionState,
      GameSessionArgs
    >(GameSessionNotifier.new);

class DeckPeekBattleUseResult {
  const DeckPeekBattleUseResult._({required this.candidates, this.failMessage});

  const DeckPeekBattleUseResult.success(List<Tile> candidates)
    : this._(candidates: candidates);

  const DeckPeekBattleUseResult.failure(String message)
    : this._(candidates: const [], failMessage: message);

  final List<Tile> candidates;
  final String? failMessage;

  bool get isSuccess => failMessage == null;
}

class GameSessionNotifier
    extends FamilyNotifier<GameSessionState, GameSessionArgs>
    with GameSessionNotifierSaveCommands, GameSessionNotifierBattleCommands {
  @override
  GameSessionState build(GameSessionArgs args) {
    return _withDerivedViews(_buildInitialGameSessionState(args));
  }

  void markDirty() {
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    _replaceState(
      state.copyWith(jesterCatalog: catalog, revision: state.revision + 1),
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    _replaceState(
      state.copyWith(
        runLoopPhase: _loopPhaseForScene(scene),
        activeRunScene: scene,
        revision: state.revision + 1,
      ),
    );
  }

  void setDebugMaxHandSize(int value) {
    final session = state.session;
    if (session == null) return;
    final ruleset = state.ruleset;
    final clamped = value.clamp(
      ruleset.minDebugMaxHandSize,
      ruleset.maxDebugMaxHandSize,
    );
    session.setDebugMaxHandSize(clamped);
    final selectedHandTile = state.selectedHandTile;
    _replaceState(
      state.copyWith(
        selectedHandTile:
            selectedHandTile != null && !session.hand.contains(selectedHandTile)
            ? null
            : selectedHandTile,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  void clearSelections() {
    _replaceState(
      state.copyWith(
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedHandTile(Tile? tile) {
    _replaceState(
      state.copyWith(
        selectedHandTile: tile,
        selectedBoardRow: tile == null ? state.selectedBoardRow : null,
        selectedBoardCol: tile == null ? state.selectedBoardCol : null,
        revision: state.revision + 1,
      ),
    );
  }

  void toggleSelectedHandTile(Tile tile) {
    setSelectedHandTile(state.selectedHandTile == tile ? null : tile);
  }

  @override
  void setSelectedBoardCell(int? row, int? col) {
    _replaceState(
      state.copyWith(
        selectedBoardRow: row,
        selectedBoardCol: col,
        selectedHandTile: row == null && col == null
            ? state.selectedHandTile
            : null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: index,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    _replaceState(
      state.copyWith(
        settlementBoardSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    ScoringPresentationStep activeSettlementStep = ScoringPresentationStep.none,
    int? activeSettlementEffectIndex,
    List<int> activeSettlementEffectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    _replaceState(
      state.copyWith(
        stageFlowPhase: phase,
        stageScoreAdded: stageScoreAdded,
        activeSettlementLine: activeSettlementLine,
        activeSettlementStep: activeSettlementStep,
        activeSettlementEffectIndex: activeSettlementEffectIndex,
        activeSettlementEffectIndexes: activeSettlementEffectIndexes,
        settlementGoalDisplayScore: settlementGoalDisplayScore,
        settlementBoardSnapshot: settlementBoardSnapshot,
        settlementSequenceTick: bumpSettlementSequence
            ? state.settlementSequenceTick + 1
            : state.settlementSequenceTick,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  GameSessionState _withValidSelections(GameSessionState current) {
    final session = current.session;
    if (session == null) return current;

    final selectedHandTile = current.selectedHandTile;
    final keepHandSelection =
        selectedHandTile != null && session.hand.contains(selectedHandTile);
    final selectedBoardRow = current.selectedBoardRow;
    final selectedBoardCol = current.selectedBoardCol;
    final keepBoardSelection =
        selectedBoardRow != null &&
        selectedBoardCol != null &&
        selectedBoardRow >= 0 &&
        selectedBoardRow < kBoardSize &&
        selectedBoardCol >= 0 &&
        selectedBoardCol < kBoardSize &&
        session.board.cellAt(selectedBoardRow, selectedBoardCol) != null;

    return current.copyWith(
      selectedHandTile: keepHandSelection ? selectedHandTile : null,
      selectedBoardRow: keepBoardSelection ? selectedBoardRow : null,
      selectedBoardCol: keepBoardSelection ? selectedBoardCol : null,
    );
  }

  // -- Business logic --

  /// 스테이지 잔여물 처리 + 캐시아웃 계산/적용. 결과 breakdown 반환.
  RummiCashOutBreakdown prepareCashOut({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    session.discardStageRemainder();
    var breakdown = runProgress.buildCashOutBreakdown(
      session,
      itemCatalog: itemCatalog,
      rewardMultiplier: state.runModifier.rewardMultiplier,
    );
    runProgress.applyCashOut(breakdown);
    if (runProgress.currentStationBlindTierIndex == BlindTier.boss.index) {
      final rewardTile = runProgress.addBossClearDeckTileReward(
        session.runRandom,
      );
      breakdown = breakdown.copyWith(deckTileRewards: [rewardTile]);
      if (itemCatalog != null) {
        ItemEffectRuntime.applyOwnedBossClearItems(
          catalog: itemCatalog,
          runProgress: runProgress,
        );
      }
      runProgress.claimBossSlotUnlockRewards(itemCatalog: itemCatalog);
      runProgress.recordSeenBossModifier(session.blind.bossModifier?.id);
      runProgress.recordClearedStation(runProgress.stageIndex);
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return breakdown;
  }

  /// 전투 정산 직후 캐시아웃 준비를 notifier 경계로 모은다.
  RummiCashOutBreakdown prepareSettlementAndCashOut({
    ItemCatalog? itemCatalog,
  }) {
    final breakdown = prepareCashOut(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.settlement,
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
    return breakdown;
  }

  /// 상점 열기: 오퍼 생성.
  void openShop({ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    final catalog = state.jesterCatalog;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedEnterMarketItems(
        catalog: itemCatalog,
        runProgress: runProgress,
      );
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  /// 캐시아웃 뒤 market 진입 준비를 notifier 경계에서 처리한다.
  void enterMarketAfterCashOut({ItemCatalog? itemCatalog}) {
    openShop(itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.market,
        activeRunScene: ActiveRunScene.shop,
        revision: state.revision + 1,
      ),
    );
  }

  void markSlotUnlockPresentationShown() {
    final runProgress = state.runProgress;
    if (runProgress == null ||
        runProgress.snapshotPendingSlotUnlockPresentations().isEmpty) {
      return;
    }
    runProgress.clearPendingSlotUnlockPresentations();
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  String? rerollShopFromState({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final catalog =
        state.jesterCatalog?.shopCatalog ?? const <RummiJesterCard>[];
    return rerollShop(
      catalog: catalog,
      rng: session.runRandom,
      itemCatalog: itemCatalog,
    );
  }

  String? rerollItemOffersFromState({
    ItemCatalog? itemCatalog,
    ItemPlacement placement = ItemPlacement.inventory,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      itemRerollPlacement: placement,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollItemOffers(placement: placement);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? rerollTileOffersFromState({ItemCatalog? itemCatalog}) {
    final session = state.session;
    final runProgress = state.runProgress;
    if (session == null || runProgress == null) {
      return '상점 진행 정보가 없습니다.';
    }
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollTileOffers(rng: session.runRandom);
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final rerollItem = _nextOwnedMarketRerollItem(
      catalog: itemCatalog,
      runProgress: runProgress,
    );
    if (rerollItem != null) {
      final result = ItemEffectRuntime.applyMarketRerollItem(
        item: rerollItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final ok = runProgress.rerollShop(
      catalog: catalog,
      rng: rng,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    if (!ok) {
      return '리롤 골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketRerollItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
    ItemPlacement? itemRerollPlacement,
  }) {
    final cost = itemRerollPlacement != null
        ? runProgress.effectiveItemRerollCostFor(itemRerollPlacement)
        : runProgress.effectiveRerollCost();
    if (catalog == null || cost <= 0) {
      return null;
    }
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null) continue;
      if (item.effect.timing == 'market_reroll' &&
          (item.effect.op == 'free_next_reroll' ||
              item.effect.op == 'discount_next_reroll') &&
          item.effect.consume) {
        return item;
      }
    }
    return null;
  }

  String? buyShopOffer(int offerIndex, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.shopOffers.length) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= runProgress.jesterSlotCapacity()) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'jester',
    );
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
    }
    final price = runProgress.effectiveJesterOfferPrice(offerIndex);
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(offerIndex);
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyShopOfferView(
    RummiMarketOfferView offer, {
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final offerIndex = runProgress.shopOffers.indexWhere(
      (entry) => entry.card.id == offer.contentId,
    );
    if (offerIndex < 0) {
      return '구매할 오퍼를 찾지 못했습니다.';
    }
    if (runProgress.ownedJesters.length >= runProgress.jesterSlotCapacity()) {
      return '제스터 슬롯이 가득 찼습니다. 먼저 판매하세요.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'jester',
    );
    var price = offer.price;
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
      price = runProgress.effectiveJesterOfferPrice(
        offerIndex,
        includeCheapestFirstOfferDiscount: false,
      );
      if (offer.discountSourceLabel == '나침반') {
        price = max(
          0,
          price - runProgress.marketModifiers.cheapestFirstOfferDiscount,
        );
      }
    }
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyOffer(
      offerIndex,
      price: price,
      consumeCheapestFirstOfferDiscount: offer.discountSourceLabel == '나침반',
    );
    if (!ok) {
      return '구매 처리에 실패했습니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyItemOffer(
    RummiMarketItemOfferView offer, {
    ItemCatalog? itemCatalog,
  }) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    final quickSlotCapacity = runProgress.quickSlotCapacity(
      itemCatalog: itemCatalog,
    );
    if (!runProgress.itemInventory.canAcquire(
      offer.item,
      quickSlotCapacity: quickSlotCapacity,
      passiveRelicCapacity: runProgress.passiveRelicCapacity(
        itemCatalog: itemCatalog,
      ),
    )) {
      return '이미 보유 한도에 도달한 아이템입니다.';
    }
    final marketBuyItem = _nextOwnedMarketBuyItem(
      catalog: itemCatalog,
      runProgress: runProgress,
      category: 'item',
    );
    var price = offer.price;
    if (marketBuyItem != null) {
      final result = ItemEffectRuntime.applyMarketBuyItem(
        item: marketBuyItem,
        runProgress: runProgress,
      );
      if (!result.isSuccess) return result.failMessage;
      price = runProgress.effectiveItemPrice(
        offer.item,
        includeCheapestFirstOfferDiscount: false,
      );
      if (offer.discountSourceLabel == '나침반') {
        price = max(
          0,
          price - runProgress.marketModifiers.cheapestFirstOfferDiscount,
        );
      }
    }
    if (runProgress.gold < price) {
      return '골드가 부족합니다.';
    }
    final ok = runProgress.buyItem(
      offer.item,
      price: price,
      itemCatalog: itemCatalog,
      consumeCheapestFirstOfferDiscount: offer.discountSourceLabel == '나침반',
    );
    if (!ok) {
      return '아이템 구매 처리에 실패했습니다.';
    }
    runProgress.markItemOfferConsumed(offer.contentId);
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  String? buyTileOffer(int offerIndex) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';
    if (offerIndex < 0 || offerIndex >= runProgress.tileOffers.length) {
      return '구매할 타일을 찾지 못했습니다.';
    }
    final ok = runProgress.buyTileOffer(offerIndex);
    if (!ok) {
      return '골드가 부족합니다.';
    }
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  ItemDefinition? _nextOwnedMarketBuyItem({
    required ItemCatalog? catalog,
    required RummiRunProgress runProgress,
    required String category,
  }) {
    if (catalog == null) return null;
    for (final entry in runProgress.itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = catalog.findById(entry.itemId);
      if (item == null || item.effect.op != 'discount_next_purchase') {
        continue;
      }
      if (item.effect.timing == 'market_buy') {
        return item;
      }
      if (item.effect.timing == 'market_buy_if_category' &&
          item.effect.value('category') == category) {
        return item;
      }
    }
    return null;
  }

  /// market 종료 후 다음 station 로딩 직전의 짧은 전환 단계를 기록한다.
  void beginNextStationTransition() {
    _replaceState(
      state.copyWith(
        runLoopPhase: GameRunLoopPhase.nextStationTransition,
        activeRunScene: ActiveRunScene.blindSelect,
        revision: state.revision + 1,
      ),
    );
  }

  /// Market 종료 뒤 blind select route로 넘길 runtime을 station-loop 경계에서 만든다.
  ActiveRunRuntimeState prepareNextStationBlindSelectRuntime({
    required NewRunDifficulty difficulty,
  }) {
    beginNextStationTransition();
    return BlindSelectionSetup.prepareRuntimeForBlindSelect(
      runtime: buildSaveRuntimeState(
        scene: ActiveRunScene.blindSelect,
        difficulty: difficulty,
      ),
    );
  }

  /// 다음 스테이지로 진입 처리.
  void advanceToNextStage(int runSeed, {ItemCatalog? itemCatalog}) {
    final session = state.session!;
    final runProgress = state.runProgress!;
    runProgress.advanceStage(session, runSeed: runSeed);
    if (itemCatalog != null) {
      ItemEffectRuntime.applyOwnedStationStartItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
      );
    }
    clearSelections();
    _replaceState(
      state.copyWith(
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
        runLoopPhase: GameRunLoopPhase.battle,
        revision: state.revision + 1,
      ),
    );
  }

  /// market 종료 후 다음 station 진입까지를 notifier command로 감싼다.
  void advanceToNextStation(int runSeed, {ItemCatalog? itemCatalog}) {
    advanceToNextStage(runSeed, itemCatalog: itemCatalog);
    _replaceState(
      state.copyWith(
        activeRunScene: ActiveRunScene.battle,
        revision: state.revision + 1,
      ),
    );
  }

  // -- 전투 액션 (View에서 직접 session을 조작하던 것을 이관) --

  String? useMarketItem(ItemDefinition item) {
    final runProgress = state.runProgress;
    if (runProgress == null) return '상점 진행 정보가 없습니다.';

    final result = ItemEffectRuntime.applyMarketUseItem(
      item: item,
      runProgress: runProgress,
    );
    if (!result.isSuccess) return result.failMessage;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return null;
  }

  bool sellMarketItem(ItemDefinition item) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedItem(item);
    if (!ok) return false;
    _replaceState(state.copyWith(revision: state.revision + 1));
    return true;
  }

  /// 장착 제스터 판매. 성공 시 true.
  bool sellOwnedJester(int index, {ItemCatalog? itemCatalog}) {
    final runProgress = state.runProgress;
    if (runProgress == null) return false;
    final ok = runProgress.sellOwnedJester(index, itemCatalog: itemCatalog);
    if (!ok) return false;
    _replaceState(
      state.copyWith(
        selectedJesterOverlayIndex: null,
        revision: state.revision + 1,
      ),
    );
    return true;
  }

  bool sellSelectedJesterOverlayFromState() {
    final index = state.selectedJesterOverlayIndex;
    if (index == null) return false;
    return sellOwnedJester(index);
  }

  /// 검사용 상점 열기 (특정 오퍼 ID 지정).
  void openShopForTest({required List<String> preferredOfferIds}) {
    final session = state.session;
    final runProgress = state.runProgress;
    final catalog = state.jesterCatalog;
    if (session == null || runProgress == null) return;
    runProgress.openShop(
      catalog: catalog?.shopCatalog ?? const <RummiJesterCard>[],
      rng: session.runRandom,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: preferredOfferIds.length,
      pressureProfile: _marketPressureProfileFor(state.runModifier),
    );
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  @override
  void _replaceState(GameSessionState next) {
    state = _withDerivedViews(next);
  }

  GameSessionState _withDerivedViews(GameSessionState next) {
    final session = next.session;
    final runProgress = next.runProgress;
    if (session == null || runProgress == null) {
      return next.copyWith(
        stationView: null,
        marketView: null,
        battleView: null,
        activeRunSaveView: null,
      );
    }

    return next.copyWith(
      stationView: RummiStationRuntimeFacade.fromSession(session),
      marketView: RummiMarketRuntimeFacade.fromRunProgress(
        runProgress,
        pressureProfile: _marketPressureProfileFor(next.runModifier),
      ),
      battleView: RummiBattleRuntimeFacade.fromRuntime(
        session: session,
        runProgress: runProgress,
      ),
      activeRunSaveView: RummiActiveRunSaveFacade.fromRuntimeState(
        ActiveRunRuntimeState(
          activeScene: next.activeRunScene,
          difficulty: arg.difficulty,
          session: session,
          runProgress: runProgress,
          stageStartSnapshot:
              next.stageStartSnapshot ??
              ActiveRunSaveService.captureStageStartSnapshot(
                session: session,
                runProgress: runProgress,
              ),
        ),
      ),
    );
  }

  RummiMarketPressureProfile _marketPressureProfileFor(
    NewRunModifier modifier,
  ) {
    return modifier == NewRunModifier.highStakes
        ? RummiMarketPressureProfile.highStakes
        : RummiMarketPressureProfile.standard;
  }
}
