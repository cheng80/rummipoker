import 'package:firebase_analytics/firebase_analytics.dart';

typedef AnalyticsEventSink =
    Future<void> Function(String name, Map<String, Object> parameters);

class GameAnalyticsContext {
  const GameAnalyticsContext({
    this.enabled = true,
    this.debugFixture = false,
    this.queryParameters = const {},
  });

  final bool enabled;
  final bool debugFixture;
  final Map<String, String> queryParameters;

  bool get shouldLog {
    if (!enabled || debugFixture) return false;
    return !queryParameters.keys.any(_isDebugAutomationKey);
  }

  static bool _isDebugAutomationKey(String key) {
    return key == 'fixture' ||
        key == 'auto_advance_market' ||
        key == 'auto_enter_market' ||
        key == 'auto_cashout_loop' ||
        key.startsWith('debug_');
  }
}

class GameAnalyticsService {
  GameAnalyticsService({AnalyticsEventSink? sink})
    : _sink =
          sink ??
          ((name, parameters) {
            return FirebaseAnalytics.instance.logEvent(
              name: name,
              parameters: parameters,
            );
          });

  static GameAnalyticsService instance = GameAnalyticsService();

  static void debugSetInstanceForTest(GameAnalyticsService service) {
    instance = service;
  }

  static void debugResetForTest() {
    instance = GameAnalyticsService();
  }

  static const int maxNameLength = 40;
  static const int maxStringValueLength = 100;
  static const int maxParamsPerEvent = 25;

  final AnalyticsEventSink _sink;

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
    GameAnalyticsContext context = const GameAnalyticsContext(),
  }) async {
    if (!context.shouldLog) return;
    final eventName = _safeName(name);
    final eventParameters = _safeParameters(parameters);
    try {
      await _sink(eventName, eventParameters);
    } catch (_) {
      // Analytics must never break gameplay.
    }
  }

  Map<String, Object> _safeParameters(Map<String, Object?> parameters) {
    final result = <String, Object>{};
    for (final entry in parameters.entries) {
      if (result.length >= maxParamsPerEvent) break;
      final value = entry.value;
      if (value == null) continue;
      result[_safeName(entry.key)] = _safeValue(value);
    }
    return result;
  }

  Object _safeValue(Object value) {
    if (value is String) {
      return value.length <= maxStringValueLength
          ? value
          : value.substring(0, maxStringValueLength);
    }
    if (value is num || value is bool) return value;
    final text = value.toString();
    return text.substring(0, text.length.clamp(0, maxStringValueLength));
  }

  String _safeName(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isUpper = codeUnit >= 65 && codeUnit <= 90;
      final isLower = codeUnit >= 97 && codeUnit <= 122;
      final isUnderscore = codeUnit == 95;
      buffer.writeCharCode(
        isDigit || isUpper || isLower || isUnderscore ? codeUnit : 95,
      );
    }
    var safe = buffer.toString();
    if (safe.isEmpty || !_startsWithLetter(safe)) {
      safe = 'x_$safe';
    }
    if (_hasReservedPrefix(safe)) {
      safe = 'app_$safe';
    }
    if (safe.length > maxNameLength) {
      safe = safe.substring(0, maxNameLength);
    }
    return safe;
  }

  bool _startsWithLetter(String value) {
    final codeUnit = value.codeUnitAt(0);
    return codeUnit >= 65 && codeUnit <= 90 ||
        codeUnit >= 97 && codeUnit <= 122;
  }

  bool _hasReservedPrefix(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('firebase_') ||
        lower.startsWith('google_') ||
        lower.startsWith('ga_');
  }
}
