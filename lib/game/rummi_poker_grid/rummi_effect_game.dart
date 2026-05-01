import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'rummi_particle_burst.dart';

/// Flutter 보드 위에 얹는 presentation 전용 Flame 레이어.
///
/// 런타임 결과를 계산하지 않고, 외부에서 전달받은 좌표에 짧은 파티클만 그린다.
class RummiEffectGame extends FlameGame {
  RummiParticlePool? _particlePool;
  final List<List<Vector2>> _pendingLineBursts = [];

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    _particlePool = RummiParticlePool(world);
    for (final centers in _pendingLineBursts) {
      _spawnLineConfirmBurstNow(centers);
    }
    _pendingLineBursts.clear();
  }

  void spawnLineConfirmBurst(Iterable<Vector2> centers) {
    final copiedCenters = centers.toList(growable: false);
    if (_particlePool == null) {
      _pendingLineBursts.add(copiedCenters);
      return;
    }
    _spawnLineConfirmBurstNow(copiedCenters);
  }

  void _spawnLineConfirmBurstNow(Iterable<Vector2> centers) {
    final pool = _particlePool;
    if (pool == null) return;
    for (final center in centers) {
      pool.spawn(
        center: center,
        baseColor: const Color(0xFFF2C14E),
        count: 12,
        lifetime: 0.68,
        speedScale: 0.76,
        sizeScale: 0.95,
        withGlow: false,
      );
    }
  }
}
