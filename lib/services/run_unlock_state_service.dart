import 'dart:convert';

import '../app_config.dart';
import '../utils/storage_helper.dart';
import 'new_run_setup.dart';

class RunUnlockState {
  const RunUnlockState({
    required this.unlockedDifficultyNames,
    required this.clearedDifficultyNames,
    required this.availableDeckIds,
    required this.unlockedRunModifierIds,
    required this.insight,
    this.seenMarketJesterIds = const <String>{},
    this.seenMarketItemIds = const <String>{},
    this.boughtJesterIds = const <String>{},
    this.boughtItemIds = const <String>{},
    this.seenBossModifierIds = const <String>{},
    this.clearedStationKeys = const <String>{},
    this.earnedMemoryCardIds = const <String>{},
  });

  factory RunUnlockState.defaults() {
    return const RunUnlockState(
      unlockedDifficultyNames: <String>{'standard'},
      clearedDifficultyNames: <String>{},
      availableDeckIds: <String>{'basic_deck'},
      unlockedRunModifierIds: <String>{'basic'},
      insight: 0,
    );
  }

  factory RunUnlockState.fromJson(Map<String, dynamic> json) {
    final rawDifficultyNames =
        (json['unlockedDifficultyNames'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toSet();
    final rawDeckIds =
        (json['availableDeckIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toSet();
    final rawRunModifierIds =
        (json['unlockedRunModifierIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toSet();

    return RunUnlockState(
      unlockedDifficultyNames: rawDifficultyNames.isEmpty
          ? RunUnlockState.defaults().unlockedDifficultyNames
          : rawDifficultyNames,
      clearedDifficultyNames:
          (json['clearedDifficultyNames'] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toSet(),
      availableDeckIds: rawDeckIds.isEmpty
          ? RunUnlockState.defaults().availableDeckIds
          : rawDeckIds,
      unlockedRunModifierIds: rawRunModifierIds.isEmpty
          ? RunUnlockState.defaults().unlockedRunModifierIds
          : rawRunModifierIds,
      insight: (json['insight'] as num?)?.toInt() ?? 0,
      seenMarketJesterIds: _stringSet(json['seenMarketJesterIds']),
      seenMarketItemIds: _stringSet(json['seenMarketItemIds']),
      boughtJesterIds: _stringSet(json['boughtJesterIds']),
      boughtItemIds: _stringSet(json['boughtItemIds']),
      seenBossModifierIds: _stringSet(json['seenBossModifierIds']),
      clearedStationKeys: _stringSet(json['clearedStationKeys']),
      earnedMemoryCardIds: _stringSet(json['earnedMemoryCardIds']),
    );
  }

  final Set<String> unlockedDifficultyNames;
  final Set<String> clearedDifficultyNames;
  final Set<String> availableDeckIds;
  final Set<String> unlockedRunModifierIds;
  final int insight;
  final Set<String> seenMarketJesterIds;
  final Set<String> seenMarketItemIds;
  final Set<String> boughtJesterIds;
  final Set<String> boughtItemIds;
  final Set<String> seenBossModifierIds;
  final Set<String> clearedStationKeys;
  final Set<String> earnedMemoryCardIds;

  Map<String, dynamic> toJson() => {
    'unlockedDifficultyNames': unlockedDifficultyNames.toList()..sort(),
    'clearedDifficultyNames': clearedDifficultyNames.toList()..sort(),
    'availableDeckIds': availableDeckIds.toList()..sort(),
    'unlockedRunModifierIds': unlockedRunModifierIds.toList()..sort(),
    'insight': insight,
    'seenMarketJesterIds': seenMarketJesterIds.toList()..sort(),
    'seenMarketItemIds': seenMarketItemIds.toList()..sort(),
    'boughtJesterIds': boughtJesterIds.toList()..sort(),
    'boughtItemIds': boughtItemIds.toList()..sort(),
    'seenBossModifierIds': seenBossModifierIds.toList()..sort(),
    'clearedStationKeys': clearedStationKeys.toList()..sort(),
    'earnedMemoryCardIds': earnedMemoryCardIds.toList()..sort(),
  };

  bool isDifficultyUnlocked(NewRunDifficulty difficulty) {
    return unlockedDifficultyNames.contains(difficulty.name);
  }

  bool isDifficultyCleared(NewRunDifficulty difficulty) {
    return clearedDifficultyNames.contains(difficulty.name);
  }

  bool isDeckAvailable(String deckId) {
    return availableDeckIds.contains(deckId);
  }

  bool isRunModifierUnlocked(NewRunModifier modifier) {
    return unlockedRunModifierIds.contains(modifier.id);
  }

  RunUnlockState copyWith({
    Set<String>? unlockedDifficultyNames,
    Set<String>? clearedDifficultyNames,
    Set<String>? availableDeckIds,
    Set<String>? unlockedRunModifierIds,
    int? insight,
    Set<String>? seenMarketJesterIds,
    Set<String>? seenMarketItemIds,
    Set<String>? boughtJesterIds,
    Set<String>? boughtItemIds,
    Set<String>? seenBossModifierIds,
    Set<String>? clearedStationKeys,
    Set<String>? earnedMemoryCardIds,
  }) {
    return RunUnlockState(
      unlockedDifficultyNames:
          unlockedDifficultyNames ?? this.unlockedDifficultyNames,
      clearedDifficultyNames:
          clearedDifficultyNames ?? this.clearedDifficultyNames,
      availableDeckIds: availableDeckIds ?? this.availableDeckIds,
      unlockedRunModifierIds:
          unlockedRunModifierIds ?? this.unlockedRunModifierIds,
      insight: insight ?? this.insight,
      seenMarketJesterIds: seenMarketJesterIds ?? this.seenMarketJesterIds,
      seenMarketItemIds: seenMarketItemIds ?? this.seenMarketItemIds,
      boughtJesterIds: boughtJesterIds ?? this.boughtJesterIds,
      boughtItemIds: boughtItemIds ?? this.boughtItemIds,
      seenBossModifierIds: seenBossModifierIds ?? this.seenBossModifierIds,
      clearedStationKeys: clearedStationKeys ?? this.clearedStationKeys,
      earnedMemoryCardIds: earnedMemoryCardIds ?? this.earnedMemoryCardIds,
    );
  }

  static Set<String> _stringSet(Object? value) {
    return (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toSet();
  }
}

class RunCollectionUpdate {
  const RunCollectionUpdate({
    this.seenMarketJesterIds = const <String>{},
    this.seenMarketItemIds = const <String>{},
    this.boughtJesterIds = const <String>{},
    this.boughtItemIds = const <String>{},
    this.seenBossModifierIds = const <String>{},
    this.clearedStationKeys = const <String>{},
    this.earnedMemoryCardIds = const <String>{},
  });

  final Set<String> seenMarketJesterIds;
  final Set<String> seenMarketItemIds;
  final Set<String> boughtJesterIds;
  final Set<String> boughtItemIds;
  final Set<String> seenBossModifierIds;
  final Set<String> clearedStationKeys;
  final Set<String> earnedMemoryCardIds;
}

class RunUnlockStateService {
  RunUnlockStateService._();

  static Future<RunUnlockState> load() async {
    final raw = StorageHelper.readString(
      StorageKeys.runUnlockStateV1,
      defaultValue: '',
    );
    if (raw.isEmpty) {
      final defaults = RunUnlockState.defaults();
      await save(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid unlock state payload');
      }
      return RunUnlockState.fromJson(decoded);
    } catch (_) {
      final defaults = RunUnlockState.defaults();
      await save(defaults);
      return defaults;
    }
  }

  static Future<void> save(RunUnlockState state) {
    return StorageHelper.write(
      StorageKeys.runUnlockStateV1,
      jsonEncode(state.toJson()),
    );
  }

  static Future<void> unlockDifficulty(NewRunDifficulty difficulty) async {
    final current = await load();
    await save(
      current.copyWith(
        unlockedDifficultyNames: <String>{
          ...current.unlockedDifficultyNames,
          difficulty.name,
        },
      ),
    );
  }

  static Future<void> markDifficultyCleared(NewRunDifficulty difficulty) async {
    final current = await load();
    await save(
      current.copyWith(
        clearedDifficultyNames: <String>{
          ...current.clearedDifficultyNames,
          difficulty.name,
        },
      ),
    );
  }

  static Future<void> addInsight(int amount) async {
    if (amount <= 0) return;
    final current = await load();
    await save(current.copyWith(insight: current.insight + amount));
  }

  static Future<void> recordRunCollection(RunCollectionUpdate update) async {
    final current = await load();
    await save(
      current.copyWith(
        seenMarketJesterIds: <String>{
          ...current.seenMarketJesterIds,
          ...update.seenMarketJesterIds,
        },
        seenMarketItemIds: <String>{
          ...current.seenMarketItemIds,
          ...update.seenMarketItemIds,
        },
        boughtJesterIds: <String>{
          ...current.boughtJesterIds,
          ...update.boughtJesterIds,
        },
        boughtItemIds: <String>{
          ...current.boughtItemIds,
          ...update.boughtItemIds,
        },
        seenBossModifierIds: <String>{
          ...current.seenBossModifierIds,
          ...update.seenBossModifierIds,
        },
        clearedStationKeys: <String>{
          ...current.clearedStationKeys,
          ...update.clearedStationKeys,
        },
        earnedMemoryCardIds: <String>{
          ...current.earnedMemoryCardIds,
          ...update.earnedMemoryCardIds,
        },
      ),
    );
  }

  static Future<bool> unlockRunModifier(NewRunModifier modifier) async {
    if (modifier == NewRunModifier.basic) return true;
    final current = await load();
    if (current.isRunModifierUnlocked(modifier)) return true;
    if (current.insight < modifier.unlockCostInsight) return false;
    await save(
      current.copyWith(
        insight: current.insight - modifier.unlockCostInsight,
        unlockedRunModifierIds: <String>{
          ...current.unlockedRunModifierIds,
          modifier.id,
        },
      ),
    );
    return true;
  }
}
