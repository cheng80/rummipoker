@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/views/game/game_feedback_cues.dart';

/// cue가 가리키는 효과음이 실제로 존재하고 앱이 미리 받아 두는지 확인한다.
/// 매핑만 고치고 파일이나 사전 로드 목록을 빠뜨리면 여기서 걸린다.
void main() {
  const audioRoot = 'assets/audio';

  test('모든 cue의 효과음 파일이 디스크에 있다', () {
    for (final entry in gameFeedbackCues.entries) {
      final file = File('$audioRoot/${entry.value.sfx}');
      expect(file.existsSync(), isTrue, reason: '${entry.key.name}: ${file.path}');
    }
  });

  test('모든 cue의 효과음이 사전 로드 목록에 있다', () {
    final preloaded = SoundManager.debugSfxPaths.toSet();
    for (final entry in gameFeedbackCues.entries) {
      expect(preloaded, contains(entry.value.sfx), reason: entry.key.name);
    }
  });

  test('사전 로드 목록의 효과음 파일이 모두 있다', () {
    for (final path in SoundManager.debugSfxPaths) {
      expect(File('$audioRoot/$path').existsSync(), isTrue, reason: path);
    }
  });

  test('모든 cue의 효과음이 AssetPaths에 선언돼 있다', () {
    // AssetPaths는 const 클래스라 런타임에 목록을 얻을 수 없다. 파일에서 'sfx/...'
    // 문자열만 뽑아 비교한다.
    final source = File('lib/resources/asset_paths.dart').readAsStringSync();
    final declared = RegExp(r"'(sfx/[^']+)'")
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toSet();
    expect(declared, isNotEmpty);
    for (final entry in gameFeedbackCues.entries) {
      expect(declared, contains(entry.value.sfx), reason: entry.key.name);
    }
  });

  test('iOS Safari가 디코딩하지 못하는 형식을 쓰지 않는다', () {
    for (final path in SoundManager.debugSfxPaths) {
      expect(
        path.endsWith('.mp3') || path.endsWith('.wav'),
        isTrue,
        reason: '$path: 웹 Web Audio 경로는 mp3와 wav만 읽는다',
      );
    }
  });
}
