import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/archive_view.dart';
import '../support/test_translations.dart';

void main() {
  testWidgets('open Item and Jester details use official translated catalogs', (
    tester,
  ) async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    await RunUnlockStateService.recordRunCollection(
      const RunCollectionUpdate(
        boughtJesterIds: {'jester'},
        boughtItemIds: {'coin_cache'},
      ),
    );
    late BuildContext localeContext;
    await tester.pumpWidget(
      EasyLocalization(
        assetLoader: const TestTranslationAssetLoader(),
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            localeContext = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const JesterTranslationScope(
                child: ItemTranslationScope(
                  child: Scaffold(body: ArchiveView()),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    for (final key in ['archive-jester-jester', 'archive-item-coin_cache']) {
      final card = find.byKey(ValueKey(key));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
    }
    await localeContext.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    for (final (kind, id) in [('items', 'coin_cache'), ('jesters', 'jester')]) {
      final catalog =
          jsonDecode(
                File(
                  'assets/translations/data/en/$kind.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final entry = catalog['data'][kind][id] as Map<String, dynamic>;
      expect(
        find.text(entry['displayName'] as String),
        findsAtLeastNWidgets(1),
      );
      expect(find.text(entry['effectText'] as String), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
