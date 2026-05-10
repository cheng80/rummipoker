import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/utils/common_ui.dart';

void main() {
  testWidgets('showTopNotice stays inside the phone frame on wide screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showTopNotice(context, '상단 배너'),
                child: const Text('show top'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show top'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final noticeRect = tester.getRect(
      find.byKey(const ValueKey('common-top-notice')),
    );
    final expectedFrameWidth = 390 * (720 / 750);
    final expectedFrameLeft = (1280 - expectedFrameWidth) / 2;

    expect(noticeRect.left, greaterThanOrEqualTo(expectedFrameLeft));
    expect(noticeRect.right, lessThanOrEqualTo(1280 - expectedFrameLeft));
    expect(noticeRect.top, greaterThanOrEqualTo(0));

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('showBottomNotice stays inside the phone frame on wide screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showBottomNotice(context, '하단 배너'),
                child: const Text('show bottom'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show bottom'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final noticeRect = tester.getRect(
      find.byKey(const ValueKey('common-bottom-notice')),
    );
    final expectedFrameWidth = 390 * (720 / 750);
    final expectedFrameLeft = (1280 - expectedFrameWidth) / 2;

    expect(noticeRect.left, greaterThanOrEqualTo(expectedFrameLeft));
    expect(noticeRect.right, lessThanOrEqualTo(1280 - expectedFrameLeft));
    expect(noticeRect.bottom, lessThanOrEqualTo(720));

    await tester.pump(const Duration(seconds: 3));
  });

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
