import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(ActiveRunSaveService.hasStoredActiveRun(), isTrue);
    final activeRun = await ActiveRunSaveService.loadActiveRun();
    expect(activeRun?.session.runSeed, 91460);
    expect(activeRun?.activeScene, ActiveRunScene.blindSelect);
    expect(find.text('Station Select'), findsOneWidget);
  });
}
