import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/resources/card_emblem_assets.dart';

void main() {
  test('all catalog item emblem asset paths exist', () {
    final catalog = ItemCatalog.fromJsonString(
      File('data/common/items_common_v1.json').readAsStringSync(),
    );

    for (final item in catalog.all) {
      final assetPath = CardEmblemAssets.item(item.id);
      expect(File(assetPath).existsSync(), isTrue, reason: item.id);
    }
  });
}
