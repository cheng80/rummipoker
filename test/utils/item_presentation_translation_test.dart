import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_presentation_event.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/utils/item_presentation_translation.dart';

const locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

class Loader extends AssetLoader {
  const Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}

ItemPresentationEvent event({
  bool? consumed = false,
  String? timing,
  ItemEffectEventKind kind = ItemEffectEventKind.tileDrawn,
  int amount = 1,
  String? detail,
  String? operation,
}) => ItemPresentationEvent(
  itemId: 'emergency_draw',
  sourceKind: ItemPresentationSourceKind.quickSlot,
  sourceLabel: 'Manual name',
  sourceItemIds: consumed == null ? null : const ['emergency_draw'],
  target: const ItemPresentationTarget(
    kind: ItemPresentationTargetKind.hand,
    label: 'Manual target',
    translateKind: true,
  ),
  resultLabel: 'Manual result',
  consumed: consumed,
  activationTiming: timing,
  operation: operation,
  effectEvent: ItemEffectEvent(
    kind: kind,
    itemId: 'emergency_draw',
    amount: amount,
    detail: detail,
  ),
);

void main() {
  testWidgets(
    'typed feedback reacts in five locales and retains explicit/custom fallbacks',
    (tester) async {
      late BuildContext screen;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: locales,
          path: 'assets/translations',
          assetLoader: const Loader(),
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
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final locale in locales) {
        await screen.setLocale(locale);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();
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
        expect(
          localizedItemPresentationSource(screen, event()),
          names['data']['items']['emergency_draw']['displayName'],
        );
        expect(
          localizedItemPresentationTarget(screen, event()),
          strings['coreItemTargetHand'],
        );
        for (final amount in [0, 1, 2]) {
          final count = amount == 0 ? 1 : amount;
          final expected =
              (strings['coreItemDraw${count == 1 ? 'One' : 'Other'}'] as String)
                  .replaceAll('{count}', '$count');
          expect(
            localizedItemPresentationResult(screen, event(amount: amount)),
            expected,
          );
          expect(
            localizedItemPresentationResult(
              screen,
              event(amount: amount, consumed: true),
            ),
            (strings['coreItemResultConsumed'] as String).replaceAll(
              '{effect}',
              expected,
            ),
          );
        }
        expect(
          localizedItemPresentationResult(
            screen,
            event(timing: 'next_confirm', consumed: true),
          ),
          (strings['coreItemPendingConsumed'] as String).replaceAll(
            '{effect}',
            strings['coreItemPendingConfirm'] as String,
          ),
        );
        expect(
          localizedItemPresentationResult(
            screen,
            event(timing: 'station_start'),
          ),
          strings['coreItemPendingBattle'],
        );
        expect(
          localizedItemPresentationResult(screen, event(consumed: null)),
          'Manual result',
        );
        expect(
          localizedItemPresentationSource(screen, event(consumed: null)),
          'Manual name',
        );
        expect(
          localizedItemPresentationResult(
            screen,
            event(
              kind: ItemEffectEventKind.marketModifierQueued,
              detail: 'custom_op',
            ),
          ),
          'Manual result',
        );
        expect(
          localizedItemPresentationResult(
            screen,
            event(timing: 'custom_timing'),
          ),
          'Manual result',
        );
        expect(
          localizedItemPresentationResult(
            screen,
            event(operation: 'custom_op'),
          ),
          'Manual result',
        );
        expect(
          localizedItemPresentationResult(
            screen,
            event(
              kind: ItemEffectEventKind.marketModifierQueued,
              amount: 2,
              detail: 'market_buy:discount_next_purchase',
            ),
          ),
          (strings['coreItemPurchase'] as String).replaceAll('{count}', '2'),
        );
        final jesters =
            jsonDecode(
                  File(
                    'assets/translations/data/$code/jesters.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        for (final isJester in [false, true]) {
          final targeted = ItemPresentationEvent(
            itemId: 'coupon_stamp',
            sourceKind: ItemPresentationSourceKind.tool,
            sourceLabel: 'fallback',
            sourceItemIds: const ['coupon_stamp', 'market_compass'],
            target: ItemPresentationTarget(
              kind: ItemPresentationTargetKind.marketOffer,
              label: 'old target',
              itemId: isJester ? null : 'emergency_draw',
              jesterId: isJester ? 'jester' : null,
            ),
            resultLabel: 'fallback',
            consumed: true,
            operation: 'discount_next_purchase',
            effectEvent: const ItemEffectEvent(
              kind: ItemEffectEventKind.marketModifierQueued,
              itemId: 'coupon_stamp',
              amount: 3,
            ),
          );
          expect(
            localizedItemPresentationTarget(screen, targeted),
            isJester
                ? jesters['data']['jesters']['jester']['displayName']
                : names['data']['items']['emergency_draw']['displayName'],
          );
          expect(
            localizedItemPresentationResult(screen, targeted),
            (strings['marketPurchaseDiscountConsumed'] as String).replaceAll(
              '{amount}',
              '3',
            ),
          );
          expect(
            localizedItemPresentationSource(screen, targeted),
            (strings['coreItemCombinedSources'] as String)
                .replaceAll(
                  '{first}',
                  names['data']['items']['coupon_stamp']['displayName']
                      as String,
                )
                .replaceAll(
                  '{second}',
                  names['data']['items']['market_compass']['displayName']
                      as String,
                ),
          );
        }
        final custom = ItemPresentationEvent(
          itemId: 'custom',
          sourceKind: ItemPresentationSourceKind.tool,
          sourceLabel: '사용자 이름',
          sourceItemIds: const ['custom'],
          target: const ItemPresentationTarget(
            kind: ItemPresentationTargetKind.hand,
            label: '사용자 대상',
          ),
          resultLabel: '사용자 결과',
        );
        expect(localizedItemPresentationSource(screen, custom), '사용자 이름');
        expect(localizedItemPresentationTarget(screen, custom), '사용자 대상');
        expect(localizedItemPresentationResult(screen, custom), '사용자 결과');
      }
    },
  );
}
