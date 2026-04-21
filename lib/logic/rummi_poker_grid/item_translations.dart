import 'dart:convert';

class ItemTranslations {
  ItemTranslations._(this._map);

  factory ItemTranslations.fromJsonString(String jsonString) {
    final root = jsonDecode(jsonString) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;
    final items = data?['items'] as Map<String, dynamic>?;
    return ItemTranslations._(items ?? const {});
  }

  factory ItemTranslations.empty() => ItemTranslations._(const {});

  final Map<String, dynamic> _map;

  String? displayName(String itemId) {
    final entry = _map[itemId] as Map<String, dynamic>?;
    return entry?['displayName'] as String?;
  }

  String? effectText(String itemId) {
    final entry = _map[itemId] as Map<String, dynamic>?;
    return entry?['effectText'] as String?;
  }

  String resolveDisplayName(String itemId, String fallback) {
    return displayName(itemId) ?? fallback;
  }

  String resolveEffectText(String itemId, String fallback) {
    return effectText(itemId) ?? fallback;
  }
}
