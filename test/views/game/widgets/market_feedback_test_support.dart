import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

/// Each test owns its feedback hooks, including tests that replace these sinks.
void setUpMarketFeedback() {
  setUp(() {
    SoundManager.debugSfxSink = (_, _, _) {};
    GameHaptics.debugSink = (_) {};
  });
  tearDown(() {
    SoundManager.debugSfxSink = null;
    GameHaptics.debugSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
  });
}
