import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/views/game/widgets/game_effect_overlay.dart';
import 'package:rummipoker/widgets/fx/fx_layer.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_station_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/utils/app_translation.dart';
import 'package:rummipoker/views/game/widgets/game_bookmark_slot_dialog.dart';
import 'package:rummipoker/views/game/widgets/game_boss_intro_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_hand_zone.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_tile_choice_dialog.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import '../../../support/test_translations.dart';

const _locales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];
const _codes = ['ko', 'en', 'ja', 'zh-CN', 'zh-TW'];
const _station = RummiStationRuntimeFacade(
  stationType: RummiStationType.currentStage,
  objective: RummiStationObjectiveView(
    targetScore: 100,
    scoreTowardObjective: 0,
  ),
  resources: RummiStationResourceView(
    boardDiscardsRemaining: 3,
    boardDiscardsMax: 3,
    handDiscardsRemaining: 3,
    handDiscardsMax: 3,
    boardMovesRemaining: 3,
    boardMovesMax: 3,
    maxHandSize: 3,
    drawPileRemaining: 20,
  ),
);
const _customBoss = RummiBossModifier(
  id: 'custom-i2',
  category: RummiBossModifierCategory.boardCellBlock,
  title: 'Custom title',
  ruleText: 'Custom rule stays literal.',
  markerText: 'Custom mark',
  scoreMultiplier: 1,
);

void main() {
  setUpAll(() async {
    await (FontLoader(
      'NexonLv2Gothic',
    )..addFont(rootBundle.load('assets/fonts/NEXON Lv2 Gothic.ttf'))).load();
    await (FontLoader('NotoSansCjkUiSubset')..addFont(
          rootBundle.load('assets/fonts/NotoSansCjkUiSubset-Regular.otf'),
        ))
        .load();
  });
  testWidgets(
    'battle widgets and an open game-over route follow all five locales',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MotionPolicy.debugReduceMotionOverride = true;
      addTearDown(() => MotionPolicy.debugReduceMotionOverride = null);
      GameSettings.bgmMuted = true;
      GameSettings.sfxMuted = true;
      final content = ValueNotifier<Widget>(const SizedBox());
      addTearDown(content.dispose);
      late BuildContext screenContext;
      await tester.pumpWidget(
        EasyLocalization(
          assetLoader: const TestTranslationAssetLoader(),
          supportedLocales: _locales,
          path: 'assets/translations',
          startLocale: _locales.first,
          fallbackLocale: _locales.first,
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              theme: ThemeData(
                fontFamily: 'NexonLv2Gothic',
                fontFamilyFallback: const ['NotoSansCjkUiSubset'],
              ),
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: JesterTranslationScope(
                child: ItemTranslationScope(
                  child: Builder(
                    builder: (context) {
                      screenContext = context;
                      return Scaffold(
                        body: Center(
                          child: ValueListenableBuilder<Widget>(
                            valueListenable: content,
                            builder: (_, child, _) => child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      final translations = [
        for (final code in _codes)
          (jsonDecode(File('assets/translations/$code.json').readAsStringSync())
              as Map<String, dynamic>),
      ];
      Future<void> switchLocale(int i) async {
        await screenContext.setLocale(_locales[i]);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: _codes[i]);
        for (final element in find.byType(RichText).evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '${_codes[i]} clipped: ${paragraph.text.toPlainText()}',
          );
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: 0,
              extentOffset: paragraph.text.toPlainText().length,
            ),
          );
          // Glyphs may extend beyond a height:1 line box into its padding.
          // Check the enclosing padded/aligned surface, not that line box.
          RenderObject? ancestor = paragraph.parent;
          while (ancestor is RenderBox &&
              ancestor is! RenderPadding &&
              ancestor is! RenderPositionedBox &&
              ancestor is! RenderFlex) {
            ancestor = ancestor.parent;
          }
          if (ancestor is RenderBox) {
            for (final box in boxes) {
              final bottom = paragraph
                  .localToGlobal(Offset(0, box.bottom), ancestor: ancestor)
                  .dy;
              expect(
                bottom,
                lessThanOrEqualTo(ancestor.size.height + 2),
                reason:
                    '${_codes[i]} surface height: ${paragraph.text.toPlainText()}',
              );
            }
          }
        }
      }

      void expectKey(int i, String key, {Map<String, String> args = const {}}) {
        var value = translations[i][key] as String;
        for (final entry in args.entries) {
          value = value.replaceAll('{${entry.key}}', entry.value);
        }
        expect(find.text(value), findsWidgets, reason: '${_codes[i]} $key');
      }

      // Keep the same stateful Boss card mounted across locale changes. Its
      // animated icon metadata must not freeze the initial Korean marker.
      content.value = GameBossIntroCard(
        modifier: RummiBossModifier.repeatRankPressure,
        buttonLabel: 'OK',
        onConfirm: () {},
        animate: false,
        maxHeight: 640,
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        final keys = RummiBossModifier.repeatRankPressure.displayKeys!;
        expectKey(i, keys.titleKey);
        expectKey(i, keys.ruleTextKey);
        expectKey(i, keys.markerTextKey);
      }
      content.value = GameBossIntroCard(
        modifier: _customBoss,
        buttonLabel: 'OK',
        onConfirm: () {},
        animate: false,
      );
      await tester.pumpAndSettle();
      expect(find.text(_customBoss.title), findsOneWidget);
      expect(find.text(_customBoss.ruleText), findsOneWidget);
      expect(find.text(_customBoss.markerText), findsOneWidget);

      content.value = const GameTileChoiceDialog(
        title: '',
        message: 'Choose one.',
        tiles: [Tile(color: TileColor.red, number: 1)],
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expectKey(i, 'battleWidgetsTileCandidate', args: {'index': '1'});
        final expected =
            (translations[i]['battleWidgetsTileCandidateLabel'] as String)
                .replaceAll('{index}', '1')
                .replaceAll('{code}', 'R1');
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == expected,
          ),
          findsOneWidget,
        );
      }

      final battle = RummiBattleRuntimeFacade(
        stageIndex: 1,
        currentGold: 0,
        totalDeckSize: 52,
        board: RummiBoard(),
        hand: const [],
        scoringCellKeys: const {},
        itemSlots: const [],
      );
      content.value = GameHandZone(
        battle: battle,
        station: _station,
        hand: const [],
        selectedHandTile: null,
        onHandTileTap: (_) {},
        onHandTileLongPress: (_) {},
        onDraw: () {},
        tileWidth: 48,
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expectKey(i, 'battleWidgetsHandEmpty');
        expectKey(i, 'battleWidgetsDraw');
        expectKey(i, 'battleWidgetsHandSpace', args: {'count': '3'});
      }

      content.value = GameTopHud(
        difficulty: NewRunDifficulty.challenge,
        runModifier: NewRunModifier.highStakes,
        station: _station,
        battle: battle,
        onOptionsTap: () {},
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expect(
          find.textContaining(translations[i]['menuChallenge'] as String),
          findsOneWidget,
        );
        expect(
          find.textContaining(translations[i]['menuHighStakes'] as String),
          findsOneWidget,
        );
        expectKey(
          i,
          'battleWidgetsReward',
          args: {'gold': '${RummiRunProgress.stageClearGoldBase}'},
        );
      }

      final item = ItemDefinition.fromJson({
        'id': 'deck_needle',
        'displayName': 'fallback item',
        'effectText': 'fallback effect',
        'type': 'utility',
        'rarity': 'common',
        'placement': 'quickSlot',
        'usableInBattle': true,
        'effect': {
          'timing': 'use_battle',
          'op': 'peek_deck_discard_one',
          'amount': 1,
          'consume': true,
        },
      });
      for (final placement in [
        ItemPlacement.quickSlot,
        ItemPlacement.passiveRack,
        ItemPlacement.inventory,
      ]) {
        content.value = GameBattleItemInfoOverlay(
          itemSlot: RummiBattleItemSlotView(
            slotIndex: 0,
            slotLabel: 'Q1',
            contentId: item.id,
            displayName: item.displayName,
            displayNameKey: item.displayNameKey,
            effectText: item.effectText,
            effectTextKey: item.effectTextKey,
            count: 1,
            placement: placement,
            usableInBattle: true,
            item: item,
          ),
          onUse: () {},
          onClose: () {},
        );
        for (var i = 0; i < _locales.length; i++) {
          await switchLocale(i);
          expectKey(i, switch (placement) {
            ItemPlacement.quickSlot => 'battleWidgetsUse',
            ItemPlacement.passiveRack => 'battleWidgetsPassiveNotice',
            _ => 'battleWidgetsToolNotice',
          });
          expect(find.text('fallback item'), findsNothing);
          expect(find.text('fallback effect'), findsNothing);
        }
      }

      content.value = GameHandTileInfoOverlay(
        tile: const Tile(
          color: TileColor.blue,
          number: 7,
          enhancement: TileEnhancement.chipInlaid,
          seal: TileSeal.fractureSeal,
          edition: TileEdition.prismEdition,
        ),
        constrained: true,
        bossModifier: RummiBossModifier.repeatRankPressure,
        onClose: () {},
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expect(
          find.textContaining(
            translations[i]['battleWidgetsTileSealFractureEffect'] as String,
          ),
          findsOneWidget,
        );
        expect(
          find.byTooltip(translations[i]['battleWidgetsClose'] as String),
          findsOneWidget,
        );
      }

      final card = RummiJesterCard.fromJson({
        'id': 'ice_cream',
        'displayName': 'fallback',
        'effectText': 'fallback',
        'effectType': 'stateful_growth',
      });
      content.value = Builder(
        builder: (context) => GameJesterInfoOverlay(
          card: card,
          runtimeValueText: jesterRuntimeValueText(
            card,
            const RummiJesterRuntimeSnapshot(slotStateValues: {0: 4}),
            slotIndex: 0,
            context: context,
          ),
          sellGold: 3,
          onSell: () {},
          onClose: () {},
        ),
      );
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expectKey(i, 'battleWidgetsSellGold', args: {'gold': '3'});
        expectKey(i, 'battleWidgetsCurrentChips', args: {'count': '4'});
        expect(
          find.text('fallback'),
          findsNothing,
          reason: 'catalog scope must resolve before display',
        );
      }

      // Translate the displayed effect on rebuild, without restarting its
      // sequence or storing a previously translated marker in state.
      Fx.debugReset();
      final boss = RummiBossModifier.repeatRankPressure;
      content.value = SizedBox.square(
        dimension: 240,
        child: GameBoardEffectOverlay(
          activeSettlementLine: ConfirmedLineBreakdown(
            ref: LineRef.row(0),
            rank: RummiHandRank.straight,
            baseScore: 70,
            finalScore: 56,
            jesterBonus: 0,
            hasScoringFaceCard: false,
            effects: const [],
            contributingCells: const [(0, 0), (0, 1), (0, 2)],
            constraintPenalties: [
              RummiConstraintPenaltyBreakdown(
                modifierId: boss.id,
                title: boss.title,
                ruleText: boss.ruleText,
                markerText: boss.markerText,
                scoreDelta: -14,
                scoreMultiplier: 0.8,
              ),
            ],
          ),
          activeSettlementStep: ScoringPresentationStep.constraint,
          settlementSequenceTick: 1,
          frameInset: 6,
          gridGap: 4,
        ),
      );
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < _locales.length; i++) {
        await screenContext.setLocale(_locales[i]);
        await tester.pump();
        await tester.pump();
        expectKey(i, boss.displayKeys!.markerTextKey);
        expect(tester.takeException(), isNull);
      }
      await tester.pump(const Duration(seconds: 2));
      Fx.debugReset();

      content.value = const SizedBox();
      await switchLocale(0);
      showGameOverDialog(
        context: screenContext,
        signals: const [RummiExpirySignal.drawPileExhausted],
        insightReward: 1,
        runSummary: const GameOverRunSummary(
          difficulty: NewRunDifficulty.challenge,
          runModifier: NewRunModifier.highStakes,
          stageIndex: 1,
          scoreTowardTarget: 0,
          targetScore: 100,
          seed: 0,
          bestRank: RummiHandRank.flush,
          bestRankScore: 80,
        ),
        onRetryStake: () async {},
        onRetryStation: () async {},
        onNewRun: () async {},
        onExit: () async {},
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expectKey(i, 'gameResult');
        expect(
          find.textContaining(translations[i]['menuChallenge'] as String),
          findsOneWidget,
        );
        expect(
          find.textContaining(translations[i]['menuHighStakes'] as String),
          findsOneWidget,
        );
        expectKey(i, 'battleWidgetsRetryBattle');
        expectKey(i, 'battleWidgetsTaunt1');
        expectKey(i, 'battleWidgetsMemoryEarned');
        expect(
          find.textContaining(
            translations[i]['battleWidgetsExpiryDeck'] as String,
          ),
          findsOneWidget,
        );
        expectKey(
          i,
          'battleWidgetsBestHandValue',
          args: {
            'rank': translations[i]['coreHandRankFlush'] as String,
            'chips': '80',
          },
        );
      }
      Navigator.of(screenContext).pop();
      await tester.pumpAndSettle();
      final bookmarkResult = showBookmarkSlotDialog(
        context: screenContext,
        titleBuilder: (dialogContext) =>
            dialogContext.translate('runInfoTitle'),
        messageBuilder: (dialogContext) =>
            dialogContext.translate('battleWidgetsMemoryDescription'),
        slots: const [
          ActiveRunBookmarkSlotView(slotIndex: 0, summary: null),
          ActiveRunBookmarkSlotView(
            slotIndex: 1,
            summary: RummiActiveRunSaveFacade(
              schemaVersion: 2,
              activeScene: 'battle',
              sceneAlias: RummiSaveSceneAlias.battle,
              difficulty: NewRunDifficulty.challenge,
              runModifier: NewRunModifier.highStakes,
              currentStageIndex: 9,
              currentStationIndex: 9,
              currentBlindTierIndex: 2,
              currentRunSeed: 42,
              currentGold: 27,
              checkpoint: RummiStationCheckpointSaveView(
                stageIndex: 9,
                stationIndex: 9,
                runSeed: 42,
                gold: 10,
              ),
            ),
          ),
          ActiveRunBookmarkSlotView(
            slotIndex: 2,
            summary: RummiActiveRunSaveFacade(
              schemaVersion: 2,
              activeScene: 'battle',
              sceneAlias: RummiSaveSceneAlias.battle,
              difficultyLabel: 'Custom mode',
              runModifierLabel: 'Custom modifier',
              currentStageIndex: 1,
              currentStationIndex: 1,
              currentBlindTierIndex: -1,
              currentRunSeed: 42,
              currentGold: 27,
              checkpoint: RummiStationCheckpointSaveView(
                stageIndex: 1,
                stationIndex: 1,
                runSeed: 42,
                gold: 10,
              ),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < _locales.length; i++) {
        await switchLocale(i);
        expectKey(i, 'runInfoTitle');
        expectKey(i, 'battleWidgetsMemoryDescription');
        expectKey(i, 'cancel');
        expectKey(i, 'coreSaveEmpty');
        for (var slot = 1; slot <= 3; slot++) {
          expectKey(i, 'coreSaveSlotTitle', args: {'slot': '$slot'});
        }
        expect(find.textContaining('∞S9'), findsOneWidget);
        expect(
          find.textContaining(translations[i]['menuChallenge'] as String),
          findsOneWidget,
        );
        expect(
          find.textContaining(translations[i]['menuHighStakes'] as String),
          findsOneWidget,
        );
        expect(
          find.textContaining('Custom mode · Custom modifier'),
          findsOneWidget,
        );
        final slotTitle = (translations[i]['coreSaveSlotTitle'] as String)
            .replaceAll('{slot}', '1');
        final semantic = (translations[i]['coreSaveSlotSemantic'] as String)
            .replaceAll('{slot}', slotTitle)
            .replaceAll(
              '{summary}',
              translations[i]['coreSaveEmpty'] as String,
            );
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(semantic)}')),
          findsOneWidget,
        );
      }
      Navigator.of(screenContext).pop();
      expect(await bookmarkResult, isNull);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
