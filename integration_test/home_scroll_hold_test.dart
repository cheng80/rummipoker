import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummipoker/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll home until settings is visible and hold', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    app.main();
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('이어하기'), findsWidgets);

    await tester.dragFrom(const Offset(195, 640), const Offset(0, -1200));
    await tester.pump(const Duration(seconds: 1));

    debugPrint('HOME_SCROLL_READY_FOR_SCREENSHOT');
    await Future<void>.delayed(const Duration(seconds: 15));
  });
}
