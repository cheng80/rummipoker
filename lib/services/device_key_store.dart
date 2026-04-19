import 'device_key_store_default.dart'
    if (dart.library.io) 'device_key_store_native.dart'
    as impl;

abstract class DeviceKeyStore {
  Future<String?> read();
  Future<void> write(String value);
}

DeviceKeyStore? _deviceKeyStoreOverride;

DeviceKeyStore createDeviceKeyStore() => impl.createDeviceKeyStore();

DeviceKeyStore getDeviceKeyStore() =>
    _deviceKeyStoreOverride ?? createDeviceKeyStore();

void overrideDeviceKeyStoreForTest(DeviceKeyStore? store) {
  _deviceKeyStoreOverride = store;
}
