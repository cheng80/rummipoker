import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/item_catalog_loader.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/blind_selection_setup.dart';
import '../services/game_analytics_service.dart';
import '../services/new_run_setup.dart';
import '../utils/common_ui.dart';
import '../widgets/phone_frame_scaffold.dart';
import '../widgets/fx/entrance_in.dart';
import '../widgets/fx/fx_ambient.dart';
import '../widgets/fx/motion_policy.dart';
import 'game/game_feedback_cues.dart';
import 'game/game_presentation_timings.dart';
import 'game/widgets/game_ui_palette.dart';
import 'home_entry_widgets.dart';

class BlindSelectView extends StatefulWidget {
  const BlindSelectView({
    super.key,
    required this.runSeed,
    required this.difficulty,
    this.runModifier = NewRunModifier.basic,
    this.restoredRun,
  });

  final int runSeed;
  final NewRunDifficulty difficulty;
  final NewRunModifier runModifier;
  final ActiveRunRuntimeState? restoredRun;

  @override
  State<BlindSelectView> createState() => _BlindSelectViewState();
}

class _BlindSelectViewState extends State<BlindSelectView>
    with SingleTickerProviderStateMixin {
  late final List<BlindSelectionSpec> _options;
  ItemCatalog? _itemCatalog;

  // --- T4: 진입 연출. 한 컨트롤러의 구간으로 카드 등장, 진행 띠 전진, 배지 전환을 맞춘다.
  late final AnimationController _intro;
  late final bool _introStatic;
  bool _badgesSwapped = false;
  BlindTier? _committingTier;

  static const double _badgeSwapAt = 0.72;

  Duration get _introDuration =>
      GamePresentationTimings.flowEntranceStagger * 3 +
      GamePresentationTimings.runProgressAdvance;

  @override
  void initState() {
    super.initState();
    FxAmbient.setMoodAfterFrame(FxAmbientMood.menu);
    _introStatic = MotionPolicy.juiceScale <= 0;
    _intro = AnimationController(vsync: this, duration: _introDuration);
    if (_introStatic) {
      _intro.value = 1;
      _badgesSwapped = true;
    } else {
      _intro.addListener(_onIntroTick);
      _intro.forward();
    }
    SoundManager.playBgm(AssetPaths.bgmMenu);
    _options = BlindSelectionSetup.buildForStation(
      stationIndex: _stationIndex,
      clearedBlindTierIndex: _clearedBlindTierIndex,
      difficulty: _effectiveDifficulty,
      runModifier: _effectiveRunModifier,
      runSeed: _effectiveRunSeed,
      ruleset: _effectiveRuleset,
      bossModifierOverride: widget.restoredRun?.blindSelectBossModifier,
    );
    _loadItemCatalog();
  }

  void _onIntroTick() {
    if (_badgesSwapped || _intro.value < _badgeSwapAt) return;
    setState(() => _badgesSwapped = true);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// 방금 넘어온 상태 변화를 보여 줄 때 쓰는 이전 가용 상태. 변화가 없으면 null.
  ///
  /// 이어하기 Blind Select에서 방금 깬 tier는 OPEN→CLEAR, 새로 열린 tier는
  /// LOCKED→OPEN으로 짧게 바뀐다. 저장 필드를 더하지 않고 현재 run 상태만 읽는다.
  BlindSelectionAvailability? _previousAvailability(BlindSelectionSpec spec) {
    if (widget.restoredRun == null || _badgesSwapped) return null;
    final cleared = _clearedBlindTierIndex;
    if (cleared < 0) return null;
    if (spec.tier.index == cleared && spec.isCleared) {
      return BlindSelectionAvailability.selectable;
    }
    if (spec.tier.index == cleared + 1 && spec.isSelectable) {
      return BlindSelectionAvailability.locked;
    }
    return null;
  }

  /// Market에서 돌아와 새 Station이 열렸다. 진행 띠의 현재 위치가 한 칸 나아간다.
  bool get _stationJustAdvanced =>
      widget.restoredRun != null &&
      _clearedBlindTierIndex < 0 &&
      _stationIndex > 1;

  Future<void> _loadItemCatalog() async {
    try {
      final catalog = await ItemCatalogLoader.loadFromAsset(
        AssetPaths.itemsCommon,
      );
      if (!mounted) return;
      setState(() => _itemCatalog = catalog);
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemCatalog = null);
    }
  }

  NewRunDifficulty get _effectiveDifficulty =>
      widget.restoredRun?.difficulty ?? widget.difficulty;

  NewRunModifier get _effectiveRunModifier =>
      widget.restoredRun?.runModifier ?? widget.runModifier;

  int get _effectiveRunSeed =>
      widget.restoredRun?.session.runSeed ?? widget.runSeed;

  RummiRuleset get _effectiveRuleset =>
      widget.restoredRun?.session.ruleset ?? RummiRuleset.currentDefaults;

  int get _stationIndex {
    final restoredRun = widget.restoredRun;
    if (restoredRun == null) return 1;
    return restoredRun.runProgress.stageIndex;
  }

  int get _clearedBlindTierIndex =>
      widget.restoredRun?.runProgress.currentStationBlindTierIndex ?? -1;

  String get _stationSubtitle {
    final difficultyLabel = NewRunSetup(
      difficulty: _effectiveDifficulty,
    ).difficultyLabel;
    final modeLabel = BlindSelectionSetup.isEndlessStation(_stationIndex)
        ? '무한 도전'
        : '난이도 $difficultyLabel';
    if (widget.restoredRun == null) {
      return modeLabel;
    }
    if (BlindSelectionSetup.isEndlessStation(_stationIndex)) {
      return '$modeLabel · 난이도 $difficultyLabel · 점수가 계속 상승합니다.';
    }
    return '$modeLabel · 다음 전투를 선택하세요.';
  }

  String get _stationTitle =>
      BlindSelectionSetup.isEndlessStation(_stationIndex)
      ? '무한 도전 S$_stationIndex'
      : 'Station $_stationIndex';

  Future<void> _startBlind(BlindSelectionSpec selected) async {
    if (!selected.isSelectable || _committingTier != null) return;
    SoundManager.unlockForWeb();
    GameFeedback.play(GameCue.battleStart);
    SoundManager.playBgmFromUserGesture(AssetPaths.bgmMain);
    if (!mounted) return;
    // 고른 카드가 커지고 나머지가 물러난 뒤 넘어간다. 꾸밈이라 짧게만 기다린다.
    if (!_introStatic) {
      setState(() => _committingTier = selected.tier);
      await Future<void>.delayed(GamePresentationTimings.blindPlayCommit);
      if (!mounted) return;
    }
    _logStationSelect(selected);
    final restoredRun = widget.restoredRun;
    if (restoredRun != null) {
      final nextRuntime =
          BlindSelectionSetup.prepareContinuedRunForSelectedBlind(
            runtime: restoredRun,
            tier: selected.tier,
            itemCatalog: _itemCatalog,
          );
      context.go(
        '${RoutePaths.game}?difficulty=${_effectiveDifficulty.name}'
        '&modifier=${_effectiveRunModifier.id}'
        '&blind_tier=${selected.tier.name}',
        extra: nextRuntime,
      );
      return;
    }
    context.go(
      '${RoutePaths.game}?seed=${widget.runSeed}'
      '&difficulty=${_effectiveDifficulty.name}'
      '&modifier=${_effectiveRunModifier.id}'
      '&blind_tier=${selected.tier.name}',
    );
  }

  void _logStationSelect(BlindSelectionSpec selected) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'station_select',
        parameters: {
          'seed_mode': widget.restoredRun == null ? 'new' : 'restored',
          'seed_bucket': _effectiveRunSeed.abs() % 100,
          'difficulty': _effectiveDifficulty.name,
          'modifier': _effectiveRunModifier.id,
          'station_index': _stationIndex,
          'blind_tier': selected.tier.name,
          'target_score': selected.targetScore,
          'board_discards': selected.boardDiscards,
          'hand_discards': selected.handDiscards,
          'max_hand_size': selected.maxHandSize,
          'is_endless': selected.isEndless,
        },
      ),
    );
  }

  void _goBack() {
    SoundManager.playBgm(AssetPaths.bgmMenu);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(
      widget.restoredRun == null ? RoutePaths.newRun : RoutePaths.title,
    );
  }

  double _intervalStart(Duration at) =>
      (at.inMicroseconds / _introDuration.inMicroseconds).clamp(0.0, 1.0);

  /// blind 카드 [index]의 등장 구간(80ms 간격).
  Animation<double> _cardEntrance(int index) {
    final start = GamePresentationTimings.flowEntranceStagger * index;
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(
        _intervalStart(start),
        _intervalStart(start + GamePresentationTimings.flowEntranceIn),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrameScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: GameUiPalette.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Station Select',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 14),
            _RunProgressBand(
              stationIndex: _stationIndex,
              advanced: _stationJustAdvanced,
              animation: CurvedAnimation(
                parent: _intro,
                curve: Interval(
                  _intervalStart(GamePresentationTimings.flowEntranceStagger),
                  1,
                  curve: Curves.easeInOutCubic,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (BlindSelectionSetup.isEndlessStation(_stationIndex)) ...[
              EntranceIn(
                duration: GamePresentationTimings.flowEntranceIn,
                scaleFrom: 0.92,
                offset: const Offset(0, -0.2),
                curve: Curves.easeOutBack,
                child: const _EndlessWarningBanner(),
              ),
              const SizedBox(height: 12),
            ],
            if (_effectiveRunModifier != NewRunModifier.basic) ...[
              EntranceIn(
                delay: GamePresentationTimings.flowEntranceStagger,
                duration: GamePresentationTimings.flowEntranceIn,
                scaleFrom: 0.92,
                curve: Curves.easeOutBack,
                child: _HighStakesChip(modifier: _effectiveRunModifier),
              ),
              const SizedBox(height: 12),
            ],
            HomeSection(
              title: _stationTitle,
              subtitle: _stationSubtitle,
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    _BlindCardMotion(
                      key: ValueKey('blind-card-${_options[i].tier.name}'),
                      entrance: _cardEntrance(i),
                      committing: _committingTier,
                      tier: _options[i].tier,
                      child: _BlindOptionCard(
                        spec: _options[i],
                        displayAvailability: _previousAvailability(_options[i]),
                        onTap: _options[i].isSelectable
                            ? () => _startBlind(_options[i])
                            : null,
                      ),
                    ),
                    if (i != _options.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndlessWarningBanner extends StatelessWidget {
  const _EndlessWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceEndless,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameUiPalette.specialDanger, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.specialDangerHard.withValues(alpha: 0.26),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.34),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GameUiPalette.specialDanger,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GameUiPalette.specialEndlessTextMuted,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: GameUiPalette.specialDangerDeepText,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '무한 도전',
                  style: TextStyle(
                    color: GameUiPalette.specialEndlessTextMuted,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '목표 점수가 계속 상승합니다. 여기부터는 기록 경쟁 구간입니다.',
                  softWrap: true,
                  style: TextStyle(
                    color: GameUiPalette.specialEndlessText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlindOptionCard extends StatelessWidget {
  const _BlindOptionCard({
    required this.spec,
    required this.onTap,
    this.displayAvailability,
  });

  final BlindSelectionSpec spec;
  final VoidCallback? onTap;

  /// 진입 직후 잠깐 보여 줄 이전 상태. 배지만 이 값으로 그린다.
  final BlindSelectionAvailability? displayAvailability;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyleFor(spec);
    final badgeStatus = displayAvailability == null
        ? status
        : _statusStyleFor(spec, availability: displayAvailability);
    final isInteractive = spec.isSelectable && onTap != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: status.fillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status.borderColor,
          width: isInteractive ? 1.6 : 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _BlindStatusBadge(status: badgeStatus),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spec.title,
                        style: TextStyle(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: isInteractive ? 0.95 : 0.78,
                          ),
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontSize: 19,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _BlindMetric(label: '목표', value: '${spec.targetScore}'),
                    _BlindMetric(label: '보상', value: '+${spec.rewardPreview}'),
                    _BlindMetric(label: '손패', value: '${spec.maxHandSize}'),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _conditionSummary(spec),
                  maxLines: 2,
                  style: TextStyle(
                    color: status.stateColor.withValues(
                      alpha: isInteractive ? 0.92 : 0.74,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (spec.bossModifier != null) ...[
                  const SizedBox(height: 7),
                  _BlindConstraintChip(
                    title: spec.bossModifier!.title,
                    markerText: spec.bossModifier!.markerText,
                    enabled: isInteractive,
                    pulse: isInteractive,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BlindPlayButton(
            status: status,
            enabled: isInteractive,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _BlindConstraintChip extends StatefulWidget {
  const _BlindConstraintChip({
    required this.title,
    required this.markerText,
    required this.enabled,
    this.pulse = false,
  });

  final String title;
  final String markerText;
  final bool enabled;

  /// 등장할 때 위험 표시가 몇 번 맥동하고 멈춘다.
  final bool pulse;

  @override
  State<_BlindConstraintChip> createState() => _BlindConstraintChipState();
}

class _BlindConstraintChipState extends State<_BlindConstraintChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: GamePresentationTimings.blindDangerPulse,
    );
    if (widget.pulse && MotionPolicy.juiceScale > 0) {
      // 무한 반복하지 않는다. 정해진 횟수만큼 돌고 0에서 멈춘다.
      _pulse.repeat(
        reverse: true,
        count: GamePresentationTimings.blindDangerPulseCycles * 2,
      );
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 1 + 0.035 * t,
          child: _chip(glow: t),
        );
      },
    );
  }

  Widget _chip({required double glow}) {
    final enabled = widget.enabled;
    final title = widget.title;
    final markerText = widget.markerText;
    final color = enabled
        ? GameUiPalette.specialDangerSoft
        : GameUiPalette.specialDangerSoft.withValues(alpha: 0.62);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: GameUiPalette.specialDangerMutedSurface.withValues(
          alpha: enabled ? 0.56 : 0.28,
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Color.lerp(
            color.withValues(alpha: 0.54),
            GameUiPalette.bossWeakenPreview,
            glow,
          )!,
          width: 1 + glow,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: enabled ? 0.88 : 0.48),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              markerText,
              maxLines: 1,
              style: const TextStyle(
                color: GameUiPalette.textOnWarm,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              title,
              softWrap: true,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlindPlayButton extends StatelessWidget {
  const _BlindPlayButton({
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  final _BlindStatusStyle status;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final buttonColor = enabled
        ? GameUiPalette.actionGold
        : GameUiPalette.ink.withValues(alpha: 0.14);
    final iconColor = enabled
        ? GameUiPalette.surfacePanel
        : status.stateColor.withValues(alpha: 0.68);
    // 잠김·완료 상태의 탭은 거절 흔들림·오류음만 내고 상태는 바꾸지 않는다.
    return PressFeedback(
      onTap: enabled ? onTap : null,
      deny: true,
      decision: true,
      haptic: null,
      builder: (context, onTap) => Material(
        color: GameUiPalette.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              border: Border.all(
                color: enabled
                    ? GameUiPalette.actionOrangePale
                    : status.stateColor.withValues(alpha: 0.45),
                width: enabled ? 2 : 1.4,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: GameUiPalette.actionGold.withValues(alpha: 0.34),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: GameUiPalette.ink.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(status.trailingIcon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}

class _BlindMetric extends StatelessWidget {
  const _BlindMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.54),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.92),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _conditionSummary(BlindSelectionSpec spec) {
  if (spec.isCleared) return '클리어 완료';
  if (spec.isLocked) return spec.lockReason ?? '아직 선택할 수 없습니다';
  return '보드 버림 ${spec.boardDiscards} · 손패 버림 ${spec.handDiscards}';
}

_BlindStatusStyle _statusStyleFor(
  BlindSelectionSpec spec, {
  BlindSelectionAvailability? availability,
}) {
  final shown = availability ?? spec.availability;
  if (shown == BlindSelectionAvailability.cleared) {
    return const _BlindStatusStyle(
      fillColor: GameUiPalette.blindBasicFill,
      borderColor: GameUiPalette.blindBasicBorder,
      badgeColor: GameUiPalette.blindBasicBadge,
      badgeTextColor: GameUiPalette.textPrimary,
      stateColor: GameUiPalette.blindBasicState,
      badgeLabel: 'CLEAR',
      trailingIcon: Icons.check_circle_rounded,
    );
  }
  if (shown == BlindSelectionAvailability.locked) {
    return const _BlindStatusStyle(
      fillColor: GameUiPalette.blindChallengeFill,
      borderColor: GameUiPalette.blindChallengeBorder,
      badgeColor: GameUiPalette.blindChallengeBadge,
      badgeTextColor: GameUiPalette.blindChallengeText,
      stateColor: GameUiPalette.blindChallengeState,
      badgeLabel: 'LOCKED',
      trailingIcon: Icons.lock_rounded,
    );
  }
  if (spec.isEndless) {
    return const _BlindStatusStyle(
      fillColor: GameUiPalette.blindEndlessFill,
      borderColor: GameUiPalette.specialDanger,
      badgeColor: GameUiPalette.blindEndlessBadge,
      badgeTextColor: GameUiPalette.specialEndlessText,
      stateColor: GameUiPalette.specialGold,
      badgeLabel: 'DANGER',
      trailingIcon: Icons.local_fire_department_rounded,
    );
  }
  return const _BlindStatusStyle(
    fillColor: GameUiPalette.blindCustomFill,
    borderColor: GameUiPalette.blindCustomBorder,
    badgeColor: GameUiPalette.blindCustomBadge,
    badgeTextColor: GameUiPalette.textPrimary,
    stateColor: GameUiPalette.blindCustomState,
    badgeLabel: 'OPEN',
    trailingIcon: Icons.play_arrow_rounded,
  );
}

class _BlindStatusStyle {
  const _BlindStatusStyle({
    required this.fillColor,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.stateColor,
    required this.badgeLabel,
    required this.trailingIcon,
  });

  final Color fillColor;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color stateColor;
  final String badgeLabel;
  final IconData trailingIcon;
}

/// 상태 배지. 값이 바뀌면 짧게 눌렸다 커지며 바뀐다.
class _BlindStatusBadge extends StatelessWidget {
  const _BlindStatusBadge({required this.status});

  final _BlindStatusStyle status;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionPolicy.juiceScale <= 0
          ? Duration.zero
          : GamePresentationTimings.blindBadgeSwap,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey('blind-badge-${status.badgeLabel}'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: status.badgeColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.badgeLabel,
          style: TextStyle(
            color: status.badgeTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// blind 카드의 등장과 play 뒤 선택 강조. 움직임은 Transform과 FadeTransition만 쓴다.
///
/// [committing]이 정해지면 고른 카드는 커지고 나머지는 작아지며 물러난다.
class _BlindCardMotion extends StatelessWidget {
  const _BlindCardMotion({
    super.key,
    required this.entrance,
    required this.committing,
    required this.tier,
    required this.child,
  });

  final Animation<double> entrance;
  final BlindTier? committing;
  final BlindTier tier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chosen = committing == tier;
    final receding = committing != null && !chosen;
    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(entrance),
        child: AnimatedSlide(
          offset: receding ? const Offset(0.06, 0.05) : Offset.zero,
          duration: GamePresentationTimings.blindPlayCommit,
          curve: Curves.easeInCubic,
          child: AnimatedScale(
            scale: chosen
                ? 1.04
                : receding
                ? 0.92
                : 1,
            duration: GamePresentationTimings.blindPlayCommit,
            curve: chosen ? Curves.easeOutBack : Curves.easeInCubic,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 하이 스테이크 런 표시. 배율은 modifier 값을 그대로 보여 준다.
class _HighStakesChip extends StatelessWidget {
  const _HighStakesChip({required this.modifier});

  final NewRunModifier modifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('blind-high-stakes-chip'),
      width: 332,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameUiPalette.actionGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.actionGoldBright.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up_rounded,
            size: 18,
            color: GameUiPalette.actionGoldBright,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'flowHighStakesChip'.tr(
                args: [
                  '${modifier.targetScoreMultiplier}',
                  '${modifier.rewardMultiplier}',
                ],
              ),
              softWrap: true,
              style: const TextStyle(
                color: GameUiPalette.actionGoldBright,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 런 진행 띠. S1부터 마지막 Station까지 지난 곳, 현재, 마지막 Boss를 구분한다.
///
/// [advanced]면 현재 표시가 이전 칸에서 한 칸 나아간다. 무한 구간(S9+)은 모든
/// 칸을 완료로 두고 끝에 무한 표시를 붙인다. run 상태만 읽는다.
class _RunProgressBand extends StatelessWidget {
  const _RunProgressBand({
    required this.stationIndex,
    required this.advanced,
    required this.animation,
  });

  final int stationIndex;
  final bool advanced;
  final Animation<double> animation;

  static const int _finalStation =
      BlindSelectionSpecBuilder.finalCoreStationIndex;
  static const double _dot = 22;

  @override
  Widget build(BuildContext context) {
    final endless = BlindSelectionSetup.isEndlessStation(stationIndex);
    final current = endless ? null : stationIndex.clamp(1, _finalStation);
    return Semantics(
      label: endless
          ? 'flowRunProgressEndless'.tr(args: ['$stationIndex'])
          : 'flowRunProgressLabel'.tr(args: ['$current', '$_finalStation']),
      child: ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey('run-progress-band'),
          width: 332,
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final step = constraints.maxWidth / _finalStation;
                    double centerOf(int station) => step * (station - 0.5);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: centerOf(1),
                          right: step / 2,
                          top: _dot / 2 - 1,
                          height: 2,
                          child: ColoredBox(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        for (var s = 1; s <= _finalStation; s++)
                          Positioned(
                            left: centerOf(s) - _dot / 2,
                            top: 0,
                            width: _dot,
                            child: _StationDot(
                              key: ValueKey('run-progress-s$s'),
                              station: s,
                              done: endless || (current != null && s < current),
                              current: s == current,
                              finalBoss: s == _finalStation,
                            ),
                          ),
                        if (current != null)
                          AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final from = advanced && current > 1
                                  ? centerOf(current - 1)
                                  : centerOf(current);
                              final x =
                                  from +
                                  (centerOf(current) - from) * animation.value;
                              return Positioned(
                                key: const ValueKey('run-progress-marker'),
                                left: x - (_dot + 8) / 2,
                                top: -4,
                                width: _dot + 8,
                                height: _dot + 8,
                                child: const IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: GameUiPalette.actionGoldBright,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (endless) ...[
                const SizedBox(width: 8),
                Container(
                  key: const ValueKey('run-progress-endless'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GameUiPalette.surfaceEndless,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: GameUiPalette.specialDanger),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.all_inclusive_rounded,
                        size: 14,
                        color: GameUiPalette.specialEndlessTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'S$stationIndex',
                        style: const TextStyle(
                          color: GameUiPalette.specialEndlessText,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StationDot extends StatelessWidget {
  const _StationDot({
    super.key,
    required this.station,
    required this.done,
    required this.current,
    required this.finalBoss,
  });

  final int station;
  final bool done;
  final bool current;
  final bool finalBoss;

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? GameUiPalette.actionGold
        : current
        ? GameUiPalette.actionGoldBright.withValues(alpha: 0.28)
        : GameUiPalette.surfacePanel;
    final border = finalBoss
        ? GameUiPalette.bossWeakenPreview
        : done || current
        ? GameUiPalette.actionGoldBright
        : GameUiPalette.textPrimary.withValues(alpha: 0.28);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: finalBoss ? 2 : 1.4),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: GameUiPalette.surfacePanel,
                )
              : finalBoss
              ? const Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: GameUiPalette.bossWeakenPreview,
                )
              : null,
        ),
        const SizedBox(height: 2),
        Text(
          'S$station',
          maxLines: 1,
          style: TextStyle(
            color: current
                ? GameUiPalette.actionGoldBright
                : GameUiPalette.textPrimary.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: current ? FontWeight.w900 : FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
