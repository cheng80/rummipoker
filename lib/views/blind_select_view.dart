import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/blind_selection_setup.dart';
import '../services/new_run_setup.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'home_entry_widgets.dart';

class BlindSelectView extends StatefulWidget {
  const BlindSelectView({
    super.key,
    required this.runSeed,
    required this.difficulty,
    this.restoredRun,
  });

  final int runSeed;
  final NewRunDifficulty difficulty;
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
    _options = BlindSelectionSetup.buildForStation(
      stationIndex: _stationIndex,
      clearedBlindTierIndex: _clearedBlindTierIndex,
      difficulty: _effectiveDifficulty,
      ruleset: _effectiveRuleset,
    );
    _loadItemCatalog();
  }

  Future<void> _loadItemCatalog() async {
    try {
      final catalog = await ItemCatalog.loadFromAsset(AssetPaths.itemsCommon);
      if (!mounted) return;
      setState(() => _itemCatalog = catalog);
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemCatalog = null);
    }
  }

  NewRunDifficulty get _effectiveDifficulty =>
      widget.restoredRun?.difficulty ?? widget.difficulty;

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
    if (widget.restoredRun == null) {
      return '난이도 ${NewRunSetup(difficulty: _effectiveDifficulty).difficultyLabel}';
    }
    return '다음 전투를 선택하세요.';
  }

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
        '&blind_tier=${selected.tier.name}',
        extra: nextRuntime,
      );
      return;
    }
    context.go(
      '${RoutePaths.game}?seed=${widget.runSeed}'
      '&difficulty=${_effectiveDifficulty.name}'
      '&blind_tier=${selected.tier.name}',
    );
  }

  void _goBack() {
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
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '블라인드 선택',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            HomeSection(
              title: 'Station $_stationIndex',
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
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
                    ruleText: spec.bossModifier!.ruleText,
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
    required this.ruleText,
    required this.enabled,
  });

  final String title;
  final String ruleText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFFFFB4A8)
        : const Color(0xFFFFB4A8).withValues(alpha: 0.62);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5A2B30).withValues(alpha: enabled ? 0.56 : 0.28),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.54), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '$title · $ruleText',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
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
        ? const Color(0xFFF4A81D)
        : Colors.black.withValues(alpha: 0.14);
    final iconColor = enabled
        ? const Color(0xFF173126)
        : status.stateColor.withValues(alpha: 0.68);
    return Material(
      color: Colors.transparent,
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
                  ? const Color(0xFFFFF0B0)
                  : status.stateColor.withValues(alpha: 0.45),
              width: enabled ? 2 : 1.4,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFF4A81D).withValues(alpha: 0.34),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
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
              color: Colors.white.withValues(alpha: 0.54),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
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
      fillColor: Color(0x1629B36A),
      borderColor: Color(0x8A6CCB8C),
      badgeColor: Color(0xFF2E7D4B),
      badgeTextColor: Colors.white,
      stateColor: Color(0xFF8EE0AB),
      badgeLabel: 'CLEAR',
      trailingIcon: Icons.check_circle_rounded,
    );
  }
  if (spec.isLocked) {
    return const _BlindStatusStyle(
      fillColor: Color(0x10A57A1E),
      borderColor: Color(0x72C8A24B),
      badgeColor: Color(0x7A6B5A32),
      badgeTextColor: Color(0xFFF5DA96),
      stateColor: Color(0xFFF0C96A),
      badgeLabel: 'LOCKED',
      trailingIcon: Icons.lock_rounded,
    );
  }
  return const _BlindStatusStyle(
    fillColor: Color(0x1840BDE8),
    borderColor: Color(0xFF4FC3F7),
    badgeColor: Color(0xFF275B49),
    badgeTextColor: Colors.white,
    stateColor: Color(0xFF82D9FF),
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
