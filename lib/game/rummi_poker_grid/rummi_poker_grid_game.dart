import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../logic/rummi_poker_grid/models/board.dart';
import '../../logic/rummi_poker_grid/models/tile.dart';
import '../../logic/rummi_poker_grid/hand_rank.dart';
import '../../logic/rummi_poker_grid/line_ref.dart';
import '../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'rummikub_tile_canvas.dart';

class _UiTheme {
  static const Color felt = Color(0xFF0D1F14);
  static const Color panel = Color(0xFF163022);
  static const Color panel3 = Color(0xFF234430);
  static const Color panelDeep = Color(0xFF10261C);
  static const Color teal = Color(0xFF1E8A74);
  static const Color shadow = Color(0xFF08110C);
  static const Color line = Color(0xFF355A46);
  static const Color glow = Color(0x6629B36B);
  static const Color score = Color(0xFFE65100);
  static const Color slate = Color(0xFF37474F);
  static const Color cream = Color(0xFFF2EDE6);
  static const Color creamMute = Color(0xFFD6D0C7);
  static const Color mist = Color(0xFFECEFF1);
}

enum _ButtonTone { primary, danger, neutral, draw }

/// 루미 포커 그리드 플레이 필드. [session]은 외부에서 생성해 주입한다.
class RummiPokerGridGame extends FlameGame {
  RummiPokerGridGame({
    required this.session,
    this.onSessionChanged,
    this.onMessage,
    this.onGameOver,
    this.onInteractionLocked,
  });

  @override
  Color backgroundColor() => const Color(0xFF0D1F14);

  final RummiPokerGridSession session;
  final VoidCallback? onSessionChanged;
  final void Function(String message)? onMessage;
  final void Function(List<RummiExpirySignal> signals)? onGameOver;
  /// 드로우 비행 등 연출 중 Flutter 쪽 전체 입력 차단용.
  final ValueChanged<bool>? onInteractionLocked;

  Tile? selectedHandTile;

  /// 보드에서 버림 대상으로 선택한 칸 (`null`이면 미선택).
  int? selectedBoardRow;
  int? selectedBoardCol;

  /// 드로우 직후 비행 중인 손패 인덱스(해당 타일은 손패에서 숨김).
  int? flyingDrawHandIndex;

  late final RummiPlayfield playfield;
  bool _playfieldReady = false;

  void _notify() {
    onSessionChanged?.call();
  }

  void _msg(String m) => onMessage?.call(m);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    playfield = RummiPlayfield();
    playfield.gameRef = this;
    await add(playfield);
    await playfield.rebuild();
    _playfieldReady = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_playfieldReady) {
      playfield.rebuild();
    }
  }

  void selectHandTile(Tile? t) {
    if (t == null) {
      selectedHandTile = null;
      selectedBoardRow = null;
      selectedBoardCol = null;
      playfield.rebuild();
      return;
    }
    if (selectedHandTile == t) {
      selectedHandTile = null;
    } else {
      selectedHandTile = t;
      selectedBoardRow = null;
      selectedBoardCol = null;
    }
    playfield.rebuild();
  }

  /// 보드에 놓인 타일을 탭해 버림 대상으로 선택(같은 칸 재탭 시 해제).
  void toggleBoardTileSelect(int row, int col) {
    if (session.board.cellAt(row, col) == null) return;
    if (selectedBoardRow == row && selectedBoardCol == col) {
      selectedBoardRow = null;
      selectedBoardCol = null;
    } else {
      selectedBoardRow = row;
      selectedBoardCol = col;
      selectedHandTile = null;
    }
    playfield.rebuild();
  }

  bool boardCellSelected(int row, int col) =>
      selectedBoardRow == row && selectedBoardCol == col;

  void tryPlaceOnCell(int row, int col) {
    final sel = selectedHandTile;
    if (sel == null) {
      _msg('손패에서 타일을 먼저 선택하세요.');
      return;
    }
    final ok = session.tryPlaceFromHand(sel, row, col);
    if (!ok) {
      _msg('이 칸에 둘 수 없습니다.');
      return;
    }
    selectedHandTile = null;
    selectedBoardRow = null;
    selectedBoardCol = null;
    playfield.rebuild();
    _notify();
    _afterAction();
  }

  void actionDraw() {
    if (flyingDrawHandIndex != null) {
      return;
    }
    if (!session.canDrawFromDeck) {
      if (session.deck.isEmpty) {
        _msg('덱이 비었습니다.');
      } else {
        _msg(
          '손패는 최대 ${RummiPokerGridSession.kMaxHandSize}장입니다. 보드에 놓은 뒤 드로우하세요.',
        );
      }
      return;
    }
    final drawn = session.drawToHand();
    if (drawn == null) return;
    unawaited(_runDrawFlyAnimation(drawn));
  }

  Future<void> _runDrawFlyAnimation(Tile drawn) async {
    flyingDrawHandIndex = session.hand.length - 1;
    onInteractionLocked?.call(true);
    try {
      await playfield.rebuild();
      final idx = flyingDrawHandIndex!;
      final end = _globalHandSlotCenter();
      final finalAngle = _handSlotRotationForIndex(idx);
      final tileSize = _handTileSizeVector();
      final start = Vector2(size.x + tileSize.x * 0.9, end.y);
      final fly = _FlyingDrawTile(
        tile: drawn,
        start: start,
        end: end,
        size: tileSize,
        angle: finalAngle,
        onDone: () {
          flyingDrawHandIndex = null;
          onInteractionLocked?.call(false);
          playfield.rebuild();
          _notify();
          _afterAction();
        },
      );
      await add(fly);
    } catch (_) {
      flyingDrawHandIndex = null;
      onInteractionLocked?.call(false);
      playfield.rebuild();
      rethrow;
    }
  }

  /// [flyingDrawHandIndex] 기준 고정 슬롯 좌표(게임 좌표, 앵커 중심).
  Vector2 _globalHandSlotCenter() {
    final n = session.hand.length;
    final idx = flyingDrawHandIndex ?? (n - 1);
    return _handSlotCenterInGame(this, index: idx);
  }

  Vector2 _handTileSizeVector() {
    final m = _PlayfieldLayout.fromSize(size);
    final lay = _handStripLayout(m.handStripW);
    return Vector2(lay.tileW, lay.tileH);
  }

  void actionDiscard() {
    final br = selectedBoardRow;
    final bc = selectedBoardCol;
    if (br == null || bc == null) {
      _msg('보드에서 버릴 타일을 선택한 뒤 버림을 누르세요.');
      return;
    }
    final r = session.tryDiscardFromBoard(br, bc);
    if (r.fail != null) {
      _msg(switch (r.fail!) {
        DiscardFailReason.noDiscardsLeft => '버림 횟수(D)가 없습니다.',
        DiscardFailReason.cellEmpty => '해당 칸에 타일이 없습니다.',
      });
      return;
    }
    selectedBoardRow = null;
    selectedBoardCol = null;
    playfield.rebuild();
    _notify();
    _afterAction();
  }

  void actionConfirmLines() {
    final out = session.confirmAllFullLines();
    if (!out.result.ok) {
      _msg('확정할 족보(점수) 줄이 없습니다.');
      return;
    }
    selectedHandTile = null;
    selectedBoardRow = null;
    selectedBoardCol = null;
    _msg('줄 확정: +${out.result.scoreAdded}점');
    if (out.cleared != null) {
      _msg('블라인드 목표 달성!');
    }
    playfield.rebuild();
    _notify();
    _afterAction();
  }

  void _afterAction() {
    final sig = session.evaluateExpirySignals();
    if (sig.isNotEmpty) {
      onGameOver?.call(sig);
    }
  }
}

/// HUD·보드·손패·버튼 배치 수치 (한 곳에서만 계산).
class _PlayfieldLayout {
  _PlayfieldLayout._({
    required this.pad,
    required this.hudH,
    required this.jesterTop,
    required this.jesterH,
    required this.boardSide,
    required this.boardTop,
    required this.handTop,
    required this.handH,
    required this.areaW,
    required this.btnBlock,
  });

  final double pad;
  final double hudH;
  final double jesterTop;
  final double jesterH;
  final double boardSide;
  final double boardTop;
  final double handTop;
  final double handH;
  final double areaW;
  /// 하단 액션 한 줄(줄 확정·버림·선택 해제 3칸) + 여백. 드로우는 손패 왼쪽 열.
  final double btnBlock;

  /// 손패 타일만 쓰는 가로 폭(왼쪽 드로우 열·간격 제외).
  double get handStripW => areaW - _kDrawBandW - _kDrawHandGap;

  static const double _btnH = 52.0;
  static const double _btnRowGap = 10.0;

  static double get btnH => _btnH;

  static _PlayfieldLayout fromSize(Vector2 size) {
    const pad = 10.0;
    const hudH = 102.0;
    final btnBlock = _btnH + _btnRowGap;
    const jesterGap = 16.0;
    const jesterH = 88.0;
    const handH = 58.0;
    const boardGap = 8.0;
    const handGap = 6.0;
    final areaW = size.x - pad * 2;
    final boardMaxByHeight =
        size.y -
        pad * 2 -
        hudH -
        jesterH -
        handH -
        btnBlock -
        boardGap -
        handGap -
        jesterGap;
    final boardSide = areaW.clamp(
      120.0,
      boardMaxByHeight.clamp(120.0, 360.0),
    );
    final jesterTop = pad + hudH + jesterGap;
    final boardTop = jesterTop + jesterH + boardGap;
    final handTop = boardTop + boardSide + handGap;
    return _PlayfieldLayout._(
      pad: pad,
      hudH: hudH,
      jesterTop: jesterTop,
      jesterH: jesterH,
      boardSide: boardSide,
      boardTop: boardTop,
      handTop: handTop,
      handH: handH,
      areaW: areaW,
      btnBlock: btnBlock,
    );
  }
}

/// 손패는 항상 [kMaxHandSize]칸 고정 슬롯(1·2·3) — 장수가 늘어나도 위치가 밀리지 않음.
int get _kHandSlotCount => RummiPokerGridSession.kMaxHandSize;

/// 손패 **왼쪽** 드로우 버튼 전용 폭 + 손패와의 간격(겹침 없음).
const double _kDrawBandW = 58.0;
const double _kDrawHandGap = 10.0;

/// 손패 스트립 너비 기준 타일 크기·스텝(배치·비행 도착점 공통).
({double tileW, double tileH, double step}) _handStripLayout(double stripW) {
  final tileW = (stripW * 0.25).clamp(42.0, 58.0);
  final tileH = tileW * 1.38;
  final overlap = tileW * 0.16;
  final step = tileW - overlap;
  return (tileW: tileW, tileH: tileH, step: step);
}

/// 손패 영역 로컬 Y.
double _handTileCenterYLocal(double handAreaH, double tileH, int index) {
  final mid = (_kHandSlotCount - 1) / 2.0;
  final arc = (index - mid).abs() * 1.2;
  final minCy = tileH * 0.5 + 4;
  var cy = handAreaH * 0.68 + arc;
  final maxCy = handAreaH - tileH * 0.5 - 4;
  if (cy > maxCy) cy = maxCy;
  if (cy < minCy) cy = minCy;
  return cy;
}

/// 손패 슬롯 중심 (게임 전역 좌표, 앵커 center 기준).
Vector2 _handSlotCenterInGame(
  RummiPokerGridGame game, {
  required int index,
}) {
  final m = _PlayfieldLayout.fromSize(game.size);
  final slotN = _kHandSlotCount;
  if (index < 0 || index >= slotN) {
    return Vector2(
      m.pad + _kDrawBandW + _kDrawHandGap + m.handStripW / 2,
      m.handTop + m.handH / 2,
    );
  }
  final stripW = m.handStripW;
  final lay = _handStripLayout(stripW);
  final tileW = lay.tileW;
  final tileH = lay.tileH;
  final step = lay.step;
  final totalW = (slotN - 1) * step + tileW;
  final startLeft = ((stripW - totalW).clamp(0.0, double.infinity)) / 2;
  final left = startLeft + index * step;
  final cx =
      m.pad + _kDrawBandW + _kDrawHandGap + left + tileW / 2;
  final cy = m.handTop + _handTileCenterYLocal(m.handH, tileH, index);
  return Vector2(cx, cy);
}

/// 손패 슬롯 회전 — [_HandArea]와 동일(슬롯 수 고정).
double _handSlotRotationForIndex(int index) {
  return 0;
}

String _handRankKo(RummiHandRank r) => switch (r) {
      RummiHandRank.highCard => '하이',
      RummiHandRank.onePair => '원페어',
      RummiHandRank.twoPair => '투페어',
      RummiHandRank.threeOfAKind => '트리플',
      RummiHandRank.straight => '스트레이트',
      RummiHandRank.flush => '플러시',
      RummiHandRank.fullHouse => '풀하우스',
      RummiHandRank.fourOfAKind => '포카드',
      RummiHandRank.straightFlush => '스티플',
    };

/// 보드·손패·버튼 영역 레이아웃.
class RummiPlayfield extends Component with HasGameReference<RummiPokerGridGame> {
  RummiPokerGridGame? gameRef;

  Future<void> rebuild() async {
    final g = gameRef ?? game;
    for (final c in List<Component>.from(children)) {
      c.removeFromParent();
    }

    final size = g.size;
    if (size.x <= 0 || size.y <= 0) return;

    final m = _PlayfieldLayout.fromSize(size);
    final cell = m.boardSide / kBoardSize;

    await add(_BackdropChrome(size: size.clone()));

    await add(
      _HudPanel(
        position: Vector2(m.pad, m.pad),
        size: Vector2(size.x - m.pad * 2, m.hudH),
        game: g,
      ),
    );

    await add(
      _JesterSlots(
        position: Vector2(m.pad, m.jesterTop),
        size: Vector2(size.x - m.pad * 2, m.jesterH),
      ),
    );

    await add(
      _BoardGrid(
        position: Vector2((size.x - m.boardSide) / 2, m.boardTop),
        size: Vector2.all(m.boardSide),
        cellSize: cell,
        game: g,
      ),
    );

    final drawBtnH = (m.handH - 12).clamp(64.0, m.handH);
    final drawBtnY = m.handTop + (m.handH - drawBtnH) / 2;
    await add(
      _TextButton(
        position: Vector2(m.pad, drawBtnY),
        size: Vector2(_kDrawBandW, drawBtnH),
        label: '드로우',
        onTap: g.actionDraw,
        tone: _ButtonTone.draw,
      ),
    );

    await add(
      _HandArea(
        position: Vector2(
          m.pad + _kDrawBandW + _kDrawHandGap,
          m.handTop,
        ),
        size: Vector2(m.handStripW, m.handH),
        game: g,
      ),
    );

    const btnGap = 8.0;
    final rowInnerW = size.x - m.pad * 2;
    final sideBtnW = (rowInnerW * 0.24).clamp(68.0, 96.0);
    final btnW = rowInnerW - sideBtnW * 2 - btnGap * 2;
    final actionY = size.y - m.pad - _PlayfieldLayout.btnH;
    var bx = m.pad;
    await add(
      _TextButton(
        position: Vector2(bx, actionY),
        size: Vector2(sideBtnW, _PlayfieldLayout.btnH),
        label: '버림',
        onTap: g.actionDiscard,
        tone: _ButtonTone.danger,
      ),
    );
    bx += sideBtnW + btnGap;
    await add(
      _TextButton(
        position: Vector2(bx, actionY),
        size: Vector2(btnW, _PlayfieldLayout.btnH),
        label: '줄 확정',
        onTap: g.actionConfirmLines,
        tone: _ButtonTone.primary,
      ),
    );
    bx += btnW + btnGap;
    await add(
      _TextButton(
        position: Vector2(bx, actionY),
        size: Vector2(sideBtnW, _PlayfieldLayout.btnH),
        label: '선택 해제',
        onTap: () {
          g.selectHandTile(null);
        },
        tone: _ButtonTone.neutral,
      ),
    );
  }
}

class _BackdropChrome extends PositionComponent {
  _BackdropChrome({required Vector2 size})
      : super(size: size, priority: -10);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF13281C),
            _UiTheme.felt,
            Color(0xFF0A1710),
          ],
        ).createShader(rect),
    );

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.18),
        radius: 1.05,
        colors: [
          Colors.transparent,
          _UiTheme.shadow.withValues(alpha: 0.06),
          _UiTheme.shadow.withValues(alpha: 0.28),
        ],
        stops: const [0.45, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    final topGlow = Rect.fromCenter(
      center: Offset(width * 0.5, height * 0.18),
      width: width * 0.9,
      height: height * 0.22,
    );
    canvas.drawOval(
      topGlow,
      Paint()
        ..color = _UiTheme.glow.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
  }
}

class _HudPanel extends PositionComponent {
  _HudPanel({
    required super.position,
    required super.size,
    required this.game,
  });

  final RummiPokerGridGame game;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final s = game.session;
    final b = s.blind;
    final occupied = RummiPokerGridSession.countTilesOnBoard(s.board);
    final fullLines = s.engine.listFullLines(s.board);
    final scoringLines = fullLines
        .where((line) => !line.report.evaluation.isDeadLine)
        .length;
    final deadLines = fullLines.length - scoringLines;
    const small = TextStyle(
      color: _UiTheme.creamMute,
      fontSize: 9.4,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    const value = TextStyle(
      color: _UiTheme.cream,
      fontSize: 14,
      height: 1.1,
      fontWeight: FontWeight.w800,
    );
    add(
      TextComponent(
        text: 'RESOURCE',
        position: Vector2(18, 10),
        textRenderer: TextPaint(style: small),
      ),
    );
    add(
      TextComponent(
        text: '덱',
        position: Vector2(18, 27),
        textRenderer: TextPaint(style: small),
      ),
    );
    add(
      TextComponent(
        text: '${s.deck.remaining}/${s.totalDeckSize}',
        position: Vector2(18, 39),
        textRenderer: TextPaint(style: value),
      ),
    );
    add(
      TextComponent(
        text: '버림 D',
        position: Vector2(18, 61),
        textRenderer: TextPaint(style: small),
      ),
    );
    add(
      TextComponent(
        text: '${b.discardsRemaining}/${b.discardsMax}',
        position: Vector2(18, 73),
        textRenderer: TextPaint(style: value),
      ),
    );
    add(
      TextComponent(
        text: 'BLIND SCORE',
        position: Vector2(width * 0.35, 10),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.creamMute,
            fontSize: 9.4,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '${b.scoreTowardBlind} / ${b.targetScore}',
        position: Vector2(width * 0.35, 22),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.cream,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '득점줄 $scoringLines · 죽은줄 $deadLines',
        position: Vector2(width * 0.35, 50),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.creamMute,
            fontSize: 9.6,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: 'BOARD STATE',
        position: Vector2(width - 96, 10),
        textRenderer: TextPaint(style: small),
      ),
    );
    add(
      TextComponent(
        text: '$occupied/25',
        position: Vector2(width - 96, 24),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.cream,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '손패 ${s.hand.length}/${RummiPokerGridSession.kMaxHandSize}',
        position: Vector2(width - 96, 50),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.creamMute,
            fontSize: 9.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '목표 ${b.targetScore}',
        position: Vector2(width - 96, 67),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.creamMute,
            fontSize: 9.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(22),
    );
    final bodyRect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawShadow(
      Path()..addRRect(outer),
      _UiTheme.shadow.withValues(alpha: 0.48),
      14,
      false,
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B3728),
            _UiTheme.panel,
          ],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _UiTheme.line.withValues(alpha: 0.95),
    );

    final resourceRect = const Rect.fromLTWH(10, 10, 92, 82);
    final scoreRect = Rect.fromLTWH(108, 10, width - 216, 82);
    final boardRect = Rect.fromLTWH(width - 102, 10, 92, 82);
    _drawHudChip(canvas, resourceRect, alpha: 0.82);
    _drawHudChip(canvas, scoreRect, alpha: 0.68);
    _drawHudChip(canvas, boardRect, alpha: 0.82);

    final progressRect = Rect.fromLTWH(120, 68, width - 240, 7);
    final progressBack = RRect.fromRectAndRadius(
      progressRect,
      const Radius.circular(999),
    );
    canvas.drawRRect(
      progressBack,
      Paint()..color = _UiTheme.shadow.withValues(alpha: 0.92),
    );
    final ratio = game.session.blind.targetScore <= 0
        ? 0.0
        : (game.session.blind.scoreTowardBlind / game.session.blind.targetScore)
            .clamp(0.0, 1.0);
    final progressWidth = progressRect.width * ratio;
    if (progressWidth > 0) {
      final progressFill = RRect.fromRectAndRadius(
        Rect.fromLTWH(progressRect.left, progressRect.top, progressWidth, 7),
        const Radius.circular(999),
      );
      canvas.drawRRect(
        progressFill,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFE6A63C),
              _UiTheme.score,
            ],
          ).createShader(
            Rect.fromLTWH(
              progressRect.left,
              progressRect.top,
              progressWidth,
              progressRect.height,
            ),
          ),
      );
    }
  }

  void _drawHudChip(Canvas canvas, Rect rect, {double alpha = 0.72}) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _UiTheme.panel3.withValues(alpha: alpha),
            _UiTheme.panelDeep.withValues(alpha: alpha),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _UiTheme.teal.withValues(alpha: 0.14),
    );
  }
}

class _BoardGrid extends PositionComponent {
  _BoardGrid({
    required super.position,
    required super.size,
    required this.cellSize,
    required this.game,
  });

  final double cellSize;
  final RummiPokerGridGame game;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      _BoardPanelFrame(
        size: size.clone(),
      ),
    );
    final board = game.session.board;
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final t = board.cellAt(r, c);
        add(
          _BoardCell(
            position: Vector2(c * cellSize, r * cellSize),
            size: Vector2.all(cellSize),
            tile: t,
            row: r,
            col: c,
            game: game,
          ),
        );
      }
    }
    await add(
      _BoardLineOverlays(
        cellSize: cellSize,
        game: game,
        size: size.clone(),
      ),
    );
  }
}

class _JesterSlots extends PositionComponent {
  _JesterSlots({
    required super.position,
    required super.size,
  });

  @override
  void render(Canvas canvas) {
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'JESTER',
        style: TextStyle(
          color: _UiTheme.creamMute,
          fontSize: 9.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, const Offset(2, 0));

    const gap = 8.0;
    const topPad = 16.0;
    final slotW = (width - gap * 4) / 5;
    final slotH = height - topPad - 2;
    for (var i = 0; i < 5; i++) {
      final rect = Rect.fromLTWH(i * (slotW + gap), topPad, slotW, slotH);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF173326),
              Color(0xFF11261D),
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.14),
      );

      final chip = TextPainter(
        text: const TextSpan(
          text: 'J',
          style: TextStyle(
            color: _UiTheme.creamMute,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      chip.paint(
        canvas,
        Offset(rect.center.dx - chip.width / 2, rect.center.dy - 18),
      );

      final iconRect = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.center.dy + 10),
        width: 16,
        height: 12,
      );
      final icon = RRect.fromRectAndRadius(iconRect, const Radius.circular(4));
      canvas.drawRRect(
        icon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _UiTheme.creamMute.withValues(alpha: 0.45),
      );
      canvas.drawLine(
        Offset(iconRect.left + 3, iconRect.center.dy),
        Offset(iconRect.right - 3, iconRect.center.dy),
        Paint()
          ..strokeWidth = 1.4
          ..color = _UiTheme.creamMute.withValues(alpha: 0.45),
      );
      canvas.drawLine(
        Offset(iconRect.center.dx, iconRect.bottom + 2),
        Offset(iconRect.center.dx, iconRect.bottom + 8),
        Paint()
          ..strokeWidth = 1.4
          ..color = _UiTheme.creamMute.withValues(alpha: 0.45),
      );
      canvas.drawLine(
        Offset(iconRect.center.dx - 3, iconRect.bottom + 5),
        Offset(iconRect.center.dx + 3, iconRect.bottom + 5),
        Paint()
          ..strokeWidth = 1.4
          ..color = _UiTheme.creamMute.withValues(alpha: 0.45),
      );
    }
  }
}

class _BoardPanelFrame extends PositionComponent {
  _BoardPanelFrame({required Vector2 size})
      : super(size: size, priority: -2);

  @override
  void render(Canvas canvas) {
    final pad = 7.0;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(-pad, -pad, width + pad * 2, height + pad * 2),
      const Radius.circular(22),
    );
    canvas.drawShadow(
      Path()..addRRect(outer),
      _UiTheme.shadow.withValues(alpha: 0.5),
      16,
      false,
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF184434),
            Color(0xFF102B21),
          ],
        ).createShader(Rect.fromLTWH(-pad, -pad, width + pad * 2, height + pad * 2)),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _UiTheme.line.withValues(alpha: 0.95),
    );
  }
}

/// 5칸이 찬 줄에 족보 라벨·하이라이트(투페어 등).
class _BoardLineOverlays extends PositionComponent {
  _BoardLineOverlays({
    required this.cellSize,
    required this.game,
    required super.size,
  }) : super(priority: 8);

  final double cellSize;
  final RummiPokerGridGame game;

  /// 족보 완성(점수 줄) — 외곽선만.
  static const Color _scoreEdge = Color(0xFFE65100);
  static const Color _scoreLabel = Color(0xFF263D0D);

  /// 죽은 줄(하이·원페어) — 외곽선만.
  static const Color _deadEdge = Color(0xFF37474F);
  static const Color _deadLabel = Color(0xFFECEFF1);

  @override
  void render(Canvas canvas) {
    final lines = game.session.engine.listFullLines(game.session.board);
    for (final e in lines) {
      final ev = e.report.evaluation;
      final dead = ev.isDeadLine;
      final strokeColor = dead ? _deadEdge : _scoreEdge;
      final glowColor = dead
          ? _deadEdge.withValues(alpha: 0.18)
          : _scoreEdge.withValues(alpha: 0.18);
      final fillPaint = Paint()..color = glowColor;
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dead ? 1.6 : 2.0
        ..color = strokeColor;
      for (final (rr, cc) in e.ref.cells()) {
        final rect = Rect.fromLTWH(
          cc * cellSize,
          rr * cellSize,
          cellSize,
          cellSize,
        );
        final rrct = RRect.fromRectAndRadius(rect, const Radius.circular(5));
        canvas.drawRRect(rrct, fillPaint);
        canvas.drawRRect(rrct, edge);
      }

      final o = _lineRankLabelOffset(e.ref, cellSize);
      final badge = _lineLabelRect(
        center: o,
        text: _handRankKo(ev.rank),
        dead: dead,
      );
      final badgeRRect = RRect.fromRectAndRadius(
        badge.inflate(0.5),
        const Radius.circular(999),
      );
      canvas.drawShadow(
        Path()..addRRect(badgeRRect),
        _UiTheme.shadow.withValues(alpha: 0.36),
        6,
        false,
      );
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..color = dead
              ? _UiTheme.slate.withValues(alpha: 0.92)
              : _scoreLabel.withValues(alpha: 0.94),
      );
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = strokeColor.withValues(alpha: dead ? 0.45 : 0.8),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: _handRankKo(ev.rank),
          style: TextStyle(
            color: dead ? _deadLabel : _scoreLabel,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: dead ? 2 : 1.5,
                color: dead ? Colors.black54 : const Color(0x66FFF8E1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(o.dx - tp.width / 2, o.dy - tp.height / 2));
    }
  }
}

Rect _lineLabelRect({
  required Offset center,
  required String text,
  required bool dead,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: dead ? _UiTheme.mist : _BoardLineOverlays._scoreLabel,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = tp.width + 16;
  final h = tp.height + 7;
  return Rect.fromCenter(center: center, width: w, height: h);
}

Offset _lineRankLabelOffset(LineRef ref, double cs) {
  switch (ref.kind) {
    case LineKind.row:
      return Offset(cs * 2.5, cs * (ref.index + 0.22));
    case LineKind.col:
      return Offset(cs * (ref.index + 0.52), cs * 0.26);
    case LineKind.diagMain:
      return Offset(cs * 1.28, cs * 1.2);
    case LineKind.diagAnti:
      return Offset(cs * 3.68, cs * 1.2);
  }
}

class _BoardCell extends PositionComponent with TapCallbacks {
  _BoardCell({
    required super.position,
    required super.size,
    required this.tile,
    required this.row,
    required this.col,
    required this.game,
  });

  final Tile? tile;
  final int row;
  final int col;
  final RummiPokerGridGame game;

  @override
  void render(Canvas canvas) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(6),
    );
    final bg = Paint()..color = const Color(0xFF1B3326);
    final innerGlow = Paint()
      ..color = const Color(0x1429B36B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawRRect(rr, bg);
    canvas.drawRRect(rr, innerGlow);
    canvas.drawRRect(rr, border);
    if (tile != null) {
      const inset = 2.5;
      paintRummikubTile(
        canvas,
        Rect.fromLTWH(
          inset,
          inset,
          width - inset * 2,
          height - inset * 2,
        ),
        tile!,
        selected: game.boardCellSelected(row, col),
        shadowElevation: 1.5,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (tile != null) {
      game.toggleBoardTileSelect(row, col);
    } else {
      game.tryPlaceOnCell(row, col);
    }
  }
}

class _HandArea extends PositionComponent {
  _HandArea({
    required super.position,
    required super.size,
    required this.game,
  });

  final RummiPokerGridGame game;

  @override
  void render(Canvas canvas) {
    final lay = _handStripLayout(width);
    final totalW = (_kHandSlotCount - 1) * lay.step + lay.tileW;
    final startLeft = ((width - totalW).clamp(0.0, double.infinity)) / 2;
    for (var i = 0; i < _kHandSlotCount; i++) {
      final left = startLeft + i * lay.step;
      final cy = _handTileCenterYLocal(height, lay.tileH, i);
      final slotRect = Rect.fromCenter(
        center: Offset(left + lay.tileW / 2, cy),
        width: lay.tileW + 10,
        height: lay.tileH + 4,
      );
      final slot = RRect.fromRectAndRadius(
        slotRect,
        const Radius.circular(14),
      );
      canvas.drawRRect(slot, Paint()..color = Colors.transparent);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final hand = game.session.hand;
    final fi = game.flyingDrawHandIndex;
    if (hand.isEmpty) return;

    final slotN = _kHandSlotCount;
    final lay = _handStripLayout(width);
    final tileW = lay.tileW;
    final tileH = lay.tileH;
    final step = lay.step;
    final totalW = (slotN - 1) * step + tileW;
    final startLeft = ((width - totalW).clamp(0.0, double.infinity)) / 2;

    for (var i = 0; i < hand.length; i++) {
      if (fi != null && i == fi) {
        continue;
      }
      final t = hand[i];
      final sel = game.selectedHandTile;
      final isSel = sel != null && sel == t;
      final left = startLeft + i * step;
      final cx = left + tileW / 2;
      final cy = height * 0.58;
      final rot = _handSlotRotationForIndex(i);
      // 선택 패를 나머지보다 위에 그림(Flame priority).
      final z = isSel ? 60 : 48;

      add(
        _HandTileButton(
          position: Vector2(cx, cy),
          size: Vector2(tileW, tileH),
          anchor: Anchor.center,
          angle: rot,
          priority: z,
          tile: t,
          selected: isSel,
          onTap: () => game.selectHandTile(t),
        ),
      );
    }
  }
}

class _HandTileButton extends PositionComponent with TapCallbacks {
  _HandTileButton({
    required super.position,
    required super.size,
    super.angle,
    super.anchor,
    super.priority,
    required this.tile,
    required this.selected,
    required this.onTap,
  });

  final Tile tile;
  final bool selected;
  final void Function() onTap;

  @override
  void render(Canvas canvas) {
    paintRummikubTile(
      canvas,
      Rect.fromLTWH(0, 0, width, height),
      tile,
      selected: selected,
      shadowElevation: 3,
    );
  }

  @override
  void onTapDown(TapDownEvent event) => onTap();
}

/// 드로우 시 오른쪽 화면 밖에서 손패 슬롯으로 이동.
class _FlyingDrawTile extends PositionComponent {
  _FlyingDrawTile({
    required this.tile,
    required Vector2 start,
    required this.end,
    required Vector2 size,
    required double angle,
    required this.onDone,
  })  : _start = start.clone(),
        super(
          position: start.clone(),
          size: size,
          anchor: Anchor.center,
          angle: angle,
          priority: 62,
        );

  final Tile tile;
  final Vector2 end;
  final Vector2 _start;
  final void Function() onDone;

  double _elapsed = 0;
  bool _finished = false;
  static const _dur = 0.42;

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;
    _elapsed += dt;
    final u = (_elapsed / _dur).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(u);
    position = _start + (end - _start) * e;
    if (u >= 1.0) {
      _finished = true;
      onDone();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    paintRummikubTile(
      canvas,
      Rect.fromLTWH(0, 0, width, height),
      tile,
      shadowElevation: 4,
    );
  }
}

class _TextButton extends PositionComponent with TapCallbacks {
  _TextButton({
    required super.position,
    required super.size,
    required this.label,
    required this.onTap,
    this.tone = _ButtonTone.neutral,
  });

  final String label;
  final void Function() onTap;
  final _ButtonTone tone;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      TextComponent(
        text: label,
        position: Vector2(width / 2, height / 2),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: _UiTheme.cream,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(tone == _ButtonTone.draw ? 18 : 18),
    );
    final bgRect = Rect.fromLTWH(0, 0, width, height);
    final colors = switch (tone) {
      _ButtonTone.primary => const [Color(0xFFFFB12A), Color(0xFFE78A1A)],
      _ButtonTone.danger => const [Color(0xFF3A4D45), Color(0xFF25342D)],
      _ButtonTone.draw => const [Color(0xFF1D6E5E), Color(0xFF145145)],
      _ButtonTone.neutral => const [Color(0xFF324A42), Color(0xFF263730)],
    };
    final borderColor = switch (tone) {
      _ButtonTone.primary => const Color(0xFFFFE2A6).withValues(alpha: 0.5),
      _ButtonTone.danger => Colors.white.withValues(alpha: 0.09),
      _ButtonTone.draw => const Color(0xFF9FE3BD).withValues(alpha: 0.28),
      _ButtonTone.neutral => Colors.white.withValues(alpha: 0.12),
    };
    final glowColor = switch (tone) {
      _ButtonTone.primary => const Color(0x33FFB12A),
      _ButtonTone.danger => const Color(0x14000000),
      _ButtonTone.draw => const Color(0x2247D2A0),
      _ButtonTone.neutral => const Color(0x14000000),
    };
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = borderColor;
    canvas.drawShadow(
      Path()..addRRect(rr),
      _UiTheme.shadow.withValues(alpha: 0.42),
      9,
      false,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(bgRect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = glowColor,
    );
    canvas.drawRRect(rr, border);

  }

  @override
  void onTapDown(TapDownEvent event) => onTap();
}
