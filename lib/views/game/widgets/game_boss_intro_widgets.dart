import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/boss_modifier.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../resources/asset_paths.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../../../widgets/fx/screen_shake.dart';
import '../game_feedback_cues.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

/// Boss 인트로 배너가 닫히기 전까지 보드·손패의 Boss 제약 표시를 숨긴다.
///
/// 숨김이 풀리는 순간 [GameStampIn]이 새로 만들어져 도장이 찍힌다. 그래서
/// 배너에서 날아온 표시와 보드의 도장이 한 흐름으로 이어진다. 숨김은 투명도 0
/// 고정이라 레이아웃은 그대로이고, 비행 목표 위치도 이 상태에서 잰다.
class GameBossMarkVeil extends InheritedWidget {
  const GameBossMarkVeil({
    super.key,
    required this.hidden,
    required super.child,
  });

  final bool hidden;

  static bool hiddenOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameBossMarkVeil>()?.hidden ??
      false;

  @override
  bool updateShouldNotify(GameBossMarkVeil oldWidget) =>
      hidden != oldWidget.hidden;
}

/// Boss 인트로 배너의 내용. 기존 다이얼로그 골격(제목·규칙 스크롤·확인 버튼)을
/// 그대로 두고 등장 박자만 더한다.
///
/// 붉은 띠가 들어오고, Boss 이름이 도장처럼 찍히고, 제약 아이콘이 차례로
/// 떨어진다. 확인 버튼은 처음부터 눌린다. 자동으로 닫히지 않는다.
class GameBossIntroCard extends StatefulWidget {
  const GameBossIntroCard({
    super.key,
    required this.modifier,
    required this.buttonLabel,
    required this.onConfirm,
    this.animate = true,
    this.marksKey,
    this.maxHeight,
  });

  final RummiBossModifier modifier;
  final String buttonLabel;
  final VoidCallback onConfirm;

  /// 첫 진입 인트로에서만 true. 다시 열기는 정지 화면으로 보여 준다.
  final bool animate;

  /// 비행 출발점을 재기 위한 제약 아이콘 줄의 key.
  final GlobalKey? marksKey;
  final double? maxHeight;

  @override
  State<GameBossIntroCard> createState() => _GameBossIntroCardState();
}

class _GameBossIntroCardState extends State<GameBossIntroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BossMarkIcon> _icons = _bossIntroMarkIcons(widget.modifier);
  bool _stampLanded = false;

  Duration get _titleStart => GamePresentationTimings.bossIntroBannerIn * 0.7;
  Duration get _iconsStart =>
      _titleStart + GamePresentationTimings.bossIntroTitleStamp * 0.8;
  Duration get _total =>
      _iconsStart +
      GamePresentationTimings.bossIntroIconStagger *
          math.max(0, _icons.length - 1) +
      GamePresentationTimings.bossIntroIconDrop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);
    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
    GameFeedback.play(GameCue.bossIntro);
    if (MotionPolicy.juiceScale <= 0) {
      _controller.value = 1;
      return;
    }
    _controller.addListener(_onTick);
    _controller.forward();
  }

  void _onTick() {
    if (_stampLanded) return;
    final landAt = _titleStart + GamePresentationTimings.bossIntroTitleStamp;
    if (_controller.value * _total.inMicroseconds < landAt.inMicroseconds) {
      return;
    }
    _stampLanded = true;
    ScreenShake.instance.add(0.2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(Duration start, Duration length, Curve curve) {
    final total = _total.inMicroseconds;
    final begin = (start.inMicroseconds / total).clamp(0.0, 1.0);
    final end = ((start + length).inMicroseconds / total).clamp(begin, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modifier = widget.modifier;
    final banner = _interval(
      Duration.zero,
      GamePresentationTimings.bossIntroBannerIn,
      Curves.easeOutCubic,
    );
    final stamp = _interval(
      _titleStart,
      GamePresentationTimings.bossIntroTitleStamp,
      Curves.easeOutBack,
    );
    return GameModalCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: widget.maxHeight ?? double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.35, 0),
                end: Offset.zero,
              ).animate(banner),
              child: FadeTransition(
                opacity: banner,
                child: _BossIntroStrip(label: context.tr('flowBossIntroTag')),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: GameUiPalette.specialDangerNotice,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: GameUiPalette.specialDangerNoticeText.withValues(
                        alpha: 0.88,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: GameUiPalette.textPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ScaleTransition(
                    key: const ValueKey('boss-intro-title-stamp'),
                    alignment: Alignment.centerLeft,
                    scale: Tween<double>(begin: 1.4, end: 1).animate(stamp),
                    child: FadeTransition(
                      opacity: _interval(
                        _titleStart,
                        GamePresentationTimings.bossIntroTitleStamp * 0.4,
                        Curves.easeOut,
                      ),
                      child: Text(
                        modifier.title,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.96,
                          ),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              key: widget.marksKey,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _icons.length; i++)
                  _DropIn(
                    slide: _interval(
                      _iconsStart +
                          GamePresentationTimings.bossIntroIconStagger * i,
                      GamePresentationTimings.bossIntroIconDrop,
                      Curves.easeOutBack,
                    ),
                    fade: _interval(
                      _iconsStart +
                          GamePresentationTimings.bossIntroIconStagger * i,
                      GamePresentationTimings.bossIntroIconDrop * 0.5,
                      Curves.easeOut,
                    ),
                    child: _BossMarkIconView(icon: _icons[i]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('boss-constraint-rule-scroll'),
                child: Text(
                  modifier.ruleText,
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GameChromeButton(
              key: const ValueKey('boss-intro-confirm'),
              label: widget.buttonLabel,
              backgroundColor: GameUiPalette.actionGold,
              foregroundColor: GameUiPalette.surfacePanel,
              onPressed: widget.onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _BossIntroStrip extends StatelessWidget {
  const _BossIntroStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GameUiPalette.specialDangerNotice.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: GameUiPalette.textPrimary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropIn extends StatelessWidget {
  const _DropIn({required this.slide, required this.fade, required this.child});

  final Animation<double> slide;
  final Animation<double> fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.9),
          end: Offset.zero,
        ).animate(slide),
        child: child,
      ),
    );
  }
}

enum _BossMarkKind { marker, blockedCell, tileColor, line }

class _BossMarkIcon {
  const _BossMarkIcon(this.kind, {this.text, this.color});

  final _BossMarkKind kind;
  final String? text;
  final TileColor? color;
}

/// 배너에 떨어지는 제약 아이콘 목록. 규칙 데이터에 있는 값만 쓴다.
List<_BossMarkIcon> _bossIntroMarkIcons(RummiBossModifier modifier) {
  return [
    _BossMarkIcon(_BossMarkKind.marker, text: modifier.markerText),
    for (final _ in modifier.blockedCells.take(5))
      const _BossMarkIcon(_BossMarkKind.blockedCell),
    for (final color in modifier.affectedTileColors)
      _BossMarkIcon(_BossMarkKind.tileColor, color: color),
    if (modifier.affectedLineKinds.isNotEmpty)
      const _BossMarkIcon(_BossMarkKind.line),
  ];
}

class _BossMarkIconView extends StatelessWidget {
  const _BossMarkIconView({required this.icon});

  final _BossMarkIcon icon;

  @override
  Widget build(BuildContext context) {
    if (icon.kind == _BossMarkKind.marker) {
      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: GameUiPalette.specialDangerSoft.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            icon.text ?? '',
            style: const TextStyle(
              color: GameUiPalette.textOnWarm,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
    final fill = switch (icon.kind) {
      _BossMarkKind.tileColor => _tileColor(icon.color!),
      _ => GameUiPalette.surfacePanel,
    };
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: GameUiPalette.bossWeakenPreview.withValues(alpha: 0.9),
          width: 1.4,
        ),
      ),
      child: icon.kind == _BossMarkKind.line
          ? const Icon(
              Icons.linear_scale_rounded,
              size: 16,
              color: GameUiPalette.bossWeakenPreview,
            )
          : Text(
              'X',
              style: TextStyle(
                color: icon.kind == _BossMarkKind.tileColor
                    ? GameUiPalette.textPrimary
                    : GameUiPalette.bossWeakenPreview,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
    );
  }

  static Color _tileColor(TileColor color) => switch (color) {
    TileColor.red => GameUiPalette.tileRed,
    TileColor.blue => GameUiPalette.tileBlue,
    TileColor.yellow => GameUiPalette.actionGold,
    TileColor.black => GameUiPalette.ink,
  };
}

/// 배너에서 보드로 날아가는 제약 표시 하나. 좌표는 비행 레이어의 로컬 좌표다.
class GameBossMarkFlight {
  const GameBossMarkFlight({required this.from, required this.to});

  final Offset from;
  final Rect to;
}

/// 배너가 닫힌 뒤 제약 표시가 호를 그리며 목표 칸으로 날아간다.
///
/// 표시는 날아가며 커져 목표 칸 도장 시작 크기(1.9배)에 닿는다. 모두 닿으면
/// [onLanded]를 부르고, 호출부가 숨김을 풀면 보드의 [GameStampIn]이 같은
/// 크기에서 줄어들며 자리 잡는다. 입력은 막지 않는다.
class GameBossMarkFlightLayer extends StatefulWidget {
  const GameBossMarkFlightLayer({
    super.key,
    required this.flights,
    required this.onLanded,
  });

  final List<GameBossMarkFlight> flights;
  final VoidCallback onLanded;

  static Duration totalDuration(int count) =>
      GamePresentationTimings.bossMarkFlight +
      _stagger(count) * math.max(0, count - 1);

  /// 칸이 많아도 출발 간격 합이 240ms를 넘지 않게 줄인다.
  static Duration _stagger(int count) {
    if (count <= 1) return Duration.zero;
    const spread = Duration(milliseconds: 240);
    final even = spread ~/ (count - 1);
    return even < GamePresentationTimings.bossMarkFlightStagger
        ? even
        : GamePresentationTimings.bossMarkFlightStagger;
  }

  @override
  State<GameBossMarkFlightLayer> createState() =>
      _GameBossMarkFlightLayerState();
}

class _GameBossMarkFlightLayerState extends State<GameBossMarkFlightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GameBossMarkFlightLayer.totalDuration(widget.flights.length),
    )..addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onLanded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stagger = GameBossMarkFlightLayer._stagger(widget.flights.length);
    final total = _controller.duration!.inMicroseconds;
    final flight = GamePresentationTimings.bossMarkFlight.inMicroseconds;
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          key: const ValueKey('boss-mark-flight-layer'),
          animation: _controller,
          builder: (context, _) {
            final elapsed = _controller.value * total;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < widget.flights.length; i++)
                  _flightMark(
                    widget.flights[i],
                    (elapsed - stagger.inMicroseconds * i) / flight,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const double _baseSize = 20;

  Widget _flightMark(GameBossMarkFlight f, double raw) {
    if (raw <= 0) return const SizedBox.shrink();
    final t = Curves.easeInOutCubic.transform(raw.clamp(0.0, 1.0));
    final to = f.to.center;
    final control = Offset(
      (f.from.dx + to.dx) / 2,
      math.min(f.from.dy, to.dy) - 70,
    );
    final u = 1 - t;
    final p = f.from * (u * u) + control * (2 * u * t) + to * (t * t);
    // 목표 도장 시작 크기: 목표 글자 높이를 1.9배로 키운 크기.
    final endHeight = f.to.height * 1.9;
    final scale = (_baseSize + (endHeight - _baseSize) * t) / _baseSize;
    return Positioned(
      left: p.dx - _baseSize,
      top: p.dy - _baseSize,
      width: _baseSize * 2,
      height: _baseSize * 2,
      child: Transform.rotate(
        angle: (1 - t) * -0.5,
        child: Transform.scale(
          scale: scale,
          child: const Center(
            child: Text(
              'X',
              style: TextStyle(
                color: GameUiPalette.bossWeakenPreview,
                fontSize: _baseSize,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(
                    color: GameUiPalette.ink,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [root] 아래에서 Boss 제약 표시([GameStampIn]) 안 `X` 글자의 전역 사각형을 모은다.
///
/// 비어 있으면 [fallbackKey](Boss 정보 칩)의 사각형 하나를 돌려준다.
List<Rect> collectBossMarkTargets(BuildContext root, {Key? fallbackKey}) {
  final rects = <Rect>[];
  Rect? fallback;

  Rect? rectOf(Element element) {
    final box = element.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? glyphRect(Element stamp) {
    Rect? found;
    void find(Element element) {
      if (found != null) return;
      if (element.widget is RichText) {
        found = rectOf(element);
        return;
      }
      element.visitChildElements(find);
    }

    stamp.visitChildElements(find);
    return found ?? rectOf(stamp);
  }

  void visit(Element element) {
    final widget = element.widget;
    if (widget is GameStampIn) {
      final rect = glyphRect(element);
      if (rect != null) rects.add(rect);
      return;
    }
    if (fallbackKey != null && widget.key == fallbackKey) {
      fallback ??= rectOf(element);
    }
    element.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  if (rects.isEmpty && fallback != null) {
    final chip = fallback!;
    rects.add(Rect.fromCenter(center: chip.center, width: 16, height: 16));
  }
  return rects;
}
