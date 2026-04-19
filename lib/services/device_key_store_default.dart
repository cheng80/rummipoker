import '../app_config.dart';
import '../utils/storage_helper.dart';
import 'device_key_store.dart';

class _StorageHelperDeviceKeyStore implements DeviceKeyStore {
  @override
  Future<String?> read() async {
    final key = StorageHelper.readString(
      StorageKeys.saveDeviceKeyV1,
      defaultValue: '',
    ).trim();
    return key.isEmpty ? null : key;
  }

  @override
  Future<void> write(String value) {
    return StorageHelper.write(StorageKeys.saveDeviceKeyV1, value);
  }
}

DeviceKeyStore createDeviceKeyStore() => _StorageHelperDeviceKeyStore();
