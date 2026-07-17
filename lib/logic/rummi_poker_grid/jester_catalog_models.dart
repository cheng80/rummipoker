part of 'jester_meta.dart';

class RummiJesterCatalog {
  const RummiJesterCatalog._(this._cards);

  factory RummiJesterCatalog.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final cards = decoded
        .cast<Map<String, dynamic>>()
        .map(RummiJesterCard.fromJson)
        .toList(growable: false);
    return RummiJesterCatalog._(cards);
  }

  final List<RummiJesterCard> _cards;

  List<RummiJesterCard> get all => List<RummiJesterCard>.unmodifiable(_cards);

  RummiJesterCard? findById(String id) {
    for (final card in _cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  List<RummiJesterCard> get shopCatalog {
    return _cards
        .where((card) => card.isSupportedInCurrentRunMeta)
        .toList(growable: false);
  }
}

class RummiShopOffer {
  RummiShopOffer({required this.slotIndex, required this.card, int? price})
    : price = price ?? card.baseCost;

  final int slotIndex;
  final RummiJesterCard card;
  final int price;
}

class RummiOverkillGrowthBonus {
  const RummiOverkillGrowthBonus({
    required this.rank,
    required this.amount,
    required this.finalScore,
    required this.thresholdScore,
  });

  final RummiHandRank rank;
  final int amount;
  final int finalScore;
  final int thresholdScore;
}

class RummiCashOutBreakdown {
  const RummiCashOutBreakdown({
    required this.stageIndex,
    required this.targetScore,
    required this.blindReward,
    required this.remainingBoardDiscards,
    required this.remainingHandDiscards,
    required this.perBoardDiscardBonus,
    required this.perHandDiscardBonus,
    required this.boardDiscardGold,
    required this.handDiscardGold,
    required this.economyBonuses,
    required this.economyGold,
    required this.totalGold,
    this.remainingBoardMoves = 0,
    this.perBoardMoveBonus = 0,
    this.boardMoveGold = 0,
    this.firstBlindClearBonusGold = 0,
    this.itemBonuses = const [],
    this.itemGold = 0,
    this.deckTileRewards = const [],
    this.overkillGrowthBonuses = const [],
    this.overkillGoldBonus = 0,
  });

  final int stageIndex;
  final int targetScore;
  final int blindReward;
  final int remainingBoardDiscards;
  final int remainingHandDiscards;
  final int remainingBoardMoves;
  final int perBoardDiscardBonus;
  final int perHandDiscardBonus;
  final int perBoardMoveBonus;
  final int boardDiscardGold;
  final int handDiscardGold;
  final int boardMoveGold;
  final List<RummiRoundEndEconomyBonus> economyBonuses;
  final int economyGold;
  final int firstBlindClearBonusGold;
  final List<RummiRoundEndItemBonus> itemBonuses;
  final int itemGold;
  final List<Tile> deckTileRewards;
  final List<RummiOverkillGrowthBonus> overkillGrowthBonuses;
  final int overkillGoldBonus;
  final int totalGold;

  RummiCashOutBreakdown copyWith({
    List<Tile>? deckTileRewards,
    List<RummiOverkillGrowthBonus>? overkillGrowthBonuses,
  }) {
    return RummiCashOutBreakdown(
      stageIndex: stageIndex,
      targetScore: targetScore,
      blindReward: blindReward,
      remainingBoardDiscards: remainingBoardDiscards,
      remainingHandDiscards: remainingHandDiscards,
      remainingBoardMoves: remainingBoardMoves,
      perBoardDiscardBonus: perBoardDiscardBonus,
      perHandDiscardBonus: perHandDiscardBonus,
      perBoardMoveBonus: perBoardMoveBonus,
      boardDiscardGold: boardDiscardGold,
      handDiscardGold: handDiscardGold,
      boardMoveGold: boardMoveGold,
      economyBonuses: economyBonuses,
      economyGold: economyGold,
      firstBlindClearBonusGold: firstBlindClearBonusGold,
      itemBonuses: itemBonuses,
      itemGold: itemGold,
      deckTileRewards: deckTileRewards ?? this.deckTileRewards,
      overkillGrowthBonuses:
          overkillGrowthBonuses ?? this.overkillGrowthBonuses,
      overkillGoldBonus: overkillGoldBonus,
      totalGold: totalGold,
    );
  }

  Map<String, dynamic> toJson() => {
    'stageIndex': stageIndex,
    'targetScore': targetScore,
    'blindReward': blindReward,
    'remainingBoardDiscards': remainingBoardDiscards,
    'remainingHandDiscards': remainingHandDiscards,
    'remainingBoardMoves': remainingBoardMoves,
    'perBoardDiscardBonus': perBoardDiscardBonus,
    'perHandDiscardBonus': perHandDiscardBonus,
    'perBoardMoveBonus': perBoardMoveBonus,
    'boardDiscardGold': boardDiscardGold,
    'handDiscardGold': handDiscardGold,
    'boardMoveGold': boardMoveGold,
    'economyBonuses': [
      for (final b in economyBonuses)
        {'jesterId': b.jesterId, 'displayName': b.displayName, 'gold': b.gold},
    ],
    'economyGold': economyGold,
    'firstBlindClearBonusGold': firstBlindClearBonusGold,
    'itemBonuses': [
      for (final b in itemBonuses)
        {'itemId': b.itemId, 'displayName': b.displayName, 'gold': b.gold},
    ],
    'itemGold': itemGold,
    'deckTileRewards': deckTileRewards.map((tile) => tile.toJson()).toList(),
    'overkillGrowthBonuses': [
      for (final b in overkillGrowthBonuses)
        {
          'rank': b.rank.name,
          'amount': b.amount,
          'finalScore': b.finalScore,
          'thresholdScore': b.thresholdScore,
        },
    ],
    'overkillGoldBonus': overkillGoldBonus,
    'totalGold': totalGold,
  };

  factory RummiCashOutBreakdown.fromJson(
    Map<String, dynamic> json,
  ) => RummiCashOutBreakdown(
    stageIndex: (json['stageIndex'] as num).toInt(),
    targetScore: (json['targetScore'] as num).toInt(),
    blindReward: (json['blindReward'] as num).toInt(),
    remainingBoardDiscards: (json['remainingBoardDiscards'] as num).toInt(),
    remainingHandDiscards: (json['remainingHandDiscards'] as num).toInt(),
    remainingBoardMoves: (json['remainingBoardMoves'] as num?)?.toInt() ?? 0,
    perBoardDiscardBonus: (json['perBoardDiscardBonus'] as num).toInt(),
    perHandDiscardBonus: (json['perHandDiscardBonus'] as num).toInt(),
    perBoardMoveBonus: (json['perBoardMoveBonus'] as num?)?.toInt() ?? 0,
    boardDiscardGold: (json['boardDiscardGold'] as num).toInt(),
    handDiscardGold: (json['handDiscardGold'] as num).toInt(),
    boardMoveGold: (json['boardMoveGold'] as num?)?.toInt() ?? 0,
    economyBonuses: [
      for (final b in json['economyBonuses'] as List<dynamic>? ?? const [])
        RummiRoundEndEconomyBonus(
          jesterId: b['jesterId'] as String,
          displayName: b['displayName'] as String,
          gold: (b['gold'] as num).toInt(),
        ),
    ],
    economyGold: (json['economyGold'] as num).toInt(),
    firstBlindClearBonusGold:
        (json['firstBlindClearBonusGold'] as num?)?.toInt() ?? 0,
    itemBonuses: [
      for (final b in json['itemBonuses'] as List<dynamic>? ?? const [])
        RummiRoundEndItemBonus(
          itemId: b['itemId'] as String,
          displayName: b['displayName'] as String,
          gold: (b['gold'] as num).toInt(),
        ),
    ],
    itemGold: (json['itemGold'] as num?)?.toInt() ?? 0,
    deckTileRewards: [
      for (final tile in json['deckTileRewards'] as List<dynamic>? ?? const [])
        Tile.fromJson(Map<String, dynamic>.from(tile as Map)),
    ],
    overkillGrowthBonuses: [
      for (final b
          in json['overkillGrowthBonuses'] as List<dynamic>? ?? const [])
        RummiOverkillGrowthBonus(
          rank: RummiHandRank.values.byName(b['rank'] as String),
          amount: (b['amount'] as num).toInt(),
          finalScore: (b['finalScore'] as num).toInt(),
          thresholdScore: (b['thresholdScore'] as num).toInt(),
        ),
    ],
    overkillGoldBonus: (json['overkillGoldBonus'] as num?)?.toInt() ?? 0,
    totalGold: (json['totalGold'] as num).toInt(),
  );
}

class RummiRoundEndEconomyBonus {
  const RummiRoundEndEconomyBonus({
    required this.jesterId,
    required this.displayName,
    required this.gold,
  });

  final String jesterId;
  final String displayName;
  final int gold;
}

class RummiRoundEndItemBonus {
  const RummiRoundEndItemBonus({
    required this.itemId,
    required this.displayName,
    required this.gold,
  });

  final String itemId;
  final String displayName;
  final int gold;
}

class RummiEconomyConfig {
  const RummiEconomyConfig._();

  static const int startingGold = 0;
  static const int stageClearGoldBase = 4;
  static const int firstBlindClearBonusGold = 2;
  static const int remainingBoardDiscardGoldBonus = 2;
  static const int remainingHandDiscardGoldBonus = 1;
  static const int remainingBoardMoveGoldBonus = 1;
  static const int marketPriceScaleNumerator = 11;
  static const int marketPriceScaleDenominator = 5;
  static const int shopBaseRerollCost = 5;
  static const int shopRerollCostStep = 2;
  static const int shopFirstRerollDiscount = shopBaseRerollCost;
  static const int shopOfferCount = 3;

  static int scaledMarketPrice(int basePrice) {
    if (basePrice <= 0) return 0;
    return (basePrice * marketPriceScaleNumerator / marketPriceScaleDenominator)
        .round();
  }
}

enum RummiStationMarketBand { early, mid, late }

/// 스테이션 구간별 상점 가중치 정책.
///
/// 시뮬의 `shop_slot_market_v9`를 실제 런타임이 이해할 수 있는 Jester rarity와
/// Item tag/rarity 가중치로 번역한다. 저장 데이터가 아니라 상점 생성 시점의
/// transient policy라서, 실제 save schema를 늘리지 않는다.
enum RummiMarketPressureProfile { standard, highStakes }

class RummiStationBandMarketPolicy {
  const RummiStationBandMarketPolicy._(
    this.stageIndex,
    this.band,
    this.pressureProfile,
  );

  factory RummiStationBandMarketPolicy.forStage(
    int stageIndex, {
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final stage = stageIndex < 1 ? 1 : stageIndex;
    return RummiStationBandMarketPolicy._(
      stage,
      stage <= 2
          ? RummiStationMarketBand.early
          : stage <= 5
          ? RummiStationMarketBand.mid
          : RummiStationMarketBand.late,
      pressureProfile,
    );
  }

  final int stageIndex;
  final RummiStationMarketBand band;
  final RummiMarketPressureProfile pressureProfile;

  int jesterRarityWeight(
    RummiJesterRarity rarity, {
    int rarityWeightBonus = 0,
  }) {
    final tier = stageIndex >= 6 ? 6 : stageIndex;
    return switch (rarity) {
      RummiJesterRarity.common => switch (tier) {
        1 => 860,
        2 => 780,
        3 => 700,
        4 => 620,
        5 => 550,
        _ => 480,
      },
      RummiJesterRarity.uncommon => switch (tier) {
        1 => 120,
        2 => 170,
        3 => 220,
        4 => 270,
        5 => 310,
        _ => 340,
      },
      RummiJesterRarity.rare =>
        switch (tier) {
              1 => 20,
              2 => 40,
              3 => 70,
              4 => 100,
              5 => 130,
              _ => 160,
            } +
            rarityWeightBonus,
      RummiJesterRarity.legendary =>
        switch (tier) {
              1 => 1,
              2 => 2,
              3 => 4,
              4 => 8,
              5 => 12,
              _ => 20,
            } +
            (rarityWeightBonus ~/ 2),
    };
  }

  int itemOfferWeight(
    ItemDefinition item, {
    Set<String> missingGrowthTags = const {},
    int collectionWeightBonus = 0,
  }) {
    var weight = _itemRarityBaseWeight(item.rarity);
    weight += _itemTagBonus(item.tags);
    weight += _missingGrowthTagBonus(item.tags, missingGrowthTags);
    weight += collectionWeightBonus;
    if (item.usableInBattle) {
      weight += band == RummiStationMarketBand.late ? 30 : 50;
    }
    if (item.isPassive) {
      weight += band == RummiStationMarketBand.early ? 20 : 70;
    }
    return weight < 1 ? 1 : weight;
  }

  int _itemRarityBaseWeight(ItemRarity rarity) {
    return switch (band) {
      RummiStationMarketBand.early => switch (rarity) {
        ItemRarity.common => 580,
        ItemRarity.uncommon => 220,
        ItemRarity.rare => 60,
        ItemRarity.legendary => 4,
      },
      RummiStationMarketBand.mid => switch (rarity) {
        ItemRarity.common => 360,
        ItemRarity.uncommon => 420,
        ItemRarity.rare => 140,
        ItemRarity.legendary => 10,
      },
      RummiStationMarketBand.late => switch (rarity) {
        ItemRarity.common => 260,
        ItemRarity.uncommon => 360,
        ItemRarity.rare => 260,
        ItemRarity.legendary => 30,
      },
    };
  }

  int _itemTagBonus(List<String> tags) {
    var bonus = 0;
    bool has(String tag) => tags.contains(tag);
    if (has('fate_transform')) {
      bonus -= switch (band) {
        RummiStationMarketBand.early => 120,
        RummiStationMarketBand.mid => 70,
        RummiStationMarketBand.late => 20,
      };
    }
    if (has('ritual') && !has('fate_transform')) {
      bonus -= band == RummiStationMarketBand.early ? 55 : 25;
    }
    switch (band) {
      case RummiStationMarketBand.early:
        if (has('economy') || has('market')) bonus += 120;
        if (has('discard') || has('safety') || has('move')) bonus += 95;
        if (has('tile_color') || has('rank') || has('draw')) bonus += 65;
        if (has('legendary')) bonus -= 20;
      case RummiStationMarketBand.mid:
        if (has('score') || has('rank') || has('tile_color')) bonus += 150;
        if (has('market') || has('rarity') || has('capacity')) bonus += 75;
        if (has('discard') || has('safety') || has('move')) bonus += 65;
        if (has('boss')) bonus += 40;
      case RummiStationMarketBand.late:
        if (has('boss') || has('legendary')) bonus += 130;
        if (has('score') || has('xmult') || has('rarity')) bonus += 115;
        if (has('market') || has('capacity')) bonus += 85;
        if (has('safety') || has('move') || has('discard')) bonus += 55;
        // S7~S8은 점수 전환 후보보다 덱/타일 형상 보정 후보가 부족했다.
        // 직접 지급이 아니라 후반 마켓 후보군에 더 안정적으로 남기는 보정이다.
        final isShapeCorrection =
            has('tile_color') || has('draw') || (has('rank') && !has('score'));
        if (stageIndex >= 7 && isShapeCorrection) bonus += 80;
    }
    return bonus;
  }

  int _missingGrowthTagBonus(
    List<String> itemTags,
    Set<String> missingGrowthTags,
  ) {
    if (missingGrowthTags.isEmpty) return 0;
    var matched = 0;
    for (final tag in itemTags) {
      if (missingGrowthTags.contains(tag)) {
        matched += 1;
      }
    }
    // 직접 지급이 아니라 등장 확률만 보정한다. high stakes는 난도가
    // 높으므로 필요한 성장축 후보가 마켓에 남는 힘만 조금 더 준다.
    final cappedMatches = matched > 2 ? 2 : matched;
    final bonusPerMatch =
        pressureProfile == RummiMarketPressureProfile.highStakes ? 70 : 45;
    return cappedMatches * bonusPerMatch;
  }
}

class RummiMarketModifierState {
  const RummiMarketModifierState({
    this.nextRerollDiscount = 0,
    this.firstRerollDiscount = 0,
    this.nextPurchaseDiscount = 0,
    this.nextJesterPurchaseDiscount = 0,
    this.nextItemPurchaseDiscount = 0,
    this.cheapestFirstOfferDiscount = 0,
    this.extraJesterOfferSlots = 0,
    this.nextMarketExtraJesterOfferSlots = 0,
    this.extraItemOfferSlots = 0,
    this.itemOfferRerollOffset = 0,
    int? quickSlotOfferRerollOffset,
    int? passiveOfferRerollOffset,
    int? toolOfferRerollOffset,
    int? gearOfferRerollOffset,
    this.consumedItemOfferIds = const [],
    this.pinnedItemOfferKeys = const [],
    this.rarityWeightBonus = 0,
  }) : quickSlotOfferRerollOffset =
           quickSlotOfferRerollOffset ?? itemOfferRerollOffset,
       passiveOfferRerollOffset =
           passiveOfferRerollOffset ?? itemOfferRerollOffset,
       toolOfferRerollOffset = toolOfferRerollOffset ?? itemOfferRerollOffset,
       gearOfferRerollOffset = gearOfferRerollOffset ?? itemOfferRerollOffset;

  factory RummiMarketModifierState.fromJson(Map<String, dynamic> json) {
    return RummiMarketModifierState(
      nextRerollDiscount: _nonNegativeJsonInt(json['nextRerollDiscount']),
      firstRerollDiscount: _nonNegativeJsonInt(json['firstRerollDiscount']),
      nextPurchaseDiscount: _nonNegativeJsonInt(json['nextPurchaseDiscount']),
      nextJesterPurchaseDiscount: _nonNegativeJsonInt(
        json['nextJesterPurchaseDiscount'],
      ),
      nextItemPurchaseDiscount: _nonNegativeJsonInt(
        json['nextItemPurchaseDiscount'],
      ),
      cheapestFirstOfferDiscount: _nonNegativeJsonInt(
        json['cheapestFirstOfferDiscount'],
      ),
      extraJesterOfferSlots: _nonNegativeJsonInt(json['extraJesterOfferSlots']),
      nextMarketExtraJesterOfferSlots: _nonNegativeJsonInt(
        json['nextMarketExtraJesterOfferSlots'],
      ),
      extraItemOfferSlots: _nonNegativeJsonInt(json['extraItemOfferSlots']),
      itemOfferRerollOffset: _nonNegativeJsonInt(json['itemOfferRerollOffset']),
      quickSlotOfferRerollOffset: json.containsKey('quickSlotOfferRerollOffset')
          ? _nonNegativeJsonInt(json['quickSlotOfferRerollOffset'])
          : _nonNegativeJsonInt(json['itemOfferRerollOffset']),
      passiveOfferRerollOffset: json.containsKey('passiveOfferRerollOffset')
          ? _nonNegativeJsonInt(json['passiveOfferRerollOffset'])
          : _nonNegativeJsonInt(json['itemOfferRerollOffset']),
      toolOfferRerollOffset: json.containsKey('toolOfferRerollOffset')
          ? _nonNegativeJsonInt(json['toolOfferRerollOffset'])
          : _nonNegativeJsonInt(json['itemOfferRerollOffset']),
      gearOfferRerollOffset: json.containsKey('gearOfferRerollOffset')
          ? _nonNegativeJsonInt(json['gearOfferRerollOffset'])
          : _nonNegativeJsonInt(json['itemOfferRerollOffset']),
      consumedItemOfferIds: _stringListFromJson(json['consumedItemOfferIds']),
      pinnedItemOfferKeys: _stringListFromJson(json['pinnedItemOfferKeys']),
      rarityWeightBonus: _nonNegativeJsonInt(json['rarityWeightBonus']),
    );
  }

  final int nextRerollDiscount;
  final int firstRerollDiscount;
  final int nextPurchaseDiscount;
  final int nextJesterPurchaseDiscount;
  final int nextItemPurchaseDiscount;
  final int cheapestFirstOfferDiscount;
  final int extraJesterOfferSlots;
  final int nextMarketExtraJesterOfferSlots;
  final int extraItemOfferSlots;
  final int itemOfferRerollOffset;
  final int quickSlotOfferRerollOffset;
  final int passiveOfferRerollOffset;
  final int toolOfferRerollOffset;
  final int gearOfferRerollOffset;
  final List<String> consumedItemOfferIds;
  final List<String> pinnedItemOfferKeys;
  final int rarityWeightBonus;

  bool get isEmpty =>
      nextRerollDiscount == 0 &&
      firstRerollDiscount == 0 &&
      nextPurchaseDiscount == 0 &&
      nextJesterPurchaseDiscount == 0 &&
      nextItemPurchaseDiscount == 0 &&
      cheapestFirstOfferDiscount == 0 &&
      extraJesterOfferSlots == 0 &&
      nextMarketExtraJesterOfferSlots == 0 &&
      extraItemOfferSlots == 0 &&
      itemOfferRerollOffset == 0 &&
      quickSlotOfferRerollOffset == 0 &&
      passiveOfferRerollOffset == 0 &&
      toolOfferRerollOffset == 0 &&
      gearOfferRerollOffset == 0 &&
      consumedItemOfferIds.isEmpty &&
      pinnedItemOfferKeys.isEmpty &&
      rarityWeightBonus == 0;

  int get jesterOfferSlotCount =>
      RummiEconomyConfig.shopOfferCount + extraJesterOfferSlots;

  int get itemOfferSlotCount =>
      RummiEconomyConfig.shopOfferCount + extraItemOfferSlots;

  int itemOfferRerollOffsetFor(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => quickSlotOfferRerollOffset,
      ItemPlacement.passiveRack => passiveOfferRerollOffset,
      ItemPlacement.inventory => toolOfferRerollOffset,
      ItemPlacement.equipped => gearOfferRerollOffset,
    };
  }

  Map<String, dynamic> toJson() => {
    'nextRerollDiscount': nextRerollDiscount,
    'firstRerollDiscount': firstRerollDiscount,
    'nextPurchaseDiscount': nextPurchaseDiscount,
    'nextJesterPurchaseDiscount': nextJesterPurchaseDiscount,
    'nextItemPurchaseDiscount': nextItemPurchaseDiscount,
    'cheapestFirstOfferDiscount': cheapestFirstOfferDiscount,
    'extraJesterOfferSlots': extraJesterOfferSlots,
    'nextMarketExtraJesterOfferSlots': nextMarketExtraJesterOfferSlots,
    'extraItemOfferSlots': extraItemOfferSlots,
    'itemOfferRerollOffset': itemOfferRerollOffset,
    'quickSlotOfferRerollOffset': quickSlotOfferRerollOffset,
    'passiveOfferRerollOffset': passiveOfferRerollOffset,
    'toolOfferRerollOffset': toolOfferRerollOffset,
    'gearOfferRerollOffset': gearOfferRerollOffset,
    'consumedItemOfferIds': consumedItemOfferIds,
    'pinnedItemOfferKeys': pinnedItemOfferKeys,
    'rarityWeightBonus': rarityWeightBonus,
  };

  RummiMarketModifierState copyWith({
    int? nextRerollDiscount,
    int? firstRerollDiscount,
    int? nextPurchaseDiscount,
    int? nextJesterPurchaseDiscount,
    int? nextItemPurchaseDiscount,
    int? cheapestFirstOfferDiscount,
    int? extraJesterOfferSlots,
    int? nextMarketExtraJesterOfferSlots,
    int? extraItemOfferSlots,
    int? itemOfferRerollOffset,
    int? quickSlotOfferRerollOffset,
    int? passiveOfferRerollOffset,
    int? toolOfferRerollOffset,
    int? gearOfferRerollOffset,
    List<String>? consumedItemOfferIds,
    List<String>? pinnedItemOfferKeys,
    int? rarityWeightBonus,
  }) {
    return RummiMarketModifierState(
      nextRerollDiscount: nextRerollDiscount ?? this.nextRerollDiscount,
      firstRerollDiscount: firstRerollDiscount ?? this.firstRerollDiscount,
      nextPurchaseDiscount: nextPurchaseDiscount ?? this.nextPurchaseDiscount,
      nextJesterPurchaseDiscount:
          nextJesterPurchaseDiscount ?? this.nextJesterPurchaseDiscount,
      nextItemPurchaseDiscount:
          nextItemPurchaseDiscount ?? this.nextItemPurchaseDiscount,
      cheapestFirstOfferDiscount:
          cheapestFirstOfferDiscount ?? this.cheapestFirstOfferDiscount,
      extraJesterOfferSlots:
          extraJesterOfferSlots ?? this.extraJesterOfferSlots,
      nextMarketExtraJesterOfferSlots:
          nextMarketExtraJesterOfferSlots ??
          this.nextMarketExtraJesterOfferSlots,
      extraItemOfferSlots: extraItemOfferSlots ?? this.extraItemOfferSlots,
      itemOfferRerollOffset:
          itemOfferRerollOffset ?? this.itemOfferRerollOffset,
      quickSlotOfferRerollOffset:
          quickSlotOfferRerollOffset ?? this.quickSlotOfferRerollOffset,
      passiveOfferRerollOffset:
          passiveOfferRerollOffset ?? this.passiveOfferRerollOffset,
      toolOfferRerollOffset:
          toolOfferRerollOffset ?? this.toolOfferRerollOffset,
      gearOfferRerollOffset:
          gearOfferRerollOffset ?? this.gearOfferRerollOffset,
      consumedItemOfferIds: consumedItemOfferIds ?? this.consumedItemOfferIds,
      pinnedItemOfferKeys: pinnedItemOfferKeys ?? this.pinnedItemOfferKeys,
      rarityWeightBonus: rarityWeightBonus ?? this.rarityWeightBonus,
    );
  }

  static String itemOfferKey(ItemPlacement placement, String itemId) {
    return '${placement.name}:${canonicalItemId(itemId)}';
  }

  static bool itemOfferKeyMatchesPlacement(
    String key,
    ItemPlacement placement,
  ) {
    return key.startsWith('${placement.name}:');
  }

  static String itemIdFromOfferKey(String key) {
    final separator = key.indexOf(':');
    if (separator < 0 || separator == key.length - 1) return key;
    return canonicalItemId(key.substring(separator + 1));
  }

  static int _nonNegativeJsonInt(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  static List<String> _stringListFromJson(Object? value) {
    return List<String>.unmodifiable(
      (value as List<dynamic>? ?? const []).whereType<String>(),
    );
  }
}

enum RummiSlotUnlockKind {
  jester,
  quickSlot,
  passiveRelic;

  String get persistenceValue {
    return switch (this) {
      RummiSlotUnlockKind.jester => 'jester',
      RummiSlotUnlockKind.quickSlot => 'quickSlot',
      RummiSlotUnlockKind.passiveRelic => 'passiveRelic',
    };
  }

  String get displayLabel {
    return switch (this) {
      RummiSlotUnlockKind.jester => 'Jester 슬롯 +1',
      RummiSlotUnlockKind.quickSlot => 'Item 슬롯 +1',
      RummiSlotUnlockKind.passiveRelic => 'Passive 슬롯 +1',
    };
  }

  static RummiSlotUnlockKind? fromPersistenceValue(String value) {
    return switch (value) {
      'jester' => RummiSlotUnlockKind.jester,
      'quickSlot' => RummiSlotUnlockKind.quickSlot,
      'passiveRelic' => RummiSlotUnlockKind.passiveRelic,
      _ => null,
    };
  }
}
