import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/views/game/game_feedback_cues.dart';

void main() {
  test('all cue mappings match approved decisions and protected baseline', () {
    final rows =
        jsonDecode(
              File(
                'test/resources/fixtures/audio_cue_contract.json',
              ).readAsStringSync(),
            )
            as List;
    expect(rows.length, GameCue.values.length);
    for (final row in rows) {
      final cue = GameCue.values.byName(row['cue'] as String);
      final spec = gameFeedbackCues[cue]!;
      if (spec.sfx != null) {
        expect(AssetPaths.sfxAssets, contains(spec.sfx));
        expect(File('assets/audio/${spec.sfx}').existsSync(), isTrue);
      }
      expect(spec.sfx, row['current_asset'], reason: cue.name);
      expect(spec.pitch, row['pitch'], reason: cue.name);
      expect(spec.pitchVariance, row['pitch_variance'], reason: cue.name);
      expect(
        spec.preserveOriginalPitch,
        row['preserve_original_pitch'],
        reason: cue.name,
      );
      expect(spec.haptic?.name, row['haptic'], reason: cue.name);
    }
  });
}
