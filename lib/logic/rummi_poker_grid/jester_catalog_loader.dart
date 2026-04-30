import 'package:flutter/services.dart' show rootBundle;

import 'jester_meta.dart';

/// Flutter asset bundle에서 Jester catalog를 읽어 순수 JSON parser에 위임한다.
class RummiJesterCatalogLoader {
  const RummiJesterCatalogLoader._();

  static Future<RummiJesterCatalog> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return RummiJesterCatalog.fromJsonString(jsonString);
  }
}
