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
  });
}
