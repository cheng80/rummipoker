import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';

const _locales = ['ko', 'en', 'ja', 'zh-CN', 'zh-TW'];

Map<String, dynamic> _translations(String locale) =>
    jsonDecode(
          File('assets/translations/src/core/$locale.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  final ko = _translations('ko');
  final legacy =
      (jsonDecode(
                File(
                  'test/logic/fixtures/boss_modifier_legacy_json.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();

  test(
    'known Boss keys cover every catalog entry without changing Korean text',
    () {
      final keys = <String>{};
      expect(RummiBossModifier.allKnownModifiers, hasLength(28));
      for (final boss in RummiBossModifier.allKnownModifiers) {
        final display = boss.displayKeys!;
        expect(display, rummiBossDisplayKeys(boss.id));
        keys.addAll([
          display.titleKey,
          display.ruleTextKey,
          display.markerTextKey,
        ]);
        expect(ko[display.titleKey], boss.title, reason: boss.id);
        expect(ko[display.ruleTextKey], boss.ruleText, reason: boss.id);
        expect(ko[display.markerTextKey], boss.markerText, reason: boss.id);
        final penalty = RummiConstraintPenaltyBreakdown(
          modifierId: boss.id,
          title: boss.title,
          ruleText: boss.ruleText,
          markerText: boss.markerText,
          scoreDelta: -10,
          scoreMultiplier: boss.scoreMultiplier,
        );
        expect(penalty.displayKeys, display);
      }
      expect(keys, hasLength(84));
      expect(RummiBossModifier.redDampener.displayKeys, (
        titleKey: 'coreBossRedDampenerTitle',
        ruleTextKey: 'coreBossRedDampenerRule',
        markerTextKey: 'coreBossRedDampenerMarker',
      ));
    },
  );

  test('unknown IDs return null and retain custom text for UI fallback', () {
    final custom = RummiBossModifier.fromJson(legacy.last);
    expect(custom.displayKeys, isNull);
    expect(custom.title, '사용자 Boss');
    expect(custom.ruleText, '사용자 규칙 17%');
    expect(custom.markerText, '사용자');
    for (final id in ['', 'red_dampener_v2', 'RED_DAMPENER_V1']) {
      expect(rummiBossDisplayKeys(id), isNull);
    }
    final penalty = RummiConstraintPenaltyBreakdown(
      modifierId: custom.id,
      title: custom.title,
      ruleText: custom.ruleText,
      markerText: custom.markerText,
      scoreDelta: -17,
      scoreMultiplier: custom.scoreMultiplier,
    );
    expect(penalty.displayKeys, isNull);
    expect(penalty.title, custom.title);
    expect(penalty.ruleText, custom.ruleText);
    expect(penalty.markerText, custom.markerText);
  });

  test(
    'pre-change saved JSON stays identical for all known and custom Bosses',
    () {
      expect(legacy, hasLength(29));
      for (final saved in legacy) {
        final restored = RummiBossModifier.fromJson(saved);
        expect(restored.toJson(), saved, reason: saved['id'] as String);
        expect(jsonEncode(restored.toJson()), jsonEncode(saved));
        if (restored.displayKeys != null) {
          expect(RummiBossModifier.allKnownModifiers, contains(same(restored)));
        }
      }
      for (final boss in RummiBossModifier.allKnownModifiers) {
        expect(
          boss.toJson(),
          legacy.singleWhere((json) => json['id'] == boss.id),
        );
      }
    },
  );

  test('known saved ID still overrides old display fields on restore', () {
    final saved = Map<String, dynamic>.from(legacy.first)
      ..['title'] = 'old title'
      ..['ruleText'] = 'old rule'
      ..['markerText'] = 'old marker';
    final boss = RummiBossModifier.fromJson(saved);
    expect(boss, same(RummiBossModifier.redDampener));
    expect(boss.toJson(), legacy.first);
  });

  test('all hand ranks have stable unique keys and retain legacy labels', () {
    const expectedKeys = [
      'coreHandRankHighCard',
      'coreHandRankOnePair',
      'coreHandRankTwoPair',
      'coreHandRankThreeOfAKind',
      'coreHandRankStraight',
      'coreHandRankFlush',
      'coreHandRankFullHouse',
      'coreHandRankFourOfAKind',
      'coreHandRankStraightFlush',
      'coreHandRankPrismStraight',
      'coreHandRankCrownFourOfAKind',
      'coreHandRankLowStraightFlush',
      'coreHandRankRoyalStraightFlush',
      'coreHandRankFiveOfAKind',
      'coreHandRankFlushHouse',
      'coreHandRankFlushFive',
    ];
    expect(RummiHandRank.values.map(rummiHandRankKey), expectedKeys);
    for (final rank in RummiHandRank.values) {
      expect(ko[rummiHandRankKey(rank)], rummiHandRankLabel(rank));
    }
  });

  test('five locale fragments contain all display keys and fixed rules', () {
    final expected = {
      for (final rank in RummiHandRank.values) rummiHandRankKey(rank),
      for (final boss in RummiBossModifier.allKnownModifiers) ...[
        boss.displayKeys!.titleKey,
        boss.displayKeys!.ruleTextKey,
        boss.displayKeys!.markerTextKey,
      ],
    };
    expect(expected, hasLength(100));
    for (final locale in _locales) {
      final translations = _translations(locale);
      expect(translations.keys.toSet(), ko.keys.toSet(), reason: locale);
      expect(translations.keys, containsAll(expected), reason: locale);
      for (final entry in translations.entries.where(
        (entry) => expected.contains(entry.key),
      )) {
        expect(entry.value, isA<String>(), reason: '$locale ${entry.key}');
        expect((entry.value as String).trim(), isNotEmpty);
        expect(
          entry.value,
          isNot(matches(RegExp(r'[{}]'))),
          reason: 'This fixed catalog contract has no namedArgs',
        );
      }
      for (final boss in RummiBossModifier.allKnownModifiers) {
        final rule = translations[boss.displayKeys!.ruleTextKey] as String;
        if (boss.scoreMultiplier < 1) {
          final percent = ((1 - boss.scoreMultiplier) * 100).round();
          expect(rule, contains('$percent%'), reason: '$locale ${boss.id}');
        }
        if (boss.category == RummiBossModifierCategory.boardCellBlock &&
            boss != RummiBossModifier.blockFourCorners &&
            boss != RummiBossModifier.blockCornersCenter) {
          expect(
            rule,
            contains('${boss.blockedCells.length}'),
            reason: '$locale ${boss.id} blocked cell count',
          );
        }
      }
    }
  });
}
