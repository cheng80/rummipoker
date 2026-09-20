import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/views/game/game_presentation_timings.dart';
import 'package:rummipoker/views/game/widgets/game_boss_intro_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const flights = [
    GameBossMarkFlight(
      from: Offset(40, 40),
      to: Rect.fromLTWH(200, 300, 20, 24),
    ),
    GameBossMarkFlight(
      from: Offset(40, 40),
      to: Rect.fromLTWH(200, 340, 20, 24),
    ),
  ];

  testWidgets('비행 레이어는 끝까지 가도, 도중에 사라져도 한 번만 알린다', (tester) async {
    var landed = 0;
    Widget layer() => MaterialApp(
      home: GameBossMarkFlightLayer(flights: flights, onLanded: () => landed++),
    );

    // 정상 완료: 한 번만 알린다.
    await tester.pumpWidget(layer());
    await tester.pump(GameBossMarkFlightLayer.totalDuration(flights.length));
    await tester.pump(const Duration(milliseconds: 16));
    expect(landed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(landed, 1, reason: '완료 뒤 사라져도 다시 알리지 않는다');

    // 비행 도중 레이어가 사라지면 그래도 알린다.
    landed = 0;
    await tester.pumpWidget(layer());
    await tester.pump(GamePresentationTimings.bossMarkFlight ~/ 3);
    expect(landed, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(landed, 1, reason: '완료 없이 사라져도 숨김을 풀 수 있게 알린다');
    await tester.pump(GameBossMarkFlightLayer.totalDuration(flights.length));
    expect(landed, 1);
  });
}
