enum NewRunDifficulty { standard, relaxed, pressure }

enum NewRunModifier {
  basic(
    id: 'basic',
    label: '기본 런',
    targetScoreMultiplier: 1,
    rewardMultiplier: 1,
    unlockCostInsight: 0,
  ),
  highStakes(
    id: 'high_stakes',
    label: '하이 스테이크',
    targetScoreMultiplier: 1.04,
    rewardMultiplier: 1.12,
    unlockCostInsight: 20,
  );

  const NewRunModifier({
    required this.id,
    required this.label,
    required this.targetScoreMultiplier,
    required this.rewardMultiplier,
    required this.unlockCostInsight,
  });

  final String id;
  final String label;
  final double targetScoreMultiplier;
  final double rewardMultiplier;
  final int unlockCostInsight;

  static NewRunModifier parse(String? raw) {
    return switch (raw) {
      'basic' => NewRunModifier.basic,
      'high_stakes' => NewRunModifier.highStakes,
      _ => NewRunModifier.basic,
    };
  }
}

class NewRunSetup {
  const NewRunSetup({
    required this.difficulty,
    this.runModifier = NewRunModifier.basic,
  });

  final NewRunDifficulty difficulty;
  final NewRunModifier runModifier;

  String get difficultyParam => difficulty.name;
  String get runModifierParam => runModifier.id;

  String get difficultyLabel => switch (difficulty) {
    NewRunDifficulty.standard => '표준',
    NewRunDifficulty.relaxed => '완화',
    NewRunDifficulty.pressure => '압박',
  };

  bool get isDifficultyUnlocked => isDifficultySelectable(difficulty);

  static NewRunDifficulty parseDifficulty(String? raw) {
    return switch (raw) {
      'relaxed' => NewRunDifficulty.relaxed,
      'pressure' => NewRunDifficulty.pressure,
      _ => NewRunDifficulty.standard,
    };
  }

  static bool isDifficultySelectable(NewRunDifficulty difficulty) {
    return switch (difficulty) {
      NewRunDifficulty.standard => true,
      NewRunDifficulty.relaxed => false,
      NewRunDifficulty.pressure => false,
    };
  }

  static NewRunDifficulty resolveSelectableDifficulty(
    NewRunDifficulty difficulty,
  ) {
    return isDifficultySelectable(difficulty)
        ? difficulty
        : NewRunDifficulty.standard;
  }
}
