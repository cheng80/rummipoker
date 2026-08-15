import 'dart:math';

import 'package:flutter/material.dart';

import '../views/game/widgets/game_ui_palette.dart';

/// 우주 배경.
///
/// 별을 3개 [RepaintBoundary]로 나눠 정적으로 래스터 캐싱한다.
class StarryBackground extends StatelessWidget {
  const StarryBackground({super.key});

  static const _groupCount = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final groups = _StarPool.groups(size, _groupCount);

        return Stack(
          children: [
            // 배경 그라데이션 — 1회 paint, 래스터 캐시
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: const _GradientPainter(),
                  isComplex: true,
                  willChange: false,
                ),
              ),
            ),
            // 별 그룹 레이어 — 지속 합성 없이 정적으로 캐시한다.
            for (var i = 0; i < _groupCount; i++)
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: _StarGroupPainter(stars: groups[i]),
                    isComplex: true,
                    willChange: false,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _GradientPainter extends CustomPainter {
  const _GradientPainter();

  static const _colors = [
    GameUiPalette.starFieldDeep,
    GameUiPalette.starFieldMid,
    GameUiPalette.starFieldLight,
    GameUiPalette.starFieldMid,
    GameUiPalette.starFieldDeep,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) => false;
}

/// 한 그룹의 별을 그린다. [RepaintBoundary] 안에서 1회만 호출됨.
class _StarGroupPainter extends CustomPainter {
  const _StarGroupPainter({required this.stars});

  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final x = star.nx * size.width;
      final y = star.ny * size.height;
      final paint = Paint()..color = star.color.withValues(alpha: star.alpha);
      canvas.drawCircle(Offset(x, y), star.radius, paint);

      if (star.radius > 1.2) {
        final glowPaint = Paint()
          ..color = star.color.withValues(alpha: star.alpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), star.radius * 2.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarGroupPainter oldDelegate) =>
      !identical(oldDelegate.stars, stars);
}

// ---------------------------------------------------------------------------
// Star data pool — 정규화 좌표(0~1) 사용, 크기 무관하게 1회만 생성
// ---------------------------------------------------------------------------

class _StarPool {
  _StarPool._();

  static List<List<_Star>>? _cached;
  static int _cachedGroupCount = 0;

  static List<List<_Star>> groups(Size size, int groupCount) {
    if (_cached != null && _cachedGroupCount == groupCount) return _cached!;
    _cachedGroupCount = groupCount;
    _cached = _generate(groupCount);
    return _cached!;
  }

  static List<List<_Star>> _generate(int groupCount) {
    final rng = Random(42);
    final groups = List.generate(groupCount, (_) => <_Star>[]);

    for (var i = 0; i < 100; i++) {
      groups[i % groupCount].add(
        _Star(
          nx: rng.nextDouble(),
          ny: rng.nextDouble(),
          radius: rng.nextDouble() * 1.6 + 0.3,
          alpha: rng.nextDouble() * 0.5 + 0.3,
          color: _starColor(rng),
        ),
      );
    }

    return groups;
  }

  static Color _starColor(Random rng) {
    final roll = rng.nextDouble();
    if (roll < 0.7) return GameUiPalette.textPrimary;
    if (roll < 0.85) return GameUiPalette.starBlue;
    if (roll < 0.95) return GameUiPalette.starWarm;
    return GameUiPalette.starRed;
  }
}

class _Star {
  const _Star({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.alpha,
    required this.color,
  });

  /// 정규화 좌표 (0~1). paint 시점에 size를 곱해서 실제 좌표 산출.
  final double nx;
  final double ny;
  final double radius;
  final double alpha;
  final Color color;
}
