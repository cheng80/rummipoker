import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/widgets/starry_background.dart';

void main() {
  testWidgets('starry background has no continuous animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StarryBackground())),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });
}
