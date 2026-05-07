import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/archive_view.dart';

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
  });

  testWidgets('ArchiveView shows competition compendium entries', (
    tester,
  ) async {
    await RunUnlockStateService.recordRunCollection(
      const RunCollectionUpdate(
        seenMarketJesterIds: {'green_jester'},
        seenMarketItemIds: {'coin_cache'},
        boughtJesterIds: {'green_jester'},
        boughtItemIds: {'coin_cache'},
        seenBossModifierIds: {'red_dampener_v1'},
        clearedStationKeys: {'station_1'},
        earnedMemoryCardIds: {'memory_card_expired_standard_s2'},
      ),
    );
    await RunUnlockStateService.addInsight(4);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArchiveView())),
    );

    await tester.pumpAndSettle();

    expect(find.text('도감'), findsOneWidget);
    expect(find.text('기억 카드'), findsAtLeastNWidgets(1));
    expect(find.textContaining('보유 4장'), findsOneWidget);
    expect(find.textContaining('Jester 1/'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Item 1/'), findsAtLeastNWidgets(1));
    expect(find.text('미발견'), findsAtLeastNWidgets(1));
    expect(find.text('획득'), findsAtLeastNWidgets(1));
    expect(find.text('클리어'), findsNothing);
    expect(find.text('구매 기록'), findsNothing);
    expect(find.text('진행 기록'), findsNothing);
    expect(find.textContaining('만난 Boss'), findsNothing);
    expect(find.textContaining('깬 Station'), findsNothing);
    expect(find.text('하이 스테이크'), findsOneWidget);
    expect(find.text('Jester'), findsAtLeastNWidgets(1));
    expect(find.text('Item'), findsAtLeastNWidgets(1));
    expect(find.text('Boss'), findsOneWidget);
    expect(find.textContaining('Insight'), findsNothing);

    final acquiredBadge = find
        .ancestor(
          of: find.text('획득').first,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.alignment == Alignment.center,
          ),
        )
        .first;
    final undiscoveredBadge = find
        .ancestor(
          of: find.text('미발견').first,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.alignment == Alignment.center,
          ),
        )
        .first;
    final acquiredCard = find
        .ancestor(
          of: find.text('표준 S2'),
          matching: find.byType(GestureDetector),
        )
        .first;

    expect(tester.getSize(acquiredBadge), tester.getSize(undiscoveredBadge));
    expect(
      tester.getSize(acquiredBadge).width,
      lessThan(tester.getSize(acquiredCard).width),
    );
    expect(
      find.ancestor(of: acquiredBadge, matching: find.byType(GestureDetector)),
      findsNothing,
    );
    expect(
      tester.getTopLeft(find.text('획득').first).dy,
      greaterThan(tester.getBottomLeft(find.text('표준 S2')).dy),
    );

    await tester.tap(find.text('표준 S2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('획득 · 기억 카드'), findsOneWidget);
    expect(find.textContaining('게임오버나 런 완료 후'), findsOneWidget);
  });
}
