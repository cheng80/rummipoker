import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import 'hand_rank.dart';
import 'models/tile.dart';
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
    final mappedColors =
        (json['mappedTileColors'] as List<dynamic>? ?? const [])
            .map((value) => _tileColorFromString(value as String?))
            .whereType<TileColor>()
            .toList(growable: false);
    final mappedNumbers =
        (json['mappedTileNumbers'] as List<dynamic>? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false);

    return RummiJesterCard(
      id: json['id'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
      rarity: _rarityFromString(json['rarity'] as String?),
      baseCost: (json['baseCost'] as num?)?.toInt() ?? 0,
      effectText: json['effectText'] as String? ?? '',
      effectType: json['effectType'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      conditionType: json['conditionType'] as String? ?? '',
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

  static RummiJesterRarity _rarityFromString(String? value) {
    return switch (value) {
      'uncommon' => RummiJesterRarity.uncommon,
      'rare' => RummiJesterRarity.rare,
      'legendary' => RummiJesterRarity.legendary,
      _ => RummiJesterRarity.common,
    };
  }

  static TileColor? _tileColorFromString(String? value) {
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
      'suit_scored' => _countSuitMatches(scoringTiles) * bonus,
      'pair' ||
      'two_pair' ||
      'three_of_a_kind' ||
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
      'suit_scored' => _countSuitMatches(scoringTiles) * bonus,
      'pair' ||
      'two_pair' ||
      'three_of_a_kind' ||
      'straight' ||
      'flush' => _matchesRankCondition(rank) ? bonus : 0,
      'face_card' => _countFaceCards(scoringTiles) * bonus,
      'rank_scored' => _countRankMatches(scoringTiles) * bonus,
      'other' => _otherMultBonus(scoringTiles, context, bonus),
      _ => 0,
    };
  }

  double _evaluateXmultBonus({
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
      'straight' =>
        rank == RummiHandRank.straight || rank == RummiHandRank.straightFlush,
      'flush' =>
        rank == RummiHandRank.flush || rank == RummiHandRank.straightFlush,
      _ => false,
    };
  }

  int _countSuitMatches(List<Tile> scoringTiles) {
    if (mappedTileColors.isEmpty) return 0;
    return scoringTiles
        .where((tile) => mappedTileColors.contains(tile.color))
        .length;
  }

  int _countFaceCards(List<Tile> scoringTiles) {
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

  static Future<RummiJesterCatalog> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return RummiJesterCatalog.fromJsonString(jsonString);
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
        .where((card) {
          return card.effectType == 'chips_bonus' ||
              card.effectType == 'mult_bonus' ||
              card.effectType == 'xmult_bonus' ||
              card.id == 'scholar';
        })
        .toList(growable: false);
  }
}

class RummiShopOffer {
  const RummiShopOffer({required this.slotIndex, required this.card});

  final int slotIndex;
  final RummiJesterCard card;

  int get price => card.baseCost;
}

class RummiCashOutBreakdown {
  const RummiCashOutBreakdown({
    required this.stageIndex,
    required this.targetScore,
    required this.blindReward,
    required this.remainingDiscards,
    required this.perDiscardBonus,
    required this.discardGold,
    required this.totalGold,
  });

  final int stageIndex;
  final int targetScore;
  final int blindReward;
  final int remainingDiscards;
  final int perDiscardBonus;
  final int discardGold;
  final int totalGold;
}

class RummiRunProgress {
  static const int maxJesterSlots = 5;
  static const int stageClearGoldBase = 10;
  static const int remainingDiscardGoldBonus = 5;
  static const int shopBaseRerollCost = 5;

  int stageIndex = 1;
  int gold = 10;
  int rerollCost = shopBaseRerollCost;
  final List<RummiJesterCard> ownedJesters = <RummiJesterCard>[];
  final List<RummiShopOffer> shopOffers = <RummiShopOffer>[];

  int targetForStage(int stageNumber) {
    if (stageNumber <= 1) {
      return 300;
    }
    final scaled = 300 * pow(1.6, stageNumber - 1);
    return scaled.floor();
  }

  RummiCashOutBreakdown buildCashOutBreakdown(RummiPokerGridSession session) {
    final blindReward = stageClearGoldBase;
    final remainingDiscards = session.blind.discardsRemaining;
    final discardGold = remainingDiscards * remainingDiscardGoldBonus;
    return RummiCashOutBreakdown(
      stageIndex: stageIndex,
      targetScore: session.blind.targetScore,
      blindReward: blindReward,
      remainingDiscards: remainingDiscards,
      perDiscardBonus: remainingDiscardGoldBonus,
      discardGold: discardGold,
      totalGold: blindReward + discardGold,
    );
  }

  void applyCashOut(RummiCashOutBreakdown breakdown) {
    gold += breakdown.totalGold;
  }

  void openShop({required List<RummiJesterCard> catalog, required Random rng}) {
    rerollCost = shopBaseRerollCost;
    _generateOffers(catalog: catalog, rng: rng);
  }

  bool canAfford(int cost) => gold >= cost;

  bool rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
  }) {
    if (gold < rerollCost) {
      return false;
    }
    gold -= rerollCost;
    rerollCost += 1;
    _generateOffers(catalog: catalog, rng: rng);
    return true;
  }

  bool buyOffer(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) {
      return false;
    }
    if (ownedJesters.length >= maxJesterSlots) {
      return false;
    }
    final offer = shopOffers[offerIndex];
    if (gold < offer.price) {
      return false;
    }
    gold -= offer.price;
    ownedJesters.add(offer.card);
    shopOffers.removeAt(offerIndex);
    return true;
  }

  bool sellOwnedJester(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return false;
    }
    final sold = ownedJesters.removeAt(slotIndex);
    gold += _sellPriceFor(sold);
    return true;
  }

  int sellPriceAt(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return 0;
    }
    return _sellPriceFor(ownedJesters[slotIndex]);
  }

  void advanceStage(
    RummiPokerGridSession session, {
    required int runSeed,
  }) {
    stageIndex += 1;
    session.prepareNextBlind(
      targetScore: targetForStage(stageIndex),
      discardsRemaining: session.blind.discardsMax,
      shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(
        runSeed,
        stageIndex,
      ),
    );
  }

  void _generateOffers({
    required List<RummiJesterCard> catalog,
    required Random rng,
  }) {
    shopOffers.clear();
    final ownedIds = ownedJesters.map((card) => card.id).toSet();
    final pool = catalog.where((card) => !ownedIds.contains(card.id)).toList();
    if (pool.isEmpty) {
      return;
    }

    final slotCount = pool.length <= 2 ? pool.length : 2 + rng.nextInt(2);
    for (var slot = 0; slot < slotCount && pool.isNotEmpty; slot++) {
      final selected = pool.removeAt(rng.nextInt(pool.length));
      shopOffers.add(RummiShopOffer(slotIndex: slot, card: selected));
    }
  }

  static int _sellPriceFor(RummiJesterCard card) {
    final value = card.baseCost ~/ 2;
    return value < 1 ? 1 : value;
  }
}

class RummiJesterScoreContext {
  const RummiJesterScoreContext({
    required this.discardsRemaining,
    required this.cardsRemainingInDeck,
    required this.ownedJesterCount,
    this.maxJesterSlots = RummiRunProgress.maxJesterSlots,
  });

  final int discardsRemaining;
  final int cardsRemainingInDeck;
  final int ownedJesterCount;
  final int maxJesterSlots;
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

  String get displayToken {
    if (hasIntegerMultiplierToken) {
      return 'x${xmultBonus.round()}';
    }
    if (chipsBonus > 0) {
      return '+$chipsBonus';
    }
    if (multBonus > 0) {
      return '+$multBonus';
    }
    return '+$scoreDelta';
  }

  String get displaySuffix {
    if (hasIntegerMultiplierToken) {
      return '';
    }
    if (chipsBonus > 0) {
      return 'Chips';
    }
    if (multBonus > 0) {
      return 'Mult';
    }
    return '점수';
  }
}
