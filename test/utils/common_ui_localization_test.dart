import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';

class _TranslationLoader extends AssetLoader {
  const _TranslationLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

Future<BuildContext> openLocalizedDialog(
  WidgetTester tester,
  void Function(BuildContext) open,
) async {
  late BuildContext screen;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      assetLoader: const _TranslationLoader(),
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Builder(
            builder: (context) {
              screen = context;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => open(context),
                  child: const Text('open'),
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
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return screen;
}

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets(
    'open confirmation rebuilds text, semantics and default buttons',
    (tester) async {
      bool? result;
      final screen = await openLocalizedDialog(tester, (context) async {
        result = await showConfirmDialog(
          context,
          titleBuilder: (c) => c.translate('runInfoTitle'),
          messageBuilder: (c) => c.translate('gameTermsTitle'),
        );
      });
      expect(find.text('런 정보'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
      await screen.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Run Info'), findsOneWidget);
      expect(find.text('Game Terms'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('런 정보'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Run Info',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );

  testWidgets(
    'explicit labels stay literal and label builders take precedence',
    (tester) async {
      bool? result;
      final screen = await openLocalizedDialog(tester, (context) async {
        result = await showConfirmDialog(
          context,
          title: 'literal title',
          message: 'literal message',
          cancelLabel: 'keep literal',
          confirmLabel: 'overridden',
          confirmLabelBuilder: (c) => c.translate('continueGame'),
        );
      });
      await screen.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('literal title'), findsOneWidget);
      expect(find.text('literal message'), findsOneWidget);
      expect(find.text('keep literal'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('overridden'), findsNothing);
      await tester.tap(find.text('keep literal'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );

  testWidgets(
    'choice action builder follows locale and preserves typed results',
    (tester) async {
      int? result;
      final screen = await openLocalizedDialog(tester, (context) async {
        result = await showGameChoiceDialog<int>(
          context,
          title: 'old title',
          message: 'old message',
          titleBuilder: (c) => c.translate('runInfoTitle'),
          messageBuilder: (c) => c.translate('gameTermsTitle'),
          actions: const [GameDialogAction(label: 'old action', value: -1)],
          actionsBuilder: (c) => [
            GameDialogAction(label: c.translate('ok'), value: 7),
          ],
        );
      });
      await screen.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Run Info'), findsOneWidget);
      expect(find.text('Game Terms'), findsOneWidget);
      expect(find.text('old action'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, 7);
    },
  );
}
