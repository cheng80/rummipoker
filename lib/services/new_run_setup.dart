enum NewRunDifficulty { standard, relaxed, pressure }

class NewRunSetup {
  const NewRunSetup({
    required this.difficulty,
  });

  final NewRunDifficulty difficulty;

  String get difficultyParam => difficulty.name;

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
