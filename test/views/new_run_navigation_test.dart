import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/blind_select_view.dart';
import 'package:rummipoker/views/new_run_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
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
    GameAnalyticsService.debugResetForTest();
  });

  tearDown(() {
    SoundManager.debugResetForTest();
    GameAnalyticsService.debugResetForTest();
  });

  testWidgets('new run to blind select keeps back navigation to title', (
    tester,
  ) async {
    final analyticsEvents = <_CapturedEvent>[];
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          analyticsEvents.add(_CapturedEvent(name, parameters));
        },
      ),
    );
    final router = GoRouter(
      initialLocation: RoutePaths.title,
      routes: [
        GoRoute(
          path: RoutePaths.title,
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(RoutePaths.newRun),
              child: const Text('title-new-run'),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.newRun,
          builder: (context, state) => const NewRunView(),
        ),
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) {
            final seed = int.tryParse(state.uri.queryParameters['seed'] ?? '');
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    router.push(RoutePaths.newRun);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('랜덤 시작'), findsOneWidget);

    await tester.tap(find.text('랜덤 시작'));
    await tester.pumpAndSettle();

    final runStartEvents = analyticsEvents
        .where((event) => event.name == 'run_start')
        .toList();
    expect(runStartEvents, hasLength(1));
    expect(runStartEvents.single.parameters['seed_mode'], 'random');
    expect(runStartEvents.single.parameters['difficulty'], 'standard');
    expect(runStartEvents.single.parameters['modifier'], 'basic');
    expect(find.text('Station Select'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('랜덤 시작'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('시드 시작'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final manualRunStartEvents = analyticsEvents
        .where((event) => event.name == 'run_start')
        .toList();
    expect(manualRunStartEvents, hasLength(2));
    expect(manualRunStartEvents.last.parameters['seed_mode'], 'manual');
    expect(manualRunStartEvents.last.parameters['seed_bucket'], 45);
    expect(manualRunStartEvents.last.parameters['difficulty'], 'standard');
    expect(manualRunStartEvents.last.parameters['modifier'], 'basic');
    expect(find.text('Station Select'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('랜덤 시작'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.title,
    );
    expect(find.text('랜덤 시작'), findsNothing);
  });
}

class _CapturedEvent {
  const _CapturedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}
