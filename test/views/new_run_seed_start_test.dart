import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/device_key_store.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import 'package:rummipoker/views/home_entry_widgets.dart';
import 'package:rummipoker/views/new_run_view.dart';

class _MemoryDeviceKeyStore implements DeviceKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String nextValue) async {
    value = nextValue;
  }
}

class _FailingActiveRecordStore extends InMemorySharedPreferencesStore {
  _FailingActiveRecordStore.withData(super.data) : super.withData();

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (key == 'flutter.${StorageKeys.activeRunRecordV1}') {
      return Future<bool>.value(false);
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    overrideDeviceKeyStoreForTest(_MemoryDeviceKeyStore());
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Rummi Poker',
      packageName: 'rummipoker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    SoundManager.debugResetForTest();
  });

  tearDown(() {
    overrideDeviceKeyStoreForTest(null);
    SoundManager.debugResetForTest();
  });

  testWidgets('stored active run does not block starting a seeded new run', (
    tester,
  ) async {
    final storedSession = RummiPokerGridSession(runSeed: 123);
    final storedProgress = RummiRunProgress();
    await ActiveRunSaveService.saveRuntimeState(
      ActiveRunRuntimeState(
        activeScene: ActiveRunScene.battle,
        difficulty: NewRunDifficulty.standard,
        session: storedSession,
        runProgress: storedProgress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: storedSession.copySnapshot(),
          runProgress: storedProgress.copySnapshot(),
        ),
      ),
    );

    int? openedSeed;
    ActiveRunRuntimeState? openedRuntime;
    final router = GoRouter(
      initialLocation: RoutePaths.newRun,
      routes: [
        GoRoute(
          path: RoutePaths.newRun,
          builder: (context, state) => const NewRunView(),
        ),
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) {
            openedRuntime = state.extra as ActiveRunRuntimeState?;
            final seed = int.tryParse(state.uri.queryParameters['seed'] ?? '');
            openedSeed = seed;
            return BlindSelectView(
              runSeed: seed ?? 77,
              difficulty: NewRunSetup.parseDifficulty(
                state.uri.queryParameters['difficulty'],
              ),
              runModifier: NewRunModifier.parse(
                state.uri.queryParameters['modifier'],
              ),
              restoredRun: openedRuntime,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            return ProviderScope(
              child: MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HomeEntryCard).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '91460');
    await tester.tap(find.text('확인').last);
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('올바른 정수를 입력하세요'), findsNothing);
    expect(openedSeed, 91460);
    expect(openedRuntime, isNotNull);
    expect(openedRuntime!.activeScene, ActiveRunScene.blindSelect);
    expect(openedRuntime!.runProgress.currentStationBlindTierIndex, -1);
    expect(ActiveRunSaveService.hasStoredActiveRun(), isTrue);
    final savedRuntime = await ActiveRunSaveService.loadActiveRun();
    expect(savedRuntime, isNotNull);
    expect(savedRuntime!.session.runSeed, openedRuntime!.session.runSeed);
    expect(savedRuntime.difficulty, openedRuntime!.difficulty);
    expect(savedRuntime.runModifier, openedRuntime!.runModifier);
    expect(
      savedRuntime.runProgress.runClaimId,
      openedRuntime!.runProgress.runClaimId,
    );
    expect(find.text('Station Select'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(HomeEntryCard), findsWidgets);
    final oldRecord = StorageHelper.readString(StorageKeys.activeRunRecordV1);
    final originalStore = SharedPreferencesStorePlatform.instance;
    addTearDown(() {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = originalStore;
      StorageHelper.resetForTest();
    });
    SharedPreferencesStorePlatform.instance =
        _FailingActiveRecordStore.withData(<String, Object>{
          'flutter.${StorageKeys.activeRunRecordV1}': oldRecord,
        });

    await tester.tap(find.byType(HomeEntryCard).first);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.newRun,
    );
    expect(find.text('저장에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);

    SharedPreferences.resetStatic();
    StorageHelper.resetForTest();
    await StorageHelper.init();
    expect(StorageHelper.readString(StorageKeys.activeRunRecordV1), oldRecord);
    await tester.pump(const Duration(seconds: 3));
  });
}
