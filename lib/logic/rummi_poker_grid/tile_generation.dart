import 'dart:math';

import 'models/poker_deck.dart';
import 'models/tile.dart';

Tile generateRandomMarketStyleTile({
  required Random rng,
  required int stageIndex,
  int offerIndex = 0,
}) {
  final allTiles = buildStandardPokerDeck(copiesPerTile: 1);
  final tile = allTiles[rng.nextInt(allTiles.length)];
  return decorateTileWithMarketStyleModifiers(
    tile,
    stageIndex: stageIndex,
    offerIndex: offerIndex,
  );
}

Tile decorateTileWithMarketStyleModifiers(
  Tile tile, {
  required int stageIndex,
  required int offerIndex,
}) {
  final enhancementChance = stageIndex >= 6
      ? 45
      : stageIndex >= 3
      ? 30
      : 15;
  final seed = _tileOfferModifierSeed(
    tile,
    stageIndex: stageIndex,
    offerIndex: offerIndex,
  );
  if (_tileOfferRoll(seed, 11) >= enhancementChance) {
    return tile;
  }

  final enhancementPool = stageIndex >= 3
      ? const [
          TileEnhancement.chipInlaid,
          TileEnhancement.scoreGilded,
          TileEnhancement.goldTile,
          TileEnhancement.glassTile,
        ]
      : const [
          TileEnhancement.chipInlaid,
          TileEnhancement.scoreGilded,
          TileEnhancement.goldTile,
        ];
  final enhancement =
      enhancementPool[_tileOfferRoll(seed, 23) % enhancementPool.length];
  final seal = stageIndex >= 4 && _tileOfferRoll(seed, 37) < 20
      ? (_tileOfferRoll(seed, 41).isEven ? TileSeal.blueSeal : TileSeal.redSeal)
      : null;
  final edition = stageIndex >= 5 && _tileOfferRoll(seed, 43) < 12
      ? const [
          TileEdition.silverEdition,
          TileEdition.glowEdition,
          TileEdition.prismEdition,
        ][_tileOfferRoll(seed, 47) % TileEdition.values.length]
      : null;
  return Tile(
    color: tile.color,
    number: tile.number,
    id: tile.id,
    enhancement: enhancement,
    seal: seal,
    edition: edition,
  );
}

int _tileOfferModifierSeed(
  Tile tile, {
  required int stageIndex,
  required int offerIndex,
}) {
  return Object.hash(
    stageIndex,
    offerIndex,
    tile.color.index,
    tile.number,
    tile.id,
  );
}

int _tileOfferRoll(int seed, int salt) {
  var value = seed ^ (salt * 0x45d9f3b);
  value = ((value >> 16) ^ value) * 0x45d9f3b;
  value = ((value >> 16) ^ value) * 0x45d9f3b;
  value = (value >> 16) ^ value;
  return value.abs() % 100;
}
