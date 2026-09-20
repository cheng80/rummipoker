import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/archive_seen_service.dart';
import 'package:rummipoker/services/run_unlock_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
  });

  test('키가 없는 기존 사용자는 지금까지 발견한 것을 모두 확인한 것으로 본다', () async {
    final before = RunUnlockState.defaults().copyWith(
      seenMarketJesterIds: const {'egg'},
      boughtItemIds: const {'coin_cache'},
      earnedMemoryCardIds: const {'memory_card_expired_standard_s2'},
    );
    final acknowledged = await ArchiveSeenService.loadOrInitialize(before);
    expect(
      ArchiveSeenService.discoveredIds(before).difference(acknowledged),
      isEmpty,
    );

    // 이후 새로 발견한 항목만 NEW다.
    final after = before.copyWith(
      seenMarketJesterIds: const {'egg', 'popcorn'},
    );
    final reloaded = await ArchiveSeenService.loadOrInitialize(after);
    expect(ArchiveSeenService.discoveredIds(after).difference(reloaded), {
      'jester:popcorn',
    });

    await ArchiveSeenService.acknowledge('jester:popcorn');
    final third = await ArchiveSeenService.loadOrInitialize(after);
    expect(ArchiveSeenService.discoveredIds(after).difference(third), isEmpty);
  });

  test('새 사용자는 빈 집합으로 시작해 이후 발견이 NEW가 된다', () async {
    await ArchiveSeenService.ensureInitialized();
    final state = RunUnlockState.defaults().copyWith(
      boughtJesterIds: const {'supernova'},
    );
    final acknowledged = await ArchiveSeenService.loadOrInitialize(state);
    expect(ArchiveSeenService.discoveredIds(state).difference(acknowledged), {
      'jester:supernova',
    });
  });
}
