import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';

class GameHandZone extends StatefulWidget {
  const GameHandZone({
    super.key,
    required this.battle,
    required this.station,
    required this.hand,
    required this.selectedHandTile,
    required this.onHandTileTap,
    required this.onDraw,
    required this.tileWidth,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final List<Tile> hand;
  final Tile? selectedHandTile;
  final ValueChanged<Tile> onHandTileTap;
  final VoidCallback onDraw;
  final double tileWidth;

  @override
  State<GameHandZone> createState() => _GameHandZoneState();
}

class _GameHandZoneState extends State<GameHandZone>
    with TickerProviderStateMixin {
  static const Duration _handAnimDuration =
      GamePresentationTimings.handTileTransition;

  late final AnimationController _controller;
  late final AnimationController _capacityController;
  List<Tile> _settledHand = <Tile>[];
  List<Tile> _fromHand = <Tile>[];
  List<Tile> _toHand = <Tile>[];
  Tile? _incomingTile;
  Tile? _discardingTile;
  bool _animating = false;
  int _capacityGain = 0;

  @override
  void initState() {
    super.initState();
    _settledHand = List<Tile>.from(widget.hand);
    _controller = AnimationController(vsync: this, duration: _handAnimDuration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        setState(() {
          _settledHand = List<Tile>.from(_toHand);
          _fromHand = List<Tile>.from(_toHand);
          _incomingTile = null;
          _discardingTile = null;
          _animating = false;
        });
      });
    _capacityController =
        AnimationController(
          vsync: this,
          duration: GamePresentationTimings.handCapacityPulse,
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed || !mounted) return;
          setState(() => _capacityGain = 0);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameHandZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCapacity = oldWidget.station.resources.maxHandSize;
    final newCapacity = widget.station.resources.maxHandSize;
    if (newCapacity > oldCapacity) {
      setState(() => _capacityGain = newCapacity - oldCapacity);
      _capacityController
        ..stop()
        ..value = 0
        ..forward();
    }
    if (_sameTileKeys(oldWidget.hand, widget.hand)) {
      return;
    }

    final oldKeys = oldWidget.hand.map(_handTileKey).toSet();
    final newKeys = widget.hand.map(_handTileKey).toSet();
    final addedKeys = newKeys.difference(oldKeys);
    final removedKeys = oldKeys.difference(newKeys);
    final isSimpleAppend =
        widget.hand.length == oldWidget.hand.length + 1 &&
        addedKeys.length == 1;
    final isOneForOneReplacement =
        widget.hand.length == oldWidget.hand.length &&
        addedKeys.length == 1 &&
        removedKeys.length == 1;
    final isSingleRemoval =
        widget.hand.length == oldWidget.hand.length - 1 &&
        addedKeys.isEmpty &&
        removedKeys.length == 1;

    if (!isSimpleAppend && !isOneForOneReplacement && !isSingleRemoval) {
      _controller.stop();
      setState(() {
        _settledHand = List<Tile>.from(widget.hand);
        _fromHand = List<Tile>.from(widget.hand);
        _toHand = List<Tile>.from(widget.hand);
        _incomingTile = null;
        _discardingTile = null;
        _animating = false;
      });
      return;
    }

    final incoming = addedKeys.isEmpty
        ? null
        : widget.hand.firstWhere(
            (tile) => addedKeys.contains(_handTileKey(tile)),
          );
    final discarding = removedKeys.isEmpty
        ? null
        : oldWidget.hand.firstWhere(
            (tile) => removedKeys.contains(_handTileKey(tile)),
          );

    _controller
      ..stop()
      ..value = 0;

    setState(() {
      _fromHand = isOneForOneReplacement
          ? oldWidget.hand
                .where((tile) => !removedKeys.contains(_handTileKey(tile)))
                .toList(growable: false)
          : List<Tile>.from(oldWidget.hand);
      _toHand = List<Tile>.from(widget.hand);
      _incomingTile = incoming;
      _discardingTile = isSingleRemoval ? discarding : null;
      _animating = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final displayedHand = _animating ? _fromHand : _settledHand;
    final resources = widget.station.resources;
    final drawSlotsRemaining = (resources.maxHandSize - widget.hand.length)
        .clamp(0, resources.maxHandSize)
        .toInt();
    final canDraw = drawSlotsRemaining > 0 && resources.drawPileRemaining > 0;
    return Column(
      children: [
        GameBottomInfoRow(station: widget.station, battle: widget.battle),
        const SizedBox(height: 4),
        SizedBox(
          height: 76,
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: _DrawHandButton(
                  slotsRemaining: drawSlotsRemaining,
                  canDraw: canDraw,
                  pulse: _capacityController,
                  pulsing: _capacityGain > 0,
                  onPressed: canDraw ? widget.onDraw : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedBuilder(
                  animation: _capacityController,
                  builder: (context, child) {
                    final pulse = Curves.easeOutCubic.transform(
                      _capacityController.value,
                    );
                    final glow = _capacityController.isAnimating
                        ? (1 - pulse).clamp(0.0, 1.0)
                        : 0.0;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Color.lerp(
                            Colors.white.withValues(alpha: 0.08),
                            const Color(0xFF7DE0B8),
                            glow,
                          )!,
                          width: 1 + glow,
                        ),
                        boxShadow: glow <= 0
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7DE0B8,
                                  ).withValues(alpha: 0.22 * glow),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                      child: child,
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fromLayouts = _layoutByKey(
                            _fromHand,
                            size: constraints.biggest,
                            tileWidth: widget.tileWidth,
                          );
                          final toLayouts = _layoutByKey(
                            _toHand.isEmpty ? displayedHand : _toHand,
                            size: constraints.biggest,
                            tileWidth: widget.tileWidth,
                          );
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final t = _animating ? _controller.value : 1.0;
                              final sel = widget.selectedHandTile;
                              final handPaintOrder = <Tile>[
                                for (final tile in displayedHand)
                                  if ((sel == null || tile != sel) &&
                                      tile != _discardingTile)
                                    tile,
                                if (sel != null &&
                                    displayedHand.contains(sel) &&
                                    sel != _discardingTile)
                                  sel,
                              ];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final tile in handPaintOrder)
                                    _buildSettledTile(
                                      tile,
                                      fromLayouts: fromLayouts,
                                      toLayouts: toLayouts,
                                      areaSize: constraints.biggest,
                                      t: t,
                                    ),
                                  if (_discardingTile != null)
                                    _buildDiscardingTile(
                                      _discardingTile!,
                                      fromLayouts: fromLayouts,
                                      areaSize: constraints.biggest,
                                      t: t,
                                    ),
                                  if (_incomingTile != null)
                                    _buildIncomingTile(
                                      _incomingTile!,
                                      toLayouts: toLayouts,
                                      areaSize: constraints.biggest,
                                      t: t,
                                    ),
                                  if (displayedHand.isEmpty &&
                                      _incomingTile == null)
                                    Center(
                                      child: Text(
                                        '손패 비어 있음',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.38,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      if (_capacityGain > 0)
                        Positioned(
                          key: const ValueKey('hand-capacity-gain-badge'),
                          left: 10,
                          top: -8,
                          child: _HandCapacityGainBadge(
                            amount: _capacityGain,
                            animation: _capacityController,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettledTile(
    Tile tile, {
    required Map<String, _HandSlotLayout> fromLayouts,
    required Map<String, _HandSlotLayout> toLayouts,
    required Size areaSize,
    required double t,
  }) {
    final key = _handTileKey(tile);
    final from = fromLayouts[key] ?? toLayouts[key];
    final to = toLayouts[key] ?? fromLayouts[key];
    if (from == null || to == null) {
      return const SizedBox.shrink();
    }
    final left = lerpDouble(from.left, to.left, t)!;
    final top = lerpDouble(from.top, to.top, t)!;
    final angle = lerpDouble(from.angle, to.angle, t)!;

    return Positioned(
      key: ValueKey('settled-$key'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: () => widget.onHandTileTap(tile),
          child: _HandTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            constrained: widget.battle.isTileConstrained(tile),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscardingTile(
    Tile tile, {
    required Map<String, _HandSlotLayout> fromLayouts,
    required Size areaSize,
    required double t,
  }) {
    final key = _handTileKey(tile);
    final from = fromLayouts[key];
    if (from == null) {
      return const SizedBox.shrink();
    }
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final top = lerpDouble(from.top, from.top - 18, eased)!;
    final scale = lerpDouble(1.0, 0.9, eased)!;
    final opacity = (1 - eased).clamp(0.0, 1.0);

    return Positioned(
      key: ValueKey('discarding-$key'),
      left: from.left,
      top: top,
      width: from.width,
      height: from.height,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: lerpDouble(from.angle, from.angle - 0.08, eased)!,
            child: IgnorePointer(
              child: _HandTileCard(
                tile: tile,
                selected: widget.selectedHandTile == tile,
                constrained: widget.battle.isTileConstrained(tile),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingTile(
    Tile tile, {
    required Map<String, _HandSlotLayout> toLayouts,
    required Size areaSize,
    required double t,
  }) {
    final to = toLayouts[_handTileKey(tile)];
    if (to == null) {
      return const SizedBox.shrink();
    }
    final startLeft = areaSize.width + 12;
    final startTop = (areaSize.height - to.height) / 2;
    final left = lerpDouble(startLeft, to.left, t)!;
    final top = lerpDouble(startTop, to.top, t)!;
    final angle = lerpDouble(0.18, to.angle, t)!;

    return Positioned(
      key: ValueKey('incoming-${_handTileKey(tile)}'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onTap: () => widget.onHandTileTap(tile),
          child: _HandTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            constrained: widget.battle.isTileConstrained(tile),
          ),
        ),
      ),
    );
  }
}

class _DrawHandButton extends StatelessWidget {
  const _DrawHandButton({
    required this.slotsRemaining,
    required this.canDraw,
    required this.pulse,
    required this.pulsing,
    required this.onPressed,
  });

  final int slotsRemaining;
  final bool canDraw;
  final Animation<double> pulse;
  final bool pulsing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final pulseValue = Curves.easeOutCubic.transform(pulse.value);
        final glow = pulsing ? (1 - pulseValue).clamp(0.0, 1.0) : 0.0;
        final baseColor = canDraw
            ? Color.lerp(
                const Color(0xFF267B67),
                const Color(0xFF35A982),
                glow,
              )!
            : const Color(0xFF3F5750);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('draw-hand-button'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                color: canDraw ? baseColor : baseColor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: canDraw ? 0.18 : 0.08),
                    const Color(0xFF9AF0C9),
                    glow,
                  )!,
                  width: 1.4,
                ),
                boxShadow: glow <= 0
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF7DE0B8,
                          ).withValues(alpha: 0.22 * glow),
                          blurRadius: 14,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Text(
                    '드로우',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: canDraw ? 1.0 : 0.56,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    slotsRemaining > 0 ? '$slotsRemaining칸 남음' : '가득 참',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: canDraw ? 0.86 : 0.46,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandCapacityGainBadge extends StatelessWidget {
  const _HandCapacityGainBadge({required this.amount, required this.animation});

  final int amount;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final opacity = (1 - t).clamp(0.0, 1.0);
        final dy = lerpDouble(0, -10, t)!;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF193D32),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9AF0C9)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '손패 +$amount',
                  style: const TextStyle(
                    color: Color(0xFFD8FFE9),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandTileCard extends StatelessWidget {
  const _HandTileCard({
    required this.tile,
    required this.selected,
    required this.constrained,
  });

  final Tile tile;
  final bool selected;
  final bool constrained;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GameRummiTileCard(
            tile: tile,
            selected: selected,
            accent: false,
            aspectRatio: kGameTileAspectRatio,
          ),
        ),
        if (constrained)
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(1),
              child: GameConstraintBadge(side: 58),
            ),
          ),
      ],
    );
  }
}

class _HandSlotLayout {
  const _HandSlotLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
}

List<_HandSlotLayout> _buildHandSlotLayouts(
  Size size, {
  required double tileWidth,
  required int cardCount,
}) {
  final slotCount = cardCount.clamp(1, 3);
  final cardWidth = tileWidth;
  final cardHeight = cardWidth / kGameTileAspectRatio;
  final step = cardWidth * 0.88;
  final usedWidth = cardWidth + step * (slotCount - 1);
  final startLeft = (size.width - usedWidth) / 2;
  final centerY = (size.height - cardHeight) / 2;
  final mid = (slotCount - 1) / 2;

  return List<_HandSlotLayout>.generate(slotCount, (index) {
    final delta = index - mid;
    final angle = delta * 0.055;
    final lift = delta.abs() * 3.0;
    return _HandSlotLayout(
      left: startLeft + step * index,
      top: centerY + lift,
      width: cardWidth,
      height: cardHeight,
      angle: angle,
    );
  });
}

String _handTileKey(Tile tile) => tile.toString();

bool _sameTileKeys(List<Tile> a, List<Tile> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (_handTileKey(a[i]) != _handTileKey(b[i])) return false;
  }
  return true;
}

Map<String, _HandSlotLayout> _layoutByKey(
  List<Tile> hand, {
  required Size size,
  required double tileWidth,
}) {
  final layouts = _buildHandSlotLayouts(
    size,
    tileWidth: tileWidth,
    cardCount: hand.length,
  );
  final out = <String, _HandSlotLayout>{};
  for (var i = 0; i < hand.length && i < layouts.length; i++) {
    out[_handTileKey(hand[i])] = layouts[i];
  }
  return out;
}
