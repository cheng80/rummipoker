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
const double kMarketShopPanelHeight = 168.0;
const double kMarketSpeechPanelHeight = 132.0;
const double kMarketDescriptionFontSize = 12.0;
const double kMarketDescriptionLineHeight = 1.18;
const double kMarketDescriptionMinHeight =
    kMarketDescriptionFontSize * kMarketDescriptionLineHeight * 2;

const int kMarketOfferRowPageSlots = 3;
const double kMarketOfferRowGap = 8.0;

const Duration kMarketSlotUnlockBannerDelay = Duration(milliseconds: 850);
const Duration kMarketSlotUnlockBannerVisible = Duration(milliseconds: 1250);
const Duration kMarketSlotUnlockPulseDuration = Duration(milliseconds: 1200);
const Duration kMarketSlotUnlockBannerIn = Duration(milliseconds: 420);
const Duration kMarketPurchaseFlightDuration =
    GamePresentationTimings.marketPurchaseFlight;
