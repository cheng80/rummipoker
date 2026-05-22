import 'dart:convert';
import 'dart:math';

import 'hand_rank.dart';
import 'item_definition.dart';
import 'models/tile.dart';
import 'models/poker_deck.dart';
import 'rummi_hand_growth.dart';
import 'rummi_poker_grid_session.dart';

enum RummiJesterRarity { common, uncommon, rare, legendary }

class RummiJesterCard {
  const RummiJesterCard({
    required this.id,
    required this.displayName,
    required this.rarity,
    required this.baseCost,
    required this.effectText,
    required this.effectType,
    required this.trigger,
    required this.conditionType,
    required this.conditionValue,
    required this.value,
    required this.xValue,
    required this.mappedTileColors,
    required this.mappedTileNumbers,
  });

  factory RummiJesterCard.fromJson(Map<String, dynamic> json) {
    final conditionType = json['conditionType'] as String? ?? '';
    final mappedColors = _resolveTileColorsFromJson(json, conditionType);
    final mappedNumbers = _resolveTileNumbersFromJson(json, conditionType);

    return RummiJesterCard(
      id: json['id'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
      rarity: _rarityFromString(json['rarity'] as String?),
      baseCost: (json['baseCost'] as num?)?.toInt() ?? 0,
      effectText: json['effectText'] as String? ?? '',
      effectType: json['effectType'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      conditionType: conditionType,
      conditionValue: json['conditionValue'],
      value: (json['value'] as num?)?.toInt(),
      xValue: (json['xValue'] as num?)?.toDouble(),
      mappedTileColors: mappedColors,
      mappedTileNumbers: mappedNumbers,
    );
  }

  final String id;
  final String displayName;
  final RummiJesterRarity rarity;
  final int baseCost;
  final String effectText;
  final String effectType;
  final String trigger;
  final String conditionType;
  final Object? conditionValue;
  final int? value;
  final double? xValue;
  final List<TileColor> mappedTileColors;
  final List<int> mappedTileNumbers;

  /// 현재 전투 점수 정산 단계에서 실제로 처리 가능한 Jester인지 여부.
  ///
  /// 이 플래그가 `true`인 카드만 상점 오퍼로 노출한다.
  bool get isSupportedInCurrentScoringMeta {
    return effectType == 'chips_bonus' ||
        effectType == 'mult_bonus' ||
        effectType == 'xmult_bonus' ||
        id == 'scholar';
  }

  /// 현재 런 구조에서 라운드 종료 경제 보너스로 실제 처리 가능한 Jester인지 여부.
  bool get isSupportedInCurrentEconomyMeta {
    if (effectType != 'economy' || trigger != 'onRoundEnd') {
      return false;
    }
    return id == 'egg' ||
        id == 'golden_jester' ||
        (id == 'delayed_gratification' &&
            conditionType == 'other' &&
            conditionValue == 'unused_discards');
  }

  /// 현재 앱에서 상점/런 메타로 실제 지원 가능한지 여부.
  bool get isSupportedInCurrentRunMeta {
    return isSupportedInCurrentScoringMeta ||
        isSupportedInCurrentEconomyMeta ||
        isSupportedInCurrentStatefulMeta;
  }

  /// 현재 런 구조에서 실제 처리 가능한 상태형 Jester인지 여부.
  bool get isSupportedInCurrentStatefulMeta {
    return id == 'supernova' ||
        id == 'popcorn' ||
        id == 'ice_cream' ||
        id == 'green_jester' ||
        id == 'ride_the_bus';
  }

  RummiLineScore applyToLine({
    required RummiHandRank rank,
    required int baseScore,
    required List<Tile> scoringTiles,
    required RummiJesterScoreContext context,
  }) {
    var chipsBonus = 0;
    var multBonus = 0;
    var xmultBonus = 1.0;

    if (id == 'scholar') {
      final aceCount = scoringTiles.where((tile) => tile.number == 1).length;
      chipsBonus += aceCount * (value ?? 0);
      multBonus += aceCount * 4;
    } else if (effectType == 'stateful_growth') {
      switch (id) {
        case 'supernova':
          multBonus += context.currentHandPlayedCount;
        case 'popcorn':
          multBonus += context.stateValue;
        case 'ice_cream':
          chipsBonus += context.stateValue;
        case 'green_jester':
          multBonus += context.stateValue;
        case 'ride_the_bus':
          multBonus += context.stateValue;
      }
    } else {
      switch (effectType) {
        case 'chips_bonus':
          chipsBonus += _evaluateChipsBonus(
            rank: rank,
            scoringTiles: scoringTiles,
            context: context,
          );
        case 'mult_bonus':
          multBonus += _evaluateMultBonus(
            rank: rank,
            scoringTiles: scoringTiles,
            context: context,
          );
        case 'xmult_bonus':
          xmultBonus *= _evaluateXmultBonus(
            rank: rank,
            scoringTiles: scoringTiles,
            context: context,
          );
      }
    }

    final finalScore = _composeScore(
      baseScore: baseScore,
      chipsBonus: chipsBonus,
      multBonus: multBonus,
      xmultBonus: xmultBonus,
    );
    final scoreDelta = max(0, finalScore - baseScore);
    final effect = scoreDelta > 0
        ? RummiJesterEffectBreakdown(
            jesterId: id,
            displayName: displayName,
            chipsBonus: chipsBonus,
            multBonus: multBonus,
            xmultBonus: xmultBonus,
            scoreDelta: scoreDelta,
          )
        : null;

    return RummiLineScore(
      baseScore: baseScore,
      chipsBonus: chipsBonus,
      multBonus: multBonus,
      xmultBonus: xmultBonus,
      finalScore: finalScore,
      effect: effect,
    );
  }

  /// 타일 컬러 후보를 JSON에서 합성한다. 우선순위:
  /// 1. `mappedTileColors` — 엔진 컬러 문자열 배열
  /// 2. `originalSuitRefs` — 포커 슈트(`diamonds` 등) → [TileColor]로 변환
  /// 3. `tile_color_scored`이고 위가 비었을 때 `conditionValue`(타일 컬러명 또는 슈트명)
  static List<TileColor> _resolveTileColorsFromJson(
    Map<String, dynamic> json,
    String conditionType,
  ) {
    final fromMapped = (json['mappedTileColors'] as List<dynamic>? ?? const [])
        .map((value) => _parseJsonTileColor(value as String?))
        .whereType<TileColor>()
        .toList(growable: false);
    if (fromMapped.isNotEmpty) {
      return fromMapped;
    }

    final fromSuitRefs = <TileColor>[];
    for (final e in json['originalSuitRefs'] as List<dynamic>? ?? const []) {
      if (e is! String) continue;
      final c = _parseJsonTileColor(e) ?? _pokerSuitRefToTileColor(e);
      if (c != null) {
        fromSuitRefs.add(c);
      }
    }
    if (fromSuitRefs.isNotEmpty) {
      return fromSuitRefs;
    }

    if (conditionType != 'tile_color_scored') {
      return const [];
    }
    final cv = json['conditionValue'];
    if (cv is String) {
      final c = _parseJsonTileColor(cv) ?? _pokerSuitRefToTileColor(cv);
      return c != null ? <TileColor>[c] : const [];
    }
    if (cv is List) {
      return cv
          .map((e) {
            if (e is! String) return null;
            return _parseJsonTileColor(e) ?? _pokerSuitRefToTileColor(e);
          })
          .whereType<TileColor>()
          .toList(growable: false);
    }
    return const [];
  }

  /// 원본 데이터 포커 슈트명 → 루미 타일 [TileColor].
  static TileColor? _pokerSuitRefToTileColor(String raw) {
    return switch (raw.toLowerCase()) {
      'diamonds' => TileColor.yellow,
      'hearts' => TileColor.red,
      'spades' => TileColor.blue,
      'clubs' => TileColor.black,
      _ => null,
    };
  }

  /// 스코어에 쓸 랭크(1–13) 목록. 우선순위:
  /// 1. `mappedTileNumbers` — 정수 또는 `"face_card"` 등 토큰 문자열
  /// 2. `originalRankRefs` — `"ace"`, `"10"`, `"jack"` 등
  /// 3. `rank_scored`이고 위가 비었을 때 `conditionValue`의 숫자 배열
  static List<int> _resolveTileNumbersFromJson(
    Map<String, dynamic> json,
    String conditionType,
  ) {
    final ranks = <int>{};

    for (final e in json['mappedTileNumbers'] as List<dynamic>? ?? const []) {
      if (e is num) {
        ranks.add(e.toInt());
      } else if (e is String) {
        ranks.addAll(_expandRankRefToken(e));
      }
    }
    for (final e in json['originalRankRefs'] as List<dynamic>? ?? const []) {
      if (e is String) {
        ranks.addAll(_expandRankRefToken(e));
      }
    }
    if (ranks.isEmpty && conditionType == 'rank_scored') {
      final cv = json['conditionValue'];
      if (cv is List) {
        for (final e in cv) {
          if (e is num) {
            ranks.add(e.toInt());
          }
        }
      }
    }

    final out = ranks.toList()..sort();
    return out;
  }

  /// `originalRankRefs` / `mappedTileNumbers` 안의 랭크 토큰을 1–13 정수로 펼친다.
  static List<int> _expandRankRefToken(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'ace':
        return [1];
      case 'jack':
        return [11];
      case 'queen':
        return [12];
      case 'king':
        return [13];
      case 'face_card':
        return [11, 12, 13];
      default:
        final n = int.tryParse(s);
        if (n != null && n >= 1 && n <= 13) {
          return [n];
        }
        return [];
    }
  }

  static RummiJesterRarity _rarityFromString(String? value) {
    return switch (value) {
      'uncommon' => RummiJesterRarity.uncommon,
      'rare' => RummiJesterRarity.rare,
      'legendary' => RummiJesterRarity.legendary,
      _ => RummiJesterRarity.common,
    };
  }

  static TileColor? _parseJsonTileColor(String? value) {
    return switch (value) {
      'red' => TileColor.red,
      'blue' => TileColor.blue,
      'yellow' => TileColor.yellow,
      'black' => TileColor.black,
      _ => null,
    };
  }

  int _evaluateChipsBonus({
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required RummiJesterScoreContext context,
  }) {
    final bonus = value ?? 0;
    return switch (conditionType) {
      'none' => bonus,
      'tile_color_scored' => _countTileColorMatches(scoringTiles) * bonus,
      'pair' ||
      'two_pair' ||
      'three_of_a_kind' ||
      'four_of_a_kind' ||
      'straight' ||
      'flush' => _matchesRankCondition(rank) ? bonus : 0,
      'face_card' => _countFaceCards(scoringTiles) * bonus,
      'rank_scored' => _countRankMatches(scoringTiles) * bonus,
      'other' => _otherChipsBonus(context, bonus),
      _ => 0,
    };
  }

  int _evaluateMultBonus({
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required RummiJesterScoreContext context,
  }) {
    final bonus = value ?? 0;
    return switch (conditionType) {
      'none' => bonus,
      'tile_color_scored' => _countTileColorMatches(scoringTiles) * bonus,
      'pair' ||
      'two_pair' ||
      'three_of_a_kind' ||
      'four_of_a_kind' ||
      'straight' ||
      'flush' => _matchesRankCondition(rank) ? bonus : 0,
      'face_card' => _countFaceCards(scoringTiles) * bonus,
      'rank_scored' => _countRankMatches(scoringTiles) * bonus,
      'other' => _otherMultBonus(scoringTiles, context, bonus),
      _ => 0,
    };
  }

  double _evaluateXmultBonus({
    required RummiHandRank rank,
    required List<Tile> scoringTiles,
    required RummiJesterScoreContext context,
  }) {
    final bonus = xValue ?? 1.0;
    if (conditionType == 'other' && conditionValue == 'empty_jester_slots') {
      final empty = context.maxJesterSlots - context.ownedJesterCount;
      return pow(bonus, empty.clamp(0, context.maxJesterSlots)).toDouble();
    }
    if (conditionType == 'face_card' && conditionValue == 'first_scored') {
      return scoringTiles.any(_isFaceCard) ? bonus : 1.0;
    }
    if (conditionType == 'pair' ||
        conditionType == 'two_pair' ||
        conditionType == 'three_of_a_kind' ||
        conditionType == 'four_of_a_kind' ||
        conditionType == 'straight' ||
        conditionType == 'flush') {
      return _matchesRankCondition(rank) ? bonus : 1.0;
    }
    return 1.0;
  }

  bool _matchesRankCondition(RummiHandRank rank) {
    return switch (conditionType) {
      'pair' =>
        rank == RummiHandRank.onePair ||
            rank == RummiHandRank.twoPair ||
            rank == RummiHandRank.threeOfAKind ||
            rank == RummiHandRank.fullHouse ||
            rank == RummiHandRank.fourOfAKind,
      'two_pair' =>
        rank == RummiHandRank.twoPair || rank == RummiHandRank.fullHouse,
      'three_of_a_kind' =>
        rank == RummiHandRank.threeOfAKind ||
            rank == RummiHandRank.fullHouse ||
            rank == RummiHandRank.fourOfAKind,
      'four_of_a_kind' => rank == RummiHandRank.fourOfAKind,
      'straight' =>
        rank == RummiHandRank.straight || rank == RummiHandRank.straightFlush,
      'flush' =>
        rank == RummiHandRank.flush || rank == RummiHandRank.straightFlush,
      _ => false,
    };
  }

  int _countTileColorMatches(List<Tile> scoringTiles) {
    if (mappedTileColors.isEmpty) return 0;
    return scoringTiles
        .where((tile) => mappedTileColors.contains(tile.color))
        .length;
  }

  /// JSON에서 채운 [mappedTileNumbers]가 있으면 그 랭크만, 없으면 11–13(페이스) 기본.
  int _countFaceCards(List<Tile> scoringTiles) {
    if (mappedTileNumbers.isNotEmpty) {
      return scoringTiles
          .where((tile) => mappedTileNumbers.contains(tile.number))
          .length;
    }
    return scoringTiles.where(_isFaceCard).length;
  }

  int _countRankMatches(List<Tile> scoringTiles) {
    return scoringTiles.where(_matchesRank).length;
  }

  bool _matchesRank(Tile tile) {
    if (mappedTileNumbers.isNotEmpty) {
      return mappedTileNumbers.contains(tile.number);
    }
    final cv = conditionValue;
    if (cv == 'ace') return tile.number == 1;
    if (cv is num) return tile.number == cv.toInt();
    if (cv is String) {
      return switch (cv) {
        'jack' => tile.number == 11,
        'queen' => tile.number == 12,
        'king' => tile.number == 13,
        _ => false,
      };
    }
    if (cv is List) {
      return cv
          .whereType<num>()
          .map((value) => value.toInt())
          .contains(tile.number);
    }
    return false;
  }

  int _otherChipsBonus(RummiJesterScoreContext context, int bonus) {
    return switch (conditionValue) {
      'cards_remaining_in_deck' => context.cardsRemainingInDeck * bonus,
      'remaining_discards' => context.discardsRemaining * bonus,
      _ => 0,
    };
  }

  int _otherMultBonus(
    List<Tile> scoringTiles,
    RummiJesterScoreContext context,
    int bonus,
  ) {
    return switch (conditionValue) {
      'played_hand_size_lte_3' => scoringTiles.length <= 3 ? bonus : 0,
      'owned_jester_count' => context.ownedJesterCount * bonus,
      'zero_discards_remaining' => context.discardsRemaining == 0 ? bonus : 0,
      _ => 0,
    };
  }

  static bool _isFaceCard(Tile tile) => tile.number >= 11 && tile.number <= 13;

  static int _composeScore({
    required int baseScore,
    required int chipsBonus,
    required int multBonus,
    required double xmultBonus,
  }) {
    final chips = baseScore + chipsBonus;
    if (chips <= 0) return 0;
    final multFactor = 1 + (multBonus / 20.0);
    return max(0, (chips * multFactor * xmultBonus).round());
  }
}

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
    return '${placement.name}:$itemId';
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
    return key.substring(separator + 1);
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

class RummiRunProgress {
  RummiRunProgress();

  RummiRunProgress.restore({
    required this.stageIndex,
    this.currentStationBlindTierIndex = 0,
    this.runCompletionRewardClaimed = false,
    required this.gold,
    required this.rerollCost,
    int? tileRerollCost,
    int? itemRerollCost,
    int? quickSlotRerollCost,
    int? passiveRerollCost,
    int? toolRerollCost,
    int? gearRerollCost,
    required List<RummiJesterCard> ownedJesters,
    required List<RummiShopOffer> shopOffers,
    required Map<int, int> statefulValuesBySlot,
    required Map<RummiHandRank, int> playedHandCounts,
    Map<RummiHandRank, RummiHandGrowthState> handGrowthStates = const {},
    Map<RummiHandRank, int> stationRankFinalScores = const {},
    Set<String> overkillGrowthClaimedStationKeys = const <String>{},
    List<Tile> addedDeckTiles = const [],
    List<Tile> tileOffers = const [],
    this.pendingBossTileReward = false,
    this.firstShopRerollDiscountConsumed = false,
    Set<String> firstShopRerollDiscountConsumedLanes = const <String>{},
    int? unlockedJesterSlots,
    int? unlockedQuickSlotCapacity,
    int? unlockedPassiveRelicCapacity,
    Set<RummiSlotUnlockKind> pendingSlotUnlockPresentations =
        const <RummiSlotUnlockKind>{},
    this.itemInventory = const RunInventoryState(),
    this.marketModifiers = const RummiMarketModifierState(),
    this.seenMarketJesterIds = const <String>{},
    this.seenMarketItemIds = const <String>{},
    this.boughtJesterIds = const <String>{},
    this.boughtItemIds = const <String>{},
    this.seenBossModifierIds = const <String>{},
    this.clearedStationKeys = const <String>{},
  }) {
    this.unlockedJesterSlots = (unlockedJesterSlots ?? baseUnlockedJesterSlots)
        .clamp(baseUnlockedJesterSlots, maxJesterSlots)
        .toInt();
    this.unlockedQuickSlotCapacity =
        (unlockedQuickSlotCapacity ??
                RunInventoryState.defaultQuickSlotCapacity)
            .clamp(
              RunInventoryState.defaultQuickSlotCapacity,
              RunInventoryState.maxQuickSlotCapacity,
            )
            .toInt();
    this.unlockedPassiveRelicCapacity =
        (unlockedPassiveRelicCapacity ??
                RunInventoryState.defaultPassiveRelicCapacity)
            .clamp(
              RunInventoryState.defaultPassiveRelicCapacity,
              RunInventoryState.maxPassiveRelicCapacity,
            )
            .toInt();
    this.itemRerollCost = itemRerollCost ?? rerollCost;
    this.tileRerollCost = tileRerollCost ?? rerollCost;
    this.quickSlotRerollCost =
        quickSlotRerollCost ?? itemRerollCost ?? rerollCost;
    this.passiveRerollCost = passiveRerollCost ?? itemRerollCost ?? rerollCost;
    this.toolRerollCost = toolRerollCost ?? itemRerollCost ?? rerollCost;
    this.gearRerollCost = gearRerollCost ?? itemRerollCost ?? rerollCost;
    this.ownedJesters.addAll(ownedJesters);
    this.shopOffers.addAll(shopOffers);
    _statefulValuesBySlot.addAll(statefulValuesBySlot);
    _playedHandCounts.addAll(playedHandCounts);
    if (handGrowthStates.isEmpty) {
      for (final entry in playedHandCounts.entries) {
        if (isDeadLineRank(entry.key)) continue;
        _handGrowthStates[entry.key] = RummiHandGrowthState.fromCompletedCount(
          entry.key,
          entry.value,
        );
      }
    } else {
      _handGrowthStates.addAll(handGrowthStates);
    }
    _stationRankFinalScores.addAll(stationRankFinalScores);
    _overkillGrowthClaimedStationKeys.addAll(overkillGrowthClaimedStationKeys);
    this.addedDeckTiles.addAll(addedDeckTiles);
    this.tileOffers.addAll(tileOffers);
    if (firstShopRerollDiscountConsumedLanes.isEmpty &&
        firstShopRerollDiscountConsumed) {
      _firstShopRerollDiscountConsumedLanes.addAll(_marketRerollLaneKeys);
    } else {
      _firstShopRerollDiscountConsumedLanes.addAll(
        firstShopRerollDiscountConsumedLanes.where(
          _marketRerollLaneKeys.contains,
        ),
      );
    }
    _pendingSlotUnlockPresentations.addAll(pendingSlotUnlockPresentations);
  }

  static const int maxJesterSlots = 5;
  static const int baseUnlockedJesterSlots = 4;
  static const int stageClearGoldBase = RummiEconomyConfig.stageClearGoldBase;
  static const int remainingBoardDiscardGoldBonus =
      RummiEconomyConfig.remainingBoardDiscardGoldBonus;
  static const int remainingHandDiscardGoldBonus =
      RummiEconomyConfig.remainingHandDiscardGoldBonus;
  static const int remainingBoardMoveGoldBonus =
      RummiEconomyConfig.remainingBoardMoveGoldBonus;
  static const int shopBaseRerollCost = RummiEconomyConfig.shopBaseRerollCost;
  static const int shopRerollCostStep = RummiEconomyConfig.shopRerollCostStep;
  static const String _jesterRerollLaneKey = 'jester';
  static const String _tileRerollLaneKey = 'tile';
  static const String _quickSlotRerollLaneKey = 'quickSlot';
  static const String _passiveRerollLaneKey = 'passive';
  static const String _toolRerollLaneKey = 'tool';
  static const String _gearRerollLaneKey = 'gear';
  static const Set<String> _marketRerollLaneKeys = <String>{
    _jesterRerollLaneKey,
    _tileRerollLaneKey,
    _quickSlotRerollLaneKey,
    _passiveRerollLaneKey,
    _toolRerollLaneKey,
    _gearRerollLaneKey,
  };

  int stageIndex = 1;
  int currentStationBlindTierIndex = 0;
  bool runCompletionRewardClaimed = false;
  int gold = RummiEconomyConfig.startingGold;
  int rerollCost = shopBaseRerollCost;
  int tileRerollCost = shopBaseRerollCost;
  int itemRerollCost = shopBaseRerollCost;
  int quickSlotRerollCost = shopBaseRerollCost;
  int passiveRerollCost = shopBaseRerollCost;
  int toolRerollCost = shopBaseRerollCost;
  int gearRerollCost = shopBaseRerollCost;
  RunInventoryState itemInventory = const RunInventoryState();
  RummiMarketModifierState marketModifiers = const RummiMarketModifierState();
  Set<String> seenMarketJesterIds = <String>{};
  Set<String> seenMarketItemIds = <String>{};
  Set<String> boughtJesterIds = <String>{};
  Set<String> boughtItemIds = <String>{};
  Set<String> seenBossModifierIds = <String>{};
  Set<String> clearedStationKeys = <String>{};
  int unlockedJesterSlots = baseUnlockedJesterSlots;
  int unlockedQuickSlotCapacity = RunInventoryState.defaultQuickSlotCapacity;
  int unlockedPassiveRelicCapacity =
      RunInventoryState.defaultPassiveRelicCapacity;
  final List<RummiJesterCard> ownedJesters = <RummiJesterCard>[];
  final List<RummiShopOffer> shopOffers = <RummiShopOffer>[];
  final List<Tile> addedDeckTiles = <Tile>[];
  final List<Tile> tileOffers = <Tile>[];
  bool pendingBossTileReward = false;
  bool firstShopRerollDiscountConsumed = false;
  final Set<String> _firstShopRerollDiscountConsumedLanes = <String>{};
  final Map<int, int> _statefulValuesBySlot = <int, int>{};
  final Map<RummiHandRank, int> _playedHandCounts = <RummiHandRank, int>{};
  final Map<RummiHandRank, RummiHandGrowthState> _handGrowthStates =
      <RummiHandRank, RummiHandGrowthState>{};
  final Map<RummiHandRank, int> _stationRankFinalScores =
      <RummiHandRank, int>{};
  final Set<String> _overkillGrowthClaimedStationKeys = <String>{};
  final Set<RummiSlotUnlockKind> _pendingSlotUnlockPresentations =
      <RummiSlotUnlockKind>{};

  Map<int, int> snapshotStatefulValuesBySlot() =>
      Map<int, int>.unmodifiable(_statefulValuesBySlot);

  Map<RummiHandRank, int> snapshotPlayedHandCounts() =>
      Map<RummiHandRank, int>.unmodifiable(_playedHandCounts);

  Map<RummiHandRank, RummiHandGrowthState> snapshotHandGrowthStates() =>
      Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(_handGrowthStates);

  Map<RummiHandRank, int> snapshotStationRankFinalScores() =>
      Map<RummiHandRank, int>.unmodifiable(_stationRankFinalScores);

  Set<String> snapshotOverkillGrowthClaimedStationKeys() =>
      Set<String>.unmodifiable(_overkillGrowthClaimedStationKeys);

  Set<String> snapshotFirstShopRerollDiscountConsumedLanes() =>
      Set<String>.unmodifiable(_firstShopRerollDiscountConsumedLanes);

  Set<RummiSlotUnlockKind> snapshotPendingSlotUnlockPresentations() =>
      Set<RummiSlotUnlockKind>.unmodifiable(_pendingSlotUnlockPresentations);

  void applyChallengeCarryover({
    Map<RummiHandRank, int> playedHandCounts = const <RummiHandRank, int>{},
    Map<RummiHandRank, RummiHandGrowthState> handGrowthStates =
        const <RummiHandRank, RummiHandGrowthState>{},
    List<Tile> addedDeckTiles = const <Tile>[],
  }) {
    _playedHandCounts
      ..clear()
      ..addAll(playedHandCounts);
    _handGrowthStates
      ..clear()
      ..addAll(handGrowthStates);
    this.addedDeckTiles
      ..clear()
      ..addAll(addedDeckTiles);
  }

  bool addHandRankProgress(RummiHandRank rank, {int amount = 1}) {
    if (amount <= 0 || isDeadLineRank(rank)) {
      return false;
    }
    final current =
        _handGrowthStates[rank] ?? RummiHandGrowthState.initial(rank);
    _handGrowthStates[rank] = current.addProgress(rank, amount);
    return true;
  }

  bool recordHandRankCompletion(RummiHandRank rank) {
    _playedHandCounts.update(rank, (value) => value + 1, ifAbsent: () => 1);
    return addHandRankProgress(rank);
  }

  RummiRunProgress copySnapshot() {
    return RummiRunProgress.restore(
      stageIndex: stageIndex,
      currentStationBlindTierIndex: currentStationBlindTierIndex,
      runCompletionRewardClaimed: runCompletionRewardClaimed,
      gold: gold,
      rerollCost: rerollCost,
      itemRerollCost: itemRerollCost,
      quickSlotRerollCost: quickSlotRerollCost,
      passiveRerollCost: passiveRerollCost,
      toolRerollCost: toolRerollCost,
      gearRerollCost: gearRerollCost,
      ownedJesters: List<RummiJesterCard>.from(ownedJesters),
      shopOffers: shopOffers
          .map(
            (offer) => RummiShopOffer(
              slotIndex: offer.slotIndex,
              card: offer.card,
              price: offer.price,
            ),
          )
          .toList(growable: false),
      statefulValuesBySlot: Map<int, int>.from(_statefulValuesBySlot),
      playedHandCounts: Map<RummiHandRank, int>.from(_playedHandCounts),
      handGrowthStates: Map<RummiHandRank, RummiHandGrowthState>.from(
        _handGrowthStates,
      ),
      stationRankFinalScores: Map<RummiHandRank, int>.from(
        _stationRankFinalScores,
      ),
      overkillGrowthClaimedStationKeys: Set<String>.from(
        _overkillGrowthClaimedStationKeys,
      ),
      addedDeckTiles: List<Tile>.from(addedDeckTiles),
      tileOffers: List<Tile>.from(tileOffers),
      pendingBossTileReward: pendingBossTileReward,
      firstShopRerollDiscountConsumed: firstShopRerollDiscountConsumed,
      firstShopRerollDiscountConsumedLanes: Set<String>.from(
        _firstShopRerollDiscountConsumedLanes,
      ),
      unlockedJesterSlots: unlockedJesterSlots,
      unlockedQuickSlotCapacity: unlockedQuickSlotCapacity,
      unlockedPassiveRelicCapacity: unlockedPassiveRelicCapacity,
      pendingSlotUnlockPresentations: Set<RummiSlotUnlockKind>.from(
        _pendingSlotUnlockPresentations,
      ),
      itemInventory: itemInventory,
      marketModifiers: marketModifiers,
      seenMarketJesterIds: Set<String>.from(seenMarketJesterIds),
      seenMarketItemIds: Set<String>.from(seenMarketItemIds),
      boughtJesterIds: Set<String>.from(boughtJesterIds),
      boughtItemIds: Set<String>.from(boughtItemIds),
      seenBossModifierIds: Set<String>.from(seenBossModifierIds),
      clearedStationKeys: Set<String>.from(clearedStationKeys),
    );
  }

  /// 도감에 남길 마켓 노출 이력을 런 진행 상태에 쌓는다.
  void recordSeenMarketItems(Iterable<String> itemIds) {
    seenMarketItemIds.addAll(itemIds.where((id) => id.isNotEmpty));
  }

  void recordSeenBossModifier(String? modifierId) {
    if (modifierId == null || modifierId.isEmpty) return;
    seenBossModifierIds.add(modifierId);
  }

  void recordClearedStation(int stationIndex) {
    if (stationIndex <= 0) return;
    clearedStationKeys.add('station_$stationIndex');
  }

  bool unlockSlotCapacity(
    RummiSlotUnlockKind kind, {
    ItemCatalog? itemCatalog,
  }) {
    final visibleCapacityBefore = _slotCapacityFor(
      kind,
      itemCatalog: itemCatalog,
    );
    final unlocked = switch (kind) {
      RummiSlotUnlockKind.jester => _increaseJesterSlots(),
      RummiSlotUnlockKind.quickSlot => _increaseQuickSlotCapacity(),
      RummiSlotUnlockKind.passiveRelic => _increasePassiveRelicCapacity(),
    };
    if (unlocked) {
      final visibleCapacityAfter = _slotCapacityFor(
        kind,
        itemCatalog: itemCatalog,
      );
      if (visibleCapacityAfter > visibleCapacityBefore) {
        _pendingSlotUnlockPresentations.add(kind);
      }
    }
    return unlocked;
  }

  List<RummiSlotUnlockKind> claimBossSlotUnlockRewards({
    ItemCatalog? itemCatalog,
  }) {
    final rewardKind = switch (stageIndex) {
      2 => RummiSlotUnlockKind.quickSlot,
      4 => RummiSlotUnlockKind.passiveRelic,
      6 => RummiSlotUnlockKind.jester,
      _ => null,
    };
    if (rewardKind == null) return const <RummiSlotUnlockKind>[];
    return unlockSlotCapacity(rewardKind, itemCatalog: itemCatalog) &&
            _pendingSlotUnlockPresentations.contains(rewardKind)
        ? <RummiSlotUnlockKind>[rewardKind]
        : const <RummiSlotUnlockKind>[];
  }

  int _slotCapacityFor(RummiSlotUnlockKind kind, {ItemCatalog? itemCatalog}) {
    return switch (kind) {
      RummiSlotUnlockKind.jester => jesterSlotCapacity(
        itemCatalog: itemCatalog,
      ),
      RummiSlotUnlockKind.quickSlot => quickSlotCapacity(
        itemCatalog: itemCatalog,
      ),
      RummiSlotUnlockKind.passiveRelic => passiveRelicCapacity(
        itemCatalog: itemCatalog,
      ),
    };
  }

  void clearPendingSlotUnlockPresentations() {
    _pendingSlotUnlockPresentations.clear();
  }

  bool _increaseJesterSlots() {
    if (unlockedJesterSlots >= maxJesterSlots) return false;
    unlockedJesterSlots += 1;
    return true;
  }

  bool _increaseQuickSlotCapacity() {
    if (unlockedQuickSlotCapacity >= RunInventoryState.maxQuickSlotCapacity) {
      return false;
    }
    unlockedQuickSlotCapacity += 1;
    return true;
  }

  bool _increasePassiveRelicCapacity() {
    if (unlockedPassiveRelicCapacity >=
        RunInventoryState.maxPassiveRelicCapacity) {
      return false;
    }
    unlockedPassiveRelicCapacity += 1;
    return true;
  }

  List<Tile> buildDeckSourceForNextBlind(int deckCopiesPerTile) {
    return List<Tile>.unmodifiable([
      ...buildStandardPokerDeck(copiesPerTile: deckCopiesPerTile),
      ...addedDeckTiles,
    ]);
  }

  void queueBossTileReward() {
    pendingBossTileReward = true;
  }

  Tile addDeckTile(Tile tile) {
    final copyId = _nextCopyIdForTile(tile);
    final addedTile = Tile(color: tile.color, number: tile.number, id: copyId);
    addedDeckTiles.add(addedTile);
    return addedTile;
  }

  Tile addBossClearDeckTileReward(Random rng) {
    final rewardPool = buildStandardPokerDeck(copiesPerTile: 1);
    return addDeckTile(rewardPool[rng.nextInt(rewardPool.length)]);
  }

  bool buyTileOffer(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= tileOffers.length) return false;
    final price = effectiveTileOfferPrice(offerIndex);
    if (gold < price) return false;
    final tile = tileOffers.removeAt(offerIndex);
    gold -= price;
    addDeckTile(tile);
    _consumePurchaseDiscounts('tile');
    return true;
  }

  bool claimFreeTileOffer(int offerIndex) {
    if (!pendingBossTileReward) return false;
    if (offerIndex < 0 || offerIndex >= tileOffers.length) return false;
    final tile = tileOffers.removeAt(offerIndex);
    addDeckTile(tile);
    pendingBossTileReward = false;
    return true;
  }

  int effectiveTileOfferPrice(int offerIndex) {
    final stageStep = max(0, stageIndex - 1) ~/ 2;
    return 3 + stageStep;
  }

  int _nextCopyIdForTile(Tile tile) {
    var maxId = 0;
    for (final existing in addedDeckTiles) {
      if (existing.color == tile.color && existing.number == tile.number) {
        maxId = max(maxId, existing.id);
      }
    }
    return maxId + 1;
  }

  int targetForStage(int stageNumber) {
    const scoutTargets = <int>[480, 650, 900, 1250, 1750, 2450, 3450, 4850];
    if (stageNumber <= 1) return scoutTargets.first;
    if (stageNumber <= scoutTargets.length) {
      return scoutTargets[stageNumber - 1];
    }
    final extraStep = stageNumber - scoutTargets.length;
    return (scoutTargets.last * pow(1.25, extraStep)).round();
  }

  void startBlind(
    RummiPokerGridSession session, {
    required int stationIndex,
    required int blindTierIndex,
    required int shuffleSeed,
    required int targetScore,
    required int boardDiscards,
    required int handDiscards,
    required int maxHandSize,
    List<Tile>? deckSource,
    bool applyRoundEndDecay = true,
  }) {
    stageIndex = stationIndex;
    currentStationBlindTierIndex = blindTierIndex;
    _stationRankFinalScores.clear();
    if (applyRoundEndDecay) {
      _applyRoundEndStateDecay();
    }
    session.prepareNextBlind(
      targetScore: targetScore,
      boardDiscardsRemaining: boardDiscards,
      handDiscardsRemaining: handDiscards,
      shuffleSeed: shuffleSeed,
      deckSource: deckSource,
    );
    session.maxHandSize = maxHandSize;
  }

  RummiCashOutBreakdown buildCashOutBreakdown(
    RummiPokerGridSession session, {
    ItemCatalog? itemCatalog,
    double rewardMultiplier = 1,
  }) {
    final blindReward = (stageClearGoldBase * rewardMultiplier).round();
    final firstBlindClearBonusGold = _firstBlindClearBonusGold();
    final remainingBoardDiscards = session.blind.boardDiscardsRemaining;
    final remainingHandDiscards = session.blind.handDiscardsRemaining;
    final remainingBoardMoves = session.blind.boardMovesRemaining;
    final boardDiscardGold =
        remainingBoardDiscards * remainingBoardDiscardGoldBonus;
    final handDiscardGold =
        remainingHandDiscards * remainingHandDiscardGoldBonus;
    final boardMoveGold = remainingBoardMoves * remainingBoardMoveGoldBonus;
    final economyBonuses = ownedJesters
        .map(
          (card) => _buildRoundEndEconomyBonus(
            card: card,
            remainingBoardDiscards: remainingBoardDiscards,
            remainingHandDiscards: remainingHandDiscards,
          ),
        )
        .whereType<RummiRoundEndEconomyBonus>()
        .toList(growable: false);
    final economyGold = economyBonuses.fold<int>(
      0,
      (sum, bonus) => sum + bonus.gold,
    );
    final itemBonuses = itemCatalog == null
        ? const <RummiRoundEndItemBonus>[]
        : _buildRoundEndItemBonuses(
            catalog: itemCatalog,
            remainingBoardDiscards: remainingBoardDiscards,
            remainingHandDiscards: remainingHandDiscards,
          );
    final itemGold = itemBonuses.fold<int>(0, (sum, bonus) => sum + bonus.gold);
    final overkillGrowthBonuses = claimOverkillGrowthBonus(
      targetScore: session.blind.targetScore,
      finalScore: session.blind.scoreTowardBlind,
    );
    final overkillGoldBonus = overkillGrowthBonuses.isEmpty
        ? 0
        : calculateOverkillGoldBonus(
            targetScore: session.blind.targetScore,
            finalScore: session.blind.scoreTowardBlind,
          );
    return RummiCashOutBreakdown(
      stageIndex: stageIndex,
      targetScore: session.blind.targetScore,
      blindReward: blindReward,
      remainingBoardDiscards: remainingBoardDiscards,
      remainingHandDiscards: remainingHandDiscards,
      remainingBoardMoves: remainingBoardMoves,
      perBoardDiscardBonus: remainingBoardDiscardGoldBonus,
      perHandDiscardBonus: remainingHandDiscardGoldBonus,
      perBoardMoveBonus: remainingBoardMoveGoldBonus,
      boardDiscardGold: boardDiscardGold,
      handDiscardGold: handDiscardGold,
      boardMoveGold: boardMoveGold,
      economyBonuses: economyBonuses,
      economyGold: economyGold,
      firstBlindClearBonusGold: firstBlindClearBonusGold,
      itemBonuses: itemBonuses,
      itemGold: itemGold,
      overkillGrowthBonuses: overkillGrowthBonuses,
      overkillGoldBonus: overkillGoldBonus,
      totalGold:
          blindReward +
          firstBlindClearBonusGold +
          boardDiscardGold +
          handDiscardGold +
          boardMoveGold +
          economyGold +
          itemGold +
          overkillGoldBonus,
    );
  }

  int _firstBlindClearBonusGold() {
    if (stageIndex == 1 && currentStationBlindTierIndex == 0) {
      return RummiEconomyConfig.firstBlindClearBonusGold;
    }
    return 0;
  }

  List<RummiRoundEndItemBonus> _buildRoundEndItemBonuses({
    required ItemCatalog catalog,
    required int remainingBoardDiscards,
    required int remainingHandDiscards,
  }) {
    final activeIds = <String>{
      for (final entry in itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final bonuses = <RummiRoundEndItemBonus>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null || item.effect.timing != 'settlement') {
        continue;
      }
      final amount = (item.effect.amount ?? 0).toInt();
      if (amount <= 0) continue;
      final gold = switch (item.effect.op) {
        'board_discard_reward_bonus' => remainingBoardDiscards * amount,
        'hand_discard_reward_bonus' => remainingHandDiscards * amount,
        _ => 0,
      };
      if (gold <= 0) continue;
      bonuses.add(
        RummiRoundEndItemBonus(
          itemId: item.id,
          displayName: item.displayName,
          gold: gold,
        ),
      );
    }
    return List<RummiRoundEndItemBonus>.unmodifiable(bonuses);
  }

  void applyCashOut(RummiCashOutBreakdown breakdown) {
    gold += breakdown.totalGold;
  }

  RummiJesterRuntimeSnapshot buildRuntimeSnapshot() {
    return RummiJesterRuntimeSnapshot(
      slotStateValues: Map<int, int>.unmodifiable(_statefulValuesBySlot),
      playedHandCounts: Map<RummiHandRank, int>.unmodifiable(_playedHandCounts),
      handGrowthStates: Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(
        _handGrowthStates,
      ),
    );
  }

  /// 현재 상점은 "전투 점수 정산 또는 라운드 종료 정산에 즉시 반영 가능한
  /// Jester만 노출" 정책을 쓴다.
  void openShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    rerollCost = shopBaseRerollCost;
    tileRerollCost = shopBaseRerollCost;
    itemRerollCost = shopBaseRerollCost;
    quickSlotRerollCost = shopBaseRerollCost;
    passiveRerollCost = shopBaseRerollCost;
    toolRerollCost = shopBaseRerollCost;
    gearRerollCost = shopBaseRerollCost;
    final nextMarketExtraJesterOfferSlots =
        marketModifiers.nextMarketExtraJesterOfferSlots;
    marketModifiers = marketModifiers.copyWith(
      nextRerollDiscount: 0,
      firstRerollDiscount: RummiEconomyConfig.shopFirstRerollDiscount,
      nextPurchaseDiscount: 0,
      nextJesterPurchaseDiscount: 0,
      nextItemPurchaseDiscount: 0,
      cheapestFirstOfferDiscount: 0,
      extraJesterOfferSlots: nextMarketExtraJesterOfferSlots,
      nextMarketExtraJesterOfferSlots: 0,
      itemOfferRerollOffset: 0,
      quickSlotOfferRerollOffset: 0,
      passiveOfferRerollOffset: 0,
      toolOfferRerollOffset: 0,
      gearOfferRerollOffset: 0,
      consumedItemOfferIds: const [],
      pinnedItemOfferKeys: const [],
    );
    _generateOffers(
      catalog: catalog,
      rng: rng,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: offerCountOverride,
      pressureProfile: pressureProfile,
    );
    _generateTileOffers(rng);
  }

  bool canAfford(int cost) => gold >= cost;

  int effectiveRerollCost() {
    return _effectiveRerollCostForRawCost(rerollCost, _jesterRerollLaneKey);
  }

  int effectiveTileRerollCost() {
    return _effectiveRerollCostForRawCost(tileRerollCost, _tileRerollLaneKey);
  }

  int effectiveItemRerollCost() {
    return effectiveItemRerollCostFor(ItemPlacement.inventory);
  }

  int itemRerollCostFor(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => quickSlotRerollCost,
      ItemPlacement.passiveRack => passiveRerollCost,
      ItemPlacement.inventory => toolRerollCost,
      ItemPlacement.equipped => gearRerollCost,
    };
  }

  int effectiveItemRerollCostFor(ItemPlacement placement) {
    return _effectiveRerollCostForRawCost(
      itemRerollCostFor(placement),
      _rerollLaneKeyForPlacement(placement),
    );
  }

  int _effectiveRerollCostForRawCost(int rawCost, String laneKey) {
    final firstRerollDiscount =
        rawCost == shopBaseRerollCost &&
            !_firstShopRerollDiscountConsumedLanes.contains(laneKey)
        ? marketModifiers.firstRerollDiscount
        : 0;
    return max(
      0,
      rawCost - marketModifiers.nextRerollDiscount - firstRerollDiscount,
    );
  }

  String _rerollLaneKeyForPlacement(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => _quickSlotRerollLaneKey,
      ItemPlacement.passiveRack => _passiveRerollLaneKey,
      ItemPlacement.inventory => _toolRerollLaneKey,
      ItemPlacement.equipped => _gearRerollLaneKey,
    };
  }

  int effectiveJesterOfferPrice(
    int offerIndex, {
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) return 0;
    final offer = shopOffers[offerIndex];
    return effectivePurchasePrice(
      basePrice: offer.price,
      category: 'jester',
      jester: offer.card,
      includeCheapestFirstOfferDiscount: includeCheapestFirstOfferDiscount,
    );
  }

  int effectiveJesterOfferBasePrice(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) return 0;
    final offer = shopOffers[offerIndex];
    return effectivePurchaseBasePrice(
      basePrice: offer.price,
      jester: offer.card,
    );
  }

  int effectiveItemPrice(
    ItemDefinition item, {
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    return effectivePurchasePrice(
      basePrice: item.basePrice,
      category: 'item',
      item: item,
      includeCheapestFirstOfferDiscount: includeCheapestFirstOfferDiscount,
    );
  }

  int effectiveItemBasePrice(ItemDefinition item) {
    return effectivePurchaseBasePrice(basePrice: item.basePrice, item: item);
  }

  int effectivePurchaseBasePrice({
    required int basePrice,
    RummiJesterCard? jester,
    ItemDefinition? item,
  }) {
    return _growthAccessMarketPrice(
      scaledBasePrice: RummiEconomyConfig.scaledMarketPrice(basePrice),
      jester: jester,
      item: item,
    );
  }

  int effectivePurchasePrice({
    required int basePrice,
    required String category,
    RummiJesterCard? jester,
    ItemDefinition? item,
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    final scaledBasePrice = effectivePurchaseBasePrice(
      basePrice: basePrice,
      jester: jester,
      item: item,
    );
    final categoryDiscount = switch (category) {
      'jester' => marketModifiers.nextJesterPurchaseDiscount,
      'item' => marketModifiers.nextItemPurchaseDiscount,
      _ => 0,
    };
    final cheapestDiscount =
        includeCheapestFirstOfferDiscount &&
            _cheapestFirstOfferDiscountApplies(scaledBasePrice, category)
        ? marketModifiers.cheapestFirstOfferDiscount
        : 0;
    return max(
      0,
      scaledBasePrice -
          marketModifiers.nextPurchaseDiscount -
          categoryDiscount -
          cheapestDiscount,
    );
  }

  int _growthAccessMarketPrice({
    required int scaledBasePrice,
    RummiJesterCard? jester,
    ItemDefinition? item,
  }) {
    if (jester != null && _isGrowthAccessJester(jester)) {
      final cap = switch (jester.rarity) {
        RummiJesterRarity.common => 5,
        RummiJesterRarity.uncommon => 7,
        RummiJesterRarity.rare => 8,
        RummiJesterRarity.legendary => 14,
      };
      return min(scaledBasePrice, cap);
    }
    if (item != null && _isGrowthAccessItem(item)) {
      final cap = switch (item.rarity) {
        ItemRarity.common => 5,
        ItemRarity.uncommon => 7,
        ItemRarity.rare => 8,
        ItemRarity.legendary => 14,
      };
      return min(scaledBasePrice, cap);
    }
    return scaledBasePrice;
  }

  bool _isGrowthAccessJester(RummiJesterCard card) {
    return card.effectType == 'chips_bonus' ||
        card.effectType == 'mult_bonus' ||
        card.effectType == 'xmult_bonus' ||
        card.effectType == 'stateful_growth';
  }

  bool _isGrowthAccessItem(ItemDefinition item) {
    const growthTags = {
      'score',
      'rank',
      'tile_color',
      'xmult',
      'discard',
      'move',
      'safety',
      'draw',
    };
    for (final tag in item.tags) {
      if (growthTags.contains(tag)) return true;
    }
    return false;
  }

  void queueMarketModifier({
    required String op,
    required int amount,
    String? category,
  }) {
    if (amount <= 0) return;
    switch (op) {
      case 'discount_next_reroll':
        marketModifiers = marketModifiers.copyWith(
          nextRerollDiscount: marketModifiers.nextRerollDiscount + amount,
        );
      case 'discount_first_reroll':
        marketModifiers = marketModifiers.copyWith(
          firstRerollDiscount: marketModifiers.firstRerollDiscount + amount,
        );
      case 'discount_next_purchase':
        if (category == 'jester') {
          marketModifiers = marketModifiers.copyWith(
            nextJesterPurchaseDiscount:
                marketModifiers.nextJesterPurchaseDiscount + amount,
          );
        } else if (category == 'item') {
          marketModifiers = marketModifiers.copyWith(
            nextItemPurchaseDiscount:
                marketModifiers.nextItemPurchaseDiscount + amount,
          );
        } else {
          marketModifiers = marketModifiers.copyWith(
            nextPurchaseDiscount: marketModifiers.nextPurchaseDiscount + amount,
          );
        }
      case 'discount_cheapest_first_offer':
        marketModifiers = marketModifiers.copyWith(
          cheapestFirstOfferDiscount:
              marketModifiers.cheapestFirstOfferDiscount + amount,
        );
      case 'extra_item_offer_slot':
        marketModifiers = marketModifiers.copyWith(
          extraItemOfferSlots: marketModifiers.extraItemOfferSlots + amount,
        );
      case 'reroll_item_offers_only':
        final nextQuickSlotOffset =
            marketModifiers.quickSlotOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextPassiveOffset =
            marketModifiers.passiveOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextToolOffset =
            marketModifiers.toolOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextGearOffset =
            marketModifiers.gearOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        marketModifiers = marketModifiers.copyWith(
          itemOfferRerollOffset:
              marketModifiers.itemOfferRerollOffset +
              marketModifiers.itemOfferSlotCount,
          quickSlotOfferRerollOffset: nextQuickSlotOffset,
          passiveOfferRerollOffset: nextPassiveOffset,
          toolOfferRerollOffset: nextToolOffset,
          gearOfferRerollOffset: nextGearOffset,
          consumedItemOfferIds: const [],
          pinnedItemOfferKeys: const [],
        );
      case 'extra_jester_offer_next_market':
        marketModifiers = marketModifiers.copyWith(
          nextMarketExtraJesterOfferSlots:
              marketModifiers.nextMarketExtraJesterOfferSlots + amount,
        );
    }
  }

  bool rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final cost = effectiveRerollCost();
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    rerollCost += shopRerollCostStep;
    _markFirstShopRerollDiscountConsumed(_jesterRerollLaneKey);
    marketModifiers = marketModifiers.copyWith(nextRerollDiscount: 0);
    _generateOffers(
      catalog: catalog,
      rng: rng,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: offerCountOverride,
      pressureProfile: pressureProfile,
    );
    return true;
  }

  bool rerollTileOffers({required Random rng}) {
    final cost = effectiveTileRerollCost();
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    tileRerollCost += shopRerollCostStep;
    _markFirstShopRerollDiscountConsumed(_tileRerollLaneKey);
    marketModifiers = marketModifiers.copyWith(nextRerollDiscount: 0);
    _generateTileOffers(rng);
    return true;
  }

  bool rerollItemOffers({ItemPlacement placement = ItemPlacement.inventory}) {
    final cost = effectiveItemRerollCostFor(placement);
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    _increaseItemRerollCostFor(placement);
    _markFirstShopRerollDiscountConsumed(_rerollLaneKeyForPlacement(placement));
    final nextOffset =
        marketModifiers.itemOfferRerollOffsetFor(placement) +
        marketModifiers.itemOfferSlotCount;
    marketModifiers = marketModifiers.copyWith(
      nextRerollDiscount: 0,
      itemOfferRerollOffset: placement == ItemPlacement.inventory
          ? nextOffset
          : marketModifiers.itemOfferRerollOffset,
      quickSlotOfferRerollOffset: placement == ItemPlacement.quickSlot
          ? nextOffset
          : marketModifiers.quickSlotOfferRerollOffset,
      passiveOfferRerollOffset: placement == ItemPlacement.passiveRack
          ? nextOffset
          : marketModifiers.passiveOfferRerollOffset,
      toolOfferRerollOffset: placement == ItemPlacement.inventory
          ? nextOffset
          : marketModifiers.toolOfferRerollOffset,
      gearOfferRerollOffset: placement == ItemPlacement.equipped
          ? nextOffset
          : marketModifiers.gearOfferRerollOffset,
      pinnedItemOfferKeys: _itemOfferKeysWithoutPlacement(
        marketModifiers.pinnedItemOfferKeys,
        placement,
      ),
    );
    return true;
  }

  void _markFirstShopRerollDiscountConsumed(String laneKey) {
    if (marketModifiers.firstRerollDiscount > 0 &&
        !_firstShopRerollDiscountConsumedLanes.contains(laneKey)) {
      _firstShopRerollDiscountConsumedLanes.add(laneKey);
      firstShopRerollDiscountConsumed = true;
    }
  }

  void _increaseItemRerollCostFor(ItemPlacement placement) {
    switch (placement) {
      case ItemPlacement.quickSlot:
        quickSlotRerollCost += shopRerollCostStep;
      case ItemPlacement.passiveRack:
        passiveRerollCost += shopRerollCostStep;
      case ItemPlacement.inventory:
        toolRerollCost += shopRerollCostStep;
        itemRerollCost = toolRerollCost;
      case ItemPlacement.equipped:
        gearRerollCost += shopRerollCostStep;
    }
  }

  bool buyOffer(
    int offerIndex, {
    int? price,
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) {
      return false;
    }
    if (ownedJesters.length >= jesterSlotCapacity()) {
      return false;
    }
    final offer = shopOffers[offerIndex];
    final resolvedPrice = price ?? effectiveJesterOfferPrice(offerIndex);
    if (gold < resolvedPrice) {
      return false;
    }
    gold -= resolvedPrice;
    ownedJesters.add(offer.card);
    boughtJesterIds.add(offer.card.id);
    _initializeStateForSlot(ownedJesters.length - 1, offer.card);
    shopOffers.removeAt(offerIndex);
    _consumePurchaseDiscounts(
      'jester',
      consumeCheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount,
    );
    return true;
  }

  bool buyItem(
    ItemDefinition item, {
    int? price,
    ItemCatalog? itemCatalog,
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    final resolvedPrice = price ?? effectiveItemPrice(item);
    if (gold < resolvedPrice) {
      return false;
    }
    final capacity = quickSlotCapacity(itemCatalog: itemCatalog);
    if (!itemInventory.canAcquire(
      item,
      quickSlotCapacity: capacity,
      passiveRelicCapacity: passiveRelicCapacity(itemCatalog: itemCatalog),
    )) {
      return false;
    }
    gold -= resolvedPrice;
    itemInventory = itemInventory.withAcquiredItem(
      item,
      quickSlotCapacity: capacity,
      passiveRelicCapacity: passiveRelicCapacity(itemCatalog: itemCatalog),
    );
    boughtItemIds.add(item.id);
    _consumePurchaseDiscounts(
      'item',
      consumeCheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount,
    );
    return true;
  }

  bool sellOwnedItem(ItemDefinition item) {
    final existing = itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!existing) return false;
    itemInventory = itemInventory.withSoldItem(item.id);
    gold += item.sellPrice < 0 ? 0 : item.sellPrice;
    return true;
  }

  void markItemOfferConsumed(String itemId) {
    if (marketModifiers.consumedItemOfferIds.contains(itemId)) return;
    marketModifiers = marketModifiers.copyWith(
      consumedItemOfferIds: List<String>.unmodifiable([
        ...marketModifiers.consumedItemOfferIds,
        itemId,
      ]),
    );
  }

  void pinCurrentItemOfferKeys(Iterable<String> itemOfferKeys) {
    final keys = itemOfferKeys
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
    marketModifiers = marketModifiers.copyWith(
      pinnedItemOfferKeys: List<String>.unmodifiable(keys),
    );
  }

  static List<String> _itemOfferKeysWithoutPlacement(
    List<String> keys,
    ItemPlacement placement,
  ) {
    return List<String>.unmodifiable(
      keys.where(
        (key) => !RummiMarketModifierState.itemOfferKeyMatchesPlacement(
          key,
          placement,
        ),
      ),
    );
  }

  bool sellOwnedJester(int slotIndex, {ItemCatalog? itemCatalog}) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return false;
    }
    final sold = ownedJesters.removeAt(slotIndex);
    _removeStateAtSlot(slotIndex);
    gold +=
        _sellPriceFor(sold) + jesterSellPriceBonus(itemCatalog: itemCatalog);
    return true;
  }

  int sellPriceAt(int slotIndex, {ItemCatalog? itemCatalog}) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return 0;
    }
    return _sellPriceFor(ownedJesters[slotIndex]) +
        jesterSellPriceBonus(itemCatalog: itemCatalog);
  }

  int quickSlotCapacity({ItemCatalog? itemCatalog}) {
    return unlockedQuickSlotCapacity
        .clamp(
          RunInventoryState.defaultQuickSlotCapacity,
          RunInventoryState.maxQuickSlotCapacity,
        )
        .toInt();
  }

  int passiveRelicCapacity({ItemCatalog? itemCatalog}) {
    return unlockedPassiveRelicCapacity
        .clamp(
          RunInventoryState.defaultPassiveRelicCapacity,
          RunInventoryState.maxPassiveRelicCapacity,
        )
        .toInt();
  }

  int jesterSlotCapacity({ItemCatalog? itemCatalog}) {
    return unlockedJesterSlots.clamp(0, maxJesterSlots).toInt();
  }

  int jesterSellPriceBonus({ItemCatalog? itemCatalog}) {
    return _sumOwnedItemEffectAmount(
      itemCatalog: itemCatalog,
      timing: 'sell_jester',
      op: 'sell_price_bonus',
    );
  }

  void advanceStage(
    RummiPokerGridSession session, {
    required int runSeed,
    int? targetScoreOverride,
    int? boardDiscardsOverride,
    int? handDiscardsOverride,
    int? maxHandSizeOverride,
  }) {
    stageIndex += 1;
    _applyRoundEndStateDecay();
    session.prepareNextBlind(
      targetScore: targetScoreOverride ?? targetForStage(stageIndex),
      boardDiscardsRemaining:
          boardDiscardsOverride ?? session.blind.boardDiscardsMax,
      handDiscardsRemaining:
          handDiscardsOverride ?? session.blind.handDiscardsMax,
      shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(
        runSeed,
        stageIndex,
      ),
    );
    if (maxHandSizeOverride != null) {
      session.maxHandSize = maxHandSizeOverride;
    }
  }

  void onConfirmedLines(List<ConfirmedLineBreakdown> lineBreakdowns) {
    if (lineBreakdowns.isEmpty) {
      return;
    }
    final hadScoringFaceCard = lineBreakdowns.any(
      (line) => line.hasScoringFaceCard,
    );
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'green_jester') {
        _statefulValuesBySlot.update(
          slot,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      if (ownedJesters[slot].id == 'ride_the_bus') {
        if (hadScoringFaceCard) {
          _statefulValuesBySlot[slot] = 0;
        } else {
          _statefulValuesBySlot.update(
            slot,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
    for (final line in lineBreakdowns) {
      recordHandRankCompletion(line.rank);
      if (!isDeadLineRank(line.rank)) {
        _stationRankFinalScores.update(
          line.rank,
          (value) => value + line.finalScore,
          ifAbsent: () => line.finalScore,
        );
      }
    }
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'ice_cream') {
        final next = (_statefulValuesBySlot[slot] ?? 0) - 5;
        _statefulValuesBySlot[slot] = next < 0 ? 0 : next;
      }
    }
  }

  List<RummiOverkillGrowthBonus> claimOverkillGrowthBonus({
    required int targetScore,
    required int finalScore,
  }) {
    if (targetScore <= 0 ||
        finalScore <= 0 ||
        _stationRankFinalScores.isEmpty) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final thresholdPercent = _overkillThresholdPercent();
    final thresholdScore = ((targetScore * thresholdPercent) / 100).ceil();
    if (finalScore < thresholdScore) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final stationKey = '$stageIndex:$currentStationBlindTierIndex';
    if (_overkillGrowthClaimedStationKeys.contains(stationKey)) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final rank = _representativeOverkillRank();
    if (rank == null) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final applied = addHandRankProgress(rank);
    if (!applied) {
      return const <RummiOverkillGrowthBonus>[];
    }
    _overkillGrowthClaimedStationKeys.add(stationKey);
    return [
      RummiOverkillGrowthBonus(
        rank: rank,
        amount: 1,
        finalScore: finalScore,
        thresholdScore: thresholdScore,
      ),
    ];
  }

  int calculateOverkillGoldBonus({
    required int targetScore,
    required int finalScore,
  }) {
    if (targetScore <= 0 || finalScore <= 0) return 0;
    final surplusNumerator =
        finalScore * 100 - targetScore * _overkillThresholdPercent();
    if (surplusNumerator <= 0) return 0;
    return surplusNumerator ~/ (targetScore * 50);
  }

  int _overkillThresholdPercent() =>
      currentStationBlindTierIndex >= 2 ? 120 : 130;

  RummiHandRank? _representativeOverkillRank() {
    RummiHandRank? bestRank;
    var bestFinalScore = -1;
    var bestCurrentScore = -1;
    var bestBaseScore = -1;
    for (final entry in _stationRankFinalScores.entries) {
      if (isDeadLineRank(entry.key)) continue;
      final currentScore =
          gddBaseScore(entry.key) +
          RummiHandGrowth.growthBonusForState(
            rank: entry.key,
            state:
                _handGrowthStates[entry.key] ??
                RummiHandGrowthState.fromCompletedCount(
                  entry.key,
                  _playedHandCounts[entry.key] ?? 0,
                ),
          );
      final baseScore = gddBaseScore(entry.key);
      final isBetter =
          entry.value > bestFinalScore ||
          (entry.value == bestFinalScore && currentScore > bestCurrentScore) ||
          (entry.value == bestFinalScore &&
              currentScore == bestCurrentScore &&
              baseScore > bestBaseScore);
      if (!isBetter) continue;
      bestRank = entry.key;
      bestFinalScore = entry.value;
      bestCurrentScore = currentScore;
      bestBaseScore = baseScore;
    }
    return bestRank;
  }

  void onDiscardUsed() {
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'green_jester') {
        _statefulValuesBySlot.update(
          slot,
          (value) => value - 1,
          ifAbsent: () => -1,
        );
      }
    }
  }

  void _generateOffers({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    shopOffers.clear();
    final ownedIds = ownedJesters.map((card) => card.id).toSet();
    final pool = catalog.where((card) => !ownedIds.contains(card.id)).toList();
    if (pool.isEmpty) {
      return;
    }

    final requestedCount =
        offerCountOverride ?? marketModifiers.jesterOfferSlotCount;
    final slotCount = min(requestedCount, pool.length);
    final pickedIds = <String>{};
    for (final preferredId in preferredOfferIds) {
      if (shopOffers.length >= slotCount) break;
      final index = pool.indexWhere(
        (card) => card.id == preferredId && !pickedIds.contains(card.id),
      );
      if (index < 0) continue;
      final selected = pool.removeAt(index);
      pickedIds.add(selected.id);
      shopOffers.add(
        RummiShopOffer(slotIndex: shopOffers.length, card: selected),
      );
      seenMarketJesterIds.add(selected.id);
    }
    final focusSlot = _missingJesterGrowthFocusSlot(
      rng,
      startSlot: shopOffers.length,
      slotCount: slotCount,
      pressureProfile: pressureProfile,
    );
    for (var slot = 0; slot < slotCount && pool.isNotEmpty; slot++) {
      if (slot < shopOffers.length) {
        continue;
      }
      if (slot == focusSlot) {
        final missingTags = _missingJesterGrowthTags();
        final focusPool = pool
            .where((card) => _jesterMatchesAnyGrowthTag(card, missingTags))
            .toList(growable: false);
        if (focusPool.isNotEmpty) {
          final selected = _pickWeightedShopJester(pool: focusPool, rng: rng);
          pool.remove(selected);
          shopOffers.add(RummiShopOffer(slotIndex: slot, card: selected));
          seenMarketJesterIds.add(selected.id);
          continue;
        }
      }
      final selected = _pickWeightedShopJester(pool: pool, rng: rng);
      pool.remove(selected);
      shopOffers.add(RummiShopOffer(slotIndex: slot, card: selected));
      seenMarketJesterIds.add(selected.id);
    }
  }

  void _generateTileOffers(Random rng) {
    tileOffers.clear();
    final usedCodes = <String>{};
    final allTiles = buildStandardPokerDeck(copiesPerTile: 1);
    while (tileOffers.length < 3 && usedCodes.length < allTiles.length) {
      final tile = allTiles[rng.nextInt(allTiles.length)];
      final code = tile.code;
      if (!usedCodes.add(code)) continue;
      tileOffers.add(tile);
    }
  }

  RummiJesterCard _pickWeightedShopJester({
    required List<RummiJesterCard> pool,
    required Random rng,
  }) {
    final candidates = pool;
    final weights = candidates
        .map(_shopOfferWeightForCard)
        .toList(growable: false);
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) {
      return candidates[rng.nextInt(candidates.length)];
    }

    var roll = rng.nextInt(totalWeight);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        return candidates[i];
      }
    }
    return candidates.last;
  }

  int _shopOfferWeightForRarity(RummiJesterRarity rarity) {
    return RummiStationBandMarketPolicy.forStage(stageIndex).jesterRarityWeight(
      rarity,
      rarityWeightBonus: marketModifiers.rarityWeightBonus,
    );
  }

  int _shopOfferWeightForCard(RummiJesterCard card) {
    var weight = _shopOfferWeightForRarity(card.rarity);
    // 수집 audit가 실제 미수집 후보 노출을 볼 수 있도록 개별 미수집에도
    // 작은 가중치를 준다. 성장축 보강보다 약하며, 직접 지급/고정 노출은 아니다.
    if (!boughtJesterIds.contains(card.id)) weight += 45;
    if (!seenMarketJesterIds.contains(card.id)) weight += 90;
    return weight < 1 ? 1 : weight;
  }

  int? _missingJesterGrowthFocusSlot(
    Random rng, {
    required int startSlot,
    required int slotCount,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final missingTags = _missingJesterGrowthTags();
    if (missingTags.isEmpty || stageIndex <= 2 || startSlot >= slotCount) {
      return null;
    }
    final chance = stageIndex >= 6
        ? 45
        : stageIndex >= 4
        ? 35
        : 25;
    final pressureBonus =
        pressureProfile == RummiMarketPressureProfile.highStakes ? 15 : 0;
    if (rng.nextInt(100) >= chance + pressureBonus) return null;
    return startSlot + rng.nextInt(slotCount - startSlot);
  }

  Set<String> _missingJesterGrowthTags() {
    final station = stageIndex < 1 ? 1 : stageIndex;
    if (station <= 2) return const {};

    final ownedTags = <String>{};
    for (final card in ownedJesters) {
      ownedTags.addAll(_growthTagsForJester(card));
    }

    final missing = <String>{};
    final hasScoreGrowth =
        ownedTags.contains('score') ||
        ownedTags.contains('rank') ||
        ownedTags.contains('tile_color');
    if (!hasScoreGrowth) {
      missing.addAll(const ['score', 'rank', 'tile_color']);
    }

    if (station >= 6) {
      final hasBossGrowth =
          ownedTags.contains('boss') || ownedTags.contains('xmult');
      if (!hasBossGrowth) {
        missing.addAll(const ['boss', 'xmult']);
      }
    }

    return Set<String>.unmodifiable(missing);
  }

  static bool _jesterMatchesAnyGrowthTag(
    RummiJesterCard card,
    Set<String> expectedTags,
  ) {
    if (expectedTags.isEmpty) return false;
    for (final tag in _growthTagsForJester(card)) {
      if (expectedTags.contains(tag)) {
        return true;
      }
    }
    return false;
  }

  static Set<String> _growthTagsForJester(RummiJesterCard card) {
    final tags = <String>{};
    if (card.effectType == 'chips_bonus' ||
        card.effectType == 'mult_bonus' ||
        card.effectType == 'stateful_growth') {
      tags.add('score');
    }
    if (card.effectType == 'xmult_bonus') {
      tags.addAll(const ['score', 'xmult', 'boss']);
    }
    if (card.conditionType == 'rank_scored') {
      tags.add('rank');
    }
    if (card.conditionType == 'tile_color_scored') {
      tags.add('tile_color');
    }
    return Set<String>.unmodifiable(tags);
  }

  static int _sellPriceFor(RummiJesterCard card) {
    final value = card.baseCost ~/ 2;
    return value < 1 ? 1 : value;
  }

  int _sumOwnedItemEffectAmount({
    required ItemCatalog? itemCatalog,
    required String timing,
    required String op,
  }) {
    if (itemCatalog == null) return 0;
    var total = 0;
    for (final entry in itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = itemCatalog.findById(entry.itemId);
      if (item == null) continue;
      if (item.effect.timing != timing || item.effect.op != op) continue;
      final amount = (item.effect.amount ?? 0).toInt();
      if (amount > 0) total += amount * entry.count;
    }
    return total;
  }

  bool _cheapestFirstOfferDiscountApplies(int basePrice, String category) {
    if (marketModifiers.cheapestFirstOfferDiscount <= 0) return false;
    final firstJesterPrice = shopOffers.isEmpty ? null : shopOffers.first.price;
    final firstItemPrice = category == 'item' ? basePrice : null;
    return switch (category) {
      'jester' =>
        firstJesterPrice != null &&
            (firstItemPrice == null || firstJesterPrice <= firstItemPrice),
      'item' =>
        firstItemPrice != null &&
            (firstJesterPrice == null || firstItemPrice < firstJesterPrice),
      _ => false,
    };
  }

  void _consumePurchaseDiscounts(
    String category, {
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    marketModifiers = marketModifiers.copyWith(
      nextPurchaseDiscount: 0,
      nextJesterPurchaseDiscount: category == 'jester'
          ? 0
          : marketModifiers.nextJesterPurchaseDiscount,
      nextItemPurchaseDiscount: category == 'item'
          ? 0
          : marketModifiers.nextItemPurchaseDiscount,
      cheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount
          ? 0
          : marketModifiers.cheapestFirstOfferDiscount,
    );
  }

  void _initializeStateForSlot(int slotIndex, RummiJesterCard card) {
    // 상태형 Jester는 장착 슬롯 인덱스를 키로 쓴다.
    // 이후 점수 계산도 같은 슬롯 인덱스로 state를 조회하므로 순서가 규칙이다.
    final initialValue = switch (card.id) {
      'popcorn' || 'ice_cream' => card.value ?? 0,
      _ => 0,
    };
    if (initialValue > 0) {
      _statefulValuesBySlot[slotIndex] = initialValue;
    }
  }

  void _removeStateAtSlot(int slotIndex) {
    _statefulValuesBySlot.remove(slotIndex);
    final shifted = <int, int>{};
    for (final entry in _statefulValuesBySlot.entries) {
      final nextKey = entry.key > slotIndex ? entry.key - 1 : entry.key;
      shifted[nextKey] = entry.value;
    }
    _statefulValuesBySlot
      ..clear()
      ..addAll(shifted);
  }

  void _applyRoundEndStateDecay() {
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'popcorn') {
        final next = (_statefulValuesBySlot[slot] ?? 0) - 4;
        _statefulValuesBySlot[slot] = next < 0 ? 0 : next;
      }
    }
  }

  RummiRoundEndEconomyBonus? _buildRoundEndEconomyBonus({
    required RummiJesterCard card,
    required int remainingBoardDiscards,
    required int remainingHandDiscards,
  }) {
    if (!card.isSupportedInCurrentEconomyMeta) {
      return null;
    }

    final gold = switch (card.id) {
      'egg' || 'golden_jester' => card.value ?? 0,
      'delayed_gratification' =>
        (card.value ?? 0) * (remainingBoardDiscards + remainingHandDiscards),
      _ => 0,
    };
    if (gold <= 0) {
      return null;
    }
    return RummiRoundEndEconomyBonus(
      jesterId: card.id,
      displayName: card.displayName,
      gold: gold,
    );
  }
}

class RummiJesterScoreContext {
  const RummiJesterScoreContext({
    required this.discardsRemaining,
    required this.cardsRemainingInDeck,
    required this.ownedJesterCount,
    this.maxJesterSlots = RummiRunProgress.maxJesterSlots,
    this.stateValue = 0,
    this.currentHandPlayedCount = 0,
  });

  final int discardsRemaining;
  final int cardsRemainingInDeck;
  final int ownedJesterCount;
  final int maxJesterSlots;
  final int stateValue;
  final int currentHandPlayedCount;
}

class RummiJesterRuntimeSnapshot {
  const RummiJesterRuntimeSnapshot({
    this.slotStateValues = const {},
    this.playedHandCounts = const {},
    this.handGrowthStates = const {},
  });

  final Map<int, int> slotStateValues;
  final Map<RummiHandRank, int> playedHandCounts;
  final Map<RummiHandRank, RummiHandGrowthState> handGrowthStates;

  int stateValueForSlot(int slotIndex) => slotStateValues[slotIndex] ?? 0;

  int playedCountForRank(RummiHandRank rank) => playedHandCounts[rank] ?? 0;

  RummiHandGrowthState growthStateForRank(RummiHandRank rank) {
    return handGrowthStates[rank] ?? RummiHandGrowthState.initial(rank);
  }
}

class RummiLineScore {
  const RummiLineScore({
    required this.baseScore,
    required this.chipsBonus,
    required this.multBonus,
    required this.xmultBonus,
    required this.finalScore,
    this.effect,
  });

  final int baseScore;
  final int chipsBonus;
  final int multBonus;
  final double xmultBonus;
  final int finalScore;
  final RummiJesterEffectBreakdown? effect;
}

class RummiJesterEffectBreakdown {
  const RummiJesterEffectBreakdown({
    required this.jesterId,
    required this.displayName,
    required this.chipsBonus,
    required this.multBonus,
    required this.xmultBonus,
    required this.scoreDelta,
  });

  final String jesterId;
  final String displayName;
  final int chipsBonus;
  final int multBonus;
  final double xmultBonus;
  final int scoreDelta;

  bool get hasIntegerMultiplierToken =>
      xmultBonus > 1.0 && (xmultBonus - xmultBonus.round()).abs() < 0.05;

  int get multPercentBonus => multBonus * 5;

  String get displayToken {
    if (hasIntegerMultiplierToken) {
      return '점수 x${xmultBonus.round()}';
    }
    if (chipsBonus > 0) {
      return '+$chipsBonus';
    }
    if (multBonus > 0) {
      return '+$multPercentBonus%';
    }
    return '+$scoreDelta';
  }

  String get displaySuffix {
    if (hasIntegerMultiplierToken) {
      return '';
    }
    if (chipsBonus > 0) {
      return '칩';
    }
    if (multBonus > 0) {
      return '점수';
    }
    return '점수';
  }
}
