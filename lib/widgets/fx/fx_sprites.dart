import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// 파티클 atlas 칸.
enum FxSprite { dot, glow, streak, coin, shard }

/// 한 번 구워 재사용하는 흰색 스프라이트.
///
/// 색은 그릴 때 modulate로 입힌다. 프레임마다 blur를 계산하지 않도록 blur는
/// 굽는 순간 한 번만 쓴다.
class FxSprites {
  FxSprites._();

  static const double cell = 64;
  static const double _half = cell / 2;

  /// dot 스프라이트에서 원의 반지름(px). 파티클 반지름을 스케일로 바꿀 때 쓴다.
  static const double dotRadius = 28;

  static ui.Image? _atlas;
  static ui.Image? _boxGlow;

  static ui.Image get atlas => _atlas ??= _bakeAtlas();

  static Rect rectOf(FxSprite sprite) =>
      Rect.fromLTWH(sprite.index * cell, 0, cell, cell);

  static ui.Image _bakeAtlas() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const white = Color(0xFFFFFFFF);
    const clear = Color(0x00FFFFFF);
    for (final sprite in FxSprite.values) {
      final center = Offset(sprite.index * cell + _half, _half);
      switch (sprite) {
        case FxSprite.dot:
          canvas.drawCircle(
            center,
            dotRadius + 2,
            Paint()
              ..shader = ui.Gradient.radial(
                center,
                dotRadius + 2,
                const [white, white, clear],
                const [0, 0.86, 1],
              ),
          );
        case FxSprite.glow:
          canvas.drawCircle(
            center,
            _half,
            Paint()
              ..shader = ui.Gradient.radial(
                center,
                _half,
                const [white, Color(0x66FFFFFF), clear],
                const [0, 0.35, 1],
              ),
          );
        case FxSprite.streak:
          canvas.drawOval(
            Rect.fromCenter(center: center, width: cell - 4, height: 12),
            Paint()
              ..shader = ui.Gradient.linear(
                center.translate(-_half, 0),
                center.translate(_half, 0),
                const [clear, white, white, clear],
                const [0, 0.35, 0.8, 1],
              ),
          );
        case FxSprite.coin:
          canvas.drawCircle(
            center,
            26,
            Paint()..color = const Color(0xFFD8D8D8),
          );
          canvas.drawCircle(
            center,
            24,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = white,
          );
          canvas.drawCircle(
            center,
            14,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = const Color(0xFFF2F2F2),
          );
        case FxSprite.shard:
          final path = Path()
            ..moveTo(center.dx, center.dy - 26)
            ..lineTo(center.dx + 11, center.dy + 4)
            ..lineTo(center.dx, center.dy + 26)
            ..lineTo(center.dx - 11, center.dy - 2)
            ..close();
          canvas.drawPath(path, Paint()..color = white);
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (cell * FxSprite.values.length).toInt(),
      cell.toInt(),
    );
    picture.dispose();
    return image;
  }

  /// 둥근 사각형 그림자를 대신하는 9-slice 글로우.
  static const double boxGlowSize = 96;
  static const double boxGlowBlur = 16;
  static const double _boxGlowInset = 32;
  static const Rect boxGlowCenter = Rect.fromLTRB(46, 46, 50, 50);

  static ui.Image get boxGlow => _boxGlow ??= _bakeBoxGlow();

  static ui.Image _bakeBoxGlow() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const inner = Rect.fromLTRB(
      _boxGlowInset,
      _boxGlowInset,
      boxGlowSize - _boxGlowInset,
      boxGlowSize - _boxGlowInset,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        // 굽는 순간 한 번만 blur한다. BoxShadow blurRadius 16과 같은 sigma다.
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          boxGlowBlur * 0.57735 + 0.5,
        ),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(boxGlowSize.toInt(), boxGlowSize.toInt());
    picture.dispose();
    return image;
  }

  /// [rect] 둘레에 [blurRadius] 크기로 번지는 글로우를 그린다.
  ///
  /// `BoxShadow(blurRadius:, spreadRadius:)`를 프레임마다 바꾸는 대신 이 함수로
  /// 구운 이미지의 크기와 투명도만 바꾼다.
  static void paintBoxGlow(
    Canvas canvas,
    Rect rect, {
    required Color color,
    required double blurRadius,
    double spreadRadius = 0,
  }) {
    if (color.a <= 0 || blurRadius <= 0) return;
    final base = rect.inflate(spreadRadius);
    if (base.width <= 0 || base.height <= 0) return;
    // 구운 이미지의 번짐 폭(inset 32px)이 blurRadius가 되도록 전체를 비례 축소한다.
    final factor = blurRadius / boxGlowBlur;
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: (base.width + blurRadius * 2 * 2) / factor,
      height: (base.height + blurRadius * 2 * 2) / factor,
    );
    canvas
      ..save()
      ..translate(base.center.dx, base.center.dy)
      ..scale(factor);
    canvas.drawImageNine(
      boxGlow,
      boxGlowCenter,
      dst,
      Paint()
        ..filterQuality = FilterQuality.low
        ..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
    );
    canvas.restore();
  }

  /// [center]에 반지름 [radius]의 둥근 글로우를 그린다.
  static void paintRoundGlow(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color color,
  }) {
    if (color.a <= 0 || radius <= 0) return;
    canvas.drawImageRect(
      atlas,
      rectOf(FxSprite.glow),
      Rect.fromCircle(center: center, radius: radius),
      Paint()
        ..filterQuality = FilterQuality.low
        ..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
    );
  }

  /// 원 반지름을 dot 스프라이트 스케일로 바꾼다.
  static double dotScaleFor(double radius) => math.max(0, radius / dotRadius);
}

/// 자식 뒤에 구운 글로우를 깐다. 애니메이션 값으로 [color]와 [blurRadius]를 바꿔도
/// layout이나 blur 재계산이 없다.
class FxBoxGlow extends StatelessWidget {
  const FxBoxGlow({
    super.key,
    required this.child,
    required this.color,
    required this.blurRadius,
    this.spreadRadius = 0,
    this.offset = Offset.zero,
  });

  final Widget child;
  final Color color;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FxBoxGlowPainter(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
      child: child,
    );
  }
}

class _FxBoxGlowPainter extends CustomPainter {
  const _FxBoxGlowPainter({
    required this.color,
    required this.blurRadius,
    required this.spreadRadius,
    required this.offset,
  });

  final Color color;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    FxSprites.paintBoxGlow(
      canvas,
      offset & size,
      color: color,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }

  @override
  bool shouldRepaint(_FxBoxGlowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.spreadRadius != spreadRadius ||
      oldDelegate.offset != offset;
}
