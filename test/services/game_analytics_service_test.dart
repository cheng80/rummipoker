import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/services/game_analytics_service.dart';

void main() {
  test('normalizes event names and parameters to GA4-safe values', () async {
    final events = <_CapturedEvent>[];
    final service = GameAnalyticsService(
      sink: (name, parameters) async {
        events.add(_CapturedEvent(name, parameters));
      },
    );

    await service.logEvent(
      '1 bad-event-name-that-is-longer-than-forty-characters',
      parameters: {
        'ga_bad-key': 'x' * 120,
        'google_value': 3,
        'firebase_flag': true,
        'ok_name': 'value',
        'object_value': DateTime.utc(2026),
        'null_value': null,
      },
    );

    expect(events, hasLength(1));
    expect(events.single.name, startsWith('x_'));
    expect(events.single.name.length, lessThanOrEqualTo(40));
    expect(events.single.name, matches(RegExp(r'^[A-Za-z][A-Za-z0-9_]*$')));
    expect(
      events.single.parameters.keys,
      everyElement(isNot(startsWith('ga_'))),
    );
    expect(
      events.single.parameters.keys,
      everyElement(isNot(startsWith('google_'))),
    );
    expect(
      events.single.parameters.keys,
      everyElement(isNot(startsWith('firebase_'))),
    );
    expect(
      events.single.parameters.keys,
      everyElement(matches(RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$'))),
    );
    expect(
      events.single.parameters.values.whereType<String>().first.length,
      100,
    );
    expect(events.single.parameters, isNot(contains('null_value')));
  });

  test('caps event parameters at twenty five', () async {
    Map<String, Object>? captured;
    final service = GameAnalyticsService(
      sink: (_, parameters) async {
        captured = parameters;
      },
    );

    await service.logEvent(
      'battle_action',
      parameters: {for (var i = 0; i < 30; i += 1) 'param_$i': i},
    );

    expect(captured, isNotNull);
    expect(captured, hasLength(25));
  });

  test('skips disabled and debug automation contexts', () async {
    var count = 0;
    final service = GameAnalyticsService(
      sink: (_, _) async {
        count += 1;
      },
    );
    const excludedContexts = [
      GameAnalyticsContext(enabled: false),
      GameAnalyticsContext(debugFixture: true),
      GameAnalyticsContext(queryParameters: {'fixture': 'stage2'}),
      GameAnalyticsContext(queryParameters: {'auto_advance_market': '1'}),
      GameAnalyticsContext(queryParameters: {'auto_enter_market': '1'}),
      GameAnalyticsContext(queryParameters: {'auto_cashout_loop': '1'}),
      GameAnalyticsContext(queryParameters: {'debug_shop_tab': 'items'}),
    ];

    for (final context in excludedContexts) {
      await service.logEvent('battle_action', context: context);
    }

    expect(count, 0);
  });

  test('does not throw when sink fails', () async {
    final service = GameAnalyticsService(
      sink: (_, _) async {
        throw StateError('analytics down');
      },
    );

    await expectLater(service.logEvent('run_start'), completes);
  });
}

class _CapturedEvent {
  const _CapturedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}
