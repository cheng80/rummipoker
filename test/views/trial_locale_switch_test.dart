import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/views/home_placeholder_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/test_translations.dart';

void main() {
  testWidgets('open trial follows five locales at small width', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const locales = [
      Locale('ko'),
      Locale('en'),
      Locale('ja'),
      Locale('zh', 'CN'),
      Locale('zh', 'TW'),
    ];
    late BuildContext localeContext;
    await tester.pumpWidget(
      EasyLocalization(
        assetLoader: const TestTranslationAssetLoader(),
        supportedLocales: locales,
        path: 'assets/translations',
        startLocale: locales.first,
        fallbackLocale: locales.first,
        saveLocale: false,
        child: Builder(
          builder: (context) {
            localeContext = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const TrialPlaceholderView(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    final initial = tester.state(find.byType(HomePlaceholderView));
    for (final locale in locales) {
      await localeContext.setLocale(locale);
      await tester.pumpAndSettle();
      final strings =
          jsonDecode(
                File(
                  'assets/translations/${locale.toLanguageTag()}.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final key in [
        'homeSpecialModeTitle',
        'commonUiTrialSummary',
        'commonUiTrialCardTitle',
        'commonUiTrialStructure',
        'commonUiTrialPolicy',
        'commonUiTrialDebug',
      ]) {
        expect(
          find.text(strings[key] as String),
          findsOneWidget,
          reason: '$locale $key',
        );
      }
      expect(tester.state(find.byType(HomePlaceholderView)), same(initial));
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
