import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/archive_view.dart';
import '../support/test_translations.dart';

void main() {
  testWidgets('open memory detail and named counts follow all five locales', (
    tester,
  ) async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
    await RunUnlockStateService.recordRunCollection(
      const RunCollectionUpdate(
        earnedMemoryCardIds: {'memory_card_expired_standard_s2'},
      ),
    );
    await RunUnlockStateService.addInsight(4);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late BuildContext localeContext;
    await tester.pumpWidget(
      EasyLocalization(
        assetLoader: const TestTranslationAssetLoader(),
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
          Locale('ja'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ],
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
              home: const Scaffold(body: ArchiveView()),
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
    expect(find.text('보유 4장 · 수집 1/18'), findsOneWidget);
    final card = find.byKey(
      const ValueKey('archive-memory-memory_card_expired_standard_s2'),
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('획득 · 기억 카드'), findsOneWidget);

    const cases = [
      (
        Locale('en'),
        'Owned 4 · Collected 1/18',
        'Owned · Memory Card',
        'Standard S2',
      ),
      // Japanese writes a number tight against its word; Chinese keeps a
      // half-width space. See docs/tools/I18N_GLOSSARY.md.
      (Locale('ja'), '所持4枚 · 収集1/18', '獲得 · 記憶カード', '標準S2'),
      (Locale('zh', 'CN'), '持有 4张 · 收集 1/18', '已获得 · 记忆卡', '标准 S2'),
      (Locale('zh', 'TW'), '持有 4張 · 收集 1/18', '已獲得 · 記憶卡', '標準 S2'),
    ];
    for (final (locale, summary, status, title) in cases) {
      await localeContext.setLocale(locale);
      await tester.pumpAndSettle();
      expect(find.text(summary), findsOneWidget);
      expect(find.text(status), findsOneWidget);
      expect(find.text(title), findsNWidgets(2));
      expect(find.text('획득 · 기억 카드'), findsNothing);
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }
  });
}
