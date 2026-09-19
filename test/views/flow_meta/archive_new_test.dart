import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/archive_view.dart';

Future<void> _openArchive(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ArchiveView())),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.sfxMuted = true;
  });

  testWidgets('Archive NEW는 기존 사용자에게 뜨지 않고 새 발견에만 뜨며, 처음 열 때 한 번 뒤집힌다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 업데이트 전부터 발견 기록이 있던 사용자(새 키 없음).
    await RunUnlockStateService.recordRunCollection(
      const RunCollectionUpdate(seenMarketJesterIds: {'jester'}),
    );
    expect(
      StorageHelper.hasData(StorageKeys.archiveAcknowledgedIdsV1),
      isFalse,
    );

    await _openArchive(tester);
    expect(find.byKey(const ValueKey('archive-new-tag')), findsNothing);
    expect(
      find.textContaining('Jester 수집 1/'),
      findsOneWidget,
      reason: 'count-up 끝값',
    );

    // 이후 새로 발견한 항목만 NEW다.
    await RunUnlockStateService.recordRunCollection(
      const RunCollectionUpdate(seenMarketJesterIds: {'greedy_jester'}),
    );
    await _openArchive(tester);
    expect(find.byKey(const ValueKey('archive-new-tag')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('archive-new-tag')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.byKey(const ValueKey('archive-new-tag')),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final flipping = tester
        .widgetList<Transform>(
          find.byKey(const ValueKey('archive-flip-reveal')),
        )
        .where((t) => t.transform.storage[0] < 0.99);
    expect(flipping, isNotEmpty, reason: '처음 열 때 뒤집힌다');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('archive-new-tag')), findsNothing);

    // 확인한 항목은 다시 NEW로 뜨지 않는다.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await _openArchive(tester);
    expect(find.byKey(const ValueKey('archive-new-tag')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
