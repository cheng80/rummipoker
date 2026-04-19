import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_config.dart';
import 'device_key_store.dart';

class _SecureDeviceKeyStore implements DeviceKeyStore {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  Future<String?> read() {
    return _secureStorage.read(key: StorageKeys.saveDeviceKeyV1);
  }

  @override
  Future<void> write(String value) {
    return _secureStorage.write(key: StorageKeys.saveDeviceKeyV1, value: value);
  }
}

DeviceKeyStore createDeviceKeyStore() => _SecureDeviceKeyStore();
