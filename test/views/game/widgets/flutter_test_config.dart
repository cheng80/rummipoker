import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/utils/storage_helper.dart';

import '../../../flutter_test_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  applySharedTestSetup();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await StorageHelper.init();
  await testMain();
}
