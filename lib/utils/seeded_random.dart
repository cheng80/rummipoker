import 'dart:math';

/// 저장/복원이 가능한 경량 PRNG.
///
/// 이어하기에서 중요한 것은 "같은 시점의 다음 난수"가 같아지는 것이다.
/// `dart:math Random`의 내부 상태는 복원할 수 없으므로, 세션용 RNG는
/// 상태를 직접 저장할 수 있는 구현을 사용한다.
class SeededRandom implements Random {
  SeededRandom(int seed) : _state = _normalize(seed);

  SeededRandom.fromState(int state) : _state = _normalize(state);

  int _state;

  int get state => _state;

  static int _normalize(int value) {
    final masked = value & 0x7fffffff;
    return masked == 0 ? 1 : masked;
  }

  int _nextState() {
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    if (_state == 0) {
      _state = 1;
    }
    return _state;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => _nextState() / 0x80000000;

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw RangeError.range(max, 1, null, 'max');
    }
    return _nextState() % max;
  }
}
