import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_catalog_loader.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_notifier.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/new_run_setup.dart';

/// 전투 화면은 들어갈 때마다 거의 언제나 새 [GameSessionArgs]로 세션 provider를
/// 만든다. family 구성원이 autoDispose되지 않으면 그 구성원이 컨테이너에 남아
/// 세션 state와 Jester catalog를 계속 붙잡는다. 웹에서 이 누적이 heap 증가로
/// 나타났으므로, 구독이 끝난 구성원이 실제로 사라지는지 여기서 지킨다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('같은 seed의 새 복원 객체는 이전 구독만 해제하고 현재 세션을 유지한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const seed = 4242;
    for (var i = 0; i < 20; i++) {
      final runtime = buildInitialRunRuntime(
        const GameSessionArgs(runSeed: seed),
      );
      final args = GameSessionArgs(runSeed: seed, restoredRun: runtime);
      final provider = gameSessionNotifierProvider(args);
      final first = container.listen(provider, (_, _) {});
      final second = container.listen(provider, (_, _) {});
      final notifier = container.read(provider.notifier);
      final catalog = await RummiJesterCatalogLoader.loadFromAsset(
        AssetPaths.jestersCommon,
      );
      notifier.setJesterCatalog(catalog);

      first.close();
      await container.pump();
      expect(identical(container.read(provider.notifier), notifier), isTrue);
      expect(identical(second.read().jesterCatalog, catalog), isTrue);
      expect(identical(second.read().session, runtime.session), isTrue);

      second.close();
      await container.pump();
      expect(container.exists(provider), isFalse);
      expect(
        container.getAllProviderElements().where(
          (element) => element.origin.from == gameSessionNotifierProvider,
        ),
        isEmpty,
      );
    }
  });

  test('이탈 전에 확보한 저장 runtime은 provider 해제 뒤에도 복원할 수 있다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const args = GameSessionArgs(runSeed: 4242);
    final provider = gameSessionNotifierProvider(args);
    final subscription = container.listen(provider, (_, _) {});
    final notifier = container.read(provider.notifier);
    notifier.adjustDebugGold(17);
    final runtime = notifier.buildSaveRuntimeState(
      difficulty: NewRunDifficulty.standard,
    );
    final gold = runtime.runProgress.gold;
    subscription.close();
    await container.pump();
    expect(container.exists(provider), isFalse);

    final restored = await ActiveRunSaveService.runtimeStateFromJson(
      ActiveRunSaveService.runtimeStateToJson(runtime),
    );
    expect(restored.session.runSeed, args.runSeed);
    expect(restored.runProgress.gold, gold);
    expect(restored.activeScene, runtime.activeScene);
    expect(
      restored.stageStartSnapshot.runProgress.gold,
      runtime.stageStartSnapshot.runProgress.gold,
    );
    expect(
      restored.stakeStartSnapshot.runProgress.gold,
      runtime.stakeStartSnapshot.runProgress.gold,
    );
  });

  test('구독이 끝난 세션 provider 구성원은 컨테이너에 남지 않는다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (var i = 0; i < 20; i += 1) {
      final args = GameSessionArgs(runSeed: 1000 + i);
      final subscription = container.listen(
        gameSessionNotifierProvider(args),
        (_, _) {},
      );
      expect(subscription.read().session, isNotNull);
      subscription.close();
      // autoDispose는 현재 tick이 끝난 뒤에 정리한다.
      await Future<void>.delayed(Duration.zero);
    }

    final remaining = container
        .getAllProviderElements()
        .where((element) => element.origin.from == gameSessionNotifierProvider)
        .length;
    expect(remaining, 0);
  });

  testWidgets('initState의 ref.read는 첫 build의 ref.watch 전에 상태를 잃지 않는다', (
    tester,
  ) async {
    // 초기화에서 notifier를 ref.read로 잡고 같은 프레임의 build에서
    // ref.watch로 구독하는 경계를 확인한다. 그 사이에 구성원을 버리면 initState에서
    // 만든 상태가 사라진다. 이 테스트가 그 순서를 지킨다.
    await tester.pumpWidget(
      const ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _ReadThenWatchProbe(),
        ),
      ),
    );

    final probe =
        tester.state(find.byType(_ReadThenWatchProbe))
            as _ReadThenWatchProbeState;
    expect(probe.notifierInInitState, isNotNull);
    expect(
      identical(probe.notifierInBuild, probe.notifierInInitState),
      isTrue,
      reason: 'initState와 build가 같은 notifier를 봐야 한다',
    );
    expect(
      identical(probe.stateInBuild, probe.stateInInitState),
      isTrue,
      reason: 'initState에서 읽은 state 객체가 첫 build까지 그대로 남아야 한다',
    );

    await tester.pump();
    expect(
      identical(probe.stateInBuild, probe.stateInInitState),
      isTrue,
      reason: '다음 프레임에도 구성원이 버려지지 않아야 한다',
    );
  });
}

/// initState에서 세션 provider를 읽은 뒤, build에서 같은
/// provider를 구독하는 최소 위젯. 초기 읽기와 구독 사이의 수명을 확인한다.
class _ReadThenWatchProbe extends ConsumerStatefulWidget {
  const _ReadThenWatchProbe();

  @override
  ConsumerState<_ReadThenWatchProbe> createState() =>
      _ReadThenWatchProbeState();
}

class _ReadThenWatchProbeState extends ConsumerState<_ReadThenWatchProbe> {
  static const _args = GameSessionArgs(runSeed: 4242);

  GameSessionNotifier? notifierInInitState;
  GameSessionNotifier? notifierInBuild;
  GameSessionState? stateInInitState;
  GameSessionState? stateInBuild;

  @override
  void initState() {
    super.initState();
    notifierInInitState = ref.read(gameSessionNotifierProvider(_args).notifier);
    stateInInitState = ref.read(gameSessionNotifierProvider(_args));
  }

  @override
  Widget build(BuildContext context) {
    stateInBuild = ref.watch(gameSessionNotifierProvider(_args));
    notifierInBuild = ref.read(gameSessionNotifierProvider(_args).notifier);
    return const SizedBox.shrink();
  }
}
