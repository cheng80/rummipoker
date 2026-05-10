import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_config.dart';
import '../providers/features/rummi_poker_grid/title_notifier.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/active_run_save_facade.dart';
import '../services/in_app_review_service.dart';
import '../services/active_run_save_service.dart';
import '../services/debug_run_fixture_service.dart';
import '../utils/common_ui.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'game/widgets/game_run_info_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundManager.playBgm(AssetPaths.bgmMenu);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(titleNotifierProvider.notifier).refreshAvailability();
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
        title: '이어하기',
        message: _continueDialogMessage(summary),
        actions: [
          const GameDialogAction<String>(
            label: '삭제',
            value: 'delete',
            accent: Color(0xFF9C4735),
          ),
          const GameDialogAction<String>(
            label: '취소',
            value: 'cancel',
            accent: Color(0xFF55615F),
          ),
          GameDialogAction<String>(
            label: context.tr('runInfoTitle'),
            value: 'runInfo',
            accent: const Color(0xFFF2C14E),
            textColor: Colors.black,
          ),
          const GameDialogAction<String>(
            label: '이어하기',
            value: 'continue',
            accent: Color(0xFFF4A81D),
            textColor: Colors.black,
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
      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
      final router = GoRouter.of(context);
      await SoundManager.stopBgm();
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
        title: context.tr('runInfoTitle'),
        message: '진행 중인 런이 없습니다.\n새 런을 시작하면 족보 성장과 추가 덱 정보가 여기에 표시됩니다.',
        actions: const [
          GameDialogAction<void>(
            label: '확인',
            value: null,
            accent: Color(0xFFF2C14E),
            textColor: Colors.black,
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

  Future<void> _showCorruptedSaveDialog() async {
    final action = await showGameChoiceDialog<String>(
      context,
      title: '저장 데이터 확인',
      message:
          '이어하기용 저장 데이터가 손상되었거나 현재 버전과 호환되지 않습니다.\n삭제 후 새 런을 시작하는 것을 권장합니다.',
      actions: const [
        GameDialogAction<String>(
          label: '취소',
          value: 'cancel',
          accent: Color(0xFF55615F),
        ),
        GameDialogAction<String>(
          label: '삭제',
          value: 'delete',
          accent: Color(0xFF9C4735),
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
      showTopNotice(context, '저장 데이터를 삭제했습니다.');
    }
  }

  Future<void> _openDebugFixtureMenu() async {
    final fixtures = DebugRunFixtureService.fixtures;
    if (fixtures.isEmpty) {
      showTopNotice(context, '등록된 디버그 픽스처가 없습니다.');
      return;
    }

    final fixtureId = await showGameChoiceDialog<String>(
      context,
      title: '디버그 픽스처',
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fixtures
                .map(
                  (fixture) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebugFixtureOption(
                      label: fixture.label,
                      description: fixture.description,
                      onTap: () => Navigator.of(context).pop(fixture.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: const [
        GameDialogAction<String>(
          label: '취소',
          value: 'cancel',
          accent: Color(0xFF55615F),
        ),
      ],
    );
    if (!mounted || fixtureId == null || fixtureId == 'cancel') return;
    await _startDebugFixture(fixtureId);
  }

  Future<void> _startDebugFixture(String fixtureId) async {
    final fixture = DebugRunFixtureService.find(fixtureId);
    if (fixture == null) {
      showTopNotice(context, '디버그 픽스처를 찾지 못했습니다.');
      return;
    }
    final runtime = fixture.builder();
    final router = GoRouter.of(context);
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 28),
                    Semantics(
                      label: context.tr('gameTitleBlock').replaceAll('\n', ' '),
                      image: true,
                      child: Image.asset(
                        AssetPaths.uiRummiPokerLogo,
                        width: 318,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('gameSubtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 24),
                    HomeSection(
                      title: context.tr('homeContinueSectionTitle'),
                      subtitle: hasStoredActiveRun
                          ? context.tr('homeContinueSectionReady')
                          : context.tr('homeContinueSectionEmpty'),
                      child: Column(
                        children: [
                          HomeEntryCard(
                            title: context.tr('continueGame'),
                            description:
                                storedRunSummary?.currentLocationSummary ??
                                (hasStoredActiveRun
                                    ? context.tr('homeContinueReadyDescription')
                                    : context.tr(
                                        'homeContinueEmptyDescription',
                                      )),
                            accent: const Color(0xFFF4A81D),
                            enabled: hasStoredActiveRun,
                            onTap: _openContinueMenu,
                          ),
                          const SizedBox(height: 12),
                          HomeEntryCard(
                            title: context.tr('runInfoTitle'),
                            description: hasStoredActiveRun
                                ? context.tr('homeRunInfoReadyDescription')
                                : context.tr('homeRunInfoEmptyDescription'),
                            accent: const Color(0xFFF2C14E),
                            onTap: _openTitleRunInfo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    HomeSection(
                      title: context.tr('homeNewRunSectionTitle'),
                      subtitle: context.tr('homeNewRunSectionSubtitle'),
                      child: Column(
                        children: [
                          HomeEntryCard(
                            title: context.tr('homeNewRunTitle'),
                            description: context.tr('homeNewRunDescription'),
                            accent: const Color(0xFF3CAEE0),
                            onTap: () => context.push(RoutePaths.newRun),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    HomeSection(
                      title: context.tr('homeOtherMenuSectionTitle'),
                      subtitle: context.tr('homeOtherMenuSectionSubtitle'),
                      child: HomeEntryCard(
                        title: context.tr('archiveTitle'),
                        description: context.tr('homeArchiveDescription'),
                        accent: const Color(0xFF5C7CFA),
                        onTap: () => context.push(RoutePaths.archive),
                      ),
                    ),
                    if (_showDebugEntries) ...[
                      const SizedBox(height: 18),
                      HomeSection(
                        title: '디버그',
                        subtitle: '개발과 검증용 진입만 모아 둔 영역',
                        child: Column(
                          children: [
                            HomeEntryCard(
                              title: context.tr('homeSpecialModeTitle'),
                              description: context.tr(
                                'homeSpecialModeDescription',
                              ),
                              accent: const Color(0xFF8E5CF6),
                              onTap: () => context.push(RoutePaths.trial),
                            ),
                            const SizedBox(height: 12),
                            HomeEntryCard(
                              title: '디버그 픽스처',
                              description: '검증용 런 상태로 바로 시작',
                              accent: const Color(0xFF7E57C2),
                              onTap: _openDebugFixtureMenu,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    HomeSection(
                      title: context.tr('settings'),
                      subtitle: context.tr('homeSettingsSectionSubtitle'),
                      child: HomeEntryCard(
                        title: context.tr('settings'),
                        description: context.tr('homeSettingsDescription'),
                        accent: const Color(0xFF1976D2),
                        onTap: () {
                          context.push(RoutePaths.setting);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final v = snapshot.data;
                          final text = v != null
                              ? '${context.tr('appVersion')} ${v.version}+${v.buildNumber}'
                              : context.tr('appVersion');
                          return Center(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 13,
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

String _continueDialogMessage(RummiActiveRunSaveFacade? summary) {
  if (summary == null) {
    return '이어하기는 저장된 현재 런을 복원합니다.\n삭제하거나 그대로 이어할지 선택하세요.';
  }
  return summary.continueDialogMessage();
}

class _DebugFixtureOption extends StatelessWidget {
  const _DebugFixtureOption({
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF17352C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE6D4A1).withValues(alpha: 0.32),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
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
                        label,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        description,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6D4A1).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE6D4A1).withValues(alpha: 0.26),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFFEFE6C8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
