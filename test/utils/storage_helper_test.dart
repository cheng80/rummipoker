import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageHelper', () {
    setUp(() async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bool_key': true,
        'double_key': 0.75,
        'int_key': 7,
        'string_key': 'hello',
      });
      await StorageHelper.init();
    });

    test('reads cached primitive values from SharedPreferences', () {
      expect(StorageHelper.readBool('bool_key'), isTrue);
      expect(StorageHelper.readDouble('double_key'), 0.75);
      expect(StorageHelper.readInt('int_key'), 7);
      expect(StorageHelper.readString('string_key'), 'hello');
    });

    test('writes and removes supported primitive values', () async {
      await StorageHelper.write('next_bool', false);
      await StorageHelper.write('next_double', 1.5);
      await StorageHelper.write('next_int', 9);
      await StorageHelper.write('next_string', 'world');

      expect(StorageHelper.readBool('next_bool'), isFalse);
      expect(StorageHelper.readDouble('next_double'), 1.5);
      expect(StorageHelper.readInt('next_int'), 9);
      expect(StorageHelper.readString('next_string'), 'world');

      await StorageHelper.remove('next_string');
      expect(StorageHelper.hasData('next_string'), isFalse);
    });
  });
}
