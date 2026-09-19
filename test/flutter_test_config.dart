import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/utils/storage_helper.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await StorageHelper.init();
  SoundManager.debugSfxSink = (_, _, _) {};
  GameHaptics.debugSink = (_) {};
  await testMain();
}
