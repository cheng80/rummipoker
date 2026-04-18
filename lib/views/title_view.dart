import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../providers/features/rummi_poker_grid/title_notifier.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/in_app_review_service.dart';
import '../services/active_run_save_service.dart';
import '../services/debug_run_fixture_service.dart';
import '../utils/common_ui.dart';
import '../widgets/phone_frame_scaffold.dart';

/// 타이틀 화면. 우주 배경 위에 제목과 모드 선택 버튼을 표시한다.
class TitleView extends ConsumerStatefulWidget {
  const TitleView({super.key});

  @override
  ConsumerState<TitleView> createState() => _TitleViewState();
}

class _TitleViewState extends ConsumerState<TitleView>
    with WidgetsBindingObserver {
  final TextEditingController _seedInputController = TextEditingController();

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
  }

  Future<void> _openContinueMenu() async {
    final notifier = ref.read(titleNotifierProvider.notifier);
    final titleState = await notifier.refreshAvailability();
    if (!mounted) return;

    if (!titleState.hasStoredActiveRun) {
      return;
    }

    if (titleState.lastAvailability == ActiveRunAvailability.available) {
      final action = await showAppDialog<String>(
        context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('이어하기'),
          content: const Text('이어하기는 저장된 현재 런을 복원합니다.\n삭제하거나 그대로 이어할지 선택하세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('delete'),
              child: const Text('삭제하기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('continue'),
              child: const Text('이어하기'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;
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
      router.go(RoutePaths.game, extra: restoredRun);
      return;
    }

    await _showCorruptedSaveDialog();
  }

  Future<void> _showCorruptedSaveDialog() async {
    final action = await showAppDialog<String>(
      context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('저장 데이터 확인'),
        content: const Text(
          '이어하기용 저장 데이터가 손상되었거나 현재 버전과 호환되지 않습니다.\n삭제 후 새 런을 시작하는 것을 권장합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('delete'),
            child: const Text('삭제하기'),
          ),
        ],
      ),
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

    final fixtureId = await showAppDialog<String>(
      context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('디버그 픽스처'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final fixture in fixtures) ...[
                  _DebugFixtureOption(
                    label: fixture.label,
                    description: fixture.description,
                    onTap: () => Navigator.of(dialogContext).pop(fixture.id),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (!mounted || fixtureId == null) return;
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
    _seedInputController.dispose();
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
    return PhoneFrameScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 44),
                  Text(
                    context.tr('gameTitleBlock'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontAngduIpsul140,
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
                      fontFamily: AssetPaths.fontAngduIpsul140,
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 52),
                  if (hasStoredActiveRun) ...[
                    _RoundButton(
                      label: '이어하기',
                      color: const Color(0xFFF4A81D),
                      fontSize: 26,
                      onPressed: _openContinueMenu,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _RoundButton(
                    label: context.tr('entryRandomSeed'),
                    color: const Color(0xFF3CAEE0),
                    fontSize: 26,
                    onPressed: () async {
                      SoundManager.unlockForWeb();
                      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                      final s = RummiPokerGridSession.rollNewRunSeed();
                      await ActiveRunSaveService.clearActiveRun();
                      await SoundManager.stopBgm();
                      if (!context.mounted) return;
                      context.go('${RoutePaths.game}?seed=$s');
                    },
                  ),
                  const SizedBox(height: 20),
                  _RoundButton(
                    label: context.tr('entryInputSeed'),
                    color: const Color(0xFF2DB872),
                    fontSize: 26,
                    onPressed: () => _openSeedInputDialog(context),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    _RoundButton(
                      label: '디버그',
                      color: const Color(0xFF7E57C2),
                      fontSize: 24,
                      onPressed: _openDebugFixtureMenu,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _RoundButton(
                    label: context.tr('settings'),
                    color: const Color(0xFF1976D2),
                    onPressed: () {
                      SoundManager.unlockForWeb();
                      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                      context.push(RoutePaths.setting);
                    },
                  ),
                  const Spacer(),
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

  Future<void> _openSeedInputDialog(BuildContext context) async {
    _seedInputController.clear();
    await showAppDialog<void>(
      context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('seedDialogTitle')),
        content: TextField(
          controller: _seedInputController,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: false,
          ),
          decoration: InputDecoration(hintText: context.tr('seedHint')),
          autofocus: true,
          onSubmitted: (_) =>
              _trySubmitSeed(context, dialogContext, _seedInputController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () =>
                _trySubmitSeed(context, dialogContext, _seedInputController),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _trySubmitSeed(
    BuildContext titleContext,
    BuildContext dialogContext,
    TextEditingController controller,
  ) async {
    final v = int.tryParse(controller.text.trim());
    if (v == null) {
      showTopNotice(titleContext, titleContext.tr('seedInvalid'));
      return;
    }
    Navigator.of(dialogContext).pop();
    await WidgetsBinding.instance.endOfFrame;
    if (!titleContext.mounted) return;
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!titleContext.mounted) return;
    titleContext.go('${RoutePaths.game}?seed=$v');
  }
}

/// 참조 이미지 스타일의 둥글고 큼지막한 버튼.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.fontSize = 32,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final double fontSize;

  /// 그라데이션·테두리·그림자가 적용된 둥근 버튼을 반환한다.
  @override
  Widget build(BuildContext context) {
    const width = 300.0;
    const height = 68.0;
    final darkerColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, darkerColor],
          ),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: darkerColor.withValues(alpha: 0.6),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: darkerColor.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AssetPaths.fontAngduIpsul140,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 6,
              shadows: [
                Shadow(
                  color: darkerColor.withValues(alpha: 0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
