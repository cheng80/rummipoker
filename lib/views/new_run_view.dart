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
                fontFamily: AssetPaths.fontAngduIpsul140,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '지금 가능한 시작 방식과 준비 중인 시작 옵션을 나눠 둔 화면입니다.',
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
              title: '바로 시작',
              subtitle: '지금 바로 선택할 수 있는 시작 방식',
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
            const SizedBox(height: 18),
            HomeSection(
              title: '시작 설정',
              subtitle: '난이도만 먼저 고르고, 덱 선택은 이후 구현 전까지 자리만 유지합니다.',
              child: Column(
                children: [
                  _SelectableOptionCard(
                    title: '덱 선택',
                    options: [
                      _OptionItem(
                        label: '기본 덱',
                        description: '현재는 플레이스홀더입니다. 덱별 규칙 차이는 아직 없습니다.',
                        selected: true,
                        isLocked: !_unlockState.isDeckAvailable('basic_deck'),
                        lockReason: _unlockState.isDeckAvailable('basic_deck')
                            ? '덱 선택은 이후 구현 예정'
                            : '기본 덱 데이터 확인 필요',
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SelectableOptionCard(
                    title: '난이도 선택',
                    options: [
                      _OptionItem(
                        label: '표준',
                        description: '기본 시작값',
                        selected:
                            _selectedDifficulty == NewRunDifficulty.standard,
                        onTap: () => setState(() {
                          _selectedDifficulty = NewRunDifficulty.standard;
                        }),
                      ),
                      _OptionItem(
                        label: '완화',
                        description:
                            '목표 240 / 시작 Gold +3 / 첫 리롤 -1 / 보드+1 / 손패+1',
                        selected:
                            _selectedDifficulty == NewRunDifficulty.relaxed,
                        isLocked: !_unlockState.isDifficultyUnlocked(
                          NewRunDifficulty.relaxed,
                        ),
                        lockReason: '기본 난이도 클리어 후 해금 예정',
                        onTap:
                            _unlockState.isDifficultyUnlocked(
                              NewRunDifficulty.relaxed,
                            )
                            ? () => setState(() {
                                _selectedDifficulty = NewRunDifficulty.relaxed;
                              })
                            : null,
                      ),
                      _OptionItem(
                        label: '압박',
                        description: '목표 360 / 보드-1 / 손패-1',
                        selected:
                            _selectedDifficulty == NewRunDifficulty.pressure,
                        isLocked: !_unlockState.isDifficultyUnlocked(
                          NewRunDifficulty.pressure,
                        ),
                        lockReason: '완화보다 늦게 해금 예정',
                        onTap:
                            _unlockState.isDifficultyUnlocked(
                              NewRunDifficulty.pressure,
                            )
                            ? () => setState(() {
                                _selectedDifficulty = NewRunDifficulty.pressure;
                              })
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  HomeSnapshotCard(
                    title: '현재 선택',
                    summary:
                        '덱 선택: 기본 덱 (플레이스홀더)\n'
                        '난이도: ${NewRunSetup(difficulty: _selectedDifficulty).difficultyLabel}',
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

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({required this.title, required this.options});

  final String title;
  final List<_OptionItem> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < options.length; i++) ...[
            _SelectableOptionTile(item: options[i]),
            if (i != options.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SelectableOptionTile extends StatelessWidget {
  const _SelectableOptionTile({required this.item});

  final _OptionItem item;

  @override
  Widget build(BuildContext context) {
    final isInteractive = !item.isLocked && item.onTap != null;
    final borderColor = item.selected
        ? const Color(0xFF4FC3F7)
        : Colors.white.withValues(alpha: 0.08);
    final fillColor = item.selected
        ? const Color(0xFF4FC3F7).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.04);
    return InkWell(
      onTap: isInteractive ? item.onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: item.selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (item.lockReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.lockReason!,
                      style: TextStyle(
                        color: const Color(0xFFFFD166).withValues(alpha: 0.92),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              item.isLocked
                  ? Icons.lock_rounded
                  : item.selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: item.isLocked
                  ? const Color(0xFFFFD166)
                  : item.selected
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionItem {
  const _OptionItem({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    this.isLocked = false,
    this.lockReason,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback? onTap;
  final bool isLocked;
  final String? lockReason;
}
