import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_presentation_event.dart';
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

const _events = [
  ItemPresentationEvent(
    itemId: 'emergency_draw',
    sourceKind: ItemPresentationSourceKind.quickSlot,
    sourceLabel: 'old name',
    sourceItemIds: ['emergency_draw'],
    consumed: true,
    activated: true,
    target: ItemPresentationTarget(
      kind: ItemPresentationTargetKind.boardResource,
      label: 'old target',
      translateKind: true,
    ),
    resultLabel: 'old result',
    effectEvent: ItemEffectEvent(
      kind: ItemEffectEventKind.boardMoveAdded,
      itemId: 'emergency_draw',
      amount: 2,
    ),
  ),
  ItemPresentationEvent(
    itemId: 'custom',
    sourceKind: ItemPresentationSourceKind.tool,
    sourceLabel: 'My tool',
    target: ItemPresentationTarget(
      kind: ItemPresentationTargetKind.hand,
      label: 'My target',
    ),
    resultLabel: 'My result',
  ),
];

void main() {
  setUpMarketFeedback();
  testWidgets(
    'open Market event summary rebuilds in five locales without draining twice',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var drains = 0;
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
        initialItemPresentationEvents: _events,
        onItemPresentationEventsShown: () => drains++,
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
        onReroll: () => null,
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
      for (final locale in locales) {
        await screen.setLocale(locale);
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        });
        await tester.pump(const Duration(milliseconds: 40));
        final code = locale.toLanguageTag();
        final strings =
            jsonDecode(
                  File('assets/translations/$code.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final names =
            jsonDecode(
                  File(
                    'assets/translations/data/$code/items.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final name =
            names['data']['items']['emergency_draw']['displayName'] as String;
        final effect = (strings['coreItemMove'] as String).replaceAll(
          '{count}',
          '2',
        );
        final result = (strings['coreItemActivatedConsumed'] as String)
            .replaceAll('{effect}', effect);
        final summary = (strings['coreItemSummary'] as String)
            .replaceAll('{item}', name)
            .replaceAll('{result}', result);
        expect(find.text(summary), findsOneWidget);
        expect(
          find.text('My tool: My result'),
          locale.languageCode == 'zh' ? findsNothing : findsOneWidget,
        );
        expect(
          find.text(strings['marketEntryItemsTriggered'] as String),
          findsOneWidget,
        );
        expect(drains, 1);
        expect(tester.takeException(), isNull);
        final summaryFinder = find.byKey(
          const ValueKey('market-effect-summary-emergency_draw'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(summaryFinder);
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );
}
