import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import 'new_run_setup.dart';

enum BlindTier { small, big, boss }

class BlindSelectionSpec {
  const BlindSelectionSpec({
    required this.tier,
    required this.title,
    required this.badgeLabel,
    required this.description,
    required this.targetScore,
    required this.boardDiscards,
    required this.handDiscards,
    required this.maxHandSize,
    required this.rewardPreview,
    required this.isUnlocked,
    this.lockReason,
  });

  final BlindTier tier;
  final String title;
  final String badgeLabel;
  final String description;
  final int targetScore;
  final int boardDiscards;
  final int handDiscards;
  final int maxHandSize;
  final int rewardPreview;
  final bool isUnlocked;
  final String? lockReason;
}

class BlindSelectionSetup {
  const BlindSelectionSetup._();

  static BlindTier parseTier(String? raw) {
    return switch (raw) {
      'big' => BlindTier.big,
      'boss' => BlindTier.boss,
      _ => BlindTier.small,
    };
  }

  static List<BlindSelectionSpec> buildStageOne({
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) {
    return <BlindSelectionSpec>[
      _buildSpec(
        tier: BlindTier.small,
        difficulty: difficulty,
        ruleset: ruleset,
        isUnlocked: true,
      ),
      _buildSpec(
        tier: BlindTier.big,
        difficulty: difficulty,
        ruleset: ruleset,
        isUnlocked: false,
        lockReason: '빅 블라인드는 다음 단계에서 연결 예정',
      ),
      _buildSpec(
        tier: BlindTier.boss,
        difficulty: difficulty,
        ruleset: ruleset,
        isUnlocked: false,
        lockReason: '보스 블라인드는 규칙 확정 후 연결 예정',
      ),
    ];
  }

  static BlindSelectionSpec resolveSpec({
    required BlindTier tier,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
  }) {
    return _buildSpec(
      tier: tier,
      difficulty: difficulty,
      ruleset: ruleset,
      isUnlocked: true,
    );
  }

  static BlindSelectionSpec _buildSpec({
    required BlindTier tier,
    required NewRunDifficulty difficulty,
    required RummiRuleset ruleset,
    required bool isUnlocked,
    String? lockReason,
  }) {
    final baseTarget = switch (difficulty) {
      NewRunDifficulty.standard => 300,
      NewRunDifficulty.relaxed => 240,
      NewRunDifficulty.pressure => 360,
    };
    final baseBoardDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultBoardDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultBoardDiscards + 1,
      NewRunDifficulty.pressure => ruleset.defaultBoardDiscards - 1,
    };
    final baseHandDiscards = switch (difficulty) {
      NewRunDifficulty.standard => ruleset.defaultHandDiscards,
      NewRunDifficulty.relaxed => ruleset.defaultHandDiscards + 1,
      NewRunDifficulty.pressure => ruleset.defaultHandDiscards - 1,
    };
    final baseHandSize = ruleset.defaultMaxHandSize;
    final rewardBase = RummiRunProgress.stageClearGoldBase;

    final targetScore = switch (tier) {
      BlindTier.small => baseTarget,
      BlindTier.big => baseTarget + 150,
      BlindTier.boss => baseTarget + 300,
    };
    final boardDiscards = switch (tier) {
      BlindTier.small => baseBoardDiscards,
      BlindTier.big => baseBoardDiscards > 1 ? baseBoardDiscards - 1 : 1,
      BlindTier.boss => baseBoardDiscards > 1 ? baseBoardDiscards - 1 : 1,
    };
    final handDiscards = switch (tier) {
      BlindTier.small => baseHandDiscards,
      BlindTier.big => baseHandDiscards,
      BlindTier.boss => baseHandDiscards > 1 ? baseHandDiscards - 1 : 1,
    };
    final maxHandSize = switch (tier) {
      BlindTier.small => baseHandSize,
      BlindTier.big => baseHandSize,
      BlindTier.boss => baseHandSize > 1 ? baseHandSize - 1 : 1,
    };
    final rewardPreview = switch (tier) {
      BlindTier.small => rewardBase,
      BlindTier.big => rewardBase + 4,
      BlindTier.boss => rewardBase + 8,
    };

    return BlindSelectionSpec(
      tier: tier,
      title: switch (tier) {
        BlindTier.small => '스몰 블라인드',
        BlindTier.big => '빅 블라인드',
        BlindTier.boss => '보스 블라인드',
      },
      badgeLabel: switch (tier) {
        BlindTier.small => 'SMALL',
        BlindTier.big => 'BIG',
        BlindTier.boss => 'BOSS',
      },
      description: switch (tier) {
        BlindTier.small => '기본 조건으로 런을 시작합니다.',
        BlindTier.big => '목표 점수를 크게 올리고 보드 버림 여유를 줄입니다.',
        BlindTier.boss => '손패 크기와 버림 여유를 줄인 강한 압박 블라인드입니다.',
      },
      targetScore: targetScore,
      boardDiscards: boardDiscards,
      handDiscards: handDiscards,
      maxHandSize: maxHandSize,
      rewardPreview: rewardPreview,
      isUnlocked: isUnlocked,
      lockReason: lockReason,
    );
  }
}
