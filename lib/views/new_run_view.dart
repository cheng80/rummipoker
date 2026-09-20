import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../providers/features/rummi_poker_grid/game_session_notifier.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_service.dart';
import '../services/game_analytics_service.dart';
import '../services/new_run_setup.dart';
import '../services/run_unlock_state_service.dart';
import '../utils/common_ui.dart';
import '../widgets/phone_frame_scaffold.dart';
import '../widgets/fx/fx_ambient.dart';
import '../widgets/fx/fx_layer.dart';
import '../widgets/fx/juice.dart';
import 'game/game_feedback_cues.dart';
import 'game/game_presentation_timings.dart';
import 'game/widgets/game_ui_palette.dart';
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
  // 카드별 거절·해금 연출 트리거. 다른 카드의 값이 바뀌어도 이 카드는 튕기지 않는다.
  final Map<NewRunModifier, int> _modifierDenyTicks = {};
  final Map<NewRunModifier, int> _modifierUnlockTicks = {};

  @override
  void initState() {
    super.initState();
    SoundManager.playBgm(AssetPaths.bgmMenu);
    FxAmbient.setMoodAfterFrame(FxAmbientMood.menu);
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
    final seed = RummiPokerGridSession.rollNewRunSeed();
    final runtime = await _saveInitialRun(seed);
    if (!mounted || runtime == null) return;
    _logRunStart(seedMode: 'random', seed: seed);
    context.push(_buildStartRoute(seed: seed), extra: runtime);
  }

  Future<void> _openSeedInputDialog() async {
    _seedInputController.clear();
    final action = await showGameChoiceDialog<String>(
      context,
      title: context.tr('seedDialogTitle'),
      content: DecoratedBox(
        decoration: BoxDecoration(
          color: MenuSurface.panelFill(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MenuSurface.border(alpha: 0.34)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: TextField(
            controller: _seedInputController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            cursorColor: MenuSurface.goldBright,
            style: const TextStyle(
              color: GameUiPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: context.tr('seedHint'),
              hintStyle: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.34),
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
          accent: GameUiPalette.disabledControl,
        ),
        GameDialogAction<String>(
          label: context.tr('ok'),
          value: 'submit',
          accent: GameUiPalette.actionGold,
          textColor: GameUiPalette.textOnGold,
        ),
      ],
    );
    if (!mounted || action != 'submit') return;
    await _trySubmitSeed();
  }

  Future<void> _trySubmitSeed() async {
    final value = int.tryParse(_seedInputController.text.trim());
    if (value == null) {
      showTopNotice(context, context.tr('seedInvalid'));
      return;
    }
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    SoundManager.unlockForWeb();
    GameFeedback.play(GameCue.runStart);
    final runtime = await _saveInitialRun(value);
    if (!mounted || runtime == null) return;
    _logRunStart(seedMode: 'manual', seed: value);
    context.push(_buildStartRoute(seed: value), extra: runtime);
  }

  void _logRunStart({required String seedMode, required int seed}) {
    final difficulty = _unlockState.isDifficultyUnlocked(_selectedDifficulty)
        ? _selectedDifficulty
        : NewRunDifficulty.standard;
    final runModifier = _unlockState.isRunModifierUnlocked(_selectedRunModifier)
        ? _selectedRunModifier
        : NewRunModifier.basic;
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'run_start',
        parameters: {
          'seed_mode': seedMode,
          'seed_bucket': seed.abs() % 100,
          'difficulty': difficulty.name,
          'modifier': runModifier.id,
        },
      ),
    );
  }

  Future<ActiveRunRuntimeState?> _saveInitialRun(int seed) async {
    final difficulty = _unlockState.isDifficultyUnlocked(_selectedDifficulty)
        ? _selectedDifficulty
        : NewRunDifficulty.standard;
    final modifier = _unlockState.isRunModifierUnlocked(_selectedRunModifier)
        ? _selectedRunModifier
        : NewRunModifier.basic;
    final runtime = buildInitialRunRuntime(
      GameSessionArgs(
        runSeed: seed,
        difficulty: difficulty,
        runModifier: modifier,
        challengeCarryover: difficulty == NewRunDifficulty.challenge
            ? _unlockState.challengeCarryover
            : null,
      ),
    );
    try {
      await ActiveRunSaveService.saveRuntimeState(runtime);
      return runtime;
    } catch (_) {
      if (mounted) {
        showTopNotice(context, '저장에 실패했습니다. 다시 시도해 주세요.');
      }
      return null;
    }
  }

  void _goBack() {
    SoundManager.playBgm(AssetPaths.bgmMenu);
    context.pushReplacement(RoutePaths.title);
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
      GameFeedback.play(GameCue.choiceSelect);
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
        _modifierUnlockTicks.update(modifier, (v) => v + 1, ifAbsent: () => 1);
      } else {
        // 잠긴 카드 흔들림과 오류음은 카드의 PressFeedback이 낸다.
        _modifierDenyTicks.update(modifier, (v) => v + 1, ifAbsent: () => 1);
      }
    });
    if (unlocked) GameFeedback.play(GameCue.unlock);
    showTopNotice(
      context,
      unlocked ? '${modifier.label} 해금' : '기억 카드가 부족합니다.',
      cue: null,
    );
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
                GameIconButtonChip(
                  icon: Icons.arrow_back_rounded,
                  onPressed: _goBack,
                ),
                Expanded(
                  child: Text(
                    '새 게임 시작',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: MenuSurface.goldText.withValues(alpha: 0.96),
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
            const SizedBox(height: 18),
            if (_availableDifficulties.length > 1) ...[
              HomeSection(
                title: '난이도',
                subtitle: '이번 런의 시작 조건을 고릅니다.',
                child: _DifficultyPicker(
                  difficulties: _availableDifficulties,
                  selectedDifficulty: _selectedDifficulty,
                  onChanged: (difficulty) {
                    GameFeedback.play(GameCue.choiceSelect);
                    setState(() => _selectedDifficulty = difficulty);
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_selectedDifficulty == NewRunDifficulty.challenge) ...[
              _ChallengeCarryoverNotice(
                carryover: _unlockState.challengeCarryover,
              ),
              const SizedBox(height: 18),
            ],
            HomeSection(
              title: '런 규칙',
              subtitle: _unlockState.insight > 0 ? '기억 카드 보유' : '기억 카드 없음',
              child: _RunModifierPicker(
                selectedRunModifier: _selectedRunModifier,
                unlockState: _unlockState,
                denyTicks: _modifierDenyTicks,
                unlockTicks: _modifierUnlockTicks,
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
                    primary: true,
                    cue: GameCue.runStart,
                    decision: true,
                    onTap: _startRandomRun,
                  ),
                  const SizedBox(height: 8),
                  HomeEntryCard(
                    title: context.tr('entryInputSeed'),
                    description: '시드를 직접 입력해 시작',
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

class _ChallengeCarryoverNotice extends StatelessWidget {
  const _ChallengeCarryoverNotice({required this.carryover});

  final ChallengeCarryoverSnapshot? carryover;

  @override
  Widget build(BuildContext context) {
    final grownRankCount = carryover?.grownRankCount ?? 0;
    final addedDeckCount = carryover?.addedDeckTiles.length ?? 0;
    final hasCarryover = carryover?.hasContent ?? false;
    final summary = hasCarryover
        ? '계승: 성장 족보 $grownRankCount개 · 추가 덱 $addedDeckCount장'
        : '계승 정보 없음 · 표준 S8 Boss 클리어 후 갱신됩니다.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDeckUpgrade,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameUiPalette.actionInfoBlueSoftBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.upgrade_rounded,
            color: GameUiPalette.actionInfoBlueText,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '도전 계승',
                  style: TextStyle(
                    color: GameUiPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    color: GameUiPalette.actionInfoBluePale,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '족보 레벨과 추가 덱 카드만 유지됩니다. 골드, Jester, 아이템, 마켓 상태는 새 런에서 초기화됩니다.',
                  style: TextStyle(
                    color: GameUiPalette.actionInfoBlueMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _RunModifierPicker extends StatelessWidget {
  const _RunModifierPicker({
    required this.selectedRunModifier,
    required this.unlockState,
    required this.denyTicks,
    required this.unlockTicks,
    required this.onSelect,
  });

  final NewRunModifier selectedRunModifier;
  final RunUnlockState unlockState;
  final Map<NewRunModifier, int> denyTicks;
  final Map<NewRunModifier, int> unlockTicks;
  final ValueChanged<NewRunModifier> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        for (final modifier in NewRunModifier.values)
          _RunModifierCard(
            key: ValueKey('run-modifier-${modifier.id}'),
            modifier: modifier,
            selected: modifier == selectedRunModifier,
            unlocked: unlockState.isRunModifierUnlocked(modifier),
            canUnlock: unlockState.insight >= modifier.unlockCostInsight,
            denyTrigger: denyTicks[modifier] ?? 0,
            unlockTrigger: unlockTicks[modifier] ?? 0,
            onTap: () => onSelect(modifier),
          ),
      ],
    );
  }
}

class _RunModifierCard extends StatelessWidget {
  const _RunModifierCard({
    super.key,
    required this.modifier,
    required this.selected,
    required this.unlocked,
    required this.canUnlock,
    required this.denyTrigger,
    required this.unlockTrigger,
    required this.onTap,
  });

  final NewRunModifier modifier;
  final bool selected;
  final bool unlocked;
  final bool canUnlock;
  final int denyTrigger;
  final int unlockTrigger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = MenuSurface.goldBright;
    final borderColor = selected
        ? accent
        : MenuSurface.border(alpha: unlocked ? 0.26 : 0.14);
    final fillColor = selected
        ? MenuSurface.gold.withValues(alpha: 0.18)
        : MenuSurface.panelFill(alpha: unlocked ? 0.56 : 0.34);
    final status = unlocked
        ? (selected ? '선택됨' : '선택 가능')
        : (canUnlock ? '기억 카드로 해금' : '기억 카드 필요');
    return _UnlockBurst(
      trigger: unlockTrigger,
      color: accent,
      child: PressFeedback(
        onTap: onTap,
        denyTrigger: denyTrigger,
        haptic: null,
        builder: (context, onTap) => Material(
          color: GameUiPalette.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: GamePresentationTimings.choiceSelect,
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  _ChoiceIcon(
                    icon: unlocked
                        ? (selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded)
                        : Icons.lock_rounded,
                    color: unlocked || canUnlock
                        ? accent
                        : GameUiPalette.textPrimary.withValues(alpha: 0.42),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modifier.label,
                          style: TextStyle(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: 0.94,
                            ),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _modifierEffectText(modifier),
                          style: TextStyle(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: 0.68,
                            ),
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
                          : GameUiPalette.textPrimary.withValues(alpha: 0.46),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
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
        ? MenuSurface.goldBright
        : MenuSurface.border(alpha: 0.26);
    final fillColor = selected
        ? MenuSurface.gold.withValues(alpha: 0.18)
        : MenuSurface.panelFill(alpha: 0.56);
    return PressFeedback(
      onTap: onTap,
      haptic: null,
      builder: (context, onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: GamePresentationTimings.choiceSelect,
          curve: Curves.easeOut,
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
              _ChoiceIcon(
                icon: selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? MenuSurface.goldBright
                    : GameUiPalette.textPrimary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                setup.difficultyLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.94),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택 아이콘을 짧은 fade·scale로 바꾼다.
class _ChoiceIcon extends StatelessWidget {
  const _ChoiceIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: GamePresentationTimings.choiceSelect,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Icon(icon, key: ValueKey(icon), color: color),
    );
  }
}

/// modifier 해금 순간 카드가 크게 튕기고 불꽃이 튄다.
class _UnlockBurst extends StatefulWidget {
  const _UnlockBurst({
    required this.trigger,
    required this.color,
    required this.child,
  });

  final int trigger;
  final Color color;
  final Widget child;

  @override
  State<_UnlockBurst> createState() => _UnlockBurstState();
}

class _UnlockBurstState extends State<_UnlockBurst> {
  static const double _juiceStrength = 2.2;

  @override
  void didUpdateWidget(covariant _UnlockBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == oldWidget.trigger) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final size = box.size;
      Fx.emit(context, FxPresets.sparks.copyWith(color: widget.color), [
        size.centerLeft(Offset(size.width * 0.12, 0)),
        size.center(Offset.zero),
        size.centerRight(Offset(-size.width * 0.12, 0)),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Juice(
      trigger: widget.trigger,
      strength: _juiceStrength,
      child: widget.child,
    );
  }
}
