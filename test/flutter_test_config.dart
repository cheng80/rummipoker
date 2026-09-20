// Applies to every test under test/ that has no nearer flutter_test_config.dart.
// Flutter picks the closest config only, so a nested config must call
// `applySharedTestSetup` itself; test/views/game/widgets/flutter_test_config.dart
// does.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_translations.dart';

/// Shared setup for every test file in this package.
void applySharedTestSetup() {
  TestWidgetsFlutterBinding.ensureInitialized();
  loadKoreanTestTranslations();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  applySharedTestSetup();
  await testMain();
}
