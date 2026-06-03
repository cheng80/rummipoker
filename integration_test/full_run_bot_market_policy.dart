import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';

/// 풀런봇의 상점 구매/교체 판단 점수.
///
/// 후반 고점수 구간에서도 좁은 단일 족보 보너스만 보고 누적형 카드를
/// 버리지 않는다. 실제 손패/보드 흐름에서 여러 족보가 이어지는지가 더 중요하다.
int fullRunBotJesterScore(
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
  switch (card.conditionType) {
    case 'flush':
      score += stage >= 6 ? 360 : 220;
    case 'tile_color_scored':
      score += stage >= 6 ? 320 : 180;
  }
  return score;
}

/// 풀런봇의 Item 구매 판단 점수.
///
/// Q-Slot 증거 확보용 구매에 갇히지 않고, 후반 성장축이 되는 Tool/Gear도
/// 같은 후보군에서 평가한다.
int fullRunBotItemScore(ItemDefinition item, {required int stage}) {
  var score = switch (item.rarity) {
    ItemRarity.legendary => 900,
    ItemRarity.rare => 700,
    ItemRarity.uncommon => 520,
    ItemRarity.common => 340,
  };
  switch (item.placement) {
    case ItemPlacement.inventory:
      score += 80;
    case ItemPlacement.equipped:
      score += 70;
    case ItemPlacement.quickSlot:
      score += 50;
    case ItemPlacement.passiveRack:
      score += 40;
  }
  switch (item.effect.op) {
    case 'add_hand_rank_progress':
      final handRank = item.effect.value('rank');
      if (handRank == 'flush' || handRank == 'straightFlush') {
        score += stage >= 4 ? 680 : 420;
      } else {
        score += stage >= 4 ? 520 : 300;
      }
    case 'peek_deck_discard_one':
      score += stage >= 5 ? 280 : 120;
    case 'mark_next_board_move_bonus':
    case 'add_board_move':
      score += stage >= 5 ? 240 : 100;
    case 'add_board_discard':
    case 'add_hand_discard':
      score += stage >= 5 ? 180 : 80;
    case 'increase_hand_size':
      score += stage >= 4 ? 220 : 140;
    case 'draw_if_hand_empty':
      score += 120;
    case 'chips_bonus':
    case 'mult_bonus':
    case 'xmult_bonus':
    case 'add_percent_of_first_confirm_score':
      score += stage >= 6 ? 220 : 120;
  }
  return score;
}

int fullRunBotDeckTileScore(Tile tile) {
  final rankScore = tile.number >= 10 ? 18 : tile.number;
  var score = 40 + rankScore + tile.baseChipValue;
  if (tile.enhancement != null) score += 36;
  if (tile.seal != null) score += 34;
  if (tile.edition != null) score += 38;
  switch (tile.enhancement) {
    case TileEnhancement.wildPainted:
      score += 24;
    case TileEnhancement.glassTile:
      score += 20;
    case TileEnhancement.scoreGilded:
      score += 16;
    case TileEnhancement.chipInlaid:
    case TileEnhancement.goldTile:
    case TileEnhancement.luckyTile:
      score += 12;
    case null:
      break;
  }
  switch (tile.seal) {
    case TileSeal.redSeal:
    case TileSeal.anchorSeal:
    case TileSeal.echoSeal:
    case TileSeal.crossMemory:
    case TileSeal.bridgeSeal:
      score += 18;
    case TileSeal.blueSeal:
    case TileSeal.lineMark:
    case TileSeal.growthSeal:
    case TileSeal.goldSeal:
    case TileSeal.fractureSeal:
      score += 12;
    case null:
      break;
  }
  return score;
}
