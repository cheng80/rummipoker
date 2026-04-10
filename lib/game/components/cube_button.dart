import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../resources/asset_paths.dart';

/// 5×5 그리드의 개별 큐브.
/// 둥근 사각형 배경 위에 숫자/알파벳 텍스트를 그린다.
class CubeButton extends PositionComponent with TapCallbacks {
  final int id;
  final String label;
  final Color btnColor;
  final Color outlineColor;
  final List<Color>? gradientColors;
  final void Function(CubeButton) onTap;

  /// 그리드 인덱스 (0~24). 리사이즈 시 위치/크기 갱신에 사용.
  final int gridIndex;

  bool _isActive = true;
  bool _isBlinking = false;
  double _blinkTime = 0;
  double _alpha = 1.0;
  bool _isFading = false;
  double _fadeDuration = 0;
  double _fadeElapsed = 0;
  VoidCallback? _fadeOnComplete;

  late Paint _bgPaint;
  late Paint _blinkPaint;
  late TextPainter _textPainter;
  late TextPainter _strokePainter;

  CubeButton({
    required this.id,
    required this.label,
    required this.btnColor,
    required this.outlineColor,
    this.gradientColors,
    required super.position,
    required super.size,
    required this.onTap,
    required this.gridIndex,
  }) : super(anchor: Anchor.center) {
    _bgPaint = Paint()..color = btnColor;
    _blinkPaint = Paint()..color = Colors.white.withValues(alpha: 0);
  }

  /// 페인트와 텍스트 페인터 초기화.
  @override
  Future<void> onLoad() async {
    _preparePaints();
    _prepareText();
  }

  /// 리사이즈 시 size 변경 후 호출. 페인트·텍스트를 새 크기에 맞게 갱신.
  void refreshForResize() {
    _preparePaints();
    _prepareText();
  }

  /// gradientColors가 있으면 그라데이션 셰이더, 없으면 단색으로 _bgPaint 설정.
  void _preparePaints() {
    if (gradientColors != null) {
      _bgPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors!,
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    }
  }

  /// label용 TextPainter 생성. 외곽선(stroke)과 채우기(text) 두 개.
  /// 단일 두꺼운 stroke는 곡선에서 깨져 보이므로, 8방향 얇은 stroke로 부드럽게.
  void _prepareText() {
    // 큐브 크기에 비례한 폰트/외곽선 두께.
    final fontSize = size.x * 0.45;
    final strokeW = size.x * 0.03; // 얇게 해서 8방향으로 여러 번 그리기

    _strokePainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeJoin = StrokeJoin.round
            ..color = outlineColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// 배경, 내부 테두리, 힌트 오버레이, 텍스트를 그린다. 페이드 중이면 saveLayer로 알파 적용.
  @override
  void render(Canvas canvas) {
    if (!_isActive && !_isFading) return;

    // 페이드아웃 중: saveLayer로 전체 알파 적용.
    if (_alpha < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.white.withValues(alpha: _alpha),
      );
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.2),
    );

    canvas.drawRRect(rect, _bgPaint);

    // 큐브 내부 테두리(안쪽 스트로크).
    final strokeWidth = size.x * 0.04;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.x - strokeWidth,
        size.y - strokeWidth,
      ),
      Radius.circular(size.x * 0.18),
    );
    canvas.drawRRect(
      innerRect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (_isBlinking) {
      canvas.drawRRect(rect, _blinkPaint);
    }

    // 텍스트 중앙 정렬. 8방향으로 얇은 stroke를 여러 번 그려 깨짐 없이 부드러운 아웃라인.
    final cx = (size.x - _textPainter.width) / 2;
    final cy = (size.y - _textPainter.height) / 2;
    final d = size.x * 0.015; // 오프셋 간격
    for (final dx in [-d, 0, d]) {
      for (final dy in [-d, 0, d]) {
        if (dx != 0 || dy != 0) {
          _strokePainter.paint(canvas, Offset(cx + dx, cy + dy));
        }
      }
    }
    _textPainter.paint(canvas, Offset(cx, cy));

    if (_alpha < 1.0) {
      canvas.restore();
    }
  }

  /// 페이드아웃·깜박임 애니메이션 진행. 완료 시 removeFromParent 및 콜백 호출.
  @override
  void update(double dt) {
    super.update(dt);

    if (_isFading) {
      _fadeElapsed += dt;
      // 선형 감쇠: duration 동안 1.0 → 0.0
      _alpha = (1.0 - (_fadeElapsed / _fadeDuration)).clamp(0.0, 1.0);
      if (_fadeElapsed >= _fadeDuration) {
        _isFading = false;
        removeFromParent();
        _fadeOnComplete?.call();
      }
    }

    if (_isBlinking) {
      // cos 기반 부드러운 깜박임: alpha 0.15~0.5 사이 진동.
      _blinkTime += dt;
      final t = (_blinkTime * 1.2).remainder(1.0);
      final alpha = 0.15 + 0.35 * (0.5 + 0.5 * cos(t * 2 * pi));
      _blinkPaint.color = Colors.white.withValues(alpha: alpha);
    }
  }

  /// 탭 시 활성 상태면 onTap 콜백 호출.
  @override
  void onTapDown(TapDownEvent event) {
    if (_isActive) onTap(this);
  }

  /// 정답 시: 알파가 빠지면서 한 바퀴 회전 후 사라짐
  void animateCorrect(VoidCallback onComplete) {
    _isActive = false;
    stopBlink();

    const duration = 0.3;
    _isFading = true;
    _fadeDuration = duration;
    _fadeElapsed = 0;
    _fadeOnComplete = onComplete;

    add(
      RotateEffect.by(
        2 * pi,
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    );
  }

  /// 오답 시: 좌우로 5→-10→10→-5 이동 후 원위치.
  void animateWrong() {
    final originalX = position.x;
    add(
      SequenceEffect([
        MoveByEffect(
          Vector2(5, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(-10, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(10, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(-5, 0),
          EffectController(duration: 0.05),
        ),
      ], onComplete: () {
        position.x = originalX;
      }),
    );
  }

  /// 교체 큐브의 페이드인 애니메이션
  void animateFadeIn() {
    // HasPaint mixin이 없으므로 scale로 표현
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.3, curve: Curves.easeOutBack),
      ),
    );
  }

  /// 힌트용 깜박임 애니메이션을 시작한다.
  void startBlink() {
    _isBlinking = true;
    _blinkTime = 0;
  }

  /// 깜박임을 중지하고 오버레이 알파를 0으로 만든다.
  void stopBlink() {
    _isBlinking = false;
    _blinkPaint.color = Colors.white.withValues(alpha: 0);
  }
}
