import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/in_app_review_service.dart';
import '../widgets/phone_frame_scaffold.dart';

/// 타이틀 화면. 우주 배경 위에 제목과 모드 선택 버튼을 표시한다.
class TitleView extends StatefulWidget {
  const TitleView({super.key});

  @override
  State<TitleView> createState() => _TitleViewState();
}

class _TitleViewState extends State<TitleView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundManager.playBgm(AssetPaths.bgmMenu);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) InAppReviewService.maybeRequestReviewOnTitleIfEligible();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _StarryBackground(),
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: PhoneFrame(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),
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
                                  color: const Color(
                                    0xFFFFD54F,
                                  ).withValues(alpha: 0.5),
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
                              fontSize: 22,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(flex: 3),
                          _RoundButton(
                            label: context.tr('entryRandomSeed'),
                            color: const Color(0xFF3CAEE0),
                            fontSize: 26,
                            onPressed: () async {
                              SoundManager.unlockForWeb();
                              SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                              final s = RummiPokerGridSession.rollNewRunSeed();
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
                          const Spacer(flex: 2),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSeedInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('seedDialogTitle')),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: false,
          ),
          decoration: InputDecoration(hintText: context.tr('seedHint')),
          autofocus: true,
          onSubmitted: (_) =>
              _trySubmitSeed(context, dialogContext, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => _trySubmitSeed(context, dialogContext, controller),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _trySubmitSeed(
    BuildContext titleContext,
    BuildContext dialogContext,
    TextEditingController controller,
  ) async {
    final v = int.tryParse(controller.text.trim());
    if (v == null) {
      ScaffoldMessenger.of(
        titleContext,
      ).showSnackBar(SnackBar(content: Text(titleContext.tr('seedInvalid'))));
      return;
    }
    Navigator.of(dialogContext).pop();
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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

/// 반짝이는 별 배경.
class _StarryBackground extends StatefulWidget {
  const _StarryBackground();

  @override
  State<_StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<_StarryBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// 별 깜박임용 애니메이션 컨트롤러 시작.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  /// 애니메이션 컨트롤러 해제.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// CustomPaint로 별 배경을 그린다. _controller.value로 깜박임 주기 전달.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _StarPainter(_controller.value),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.time);
  final double time;

  static final List<_Star> _stars = _generateStars(100);

  /// [count]개의 별을 시드 42로 생성한다. 재현 가능한 배치.
  static List<_Star> _generateStars(int count) {
    // 시드 42로 재현 가능한 별 배치.
    final rng = Random(42);
    return List.generate(count, (_) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.6 + 0.3, // 0.3~1.9
        speed: rng.nextDouble() * 2.0 + 0.5, // 0.5~2.5
        offset: rng.nextDouble() * 2 * pi,
        colorIndex: rng.nextInt(4),
      );
    });
  }

  static const _colors = [
    Colors.white,
    Color(0xFFAADDFF),
    Color(0xFFFFEEAA),
    Color(0xFFFFAAAA),
  ];

  /// 그라데이션 배경 위에 sin 기반 깜박이는 별들을 그린다.
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF05051A),
          Color(0xFF0A0A2E),
          Color(0xFF12123A),
          Color(0xFF0A0A2E),
          Color(0xFF05051A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (final star in _stars) {
      // sin 기반 깜박임: alpha 0.05~0.8.
      final t = time * 2 * pi;
      final twinkle = sin(t * star.speed + star.offset);
      final alpha = (0.4 + twinkle * 0.4).clamp(0.05, 1.0);
      final color = _colors[star.colorIndex];
      final paint = Paint()..color = color.withValues(alpha: alpha);
      final cx = star.x * size.width;
      final cy = star.y * size.height;
      canvas.drawCircle(Offset(cx, cy), star.radius, paint);

      // 큰 별은 블러 글로우.
      if (star.radius > 1.2) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(cx, cy), star.radius * 2.5, glowPaint);
      }
    }
  }

  /// time이 변경되면 다시 그린다.
  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.time != time;
}

class _Star {
  final double x, y, radius, speed, offset;
  final int colorIndex;

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.offset,
    required this.colorIndex,
  });
}
