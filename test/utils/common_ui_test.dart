import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/utils/common_ui.dart';

void main() {
  testWidgets('showGameChoiceDialog constrains long scroll content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showGameChoiceDialog<String>(
                    context,
                    title: '디버그 픽스처',
                    content: SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var index = 0; index < 36; index++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text('fixture option $index'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    actions: const [
                      GameDialogAction<String>(label: '닫기', value: 'cancel'),
                    ],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('디버그 픽스처'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
