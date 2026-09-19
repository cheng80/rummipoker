import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/features/settings/settings_notifier.dart';
import '../providers/features/settings/settings_state.dart';
import '../services/game_settings.dart';
import '../views/game/widgets/game_ui_palette.dart';
import 'fx/fx_ambient.dart';
import 'fx/fx_sprites.dart';
import 'fx/motion_policy.dart';

/// 정적 gradient와 움직이는 별을 분리한 앱 공용 배경.
class StarryBackground extends StatefulWidget {
  const StarryBackground({super.key, this.controller});

  @visibleForTesting
  final FxAmbientController? controller;

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with WidgetsBindingObserver {
  late final FxAmbientController _ambient =
      widget.controller ?? FxAmbient.controller;
  late final FxAmbientTicker _ticker = FxAmbientTicker(controller: _ambient);
  ProviderSubscription<SettingsState>? _settingsSubscription;
  bool _hasSettingsProvider = false;
  bool _lifecycleActive = true;
  bool _tickerModeEnabled = true;
  bool _active = true;

  static final _owners = <FxAmbientController, Set<_StarryBackgroundState>>{};

  void _syncLifecycle() {
    _ambient.setLifecycleActive(
      _owners[_ambient]?.any(
            (owner) => owner._active && owner._lifecycleActive,
          ) ??
          false,
    );
  }

  static final List<FxAmbientStar> _stars = createFxAmbientStars();

  @override
  void initState() {
    super.initState();
    (_owners[_ambient] ??= {}).add(this);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _lifecycleActive =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FxSprites.warmUp();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindSettingsProvider();
    _syncMotionPolicy();
  }

  void _bindSettingsProvider() {
    final scope = context
        .dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>();
    final container = scope?.container;
    if (container == null) {
      _hasSettingsProvider = false;
      _settingsSubscription?.close();
      _settingsSubscription = null;
      return;
    }
    if (_hasSettingsProvider && _settingsSubscription != null) return;
    _hasSettingsProvider = true;
    _settingsSubscription?.close();
    _settingsSubscription = container.listen<SettingsState>(
      settingsNotifierProvider,
      (_, next) => _syncMotionPolicy(next.fxIntensity),
      fireImmediately: false,
    );
  }

  void _syncMotionPolicy([FxIntensity? intensity]) {
    if (!_active) return;
    final mediaQuery = MediaQuery.maybeOf(context);
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final enabled =
        (intensity ?? GameSettings.fxIntensity) != FxIntensity.off &&
        !(mediaQuery?.disableAnimations ?? false) &&
        !features.disableAnimations &&
        !features.reduceMotion &&
        !MotionPolicy.reduceMotion;
    _ambient.setMotionEnabled(enabled);
    _syncLifecycle();
    _ambient.setTickerModeEnabled(_tickerModeEnabled);
    _ambient.setHasAnimatedStars(enabled);
    _ticker.attach();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAccessibilityFeatures() => _syncMotionPolicy();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_lifecycleActive == active) return;
    _lifecycleActive = active;
    _syncLifecycle();
    _ticker.attach();
  }

  @override
  void deactivate() {
    _active = false;
    _syncLifecycle();
    _ticker.attach();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _syncLifecycle();
    _ticker.attach();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsSubscription?.close();
    _ticker.dispose();
    final owners = _owners[_ambient];
    owners?.remove(this);
    if (owners?.isEmpty ?? false) _owners.remove(_ambient);
    _active = false;
    _syncLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.expand();
    final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickerModeEnabled != tickerModeEnabled) {
      _tickerModeEnabled = tickerModeEnabled;
      _ambient.setTickerModeEnabled(tickerModeEnabled);
      _ticker.attach();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _GradientPainter(_ambient),
                isComplex: true,
                willChange: false,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _StarPainter(_ambient, _stars),
                isComplex: true,
                willChange: _ambient.shouldAnimate,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GradientPainter extends CustomPainter {
  _GradientPainter(this.ambient) : super(repaint: ambient.moodRepaint);

  final FxAmbientController ambient;
  static const _colors = [
    GameUiPalette.starFieldDeep,
    GameUiPalette.starFieldMid,
    GameUiPalette.starFieldLight,
    GameUiPalette.starFieldMid,
    GameUiPalette.starFieldDeep,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final tint = ambient.moodColor;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          for (final color in _colors)
            Color.lerp(color, tint, ambient.moodTintStrength)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.ambient, this.stars) : super(repaint: ambient);

  final FxAmbientController ambient;
  final List<FxAmbientStar> stars;
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);

  @override
  void paint(Canvas canvas, Size size) {
    final capacity = stars.fold<int>(
      0,
      (count, star) => count + (star.glow ? 2 : 1),
    );
    if (_colors.length < capacity) {
      _transforms = Float32List(capacity * 4);
      _rects = Float32List(capacity * 4);
      _colors = Int32List(capacity);
    }
    var count = 0;
    void add(FxSprite sprite, Offset center, double scale, Color color) {
      final i = count * 4;
      final rect = FxSprites.rectOf(sprite);
      final anchor = FxSprites.cell / 2;
      _transforms[i] = scale;
      _transforms[i + 1] = 0;
      _transforms[i + 2] = center.dx - scale * anchor;
      _transforms[i + 3] = center.dy - scale * anchor;
      _rects[i] = rect.left;
      _rects[i + 1] = rect.top;
      _rects[i + 2] = rect.right;
      _rects[i + 3] = rect.bottom;
      _colors[count] = color.toARGB32();
      count++;
    }

    for (final star in stars) {
      final center = Offset(star.nx * size.width, star.ny * size.height);
      final twinkle = ambient.starTwinkle(star.phase);
      final alpha =
          (star.alpha *
                  twinkle *
                  (1 + ambient.pulseValue * ambient.pulseStrength * 0.18))
              .clamp(0.0, 1.0);
      if (star.glow) {
        add(
          FxSprite.glow,
          center,
          (star.radius * 2.6) / (FxSprites.cell / 2),
          star.color.withValues(alpha: alpha * 0.12),
        );
      }
      add(
        FxSprite.dot,
        center,
        FxSprites.dotScaleFor(star.radius),
        star.color.withValues(alpha: alpha),
      );
    }
    canvas.drawRawAtlas(
      FxSprites.atlas,
      Float32List.sublistView(_transforms, 0, count * 4),
      Float32List.sublistView(_rects, 0, count * 4),
      Int32List.sublistView(_colors, 0, count),
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}
