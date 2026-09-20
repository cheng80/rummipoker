part of 'game_shared_widgets.dart';

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
    this.reserveConstraintBadgeSpace = false,
    this.modifierBadgeScale = 1.0,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;
  final bool reserveConstraintBadgeSpace;
  final double modifierBadgeScale;

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
                child: TileMaterialSurface(tile: tile, accent: accent),
              ),
            if (tile.hasModifier)
              Positioned.fill(
                child: GameTileModifierBadges(
                  tile: tile,
                  reserveConstraintBadgeSpace: reserveConstraintBadgeSpace,
                  scale: modifierBadgeScale,
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
    this.scale = 1.0,
  });

  final Tile tile;
  final bool reserveConstraintBadgeSpace;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final enhancement = tile.enhancement;
    final seal = tile.seal;
    final edition = tile.edition;
    return IgnorePointer(
      key: const ValueKey('tile-modifier-badge-layer'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final metrics = _TileModifierBadgeMetrics.forTileSide(
            side,
            scale: scale,
          );
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
                    foreground: GameUiPalette.tileModifierBadgeText,
                    circular: true,
                    highContrast: true,
                  ),
                ),
              if (edition != null)
                Positioned(
                  key: const ValueKey('tile-edition-badge'),
                  right: metrics.editionInset,
                  top: metrics.enhancementInset,
                  child: _TileModifierBadge(
                    label: tileEditionShortLabel(edition),
                    height: metrics.badgeHeight,
                    fontSize: metrics.fontSize,
                    background: tileEditionColor(edition),
                    foreground: GameUiPalette.tileModifierBadgeText,
                    highContrast: true,
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
    required this.editionInset,
  });

  factory _TileModifierBadgeMetrics.forTileSide(
    double side, {
    double scale = 1.0,
  }) {
    final badgeHeight = (side * 0.2 * scale).clamp(11.0, 17.0).toDouble();
    return _TileModifierBadgeMetrics(
      badgeHeight: badgeHeight,
      fontSize: (badgeHeight * 0.58).clamp(6.8, 9.6).toDouble(),
      enhancementInset: -3.0,
      sealInset: (side * 0.04).clamp(1.0, 3.0).toDouble(),
      editionInset: (side * 0.04).clamp(1.0, 3.0).toDouble(),
    );
  }

  final double badgeHeight;
  final double fontSize;
  final double enhancementInset;
  final double sealInset;
  final double editionInset;
}

class _TileModifierBadge extends StatelessWidget {
  const _TileModifierBadge({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.background,
    required this.foreground,
    this.circular = false,
    this.highContrast = false,
  });

  final String label;
  final double height;
  final double fontSize;
  final Color background;
  final Color foreground;
  final bool circular;
  final bool highContrast;

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
              highContrast ? 0.48 : 0.28,
            )!,
            Color.lerp(
              GameUiPalette.tileModifierBadgeSurfaceBottom,
              background,
              highContrast ? 0.22 : 0.12,
            )!,
          ],
        ),
        border: Border.all(
          color: Color.lerp(
            GameUiPalette.tileModifierBadgeBorder,
            background,
            highContrast ? 0.22 : 0.45,
          )!,
          width: highContrast ? 1.35 : 1.15,
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
        width: circular ? height : height * 1.34,
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

String tileModifierSummary(Tile tile, {BuildContext? context}) {
  final parts = <String>[
    if (tile.enhancement != null)
      tileEnhancementDisplayName(tile.enhancement!, context: context),
    if (tile.seal != null) tileSealDisplayName(tile.seal!, context: context),
    if (tile.edition != null)
      tileEditionDisplayName(tile.edition!, context: context),
  ];
  return parts.join(' · ');
}

String tileModifierEffectText(Tile tile, {BuildContext? context}) {
  final parts = <String>[
    if (tile.enhancement != null)
      tileEnhancementEffectText(tile.enhancement!, context: context),
    if (tile.seal != null) tileSealEffectText(tile.seal!, context: context),
    if (tile.edition != null)
      tileEditionEffectText(tile.edition!, context: context),
  ];
  return parts.join(' / ');
}

List<String> tileModifierBadgeDescriptions(Tile tile, {BuildContext? context}) {
  return [
    if (tile.enhancement != null)
      '${tileEnhancementShortLabel(tile.enhancement!)} ${tileEnhancementEffectText(tile.enhancement!, context: context)}',
    if (tile.seal != null)
      '${tileSealShortLabel(tile.seal!)} ${tileSealEffectText(tile.seal!, context: context)}',
    if (tile.edition != null)
      '${tileEditionShortLabel(tile.edition!)} ${tileEditionEffectText(tile.edition!, context: context)}',
  ];
}

String tileModifierBadgeDescriptionText(Tile tile, {BuildContext? context}) {
  return tileModifierBadgeDescriptions(tile, context: context).join(' / ');
}

String tileColorDisplayName(TileColor color, {BuildContext? context}) {
  return switch (color) {
    TileColor.red => _battleWidgetTranslation(
      context,
      'battleWidgetsTileColorRed',
    ),
    TileColor.blue => _battleWidgetTranslation(
      context,
      'battleWidgetsTileColorBlue',
    ),
    TileColor.yellow => _battleWidgetTranslation(
      context,
      'battleWidgetsTileColorYellow',
    ),
    TileColor.black => _battleWidgetTranslation(
      context,
      'battleWidgetsTileColorBlack',
    ),
  };
}

String tileEnhancementShortLabel(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '+C',
    TileEnhancement.scoreGilded => '+%',
    TileEnhancement.goldTile => 'G',
    TileEnhancement.glassTile => 'x',
  };
}

String tileSealShortLabel(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => 'B',
    TileSeal.redSeal => 'R',
    TileSeal.lineMark => 'L',
    TileSeal.growthSeal => '+',
    TileSeal.goldSeal => 'G',
    TileSeal.echoSeal => 'E',
    TileSeal.anchorSeal => 'A',
    TileSeal.fractureSeal => '!',
    TileSeal.crossMemory => 'X',
    TileSeal.bridgeSeal => 'Br',
  };
}

String tileEditionShortLabel(TileEdition edition) {
  return switch (edition) {
    TileEdition.silverEdition => 'S',
    TileEdition.glowEdition => 'L',
    TileEdition.prismEdition => 'P',
  };
}

String tileEnhancementDisplayName(
  TileEnhancement enhancement, {
  BuildContext? context,
}) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementChip',
    ),
    TileEnhancement.scoreGilded => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementScore',
    ),
    TileEnhancement.goldTile => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementGold',
    ),
    TileEnhancement.glassTile => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementGlass',
    ),
  };
}

String tileSealDisplayName(TileSeal seal, {BuildContext? context}) {
  return switch (seal) {
    TileSeal.blueSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealBlue',
    ),
    TileSeal.redSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealRed',
    ),
    TileSeal.lineMark => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealLine',
    ),
    TileSeal.growthSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealGrowth',
    ),
    TileSeal.goldSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealGold',
    ),
    TileSeal.echoSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealEcho',
    ),
    TileSeal.anchorSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealAnchor',
    ),
    TileSeal.fractureSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealFracture',
    ),
    TileSeal.crossMemory => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealCross',
    ),
    TileSeal.bridgeSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealBridge',
    ),
  };
}

String tileEditionDisplayName(TileEdition edition, {BuildContext? context}) {
  return switch (edition) {
    TileEdition.silverEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionSilver',
    ),
    TileEdition.glowEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionGlow',
    ),
    TileEdition.prismEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionPrism',
    ),
  };
}

String tileEnhancementEffectText(
  TileEnhancement enhancement, {
  BuildContext? context,
}) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementChipEffect',
    ),
    TileEnhancement.scoreGilded => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementScoreEffect',
    ),
    TileEnhancement.goldTile => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementGoldEffect',
    ),
    TileEnhancement.glassTile => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEnhancementGlassEffect',
    ),
  };
}

String tileSealEffectText(TileSeal seal, {BuildContext? context}) {
  return switch (seal) {
    TileSeal.blueSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealBlueEffect',
    ),
    TileSeal.redSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealRedEffect',
    ),
    TileSeal.lineMark => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealLineEffect',
    ),
    TileSeal.growthSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealGrowthEffect',
    ),
    TileSeal.goldSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealGoldEffect',
    ),
    TileSeal.echoSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealEchoEffect',
    ),
    TileSeal.anchorSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealAnchorEffect',
    ),
    TileSeal.fractureSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealFractureEffect',
    ),
    TileSeal.crossMemory => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealCrossEffect',
    ),
    TileSeal.bridgeSeal => _battleWidgetTranslation(
      context,
      'battleWidgetsTileSealBridgeEffect',
    ),
  };
}

String tileEditionEffectText(TileEdition edition, {BuildContext? context}) {
  return switch (edition) {
    TileEdition.silverEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionSilverEffect',
    ),
    TileEdition.glowEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionGlowEffect',
    ),
    TileEdition.prismEdition => _battleWidgetTranslation(
      context,
      'battleWidgetsTileEditionPrismEffect',
    ),
  };
}

Color tileEnhancementColor(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => GameUiPalette.tileChipInlaid,
    TileEnhancement.scoreGilded => GameUiPalette.tileScoreGilded,
    TileEnhancement.goldTile => GameUiPalette.actionGoldBright,
    TileEnhancement.glassTile => GameUiPalette.tileGlass,
  };
}

Color tileSealColor(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => GameUiPalette.tileBlueSeal,
    TileSeal.redSeal => GameUiPalette.tileRedSeal,
    TileSeal.lineMark => GameUiPalette.actionGold,
    TileSeal.growthSeal => GameUiPalette.actionSuccess,
    TileSeal.goldSeal => GameUiPalette.actionGoldBright,
    TileSeal.echoSeal => GameUiPalette.tileBlueSeal,
    TileSeal.anchorSeal => GameUiPalette.tileSilverEdition,
    TileSeal.fractureSeal => GameUiPalette.actionDanger,
    TileSeal.crossMemory => GameUiPalette.rarityRare,
    TileSeal.bridgeSeal => GameUiPalette.rarityUncommon,
  };
}

Color tileEditionColor(TileEdition edition) {
  return switch (edition) {
    TileEdition.silverEdition => GameUiPalette.tileSilverEdition,
    TileEdition.glowEdition => GameUiPalette.tileGlowEdition,
    TileEdition.prismEdition => GameUiPalette.tilePrismEdition,
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
        oldDelegate.tile.enhancement != tile.enhancement ||
        oldDelegate.tile.seal != tile.seal ||
        oldDelegate.tile.edition != tile.edition ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
}
