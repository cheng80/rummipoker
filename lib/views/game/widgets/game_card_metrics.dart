/// Shared gameplay card, slot, and board dimensions.
///
/// Keep runtime card numbers here so market, battle, archive, and previews stay
/// visually aligned when the generated card form changes.
const double kGameTileAspectRatio = 1.0;
const double kBoardFrameInset = 10.0;
const double kBoardGridGap = 1.5;
const double kBoardTileInnerPadding = 2.0;
const double kHandTileModifierBadgeScale = 1.22;

const double kGameHudHeight = 62.0;
const double kGameHudBlindWidth = 76.0;
const double kGameHudGoldWidth = 132.0;
const double kGameHudGap = 6.0;
const double kGameHudRadius = 18.0;
const double kGameHudProgressRadius = 99.0;

const double kBattleItemSlotWidth = 54.0;
const double kBattleItemSlotHeight = 70.0;
const double kBattleSlotCardInset = 2.0;

const int kBattleQuickSlotDisplayCount = 3;
const int kBattlePassiveSlotDisplayCount = 2;
const int kBattleToolSlotDisplayCount = 3;
const int kBattleGearSlotDisplayCount = 2;
const int kBattleBaseUnlockedQuickSlots = 2;
const int kBattleBaseUnlockedPassiveSlots = 1;

const double kJesterCardWidth = kBattleItemSlotWidth;
const double kJesterCardHeight = kBattleItemSlotHeight;
const double kJesterSelectionOutset = 3.0;
const double kJesterSelectionBorderWidth = 3.0;

const double kRuntimeCardOuterRadius = 4.0;
const double kRuntimeCardInnerRadius = 4.0;
const double kRuntimeCardArtRadius = 3.0;
const double kRuntimeCardSmallRadius = 2.0;
const double kRuntimeCardBarHeight = 5.0;
const double kRuntimeCardTypeBadgeWidth = 9.0;
const double kRuntimeCardTypeBadgeHeight = 5.0;
const double kRuntimeCardArtWidth = 41.0;
const double kRuntimeCardArtHeight = 38.0;
const double kBattleRuntimeCardArtHeight = kRuntimeCardArtHeight;
