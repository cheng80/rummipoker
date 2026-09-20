import 'package:flutter/widgets.dart';
import '../logic/rummi_poker_grid/item_effect_runtime.dart';
import 'app_translation.dart';

String actionFailureLabel(BuildContext context, ActionFailure failure) {
  final key = switch (failure.reason) {
    ActionFailureReason.selectScoringLine => 'coreActionSelectScoringLine',
    ActionFailureReason.selectRitualTarget => 'coreActionSelectRitualTarget',
    ActionFailureReason.emptyPeekDeck => 'coreActionEmptyPeekDeck',
    ActionFailureReason.selectDeckDiscard => 'coreActionSelectDeckDiscard',
    ActionFailureReason.unsupportedEffect => 'coreActionUnsupportedEffect',
    ActionFailureReason.notLineItem => 'coreActionNotLineItem',
    ActionFailureReason.notRitualItem => 'coreActionNotRitualItem',
    ActionFailureReason.notDeckPeekItem => 'coreActionNotDeckPeekItem',
    ActionFailureReason.deckDiscardTargetMissing =>
      'coreActionDeckDiscardTargetMissing',
    ActionFailureReason.confirmBonusPending => 'coreActionConfirmBonusPending',
    ActionFailureReason.boardDiscardCap => 'coreActionBoardDiscardCap',
    ActionFailureReason.itemOfferCap => 'coreActionItemOfferCap',
    ActionFailureReason.jesterOfferCap => 'coreActionJesterOfferCap',
    ActionFailureReason.expiryNotRecoverable =>
      'coreActionExpiryNotRecoverable',
    ActionFailureReason.expiryAlreadyUsed => 'coreActionExpiryAlreadyUsed',
    ActionFailureReason.handDiscardCap => 'coreActionHandDiscardCap',
    ActionFailureReason.boardMoveCap => 'coreActionBoardMoveCap',
    ActionFailureReason.noAvailableBoardMove =>
      'coreActionNoAvailableBoardMove',
    ActionFailureReason.moveBonusPending => 'coreActionMoveBonusPending',
    ActionFailureReason.handMustBeEmpty => 'coreActionHandMustBeEmpty',
    ActionFailureReason.drawFailed => 'coreActionDrawFailed',
    ActionFailureReason.noMoveHistory => 'coreActionNoMoveHistory',
    ActionFailureReason.undoSourceOccupied => 'coreActionUndoSourceOccupied',
    ActionFailureReason.undoTileMissing => 'coreActionUndoTileMissing',
    ActionFailureReason.handSizeCap => 'coreActionHandSizeCap',
    ActionFailureReason.rankMissing => 'coreActionRankMissing',
    ActionFailureReason.rankCannotGrow => 'coreActionRankCannotGrow',
    ActionFailureReason.scoringLineMissing => 'coreActionScoringLineMissing',
    ActionFailureReason.boardLineEmpty => 'coreActionBoardLineEmpty',
    ActionFailureReason.noRankToGrow => 'coreActionNoRankToGrow',
    ActionFailureReason.rankNeedsThree => 'coreActionRankNeedsThree',
    ActionFailureReason.fateNeedsTile => 'coreActionFateNeedsTile',
    ActionFailureReason.fateSetUnavailable => 'coreActionFateSetUnavailable',
    ActionFailureReason.noRankForBonus => 'coreActionNoRankForBonus',
    ActionFailureReason.matchingTileMissing => 'coreActionMatchingTileMissing',
    ActionFailureReason.noOtherColor => 'coreActionNoOtherColor',
    ActionFailureReason.matchingNumberMissing =>
      'coreActionMatchingNumberMissing',
    ActionFailureReason.sacrificeNeedsTwo => 'coreActionSacrificeNeedsTwo',
    ActionFailureReason.unknownRitual => 'coreActionUnknownRitual',
    ActionFailureReason.selectedTileMissing => 'coreActionSelectedTileMissing',
    ActionFailureReason.noTileTarget => 'coreActionNoTileTarget',
    ActionFailureReason.invalidAmount => 'coreActionInvalidAmount',
    ActionFailureReason.hookRequired => 'coreActionHookRequired',
    ActionFailureReason.notBattleItem => 'coreActionNotBattleItem',
    ActionFailureReason.itemNotReady => 'coreActionItemNotReady',
    ActionFailureReason.itemNotOwned => 'coreActionItemNotOwned',
    ActionFailureReason.notMarketItem => 'coreActionNotMarketItem',
    ActionFailureReason.goldAboveThreshold => 'coreActionGoldAboveThreshold',
    ActionFailureReason.noSession => 'coreActionNoSession',
    ActionFailureReason.bossCellBlocked => 'coreActionBossCellBlocked',
    ActionFailureReason.invalidPlacement => 'coreActionInvalidPlacement',
    ActionFailureReason.emptyDeck => 'coreActionEmptyDeck',
    ActionFailureReason.handFull => 'coreActionHandFull',
    ActionFailureReason.noBoardDiscards => 'coreActionNoBoardDiscards',
    ActionFailureReason.noHandDiscards => 'coreActionNoHandDiscards',
    ActionFailureReason.cellEmpty => 'coreActionCellEmpty',
    ActionFailureReason.handTileMissing => 'coreActionHandTileMissing',
    ActionFailureReason.selectBoardDiscard => 'coreActionSelectBoardDiscard',
    ActionFailureReason.selectHandDiscard => 'coreActionSelectHandDiscard',
    ActionFailureReason.noBoardMoves => 'coreActionNoBoardMoves',
    ActionFailureReason.moveSourceEmpty => 'coreActionMoveSourceEmpty',
    ActionFailureReason.moveDestinationOccupied =>
      'coreActionMoveDestinationOccupied',
    ActionFailureReason.bossMoveBlocked => 'coreActionBossMoveBlocked',
    ActionFailureReason.selectBoardMove => 'coreActionSelectBoardMove',
    ActionFailureReason.noMarket => 'coreActionNoMarket',
    ActionFailureReason.rerollGold => 'coreActionRerollGold',
    ActionFailureReason.offerMissing => 'coreActionOfferMissing',
    ActionFailureReason.jesterSlotsFull => 'coreActionJesterSlotsFull',
    ActionFailureReason.insufficientGold => 'coreActionInsufficientGold',
    ActionFailureReason.purchaseFailed => 'coreActionPurchaseFailed',
    ActionFailureReason.itemOwnershipCap => 'coreActionItemOwnershipCap',
    ActionFailureReason.itemPurchaseFailed => 'coreActionItemPurchaseFailed',
    ActionFailureReason.tileOfferMissing => 'coreActionTileOfferMissing',
    null => null,
  };
  return key == null
      ? failure.legacyMessage
      : context.translate(key, namedArgs: failure.args);
}

String expiryGuardLabel(
  BuildContext context,
  List<ItemEffectEvent> events, {
  bool detail = false,
}) {
  final board = events.any(
    (event) => event.kind == ItemEffectEventKind.boardDiscardAdded,
  );
  final draw = events.any(
    (event) => event.kind == ItemEffectEventKind.tileDrawn,
  );
  final key = switch ((board, draw, detail)) {
    (true, true, false) => 'coreActionRescueBoth',
    (true, true, true) => 'coreActionRescueBothDetail',
    (true, false, false) => 'coreActionRescueBoard',
    (true, false, true) => 'coreActionRescueBoardDetail',
    (_, _, false) => 'coreActionRescueDraw',
    (_, _, true) => 'coreActionRescueDrawDetail',
  };
  return context.translate(key);
}
