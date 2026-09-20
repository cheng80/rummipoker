import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/board.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_station_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_surface_metrics.dart';
import 'package:rummipoker/widgets/phone_frame_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_translations.dart';

void main() {
  testWidgets(
    '320x568 English and Japanese resource counts are fully painted',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final remaining = ValueNotifier(2);
      addTearDown(remaining.dispose);
      late BuildContext localeContext;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ja')],
          startLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const TestTranslationAssetLoader(),
          child: Builder(
            builder: (context) {
              localeContext = context;
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: PhoneFrameScaffold(
                  child: Padding(
                    padding: kBattleSurfacePadding,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ValueListenableBuilder<int>(
                        valueListenable: remaining,
                        builder: (context, value, _) => GameBottomInfoRow(
                          station: RummiStationRuntimeFacade(
                            stationType: RummiStationType.currentStage,
                            objective: const RummiStationObjectiveView(
                              targetScore: 900,
                              scoreTowardObjective: 0,
                            ),
                            resources: RummiStationResourceView(
                              boardDiscardsRemaining: 4,
                              boardDiscardsMax: 4,
                              handDiscardsRemaining: value,
                              handDiscardsMax: 2,
                              boardMovesRemaining: 3,
                              boardMovesMax: 3,
                              maxHandSize: 1,
                              drawPileRemaining: 34,
                            ),
                          ),
                          battle: RummiBattleRuntimeFacade(
                            stageIndex: 1,
                            currentGold: 0,
                            totalDeckSize: 52,
                            board: RummiBoard(),
                            hand: [],
                            scoringCellKeys: {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final locale in const [Locale('en'), Locale('ja')]) {
        await localeContext.setLocale(locale);
        await tester.pumpAndSettle();
        for (final count in [2, 1]) {
          remaining.value = count;
          await tester.pump();
          // Check during the resource pulse, including the last-use border.
          await tester.pump(const Duration(milliseconds: 80));
          final texts = find.descendant(
            of: find.byType(GameBottomInfoRow),
            matching: find.byType(Text),
          );
          expect(texts, findsNWidgets(4));
          for (final element in texts.evaluate().toList().reversed) {
            final paragraph = element.findRenderObject()! as RenderParagraph;
            final label = (element.widget as Text).data!;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '${locale.languageCode}: $label',
            );
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(
                baseOffset: label.length - 3,
                extentOffset: label.length,
              ),
            );
            expect(boxes, isNotEmpty);
            for (final box in boxes) {
              expect(box.left, greaterThanOrEqualTo(-0.01));
              expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.01));
              final bottomRight = paragraph.localToGlobal(
                Offset(box.right, box.bottom),
              );
              expect(bottomRight.dx, lessThanOrEqualTo(320));
              expect(bottomRight.dy, lessThanOrEqualTo(568));
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
