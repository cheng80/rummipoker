import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
    });
  }

  void _applyDebugScrollPreset() {
    if (!kDebugMode || widget.debugScrollPreset != 'bottom') return;
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
    return '${RoutePaths.blindSelect}?seed=$seed'
        '&difficulty=${difficulty.name}';
  }

  List<NewRunDifficulty> get _availableDifficulties {
    return NewRunDifficulty.values
        .where(_unlockState.isDifficultyUnlocked)
        .toList(growable: false);
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
