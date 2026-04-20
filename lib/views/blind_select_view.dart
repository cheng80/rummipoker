import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/blind_selection_setup.dart';
import '../services/new_run_setup.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'home_entry_widgets.dart';

class BlindSelectView extends StatefulWidget {
  const BlindSelectView({
    super.key,
    required this.runSeed,
    required this.difficulty,
  });

  final int runSeed;
  final NewRunDifficulty difficulty;

  @override
  State<BlindSelectView> createState() => _BlindSelectViewState();
}

class _BlindSelectViewState extends State<BlindSelectView> {
  late final List<BlindSelectionSpec> _options;
  BlindTier _selectedTier = BlindTier.small;

  @override
  void initState() {
    super.initState();
    _options = BlindSelectionSetup.buildStageOne(
      difficulty: widget.difficulty,
      ruleset: RummiRuleset.currentDefaults,
    );
  }

  BlindSelectionSpec get _selectedSpec => _options.firstWhere(
    (option) => option.tier == _selectedTier,
    orElse: () => _options.first,
  );

  Future<void> _startSelectedBlind() async {
    final selected = _selectedSpec;
    if (!selected.isUnlocked) return;
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    if (!mounted) return;
    context.go(
      '${RoutePaths.game}?seed=${widget.runSeed}'
      '&difficulty=${widget.difficulty.name}'
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
              title: 'Station 1',
              subtitle: '현재는 새 게임 시작 시 진입하는 첫 블라인드 선택 화면입니다.',
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    _BlindOptionCard(
                      spec: _options[i],
                      selected: _selectedTier == _options[i].tier,
                      onTap: _options[i].isUnlocked
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
                  '난이도: ${NewRunSetup(difficulty: widget.difficulty).difficultyLabel}\n'
                  '블라인드: ${_selectedSpec.title}\n'
                  '목표: ${_selectedSpec.targetScore} · 손패 ${_selectedSpec.maxHandSize} · 보드 버림 ${_selectedSpec.boardDiscards} · 손패 버림 ${_selectedSpec.handDiscards}',
            ),
            const SizedBox(height: 16),
            HomeEntryCard(
              title: '이 블라인드 시작',
              description: _selectedSpec.isUnlocked
                  ? '${_selectedSpec.title}으로 전투에 들어갑니다.'
                  : _selectedSpec.lockReason ?? '아직 선택할 수 없습니다.',
              accent: const Color(0xFF3CAEE0),
              enabled: _selectedSpec.isUnlocked,
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
    final borderColor = selected
        ? const Color(0xFF4FC3F7)
        : spec.isUnlocked
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFFFD166).withValues(alpha: 0.46);
    final fillColor = selected
        ? const Color(0xFF4FC3F7).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.04);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
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
                    color: spec.isUnlocked
                        ? const Color(0xFF1D85C7).withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    spec.badgeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  !spec.isUnlocked
                      ? Icons.lock_rounded
                      : selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: !spec.isUnlocked
                      ? const Color(0xFFFFD166)
                      : selected
                      ? const Color(0xFF4FC3F7)
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              spec.title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontFamily: AssetPaths.fontAngduIpsul140,
                fontSize: 22,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
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
            if (spec.lockReason != null) ...[
              const SizedBox(height: 10),
              Text(
                spec.lockReason!,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
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
