import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/services/game_analytics_service.dart';
import 'package:rummipoker/services/tutorial_state_service.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameAnalyticsService.debugResetForTest();
  });

  tearDown(GameAnalyticsService.debugResetForTest);

  test('logs tutorial complete and stores outcome', () async {
    final events = <_CapturedEvent>[];
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          events.add(_CapturedEvent(name, parameters));
        },
      ),
    );

    await TutorialStateService.markBattleIntroSeen();
    await _flushUnawaitedAnalytics();

    expect(TutorialStateService.battleIntroSeen, isTrue);
    expect(
      StorageHelper.readString(StorageKeys.tutorialBattleIntroOutcome),
      TutorialStateService.completeOutcome,
    );
    expect(events.single.name, 'tutorial_complete');
    expect(events.single.parameters['tutorial_id'], 'battle_intro');
    expect(events.single.parameters['outcome'], 'complete');
  });

  test('logs tutorial skip and stores outcome', () async {
    final events = <_CapturedEvent>[];
    GameAnalyticsService.debugSetInstanceForTest(
      GameAnalyticsService(
        sink: (name, parameters) async {
          events.add(_CapturedEvent(name, parameters));
        },
      ),
    );

    await TutorialStateService.markMarketIntroSeen(
      outcome: TutorialStateService.skipOutcome,
    );
    await _flushUnawaitedAnalytics();

    expect(TutorialStateService.marketIntroSeen, isTrue);
    expect(
      StorageHelper.readString(StorageKeys.tutorialMarketIntroOutcome),
      TutorialStateService.skipOutcome,
    );
    expect(events.single.name, 'tutorial_skip');
    expect(events.single.parameters['tutorial_id'], 'market_intro');
    expect(events.single.parameters['outcome'], 'skip');
  });

  test(
    'logs legacy already seen when old bool exists without outcome',
    () async {
      final events = <_CapturedEvent>[];
      await StorageHelper.write(StorageKeys.tutorialBattleIntroSeen, true);
      GameAnalyticsService.debugSetInstanceForTest(
        GameAnalyticsService(
          sink: (name, parameters) async {
            events.add(_CapturedEvent(name, parameters));
          },
        ),
      );

      TutorialStateService.logBattleIntroAlreadySeen();
      await _flushUnawaitedAnalytics();

      expect(events.single.name, 'tutorial_already_seen');
      expect(events.single.parameters['tutorial_id'], 'battle_intro');
      expect(events.single.parameters['outcome'], 'legacy_seen');
    },
  );
}

Future<void> _flushUnawaitedAnalytics() async {
  await Future<void>.delayed(Duration.zero);
}

class _CapturedEvent {
  const _CapturedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}
