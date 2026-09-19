import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/rummi_poker_grid/models/tile.dart';
import '../../providers/features/settings/settings_notifier.dart';
import '../../views/game/game_presentation_timings.dart';
import 'motion_policy.dart';

/// 하나의 시계에 등록된 화면 타일. notifier는 시계를 갖지 않는다.
class TileMaterialLease extends ChangeNotifier {
  TileMaterialLease(this.visible);
  final bool Function() visible;
  double phase = 0;
  void advance(double value) {
    phase = value;
    notifyListeners();
  }
}

class TileMaterialClock with WidgetsBindingObserver {
  TileMaterialClock();
  static final instance = TileMaterialClock();
  static const maxAnimatedTiles = 4;
  final _leases = <TileMaterialLease>[];
  Timer? _timer;
  double _phase = 0;
  bool _resumed = true;
  bool get isRunning => _timer != null;
  int get animatedCount => MotionPolicy.juiceScale <= 0 || !_resumed
      ? 0
      : _leases.where((lease) => lease.visible()).take(maxAnimatedTiles).length;

  void attach(TileMaterialLease lease) {
    if (_leases.isEmpty) {
      WidgetsBinding.instance.addObserver(this);
      final state = WidgetsBinding.instance.lifecycleState;
      _resumed = state == null || state == AppLifecycleState.resumed;
    }
    _leases.add(lease);
    refresh();
  }

  void detach(TileMaterialLease lease) {
    _leases.remove(lease);
    if (_leases.isEmpty) WidgetsBinding.instance.removeObserver(this);
    refresh();
  }

  void refresh() {
    if (animatedCount == 0) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(GamePresentationTimings.t5MaterialTick, (_) {
      refresh();
      if (!isRunning) return;
      _phase =
          (_phase +
              GamePresentationTimings.t5MaterialTick.inMicroseconds /
                  GamePresentationTimings.t5SheenPeriod.inMicroseconds) %
          1;
      for (final lease
          in _leases
              .where((l) => l.visible())
              .take(maxAnimatedTiles)
              .toList()) {
        lease.advance(_phase);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    refresh();
  }

  @override
  void didChangeAccessibilityFeatures() => refresh();
}

/// 타일 크기에 비례한 가장자리 재질 영역. 숫자와 배지는 이 안쪽을 사용한다.
class TileMaterialMetrics {
  TileMaterialMetrics(Size size)
    : face = Offset.zero & size,
      rim = size.shortestSide * .045,
      radius = size.shortestSide * .11;
  final Rect face;
  final double rim;
  final double radius;
}

/// 면 위의 좁은 가장자리만 칠하므로 숫자·배지·Boss X를 덮지 않는다.
class TileMaterialPainter extends CustomPainter {
  TileMaterialPainter({required this.tile, this.lease}) : super(repaint: lease);
  final Tile tile;
  final TileMaterialLease? lease;

  @override
  void paint(Canvas canvas, Size size) {
    if (!tile.hasModifier || size.isEmpty) return;
    final m = TileMaterialMetrics(size);
    final outer = RRect.fromRectAndRadius(
      m.face.deflate(m.rim),
      Radius.circular(m.radius),
    );
    final inner = outer.deflate(m.rim * 1.8);
    final border = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner);
    final colors = switch (tile.edition) {
      TileEdition.prismEdition => const [
        Color(0xFFDB79BB),
        Color(0xFF75BDD2),
        Color(0xFFE2C26B),
      ],
      TileEdition.glowEdition => const [
        Color(0xFF79CDC9),
        Color(0xFFD5F5DF),
        Color(0xFF8BAFDB),
      ],
      TileEdition.silverEdition => const [
        Color(0xFF8A9CAE),
        Color(0xFFF3FAFF),
        Color(0xFF95AABD),
      ],
      null => switch (tile.enhancement) {
        TileEnhancement.goldTile => const [
          Color(0xFFB67C2F),
          Color(0xFFF2D882),
          Color(0xFFC79843),
        ],
        TileEnhancement.scoreGilded => const [
          Color(0xFFD0A878),
          Color(0xFFFFE6AB),
          Color(0xFFA97F46),
        ],
        TileEnhancement.glassTile => const [
          Color(0xFFA6CCD0),
          Color(0xFFFAFFFF),
          Color(0xFFC4E3E6),
        ],
        TileEnhancement.chipInlaid => const [
          Color(0xFF809EA5),
          Color(0xFFCDDDCF),
          Color(0xFF8BACB4),
        ],
        null => const [Color(0xFFB1AC9F), Color(0xFFE6DED0), Color(0xFFB1AC9F)],
      },
    };
    canvas.drawPath(
      border,
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(m.face),
    );
    final phase = lease?.phase ?? .25;
    canvas.save();
    canvas.clipPath(border);
    final x = m.face.width * (phase * 2 - .5);
    final band = Rect.fromLTWH(x, 0, m.face.width * .5, m.face.height);
    canvas.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0xC0FFFFFF), Color(0x00FFFFFF)],
        ).createShader(band),
    );
    canvas.restore();
    // 각인은 왼쪽 아래 여백에 서로 다른 점/선 패턴으로 새긴다.
    final seal = tile.seal;
    if (seal != null) {
      final paint = Paint()
        ..color = colors.first.withValues(alpha: .75)
        ..strokeWidth = math.max(.7, m.rim * .4)
        ..style = PaintingStyle.stroke;
      final count = seal.index % 5 + 1;
      for (var i = 0; i < count; i++) {
        final x = m.face.width * (.17 + i * .045);
        final y = m.face.height * .89;
        if (seal.index < 5) {
          canvas.drawCircle(Offset(x, y), m.rim * .32, paint);
        } else {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + m.rim * .4, y - m.rim),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(TileMaterialPainter oldDelegate) =>
      oldDelegate.tile.enhancement != tile.enhancement ||
      oldDelegate.tile.seal != tile.seal ||
      oldDelegate.tile.edition != tile.edition ||
      oldDelegate.lease != lease;
}

class TileMaterialSurface extends StatefulWidget {
  const TileMaterialSurface({super.key, required this.tile});
  final Tile tile;
  @override
  State<TileMaterialSurface> createState() => _TileMaterialSurfaceState();
}

class _TileMaterialSurfaceState extends State<TileMaterialSurface> {
  late final TileMaterialLease _lease;
  bool _tickerEnabled = true;
  bool _active = true;
  ProviderSubscription<dynamic>? _settings;
  ScrollPosition? _scroll;

  bool _visible() {
    if (!mounted || !_active || !_tickerEnabled || !widget.tile.hasModifier) {
      return false;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    var bounds = MatrixUtils.transformRect(
      box.getTransformTo(null),
      box.paintBounds,
    );
    RenderObject child = box;
    RenderObject? ancestor = box.parent;
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) return false;
      final clip = ancestor.describeApproximatePaintClip(child);
      if (clip != null) {
        bounds = bounds.intersect(
          MatrixUtils.transformRect(ancestor.getTransformTo(null), clip),
        );
        if (bounds.isEmpty) return false;
      }
      child = ancestor;
      ancestor = ancestor.parent;
    }
    final view = View.of(context);
    final screen = view.physicalSize / view.devicePixelRatio;
    return (Offset.zero & screen).overlaps(bounds);
  }

  @override
  void initState() {
    super.initState();
    _lease = TileMaterialLease(_visible);
    TileMaterialClock.instance.attach(_lease);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _scroll?.removeListener(_refresh);
    _scroll = Scrollable.maybeOf(context)?.position;
    _scroll?.addListener(_refresh);
    _settings?.close();
    if (context.getInheritedWidgetOfExactType<UncontrolledProviderScope>() !=
        null) {
      _settings = ProviderScope.containerOf(context, listen: false).listen(
        settingsNotifierProvider.select((s) => s.fxIntensity),
        (_, _) => _refresh(),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _refresh() => TileMaterialClock.instance.refresh();

  @override
  void deactivate() {
    _active = false;
    _refresh();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _active = false;
    _settings?.close();
    _scroll?.removeListener(_refresh);
    TileMaterialClock.instance.detach(_lease);
    _lease.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TileMaterialPainter(tile: widget.tile, lease: _lease),
        ),
      ),
    );
  }
}

/// 숫자·색 띠보다 먼저 그리는 정적 재질 면. 움직이는 부분과 캐시를 분리한다.
void paintTileMaterialFace(Canvas canvas, Rect rect, Tile tile) {
  final enhancement = tile.enhancement;
  if (enhancement == null) return;
  final m = TileMaterialMetrics(rect.size);
  canvas.save();
  canvas.translate(rect.left, rect.top);
  canvas.clipRRect(
    RRect.fromRectAndRadius(m.face.deflate(m.rim), Radius.circular(m.radius)),
  );
  final color = switch (enhancement) {
    TileEnhancement.chipInlaid => const Color(0xFF779CA7),
    TileEnhancement.scoreGilded => const Color(0xFFCCAB65),
    TileEnhancement.goldTile => const Color(0xFFDDB44F),
    TileEnhancement.glassTile => const Color(0xFFACDDE7),
  };
  canvas.drawRect(
    m.face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: .23),
          color.withValues(alpha: .03),
          color.withValues(alpha: .18),
        ],
      ).createShader(m.face),
  );
  final paint = Paint()
    ..color = color.withValues(alpha: .35)
    ..strokeWidth = m.rim * .4;
  switch (enhancement) {
    case TileEnhancement.chipInlaid:
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(m.face.width * .14, m.face.height * (.43 + i * .11)),
          m.rim * .5,
          paint,
        );
      }
    case TileEnhancement.scoreGilded:
      for (final x in [.13, .18]) {
        canvas.drawLine(
          Offset(m.face.width * x, m.face.height * .4),
          Offset(m.face.width * x, m.face.height * .78),
          paint,
        );
      }
    case TileEnhancement.goldTile:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          m.face.deflate(m.rim * 2.8),
          Radius.circular(m.radius),
        ),
        paint..style = PaintingStyle.stroke,
      );
    case TileEnhancement.glassTile:
      canvas.drawPath(
        Path()
          ..moveTo(0, m.face.height * .68)
          ..lineTo(m.face.width, m.face.height * .22)
          ..lineTo(m.face.width, m.face.height * .36)
          ..lineTo(0, m.face.height * .82)
          ..close(),
        Paint()..color = const Color(0x70FFFFFF),
      );
  }
  canvas.restore();
}
