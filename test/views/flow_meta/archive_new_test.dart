import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/archive_seen_service.dart';
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
    // 이전 테스트의 FakeAsync에 연결된 asset Future를 재사용하지 않는다.
    rootBundle.evict(AssetPaths.jestersCommon);
    rootBundle.evict(AssetPaths.itemsCommon);
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.sfxMuted = true;
  });

  for (final (key, update) in const [
    (
      'archive-jester-jester',
      RunCollectionUpdate(seenMarketJesterIds: {'jester'}),
    ),
    (
      'archive-item-reroll_token',
      RunCollectionUpdate(seenMarketItemIds: {'reroll_token'}),
    ),
    (
      'archive-memory-memory_card_expired_standard_s2',
      RunCollectionUpdate(
        earnedMemoryCardIds: {'memory_card_expired_standard_s2'},
      ),
    ),
  ]) {
    testWidgets('Archive NEW 첫 클릭과 재클릭은 원음 1회: $key', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        SoundManager.debugResetForTest();
        GameHaptics.debugSink = null;
      });

      // 기존 항목 확인 기준을 만든 뒤 새 발견을 추가한다.
      await ArchiveSeenService.ensureInitialized();
      await RunUnlockStateService.recordRunCollection(update);
      await _openArchive(tester);
      final card = find.byKey(ValueKey(key));
      final newTag = find.descendant(
        of: card,
        matching: find.byKey(const ValueKey('archive-new-tag')),
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(newTag, findsOneWidget);

      final sounds = <(String, double)>[];
      final haptics = <HapticGrade>[];
      GameSettings.sfxMuted = false;
      GameSettings.hapticsEnabled = true;
      SoundManager.debugSfxSink = (path, _, rate) => sounds.add((path, rate));
      GameHaptics.debugSink = haptics.add;
      SoundManager.rampGlobalPitch(0.5, Duration.zero);

      for (var click = 0; click < 2; click++) {
        sounds.clear();
        haptics.clear();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(sounds, [(AssetPaths.sfxBtnSnd, 1.0)], reason: 'click=$click');
        expect(
          haptics,
          click == 0
              ? [HapticGrade.select, HapticGrade.impact]
              : [HapticGrade.select],
        );
        expect(newTag, findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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
