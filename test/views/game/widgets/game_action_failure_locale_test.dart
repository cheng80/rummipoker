import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

import 'market_feedback_test_support.dart';

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  setUpMarketFeedback();
  for (final rejected in [true, false]) {
    testWidgets(
      'Market typed result rejected=$rejected runs once and notice follows locale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        var typedCalls = 0;
        var legacyCalls = 0;
        late BuildContext screen;
        const locales = [
          Locale('ko'),
          Locale('en'),
          Locale('ja'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ];
        final shop = GameShopScreen(
          runSeed: 1,
          readMarketView: () => const RummiMarketRuntimeFacade(
            gold: 10,
            rerollCost: 5,
            maxOwnedSlots: 5,
            runtimeSnapshot: RummiJesterRuntimeSnapshot(),
            ownedEntries: [],
            offers: [],
            itemOffers: [],
            itemOfferSlotCount: 3,
            quickSlotCapacity: 3,
          ),
          onReroll: () {
            legacyCalls++;
            return 'legacy';
          },
          onRerollFailure: () {
            typedCalls++;
            if (!rejected) return null;
            return const ActionFailure(
              ActionFailureReason.rerollGold,
              '리롤 골드가 부족합니다.',
            );
          },
          onBuyOffer: (_) => null,
          onBuyItemOffer: (_) => null,
          onBuyTileOffer: (_) => null,
          onUseMarketItem: (_) => null,
          onSellOwnedJester: (_) => false,
          onSellMarketItem: (_) => false,
          onStateChanged: () async {},
          onOpenSettings: () async {},
          onExitToTitle: () async {},
          onRestartRun: () async {},
          isDebugFixtureRun: false,
          autoStartTutorials: false,
        );
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: locales,
            path: 'assets/translations',
            assetLoader: const _Loader(),
            startLocale: locales.first,
            fallbackLocale: locales.first,
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: JesterTranslationScope(
                  child: ItemTranslationScope(
                    child: Builder(
                      builder: (context) {
                        screen = context;
                        return shop;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('market-reroll')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('market-reroll-confirm')));
        await tester.pumpAndSettle();
        expect(typedCalls, 1);
        expect(legacyCalls, 0);
        if (!rejected) {
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          return;
        }
        for (final locale in locales) {
          await screen.setLocale(locale);
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          });
          await tester.pump(const Duration(milliseconds: 40));
          final strings =
              jsonDecode(
                    File(
                      'assets/translations/${locale.toLanguageTag()}.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          expect(
            find.text(strings['coreActionRerollGold'] as String),
            findsWidgets,
          );
          expect(find.text('legacy'), findsNothing);
          expect(typedCalls, 1);
          expect(legacyCalls, 0);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );
  }
}
