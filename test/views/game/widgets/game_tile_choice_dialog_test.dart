import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_tile_choice_dialog.dart';

void main() {
  testWidgets(
    'tile choice click emits one original button and disabled repeat is silent',
    (tester) async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues({});
      await StorageHelper.init();
      GameSettings.sfxMuted = false;
      final sounds = <(String, double)>[];
      SoundManager.debugSfxSink = (path, _, rate) => sounds.add((path, rate));
      SoundManager.rampGlobalPitch(0.5, Duration.zero);
      addTearDown(SoundManager.debugResetForTest);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<int>(
                context: context,
                builder: (_) => const GameTileChoiceDialog(
                  title: '선택',
                  tiles: [Tile(color: TileColor.red, number: 1)],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(sounds, isEmpty);
      await tester.tap(find.byType(GameRummiTileCard));
      await tester.pump();
      await tester.tap(find.byType(GameRummiTileCard));
      expect(sounds, [(AssetPaths.sfxBtnSnd, 1.0)]);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    },
  );

  testWidgets('tile choice candidates are not pre-highlighted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameTileChoiceDialog(
            title: '덱 확인',
            message: '덱 위 3장 중 버릴 타일을 선택합니다.',
            tiles: [
              Tile(color: TileColor.red, number: 1),
              Tile(color: TileColor.blue, number: 2),
              Tile(color: TileColor.yellow, number: 3),
            ],
          ),
        ),
      ),
    );

    final cards = tester
        .widgetList<GameRummiTileCard>(find.byType(GameRummiTileCard))
        .toList();

    expect(cards, hasLength(3));
    expect(cards.every((card) => card.accent == false), isTrue);
    expect(cards.every((card) => card.selected == false), isTrue);
  });
}
