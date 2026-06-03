part of 'debug_run_fixture_service.dart';

/// 새 디버그 픽스처는 여기에 등록하고, 대응하는 builder는 builders part에 둔다.
final List<DebugRunFixtureDefinition> _debugRunFixtures = [
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.stage2ScoringSnapshot,
    label: 'Stage 2 점수 스냅샷',
    description:
        'Stage 2 / Gold 36 / Run Call + Face Battery / 손패 비어 있음 / 덱 34',
    builder: _buildStage2ScoringSnapshot,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.stage2MarketResume,
    label: 'Stage 2 Market 복귀',
    description: 'Stage 2 / Shop scene 복귀 / Gold 46 / 다음 Station 자동 진행 검증용',
    builder: _buildStage2MarketResume,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.deckNeedleBattle,
    label: 'Deck Needle 전투 아이템',
    description: 'Deck Needle 보유 / 덱 상단 3장 확인 dialog 검증용',
    builder: _buildDeckNeedleBattle,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.handCapacityIncreasePreviewBattle,
    label: '손패 증가 연출 전투',
    description: '전투 진입 후 손패 1/1에서 1/3으로 자동 증가 / 드로우 버튼 pulse 검증용',
    builder: _buildHandCapacityIncreasePreviewBattle,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.handCapacityDeckControlBattle,
    label: '손패 증가 + 덱 제어 전투',
    description: '손패 1/3 + Travel Pouch + Deck Needle / 드로우 잔여 칸과 덱 버림 UI 검증용',
    builder: _buildHandCapacityDeckControlBattle,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.screenshotRunGrowthBattle,
    label: '스크린샷용 런 성장 전투',
    description: '스크린샷 제작용 / 런 정보에서 성장한 족보와 다음 성장 후보 표시',
    builder: _buildScreenshotRunGrowthBattle,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.marketModifierShop,
    label: 'Market Modifier 상점',
    description: '리롤/구매 할인 + Item offer 4칸 검증용',
    builder: _buildMarketModifierShop,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.slotUnlockMarket,
    label: '슬롯 해금 Market',
    description: 'S2/S4/S6 Boss 보상 슬롯 해금 배너와 Jester/Item/Passive 열린 상태 검증용',
    builder: _buildSlotUnlockMarket,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.safetyNetExpiryGuard,
    label: 'Safety Net 종료 방지',
    description: 'Safety Net 보유 / 보드가 꽉 찬 종료 위기 구조 검증용',
    builder: _buildSafetyNetExpiryGuard,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.gameOverInsightReady,
    label: '게임오버 기억 카드 체크',
    description: '보드 꽉 참 + 보드 버림 0 / 패배 보상 카드 검증용',
    builder: _buildGameOverInsightReady,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.animationEffectsEyeCheck,
    label: '연출 눈검증 전투',
    description:
        '점수 preview pulse / line confirm particle / quick item toast 검증용',
    builder: _buildAnimationEffectsEyeCheck,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.itemMotionEyeCheck,
    label: '아이템 모션 눈검증 전투',
    description: 'Deck Needle / Emergency Draw / Slide Wax 발동-대상-결과 검증용',
    builder: _buildItemMotionEyeCheck,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.nextConfirmMotionEyeCheck,
    label: '다음 확정 아이템 눈검증 전투',
    description: 'Straight Oil queued badge / preview / settlement burst 검증용',
    builder: _buildNextConfirmMotionEyeCheck,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.marketItemMotionEyeCheck,
    label: '마켓 아이템 모션 눈검증',
    description: '골드/비골드 상점 아이템 use flight 검증용',
    builder: _buildMarketItemMotionEyeCheck,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.specialTileMarketPreview,
    label: '특수 타일 Market 미리보기',
    description: '특수 타일 badge, 가격, 구매 상세 문구 스크린샷 검증용',
    builder: _buildSpecialTileMarketPreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.specialTileBattlePreview,
    label: '특수 타일 전투 미리보기',
    description: '손패/보드 특수 타일 badge와 확정 가능 라인 스크린샷 검증용',
    builder: _buildSpecialTileBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.lineMemoryMarketPreview,
    label: 'Line Memory Market 미리보기',
    description: 'Line Memory 의식 카드가 상점 후보 카드로 보이는지 검증용',
    builder: _buildLineMemoryMarketPreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.lineMemoryBattlePreview,
    label: 'Line Memory 전투 미리보기',
    description: '완성 줄 + Line Memory Q-slot 보유 + 사용 피드백 검증용',
    builder: _buildLineMemoryBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.ritualGrowthCopyBattlePreview,
    label: 'Ritual 성장/복사 전투',
    description: '라인 기억/중심석 복사/숫자 메아리 보드 선 선택 검증용',
    builder: _buildRitualGrowthCopyBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.ritualDeckEchoBattlePreview,
    label: 'Ritual 덱 복사/메아리 전투',
    description: '각인 복사/희소석 복사/색 메아리 scoringTiles 선택 검증용',
    builder: _buildRitualDeckEchoBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.ritualSealOverrideBattlePreview,
    label: 'Ritual 각인/변환 전투',
    description: '라인 각인/금빛 각인/숫자 맞춤 의식 선택 검증용',
    builder: _buildRitualSealOverrideBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.ritualPruneBurnBattlePreview,
    label: 'Ritual 압축/소각 전투',
    description: '색 가지치기/마른가지 소각/제물 의식 선택 검증용',
    builder: _buildRitualPruneBurnBattlePreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.s8ColorJesterStackPreview,
    label: 'S8 색상 Jester 중첩 전투',
    description: 'S8 Boss / 색상 호출 + 색상 증폭 보유 / 플러시 확정 발동 재현용',
    builder: _buildS8ColorJesterStackPreview,
  ),
  for (final entry
      in DebugRunFixtureService.fateLineTransformPreviewItemsByFixture.entries)
    DebugRunFixtureDefinition(
      id: entry.key,
      label: '운명 변환 전투: ${entry.value}',
      description: '${entry.value} Q1 보유 / row 2 선택 변환 눈검증용',
      builder: () => _buildFateLineTransformBattlePreview(
        fixtureId: entry.key,
        itemId: entry.value,
      ),
    ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.finalBossCashOutReady,
    label: '최종 Boss 런 완료 체크',
    description: 'S8 Boss 확정 1회로 런 완료 + 기억 카드 보상 시트 검증용',
    builder: _buildFinalBossCashOutReady,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.bossRowConstraintPreview,
    label: 'Boss 가로줄 제약',
    description: '가로줄 약화 보스전 / 확정 가능한 가로줄 표시 검증용',
    builder: _buildBossRowConstraintPreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.bossColumnConstraintPreview,
    label: 'Boss 세로줄 제약',
    description: '세로줄 약화 보스전 / 확정 가능한 세로줄 표시 검증용',
    builder: _buildBossColumnConstraintPreview,
  ),
  DebugRunFixtureDefinition(
    id: DebugRunFixtureService.bossDiagonalConstraintPreview,
    label: 'Boss 대각선 제약',
    description: '대각선 약화 보스전 / 확정 가능한 대각선 표시 검증용',
    builder: _buildBossDiagonalConstraintPreview,
  ),
];
