/// Card emblem asset path helpers.
class CardEmblemAssets {
  CardEmblemAssets._();

  static const String _basePath = 'assets/images/cards/emblems_4x';
  static const String _ritualBasePath = 'assets/images/cards/rituals_4x';

  static const Set<String> _ritualItemIds = {
    'line_memory',
    'minor_memory',
    'cross_memory',
    'thin_memory',
    'boss_memory',
    'keystone_copy',
    'edge_copy',
    'rank_echo',
    'color_echo',
    'scarce_copy',
    'sealed_copy',
    'line_seal_stamp',
    'growth_seal',
    'gold_seal_stamp',
    'echo_seal',
    'anchor_seal',
    'risk_seal',
    'rank_concord',
    'step_rite',
    'color_concord',
    'off_color_rite',
    'wild_thread',
    'number_mask',
    'line_pruner',
    'trim_color',
    'trim_rank',
    'deadwood_burn',
    'sacrifice_line',
    'cross_rite',
    'corner_rite',
    'center_rite',
    'diagonal_rite',
    'bridge_rite',
    'ritual_coupon',
    'ritual_lens',
    'line_pack_ticket',
    'seal_vendor',
    'prune_vendor',
  };

  static String jester(String id) => '$_basePath/jester_$id.png';

  static String item(String id) => _ritualItemIds.contains(id)
      ? '$_ritualBasePath/ritual_$id.png'
      : '$_basePath/item_$id.png';
}
