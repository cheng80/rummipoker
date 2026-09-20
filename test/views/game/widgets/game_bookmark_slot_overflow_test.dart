import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_bookmark_slot_dialog.dart';
import '../../../support/test_translations.dart';

void main() {
  testWidgets('작은 화면의 긴 북마크 세 슬롯은 넘치지 않고 마지막 슬롯을 선택한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runtime = buildInitialRunRuntime(
      const GameSessionArgs(runSeed: 2147483647),
    );
    final summary = RummiActiveRunSaveFacade.fromRuntimeState(runtime);
    int? selected;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const TestTranslationAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const ValueKey('open-slots'),
                  onPressed: () async {
                    selected = await showBookmarkSlotDialog(
                      context: context,
                      title: 'Load bookmark',
                      message: 'Choose a saved run to restore.',
                      slots: [
                        for (var i = 0; i < 3; i++)
                          ActiveRunBookmarkSlotView(
                            slotIndex: i,
                            summary: summary,
                          ),
                      ],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-slots')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final last = find.text('Slot 3');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
