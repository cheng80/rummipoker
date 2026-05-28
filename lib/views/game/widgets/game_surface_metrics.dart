import 'package:flutter/material.dart';

/// Shared frame and transient overlay dimensions for game runtime screens.
///
/// These numbers describe the visible phone-frame surface and route transition
/// cards, not saved gameplay state.
const double kGameSurfaceFrameRadius = 28.0;
const double kGameSurfaceShadowBlur = 28.0;
const double kGameSurfaceShadowSpread = 4.0;
const double kGameSurfaceBorderWidth = 1.2;
const EdgeInsets kBattleSurfacePadding = EdgeInsets.fromLTRB(12, 6, 12, 10);
const EdgeInsets kMarketSurfacePadding = EdgeInsets.fromLTRB(14, 6, 14, 6);

const double kGameTransitionCardWidth = 282.0;
const double kGameTransitionCardCompactWidth = 280.0;
const double kGameTransitionCardRadius = 8.0;
const double kGameTransitionCardBorderWidth = 1.2;
const double kGameTransitionCardShadowBlur = 24.0;
const Offset kGameTransitionCardShadowOffset = Offset(0, 12);
const EdgeInsets kGameTransitionCardPadding = EdgeInsets.fromLTRB(
  20,
  18,
  20,
  18,
);
const double kGameTransitionIconSize = 32.0;
const double kGameTransitionTitleFontSize = 20.0;
const double kGameTransitionBodyFontSize = 13.0;
const double kGameTransitionIconTitleGap = 10.0;
const double kGameTransitionTitleBodyGap = 6.0;
const double kGameTransitionBodyProgressGap = 14.0;
const double kGameTransitionProgressRadius = 999.0;
const double kGameTransitionProgressHeight = 5.0;
const double kSettlementToMarketTransitionYOffset = 14.0;
const double kNextStationTransitionYOffset = 16.0;

const double kGamePauseVeilRadius = 18.0;
const EdgeInsets kGamePauseVeilPadding = EdgeInsets.symmetric(
  horizontal: 22,
  vertical: 16,
);
const double kGamePauseVeilFontSize = 18.0;
