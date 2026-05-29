part of 'jester_meta.dart';

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
