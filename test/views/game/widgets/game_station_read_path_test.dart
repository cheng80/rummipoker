import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_station_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  testWidgets('GameTopHud renders station facade objective values', (
    tester,
  ) async {
    final runProgress = RummiRunProgress()
      ..stageIndex = 4
      ..gold = 27;
    const station = RummiStationRuntimeFacade(
      stationType: RummiStationType.currentStage,
      objective: RummiStationObjectiveView(
        targetScore: 900,
        scoreTowardObjective: 360,
      ),
      resources: RummiStationResourceView(
        boardDiscardsRemaining: 2,
        boardDiscardsMax: 4,
        handDiscardsRemaining: 1,
        handDiscardsMax: 2,
        maxHandSize: 3,
        drawPileRemaining: 18,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameTopHud(
            station: station,
            runProgress: runProgress,
            onOptionsTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('360 / 900'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('GameBottomInfoRow renders station facade resource values', (
    tester,
  ) async {
    const station = RummiStationRuntimeFacade(
      stationType: RummiStationType.currentStage,
      objective: RummiStationObjectiveView(
        targetScore: 900,
        scoreTowardObjective: 360,
      ),
      resources: RummiStationResourceView(
        boardDiscardsRemaining: 3,
        boardDiscardsMax: 4,
        handDiscardsRemaining: 1,
        handDiscardsMax: 2,
        maxHandSize: 3,
        drawPileRemaining: 14,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameBottomInfoRow(
            station: station,
            totalDeckSize: 52,
            currentHandSize: 2,
          ),
        ),
      ),
    );

    expect(find.text('덱 14/52'), findsOneWidget);
    expect(find.text('보드패 버림 3/4'), findsOneWidget);
    expect(find.text('손패 2/3 · 버림 1/2'), findsOneWidget);
  });
}
