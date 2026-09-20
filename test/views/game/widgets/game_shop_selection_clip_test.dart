import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/views/game/widgets/game_ui_palette.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

import 'game_shop_feedback_contract_test.dart' as fixture;
import 'market_feedback_test_support.dart';

Finder selectedBorders() => find.byWidgetPredicate((widget) {
  if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
    return false;
  }
  final border = (widget.decoration as BoxDecoration).border;
  return border is Border && border.top.color == GameUiPalette.userSelection;
});

void expectBordersInsideClip(WidgetTester tester, {bool horizontal = true}) {
  var checked = 0;
  expect(selectedBorders(), findsWidgets);
  for (final element in selectedBorders().evaluate()) {
    final border = element.renderObject! as RenderBox;
    RenderBox? clip;
    element.visitAncestorElements((ancestor) {
      if (ancestor.renderObject is RenderClipRect ||
          ancestor.renderObject is RenderClipRRect) {
        clip = ancestor.renderObject! as RenderBox;
        return false;
      }
      return true;
    });
    if (clip == null) continue;
    checked++;
    final bounds = MatrixUtils.transformRect(
      border.getTransformTo(clip),
      Offset.zero & border.size,
    );
    final area = Offset.zero & clip!.size;
    expect(
      bounds.top,
      greaterThanOrEqualTo(area.top - .01),
      reason:
          'selected border=$bounds, clip=$area; top overflow=${area.top - bounds.top}',
    );
    expect(bounds.bottom, lessThanOrEqualTo(area.bottom + .01));
    if (horizontal) {
      expect(bounds.left, greaterThanOrEqualTo(area.left - .01));
      expect(bounds.right, lessThanOrEqualTo(area.right + .01));
    }
  }
  expect(checked, greaterThan(0));
}

void main() {
  setUpMarketFeedback();
  setUp(() {
    MotionPolicy.debugReduceMotionOverride = false;
    GameSettings.fxIntensity = FxIntensity.normal;
  });
  tearDown(() => GameSettings.fxIntensity = FxIntensity.normal);
  testWidgets('selected offer border stays inside directional clip', (
    tester,
  ) async {
    await fixture.mount(tester, fixture.run(count: 3));
    await fixture.tapKey(tester, 'market-jester-offer-offer_0');
    expectBordersInsideClip(tester);
  });

  testWidgets(
    'discount fixture selection preserves border and badge clearance',
    (tester) async {
      final progress = DebugRunFixtureService.build(
        'market_modifier_shop',
      )!.runProgress;
      await fixture.mount(tester, progress);
      final offer = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
      ).offers.first;
      expect(offer.discountSourceLabel, isNotNull);
      await fixture.tapKey(
        tester,
        'market-jester-offer-${offer.contentId}',
        settle: false,
      );
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expectBordersInsideClip(tester);
      }
      await tester.pumpAndSettle();
      final price = find.descendant(
        of: find.byKey(ValueKey('market-jester-offer-${offer.contentId}')),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_MarketOfferPriceLabel',
        ),
      );
      expect(
        tester.getTopLeft(price).dy,
        greaterThan(tester.getBottomLeft(selectedBorders().last).dy),
      );
    },
  );

  for (final count in [1, 3, 4]) {
    for (final mode in ['normal', 'strong', 'reduced', 'off']) {
      testWidgets('$count offers fit at compact size with $mode motion', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        MotionPolicy.debugReduceMotionOverride = mode == 'reduced';
        GameSettings.fxIntensity = mode == 'strong'
            ? FxIntensity.strong
            : mode == 'off'
            ? FxIntensity.off
            : FxIntensity.normal;
        await fixture.mount(tester, fixture.run(count: count));
        await fixture.tapKey(
          tester,
          'market-jester-offer-offer_0',
          settle: false,
        );
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expectBordersInsideClip(tester);
        }
        await tester.pumpAndSettle();
        expectBordersInsideClip(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('all six lanes keep selection and prices within the offer area', (
    tester,
  ) async {
    final progress = fixture.run(count: 3)..gold = 999;
    progress.tileOffers.add(const Tile(color: TileColor.red, number: 7));
    final catalog = ItemCatalog.fromJson({
      'items': [
        for (final placement in [
          'quickSlot',
          'passiveRack',
          'inventory',
          'equipped',
        ])
          {
            'id': 'clip_$placement',
            'displayName': placement,
            'type': 'utility',
            'rarity': 'common',
            'basePrice': 3,
            'sellPrice': 1,
            'placement': placement,
            'effectText': '',
            'effect': {'timing': 'use_market', 'op': 'gain_gold', 'amount': 1},
            'stackable': true,
            'maxStack': 3,
          },
      ],
    });
    await fixture.mount(tester, progress, catalog: catalog);
    final market = RummiMarketRuntimeFacade.fromRunProgress(
      progress,
      itemCatalog: catalog,
    );
    final tile = market.tileOffers.single;
    final targets = <String, String>{
      'jester': 'market-jester-offer-offer_0',
      'tile':
          'market-tile-offer-${tile.slotIndex}-${tile.tile.code}-${tile.price}',
      for (final offer in market.itemOffers)
        switch (offer.item.placement) {
          ItemPlacement.quickSlot => 'quickSlot',
          ItemPlacement.passiveRack => 'passive',
          ItemPlacement.inventory => 'tool',
          ItemPlacement.equipped => 'gear',
        }: 'market-item-offer-${offer.item.placement.name}-${offer.contentId}-${offer.price}',
    };
    expect(targets.length, 6);
    for (final lane in [
      'jester',
      'tile',
      'quickSlot',
      'passive',
      'tool',
      'gear',
    ]) {
      final target = MapEntry(lane, targets[lane]!);
      if (target.key == 'tool') {
        await fixture.tapKey(tester, 'market-tab-tools');
      }
      await fixture.tapKey(tester, 'market-lane-${target.key}');
      await fixture.tapKey(tester, target.value);
      expectBordersInsideClip(tester);
      final offerBox = tester.getRect(find.byKey(ValueKey(target.value)));
      final borderBox = tester.getRect(selectedBorders().last);
      final prices = find.descendant(
        of: find.byKey(ValueKey(target.value)),
        matching: find.byWidgetPredicate(
          (w) =>
              w.runtimeType.toString() == '_MarketOfferPriceLabel' ||
              (w is Text && w.style?.fontSize == 10),
        ),
      );
      expect(prices, findsWidgets);
      for (final price in prices.evaluate()) {
        final priceBox = price.renderObject! as RenderBox;
        final bounds = MatrixUtils.transformRect(
          priceBox.getTransformTo(null),
          Offset.zero & priceBox.size,
        );
        expect(bounds.top, greaterThan(borderBox.bottom));
        expect(bounds.bottom, lessThanOrEqualTo(offerBox.bottom + .01));
        expect(
          bounds.bottom,
          lessThan(tester.getTopLeft(find.text('메인 메뉴')).dy),
        );
      }
      if (lane == 'quickSlot' || lane == 'passive') {
        await fixture.tapKey(tester, 'market-detail-action');
        expectBordersInsideClip(tester);
      }
    }
  });

  testWidgets(
    'selected offer keeps vertical clearance during page and tab transitions',
    (tester) async {
      await fixture.mount(tester, fixture.run(count: 4));
      await fixture.tapKey(tester, 'market-jester-offer-offer_0');
      await fixture.tapKey(tester, 'market-page-next', settle: false);
      await tester.pump(const Duration(milliseconds: 32));
      expectBordersInsideClip(tester, horizontal: false);
      await tester.pumpAndSettle();
      await fixture.tapKey(tester, 'market-jester-offer-offer_3');
      await fixture.tapKey(tester, 'market-page-prev', settle: false);
      await tester.pump(const Duration(milliseconds: 32));
      expectBordersInsideClip(tester, horizontal: false);
      await tester.pumpAndSettle();
      await fixture.tapKey(tester, 'market-jester-offer-offer_0');
      await fixture.tapKey(tester, 'market-tab-tools', settle: false);
      await tester.pump(const Duration(milliseconds: 32));
      expectBordersInsideClip(tester, horizontal: false);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'purchase flight starts at the relocated offer and owned selection fits',
    (tester) async {
      await fixture.mount(tester, fixture.run(count: 1));
      await fixture.tapKey(tester, 'market-jester-offer-offer_0');
      final source = tester.getCenter(
        find.byKey(const ValueKey('market-jester-offer-offer_0')),
      );
      await fixture.tapKey(tester, 'market-detail-action', settle: false);
      await tester.pump();
      final start = tester.getCenter(
        find.byKey(const ValueKey('market-purchase-flight')),
      );
      expect((start - source).distance, lessThan(.01));
      await tester.pumpAndSettle();
      expectBordersInsideClip(tester);
    },
  );
}
