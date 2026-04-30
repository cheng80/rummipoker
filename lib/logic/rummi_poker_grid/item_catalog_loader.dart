import 'package:flutter/services.dart' show rootBundle;

import 'item_definition.dart';

/// Flutter asset bundle에서 Item catalog를 읽어 순수 JSON parser에 위임한다.
class ItemCatalogLoader {
  const ItemCatalogLoader._();

  static Future<ItemCatalog> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return ItemCatalog.fromJsonString(jsonString);
  }
}
