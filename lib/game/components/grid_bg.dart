import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 큐브 그리드 영역의 라운드 블랙 배경.
class GridBg extends PositionComponent {
  GridBg({
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.topLeft);

  /// 반투명 검정 라운드 사각형으로 그리드 영역을 시각적으로 구분한다.
  @override
  void render(Canvas canvas) {
    // 반투명 검정으로 그리드 영역 시각적 분리.
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
  }
}
