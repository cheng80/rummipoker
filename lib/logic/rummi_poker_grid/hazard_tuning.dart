/// 턴 경과에 따른 점수 가산·감산 튜닝 (밸런스 미확정 시 기본 0).
///
/// 죽은 줄 방치, 평가 완료 줄을 두고 안 터뜨리는 경우 등 — **플레이 테스트 후** 수치 확정.
/// 추후 **곱셈·조건부**가 필요하면 숫자 필드 대신 [LineHazardFormula] 콜백 등으로 교체한다.
class LineHazardTuning {
  const LineHazardTuning({
    this.deadLineCarryPerTurnAdd = 0,
    this.evaluatedLineIdlePerTurnAdd = 0,
  });

  /// 죽은 줄(하이카드·원페어)을 **보드에 둔 채** 1턴이 지날 때마다 총점에 더할 값 (음수면 감점).
  final double deadLineCarryPerTurnAdd;

  /// 족보가 나온 **완성 줄을 대기**만 하고 확정하지 않은 1턴당 총점에 더할 값 (미확정 로직용).
  final double evaluatedLineIdlePerTurnAdd;

  /// 효과 없음 (기본 빌드).
  static const LineHazardTuning none = LineHazardTuning();
}

/// 향후 수식·조건부가 필요할 때 [LineHazardTuning] 대신 주입.
typedef LineHazardFormula = double Function(LineHazardContext);

/// 턴 종료 시 위험 가중에 넘길 최소 맥락 (필요 시 필드 추가).
class LineHazardContext {
  const LineHazardContext({
    this.turnIndex = 0,
  });

  final int turnIndex;
}
