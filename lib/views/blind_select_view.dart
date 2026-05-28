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
import '../services/new_run_setup.dart';
import '../widgets/phone_frame_scaffold.dart';
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

class _BlindSelectViewState extends State<BlindSelectView> {
  late final List<BlindSelectionSpec> _options;
  ItemCatalog? _itemCatalog;

  @override
  void initState() {
    super.initState();
    SoundManager.playBgm(AssetPaths.bgmMenu);
    _options = BlindSelectionSetup.buildForStation(
      stationIndex: _stationIndex,
      clearedBlindTierIndex: _clearedBlindTierIndex,
      difficulty: _effectiveDifficulty,
      runModifier: _effectiveRunModifier,
      runSeed: _effectiveRunSeed,
      ruleset: _effectiveRuleset,
    );
    _loadItemCatalog();
  }

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
    if (!selected.isSelectable) return;
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    if (!mounted) return;
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
            const SizedBox(height: 18),
            if (BlindSelectionSetup.isEndlessStation(_stationIndex)) ...[
              const _EndlessWarningBanner(),
              const SizedBox(height: 12),
            ],
            HomeSection(
              title: _stationTitle,
              subtitle: _stationSubtitle,
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    _BlindOptionCard(
                      spec: _options[i],
                      onTap: _options[i].isSelectable
                          ? () => _startBlind(_options[i])
                          : null,
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
  const _BlindOptionCard({required this.spec, required this.onTap});

  final BlindSelectionSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyleFor(spec);
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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

class _BlindConstraintChip extends StatelessWidget {
  const _BlindConstraintChip({
    required this.title,
    required this.markerText,
    required this.enabled,
  });

  final String title;
  final String markerText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: color.withValues(alpha: 0.54), width: 1),
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
    return Material(
      color: GameUiPalette.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
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

_BlindStatusStyle _statusStyleFor(BlindSelectionSpec spec) {
  if (spec.isCleared) {
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
  if (spec.isLocked) {
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
