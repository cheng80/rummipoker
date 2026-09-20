import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';
import 'package:rummipoker/views/game/game_feedback_cues.dart';
import 'package:rummipoker/views/game/widgets/game_market_feedback_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

import 'market_feedback_test_support.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    't3MarketNew': 'NEW',
    't3MarketLockedSlot': '잠긴 슬롯입니다.',
    'tutorialMarketReplayTooltip': '상점 튜토리얼',
  };
}

RummiJesterCard card(String id) => RummiJesterCard(
  id: id,
  displayName: id,
  rarity: RummiJesterRarity.common,
  baseCost: 4,
  effectText: '',
  effectType: 'chips_bonus',
  trigger: 'onScore',
  conditionType: 'none',
  conditionValue: null,
  value: 5,
  xValue: null,
  mappedTileColors: const [],
  mappedTileNumbers: const [],
);

RummiRunProgress run({int count = 2, bool duplicate = false}) =>
    RummiRunProgress()
      ..gold = 40
      ..shopOffers.addAll(
        List.generate(
          count,
          (i) => RummiShopOffer(
            slotIndex: i,
            card: card(duplicate ? 'same' : 'offer_$i'),
            price: 4,
          ),
        ),
      );

Map<String, Object> snapshot(RummiRunProgress progress) => {
  'gold': progress.gold,
  'slots': progress.ownedJesters.map((c) => c.id).toList(),
  'offers': progress.shopOffers
      .map((o) => '${o.slotIndex}:${o.card.id}:${o.price}')
      .toList(),
  'rerollCost': progress.rerollCost,
};

Future<void> mount(
  WidgetTester tester,
  RummiRunProgress progress, {
  VoidCallback? saved,
  ItemCatalog? catalog,
  bool tools = false,
}) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      assetLoader: const _Translations(),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: GameShopScreen(
            runSeed: 77,
            initialItemShopTab: tools,
            autoStartTutorials: false,
            isDebugFixtureRun: false,
            readMarketView: () => RummiMarketRuntimeFacade.fromRunProgress(
              progress,
              itemCatalog:
                  catalog ?? ItemCatalog.fromJson({'items': <dynamic>[]}),
            ),
            onBuyOffer: (offer) =>
                progress.buyOffer(
                  progress.shopOffers.indexWhere(
                    (o) => o.slotIndex == offer.slotIndex,
                  ),
                  price: offer.price,
                )
                ? null
                : '구매 실패',
            isFirstAcquisition: (category, id) =>
                !(category == 'item'
                        ? progress.boughtItemIds
                        : progress.boughtJesterIds)
                    .contains(id),
            onReroll: () =>
                progress.rerollShop(
                  catalog: List.generate(8, (i) => card('reroll_$i')),
                  rng: Random(77),
                )
                ? null
                : '골드 부족',
            onBuyItemOffer: (offer) {
              if (!progress.buyItem(
                offer.item,
                price: offer.price,
                itemCatalog: catalog,
              )) {
                return '구매 실패';
              }
              progress.markItemOfferConsumed(offer.contentId);
              return null;
            },
            onBuyTileOffer: (_) => null,
            onUseMarketItem: (_) => null,
            onSellMarketItem: (_) => false,
            onSellOwnedJester: progress.sellOwnedJester,
            onStateChanged: () async {
              saved?.call();
            },
            onOpenSettings: () async {},
            onExitToTitle: () async {},
            onRestartRun: () async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  if (settle) await tester.pumpAndSettle();
}

void main() {
  setUpMarketFeedback();
  setUp(() {
    MotionPolicy.debugReduceMotionOverride = false;
    GameSettings.fxIntensity = FxIntensity.normal;
  });
  tearDown(() {
    GameSettings.fxIntensity = FxIntensity.normal;
  });

  testWidgets(
    'buy sell reroll have identical gold slots offers across motion settings',
    (tester) async {
      final results = <List<Map<String, Object>>>[];
      for (final mode in ['normal', 'reduced', 'off']) {
        MotionPolicy.debugReduceMotionOverride = mode == 'reduced';
        GameSettings.fxIntensity = mode == 'off'
            ? FxIntensity.off
            : FxIntensity.normal;
        final progress = run();
        await mount(tester, progress);
        await tapKey(tester, 'market-jester-offer-offer_0');
        await tapKey(tester, 'market-detail-action');
        final bought = snapshot(progress);
        expect(progress.ownedJesters.length, 1);
        expect(progress.gold, lessThan(40));
        // Successful purchase selects the acquired slot and exposes its sale action.
        await tapKey(tester, 'market-detail-action');
        final sold = snapshot(progress);
        expect(progress.ownedJesters, isEmpty);
        expect(progress.gold, greaterThan(bought['gold'] as int));
        await tapKey(tester, 'market-reroll');
        await tapKey(tester, 'market-reroll-confirm');
        expect(
          progress.shopOffers.map((o) => o.card.id),
          everyElement(startsWith('reroll_')),
        );
        expect(progress.gold, lessThan(sold['gold'] as int));
        results.add([bought, sold, snapshot(progress)]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      expect(results[1], results[0]);
      expect(results[2], results[0]);
    },
  );

  testWidgets('first purchase reveals NEW and cue; repeat id emits only buy', (
    tester,
  ) async {
    final progress = run(duplicate: true);
    await mount(tester, progress);
    final sounds = <(String, double)>[];
    final haptics = <HapticGrade>[];
    SoundManager.debugSfxSink = (path, volume, rate) =>
        sounds.add((path, rate));
    GameHaptics.debugSink = haptics.add;
    for (var purchase = 0; purchase < 2; purchase++) {
      await tester.tap(
        find.byKey(const ValueKey('market-jester-offer-same')).first,
      );
      await tester.pumpAndSettle();
      sounds.clear();
      haptics.clear();
      await tapKey(tester, 'market-detail-action', settle: false);
      await tester.pump(const Duration(milliseconds: 16));
      final reveal = gameFeedbackCues[GameCue.newReveal]!;
      final revealSounds = sounds.where(
        (s) => s.$1 == reveal.sfx && (s.$2 - reveal.pitch).abs() < .05,
      );
      expect(
        find.byKey(const ValueKey('market-new-acquisition-reveal')),
        purchase == 0 ? findsOneWidget : findsNothing,
      );
      expect(revealSounds.length, purchase == 0 ? 1 : 0);
      expect(
        haptics.where((h) => h != HapticGrade.select).toList(),
        purchase == 0
            ? [gameFeedbackCues[GameCue.buy]!.haptic, reveal.haptic]
            : [gameFeedbackCues[GameCue.buy]!.haptic],
      );
      await tester.pumpAndSettle();
    }
    expect(progress.ownedJesters.map((c) => c.id), ['same', 'same']);
  });

  testWidgets(
    'back tab and previous page enter from left after forward navigation',
    (tester) async {
      await mount(tester, run(count: 5));
      expect(MotionPolicy.reduceMotion, false);
      expect(MotionPolicy.juiceScale, 1);
      Future<void> transition(String input, String childKey, int sign) async {
        await tapKey(tester, input, settle: false);
        await tester.pump();
        final slide = tester.widget<SlideTransition>(
          find.byWidgetPredicate(
            (w) => w is SlideTransition && w.child?.key == ValueKey(childKey),
          ),
        );
        expect(
          tester
              .widget<MarketDirectionalSwitcher>(
                find.byType(MarketDirectionalSwitcher),
              )
              .direction,
          sign,
        );
        expect(slide.position.value.dx.sign, sign.toDouble());
        await tester.pumpAndSettle();
      }

      await transition(
        'market-tab-tools',
        'market-offers-toolsAndGear-tool-0',
        1,
      );
      await transition(
        'market-tab-main',
        'market-offers-cardsAndQuickSlots-jester-0',
        -1,
      );
      await transition(
        'market-page-next',
        'market-offers-cardsAndQuickSlots-jester-1',
        1,
      );
      await transition(
        'market-page-prev',
        'market-offers-cardsAndQuickSlots-jester-0',
        -1,
      );
      expect(
        tester
            .widget<MarketDirectionalSwitcher>(
              find.byType(MarketDirectionalSwitcher),
            )
            .direction,
        -1,
      );
    },
  );

  testWidgets(
    'rapid tab round trip preserves active offers without duplicate keys',
    (tester) async {
      await mount(tester, run(count: 5));
      await tapKey(tester, 'market-tab-tools', settle: false);
      await tester.pump(const Duration(milliseconds: 16));
      await tapKey(tester, 'market-tab-main', settle: false);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('market-jester-offer-offer_0')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'locked slot and insufficient reroll preserve state and emit deny only',
    (tester) async {
      final progress = run()..gold = 0;
      await mount(tester, progress);
      final sounds = <String>[];
      final haptics = <HapticGrade>[];
      SoundManager.debugSfxSink = (path, _, _) {
        if (path != gameFeedbackCues[GameCue.buttonTap]!.sfx) sounds.add(path);
      };
      GameHaptics.debugSink = haptics.add;
      final before = snapshot(progress);
      final locked = find.byKey(const ValueKey('market-item-slot-Q3'));
      expect(locked, findsOneWidget);
      await tester.tap(locked);
      await tester.pumpAndSettle();
      expect(snapshot(progress), before);
      expect(sounds, [gameFeedbackCues[GameCue.deny]!.sfx]);
      expect(haptics.where((h) => h != HapticGrade.select), [
        HapticGrade.error,
      ]);
      await tapKey(tester, 'market-reroll');
      sounds.clear();
      haptics.clear();
      await tapKey(tester, 'market-reroll-confirm');
      expect(snapshot(progress), before);
      expect(sounds, [gameFeedbackCues[GameCue.deny]!.sfx]);
      expect(haptics.where((h) => h != HapticGrade.select), [
        HapticGrade.error,
      ]);
      final empty = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('market-item-slot-Q1')),
      );
      expect(empty.onTap, isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'throwing purchase audio cannot skip flight selection or queued save',
    (tester) async {
      final progress = run(count: 1);
      var saves = 0;
      await mount(tester, progress, saved: () => saves++);
      final beforeSaves = saves;
      await tapKey(tester, 'market-jester-offer-offer_0');
      SoundManager.debugSfxSink = (_, _, _) =>
          throw StateError('audio failure');
      await tapKey(tester, 'market-detail-action', settle: false);
      expect(tester.takeException(), isA<StateError>());
      SoundManager.debugSfxSink = (_, _, _) {};
      await tester.pump();
      expect(
        find.byKey(const ValueKey('market-purchase-flight')),
        findsOneWidget,
      );
      expect(progress.ownedJesters.length, 1);
      expect(progress.shopOffers, isEmpty);
      await tester.pumpAndSettle();
      expect(saves, beforeSaves + 1);
      expect(
        find.byKey(const ValueKey('market-detail-action')),
        findsOneWidget,
      );
      await tapKey(tester, 'market-detail-action');
      expect(progress.ownedJesters, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'item NEW badge and sound haptic occur only on first id acquisition',
    (tester) async {
      final catalog = ItemCatalog.fromJson({
        'items': [
          {
            'id': 'reroll_token',
            'displayName': 'Token',
            'type': 'utility',
            'rarity': 'common',
            'basePrice': 3,
            'sellPrice': 1,
            'stackable': true,
            'maxStack': 3,
            'sellable': true,
            'usableInBattle': false,
            'placement': 'inventory',
            'effectText': '',
            'effect': {
              'timing': 'use_market',
              'op': 'gain_gold',
              'amount': 1,
              'consume': true,
            },
          },
        ],
      });
      final progress = run(count: 0);
      final sounds = <(String, double)>[];
      final haptics = <HapticGrade>[];
      for (var purchase = 0; purchase < 2; purchase++) {
        // A new Market makes the same content available without clearing profile discovery.
        progress.marketModifiers = const RummiMarketModifierState();
        await mount(tester, progress, catalog: catalog, tools: true);
        SoundManager.debugSfxSink = (p, v, r) => sounds.add((p, r));
        GameHaptics.debugSink = haptics.add;
        final offer = RummiMarketRuntimeFacade.fromRunProgress(
          progress,
          itemCatalog: catalog,
        ).itemOffers.single;
        await tapKey(
          tester,
          'market-item-offer-inventory-reroll_token-${offer.price}',
        );
        sounds.clear();
        haptics.clear();
        await tapKey(tester, 'market-detail-action', settle: false);
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.byKey(const ValueKey('market-new-acquisition-reveal')),
          purchase == 0 ? findsOneWidget : findsNothing,
        );
        final cue = gameFeedbackCues[GameCue.newReveal]!;
        expect(
          sounds
              .where((s) => s.$1 == cue.sfx && (s.$2 - cue.pitch).abs() < .05)
              .length,
          purchase == 0 ? 1 : 0,
        );
        expect(
          haptics.where((h) => h == HapticGrade.impact).length,
          purchase == 0 ? 2 : 1,
        );
        expect(progress.boughtItemIds, contains('reroll_token'));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
      }
      expect(progress.itemInventory.ownedItems.single.count, 2);
    },
  );

  for (final mode in ['normal', 'reduced', 'off']) {
    testWidgets('cashout final gold matches receipt in $mode', (tester) async {
      MotionPolicy.debugReduceMotionOverride = mode == 'reduced';
      GameSettings.fxIntensity = mode == 'off'
          ? FxIntensity.off
          : FxIntensity.normal;
      const receipt = RummiSettlementRuntimeFacade(
        stageIndex: 2,
        targetScore: 400,
        currentGold: 23,
        totalGold: 7,
        entries: [
          RummiSettlementEntryView(
            kind: RummiSettlementEntryKind.stationReward,
            leadingLabel: 'Station 2',
            description: 'reward',
            gold: 5,
          ),
          RummiSettlementEntryView(
            kind: RummiSettlementEntryKind.boardDiscardReward,
            leadingLabel: '1',
            description: 'board',
            gold: 1,
          ),
          RummiSettlementEntryView(
            kind: RummiSettlementEntryKind.handDiscardReward,
            leadingLabel: '1',
            description: 'hand',
            gold: 1,
          ),
        ],
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GameCashOutSheet(settlement: receipt)),
        ),
      );
      // Each await starts the next step timer; advance all steps and final count-up.
      for (var step = 0; step < 8; step++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('cashout-total-gold-value')),
            )
            .data,
        '+${receipt.totalGold}G',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('cashout-current-gold-value')),
            )
            .data,
        '${receipt.currentGold}G',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
