import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/new_run_setup.dart';
import '../services/run_unlock_state_service.dart';
import '../utils/common_ui.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'home_entry_widgets.dart';

class NewRunView extends StatefulWidget {
  const NewRunView({super.key, this.debugScrollPreset});

  final String? debugScrollPreset;

  @override
  State<NewRunView> createState() => _NewRunViewState();
}

class _NewRunViewState extends State<NewRunView> {
  final TextEditingController _seedInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RunUnlockState _unlockState = RunUnlockState.defaults();
  NewRunDifficulty _selectedDifficulty = NewRunDifficulty.standard;
  NewRunModifier _selectedRunModifier = NewRunModifier.basic;

  @override
  void initState() {
    super.initState();
    _applyDebugScrollPreset();
    _loadUnlockState();
  }

  Future<void> _loadUnlockState() async {
    final state = await RunUnlockStateService.load();
    if (!mounted) return;
    setState(() {
      _unlockState = state;
      if (!_unlockState.isDifficultyUnlocked(_selectedDifficulty)) {
        _selectedDifficulty = NewRunDifficulty.standard;
      }
      if (!_unlockState.isRunModifierUnlocked(_selectedRunModifier)) {
        _selectedRunModifier = NewRunModifier.basic;
      }
    });
  }

  void _applyDebugScrollPreset() {
    if (!AppConfig.showDebugFixtures || widget.debugScrollPreset != 'bottom') {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _seedInputController.dispose();
    super.dispose();
  }

  Future<void> _startRandomRun() async {
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    final seed = RummiPokerGridSession.rollNewRunSeed();
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(_buildStartRoute(seed: seed));
  }

  Future<void> _openSeedInputDialog() async {
    _seedInputController.clear();
    final action = await showGameChoiceDialog<String>(
      context,
      title: context.tr('seedDialogTitle'),
      content: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: TextField(
            controller: _seedInputController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: context.tr('seedHint'),
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.34),
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
            ),
            autofocus: true,
            onSubmitted: (_) => Navigator.of(context).pop('submit'),
          ),
        ),
      ),
      actions: [
        GameDialogAction<String>(
          label: context.tr('cancel'),
          value: 'cancel',
          accent: const Color(0xFF55615F),
        ),
        GameDialogAction<String>(
          label: context.tr('ok'),
          value: 'submit',
          accent: const Color(0xFF2DB872),
        ),
      ],
    );
    if (!mounted || action != 'submit') return;
    await _trySubmitSeed(context);
  }

  Future<void> _trySubmitSeed(BuildContext dialogContext) async {
    final value = int.tryParse(_seedInputController.text.trim());
    if (value == null) {
      showTopNotice(context, context.tr('seedInvalid'));
      return;
    }
    Navigator.of(dialogContext).pop();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    context.go(_buildStartRoute(seed: value));
  }

  String _buildStartRoute({required int seed}) {
    final difficulty = _unlockState.isDifficultyUnlocked(_selectedDifficulty)
        ? _selectedDifficulty
        : NewRunDifficulty.standard;
    final runModifier = _unlockState.isRunModifierUnlocked(_selectedRunModifier)
        ? _selectedRunModifier
        : NewRunModifier.basic;
    return '${RoutePaths.blindSelect}?seed=$seed'
        '&difficulty=${difficulty.name}'
        '&modifier=${runModifier.id}';
  }

  List<NewRunDifficulty> get _availableDifficulties {
    return NewRunDifficulty.values
        .where(NewRunSetup.isDifficultySelectable)
        .where(_unlockState.isDifficultyUnlocked)
        .toList(growable: false);
  }

  Future<void> _selectOrUnlockRunModifier(NewRunModifier modifier) async {
    if (_unlockState.isRunModifierUnlocked(modifier)) {
      setState(() => _selectedRunModifier = modifier);
      return;
    }
    final unlocked = await RunUnlockStateService.unlockRunModifier(modifier);
    final latest = await RunUnlockStateService.load();
    if (!mounted) return;
    setState(() {
      _unlockState = latest;
      if (unlocked) {
        _selectedRunModifier = modifier;
      }
    });
    showTopNotice(context, unlocked ? '${modifier.label} 해금' : '기억 카드가 부족합니다.');
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrameScaffold(
      child: SingleChildScrollView(
        controller: _scrollController,
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
              '새 게임 시작',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 22),
            if (_availableDifficulties.length > 1) ...[
              HomeSection(
                title: '난이도',
                subtitle: '이번 런의 시작 조건을 고릅니다.',
                child: _DifficultyPicker(
                  difficulties: _availableDifficulties,
                  selectedDifficulty: _selectedDifficulty,
                  onChanged: (difficulty) => setState(() {
                    _selectedDifficulty = difficulty;
                  }),
                ),
              ),
              const SizedBox(height: 18),
            ],
            HomeSection(
              title: '런 규칙',
              subtitle: _unlockState.insight > 0 ? '기억 카드 보유' : '기억 카드 없음',
              child: _RunModifierPicker(
                selectedRunModifier: _selectedRunModifier,
                unlockState: _unlockState,
                onSelect: _selectOrUnlockRunModifier,
              ),
            ),
            const SizedBox(height: 18),
            HomeSection(
              title: '시작 방식',
              subtitle: _availableDifficulties.length > 1
                  ? '선택한 난이도로 시작합니다.'
                  : '표준 난이도로 시작합니다.',
              child: Column(
                children: [
                  HomeEntryCard(
                    title: context.tr('entryRandomSeed'),
                    description: '무작위 시드로 바로 시작',
                    accent: const Color(0xFF3CAEE0),
                    onTap: _startRandomRun,
                  ),
                  const SizedBox(height: 12),
                  HomeEntryCard(
                    title: context.tr('entryInputSeed'),
                    description: '시드를 직접 입력해 시작',
                    accent: const Color(0xFF2DB872),
                    onTap: _openSeedInputDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunModifierPicker extends StatelessWidget {
  const _RunModifierPicker({
    required this.selectedRunModifier,
    required this.unlockState,
    required this.onSelect,
  });

  final NewRunModifier selectedRunModifier;
  final RunUnlockState unlockState;
  final ValueChanged<NewRunModifier> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        for (final modifier in NewRunModifier.values)
          _RunModifierCard(
            modifier: modifier,
            selected: modifier == selectedRunModifier,
            unlocked: unlockState.isRunModifierUnlocked(modifier),
            canUnlock: unlockState.insight >= modifier.unlockCostInsight,
            onTap: () => onSelect(modifier),
          ),
      ],
    );
  }
}

class _RunModifierCard extends StatelessWidget {
  const _RunModifierCard({
    required this.modifier,
    required this.selected,
    required this.unlocked,
    required this.canUnlock,
    required this.onTap,
  });

  final NewRunModifier modifier;
  final bool selected;
  final bool unlocked;
  final bool canUnlock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = modifier == NewRunModifier.highStakes
        ? const Color(0xFFFFB13B)
        : const Color(0xFF4FC3F7);
    final borderColor = selected
        ? accent
        : Colors.white.withValues(alpha: unlocked ? 0.12 : 0.07);
    final fillColor = selected
        ? accent.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: unlocked ? 0.05 : 0.025);
    final status = unlocked
        ? (selected ? '선택됨' : '선택 가능')
        : (canUnlock ? '기억 카드로 해금' : '기억 카드 필요');
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
          ),
          child: Row(
            children: [
              Icon(
                unlocked
                    ? (selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded)
                    : Icons.lock_rounded,
                color: unlocked || canUnlock
                    ? accent
                    : Colors.white.withValues(alpha: 0.42),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modifier.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modifierEffectText(modifier),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                status,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: (unlocked || canUnlock)
                      ? accent
                      : Colors.white.withValues(alpha: 0.46),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modifierEffectText(NewRunModifier modifier) {
    if (modifier == NewRunModifier.basic) {
      return '목표 점수 x1.00 · 보상 x1.00';
    }
    return '목표 점수 x${modifier.targetScoreMultiplier.toStringAsFixed(2)}'
        ' · 보상 x${modifier.rewardMultiplier.toStringAsFixed(2)}'
        '\n상점 후보 +1';
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
    required this.difficulties,
    required this.selectedDifficulty,
    required this.onChanged,
  });

  final List<NewRunDifficulty> difficulties;
  final NewRunDifficulty selectedDifficulty;
  final ValueChanged<NewRunDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < difficulties.length; i++) ...[
          Expanded(
            child: _DifficultyButton(
              difficulty: difficulties[i],
              selected: difficulties[i] == selectedDifficulty,
              onTap: () => onChanged(difficulties[i]),
            ),
          ),
          if (i != difficulties.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final NewRunDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final setup = NewRunSetup(difficulty: difficulty);
    final borderColor = selected
        ? const Color(0xFF4FC3F7)
        : Colors.white.withValues(alpha: 0.08);
    final fillColor = selected
        ? const Color(0xFF4FC3F7).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.04);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              setup.difficultyLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
