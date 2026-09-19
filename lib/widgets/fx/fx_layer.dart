import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../views/game/widgets/game_ui_palette.dart';
import 'fx_sprites.dart';
import 'motion_policy.dart';

/// 파티클 한 번 발사의 모양·수·수명.
class FxBurstSpec {
  const FxBurstSpec({
    required this.sprite,
    required this.color,
    this.count = 12,
    this.lifetime = 0.6,
    this.speedScale = 1,
    this.sizeScale = 1,
    this.glow = false,
    this.gravity = 0,
    this.spin = 0,
    this.alignToVelocity = false,
  });

  final FxSprite sprite;
  final Color color;
  final int count;

  /// 초 단위 수명.
  final double lifetime;
  final double speedScale;
  final double sizeScale;
  final bool glow;

  /// 초당 아래 방향 가속(px/s²).
  final double gravity;

  /// 초당 최대 회전(rad/s).
  final double spin;

  /// 진행 방향으로 스프라이트를 눕힌다(sparks).
  final bool alignToVelocity;

  FxBurstSpec copyWith({Color? color, int? count}) => FxBurstSpec(
    sprite: sprite,
    color: color ?? this.color,
    count: count ?? this.count,
    lifetime: lifetime,
    speedScale: speedScale,
    sizeScale: sizeScale,
    glow: glow,
    gravity: gravity,
    spin: spin,
    alignToVelocity: alignToVelocity,
  );
}

/// 공용 파티클 프리셋.
class FxPresets {
  FxPresets._();

  /// 기존 Flame 오버레이의 라인 확정 burst.
  static const FxBurstSpec lineConfirm = FxBurstSpec(
    sprite: FxSprite.dot,
    color: GameUiPalette.actionGoldBright,
    count: 12,
    lifetime: 0.68,
    speedScale: 0.76,
    sizeScale: 0.95,
  );

  /// 기존 Flame 오버레이의 보스 제약 burst.
  static const FxBurstSpec constraintImpact = FxBurstSpec(
    sprite: FxSprite.dot,
    color: GameUiPalette.effectConstraint,
    count: 14,
    lifetime: 0.54,
    speedScale: 1.05,
    sizeScale: 1.1,
    glow: true,
  );

  /// 기존 Flame 오버레이의 큰 점수 burst.
  static const FxBurstSpec largeScore = FxBurstSpec(
    sprite: FxSprite.dot,
    color: GameUiPalette.settlementActive,
    count: 18,
    lifetime: 0.72,
    speedScale: 1.18,
    sizeScale: 1.18,
    glow: true,
  );

  static const FxBurstSpec burst = FxBurstSpec(
    sprite: FxSprite.dot,
    color: GameUiPalette.textPrimary,
    count: 10,
    lifetime: 0.5,
    glow: true,
  );

  static const FxBurstSpec sparks = FxBurstSpec(
    sprite: FxSprite.streak,
    color: GameUiPalette.actionGoldBright,
    count: 10,
    lifetime: 0.42,
    speedScale: 1.6,
    sizeScale: 1.4,
    alignToVelocity: true,
  );

  static const FxBurstSpec coins = FxBurstSpec(
    sprite: FxSprite.coin,
    color: GameUiPalette.actionGoldBright,
    count: 8,
    lifetime: 0.8,
    speedScale: 1.1,
    sizeScale: 1.8,
    gravity: 420,
    spin: 6,
  );

  static const FxBurstSpec shards = FxBurstSpec(
    sprite: FxSprite.shard,
    color: GameUiPalette.particleDanger,
    count: 9,
    lifetime: 0.6,
    speedScale: 1.3,
    sizeScale: 1.6,
    gravity: 260,
    spin: 9,
  );
}

class _FxParticle {
  _FxParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.spec,
    required this.rotation,
    required this.spinRate,
  });

  double x;
  double y;
  double vx;
  double vy;
  double age = 0;
  double rotation;
  final double spinRate;
  final double radius;
  final Color color;
  final FxBurstSpec spec;
}

/// 화면 전체 파티클 상태. 좌표는 앱 루트 기준 논리 px다.
class FxController extends ChangeNotifier {
  FxController({math.Random? random}) : _rng = random ?? math.Random();

  static const int maxParticles = 600;
  static const List<Color> _accentColors = [
    GameUiPalette.textPrimary,
    GameUiPalette.actionGoldBright,
    GameUiPalette.settlementActive,
    GameUiPalette.particleDanger,
    GameUiPalette.boardMoveSource,
  ];

  final math.Random _rng;
  final List<_FxParticle> _particles = [];
  VoidCallback? _wake;

  int get particleCount => _particles.length;
  bool get isIdle => _particles.isEmpty;
  bool get hasHost => _wake != null;

  /// [globalPoints]마다 [spec] 파티클을 발사한다. [scale]은 화면 배율(프레임 축소 등)이다.
  ///
  /// 호스트([FxLayer])가 없거나 연출 강도가 꺼져 있으면 무시한다.
  void emit(
    FxBurstSpec spec,
    Iterable<Offset> globalPoints, {
    double scale = 1,
  }) {
    final wake = _wake;
    if (wake == null) return;
    final count = (spec.count * MotionPolicy.particleScale).round();
    if (count <= 0) return;
    for (final point in globalPoints) {
      for (var i = 0; i < count; i++) {
        if (_particles.length >= maxParticles) _particles.removeAt(0);
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed = (_rng.nextDouble() * 120 + 52) * spec.speedScale * scale;
        _particles.add(
          _FxParticle(
            x: point.dx,
            y: point.dy,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed,
            radius: (_rng.nextDouble() * 2.4 + 0.9) * spec.sizeScale * scale,
            color: _tweakColor(spec.color),
            spec: spec,
            rotation: spec.alignToVelocity ? angle : _rng.nextDouble() * 6.28,
            spinRate: (_rng.nextDouble() * 2 - 1) * spec.spin,
          ),
        );
      }
    }
    wake();
  }

  Color _tweakColor(Color base) {
    if (_rng.nextDouble() < 0.3) {
      final accent = _accentColors[_rng.nextInt(_accentColors.length)];
      return Color.lerp(base, accent, 0.32 + _rng.nextDouble() * 0.28)!;
    }
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + _rng.nextDouble() * 0.34).clamp(0, 1))
        .withSaturation(
          (hsl.saturation + _rng.nextDouble() * 0.18 - 0.08).clamp(0, 1),
        )
        .toColor();
  }

  /// [dt]초만큼 진행한다. 프레임당 0.94 감속(60fps 기준)을 시간 기준으로 바꿔 쓴다.
  void advance(double dt) {
    if (_particles.isEmpty) return;
    final drag = math.pow(0.94, dt * 60).toDouble();
    _particles.removeWhere((p) {
      p.age += dt;
      if (p.age >= p.spec.lifetime) return true;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= drag;
      p.vy = p.vy * drag + p.spec.gravity * dt;
      if (p.spec.alignToVelocity) {
        p.rotation = math.atan2(p.vy, p.vx);
      } else {
        p.rotation += p.spinRate * dt;
      }
      return false;
    });
    notifyListeners();
  }

  void clear() {
    _particles.clear();
    notifyListeners();
  }

  /// 테스트 사이에 파티클과 호스트 wake 콜백이 남지 않게 초기 상태로 되돌린다.
  @visibleForTesting
  void debugReset() {
    _particles.clear();
    _wake = null;
  }

  // drawRawAtlas 버퍼. 프레임마다 새로 만들지 않도록 키워서 재사용한다.
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);

  void _paint(Canvas canvas) {
    if (_particles.isEmpty) return;
    var capacity = 0;
    for (final p in _particles) {
      capacity += p.spec.glow ? 3 : 1;
    }
    if (_colors.length < capacity) {
      _transforms = Float32List(capacity * 4);
      _rects = Float32List(capacity * 4);
      _colors = Int32List(capacity);
    }
    var n = 0;
    void add(
      FxSprite sprite,
      double x,
      double y,
      double scale,
      double rot,
      Color color,
    ) {
      final rect = FxSprites.rectOf(sprite);
      final scos = math.cos(rot) * scale;
      final ssin = math.sin(rot) * scale;
      const anchor = FxSprites.cell / 2;
      final i = n * 4;
      _transforms[i] = scos;
      _transforms[i + 1] = ssin;
      _transforms[i + 2] = x - scos * anchor + ssin * anchor;
      _transforms[i + 3] = y - ssin * anchor - scos * anchor;
      _rects[i] = rect.left;
      _rects[i + 1] = rect.top;
      _rects[i + 2] = rect.right;
      _rects[i + 3] = rect.bottom;
      _colors[n] = color.toARGB32();
      n++;
    }

    for (final p in _particles) {
      final progress = (p.age / p.spec.lifetime).clamp(0.0, 1.0);
      final alpha = progress < 0.2 ? 1.0 : 1.0 - ((progress - 0.2) / 0.8);
      final r = p.radius * (1.0 - progress * 0.3);
      final showGlow = p.spec.glow && progress < 0.72;
      if (showGlow && r > 1.5) {
        add(
          FxSprite.dot,
          p.x,
          p.y,
          FxSprites.dotScaleFor(r * 1.65),
          0,
          p.color.withValues(alpha: alpha * 0.12),
        );
      }
      if (showGlow && r > 1.9) {
        // 예전 MaskFilter.blur(4) 글로우를 구운 글로우 스프라이트로 대신한다.
        add(
          FxSprite.glow,
          p.x,
          p.y,
          (r * 2.0 + 4) / (FxSprites.cell / 2),
          0,
          p.color.withValues(alpha: alpha * 0.2),
        );
      }
      final scale = p.spec.sprite == FxSprite.dot
          ? FxSprites.dotScaleFor(r)
          : r / (FxSprites.cell / 2);
      add(
        p.spec.sprite,
        p.x,
        p.y,
        scale,
        p.rotation,
        p.color.withValues(alpha: alpha),
      );
    }
    canvas.drawRawAtlas(
      FxSprites.atlas,
      Float32List.sublistView(_transforms, 0, n * 4),
      Float32List.sublistView(_rects, 0, n * 4),
      Int32List.sublistView(_colors, 0, n),
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }
}

/// 전역 파티클 진입점.
class Fx {
  Fx._();

  static final FxController controller = FxController();

  /// 전역 [controller]를 테스트용으로 초기화한다.
  @visibleForTesting
  static void debugReset() => controller.debugReset();

  /// [context]의 로컬 좌표 [localPoints]에 파티클을 발사한다.
  static void emit(
    BuildContext context,
    FxBurstSpec spec,
    Iterable<Offset> localPoints,
  ) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final scale = box.getTransformTo(null).getMaxScaleOnAxis();
    controller.emit(spec, [
      for (final point in localPoints) box.localToGlobal(point),
    ], scale: scale);
  }
}

/// 전체 화면을 덮는 파티클 레이어. 앱에 하나만 둔다.
///
/// `repaint:` Listenable로만 다시 그려 build·layout을 건너뛰고, 그릴 것이 없으면
/// 티커를 멈춘다.
class FxLayer extends StatefulWidget {
  const FxLayer({super.key, this.controller});

  final FxController? controller;

  @override
  State<FxLayer> createState() => _FxLayerState();
}

class _FxLayerState extends State<FxLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  FxController get _controller => widget.controller ?? Fx.controller;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _controller._wake = _wake;
  }

  void _wake() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _controller.advance(dt);
    if (_controller.isIdle) _ticker.stop();
  }

  @override
  void dispose() {
    if (_controller._wake == _wake) _controller._wake = null;
    _controller.clear();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FxPainter(_controller),
        ),
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.controller) : super(repaint: controller);

  final FxController controller;

  @override
  void paint(Canvas canvas, Size size) => controller._paint(canvas);

  @override
  bool shouldRepaint(_FxPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
