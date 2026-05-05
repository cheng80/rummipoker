import 'dart:convert';

import '../app_config.dart';
import '../utils/storage_helper.dart';
import 'new_run_setup.dart';

class RunUnlockState {
  const RunUnlockState({
    required this.unlockedDifficultyNames,
    required this.clearedDifficultyNames,
    required this.availableDeckIds,
    required this.insight,
  });

  factory RunUnlockState.defaults() {
    return const RunUnlockState(
      unlockedDifficultyNames: <String>{'standard'},
      clearedDifficultyNames: <String>{},
      availableDeckIds: <String>{'basic_deck'},
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
      insight: (json['insight'] as num?)?.toInt() ?? 0,
    );
  }

  final Set<String> unlockedDifficultyNames;
  final Set<String> clearedDifficultyNames;
  final Set<String> availableDeckIds;
  final int insight;

  Map<String, dynamic> toJson() => {
    'unlockedDifficultyNames': unlockedDifficultyNames.toList()..sort(),
    'clearedDifficultyNames': clearedDifficultyNames.toList()..sort(),
    'availableDeckIds': availableDeckIds.toList()..sort(),
    'insight': insight,
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

  RunUnlockState copyWith({
    Set<String>? unlockedDifficultyNames,
    Set<String>? clearedDifficultyNames,
    Set<String>? availableDeckIds,
    int? insight,
  }) {
    return RunUnlockState(
      unlockedDifficultyNames:
          unlockedDifficultyNames ?? this.unlockedDifficultyNames,
      clearedDifficultyNames:
          clearedDifficultyNames ?? this.clearedDifficultyNames,
      availableDeckIds: availableDeckIds ?? this.availableDeckIds,
      insight: insight ?? this.insight,
    );
  }
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
}
