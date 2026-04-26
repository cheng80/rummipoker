import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'home_entry_widgets.dart';

/// 타이틀 화면. 우주 배경 위에 제목과 모드 선택 버튼을 표시한다.
class TitleView extends ConsumerStatefulWidget {
  const TitleView({super.key, this.debugScrollPreset});

  final String? debugScrollPreset;

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
    if (!kDebugMode || widget.debugScrollPreset != 'bottom') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
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
        actions: const [
          GameDialogAction<String>(
            label: '삭제',
            value: 'delete',
            accent: Color(0xFF9C4735),
          ),
          GameDialogAction<String>(
            label: '취소',
            value: 'cancel',
            accent: Color(0xFF55615F),
          ),
          GameDialogAction<String>(
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
    final router = GoRouter.of(context);
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    router.go('${RoutePaths.game}?fixture=${fixture.id}');
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
    return PhoneFrameScaffold(
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
                  const SizedBox(height: 44),
                  Text(
                    context.tr('gameTitleBlock'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      fontSize: 88,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                      color: const Color(0xFFFFD54F),
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                          blurRadius: 24,
                        ),
                        const Shadow(
                          color: Color(0xFFE65100),
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('gameSubtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 34),
                  HomeSection(
                    title: '이어하기',
                    subtitle: hasStoredActiveRun
                        ? '저장된 진행과 체크포인트를 확인한 뒤 이어서 들어갑니다.'
                        : '현재 이어서 들어갈 저장 진행이 없습니다.',
                    child: Column(
                      children: [
                        HomeEntryCard(
                          title: '이어하기',
                          description: hasStoredActiveRun
                              ? '저장된 현재 런 복원'
                              : '저장 런이 생기면 여기서 복귀',
                          accent: const Color(0xFFF4A81D),
                          enabled: hasStoredActiveRun,
                          onTap: _openContinueMenu,
                        ),
                        if (storedRunSummary != null) ...[
                          const SizedBox(height: 10),
                          HomeSnapshotCard(
                            title: '저장된 진행',
                            summary: storedRunSummary.snapshotSummaryLabel(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  HomeSection(
                    title: '새 시작',
                    subtitle: '새 게임 시작 화면으로 이동합니다.',
                    child: Column(
                      children: [
                        HomeEntryCard(
                          title: '새 게임 시작',
                          description: '시작 방식 선택 화면으로 이동',
                          accent: const Color(0xFF3CAEE0),
                          onTap: () => context.push(RoutePaths.newRun),
                        ),
                        const SizedBox(height: 10),
                        const HomeSnapshotCard(
                          title: '안내',
                          summary:
                              '다음 화면에서 무작위 시작 또는 시드 시작을 고를 수 있습니다.\n'
                              '준비 중인 시작 옵션은 그 아래에서 따로 보입니다.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  HomeSection(
                    title: '다른 메뉴',
                    subtitle: '본편 진행과 분리된 별도 메뉴입니다.',
                    child: Column(
                      children: [
                        HomeEntryCard(
                          title: '특별 모드',
                          description: '별도 규칙으로 즐기는 추가 모드',
                          accent: const Color(0xFF8E5CF6),
                          onTap: () => context.push(RoutePaths.trial),
                        ),
                        const SizedBox(height: 12),
                        HomeEntryCard(
                          title: '기록실',
                          description: '기록, 수집, 통계 확인',
                          accent: const Color(0xFF5C7CFA),
                          onTap: () => context.push(RoutePaths.archive),
                        ),
                      ],
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 18),
                    HomeSection(
                      title: '디버그',
                      subtitle: '개발과 검증용 진입만 모아 둔 영역',
                      child: HomeEntryCard(
                        title: '디버그 픽스처',
                        description: '검증용 런 상태로 바로 시작',
                        accent: const Color(0xFF7E57C2),
                        onTap: _openDebugFixtureMenu,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  HomeSection(
                    title: '설정',
                    subtitle: '앱 설정과 환경 옵션',
                    child: HomeEntryCard(
                      title: context.tr('settings'),
                      description: '사운드/환경 설정 열기',
                      accent: const Color(0xFF1976D2),
                      onTap: () {
                        SoundManager.unlockForWeb();
                        SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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
                            ? 'Ver ${v.version}+${v.buildNumber}'
                            : 'Ver';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF102A43),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF7E57C2).withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
