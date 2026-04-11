import 'package:flutter/material.dart';

import '../../logic/rummi_poker_grid/models/tile.dart';

/// 루미큐브 실물 타일 느낌: 크림 면, 상단 컬러 띠, 숫자는 슈트 색.
void paintRummikubTile(
  Canvas canvas,
  Rect rect,
  Tile tile, {
  bool selected = false,
  double shadowElevation = 2.5,
}) {
  final r = rect.shortestSide * 0.11;
  final rr = RRect.fromRectAndRadius(rect, Radius.circular(r));

  if (shadowElevation > 0) {
    final path = Path()..addRRect(rr);
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.38),
      shadowElevation,
      false,
    );
  }

  const face = Color(0xFFF2EDE6);
  canvas.drawRRect(rr, Paint()..color = face);

  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFC5BDB0),
  );

  final pad = rect.width * 0.06;
  final inner = rect.deflate(pad);
  final barH = inner.height * 0.24;
  final barR = RRect.fromRectAndRadius(
    Rect.fromLTWH(inner.left, inner.top, inner.width, barH),
    Radius.circular(r * 0.55),
  );
  canvas.drawRRect(barR, Paint()..color = _suitColor(tile.color));

  final digitColor = _suitColor(tile.color);
  final bodyH = inner.height - barH;
  final fontSize = bodyH * 0.72;
  final tp = TextPainter(
    text: TextSpan(
      text: '${tile.number}',
      style: TextStyle(
        color: digitColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final digitTop = inner.top + barH + (bodyH - tp.height) * 0.42;
  tp.paint(
    canvas,
    Offset(
      inner.left + (inner.width - tp.width) / 2,
      digitTop,
    ),
  );

  if (selected) {
    final ring = RRect.fromRectAndRadius(
      rect.inflate(3.5),
      Radius.circular(r + 3),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

/// 루미큐브 4색에 가깝게: 검·파·빨·주황(노랑 슈트).
Color _suitColor(TileColor c) {
  return switch (c) {
    TileColor.red => const Color(0xFFC62828),
    TileColor.blue => const Color(0xFF1565C0),
    TileColor.yellow => const Color(0xFFE65100),
    TileColor.black => const Color(0xFF212121),
  };
}
