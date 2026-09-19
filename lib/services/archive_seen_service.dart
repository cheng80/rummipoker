import '../app_config.dart';
import '../utils/storage_helper.dart';
import 'run_unlock_state_service.dart';

/// Archive의 NEW 표시를 위한 "확인한 발견 항목" 집합.
///
/// 발견 기록([RunUnlockState])은 그대로 두고, 확인 여부만 새 키
/// [StorageKeys.archiveAcknowledgedIdsV1]에 따로 저장한다. 키가 없는 기존
/// 사용자는 지금까지 발견한 것을 모두 확인한 것으로 처리해서, 업데이트 직후
/// 전부 NEW로 뜨지 않게 한다.
class ArchiveSeenService {
  ArchiveSeenService._();

  static String jesterId(String id) => 'jester:$id';
  static String itemId(String id) => 'item:$id';
  static String memoryId(String id) => 'memory:$id';

  /// 현재 기록에서 발견된 모든 항목(접두 포함).
  static Set<String> discoveredIds(RunUnlockState state) => <String>{
    for (final id in {...state.seenMarketJesterIds, ...state.boughtJesterIds})
      jesterId(id),
    for (final id in {...state.seenMarketItemIds, ...state.boughtItemIds})
      itemId(id),
    for (final id in state.earnedMemoryCardIds) memoryId(id),
  };

  /// 확인한 집합을 읽는다. 키가 없으면 [state]의 발견 항목 전체로 만들고 저장한다.
  static Future<Set<String>> loadOrInitialize(RunUnlockState state) async {
    final stored = StorageHelper.read<List<Object?>>(
      StorageKeys.archiveAcknowledgedIdsV1,
    );
    if (stored != null) return stored.whereType<String>().toSet();
    final initial = discoveredIds(state);
    await StorageHelper.write(
      StorageKeys.archiveAcknowledgedIdsV1,
      initial.toList()..sort(),
    );
    return initial;
  }

  /// 앱을 켤 때 한 번 불러, 키가 없는 기존 사용자를 "모두 확인함"으로 맞춘다.
  static Future<void> ensureInitialized() async {
    if (StorageHelper.hasData(StorageKeys.archiveAcknowledgedIdsV1)) return;
    await loadOrInitialize(await RunUnlockStateService.load());
  }

  /// [prefixedId] 한 항목을 확인한 것으로 기록한다.
  static Future<void> acknowledge(String prefixedId) async {
    final current =
        (StorageHelper.read<List<Object?>>(
                  StorageKeys.archiveAcknowledgedIdsV1,
                ) ??
                const <Object?>[])
            .whereType<String>()
            .toSet();
    if (!current.add(prefixedId)) return;
    await StorageHelper.write(
      StorageKeys.archiveAcknowledgedIdsV1,
      current.toList()..sort(),
    );
  }
}
