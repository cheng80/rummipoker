# Task 7 Compact Review Packet v2

## Reviewer Rejection Addressed

v1 rejected for: missing explicit tileOffers save/restore evidence, untracked new test file not shown in diff, and placeholder-copy assertions not visible enough. v2 embeds the new test file content and explicit tileOffers test output.

## Scope

Changed Task 7 files:
- `lib/views/game/widgets/game_shared_tile_widgets.dart`
- `test/views/game/widgets/game_tile_modifier_copy_test.dart` (untracked new file; full content embedded below)
- `test/logic/tile_model_test.dart`
- `test/services/active_run_save_service_test.dart`

## Scoped Git Diff
```diff
diff --git a/lib/views/game/widgets/game_shared_tile_widgets.dart b/lib/views/game/widgets/game_shared_tile_widgets.dart
index bc25f03..4dbc77f 100644
--- a/lib/views/game/widgets/game_shared_tile_widgets.dart
+++ b/lib/views/game/widgets/game_shared_tile_widgets.dart
@@ -358,8 +358,8 @@ String tileEnhancementEffectText(TileEnhancement enhancement) {
     TileEnhancement.scoreGilded => '확정 시 점수 +20%',
     TileEnhancement.goldTile => '확정 후 골드 +1',
     TileEnhancement.glassTile => '확정 시 점수 x1.5',
-    TileEnhancement.wildPainted => '색상 판정 확장 예정',
-    TileEnhancement.luckyTile => '확률 발동 예정',
+    TileEnhancement.wildPainted => '현재 확정 점수 효과 없음',
+    TileEnhancement.luckyTile => '현재 확정 점수 효과 없음',
   };
 }
 
diff --git a/test/logic/tile_model_test.dart b/test/logic/tile_model_test.dart
index 7d411de..038c17d 100644
--- a/test/logic/tile_model_test.dart
+++ b/test/logic/tile_model_test.dart
@@ -44,6 +44,36 @@ void main() {
       });
     });
 
+    test('all persisted modifier values survive json roundtrip', () {
+      for (final enhancement in TileEnhancement.values) {
+        final restored = Tile.fromJson(
+          Tile(
+            color: TileColor.red,
+            number: 1,
+            enhancement: enhancement,
+          ).toJson(),
+        );
+        expect(restored.enhancement, enhancement, reason: enhancement.name);
+      }
+
+      for (final seal in TileSeal.values) {
+        final restored = Tile.fromJson(
+          Tile(color: TileColor.blue, number: 2, seal: seal).toJson(),
+        );
+        expect(restored.seal, seal, reason: seal.name);
+      }
+
+      for (final edition in TileEdition.values) {
+        final restored = Tile.fromJson(
+          Tile(color: TileColor.yellow, number: 3, edition: edition).toJson(),
+        );
+        expect(restored.edition, edition, reason: edition.name);
+      }
+
+      expect(TileSeal.fromPersistenceValue('risk_seal'), TileSeal.fractureSeal);
+      expect(TileSeal.fromPersistenceValue('riskSeal'), TileSeal.fractureSeal);
+    });
+
     test('physical equality ignores modifiers', () {
       const base = Tile(color: TileColor.red, number: 7, id: 1);
       const enhanced = Tile(
diff --git a/test/services/active_run_save_service_test.dart b/test/services/active_run_save_service_test.dart
index 135faf8..71411ae 100644
--- a/test/services/active_run_save_service_test.dart
+++ b/test/services/active_run_save_service_test.dart
@@ -876,6 +876,55 @@ void main() {
       expect(restored.runProgress.pendingBossTileReward, isTrue);
     });
 
+    test('run progress saves and restores tileOffers modifiers', () async {
+      final runProgress = RummiRunProgress()
+        ..tileOffers.addAll(const [
+          Tile(
+            color: TileColor.blue,
+            number: 9,
+            enhancement: TileEnhancement.glassTile,
+            seal: TileSeal.redSeal,
+            edition: TileEdition.prismEdition,
+          ),
+          Tile(
+            color: TileColor.yellow,
+            number: 12,
+            enhancement: TileEnhancement.goldTile,
+            seal: TileSeal.bridgeSeal,
+            edition: TileEdition.glowEdition,
+          ),
+        ]);
+      final runtime = ActiveRunRuntimeState(
+        activeScene: ActiveRunScene.shop,
+        difficulty: NewRunDifficulty.standard,
+        runModifier: NewRunModifier.basic,
+        session: RummiPokerGridSession(runSeed: 10),
+        runProgress: runProgress,
+        stageStartSnapshot: ActiveRunStageSnapshot(
+          session: RummiPokerGridSession(runSeed: 10),
+          runProgress: runProgress.copySnapshot(),
+        ),
+      );
+
+      await ActiveRunSaveService.saveRuntimeState(runtime);
+      final restored = await ActiveRunSaveService.loadActiveRun();
+
+      expect(restored, isNotNull);
+      expect(restored!.runProgress.tileOffers, hasLength(2));
+      expect(restored.runProgress.tileOffers.map((tile) => tile.enhancement), [
+        TileEnhancement.glassTile,
+        TileEnhancement.goldTile,
+      ]);
+      expect(restored.runProgress.tileOffers.map((tile) => tile.seal), [
+        TileSeal.redSeal,
+        TileSeal.bridgeSeal,
+      ]);
+      expect(restored.runProgress.tileOffers.map((tile) => tile.edition), [
+        TileEdition.prismEdition,
+        TileEdition.glowEdition,
+      ]);
+    });
+
     test(
       'session tile modifiers survive deck board hand eliminated roundtrip',
       () async {
@@ -976,7 +1025,10 @@ void main() {
           TileEnhancement.chipInlaid,
         );
         expect(
-          restored.stageStartSnapshot.session.deck.snapshotPile().single.edition,
+          restored.stageStartSnapshot.session.deck
+              .snapshotPile()
+              .single
+              .edition,
           TileEdition.silverEdition,
         );
         expect(
```

## New Tile Modifier Copy Test File
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  group('tile modifier copy', () {
    test('every persisted modifier has concrete display and effect text', () {
      const blockedCopy = ['예정', '준비 중'];

      for (final enhancement in TileEnhancement.values) {
        final values = [
          tileEnhancementShortLabel(enhancement),
          tileEnhancementDisplayName(enhancement),
          tileEnhancementEffectText(enhancement),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: enhancement.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: enhancement.name);
          }
        }
      }

      for (final seal in TileSeal.values) {
        final values = [
          tileSealShortLabel(seal),
          tileSealDisplayName(seal),
          tileSealEffectText(seal),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: seal.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: seal.name);
          }
        }
      }

      for (final edition in TileEdition.values) {
        final values = [
          tileEditionShortLabel(edition),
          tileEditionDisplayName(edition),
          tileEditionEffectText(edition),
        ];
        for (final value in values) {
          expect(value.trim(), isNotEmpty, reason: edition.name);
          for (final blocked in blockedCopy) {
            expect(value, isNot(contains(blocked)), reason: edition.name);
          }
        }
      }
    });
  });
}
```

## RED Evidence
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/views/game/widgets/game_tile_modifier_copy_test.dart
00:00 +0: tile modifier copy every persisted modifier has concrete display and effect text
00:00 +0 -1: tile modifier copy every persisted modifier has concrete display and effect text [E]
  Expected: not contains '예정'
    Actual: '색상 판정 확장 예정'
  wildPainted
  
  package:matcher                                                  expect
  package:flutter_test/src/widget_tester.dart 473:18               expect
  test/views/game/widgets/game_tile_modifier_copy_test.dart 19:13  main.<fn>.<fn>
  
00:00 +0 -1: Some tests failed.

Failing tests:
  /Users/cheng80/Desktop/flame_binggo_card/test/views/game/widgets/game_tile_modifier_copy_test.dart: tile modifier copy every persisted modifier has concrete display and effect text
```

## GREEN Tile Detail Evidence
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/views/game/widgets/game_tile_modifier_copy_test.dart
00:00 +0: tile modifier copy every persisted modifier has concrete display and effect text
00:00 +1: All tests passed!
```

## Roundtrip Evidence
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/tile_model_test.dart
00:00 +0: Tile modifier persistence legacy tile json restores without modifiers
00:00 +1: Tile modifier persistence enhancement seal and edition survive json roundtrip
00:00 +2: Tile modifier persistence all persisted modifier values survive json roundtrip
00:00 +3: Tile modifier persistence physical equality ignores modifiers
00:00 +4: All tests passed!

00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/services/active_run_save_service_test.dart
00:00 +0: ActiveRunSaveService run progress saves and restores added deck tiles
00:00 +1: ActiveRunSaveService run progress saves and restores tileOffers modifiers
00:00 +2: ActiveRunSaveService session tile modifiers survive deck board hand eliminated roundtrip
00:00 +3: All tests passed!
```

## Settlement Evidence
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/rummi_session_test.dart
00:00 +0: 특수 타일 점수 보정은 확정 점수와 breakdown에 반영된다
00:00 +1: 빨간 봉인은 특수 타일 점수 효과를 한 번 더 적용한다
00:00 +2: 타일 판본은 확정 점수와 breakdown에 반영된다
00:00 +3: 각인 타일은 확정 점수, 골드, 족보 성장에 반영된다
00:00 +4: 닻 각인은 이번 Station에 이동한 타일에만 점수 보너스를 준다
00:00 +5: 겹친 각인은 같은 타일이 두 줄 이상에 기여할 때만 발동한다
00:00 +6: 유리 타일 파괴는 추가 덱 타일 source에서 제거된다
00:00 +7: All tests passed!
```

## Analyze And Cleanup
```text
Analyzing game_shared_tile_widgets.dart, game_tile_modifier_copy_test.dart, tile_model_test.dart, active_run_save_service_test.dart...
No issues found!

cleanup receipt 2026-06-03 10:23:10 KST
tmux: unavailable
flutter/webdriver/headless residue after excluding this receipt command:
conclusion: no flutter test/flutter_tester/chromedriver/webdriver/flutter web server/headless Chrome residue from Task 7 tests.
```

## Review Questions

1. Does RED/GREEN prove tile detail copy blocks both `예정` and `준비 중` placeholders?
2. Does explicit output prove `tileOffers` modifiers save/restore?
3. Does roundtrip evidence cover all persisted TileEnhancement/TileSeal/TileEdition values plus addedDeckTiles/deck/board/hand/eliminated?
4. Does settlement evidence prove documented modifier effects still apply?
