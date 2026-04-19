import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import 'game_shared_widgets.dart';

class GameHandZone extends StatefulWidget {
  const GameHandZone({
    super.key,
    required this.session,
    required this.station,
    required this.hand,
    required this.selectedHandTile,
    required this.onHandTileTap,
    required this.onDraw,
    required this.tileWidth,
  });

  final RummiPokerGridSession session;
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
    with SingleTickerProviderStateMixin {
  static const Duration _handAnimDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  List<Tile> _settledHand = <Tile>[];
  List<Tile> _fromHand = <Tile>[];
  List<Tile> _toHand = <Tile>[];
  Tile? _incomingTile;
  bool _animating = false;

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
          _animating = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameHandZone oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    if (!isSimpleAppend && !isOneForOneReplacement) {
      _controller.stop();
      setState(() {
        _settledHand = List<Tile>.from(widget.hand);
        _fromHand = List<Tile>.from(widget.hand);
        _toHand = List<Tile>.from(widget.hand);
        _incomingTile = null;
        _animating = false;
      });
      return;
    }

    final incoming = widget.hand.firstWhere(
      (tile) => addedKeys.contains(_handTileKey(tile)),
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
      _animating = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final displayedHand = _animating ? _fromHand : _settledHand;
    return Column(
      children: [
        GameBottomInfoRow(
          station: widget.station,
          totalDeckSize: widget.session.totalDeckSize,
          currentHandSize: widget.hand.length,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 76,
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: GameActionButton(
                  label: '드로우',
                  background: const Color(0xFF267B67),
                  onPressed: widget.onDraw,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: LayoutBuilder(
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
                              if (sel == null || tile != sel) tile,
                            if (sel != null && displayedHand.contains(sel)) sel,
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
          child: GameRummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: kGameTileAspectRatio,
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
          child: GameRummiTileCard(
            tile: tile,
            selected: widget.selectedHandTile == tile,
            accent: false,
            aspectRatio: kGameTileAspectRatio,
          ),
        ),
      ),
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
