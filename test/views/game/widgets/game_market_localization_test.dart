import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rummipoker/app.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';

import 'market_feedback_test_support.dart';
import '../../../support/test_translations.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';

const _locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

String _translated(Locale locale, String key) {
  final code = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
  return (jsonDecode(File('assets/translations/$code.json').readAsStringSync())
          as Map<String, dynamic>)[key]
      as String;
}

const _settlement = RummiSettlementRuntimeFacade(
  stageIndex: 8,
  targetScore: 400,
  currentGold: 17,
  totalGold: 9,
  entries: [
    RummiSettlementEntryView(
      kind: RummiSettlementEntryKind.stationReward,
      leadingLabel: 'S8',
      description: 'Station 8',
      gold: 5,
    ),
    RummiSettlementEntryView(
      kind: RummiSettlementEntryKind.boardDiscardReward,
      leadingLabel: '2',
      description: '2 × 1',
      gold: 2,
    ),
    RummiSettlementEntryView(
      kind: RummiSettlementEntryKind.handDiscardReward,
      leadingLabel: '2',
      description: '2 × 1',
      gold: 2,
    ),
  ],
);

final _card = RummiJesterCard(
  id: 'jester',
  displayName: 'Fallback Jester',
  rarity: RummiJesterRarity.common,
  baseCost: 4,
  effectText: 'Fallback effect',
  effectType: 'mult_bonus',
  trigger: 'onScore',
  conditionType: 'none',
  conditionValue: null,
  value: 20,
  xValue: null,
  mappedTileColors: const [],
  mappedTileNumbers: const [],
);

final _runtimeCard = RummiJesterCard(
  id: 'green_jester',
  displayName: 'Fallback Jester',
  rarity: RummiJesterRarity.common,
  baseCost: 4,
  effectText: 'Fallback effect',
  effectType: 'mult_bonus',
  trigger: 'onScore',
  conditionType: 'none',
  conditionValue: null,
  value: 20,
  xValue: null,
  mappedTileColors: const [],
  mappedTileNumbers: const [],
);

final _item = ItemDefinition.fromJson(<String, dynamic>{
  'id': 'trade_ticket',
  'displayName': 'Fallback Item',
  'displayNameKey': 'data.items.trade_ticket.displayName',
  'type': 'utility',
  'rarity': 'common',
  'basePrice': 3,
  'sellPrice': 1,
  'stackable': true,
  'maxStack': 3,
  'sellable': true,
  'usableInBattle': false,
  'placement': 'inventory',
  'slotHint': 'utility',
  'effectText': 'Fallback Item effect',
  'effectTextKey': 'data.items.trade_ticket.effectText',
  'effect': {
    'timing': 'use_market',
    'op': 'reroll_item_offers_only',
    'consume': true,
  },
  'tags': ['market', 'economy', 'discount'],
  'sourceNotes': 'Localization fixture.',
});

String _itemEffect(Locale locale) {
  final code = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
  return ((jsonDecode(
            File(
              'assets/translations/data/$code/items.json',
            ).readAsStringSync(),
          )
          as Map<
            String,
            dynamic
          >)['data']['items']['trade_ticket']['effectText'])
      as String;
}

Widget _market({
  bool withOffer = false,
  bool withItem = false,
  bool withOwned = false,
}) => GameShopScreen(
  key: ValueKey(withItem),
  initialItemShopTab: withItem,
  runSeed: 77,
  readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
    schemaVersion: 2,
    activeScene: 'shop',
    sceneAlias: RummiSaveSceneAlias.market,
    currentStageIndex: 8,
    currentStationIndex: 8,
    currentRunSeed: 77,
    currentGold: 12,
    checkpoint: RummiStationCheckpointSaveView(
      stageIndex: 8,
      stationIndex: 8,
      runSeed: 77,
      gold: 10,
    ),
  ),
  readMarketView: () => RummiMarketRuntimeFacade(
    gold: 12,
    rerollCost: 4,
    originalRerollCost: 5,
    maxOwnedSlots: RummiRunProgress.maxJesterSlots,
    runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    ownedEntries: withOwned
        ? [
            RummiMarketOwnedEntryView(
              slotIndex: 0,
              category: RummiMarketCategory.jester,
              contentId: _runtimeCard.id,
              displayName: _runtimeCard.displayName,
              sellPrice: 2,
              card: _runtimeCard,
            ),
          ]
        : [],
    offers: withOffer
        ? [
            RummiMarketOfferView.fromShopOffer(
              RummiShopOffer(slotIndex: 0, card: _card, price: 4),
              currentGold: 12,
            ),
          ]
        : [],
    itemOfferSlotCount: 3,
    quickSlotCapacity: 3,
    itemOffers: withItem
        ? [
            RummiMarketItemOfferView.fromItemDefinition(
              _item,
              slotIndex: 0,
              currentGold: 12,
            ),
          ]
        : [],
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

void _expectNoClippedParagraphs(WidgetTester tester) {
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Clipped text: ${paragraph.text.toPlainText()}',
    );
  }
}

Widget _settlementBurst({RummiConstraintPenaltyBreakdown? penalty}) => Scaffold(
  body: GameFloatingSettlementBurst(
    line: ConfirmedLineBreakdown(
      ref: LineRef.row(0),
      rank: RummiHandRank.flush,
      baseScore: 50,
      finalScore: 40,
      jesterBonus: 0,
      hasScoringFaceCard: false,
      effects: const [],
      constraintPenalties: penalty == null ? const [] : [penalty],
    ),
    step: penalty == null
        ? ScoringPresentationStep.handRank
        : ScoringPresentationStep.constraint,
    effectIndex: null,
  ),
);

void main() {
  setUpMarketFeedback();
  test('Market fragments preserve named argument sets in every locale', () {
    Set<String> placeholders(String value) => RegExp(
      r'\{([a-zA-Z]+)\}',
    ).allMatches(value).map((match) => match[1]!).toSet();
    final reference =
        jsonDecode(
              File('assets/translations/src/market/ko.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final locale in ['en', 'ja', 'zh-CN', 'zh-TW']) {
      final translated =
          jsonDecode(
                File(
                  'assets/translations/src/market/$locale.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(translated.keys.toSet(), reference.keys.toSet());
      for (final key in reference.keys) {
        expect(
          placeholders(translated[key] as String),
          placeholders(reference[key] as String),
          reason: '$locale $key',
        );
      }
    }
  });

  testWidgets(
    'open cashout, Market and reroll dialog follow all five locales',
    (tester) async {
      await (FontLoader(
        AssetPaths.fontNexonLv2Gothic,
      )..addFont(rootBundle.load('assets/fonts/NEXON Lv2 Gothic.ttf'))).load();
      await (FontLoader(AssetPaths.fontNotoSansCjkUiSubset)..addFont(
            rootBundle.load('assets/fonts/NotoSansCjkUiSubset-Regular.otf'),
          ))
          .load();
      tester.view.physicalSize = const Size(390, 750);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final content = ValueNotifier<Widget>(
        const Scaffold(
          body: GameCashOutSheet(
            settlement: _settlement,
            completesRun: true,
            showsChallengeCarryoverNotice: true,
          ),
        ),
      );
      addTearDown(content.dispose);
      late BuildContext localeContext;
      await tester.pumpWidget(
        EasyLocalization(
          assetLoader: const TestTranslationAssetLoader(),
          supportedLocales: _locales,
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          startLocale: const Locale('ko'),
          saveLocale: false,
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp(
                theme: buildAppTheme(),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                builder: (context, child) => JesterTranslationScope(
                  child: ItemTranslationScope(child: child!),
                ),
                home: ValueListenableBuilder<Widget>(
                  valueListenable: content,
                  builder: (context, child, _) => child,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final cashoutState = tester.state(find.byType(GameCashOutSheet));
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(GameCashOutSheet)), same(cashoutState));
        expect(
          find.text(_translated(locale, 'marketCashoutComplete')),
          findsOneWidget,
        );
        expect(
          find.text(_translated(locale, 'marketEndlessNotice')),
          findsOneWidget,
        );
        expect(
          find.text(_translated(locale, 'marketCarryoverNotice')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'cashout $locale');
        _expectNoClippedParagraphs(tester);
      }

      content.value = _market();
      await tester.pumpAndSettle();
      final marketState = tester.state(find.byType(GameShopScreen));
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(GameShopScreen)), same(marketState));
        expect(
          find.text(_translated(locale, 'marketNoSelection')),
          findsOneWidget,
        );
        final price = _translated(
          locale,
          'marketRerollDiscountPrice',
        ).replaceAll('{original}', '5').replaceAll('{cost}', '4');
        expect(find.text(price), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Market $locale');
        _expectNoClippedParagraphs(tester);
      }

      await tester.tap(find.byKey(const ValueKey('market-reroll')));
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(_translated(locale, 'marketRerollConfirm')),
          findsOneWidget,
        );
        final message = _translated(locale, 'marketRerollDiscountMessage')
            .replaceAll('{lane}', 'Jester')
            .replaceAll('{original}', '5')
            .replaceAll('{cost}', '4');
        expect(find.text(message), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'reroll dialog $locale');
        _expectNoClippedParagraphs(tester);
      }
      await tester.tap(find.byKey(const ValueKey('market-reroll-confirm')));
      await tester.pumpAndSettle();
      // Replace the Market fixture, keeping the localization host mounted.
      content.value = _market(withOffer: true);
      await localeContext.setLocale(const Locale('ko'));
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('market-jester-offer-jester')),
      );
      await tester.pumpAndSettle();
      expect(find.text('점수 +20%.'), findsWidgets);
      await localeContext.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Score +20%.'), findsWidgets);
      expect(find.text('점수 +20%.'), findsNothing);
      expect(find.text('Base Relay'), findsWidgets);
      expect(find.text('기본패'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'open card preview en');
      await tester.tap(find.byKey(const ValueKey('market-card-preview-close')));
      await tester.pumpAndSettle();
      content.value = _market(withItem: true);
      await tester.pumpAndSettle();
      final itemOffer = find.byKey(
        const ValueKey('market-item-offer-inventory-trade_ticket-3'),
      );
      await tester.tap(itemOffer);
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(find.text(_itemEffect(locale)), findsWidgets);
        _expectNoClippedParagraphs(tester);
        expect(tester.takeException(), isNull, reason: 'selected Item $locale');
      }
      await tester.longPress(itemOffer);
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(find.text(_itemEffect(locale)), findsWidgets);
        _expectNoClippedParagraphs(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'open Item preview $locale',
        );
      }
      await tester.tap(find.byKey(const ValueKey('market-card-preview-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('market-options-open')));
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(find.text(_translated(locale, 'marketOptions')), findsOneWidget);
        final location = _translated(locale, 'coreSaveLocation')
            .replaceAll('{station}', '8')
            .replaceAll('{scene}', _translated(locale, 'coreSaveSceneMarket'))
            .replaceAll('{gold}', '12');
        final checkpoint = _translated(
          locale,
          'coreSaveCheckpoint',
        ).replaceAll('{station}', '8');
        expect(
          find.text(
            _translated(locale, 'coreSaveSnapshot')
                .replaceAll('{location}', location)
                .replaceAll('{checkpoint}', checkpoint),
          ),
          findsOneWidget,
        );
        expect(
          find.text(_translated(locale, 'marketBookmarkHelp')),
          findsOneWidget,
        );
        _expectNoClippedParagraphs(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Market options $locale',
        );
      }
      for (final action in ['restart', 'exit']) {
        await localeContext.setLocale(const Locale('ko'));
        await tester.pumpAndSettle();
        final button = find.byKey(ValueKey('market-options-$action'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        for (final locale in _locales) {
          await localeContext.setLocale(locale);
          await tester.pumpAndSettle();
          expect(
            find.text(
              _translated(
                locale,
                action == 'restart'
                    ? 'marketRestartStationConfirm'
                    : 'marketExitConfirm',
              ),
            ),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'open $action $locale',
          );
          _expectNoClippedParagraphs(tester);
        }
        await tester.tap(
          find.widgetWithText(
            GameChromeButton,
            _translated(_locales.last, 'cancel'),
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('market-options-close')),
      );
      await tester.tap(find.byKey(const ValueKey('market-options-close')));
      await tester.pumpAndSettle();
      content.value = _market(withOwned: true);
      await localeContext.setLocale(const Locale('ko'));
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byWidgetPredicate(
          (w) => w is GameJesterSlot && w.card?.id == 'green_jester',
        ),
      );
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        final expected = _translated(
          locale,
          'battleWidgetsCurrentScore',
        ).replaceAll('{value}', '+0%');
        final slots = tester
            .widgetList<GameJesterSlot>(find.byType(GameJesterSlot))
            .where((w) => w.card?.id == 'green_jester');
        expect(slots, isNotEmpty);
        for (final slot in slots) {
          expect(
            slot.runtimeValueText,
            expected,
            reason: 'owned preview $locale',
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('market-card-preview-close')));
      await tester.pumpAndSettle();
      content.value = _settlementBurst();
      await tester.pumpAndSettle();
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(_translated(locale, 'coreHandRankFlush')),
          findsWidgets,
        );
        expect(
          find.text(
            _translated(locale, 'marketBaseChips').replaceAll('{count}', '50'),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      }
      const boss = RummiBossModifier.redDampener;
      content.value = _settlementBurst(
        penalty: RummiConstraintPenaltyBreakdown(
          modifierId: boss.id,
          title: boss.title,
          ruleText: boss.ruleText,
          markerText: boss.markerText,
          scoreDelta: -10,
          scoreMultiplier: 0.8,
        ),
      );
      for (final locale in _locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(_translated(locale, boss.displayKeys!.titleKey)),
          findsWidgets,
        );
        expect(
          find.text(_translated(locale, boss.displayKeys!.ruleTextKey)),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      }
      content.value = _settlementBurst(
        penalty: const RummiConstraintPenaltyBreakdown(
          modifierId: 'custom_test',
          title: 'Custom title',
          ruleText: 'Custom rule 17%',
          markerText: '',
          scoreDelta: -17,
          scoreMultiplier: 0.83,
        ),
      );
      await localeContext.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Custom title'), findsWidgets);
      expect(find.text('Custom rule 17%'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
