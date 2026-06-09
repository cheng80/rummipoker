import '../game_presentation_timings.dart';
import 'game_card_metrics.dart';

const double kMarketOwnedCardWidth = kBattleItemSlotWidth;
const double kMarketOwnedCardHeight = kBattleItemSlotHeight;
const double kMarketOfferCardWidth = kBattleItemSlotWidth;
const double kMarketOfferCardHeight = kBattleItemSlotHeight;
const double kMarketCardSelectionInset = kJesterSelectionOutset;
const double kMarketOfferCardDisplayScale = 1.25;
const double kMarketOfferCardDisplayWidth =
    (kMarketOfferCardWidth + (kMarketCardSelectionInset * 2)) *
    kMarketOfferCardDisplayScale;
const double kMarketOfferCardDisplayHeight =
    (kMarketOfferCardHeight + (kMarketCardSelectionInset * 2)) *
    kMarketOfferCardDisplayScale;
const double kMarketShopCellWidth = 84.0;
const double kMarketShopCellHeight = kMarketOfferCardDisplayHeight + 22.0;
const double kMarketOwnedSlotRowHeight =
    kMarketOwnedCardHeight + (kMarketCardSelectionInset * 2);
const double kMarketOwnedTabSectionHeight = 108.0;
const double kMarketOwnedTabSectionGap = 6.0;
const double kMarketOwnedTabAreaHeight =
    (kMarketOwnedTabSectionHeight * 2) + kMarketOwnedTabSectionGap;
const double kMarketShopPanelHeight = 168.0;
const double kMarketSpeechPanelHeight = 132.0;
const double kMarketDescriptionFontSize = 12.0;
const double kMarketDescriptionLineHeight = 1.18;
const double kMarketDescriptionMinHeight =
    kMarketDescriptionFontSize * kMarketDescriptionLineHeight * 2;

const int kMarketOfferRowPageSlots = 3;
const double kMarketOfferRowGap = 8.0;

const Duration kMarketSlotUnlockBannerDelay =
    GamePresentationTimings.marketSlotUnlockBannerDelay;
const Duration kMarketSlotUnlockBannerVisible =
    GamePresentationTimings.marketSlotUnlockBannerVisible;
const Duration kMarketSlotUnlockPulseDuration =
    GamePresentationTimings.marketSlotUnlockPulse;
const Duration kMarketSlotUnlockBannerIn =
    GamePresentationTimings.marketSlotUnlockBannerIn;
const Duration kMarketPurchaseFlightDuration =
    GamePresentationTimings.marketPurchaseFlight;
