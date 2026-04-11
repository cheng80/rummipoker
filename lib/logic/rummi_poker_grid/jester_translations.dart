import 'dart:convert';

class JesterTranslations {
  JesterTranslations._(this._map);

  factory JesterTranslations.fromJsonString(String jsonString) {
    final root = jsonDecode(jsonString) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;
    final jesters = data?['jesters'] as Map<String, dynamic>?;
    return JesterTranslations._(jesters ?? const {});
  }

  factory JesterTranslations.empty() => JesterTranslations._(const {});

  final Map<String, dynamic> _map;

  String? displayName(String jesterId) {
    final entry = _map[jesterId] as Map<String, dynamic>?;
    return entry?['displayName'] as String?;
  }

  String? effectText(String jesterId) {
    final entry = _map[jesterId] as Map<String, dynamic>?;
    return entry?['effectText'] as String?;
  }

  String? notes(String jesterId) {
    final entry = _map[jesterId] as Map<String, dynamic>?;
    return entry?['notes'] as String?;
  }

  String resolveDisplayName(String jesterId, String fallback) {
    return displayName(jesterId) ?? fallback;
  }

  String resolveEffectText(String jesterId, String fallback) {
    return effectText(jesterId) ?? fallback;
  }
}
