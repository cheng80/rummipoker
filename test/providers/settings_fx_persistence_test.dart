import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/providers/features/settings/settings_notifier.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
  });

  test('effect settings default before anything is saved', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(settingsNotifierProvider);
    expect(state.fxIntensity, FxIntensity.normal);
    expect(state.settlementSpeed, SettlementSpeed.x1);
    expect(state.screenShakeEnabled, isTrue);
    expect(state.hapticsEnabled, isTrue);
  });

  test('effect settings are saved and restored by a new notifier', () {
    final first = ProviderContainer();
    final notifier = first.read(settingsNotifierProvider.notifier);
    notifier.setFxIntensity(FxIntensity.strong);
    notifier.setSettlementSpeed(SettlementSpeed.instant);
    notifier.setScreenShakeEnabled(false);
    notifier.setHapticsEnabled(false);
    first.dispose();

    expect(StorageHelper.readInt(StorageKeys.settlementSpeed), 3);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    final state = second.read(settingsNotifierProvider);
    expect(state.fxIntensity, FxIntensity.strong);
    expect(state.settlementSpeed, SettlementSpeed.instant);
    expect(state.settlementSpeed.multiplier, double.infinity);
    expect(state.screenShakeEnabled, isFalse);
    expect(state.hapticsEnabled, isFalse);
  });

  test('out-of-range saved index falls back to the default', () async {
    await StorageHelper.write(StorageKeys.fxIntensity, 99);
    expect(GameSettings.fxIntensity, FxIntensity.normal);
  });
}
