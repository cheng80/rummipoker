import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../views/game/widgets/game_ui_palette.dart';
import 'rummi_particle_burst.dart';

/// Flutter 보드 위에 얹는 presentation 전용 Flame 레이어.
///
/// 런타임 결과를 계산하지 않고, 외부에서 전달받은 좌표에 짧은 파티클만 그린다.
class RummiEffectGame extends FlameGame {
  RummiParticlePool? _particlePool;
  final List<_PendingBoardBurst> _pendingBoardBursts = [];

  @override
  Color backgroundColor() => GameUiPalette.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    _particlePool = RummiParticlePool(world);
    for (final burst in _pendingBoardBursts) {
      _spawnBoardBurstNow(burst);
    }
    _pendingBoardBursts.clear();
  }

  void spawnLineConfirmBurst(Iterable<Vector2> centers) {
    _spawnBoardBurst(
      _PendingBoardBurst(
        centers: centers.toList(growable: false),
        baseColor: GameUiPalette.actionGoldBright,
        count: 12,
        lifetime: 0.68,
        speedScale: 0.76,
        sizeScale: 0.95,
        withGlow: false,
      ),
    );
  }

  void spawnConstraintImpactBurst(Iterable<Vector2> centers) {
    _spawnBoardBurst(
      _PendingBoardBurst(
        centers: centers.toList(growable: false),
        baseColor: GameUiPalette.effectConstraint,
        count: 14,
        lifetime: 0.54,
        speedScale: 1.05,
        sizeScale: 1.1,
        withGlow: true,
      ),
    );
  }

  void spawnLargeScoreBurst(Iterable<Vector2> centers) {
    _spawnBoardBurst(
      _PendingBoardBurst(
        centers: centers.toList(growable: false),
        baseColor: GameUiPalette.settlementActive,
        count: 18,
        lifetime: 0.72,
        speedScale: 1.18,
        sizeScale: 1.18,
        withGlow: true,
      ),
    );
  }

  void _spawnBoardBurst(_PendingBoardBurst burst) {
    if (_particlePool == null) {
      _pendingBoardBursts.add(burst);
      return;
    }
    _spawnBoardBurstNow(burst);
  }

  void _spawnBoardBurstNow(_PendingBoardBurst burst) {
    final pool = _particlePool;
    if (pool == null) return;
    for (final center in burst.centers) {
      pool.spawn(
        center: center,
        baseColor: burst.baseColor,
        count: burst.count,
        lifetime: burst.lifetime,
        speedScale: burst.speedScale,
        sizeScale: burst.sizeScale,
        withGlow: burst.withGlow,
      );
    }
  }
}

class _PendingBoardBurst {
  const _PendingBoardBurst({
    required this.centers,
    required this.baseColor,
    required this.count,
    required this.lifetime,
    required this.speedScale,
    required this.sizeScale,
    required this.withGlow,
  });

  final List<Vector2> centers;
  final Color baseColor;
  final int count;
  final double lifetime;
  final double speedScale;
  final double sizeScale;
  final bool withGlow;
}
