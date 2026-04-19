import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 래퍼. 앱 전역에서 사용하는 로컬 저장소 관리.
class StorageHelper {
  StorageHelper._();

  static SharedPreferences? _prefs;

  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'StorageHelper.init() must be awaited before using storage APIs.',
      );
    }
    return prefs;
  }

  /// 초기화 (앱 시작 시 호출)
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static void resetForTest() {
    _prefs = null;
  }

  /// 읽기. 없으면 null.
  static T? read<T>(String key) => _instance.get(key) as T?;

  /// 쓰기
  static Future<void> write(String key, dynamic value) async {
    final prefs = _instance;
    switch (value) {
      case bool v:
        await prefs.setBool(key, v);
      case int v:
        await prefs.setInt(key, v);
      case double v:
        await prefs.setDouble(key, v);
      case String v:
        await prefs.setString(key, v);
      case List<String> v:
        await prefs.setStringList(key, v);
      case null:
        await prefs.remove(key);
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported SharedPreferences value type: ${value.runtimeType}',
        );
    }
  }

  /// 삭제
  static Future<void> remove(String key) => _instance.remove(key);

  /// 전체 삭제
  static Future<void> erase() => _instance.clear();

  /// 키 존재 여부
  static bool hasData(String key) => _instance.containsKey(key);

  /// bool 읽기 (기본값 포함)
  static bool readBool(String key, {bool defaultValue = false}) =>
      _instance.getBool(key) ?? defaultValue;

  /// double 읽기 (기본값 포함)
  static double readDouble(String key, {double defaultValue = 0.0}) =>
      (_instance.getDouble(key) ?? defaultValue).toDouble();

  /// int 읽기 (기본값 포함)
  static int readInt(String key, {int defaultValue = 0}) =>
      (_instance.getInt(key) ?? defaultValue).toInt();

  /// String 읽기 (기본값 포함)
  static String readString(String key, {String defaultValue = ''}) =>
      _instance.getString(key) ?? defaultValue;
}
