import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/utils/active_run_translation.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';

const _known = RummiActiveRunSaveFacade(
  schemaVersion: 2,
  activeScene: 'shop',
  sceneAlias: RummiSaveSceneAlias.market,
  difficulty: NewRunDifficulty.challenge,
  runModifier: NewRunModifier.highStakes,
  currentStageIndex: 9,
  currentStationIndex: 9,
  currentBlindTierIndex: 2,
  currentRunSeed: 42,
  currentGold: 27,
  checkpoint: RummiStationCheckpointSaveView(
    stageIndex: 8,
    stationIndex: 8,
    runSeed: 42,
    gold: 10,
  ),
);
const _manual = RummiActiveRunSaveFacade(
  schemaVersion: 2,
  activeScene: 'battle',
  sceneAlias: RummiSaveSceneAlias.battle,
  difficultyLabel: 'Custom difficulty',
  runModifierLabel: 'Custom modifier',
  currentStageIndex: 1,
  currentStationIndex: 1,
  currentBlindTierIndex: -1,
  currentRunSeed: 42,
  currentGold: 10,
  checkpoint: RummiStationCheckpointSaveView(
    stageIndex: 1,
    stationIndex: 1,
    runSeed: 42,
    gold: 10,
  ),
);
const _locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  test('enum keys and Blind prerequisites preserve gameplay IDs', () {
    expect(NewRunDifficulty.values.map((d) => d.labelKey), [
      'menuStandard',
      'menuLegacyRules',
      'menuChallenge',
    ]);
    expect(NewRunModifier.values.map((m) => m.id), ['basic', 'high_stakes']);
    expect(NewRunModifier.values.map((m) => m.labelKey), [
      'menuBasicRun',
      'menuHighStakes',
    ]);
    for (var cleared = -1; cleared <= 2; cleared++) {
      final specs = BlindSelectionSpecBuilder.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: cleared,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      );
      expect(
        specs[1].requiredClearedTier,
        cleared < 0 ? BlindTier.small : null,
      );
      expect(specs[2].requiredClearedTier, cleared < 1 ? BlindTier.big : null);
    }
    expect(_manual.difficulty, isNull);
    expect(_manual.runModifier, isNull);
    expect(
      _manual.bookmarkLabel,
      contains('Custom difficulty · Custom modifier'),
    );
  });

  testWidgets(
    'save displays and open continue dialog follow all five locales',
    (tester) async {
      late BuildContext screen;
      final spec = BlindSelectionSpecBuilder.buildForStation(
        stationIndex: 1,
        clearedBlindTierIndex: -1,
        difficulty: NewRunDifficulty.standard,
        ruleset: RummiRuleset.currentDefaults,
      )[1];
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: _locales,
          startLocale: const Locale('ko'),
          fallbackLocale: const Locale('ko'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Loader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Builder(
                builder: (context) {
                  screen = context;
                  return Scaffold(
                    body: Column(
                      children: [
                        Text(
                          context.activeRunSlotTitle(
                            const ActiveRunBookmarkSlotView(
                              slotIndex: 0,
                              summary: null,
                            ),
                          ),
                        ),
                        Text(
                          context.activeRunSlotLabel(
                            const ActiveRunBookmarkSlotView(
                              slotIndex: 0,
                              summary: null,
                            ),
                          ),
                        ),
                        Text(context.activeRunBookmark(_known)),
                        Text(context.activeRunBookmark(_manual)),
                        Text(context.blindLockReason(spec)),
                        ElevatedButton(
                          key: const ValueKey('open-continue'),
                          onPressed: () {
                            showGameChoiceDialog<void>(
                              context,
                              titleBuilder: (c) =>
                                  c.translate('homeContinueSectionTitle'),
                              messageBuilder: (c) =>
                                  c.activeRunContinueMessage(_known),
                              actionsBuilder: (c) => [
                                GameDialogAction<void>(
                                  label: c.translate('cancel'),
                                  value: null,
                                ),
                              ],
                            );
                          },
                          child: const Text('open'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-continue')));
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await screen.setLocale(locale);
        await tester.pumpAndSettle();
        final values =
            jsonDecode(
                  File(
                    'assets/translations/${locale.toLanguageTag()}.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        String tr(String key, [Map<String, String> args = const {}]) {
          var value = values[key] as String;
          for (final entry in args.entries) {
            value = value.replaceAll('{${entry.key}}', entry.value);
          }
          return value;
        }

        final location = tr('coreSaveLocation', {
          'station': '9',
          'scene': tr('coreSaveSceneMarket'),
          'gold': '27',
        });
        final checkpoint = tr('coreSaveCheckpoint', {'station': '8'});
        final message = tr('coreSaveContinue', {
          'summary': tr('coreSaveSnapshot', {
            'location': location,
            'checkpoint': checkpoint,
          }),
        });
        expect(find.text(message), findsOneWidget);
        expect(
          find.text(
            tr('coreSaveSlotTitle', {'slot': '1'}),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.text(tr('coreSaveEmpty'), skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text(
            tr('coreSaveBookmark', {
              'station': '∞S9',
              'mode': tr('coreSaveModeModifier', {
                'difficulty': tr('menuChallenge'),
                'modifier': tr('menuHighStakes'),
              }),
              'blind': 'BOSS',
            }),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Custom difficulty · Custom modifier',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            tr('coreSaveBlindUnlock', {'required': 'Scout', 'blind': 'Clash'}),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      Navigator.of(screen).pop();
      await tester.pumpAndSettle();
    },
  );
}
