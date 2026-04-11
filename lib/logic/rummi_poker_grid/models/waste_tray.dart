import 'tile.dart';

/// 임시 슬롯 최대 3 (GDD §2.3). 빈 슬롯은 `null`.
class WasteTray {
  WasteTray({int capacity = kWasteCapacity})
      : assert(capacity > 0),
        _slots = List<Tile?>.filled(capacity, null);

  static const int kWasteCapacity = 3;

  final List<Tile?> _slots;

  int get capacity => _slots.length;

  Tile? operator [](int i) => _slots[i];

  /// 첫 빈 슬롯에 놓기. 없으면 `false`.
  bool tryPlace(Tile tile) {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) {
        _slots[i] = tile;
        return true;
      }
    }
    return false;
  }

  void removeAt(int index) {
    assert(index >= 0 && index < _slots.length);
    _slots[index] = null;
  }

  void clear() {
    for (var i = 0; i < _slots.length; i++) {
      _slots[i] = null;
    }
  }

  int get occupiedCount {
    var n = 0;
    for (final t in _slots) {
      if (t != null) n++;
    }
    return n;
  }
}
