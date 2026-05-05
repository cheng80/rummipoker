import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';

void main() {
  group('JesterTranslations', () {
    test('phase5 catalog has Korean translations without card-deck terms', () {
      final catalogJson = File(
        'data/common/jesters_common_phase5.json',
      ).readAsStringSync();
      final translationJson = File(
        'assets/translations/data/ko/jesters.json',
      ).readAsStringSync();

      final catalog = RummiJesterCatalog.fromJsonString(catalogJson);
      final translationData =
          jsonDecode(translationJson) as Map<String, dynamic>;
      final translatedJesters =
          (translationData['data'] as Map<String, dynamic>)['jesters']
              as Map<String, dynamic>;

      for (final card in catalog.all) {
        expect(
          translatedJesters,
          contains(card.id),
          reason: '${card.id} is missing Korean translation',
        );
      }

      const blockedTerms = [
        '페이스',
        '스페이드',
        '하트',
        '다이아몬드',
        '클럽',
        '에이스',
        '잭',
        '퀸',
        '킹',
        '슈트',
        '포커',
        '랭크',
        '핸드',
        '카드',
        'Mult',
        'Chips',
        'Gold',
        r'$',
        'Ace',
        'Jack',
        'Queen',
        'King',
        'Straight',
        'Flush',
        'Full House',
      ];
      for (final entry in translatedJesters.entries) {
        final value = entry.value as Map<String, dynamic>;
        final visibleText = [
          value['displayName'],
          value['effectText'],
          value['notes'],
        ].whereType<String>().join(' ');
        for (final term in blockedTerms) {
          expect(
            visibleText,
            isNot(contains(term)),
            reason: '${entry.key} exposes card-deck term "$term"',
          );
        }
      }
    });

    test('phase5 catalog separates mid-run engine Jesters by rarity', () {
      final catalogJson = File(
        'data/common/jesters_common_phase5.json',
      ).readAsStringSync();
      final catalog = RummiJesterCatalog.fromJsonString(catalogJson);

      expect(catalog.findById('green_jester')!.rarity, RummiJesterRarity.rare);
      expect(catalog.findById('fibonacci')!.rarity, RummiJesterRarity.rare);
      expect(catalog.findById('banner')!.rarity, RummiJesterRarity.rare);
      expect(catalog.findById('supernova')!.rarity, RummiJesterRarity.rare);
      expect(
        catalog.findById('ride_the_bus')!.rarity,
        RummiJesterRarity.uncommon,
      );
      expect(catalog.findById('popcorn')!.rarity, RummiJesterRarity.uncommon);
      expect(catalog.findById('ice_cream')!.rarity, RummiJesterRarity.uncommon);
    });

    test('player-facing Jester data does not restore legacy source names', () {
      final deprecatedCatalogJson = File(
        'data/common/jesters_common.json',
      ).readAsStringSync();
      final playerFacingText = [
        deprecatedCatalogJson,
        File('data/common/jesters_common_phase5.json').readAsStringSync(),
        File('assets/translations/data/ko/jesters.json').readAsStringSync(),
        File('assets/translations/data/en/jesters.json').readAsStringSync(),
      ].join('\n');

      final deprecatedCatalog =
          jsonDecode(deprecatedCatalogJson) as Map<String, dynamic>;
      expect(deprecatedCatalog['status'], 'deprecated');
      expect(
        deprecatedCatalog['replacement'],
        'data/common/jesters_common_phase5.json',
      );
      expect(deprecatedCatalog['entries'], isEmpty);

      const blockedSourceMarkers = [
        'sourceNotes',
        '"origin": "fandom"',
        'fandom',
      ];
      for (final term in blockedSourceMarkers) {
        expect(
          playerFacingText,
          isNot(contains(term)),
          reason: 'Jester data must not carry source marker "$term"',
        );
      }

      const blockedLegacyNames = [
        'Green Jester',
        'Jolly Jester',
        'Zany Jester',
        'Mad Jester',
        'Crazy Jester',
        'Droll Jester',
        'Sly Jester',
        'Wily Jester',
        'Clever Jester',
        'Devious Jester',
        'Crafty Jester',
        'Half Jester',
        'Joker Stencil',
        'Four Fingers',
        'Credit Card',
        'Ceremonial Dagger',
        'Mystic Summit',
        'Marble Joker',
        'Loyalty Card',
        'Raised Fist',
        'Chaos the Clown',
        'Steel Joker',
        'Scary Face',
        'Delayed Gratification',
        'Business Card',
        'Ride the Bus',
        'Space Joker',
        'Blue Joker',
        'Green Joker',
        'To Do List',
        'Card Sharp',
        'Red Card',
        'Square Joker',
        'Midas Mask',
        'Gift Card',
        'Turtle Bean',
        'Reserved Parking',
        'Mail-In Rebate',
        'To the Moon',
        'Fortune Teller',
        'Stone Joker',
        'Golden Joker',
        'Lucky Cat',
        'Baseball Card',
        'Trading Card',
        'Flash Card',
        'Smiley Face',
        'Mr. Bones',
        'Sock and Buskin',
        'Smeared Joker',
        'Glass Joker',
        'Wee Joker',
        'Merry Andy',
        'Oops! All 6s',
        'The Idol',
        'Seeing Double',
        'Hit the Road',
        'The Duo',
        'The Trio',
        'The Family',
        'The Order',
        'The Tribe',
        "Driver's License",
        'Shoot the Moon',
        'Burnt Joker',
      ];
      for (final term in blockedLegacyNames) {
        expect(
          playerFacingText,
          isNot(contains(term)),
          reason: 'Jester data restored legacy name "$term"',
        );
      }
    });
  });
}
