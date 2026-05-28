import 'package:flutter/material.dart';

import '../../logic/rummi_poker_grid/models/tile.dart';
import '../../views/game/widgets/game_ui_palette.dart';

const double kRummikubTileCornerRadiusFactor = 0.11;

double rummikubTileCornerRadiusForSide(double side) {
  return side * kRummikubTileCornerRadiusFactor;
}

/// 루미큐브 실물 타일 느낌: 크림 면, 상단 컬러 띠, 숫자는 타일 컬러.
void paintRummikubTile(
  Canvas canvas,
  Rect rect,
  Tile tile, {
  bool selected = false,
  double shadowElevation = 2.5,
}) {
  final r = rummikubTileCornerRadiusForSide(rect.shortestSide);
  final rr = RRect.fromRectAndRadius(rect, Radius.circular(r));

  if (shadowElevation > 0) {
    final path = Path()..addRRect(rr);
    canvas.drawShadow(
      path,
      GameUiPalette.ink.withValues(alpha: 0.38),
      shadowElevation,
      false,
    );
  }

  const face = GameUiPalette.tileFace;
  canvas.drawRRect(rr, Paint()..color = face);

  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = GameUiPalette.tileFaceBorder,
  );

  final pad = rect.width * 0.06;
  final inner = rect.deflate(pad);
  final barH = inner.height * 0.24;
  final barR = RRect.fromRectAndRadius(
    Rect.fromLTWH(inner.left, inner.top, inner.width, barH),
    Radius.circular(r * 0.55),
  );
  final tilePaintColor = _colorForTileColor(tile.color);
  canvas.drawRRect(barR, Paint()..color = tilePaintColor);

  final digitColor = tilePaintColor;
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
  tp.paint(canvas, Offset(inner.left + (inner.width - tp.width) / 2, digitTop));

  if (_isFaceRank(tile.number)) {
    final dotRadius = rect.shortestSide * 0.075;
    final dotCenter = Offset(
      inner.left + inner.width / 2,
      inner.bottom - dotRadius * 1.2,
    );
    canvas.drawCircle(
      dotCenter,
      dotRadius + 1.8,
      Paint()..color = GameUiPalette.textPrimary.withValues(alpha: 0.92),
    );
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = digitColor);
  }

  if (selected) {
    final ring = RRect.fromRectAndRadius(
      rect.inflate(3.5),
      Radius.circular(r + 3),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..color = GameUiPalette.tileSelectedStripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

/// 루미큐브 4색에 가깝게: 검·파·빨·주황(노랑 타일).
Color _colorForTileColor(TileColor c) {
  return switch (c) {
    TileColor.red => GameUiPalette.tileRed,
    TileColor.blue => GameUiPalette.tileBlue,
    TileColor.yellow => GameUiPalette.tileYellow,
    TileColor.black => GameUiPalette.tileBlack,
  };
}

bool _isFaceRank(int number) => number >= 11 && number <= 13;
