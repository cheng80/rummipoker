import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../resources/asset_paths.dart';
import '../bingo_card_game.dart';

/// 게임 상단 HUD. 타임 패널과 힌트 말풍선을 직접 렌더링한다.
class GameHud extends PositionComponent
    with HasGameReference<BingoCardGame> {
  GameHud();

  String _timeStr = '0.00';
  String _hintStr = '1';

  late double _panelCx;
  late double _panelCy;
  late double _panelW;
  late double _panelH;

  late double _hintCx;
  late double _hintCy;
  late double _hintR;

  late TextPainter _timeLabelPainter;
  late TextPainter _timePainter;
  late double _timeRefWidth; // "00.00" 기준 너비, 털림 방지용
  late TextPainter _hintLabelPainter;
  late TextPainter _hintValuePainter;
  TextPainter? _bestScoreLabelPainter;
  TextPainter? _bestScoreValuePainter;

  late double _bestScoreCx;
  late double _bestScoreCy;
  bool _showBestScore = false;
  String? _cachedBestScoreStr;
  late _PauseButton _pauseButton;

  /// HUD 레이아웃 계산 및 타임/힌트 페인터 초기화.
  /// layoutRef 기준으로 스케일해 가로가 긴 웹 화면에서 과도한 확대 방지.
  @override
  Future<void> onLoad() async {
    _pauseButton = _PauseButton(onPressed: game.pauseGame);
    add(_pauseButton);
    _layoutHud();
  }

  /// 창 크기 변경 시 HUD 레이아웃 재계산.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutHud();
  }

  /// 로케일 변경 시 HUD 재계산.
  void onLocaleChanged() {
    _layoutHud();
  }

  /// 상단 HUD 비율 계수 (hudScale 기준)
  static const double _kPanelWFactor = 2.8;
  static const double _kBtnSizeFactor = 0.5;

  void _layoutHud() {
    final scale = game.hudScale;
    priority = 10;

    // 타임 패널: 비율로 계산 (아이패드에서도 적절한 크기)
    _panelW = scale * _kPanelWFactor;
    _panelH = game.panelH;
    _panelCx = game.safeContentCenterX;
    _panelCy = game.panelCenterY;

    // 힌트 말풍선: 비율로 계산
    _hintR = game.hintR;
    _hintCx = game.safeContentRight - _hintR - 8;
    _hintCy = game.hintCenterY;

    _buildTimePainters();
    _buildHintPainters();

    // Best score: Pause-Hint 사이 (비율에 맞춰 표시 여부)
    final btnSize = scale * _kBtnSizeFactor;
    _pauseButton
      ..size = Vector2.all(btnSize)
      ..position = Vector2(
        game.safeContentLeft + 12,
        game.hintCenterY - btnSize / 2,
      );
    final pauseRight = game.safeContentLeft + 12 + btnSize;
    final hintLeft = _hintCx - _hintR;
    final gap = hintLeft - pauseRight;
    _showBestScore = gap > scale * 0.8;
    _bestScoreCx = (pauseRight + hintLeft) / 2;
    _bestScoreCy = _hintCy;
    _cachedBestScoreStr = game.formattedBestScore;
    if (_showBestScore && _cachedBestScoreStr != null) {
      _buildBestScorePainters();
    }
  }

  void _buildBestScorePainters() {
    if (_cachedBestScoreStr == null) {
      _bestScoreLabelPainter = null;
      _bestScoreValuePainter = null;
      return;
    }
    final scale = _hintR / 42;
    final bestScoreLabel = game.localeString('bestScore', 'Best score');
    _bestScoreLabelPainter = TextPainter(
      text: TextSpan(
        text: bestScoreLabel,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: Colors.white70,
          fontSize: 12 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _bestScoreValuePainter = TextPainter(
      text: TextSpan(
        text: _cachedBestScoreStr,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: Colors.amber,
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// 타임 패널용 TextPainter 생성 (라벨 + 숫자).
  /// 패널 높이 대비 스케일을 낮춰 라벨·숫자 겹침 방지.
  void _buildTimePainters() {
    final scale = _panelH / 110;
    final timeScoreLabel = game.localeString('timeScore', 'time score');
    _timeLabelPainter = TextPainter(
      text: TextSpan(
        text: timeScoreLabel,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: Colors.white70,
          fontSize: 26 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _timePainter = _createTimePainter(_timeStr);
    _timeRefWidth = _createTimePainter('00.00').width;
  }

  /// [text]로 타임 숫자용 TextPainter를 생성한다.
  TextPainter _createTimePainter(String text) {
    final scale = _panelH / 110;
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: Colors.white,
          fontSize: 38 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// 힌트 말풍선용 TextPainter 생성 (라벨 + 값).
  /// 원 크기(_hintR) 기준 스케일 → 여유 있게 키울 수 있음.
  void _buildHintPainters() {
    final scale = _hintR / 38;
    final hintLabel = game.localeString('hint', 'Hint');
    _hintLabelPainter = TextPainter(
      text: TextSpan(
        text: hintLabel,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: const Color(0xFF555555),
          fontSize: 12 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _hintValuePainter = _createHintPainter(_hintStr);
  }

  /// [text]로 힌트 값용 TextPainter를 생성한다.
  TextPainter _createHintPainter(String text) {
    final scale = _hintR / 38;
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: const Color(0xFF2145BD),
          fontSize: 28 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// 경과 시간을 베스트 스코어와 동일 포맷으로 갱신. 60초 미만(초.밀리), 1분+(34m 50.33), 1시간+(13h 20m 51.22).
  void updateTime(double elapsed) {
    final formatted = BingoCardGame.formatTime(elapsed);
    if (formatted == _timeStr) return;
    _timeStr = formatted;
    _timePainter = _createTimePainter(_timeStr);
  }

  /// 힌트에 표시할 숫자/알파벳을 갱신한다.
  void updateHint(String label) {
    if (label == _hintStr) return;
    _hintStr = label;
    _hintValuePainter = _createHintPainter(_hintStr);
  }

  /// 베스트 스코어가 변경되었는지 확인하고 페인터를 갱신한다.
  @override
  void update(double dt) {
    super.update(dt);
    if (!_showBestScore) return;
    final current = game.formattedBestScore;
    if (current != _cachedBestScoreStr) {
      _cachedBestScoreStr = current;
      _buildBestScorePainters();
    }
  }

  /// 타임 패널과 힌트 말풍선을 캔버스에 그린다.
  @override
  void render(Canvas canvas) {
    _renderTimePanel(canvas);
    if (_showBestScore &&
        _bestScoreLabelPainter != null &&
        _bestScoreValuePainter != null) {
      _renderBestScore(canvas);
    }
    _renderHintBubble(canvas);
  }

  /// Pause-Hint 사이에 Best score를 그린다.
  void _renderBestScore(Canvas canvas) {
    final label = _bestScoreLabelPainter!;
    final value = _bestScoreValuePainter!;
    final totalH = label.height + 4 + value.height;
    final top = _bestScoreCy - totalH / 2;
    label.paint(
      canvas,
      Offset(_bestScoreCx - label.width / 2, top),
    );
    value.paint(
      canvas,
      Offset(_bestScoreCx - value.width / 2, top + label.height + 4),
    );
  }

  /// 상단 중앙의 갈색 타임 패널을 그린다.
  void _renderTimePanel(Canvas canvas) {
    final panelScale = _panelH / 110;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(_panelCx, _panelCy),
        width: _panelW,
        height: _panelH,
      ),
      Radius.circular(_panelH / 2),
    );

    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(_panelCx, _panelCy - _panelH / 2),
        Offset(_panelCx, _panelCy + _panelH / 2),
        [const Color(0xFF4A3728), const Color(0xFF2E1E14)],
      );
    canvas.drawRRect(rect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF6B4E37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * panelScale;
    canvas.drawRRect(rect, borderPaint);

    // time score 라벨: 패널 상단 중앙.
    final labelTopPadding = 8.0 * panelScale;
    _timeLabelPainter.paint(
      canvas,
      Offset(
        _panelCx - _timeLabelPainter.width / 2,
        _panelCy - _panelH / 2 + labelTopPadding,
      ),
    );

    // 타임 숫자: 고정폭 부모 + 왼쪽 정렬로 털림 방지.
    // 부모는 패널 중앙, 짧은 텍스트(00.00)가 중앙에 오도록 padding → 길어지면 오른쪽으로 확장.
    final timeParentWidth = _panelW * 0.72;
    final timeBottomPadding = 12.0 * panelScale;
    final parentLeft = _panelCx - timeParentWidth / 2;
    final padding = (timeParentWidth - _timeRefWidth) / 2;
    final timeX = parentLeft + padding;
    final timeY = _panelCy + _panelH / 2 - _timePainter.height - timeBottomPadding;
    _timePainter.paint(canvas, Offset(timeX, timeY));
  }

  /// 우측 상단의 흰색 힌트 말풍선을 그린다.
  void _renderHintBubble(Canvas canvas) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(_hintCx, _hintCy), _hintR, bgPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(_hintCx, _hintCy + 2),
      _hintR,
      shadowPaint,
    );
    canvas.drawCircle(Offset(_hintCx, _hintCy), _hintR, bgPaint);

    final tailPath = Path()
      ..moveTo(_hintCx - 8, _hintCy + _hintR - 4)
      ..lineTo(_hintCx - 14, _hintCy + _hintR + 10)
      ..lineTo(_hintCx + 2, _hintCy + _hintR - 2)
      ..close();
    canvas.drawPath(tailPath, bgPaint);

    _hintLabelPainter.paint(
      canvas,
      Offset(
        _hintCx - _hintLabelPainter.width / 2,
        _hintCy - _hintR / 2 - 2,
      ),
    );

    _hintValuePainter.paint(
      canvas,
      Offset(
        _hintCx - _hintValuePainter.width / 2,
        _hintCy - _hintValuePainter.height / 2 + 6,
      ),
    );
  }
}

class _PauseButton extends PositionComponent with TapCallbacks {
  _PauseButton({required this.onPressed}) : super(anchor: Anchor.topLeft);

  final VoidCallback onPressed;

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.25),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    final barW = size.x * 0.14;
    final barH = size.x * 0.45;
    final gap = size.x * 0.12;
    final cx = size.x / 2;
    final cy = size.y / 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - gap, cy),
          width: barW,
          height: barH,
        ),
        Radius.circular(barW * 0.3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + gap, cy),
          width: barW,
          height: barH,
        ),
        Radius.circular(barW * 0.3),
      ),
      paint,
    );
  }
}
