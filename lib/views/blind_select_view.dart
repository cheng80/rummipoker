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
import '../utils/common_ui.dart';
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
  late BlindTier _selectedTier;
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
    _selectedTier = _options
        .firstWhere(
          (option) => option.isSelectable,
          orElse: () => _options.first,
        )
        .tier;
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
      return '새 게임 시작 직후 첫 블라인드를 고르는 화면입니다.';
    }
    return '이전 Station 클리어 이후 다음 블라인드를 고르는 화면입니다.';
  }

  BlindSelectionSpec get _selectedSpec => _options.firstWhere(
    (option) => option.tier == _selectedTier,
    orElse: () => _options.first,
  );

  Future<bool> _confirmStartSelectedBlind() async {
    final selected = _selectedSpec;
    return showConfirmDialog(
      context,
      title: '${selected.title} 시작',
      message:
          'Station $_stationIndex의 ${selected.title}에 진입합니다.\n'
          '목표 ${selected.targetScore} · 손패 ${selected.maxHandSize} · 보드 버림 ${selected.boardDiscards} · 손패 버림 ${selected.handDiscards}',
      cancelLabel: '취소',
      confirmLabel: '시작',
    );
  }

  Future<void> _startSelectedBlind() async {
    final selected = _selectedSpec;
    if (!selected.isSelectable) return;
    final confirmed = await _confirmStartSelectedBlind();
    if (!mounted || !confirmed) return;
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
                  onPressed: () => context.pop(),
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
                fontFamily: AssetPaths.fontAngduIpsul140,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '이번 Station의 목표와 압박 조건을 먼저 고릅니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            HomeSection(
              title: 'Station $_stationIndex',
              subtitle: _stationSubtitle,
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    _BlindOptionCard(
                      spec: _options[i],
                      selected: _selectedTier == _options[i].tier,
                      onTap: _options[i].isSelectable
                          ? () => setState(() {
                              _selectedTier = _options[i].tier;
                            })
                          : null,
                    ),
                    if (i != _options.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            HomeSnapshotCard(
              title: '현재 선택',
              summary:
                  '상태: ${_availabilityLabel(_selectedSpec)}\n'
                  '난이도: ${NewRunSetup(difficulty: _effectiveDifficulty).difficultyLabel}\n'
                  '블라인드: ${_selectedSpec.title}\n'
                  '목표: ${_selectedSpec.targetScore} · 손패 ${_selectedSpec.maxHandSize} · 보드 버림 ${_selectedSpec.boardDiscards} · 손패 버림 ${_selectedSpec.handDiscards}',
            ),
            const SizedBox(height: 16),
            HomeEntryCard(
              title: '이 블라인드 시작',
              description: _selectedSpec.isSelectable
                  ? '${_selectedSpec.title}으로 전투에 들어갑니다.'
                  : _selectedSpec.isCleared
                  ? '${_selectedSpec.title}는 이미 클리어했습니다. 다음 블라인드를 선택하세요.'
                  : _selectedSpec.lockReason ?? '아직 선택할 수 없습니다.',
              accent: _selectedSpec.isSelectable
                  ? const Color(0xFFF4A81D)
                  : _selectedSpec.isCleared
                  ? const Color(0xFF557062)
                  : const Color(0xFF5B4D33),
              enabled: _selectedSpec.isSelectable,
              onTap: _startSelectedBlind,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlindOptionCard extends StatelessWidget {
  const _BlindOptionCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final BlindSelectionSpec spec;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyleFor(spec, selected: selected);
    final isInteractive = spec.isSelectable && onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: status.fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: status.borderColor,
            width: selected ? 1.8 : 1.2,
          ),
        ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: status.borderColor.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Text(
                    status.stateLabel,
                    style: TextStyle(
                      color: status.stateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(status.trailingIcon, color: status.stateColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              spec.title,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: isInteractive ? 0.95 : 0.84,
                ),
                fontFamily: AssetPaths.fontAngduIpsul140,
                fontSize: 22,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.description,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: isInteractive ? 0.72 : 0.62,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BlindStatChip(label: '목표 ${spec.targetScore}'),
                _BlindStatChip(label: '손패 ${spec.maxHandSize}'),
                _BlindStatChip(label: '보드 버림 ${spec.boardDiscards}'),
                _BlindStatChip(label: '손패 버림 ${spec.handDiscards}'),
                _BlindStatChip(label: '보상 +${spec.rewardPreview}'),
              ],
            ),
            if (spec.isCleared) ...[
              const SizedBox(height: 10),
              Text(
                '이 블라인드는 이미 클리어 완료 상태입니다. 다시 선택할 수는 없습니다.',
                style: TextStyle(
                  color: status.stateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ] else if (spec.lockReason != null) ...[
              const SizedBox(height: 10),
              Text(
                spec.lockReason!,
                style: TextStyle(
                  color: status.stateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ] else if (selected) ...[
              const SizedBox(height: 10),
              Text(
                '현재 선택된 블라인드입니다. 아래 버튼으로 바로 진입할 수 있습니다.',
                style: TextStyle(
                  color: status.stateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlindStatChip extends StatelessWidget {
  const _BlindStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.86),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _availabilityLabel(BlindSelectionSpec spec) {
  if (spec.isSelectable) return '선택 가능';
  if (spec.isCleared) return '클리어 완료';
  return '잠금';
}

_BlindStatusStyle _statusStyleFor(
  BlindSelectionSpec spec, {
  required bool selected,
}) {
  if (spec.isCleared) {
    return const _BlindStatusStyle(
      fillColor: Color(0x1629B36A),
      borderColor: Color(0x8A6CCB8C),
      badgeColor: Color(0xFF2E7D4B),
      badgeTextColor: Colors.white,
      stateColor: Color(0xFF8EE0AB),
      stateLabel: '클리어 완료',
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
      stateLabel: '잠금',
      badgeLabel: 'LOCKED',
      trailingIcon: Icons.lock_rounded,
    );
  }
  if (selected) {
    return const _BlindStatusStyle(
      fillColor: Color(0x1840BDE8),
      borderColor: Color(0xFF4FC3F7),
      badgeColor: Color(0xFF1D85C7),
      badgeTextColor: Colors.white,
      stateColor: Color(0xFF82D9FF),
      stateLabel: '현재 선택',
      badgeLabel: 'OPEN',
      trailingIcon: Icons.radio_button_checked_rounded,
    );
  }
  return const _BlindStatusStyle(
    fillColor: Color(0x08000000),
    borderColor: Color(0x20FFFFFF),
    badgeColor: Color(0xFF275B49),
    badgeTextColor: Colors.white,
    stateColor: Color(0xFFA9F3CE),
    stateLabel: '선택 가능',
    badgeLabel: 'OPEN',
    trailingIcon: Icons.circle_outlined,
  );
}

class _BlindStatusStyle {
  const _BlindStatusStyle({
    required this.fillColor,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.stateColor,
    required this.stateLabel,
    required this.badgeLabel,
    required this.trailingIcon,
  });

  final Color fillColor;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color stateColor;
  final String stateLabel;
  final String badgeLabel;
  final IconData trailingIcon;
}
