import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 전투 보드 위에 짧게 터지는 파티클 묶음.
///
/// 저장 가능한 게임 상태와 무관한 presentation 전용 컴포넌트이며, 수명이 끝나면
/// 제거하지 않고 풀에 반납해 Component add/remove 부담을 줄인다.
class RummiParticleBurst extends PositionComponent {
  RummiParticleBurst();

  static final Random _rng = Random();
  static const MaskFilter _glowBlur = MaskFilter.blur(BlurStyle.normal, 4);
  static const List<Color> _accentColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF2C14E),
    Color(0xFF86F4C3),
    Color(0xFFFF8E7E),
    Color(0xFF5EE7F7),
  ];

  final List<_RummiParticle> _particles = [];
  final Paint _paint = Paint();

  void Function(RummiParticleBurst)? _onExpired;
  Color _baseColor = Colors.white;
  int _count = 8;
  double _lifetime = 0.4;
  double _speedScale = 1;
  double _sizeScale = 1;
  double _elapsed = 0;
  bool _active = false;
  bool _withGlow = false;

  void activate({
    required Vector2 center,
    required Color baseColor,
    int count = 8,
    double lifetime = 0.4,
    double speedScale = 1,
    double sizeScale = 1,
    bool withGlow = false,
  }) {
    position = center;
    _baseColor = baseColor;
    _count = count;
    _lifetime = lifetime;
    _speedScale = speedScale;
    _sizeScale = sizeScale;
    _withGlow = withGlow;
    _elapsed = 0;
    _active = true;
    _resetParticles();
  }

  @override
  Future<void> onLoad() async {
    priority = 100;
  }

  void _resetParticles() {
    while (_particles.length < _count) {
      _particles.add(_RummiParticle());
    }
    for (var i = 0; i < _count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = (_rng.nextDouble() * 120 + 52) * _speedScale;
      final color = _tweakColor(_baseColor);
      _particles[i].reset(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        radius: (_rng.nextDouble() * 2.4 + 0.9) * _sizeScale,
        color: color,
      );
    }
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

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _elapsed += dt;
    if (_elapsed >= _lifetime) {
      _active = false;
      _onExpired?.call(this);
      return;
    }

    for (var i = 0; i < _count; i++) {
      final p = _particles[i];
      p.x += p.dx * dt;
      p.y += p.dy * dt;
      p.dx *= 0.94;
      p.dy *= 0.94;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final progress = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = progress < 0.2 ? 1.0 : 1.0 - ((progress - 0.2) / 0.8);
    final showGlow = _withGlow && progress < 0.72;

    for (var i = 0; i < _count; i++) {
      final p = _particles[i];
      final r = p.radius * (1.0 - progress * 0.3);
      if (showGlow && r > 1.5) {
        _paint
          ..color = p.color.withValues(alpha: alpha * 0.12)
          ..maskFilter = null;
        canvas.drawCircle(Offset(p.x, p.y), r * 1.65, _paint);
      }
      _paint
        ..color = p.color.withValues(alpha: alpha)
        ..maskFilter = null;
      canvas.drawCircle(Offset(p.x, p.y), r, _paint);
      if (showGlow && r > 1.9) {
        _paint
          ..color = p.color.withValues(alpha: alpha * 0.2)
          ..maskFilter = _glowBlur;
        canvas.drawCircle(Offset(p.x, p.y), r * 2.0, _paint);
        _paint.maskFilter = null;
      }
    }
  }
}

class _RummiParticle {
  double x = 0;
  double y = 0;
  double dx = 0;
  double dy = 0;
  double radius = 1;
  Color color = Colors.white;

  void reset({
    required double dx,
    required double dy,
    required double radius,
    required Color color,
  }) {
    x = 0;
    y = 0;
    this.dx = dx;
    this.dy = dy;
    this.radius = radius;
    this.color = color;
  }
}

/// [RummiParticleBurst]를 재사용하기 위한 작은 풀.
class RummiParticlePool {
  RummiParticlePool(this._parent);

  final Component _parent;
  final List<RummiParticleBurst> _pool = [];

  void spawn({
    required Vector2 center,
    required Color baseColor,
    int count = 8,
    double lifetime = 0.4,
    double speedScale = 1,
    double sizeScale = 1,
    bool withGlow = false,
  }) {
    final burst = _pool.isNotEmpty ? _pool.removeLast() : _createBurst();
    burst.activate(
      center: center,
      baseColor: baseColor,
      count: count,
      lifetime: lifetime,
      speedScale: speedScale,
      sizeScale: sizeScale,
      withGlow: withGlow,
    );
    if (!burst.isMounted) {
      _parent.add(burst);
    }
  }

  RummiParticleBurst _createBurst() {
    final burst = RummiParticleBurst();
    burst._onExpired = _pool.add;
    return burst;
  }
}
