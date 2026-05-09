import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';

/// 공모전 풀런봇의 상점 구매/교체 판단 점수.
///
/// 후반 고점수 구간에서도 좁은 단일 족보 보너스만 보고 누적형 카드를
/// 버리지 않는다. 실제 손패/보드 흐름에서 여러 족보가 이어지는지가 더 중요하다.
int contestFullRunBotJesterScore(
  RummiJesterCard card, {
  int stateValue = 0,
  int stage = 1,
}) {
  var score = switch (card.rarity) {
    RummiJesterRarity.legendary => 900,
    RummiJesterRarity.rare => 720,
    RummiJesterRarity.uncommon => 540,
    RummiJesterRarity.common => 360,
  };
  switch (card.effectType) {
    case 'xmult_bonus':
      score += 420 + ((card.xValue ?? 1) * 120).round();
    case 'mult_bonus':
      score += 180 + (card.value ?? 0) * 8;
    case 'chips_bonus':
      score += 120 + (card.value ?? 0);
    case 'stateful_growth':
      score += 180 + stateValue * 8;
    case 'economy':
      score += 40;
  }
  switch (card.id) {
    case 'the_family':
    case 'the_order':
    case 'the_trio':
      score += 260;
    case 'mystic_summit':
      score += 220;
    case 'half_jester':
      score += 180;
    case 'ride_the_bus':
      score += stateValue > 0 ? stateValue * 12 : (stage >= 7 ? 260 : -180);
    case 'green_jester':
      score += stateValue > 0 ? stateValue * 12 : -260;
    case 'clever_jester':
      score += 220;
    case 'jester_stencil':
      if (stage >= 6) {
        score -= 760;
      }
    case 'jolly_jester':
    case 'zany_jester':
    case 'mad_jester':
    case 'droll_jester':
    case 'sly_jester':
      score += stage >= 6 ? 180 : 40;
    case 'wrathful_jester':
    case 'gluttonous_jester':
    case 'lusty_jester':
      score += stage >= 6 ? 240 : 80;
    case 'egg':
    case 'delayed_gratification':
      score -= 120;
  }
  if (stage >= 6) {
    switch (card.id) {
      case 'the_family':
      case 'the_order':
      case 'the_trio':
      case 'clever_jester':
      case 'mystic_summit':
      case 'half_jester':
        score += 140;
      case 'wrathful_jester':
      case 'gluttonous_jester':
      case 'lusty_jester':
      case 'jolly_jester':
      case 'zany_jester':
      case 'mad_jester':
      case 'droll_jester':
      case 'sly_jester':
        score += 120;
      case 'green_jester':
        score += stateValue > 0 ? 90 : -120;
      case 'ride_the_bus':
        score += stateValue > 0 ? 90 : (stage >= 7 ? 180 : -120);
    }
  }
  if (stage >= 8) {
    switch (card.id) {
      case 'clever_jester':
        score += 180;
      case 'droll_jester':
      case 'sly_jester':
      case 'jolly_jester':
      case 'zany_jester':
      case 'mad_jester':
      case 'wrathful_jester':
      case 'gluttonous_jester':
      case 'lusty_jester':
        score += 120;
    }
  }
  return score;
}
