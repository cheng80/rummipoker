part of '../game_view.dart';

class _ItemEffectFeedback {
  const _ItemEffectFeedback({
    required this.title,
    required this.detail,
    this.sourceLabel,
    required this.passive,
    this.fateTransform = false,
  });

  final String title;
  final String detail;
  final String? sourceLabel;
  final bool passive;
  final bool fateTransform;
}

class _ItemEffectFeedbackToast extends StatelessWidget {
  const _ItemEffectFeedbackToast({super.key, required this.feedback});

  final _ItemEffectFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final accent = feedback.passive
        ? GameUiPalette.marketSourcePassive
        : GameUiPalette.actionGold;
    return KeyedSubtree(
      key: feedback.fateTransform
          ? const ValueKey('fate-line-transform-result-feedback')
          : const ValueKey('item-effect-feedback-toast'),
      child:
          Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 16,
                    top: -12,
                    child: _ItemEffectSparkBurst(accent: accent),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GameUiPalette.surfaceDark.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.75),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: GameUiPalette.ink.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            feedback.passive
                                ? Icons.shield_rounded
                                : Icons.bolt_rounded,
                            color: accent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (feedback.sourceLabel != null) ...[
                                  DecoratedBox(
                                    key: const ValueKey(
                                      'item-effect-source-label',
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.52),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      child: Text(
                                        feedback.sourceLabel!,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _ItemEffectSourceToResultTrail(
                                    accent: accent,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  feedback.title,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: GameUiPalette.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  feedback.detail,
                                  key: const ValueKey(
                                    'item-effect-result-label',
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (feedback.passive)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                child: Text(
                                  '패시브',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(
                duration: GamePresentationTimings.itemEffectToastIn,
                curve: Curves.easeOutCubic,
              )
              .slideY(
                begin: 0.12,
                end: 0,
                duration: GamePresentationTimings.itemEffectToastIn,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}

enum _RitualEffectFlightKind { gold, deck }

const double _ritualDeckFlightHoldEnd = 0.65;
const double _ritualDeckFlightPopEnd = 0.14;
const double _ritualDeckFlightLargeScale = 1.75;
const double _ritualDeckFlightEndScale = 0.72;

class _RitualEffectFlight {
  const _RitualEffectFlight._({
    required this.kind,
    this.gold = 0,
    this.tiles = const [],
  });

  const _RitualEffectFlight.gold(int gold)
    : this._(kind: _RitualEffectFlightKind.gold, gold: gold);

  const _RitualEffectFlight.deck(List<Tile> tiles)
    : this._(kind: _RitualEffectFlightKind.deck, tiles: tiles);

  final _RitualEffectFlightKind kind;
  final int gold;
  final List<Tile> tiles;
}

class _RitualEffectFlightOverlay extends StatelessWidget {
  const _RitualEffectFlightOverlay({super.key, required this.flight});

  final _RitualEffectFlight flight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final start = flight.kind == _RitualEffectFlightKind.deck
              ? Offset(size.width * 0.50, size.height * 0.48)
              : Offset(size.width * 0.50, size.height * 0.54);
          final end = flight.kind == _RitualEffectFlightKind.gold
              ? Offset(size.width * 0.88, 72)
              : Offset(size.width * 0.18, size.height - 92);
          final isDeckFlight = flight.kind == _RitualEffectFlightKind.deck;
          final duration = isDeckFlight
              ? GamePresentationTimings.ritualDeckTileFlight
              : GamePresentationTimings.ritualGoldFlight;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: duration,
            curve: Curves.linear,
            builder: (context, value, child) {
              if (!isDeckFlight) {
                return _RitualGoldCoinFlights(
                  progress: value,
                  start: start,
                  end: end,
                  gold: flight.gold,
                );
              }
              final travel =
                  ((value - _ritualDeckFlightHoldEnd) /
                          (1 - _ritualDeckFlightHoldEnd))
                      .clamp(0.0, 1.0);
              final easedTravel = GamePresentationMotion.flightProgress(travel);
              final offset = GamePresentationMotion.flightOffset(
                start,
                end,
                travel,
              );
              final arc = math.sin(easedTravel * math.pi) * -46;
              final pulse = math.sin(value * math.pi);
              final opacity = isDeckFlight
                  ? (value < 0.92 ? 1.0 : (1 - value) / 0.08)
                  : (value < 0.92 ? 1.0 : (1 - value) / 0.08);
              final scale = isDeckFlight
                  ? _ritualDeckFlightScale(value)
                  : 1 + pulse * 0.12;
              return Stack(
                children: [
                  Positioned(
                    key: ValueKey(
                      flight.kind == _RitualEffectFlightKind.gold
                          ? 'ritual-gold-flight'
                          : 'ritual-deck-flight',
                    ),
                    left: offset.dx - (isDeckFlight ? 68 : 42),
                    top: offset.dy + arc - (isDeckFlight ? 42 : 30),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                ],
              );
            },
            child: flight.kind == _RitualEffectFlightKind.gold
                ? null
                : _RitualDeckTileFlightPayload(tiles: flight.tiles),
          );
        },
      ),
    );
  }
}

double _ritualDeckFlightScale(double value) {
  if (value < _ritualDeckFlightPopEnd) {
    return 1.2 +
        Curves.easeOutBack.transform(value / _ritualDeckFlightPopEnd) *
            (_ritualDeckFlightLargeScale - 1.2);
  }
  if (value < _ritualDeckFlightHoldEnd) return _ritualDeckFlightLargeScale;
  final travel =
      ((value - _ritualDeckFlightHoldEnd) / (1 - _ritualDeckFlightHoldEnd))
          .clamp(0.0, 1.0);
  return _ritualDeckFlightLargeScale +
      (_ritualDeckFlightEndScale - _ritualDeckFlightLargeScale) *
          GamePresentationMotion.flightProgress(travel);
}

class _RitualGoldCoinFlights extends StatelessWidget {
  const _RitualGoldCoinFlights({
    required this.progress,
    required this.start,
    required this.end,
    required this.gold,
  });

  final double progress;
  final Offset start;
  final Offset end;
  final int gold;

  @override
  Widget build(BuildContext context) {
    final coinCount = gold.clamp(3, 7);
    return Stack(
      key: const ValueKey('ritual-gold-flight'),
      children: [
        for (var i = 0; i < coinCount; i++)
          _RitualGoldCoin(
            key: ValueKey('ritual-gold-flight-coin-$i'),
            progress: progress,
            start: start + Offset((i - 2) * 8.0, (i.isEven ? -10 : 4)),
            end: end + Offset((i % 3 - 1) * 9.0, (i - 3) * 2.0),
            delay: i * 0.055,
            size: 22 + (i % 3) * 2,
          ),
        Positioned(
          left: end.dx - 40,
          top: end.dy + 22,
          child: Opacity(
            opacity: progress < 0.68
                ? 0.0
                : ((progress - 0.68) / 0.18).clamp(0.0, 1.0),
            child: MarketGoldGainBadge(gold: gold),
          ),
        ),
      ],
    );
  }
}

class _RitualGoldCoin extends StatelessWidget {
  const _RitualGoldCoin({
    super.key,
    required this.progress,
    required this.start,
    required this.end,
    required this.delay,
    required this.size,
  });

  final double progress;
  final Offset start;
  final Offset end;
  final double delay;
  final double size;

  @override
  Widget build(BuildContext context) {
    final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    final eased = GamePresentationMotion.flightProgress(local);
    final offset = GamePresentationMotion.flightOffset(start, end, local);
    final arc = math.sin(eased * math.pi) * -64;
    final opacity = local < 0.92 ? 1.0 : (1 - local) / 0.08;
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy + arc - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: eased * math.pi * 2.2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  GameUiPalette.textPrimary,
                  GameUiPalette.actionGoldBright,
                  GameUiPalette.actionGold,
                ],
                center: Alignment(-0.35, -0.45),
              ),
              border: Border.all(
                color: GameUiPalette.actionGoldText.withValues(alpha: 0.85),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.actionGold.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameUiPalette.actionGoldText.withValues(
                        alpha: 0.55,
                      ),
                      width: 1,
                    ),
                  ),
                  child: SizedBox(width: size * 0.46, height: size * 0.46),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualDeckTileFlightPayload extends StatelessWidget {
  const _RitualDeckTileFlightPayload({required this.tiles});

  final List<Tile> tiles;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameUiPalette.tileBlueSeal, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.tileBlueSeal.withValues(alpha: 0.24),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in tiles.take(2).indexed) ...[
              SizedBox(
                key: ValueKey(
                  'ritual-deck-flight-tile-${entry.$1}-${entry.$2.code}',
                ),
                width: 34,
                height: 44,
                child: GameRummiTileCard(
                  tile: entry.$2,
                  selected: false,
                  accent: true,
                  aspectRatio: kGameTileAspectRatio,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              '덱 +${tiles.length}',
              style: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEffectSparkBurst extends StatelessWidget {
  const _ItemEffectSparkBurst({required this.accent});

  final Color accent;

  static const List<Offset> _targets = [
    Offset(-14, -10),
    Offset(2, -18),
    Offset(18, -8),
    Offset(24, 8),
    Offset(-8, 12),
  ];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('item-effect-spark-burst'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.itemEffectSparkBurst,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final opacity = value < 0.7 ? 1.0 : (1 - value) / 0.3;
        return SizedBox(
          width: 52,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _targets.length; i++)
                Positioned(
                  left: 22 + _targets[i].dx * value,
                  top:
                      18 +
                      _targets[i].dy * value -
                      math.sin(value * math.pi) * 4,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: value * math.pi * (i.isEven ? 0.35 : -0.3),
                      child: _ItemEffectSpark(accent: accent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemEffectSpark extends StatelessWidget {
  const _ItemEffectSpark({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 7),
        ],
      ),
      child: const SizedBox(width: 4, height: 10),
    );
  }
}

class _ItemEffectSourceToResultTrail extends StatelessWidget {
  const _ItemEffectSourceToResultTrail({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('item-effect-source-result-trail'),
      height: 12,
      width: 118,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.itemEffectSparkBurst,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: accent.withValues(alpha: 0.34),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8 + (74 * value),
                  top: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final opacity = (0.34 + (index * 0.22)).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: accent.withValues(alpha: opacity),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
