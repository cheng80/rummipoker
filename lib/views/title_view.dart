import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_config.dart';
import '../providers/features/rummi_poker_grid/title_notifier.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_facade.dart';
import '../services/active_run_save_service.dart';
import '../services/archive_seen_service.dart';
import '../services/debug_run_fixture_service.dart';
import '../services/game_settings.dart';
import '../services/in_app_review_service.dart';
import '../utils/active_run_translation.dart';
import '../utils/app_translation.dart';
import '../utils/common_ui.dart';
import 'game/game_feedback_cues.dart';
import '../widgets/fx/entrance_in.dart';
import '../widgets/fx/fx_ambient.dart';
import '../widgets/fx/motion_policy.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'game/game_presentation_timings.dart';
import 'game/widgets/game_bookmark_slot_dialog.dart';
import 'game/widgets/game_run_info_dialog.dart';
import 'game/widgets/game_ui_palette.dart';
import 'home_entry_widgets.dart';

/// 타이틀 화면. 우주 배경 위에 제목과 모드 선택 버튼을 표시한다.
class TitleView extends ConsumerStatefulWidget {
  const TitleView({
    super.key,
    this.debugScrollPreset,
    this.showDebugEntriesOverride,
  });

  final String? debugScrollPreset;
  final bool? showDebugEntriesOverride;

  @override
  ConsumerState<TitleView> createState() => _TitleViewState();
}

class _TitleViewState extends ConsumerState<TitleView>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late final Future<PackageInfo> _packageInfoFuture;

  // --- T4: 앱을 켜고 처음 타이틀에 올 때만 등장 연출을 한다.
  static bool _entrancePlayed = false;
  late final bool _playEntrance;

  /// 진입 카드 묶음 [index]의 등장.
  Widget _entrance(int index, Widget child) => EntranceIn(
    enabled: _playEntrance,
    delay:
        GamePresentationTimings.titleLogoSettle * 0.5 +
        GamePresentationTimings.flowEntranceStagger * index,
    duration: GamePresentationTimings.flowEntranceIn,
    child: child,
  );

  @override
  void initState() {
    super.initState();
    FxAmbient.setMoodAfterFrame(FxAmbientMood.menu);
    _playEntrance = !_entrancePlayed;
    _entrancePlayed = true;
    _packageInfoFuture = PackageInfo.fromPlatform();
    WidgetsBinding.instance.addObserver(this);
    SoundManager.playBgm(AssetPaths.bgmMenu);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(titleNotifierProvider.notifier).refreshAvailability();
      // 키가 없는 기존 사용자는 지금까지의 발견을 모두 확인한 것으로 맞춘다.
      unawaited(ArchiveSeenService.ensureInitialized());
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) InAppReviewService.maybeRequestReviewOnTitleIfEligible();
    });
    _applyDebugScrollPreset();
  }

  void _applyDebugScrollPreset() {
    if (!_showDebugEntries || widget.debugScrollPreset != 'bottom') {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  bool get _showDebugEntries =>
      widget.showDebugEntriesOverride ?? AppConfig.showDebugFixtures;

  void _unlockMenuBgmFromGesture() {
    SoundManager.playBgmFromUserGesture(AssetPaths.bgmMenu);
  }

  Future<void> _openContinueMenu() async {
    final notifier = ref.read(titleNotifierProvider.notifier);
    final titleState = await notifier.refreshAvailability();
    if (!mounted) return;

    if (!titleState.hasStoredActiveRun) {
      return;
    }

    if (titleState.lastAvailability == ActiveRunAvailability.available) {
      final summary =
          titleState.storedRunSummary ?? await notifier.loadStoredRunSummary();
      if (!mounted) return;
      final action = await showGameChoiceDialog<String>(
        context,
        titleBuilder: (dialogContext) =>
            dialogContext.translate('homeContinueSectionTitle'),
        messageBuilder: (dialogContext) =>
            _continueDialogMessage(dialogContext, summary),
        actionsBuilder: (dialogContext) => [
          GameDialogAction<String>(
            label: dialogContext.translate('menuDelete'),
            value: 'delete',
            accent: GameUiPalette.titleDangerAccent,
          ),
          GameDialogAction<String>(
            label: dialogContext.translate('cancel'),
            value: 'cancel',
            accent: GameUiPalette.disabledControl,
          ),
          GameDialogAction<String>(
            label: dialogContext.translate('runInfoTitle'),
            value: 'runInfo',
            accent: GameUiPalette.actionGoldBright,
            textColor: GameUiPalette.ink,
          ),
          GameDialogAction<String>(
            label: dialogContext.translate('homeContinueSectionTitle'),
            value: 'continue',
            cue: GameCue.runRestore,
            accent: GameUiPalette.actionGold,
            textColor: GameUiPalette.ink,
          ),
        ],
      );
      if (!mounted || action == null || action == 'cancel') return;
      if (action == 'delete') {
        await _deleteStoredRun(showMessage: true);
        return;
      }
      if (action == 'runInfo') {
        await showGameRunInfoDialog(
          context: context,
          playedHandCounts: summary?.currentPlayedHandCounts ?? const {},
          handGrowthStates: summary?.currentHandGrowthStates ?? const {},
          addedDeckTiles: summary?.currentAddedDeckTiles ?? const [],
        );
        if (!mounted) return;
        await _openContinueMenu();
        return;
      }
      final restoredRun = await notifier.loadStoredRun();
      if (!mounted) return;
      if (restoredRun == null) {
        await _showCorruptedSaveDialog();
        return;
      }
      SoundManager.unlockForWeb();
      final router = GoRouter.of(context);
      await SoundManager.fadeOutBgm(GamePresentationTimings.titleBgmFadeOut);
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final route = restoredRun.activeScene == ActiveRunScene.blindSelect
          ? '${RoutePaths.blindSelect}?difficulty=${restoredRun.difficulty.name}'
          : '${RoutePaths.game}?difficulty=${restoredRun.difficulty.name}';
      router.go(route, extra: restoredRun);
      return;
    }

    await _showCorruptedSaveDialog();
  }

  Future<void> _openTitleRunInfo() async {
    final notifier = ref.read(titleNotifierProvider.notifier);
    final titleState = await notifier.refreshAvailability();
    if (!mounted) return;

    if (!titleState.hasStoredActiveRun ||
        titleState.lastAvailability != ActiveRunAvailability.available) {
      await showGameChoiceDialog<void>(
        context,
        title: context.translate('runInfoTitle'),
        message: context.translate('menuNoActiveRun'),
        actions: [
          GameDialogAction<void>(
            label: context.translate('ok'),
            value: null,
            accent: GameUiPalette.actionGoldBright,
            textColor: GameUiPalette.ink,
          ),
        ],
      );
      return;
    }

    final summary =
        titleState.storedRunSummary ?? await notifier.loadStoredRunSummary();
    if (!mounted) return;
    await showGameRunInfoDialog(
      context: context,
      playedHandCounts: summary?.currentPlayedHandCounts ?? const {},
      handGrowthStates: summary?.currentHandGrowthStates ?? const {},
      addedDeckTiles: summary?.currentAddedDeckTiles ?? const [],
    );
  }

  Future<void> _openBookmarkLoadMenu() async {
    final slots = await ActiveRunSaveService.loadBookmarkSlots();
    if (!mounted) return;
    final slotIndex = await showBookmarkSlotDialog(
      context: context,
      titleBuilder: (c) => c.translate('menuLoadBookmark'),
      messageBuilder: (c) => c.translate('menuLoadBookmarkDesc'),
      slots: slots,
    );
    if (!mounted || slotIndex == null) return;
    final selected = slots[slotIndex];
    if (selected.isEmpty) {
      showTopNotice(context, context.translate('menuEmptyBookmark'));
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (c) => c.translate('menuLoadBookmark'),
      messageBuilder: (c) => c.translate(
        'menuLoadBookmarkPrompt',
        namedArgs: {'summary': c.activeRunSlotLabel(selected)},
      ),
      confirmLabelBuilder: (c) => c.translate('menuLoad'),
      confirmCue: GameCue.runRestore,
    );
    if (!mounted || !confirmed) return;
    final restoredRun = await ActiveRunSaveService.restoreBookmarkToActiveRun(
      slotIndex,
    );
    if (!mounted) return;
    if (restoredRun == null) {
      showTopNotice(context, context.translate('menuLoadBookmarkFailed'));
      return;
    }
    SoundManager.unlockForWeb();
    final router = GoRouter.of(context);
    await SoundManager.fadeOutBgm(GamePresentationTimings.titleBgmFadeOut);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final route = restoredRun.activeScene == ActiveRunScene.blindSelect
        ? '${RoutePaths.blindSelect}?difficulty=${restoredRun.difficulty.name}'
        : '${RoutePaths.game}?difficulty=${restoredRun.difficulty.name}';
    router.go(route, extra: restoredRun);
  }

  Future<void> _showCorruptedSaveDialog() async {
    final action = await showGameChoiceDialog<String>(
      context,
      title: context.translate('menuCheckSave'),
      message: context.translate('menuInvalidSave'),
      actions: [
        GameDialogAction<String>(
          label: context.translate('cancel'),
          value: 'cancel',
          accent: GameUiPalette.disabledControl,
        ),
        GameDialogAction<String>(
          label: context.translate('menuDelete'),
          value: 'delete',
          accent: GameUiPalette.titleDangerAccent,
        ),
      ],
    );
    if (!mounted || action != 'delete') return;
    await _deleteStoredRun(showMessage: true);
  }

  Future<void> _deleteStoredRun({required bool showMessage}) async {
    await ref.read(titleNotifierProvider.notifier).clearStoredRun();
    if (!mounted) return;
    if (showMessage) {
      showTopNotice(context, context.translate('menuSaveDeleted'));
    }
  }

  Future<void> _openDebugFixtureMenu() async {
    final fixtures = DebugRunFixtureService.fixtures;
    if (fixtures.isEmpty) {
      showTopNotice(context, context.translate('menuNoFixtures'));
      return;
    }

    final fixtureId = await showGameChoiceDialog<String>(
      context,
      title: context.translate('menuDebugFixture'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fixtures
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _DebugFixtureOption(
                      number: entry.key + 1,
                      label: entry.value.label,
                      description: entry.value.description,
                      onTap: () => Navigator.of(context).pop(entry.value.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        GameDialogAction<String>(
          label: context.translate('cancel'),
          value: 'cancel',
          accent: GameUiPalette.disabledControl,
        ),
      ],
    );
    if (!mounted || fixtureId == null || fixtureId == 'cancel') return;
    await _startDebugFixture(fixtureId);
  }

  Future<void> _startDebugFixture(String fixtureId) async {
    final fixture = DebugRunFixtureService.find(fixtureId);
    if (fixture == null) {
      showTopNotice(context, context.translate('menuFixtureNotFound'));
      return;
    }
    final runtime = fixture.builder();
    final router = GoRouter.of(context);
    SoundManager.unlockForWeb();

    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    router.go('${RoutePaths.game}?fixture=${fixture.id}', extra: runtime);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMenu);
        break;
      case AppLifecycleState.resumed:
        SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMenu);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// 우주 배경 위에 제목·버튼을 배치한다.
  @override
  Widget build(BuildContext context) {
    final titleState = ref.watch(titleNotifierProvider).valueOrNull;
    final hasStoredActiveRun = titleState?.hasStoredActiveRun ?? false;
    final storedRunSummary = titleState?.storedRunSummary;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _unlockMenuBgmFromGesture(),
      onPointerUp: (_) => _unlockMenuBgmFromGesture(),
      child: PhoneFrameScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    EntranceIn(
                      enabled: _playEntrance,
                      duration: GamePresentationTimings.titleLogoSettle,
                      offset: const Offset(0, -0.35),
                      scaleFrom: 1.08,
                      curve: Curves.easeOutBack,
                      child: _TitleLogoIdle(
                        child: Semantics(
                          label: context
                              .translate('gameTitleBlock')
                              .replaceAll('\n', ' '),
                          image: true,
                          child: Image.asset(
                            AssetPaths.uiRummiPokerLogo,
                            width: 242,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      context.translate('gameSubtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: GameUiPalette.actionGoldText.withValues(
                          alpha: 0.76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _entrance(
                      0,
                      HomeSection(
                        title: context.translate('homeContinueSectionTitle'),
                        child: Column(
                          children: [
                            HomeEntryCard(
                              key: const ValueKey('home-entry-continue'),
                              title: context.translate('continueGame'),
                              description: storedRunSummary != null
                                  ? context.activeRunLocation(storedRunSummary)
                                  : (hasStoredActiveRun
                                        ? context.translate(
                                            'homeContinueReadyDescription',
                                          )
                                        : context.translate(
                                            'homeContinueEmptyDescription',
                                          )),
                              primary: true,
                              enabled: hasStoredActiveRun,
                              onTap: _openContinueMenu,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: HomeEntryCard(
                                    key: const ValueKey('home-entry-run-info'),
                                    title: context.translate('runInfoTitle'),
                                    compact: true,
                                    onTap: _openTitleRunInfo,
                                  ),
                                ),
                                Expanded(
                                  child: HomeEntryCard(
                                    key: const ValueKey('home-entry-bookmark'),
                                    title: context.translate('menuBookmarks'),
                                    compact: true,
                                    onTap: _openBookmarkLoadMenu,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _entrance(
                      1,
                      HomeSection(
                        title: context.translate('homeNewRunSectionTitle'),
                        child: HomeEntryCard(
                          key: const ValueKey('home-entry-new-run'),
                          title: context.translate('homeNewRunTitle'),
                          description: context.translate(
                            'homeNewRunDescription',
                          ),
                          primary: true,
                          decision: true,
                          onTap: () => context.push(RoutePaths.newRun),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _entrance(
                      2,
                      HomeSection(
                        title: context.translate('homeOtherMenuSectionTitle'),
                        child: Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: HomeEntryCard(
                                key: const ValueKey('home-entry-archive'),
                                title: context.translate('archiveTitle'),
                                compact: true,
                                onTap: () => context.push(RoutePaths.archive),
                              ),
                            ),
                            if (_showDebugEntries)
                              Expanded(
                                child: HomeEntryCard(
                                  key: ValueKey('home-entry-special-mode'),
                                  title: context.translate(
                                    'homeSpecialModeTitle',
                                  ),
                                  compact: true,
                                  accent: GameUiPalette.titleDebugPurple,
                                  onTap: () => context.push(RoutePaths.trial),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDebugEntries) ...[
                      const SizedBox(height: 12),
                      _entrance(
                        3,
                        HomeSection(
                          title: context.translate('menuDebug'),
                          child: HomeEntryCard(
                            key: const ValueKey('home-entry-debug-fixture'),
                            title: context.translate('menuDebugFixture'),
                            description: context.translate('menuDebugDesc'),
                            accent: GameUiPalette.titleDebugPurpleDark,
                            onTap: _openDebugFixtureMenu,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _entrance(
                      4,
                      HomeSection(
                        title: context.translate('settings'),
                        child: HomeEntryCard(
                          key: const ValueKey('home-entry-setting'),
                          title: context.translate('settings'),
                          description: context.translate(
                            'homeSettingsDescription',
                          ),
                          onTap: () {
                            context.push(RoutePaths.setting);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
                      child: FutureBuilder<PackageInfo>(
                        future: _packageInfoFuture,
                        builder: (context, snapshot) {
                          final v = snapshot.data;
                          // The noun alone ("Version") is not a sentence, so
                          // show nothing until the value arrives.
                          final text = v == null
                              ? ''
                              : context.translate(
                                  'appVersionValue',
                                  namedArgs: {
                                    'version': '${v.version}+${v.buildNumber}',
                                  },
                                );
                          // 버전 값이 늦게 와도 툭 튀지 않게 fade로 바꾼다.
                          return AnimatedSwitcher(
                            duration: GamePresentationTimings.flowEntranceIn,
                            child: Text(
                              text,
                              key: ValueKey(text),
                              style: TextStyle(
                                color: GameUiPalette.textPrimary.withValues(
                                  alpha: 0.58,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _continueDialogMessage(
  BuildContext context,
  RummiActiveRunSaveFacade? summary,
) {
  if (summary == null) {
    return context.translate('menuContinueDesc');
  }
  return context.activeRunContinueMessage(summary);
}

class _DebugFixtureOption extends StatelessWidget {
  const _DebugFixtureOption({
    required this.number,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final int number;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numberedLabel = '$number. $label';
    return Semantics(
      button: true,
      label: numberedLabel,
      child: PressFeedback(
        onTap: onTap,
        builder: (context, onTap) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.titlePanelSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: GameUiPalette.cardFallback.withValues(alpha: 0.32),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.ink.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          numberedLabel,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: GameUiPalette.textPrimary,
                          ),
                        ),
                        Text(
                          description,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: 0.74,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GameUiPalette.cardFallback.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: GameUiPalette.cardFallback.withValues(
                          alpha: 0.26,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: GameUiPalette.specialMutedText,
                      ),
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
}

/// 테스트에서 '앱을 켜고 처음 온 타이틀' 상태로 되돌린다.
@visibleForTesting
void debugResetTitleEntrance() => _TitleViewState._entrancePlayed = false;

/// 연출 강도 '강'에서만 로고가 천천히 떠다닌다. 기본 강도에서는 멈춰 있다.
class _TitleLogoIdle extends StatefulWidget {
  const _TitleLogoIdle({required this.child});

  final Widget child;

  @override
  State<_TitleLogoIdle> createState() => _TitleLogoIdleState();
}

class _TitleLogoIdleState extends State<_TitleLogoIdle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  late final bool _on =
      GameSettings.fxIntensity == FxIntensity.strong &&
      !MotionPolicy.reduceMotion;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: GamePresentationTimings.titleLogoIdle,
    );
    // ponytail: '강'에서만 도는 의도된 상시 루프. 화면을 떠나면 dispose로 멈춘다.
    if (_on) _idle.repeat(reverse: true);
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_on) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _idle,
        child: widget.child,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_idle.value);
          return Transform.translate(
            offset: Offset(0, -4 + 8 * t),
            child: Transform.rotate(angle: -0.008 + 0.016 * t, child: child),
          );
        },
      ),
    );
  }
}
