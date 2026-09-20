part of '../archive_view.dart';

class _ArchiveMemoryCardDefinition {
  const _ArchiveMemoryCardDefinition({
    required this.id,
    required this.titleKey,
    this.stage,
    required this.badgeKey,
  });

  final String id;
  final String titleKey;
  final int? stage;
  final String badgeKey;

  String localizedTitle(BuildContext context) => context.translate(
    titleKey,
    namedArgs: {if (stage != null) 'stage': '$stage'},
  );
}

const List<_ArchiveMemoryCardDefinition> _archiveMemoryCards = [
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s1',
    titleKey: 'menuMemoryStandardStage',
    stage: 1,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s2',
    titleKey: 'menuMemoryStandardStage',
    stage: 2,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s3',
    titleKey: 'menuMemoryStandardStage',
    stage: 3,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s4',
    titleKey: 'menuMemoryStandardStage',
    stage: 4,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s5',
    titleKey: 'menuMemoryStandardStage',
    stage: 5,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s6',
    titleKey: 'menuMemoryStandardStage',
    stage: 6,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s7',
    titleKey: 'menuMemoryStandardStage',
    stage: 7,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s8',
    titleKey: 'menuMemoryStandardStage',
    stage: 8,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_completed_standard_s8',
    titleKey: 'menuMemoryStandardComplete',
    badgeKey: 'tutorialDone',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s1',
    titleKey: 'menuMemoryChallengeStage',
    stage: 1,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s2',
    titleKey: 'menuMemoryChallengeStage',
    stage: 2,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s3',
    titleKey: 'menuMemoryChallengeStage',
    stage: 3,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s4',
    titleKey: 'menuMemoryChallengeStage',
    stage: 4,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s5',
    titleKey: 'menuMemoryChallengeStage',
    stage: 5,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s6',
    titleKey: 'menuMemoryChallengeStage',
    stage: 6,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s7',
    titleKey: 'menuMemoryChallengeStage',
    stage: 7,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s8',
    titleKey: 'menuMemoryChallengeStage',
    stage: 8,
    badgeKey: 'menuDefeat',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_completed_challenge_s8',
    titleKey: 'menuMemoryChallengeComplete',
    badgeKey: 'tutorialDone',
  ),
];
