import 'dart:math' show pi, sin;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../widgets/fx/fx_sprites.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../../../widgets/fx/spring_follow.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

class GameHandZone extends StatefulWidget {
  const GameHandZone({
    super.key,
    required this.battle,
    required this.station,
    required this.hand,
    required this.selectedHandTile,
    required this.onHandTileTap,
    required this.onHandTileLongPress,
    required this.onDraw,
    required this.tileWidth,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final List<Tile> hand;
  final Tile? selectedHandTile;
  final ValueChanged<Tile> onHandTileTap;
  final ValueChanged<Tile> onHandTileLongPress;
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

  /// 전투 진입 때 손패가 짧은 stagger로 깔리는 진행도(0~1).
  late final AnimationController _entryController;
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
    _entryController = AnimationController(
      vsync: this,
      duration:
          GamePresentationTimings.battleEntryDeal +
          GamePresentationTimings.battleEntryStagger * 5,
      value: MotionPolicy.reduceMotion ? 1 : 0,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _capacityController.dispose();
    _entryController.dispose();
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
                  // 막힌 드로우도 탭을 받아 거절 피드백을 준다.
                  onPressed: widget.onDraw,
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
                        color: GameUiPalette.ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Color.lerp(
                            GameUiPalette.textPrimary.withValues(alpha: 0.08),
                            GameUiPalette.specialSoftMint,
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
                            animation: Listenable.merge([
                              _controller,
                              _entryController,
                            ]),
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
                                          color: GameUiPalette.textPrimary
                                              .withValues(alpha: 0.38),
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
                      if (_incomingTile != null)
                        Positioned(
                          key: const ValueKey('hand-draw-incoming-badge'),
                          right: 12,
                          top: -8,
                          child: _HandDrawIncomingBadge(animation: _controller),
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
    final selected = widget.selectedHandTile == tile;
    final entry = _entryProgress(widget.hand.indexOf(tile));

    return Positioned(
      key: ValueKey('settled-$key'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform.translate(
        offset: Offset(0, 36 * (1 - entry)),
        child: Transform.scale(
          scale: 0.7 + 0.3 * entry,
          child: Transform.rotate(
            angle: angle,
            child: GestureDetector(
              onTap: () => widget.onHandTileTap(tile),
              onLongPress: () => widget.onHandTileLongPress(tile),
              // 선택하면 떠오르며 커지고 살짝 기운다. 목표를 따라가는 움직임이다.
              child: SpringFollow(
                offset: selected ? const Offset(0, -10) : Offset.zero,
                scale: selected ? 1.08 : 1,
                rotation: selected ? 0.05 - angle * 0.5 : 0,
                child: FxBoxGlow(
                  color: GameUiPalette.ink.withValues(
                    alpha: selected ? 0.45 : 0,
                  ),
                  blurRadius: selected ? 14 : 0,
                  offset: const Offset(0, 8),
                  child: _HandTileCard(
                    tile: tile,
                    selected: selected,
                    constrained: widget.battle.isTileConstrained(tile),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 진입 deal에서 [index]번째 타일의 진행도(0~1).
  double _entryProgress(int index) {
    if (_entryController.isCompleted || index < 0) return 1;
    final total = _entryController.duration!;
    final elapsed = total * _entryController.value;
    final local =
        (elapsed - GamePresentationTimings.battleEntryStagger * index)
            .inMicroseconds /
        GamePresentationTimings.battleEntryDeal.inMicroseconds;
    return Curves.easeOutBack.transform(local.clamp(0.0, 1.0));
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
    // 보드 버림과 같은 결: 먼저 들렸다가 기울며 줄어들고 사라진다.
    final p = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final top = p < 0.32
        ? from.top - 10 * (p / 0.32)
        : from.top - 10 - 16 * ((p - 0.32) / 0.68);
    final scale = p < 0.32
        ? 1.0 + 0.08 * (p / 0.32)
        : 1.08 - 0.3 * ((p - 0.32) / 0.68);
    final opacity = p < 0.32 ? 1.0 : (1 - (p - 0.32) / 0.68).clamp(0.0, 1.0);

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
            angle: lerpDouble(from.angle, from.angle - 0.14, p)!,
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
    // 덱(왼쪽 드로우 버튼)에서 호를 그리며 날아와 착지 때 눌렸다 펴진다.
    final startLeft = -(72 + 10) + (72 - to.width) / 2;
    final startTop = (areaSize.height - to.height) / 2;
    final flight = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final left = lerpDouble(startLeft, to.left, flight)!;
    final top = lerpDouble(startTop, to.top, flight)! - 28 * sin(pi * flight);
    final angle = lerpDouble(-0.35, to.angle, flight)!;
    final landing = t < 0.8 ? 0.0 : sin(pi * ((t - 0.8) / 0.2));

    return Positioned(
      key: ValueKey('incoming-${_handTileKey(tile)}'),
      left: left,
      top: top,
      width: to.width,
      height: to.height,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateZ(angle)
          ..scaleByDouble(1 + 0.08 * landing, 1 - 0.1 * landing, 1, 1),
        child: GestureDetector(
          onTap: () => widget.onHandTileTap(tile),
          onLongPress: () => widget.onHandTileLongPress(tile),
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

class _HandDrawIncomingBadge extends StatelessWidget {
  const _HandDrawIncomingBadge({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final opacity = (1 - (t - 0.72).clamp(0.0, 1.0) / 0.28).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.surfaceModalInner.withValues(
                alpha: 0.96 * opacity,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: GameUiPalette.specialSoftMint.withValues(alpha: opacity),
              ),
              boxShadow: [
                BoxShadow(
                  color: GameUiPalette.specialSoftMint.withValues(
                    alpha: 0.24 * opacity,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                '드로우 +1',
                maxLines: 1,
                style: TextStyle(
                  color: GameUiPalette.specialSoftMint.withValues(
                    alpha: opacity,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
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
                GameUiPalette.marketPositive,
                GameUiPalette.specialMint,
                glow,
              )!
            : GameUiPalette.surfaceDrawButtonIdle;
        return Material(
          color: GameUiPalette.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                color: canDraw ? baseColor : baseColor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    GameUiPalette.textPrimary.withValues(
                      alpha: canDraw ? 0.18 : 0.08,
                    ),
                    GameUiPalette.specialSoftMintText,
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
                      color: GameUiPalette.textPrimary.withValues(
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
                      color: GameUiPalette.textPrimary.withValues(
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
        // 알파를 색에 직접 곱해 Opacity 합성을 피한다.
        Color fade(Color color) => color.withValues(alpha: color.a * opacity);
        return Transform.translate(
          offset: Offset(0, dy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fade(GameUiPalette.surfaceHandPanel),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: fade(GameUiPalette.specialSoftMintText),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '손패 +$amount',
                style: TextStyle(
                  color: fade(GameUiPalette.specialSuccessText),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
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
            modifierBadgeScale: kHandTileModifierBadgeScale,
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
  final slotCount = cardCount.clamp(1, 5);
  final stepFactor = switch (slotCount) {
    <= 3 => 0.88,
    4 => 0.72,
    _ => 0.62,
  };
  final availableWidth = (size.width - 8).clamp(0.0, double.infinity);
  final maxCardWidth = availableWidth / (1 + stepFactor * (slotCount - 1));
  final cardWidth = tileWidth.clamp(0.0, maxCardWidth).toDouble();
  final cardHeight = cardWidth / kGameTileAspectRatio;
  final step = cardWidth * stepFactor;
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
