/// Card emblem asset path helpers.
class CardEmblemAssets {
  CardEmblemAssets._();

  static const String _basePath = 'assets/images/cards/emblems_4x';
  static const String _ritualBasePath = 'assets/images/cards/rituals_4x';

  static const Set<String> _ritualItemIds = {
    'line_memory',
    'cross_memory',
    'keystone_copy',
    'edge_copy',
    'rank_echo',
    'color_echo',
    'scarce_copy',
    'sealed_copy',
    'fate_three_kind_high',
    'fate_straight_low',
    'fate_straight_high',
    'fate_flush_low',
    'fate_flush_high',
    'fate_full_house_low',
    'rank_concord',
    'flush_house_fate',
    'flush_five_fate',
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

  static String item(String id) {
    final assetId = _legacyRitualAssetId(id);
    return _ritualItemIds.contains(id)
        ? '$_ritualBasePath/ritual_$assetId.png'
        : '$_basePath/item_$id.png';
  }

  static String _legacyRitualAssetId(String id) {
    return switch (id) {
      'fate_full_house_low' => 'risk_seal',
      'fate_flush_high' => 'anchor_seal',
      'fate_flush_low' => 'echo_seal',
      'fate_straight_high' => 'gold_seal_stamp',
      'fate_straight_low' => 'growth_seal',
      'fate_three_kind_high' => 'line_seal_stamp',
      'flush_house_fate' => 'rank_concord',
      'flush_five_fate' => 'color_concord',
      _ => id,
    };
  }
}
