import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/device_key_store.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/home_entry_widgets.dart';
import 'package:rummipoker/views/new_run_view.dart';
import 'package:rummipoker/views/title_view.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../support/test_translations.dart';

const _locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

class _MemoryKeyStore implements DeviceKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _DialogHarness {
  late BuildContext localeContext;
  late BuildContext hostContext;
  ActiveRunRuntimeState? startedRun;
  final sounds = <(String, double)>[];
  final haptics = <HapticGrade>[];

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            hostContext = context;
            return page;
          },
        ),
        GoRoute(
          path: RoutePaths.blindSelect,
          builder: (context, state) {
            startedRun = state.extra! as ActiveRunRuntimeState;
            return const Scaffold(body: Text('started run'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    SoundManager.debugSfxSink = (path, _, rate) => sounds.add((path, rate));
    GameHaptics.debugSink = haptics.add;
    SoundManager.rampGlobalPitch(0.5, Duration.zero);
    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: _locales,
          path: 'assets/translations',
          assetLoader: const TestTranslationAssetLoader(),
          startLocale: _locales.first,
          fallbackLocale: _locales.first,
          saveLocale: false,
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> switchLocale(WidgetTester tester, Locale locale) async {
    await tester.runAsync(() => localeContext.setLocale(locale));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$locale');
  }

  Future<void> open(WidgetTester tester, Finder entry) async {
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    sounds.clear();
    haptics.clear();
  }

  Finder dialogText(String key) => find.descendant(
    of: find.byType(Dialog),
    matching: find.text(hostContext.translate(key)),
  );

  Finder action(String key) => find.ancestor(
    of: dialogText(key),
    matching: find.byType(GameChromeButton),
  );
}

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Rummi Poker',
      packageName: 'rummipoker',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
    await StorageHelper.init();
    overrideDeviceKeyStoreForTest(_MemoryKeyStore());
    SoundManager.debugResetForTest();
    FxAmbient.debugReset();
    debugResetTitleEntrance();
    MotionPolicy.debugReduceMotionOverride = true;
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = false;
    GameSettings.hapticsEnabled = true;
  });

  tearDown(() {
    overrideDeviceKeyStoreForTest(null);
    MotionPolicy.debugReduceMotionOverride = null;
    SoundManager.debugResetForTest();
    GameHaptics.debugSink = null;
  });

  for (final exit in ['cancel', 'submit', 'keyboard']) {
    testWidgets('open seed dialog follows five locales and exits once: $exit', (
      tester,
    ) async {
      final harness = _DialogHarness();
      await harness.pump(tester, const NewRunView());
      await harness.open(tester, find.byType(HomeEntryCard).last);
      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, '424242');
      final controller = tester.widget<TextField>(fieldFinder).controller!;
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      final fieldState = tester.state(find.byType(EditableText));
      final dialogElement = tester.element(find.byType(Dialog));

      for (final locale in _locales) {
        await harness.switchLocale(tester, locale);
        expect(tester.element(find.byType(Dialog)), same(dialogElement));
        final field = tester.widget<TextField>(fieldFinder);
        expect(field.controller, same(controller));
        expect(controller.text, '424242');
        expect(
          controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 4),
        );
        expect(tester.state(find.byType(EditableText)), same(fieldState));
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(
          field.decoration!.hintText,
          harness.hostContext.translate('seedHint'),
        );
        for (final key in ['seedDialogTitle', 'cancel', 'ok']) {
          expect(
            harness.dialogText(key),
            findsOneWidget,
            reason: '$key / $locale',
          );
        }
      }
      expect(harness.sounds, isEmpty);
      if (exit == 'keyboard') {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      } else {
        await tester.tap(harness.action(exit == 'cancel' ? 'cancel' : 'ok'));
      }
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(harness.sounds, [(AssetPaths.sfxBtnSnd, 1.0)]);
      if (exit == 'cancel') {
        expect(harness.startedRun, isNull);
        expect(ActiveRunSaveService.hasStoredActiveRun(), isFalse);
      } else {
        expect(harness.haptics, contains(HapticGrade.impact));
        expect(harness.startedRun?.session.runSeed, 424242);
        expect(ActiveRunSaveService.hasStoredActiveRun(), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final (entry, title, message, actions) in const [
    ('home-entry-run-info', 'runInfoTitle', 'menuNoActiveRun', ['ok']),
    (
      'home-entry-continue',
      'menuCheckSave',
      'menuInvalidSave',
      ['cancel', 'menuDelete'],
    ),
    ('home-entry-debug-fixture', 'menuDebugFixture', null, ['cancel']),
  ]) {
    testWidgets('open Title dialog follows five locales: $title', (
      tester,
    ) async {
      if (message == 'menuInvalidSave') {
        await StorageHelper.write(
          StorageKeys.activeRunRecordV1,
          'invalid record',
        );
      }
      final harness = _DialogHarness();
      await harness.pump(
        tester,
        const TitleView(showDebugEntriesOverride: true),
      );
      await harness.open(tester, find.byKey(ValueKey(entry)));
      final dialogElement = tester.element(find.byType(Dialog));
      for (final locale in _locales) {
        await harness.switchLocale(tester, locale);
        expect(tester.element(find.byType(Dialog)), same(dialogElement));
        for (final key in [title, if (message != null) message, ...actions]) {
          expect(
            harness.dialogText(key),
            findsOneWidget,
            reason: '$key / $locale',
          );
        }
      }
      expect(harness.sounds, isEmpty);
      await tester.tap(harness.action(actions.first));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(harness.sounds, [(AssetPaths.sfxBtnSnd, 1.0)]);
      if (message == 'menuInvalidSave') {
        expect(
          StorageHelper.readString(StorageKeys.activeRunRecordV1),
          'invalid record',
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
