import 'dart:math';

import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/boss_modifier.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_hand_growth.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../utils/seeded_random.dart';
import 'active_run_save_service.dart';
import 'new_run_setup.dart';

part 'debug_run_fixture_registry.dart';
part 'debug_run_fixture_builders.dart';

class DebugRunFixtureDefinition {
  const DebugRunFixtureDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.builder,
    this.autoTutorialsEnabled = false,
  });

  final String id;
  final String label;
  final String description;
  final ActiveRunRuntimeState Function() builder;
  final bool autoTutorialsEnabled;
}

class DebugRunFixtureService {
  DebugRunFixtureService._();

  static const String stage2ScoringSnapshot = 'stage2_scoring_snapshot';
  static const String stage2MarketResume = 'stage2_market_resume';
  static const String deckNeedleBattle = 'deck_needle_battle';
  static const String handCapacityIncreasePreviewBattle =
      'hand_capacity_increase_preview_battle';
  static const String handCapacityDeckControlBattle =
      'hand_capacity_deck_control_battle';
  static const String screenshotRunGrowthBattle =
      'screenshot_run_growth_battle';
  static const String marketModifierShop = 'market_modifier_shop';
  static const String slotUnlockMarket = 'slot_unlock_market';
  static const String safetyNetExpiryGuard = 'safety_net_expiry_guard';
  static const String gameOverInsightReady = 'game_over_insight_ready';
  static const String animationEffectsEyeCheck = 'animation_effects_eye_check';
  static const String itemMotionEyeCheck = 'item_motion_eye_check';
  static const String nextConfirmMotionEyeCheck =
      'next_confirm_motion_eye_check';
  static const String marketItemMotionEyeCheck = 'market_item_motion_eye_check';
  static const String specialTileMarketPreview = 'special_tile_market_preview';
  static const String specialTileBattlePreview = 'special_tile_battle_preview';
  static const String lineMemoryMarketPreview = 'line_memory_market_preview';
  static const String lineMemoryBattlePreview = 'line_memory_battle_preview';
  static const String ritualGrowthCopyBattlePreview =
      'ritual_growth_copy_battle_preview';
  static const String ritualDeckEchoBattlePreview =
      'ritual_deck_echo_battle_preview';
  static const String ritualSealOverrideBattlePreview =
      'ritual_seal_override_battle_preview';
  static const String ritualPruneBurnBattlePreview =
      'ritual_prune_burn_battle_preview';
  static const String s8ColorJesterStackPreview =
      's8_color_jester_stack_preview';
  static const String challengeS8EndpointRecovery =
      'challenge_s8_endpoint_recovery';
  static const String endlessHighStakesHudPreview =
      'endless_high_stakes_hud_preview';
  static const Map<String, String> fateLineTransformPreviewItemsByFixture = {
    'fate_royal_flush_battle_preview': 'number_mask',
    'fate_straight_flush_high_battle_preview': 'wild_thread',
    'fate_straight_flush_low_battle_preview': 'off_color_rite',
    'fate_four_kind_high_battle_preview': 'color_concord',
    'fate_four_kind_low_battle_preview': 'step_rite',
    'fate_full_house_high_battle_preview': 'rank_concord',
    'fate_full_house_low_battle_preview': 'fate_full_house_low',
    'fate_flush_house_battle_preview': 'flush_house_fate',
    'fate_flush_five_battle_preview': 'flush_five_fate',
    'fate_flush_high_battle_preview': 'fate_flush_high',
    'fate_flush_low_battle_preview': 'fate_flush_low',
    'fate_straight_high_battle_preview': 'fate_straight_high',
    'fate_straight_low_battle_preview': 'fate_straight_low',
    'fate_three_kind_high_battle_preview': 'fate_three_kind_high',
    'fate_three_kind_low_battle_preview': 'line_pruner',
    'fate_two_pair_high_battle_preview': 'trim_rank',
  };
  static const String finalBossCashOutReady = 'final_boss_cash_out_ready';
  static const String bossRowConstraintPreview = 'boss_row_constraint_preview';
  static const String bossColumnConstraintPreview =
      'boss_column_constraint_preview';
  static const String bossDiagonalConstraintPreview =
      'boss_diagonal_constraint_preview';
  static const String bossBoardCellBlockPreview =
      'boss_board_cell_block_preview';
  static const String bossBoardCellBlockRightColumnPreview =
      'boss_board_cell_block_right_column_preview';
  static const String bossBoardCellBlockMainDiagonalPreview =
      'boss_board_cell_block_main_diagonal_preview';

  static List<DebugRunFixtureDefinition> get fixtures =>
      List<DebugRunFixtureDefinition>.unmodifiable(_debugRunFixtures);

  static DebugRunFixtureDefinition? find(String fixtureId) {
    for (final fixture in _debugRunFixtures) {
      if (fixture.id == fixtureId) {
        return fixture;
      }
    }
    return null;
  }

  static ActiveRunRuntimeState? build(String fixtureId) {
    return find(fixtureId)?.builder();
  }

  static bool shouldAutoStartTutorials(String? fixtureId) {
    if (fixtureId == null) return true;
    return find(fixtureId)?.autoTutorialsEnabled ?? false;
  }
}
