/// Card emblem asset path helpers.
class CardEmblemAssets {
  CardEmblemAssets._();

  static const String _basePath = 'assets/images/cards/emblems_4x';

  static String jester(String id) => '$_basePath/jester_$id.png';

  static String item(String id) => '$_basePath/item_$id.png';
}
