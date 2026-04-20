import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open new run, scroll until seed snapshot is visible, and hold', (
    tester,
  ) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    app.main();
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.widgetWithText(InkWell, '새 게임 시작'));
    await tester.pump(const Duration(seconds: 2));

    await tester.dragFrom(const Offset(195, 640), const Offset(0, -700));
    await tester.pump(const Duration(seconds: 1));

    debugPrint('NEW_RUN_SCROLL_READY_FOR_SCREENSHOT');
    await Future<void>.delayed(const Duration(seconds: 15));
  });
}
