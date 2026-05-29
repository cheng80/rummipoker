part of 'game_shared_widgets.dart';

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
    this.reserveConstraintBadgeSpace = false,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;
  final bool reserveConstraintBadgeSpace;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GameRummiTilePainter(
                  tile: tile,
                  selected: selected,
                  accent: accent,
                ),
              ),
            ),
            if (tile.hasModifier)
              Positioned.fill(
                child: GameTileModifierBadges(
                  tile: tile,
                  reserveConstraintBadgeSpace: reserveConstraintBadgeSpace,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GameTileModifierBadges extends StatelessWidget {
  const GameTileModifierBadges({
    super.key,
    required this.tile,
    this.reserveConstraintBadgeSpace = false,
  });

  final Tile tile;
  final bool reserveConstraintBadgeSpace;

  @override
  Widget build(BuildContext context) {
    final enhancement = tile.enhancement;
    final seal = tile.seal;
    return IgnorePointer(
      key: const ValueKey('tile-modifier-badge-layer'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final metrics = _TileModifierBadgeMetrics.forTileSide(side);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (enhancement != null)
                Positioned(
                  key: const ValueKey('tile-enhancement-badge'),
                  left: metrics.enhancementInset,
                  top: metrics.enhancementInset,
                  child: _TileModifierBadge(
                    label: tileEnhancementShortLabel(enhancement),
                    height: metrics.badgeHeight,
                    fontSize: metrics.fontSize,
                    background: tileEnhancementColor(enhancement),
                    foreground: GameUiPalette.tileModifierBadgeText,
                  ),
                ),
              if (seal != null)
                Positioned(
                  key: const ValueKey('tile-seal-badge'),
                  right: metrics.sealInset,
                  bottom: metrics.sealInset,
                  child: _TileModifierBadge(
                    label: tileSealShortLabel(seal),
                    height: metrics.badgeHeight,
                    fontSize: metrics.fontSize,
                    background: tileSealColor(seal),
                    foreground: GameUiPalette.textPrimary,
                    circular: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TileModifierBadgeMetrics {
  const _TileModifierBadgeMetrics({
    required this.badgeHeight,
    required this.fontSize,
    required this.enhancementInset,
    required this.sealInset,
  });

  factory _TileModifierBadgeMetrics.forTileSide(double side) {
    final badgeHeight = (side * 0.2).clamp(11.0, 13.0).toDouble();
    return _TileModifierBadgeMetrics(
      badgeHeight: badgeHeight,
      fontSize: (badgeHeight * 0.58).clamp(6.8, 8.2).toDouble(),
      enhancementInset: -1.0,
      sealInset: (side * 0.04).clamp(1.0, 3.0).toDouble(),
    );
  }

  final double badgeHeight;
  final double fontSize;
  final double enhancementInset;
  final double sealInset;
}

class _TileModifierBadge extends StatelessWidget {
  const _TileModifierBadge({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.background,
    required this.foreground,
    this.circular = false,
  });

  final String label;
  final double height;
  final double fontSize;
  final Color background;
  final Color foreground;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(circular ? 999 : height * 0.36);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              GameUiPalette.tileModifierBadgeSurfaceTop,
              background,
              0.28,
            )!,
            Color.lerp(
              GameUiPalette.tileModifierBadgeSurfaceBottom,
              background,
              0.12,
            )!,
          ],
        ),
        border: Border.all(
          color: Color.lerp(
            GameUiPalette.tileModifierBadgeBorder,
            background,
            0.45,
          )!,
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.34),
            blurRadius: 5.5,
            spreadRadius: -0.8,
          ),
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.34),
            blurRadius: 4,
            offset: const Offset(0, 1.2),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        width: circular ? height : height * 1.45,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

String tileModifierSummary(Tile tile) {
  final parts = <String>[
    if (tile.enhancement != null) tileEnhancementDisplayName(tile.enhancement!),
    if (tile.seal != null) tileSealDisplayName(tile.seal!),
  ];
  return parts.join(' · ');
}

String tileModifierEffectText(Tile tile) {
  final parts = <String>[
    if (tile.enhancement != null) tileEnhancementEffectText(tile.enhancement!),
    if (tile.seal != null) tileSealEffectText(tile.seal!),
  ];
  return parts.join(' / ');
}

String tileColorDisplayName(TileColor color) {
  return switch (color) {
    TileColor.red => '빨간 타일',
    TileColor.blue => '파란 타일',
    TileColor.yellow => '노란 타일',
    TileColor.black => '검은 타일',
  };
}

String tileEnhancementShortLabel(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '+C',
    TileEnhancement.scoreGilded => '+%',
    TileEnhancement.goldTile => 'G',
    TileEnhancement.glassTile => 'x',
    TileEnhancement.wildPainted => 'W',
    TileEnhancement.luckyTile => '?',
  };
}

String tileSealShortLabel(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => 'B',
    TileSeal.redSeal => 'R',
  };
}

String tileEnhancementDisplayName(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '칩 박힘',
    TileEnhancement.scoreGilded => '점수 도금',
    TileEnhancement.goldTile => '골드',
    TileEnhancement.glassTile => '유리',
    TileEnhancement.wildPainted => '와일드',
    TileEnhancement.luckyTile => '럭키',
  };
}

String tileSealDisplayName(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => '푸른 인장',
    TileSeal.redSeal => '붉은 인장',
  };
}

String tileEnhancementEffectText(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '확정 시 +20칩',
    TileEnhancement.scoreGilded => '확정 시 점수 +20%',
    TileEnhancement.goldTile => '확정 후 골드 +1',
    TileEnhancement.glassTile => '확정 시 점수 x1.5',
    TileEnhancement.wildPainted => '색상 판정 확장 예정',
    TileEnhancement.luckyTile => '확률 발동 예정',
  };
}

String tileSealEffectText(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => '확정 족보 성장 +1',
    TileSeal.redSeal => '타일 효과 1회 재발동',
  };
}

Color tileEnhancementColor(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => GameUiPalette.tileChipInlaid,
    TileEnhancement.scoreGilded => GameUiPalette.tileScoreGilded,
    TileEnhancement.goldTile => GameUiPalette.actionGoldBright,
    TileEnhancement.glassTile => GameUiPalette.tileGlass,
    TileEnhancement.wildPainted => GameUiPalette.tileWild,
    TileEnhancement.luckyTile => GameUiPalette.tileLucky,
  };
}

Color tileSealColor(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => GameUiPalette.tileBlueSeal,
    TileSeal.redSeal => GameUiPalette.tileRedSeal,
  };
}

class _GameRummiTilePainter extends CustomPainter {
  const _GameRummiTilePainter({
    required this.tile,
    required this.selected,
    required this.accent,
  });

  final Tile tile;
  final bool selected;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintRummikubTile(
      canvas,
      rect,
      tile,
      selected: selected,
      shadowElevation: selected ? 4 : 2.4,
    );

    if (!accent) return;
    final accentRect = rect.deflate(3.5);
    final rr = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = GameUiPalette.actionGoldBright.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _GameRummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
}
