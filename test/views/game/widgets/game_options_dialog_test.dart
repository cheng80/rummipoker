import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/widgets/game_options_dialog.dart';
import '../../../support/test_translations.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets(
    'Game options stays open on barrier tap and follows locale changes',
    (tester) async {
      late BuildContext localeContext;
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
                home: Builder(
                  builder: (context) {
                    return Scaffold(
                      body: Center(
                        child: ElevatedButton(
                          key: const ValueKey('open-options'),
                          onPressed: () {
                            showGameOptionsDialog(
                              context: context,
                              runSeed: 123,
                              activeRunSaveView: const RummiActiveRunSaveFacade(
                                schemaVersion: 2,
                                activeScene: 'shop',
                                sceneAlias: RummiSaveSceneAlias.market,
                                currentStageIndex: 3,
                                currentStationIndex: 3,
                                currentRunSeed: 123,
                                currentGold: 27,
                                checkpoint: RummiStationCheckpointSaveView(
                                  stageIndex: 3,
                                  stationIndex: 3,
                                  runSeed: 123,
                                  gold: 10,
                                ),
                              ),
                              onRestartRun: () async => false,
                              onExitToTitle: () async => false,
                              isDebugFixtureRun: false,
                            );
                          },
                          child: const Text('open'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open-options')));
      await tester.pumpAndSettle();

      expect(find.text('옵션'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('튜토리얼 다시 보기'), findsOneWidget);
      expect(find.text('전투 기본 조작 안내를 다시 봅니다.'), findsOneWidget);
      expect(find.text('북마크하기'), findsOneWidget);
      expect(find.text('북마크 불러오기'), findsOneWidget);
      expect(find.text('현재 전투 재시작'), findsOneWidget);
      expect(find.text('현재 Station 재시작'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.text('옵션'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);

      await localeContext.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Bookmark Run'), findsOneWidget);
      expect(find.text('Restart Battle'), findsOneWidget);
      expect(find.text('북마크하기'), findsNothing);
      expect(
        find.text('Current Station 3 · Market · Gold 27\nCheckpoint Station 3'),
        findsOneWidget,
      );
      expect(
        find.text('현재 Station 3 · Market · Gold 27\n체크포인트 Station 3'),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Game Dialog'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Bookmark Run'), findsNothing);
    },
  );
}
