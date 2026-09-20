import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/app.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';

import '../../../logic/rummi_settlement_display_test.dart'
    show settlementReceipt;
import '../../../support/test_translations.dart';

const locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];
String code(Locale locale) => locale.toString().replaceAll('_', '-');
Map<String, dynamic> translations(Locale locale) =>
    jsonDecode(
          File('assets/translations/${code(locale)}.json').readAsStringSync(),
        )
        as Map<String, dynamic>;
String expected(
  Locale locale,
  String key, [
  Map<String, String> args = const {},
]) {
  var text = translations(locale)[key] as String;
  args.forEach((key, value) => text = text.replaceAll('{$key}', value));
  return text;
}

const chipEffect = RummiJesterEffectBreakdown(
  jesterId: 'custom',
  displayName: 'Custom',
  chipsBonus: 10,
  multBonus: 0,
  xmultBonus: 1,
  scoreDelta: 10,
);
RummiJesterEffectBreakdown tileEffect(String id) => RummiJesterEffectBreakdown(
  jesterId: id,
  displayName: 'Custom tile',
  chipsBonus: 0,
  multBonus: 0,
  xmultBonus: 1.35,
  scoreDelta: 35,
);

void main() {
  test('settlement fragments have matching keys and placeholders', () {
    final base =
        jsonDecode(
              File(
                'assets/translations/src/core_settlement/ko.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    Set<String> args(String value) =>
        RegExp(r'\{([^}]+)\}').allMatches(value).map((m) => m[1]!).toSet();
    for (final locale in locales) {
      final map =
          jsonDecode(
                File(
                  'assets/translations/src/core_settlement/${code(locale)}.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(map.keys.toSet(), base.keys.toSet());
      for (final key in base.keys) {
        expect(
          args(map[key] as String),
          args(base[key] as String),
          reason: '${code(locale)} $key',
        );
      }
    }
  });

  testWidgets(
    'open receipt and actual jester burst follow five locales without rebuilding state',
    (tester) async {
      await (FontLoader(
        AssetPaths.fontNexonLv2Gothic,
      )..addFont(rootBundle.load('assets/fonts/NEXON Lv2 Gothic.ttf'))).load();
      await (FontLoader(AssetPaths.fontNotoSansCjkUiSubset)..addFont(
            rootBundle.load('assets/fonts/NotoSansCjkUiSubset-Regular.otf'),
          ))
          .load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final receipt = RummiSettlementRuntimeFacade.fromCashOut(
        breakdown: settlementReceipt,
        currentGold: 30,
      );
      final content = ValueNotifier<Widget>(
        Scaffold(body: GameCashOutSheet(settlement: receipt)),
      );
      addTearDown(content.dispose);
      late BuildContext localeContext;
      await tester.pumpWidget(
        EasyLocalization(
          assetLoader: const TestTranslationAssetLoader(),
          supportedLocales: locales,
          path: 'assets/translations',
          startLocale: locales.first,
          fallbackLocale: locales.first,
          saveLocale: false,
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp(
                theme: buildAppTheme(),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                builder: (_, child) => JesterTranslationScope(
                  child: ItemTranslationScope(child: child!),
                ),
                home: ValueListenableBuilder<Widget>(
                  valueListenable: content,
                  builder: (_, child, _) => child,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GameCashOutSheet));
      for (final locale in locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(GameCashOutSheet)), same(state));
        expect(
          find.text(
            expected(locale, 'coreSettlementEndlessReward', {'score': '9999'}),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'coreSettlementBoardDiscard', {
              'count': '2',
              'gold': '2',
            }),
          ),
          findsOneWidget,
        );
        expect(
          find.text(expected(locale, 'coreSettlementFirstBlind')),
          findsOneWidget,
        );
        expect(
          find.text(expected(locale, 'coreSettlementDeckTile')),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'coreSettlementGrowth', {
              'rank': expected(locale, 'coreHandRankFlushFive'),
              'amount': '3',
            }),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'coreSettlementGrowth', {
              'rank': expected(locale, 'coreHandRankFlushHouse'),
              'amount': '2',
            }),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'marketNamedBonus', {'name': '저장된 사용자 이름'}),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      content.value = const Scaffold(
        body: Center(
          child: GameJesterEffectBurst(
            effect: chipEffect,
            sourceName: 'Custom',
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final locale in locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(
            expected(locale, 'coreSettlementEffectChips', {'value': '10'}),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      }
      content.value = Scaffold(
        body: GameFloatingSettlementBurst(
          line: ConfirmedLineBreakdown(
            ref: LineRef.row(0),
            rank: RummiHandRank.flushFive,
            baseScore: 100,
            finalScore: 170,
            jesterBonus: 0,
            hasScoringFaceCard: false,
            effects: [
              tileEffect('tile_edition:prism_edition'),
              tileEffect('tile_seal:echo_seal'),
            ],
          ),
          step: ScoringPresentationStep.tile,
          effectIndex: null,
          effectIndexes: const [0, 1],
        ),
      );
      await tester.pumpAndSettle();
      for (final locale in locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(
            '${expected(locale, 'battleWidgetsTileEditionPrism')} · ${expected(locale, 'battleWidgetsTileSealEcho')}',
          ),
          findsNWidgets(2),
        );
        final badge = expected(locale, 'coreSettlementEffectMultiplier', {
          'value': '1.4',
        });
        expect(find.text('$badge · $badge'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
      content.value = const Scaffold(body: _ResolverProbe());
      await tester.pumpAndSettle();
      for (final locale in locales) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        expect(
          find.text(
            expected(locale, 'coreSettlementEffectMultiplier', {
              'value': '1.4',
            }),
          ),
          findsOneWidget,
        );
        expect(
          find.text(expected(locale, 'battleWidgetsTileEditionPrism')),
          findsOneWidget,
        );
        expect(find.text('Custom tile'), findsOneWidget);
        expect(
          find.text(
            expected(locale, 'coreSettlementEffectPercent', {'value': '10'}),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'coreSettlementEffectScore', {'value': '-10'}),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            expected(locale, 'coreSettlementEffectMultiplier', {'value': '2'}),
          ),
          findsOneWidget,
        );
        expect(
          find.text('coreSettlementGoal'),
          findsOneWidget,
        ); // Legacy text is not reinterpreted as a key.
        expect(find.text('Custom title'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _ResolverProbe extends StatelessWidget {
  const _ResolverProbe();
  @override
  Widget build(BuildContext context) {
    const manual = RummiSettlementEntryView(
      kind: RummiSettlementEntryKind.stationReward,
      leadingLabel: 'Custom title',
      description: 'coreSettlementGoal',
      gold: 0,
    );
    return Column(
      children: [
        Text(jesterEffectBadge(tileEffect('custom'), context: context)),
        Text(
          jesterEffectBadge(
            const RummiJesterEffectBreakdown(
              jesterId: 'custom',
              displayName: 'Custom',
              chipsBonus: 0,
              multBonus: 2,
              xmultBonus: 1,
              scoreDelta: 100,
            ),
            context: context,
          ),
        ),
        Text(
          jesterEffectBadge(
            const RummiJesterEffectBreakdown(
              jesterId: 'custom',
              displayName: 'Custom',
              chipsBonus: 0,
              multBonus: 0,
              xmultBonus: 1,
              scoreDelta: -10,
            ),
            context: context,
          ),
        ),
        Text(
          jesterEffectBadge(
            const RummiJesterEffectBreakdown(
              jesterId: 'custom',
              displayName: 'Custom',
              chipsBonus: 20,
              multBonus: 2,
              xmultBonus: 1.99,
              scoreDelta: 100,
            ),
            context: context,
          ),
        ),
        Text(
          localizedSettlementTileEffectName(
            context,
            tileEffect('tile_edition:prism_edition'),
          ),
        ),
        Text(localizedSettlementTileEffectName(context, tileEffect('unknown'))),
        Text(localizedSettlementDescription(context, manual)),
        Text(localizedSettlementLeading(context, manual)),
      ],
    );
  }
}
