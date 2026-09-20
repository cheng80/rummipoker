// Proves the translation call standard in docs/core/I18N.md.
//
// A player can open the settings and change the language while a battle screen
// is still on screen. The text on that screen has to follow. This test shows
// that `context.translate` does follow and that easy_localization's global
// `'key'.tr()` does not, which is the reason the project standardised on the
// former.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/views/game/widgets/game_run_info_dialog.dart';
import '../support/test_translations.dart';

/// Both labels are const, so nothing marks them dirty when their parent
/// rebuilds. Only a dependency on `Localizations` can bring them back.
class _ContextLabel extends StatelessWidget {
  const _ContextLabel();

  @override
  Widget build(BuildContext context) =>
      Text(context.translate('runInfoTitle'), key: const Key('context-label'));
}

class _GlobalLabel extends StatelessWidget {
  const _GlobalLabel();

  @override
  Widget build(BuildContext context) =>
      Text('runInfoTitle'.tr(), key: const Key('global-label'));
}

String _textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    EasyLocalization(
      assetLoader: const TestTranslationAssetLoader(),
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: home,
        ),
      ),
    ),
  );
  // EasyLocalization loads its assets asynchronously and Localizations resolves
  // its delegates on a later microtask, so one settle is not always enough.
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('a language change reaches the screen and the open dialog', (
    tester,
  ) async {
    late BuildContext screenContext;
    await _pumpApp(
      tester,
      Builder(
        builder: (context) {
          screenContext = context;
          return Scaffold(
            body: Column(
              children: [
                const _ContextLabel(),
                const _GlobalLabel(),
                ElevatedButton(
                  onPressed: () => showGameRunInfoDialog(
                    context: context,
                    playedHandCounts: const {RummiHandRank.flush: 2},
                  ),
                  child: const Text('open'),
                ),
              ],
            ),
          );
        },
      ),
    );

    expect(_textOf(tester, 'context-label'), '런 정보');
    expect(_textOf(tester, 'global-label'), '런 정보');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('타일 기준 칩'), findsOneWidget);

    await screenContext.setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    // The dialog is a separate route, and it follows the change too.
    expect(find.text('Chips by tile'), findsOneWidget);
    expect(find.text('Run Info'), findsNWidgets(2));
    expect(find.text('Flush'), findsOneWidget);
    expect(find.text('플러시'), findsNothing);
    expect(find.text('런 정보'), findsOneWidget);
    expect(find.text('타일 기준 칩'), findsNothing);

    expect(_textOf(tester, 'context-label'), 'Run Info');
    expect(
      _textOf(tester, 'global-label'),
      '런 정보',
      reason:
          'a const widget using the global tr() stays stale; this is why '
          'screen code uses context.translate instead',
    );
  });
}
