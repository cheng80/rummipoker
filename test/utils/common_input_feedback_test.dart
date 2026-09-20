import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/views/game/game_feedback_cues.dart';
import 'package:rummipoker/resources/game_haptics.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/router.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

void main() {
  final sfx = <String>[];
  final haptics = <HapticGrade>[];

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.sfxMuted = false;
    sfx.clear();
    haptics.clear();
    SoundManager.debugSfxSink = (path, _, _) => sfx.add(path);
    GameHaptics.debugSink = haptics.add;
  });

  tearDown(() {
    SoundManager.debugSfxSink = null;
    GameHaptics.debugSink = null;
    MotionPolicy.debugReduceMotionOverride = null;
  });

  Widget pressTarget({VoidCallback? onTap, bool deny = false}) {
    return MaterialApp(
      home: Center(
        child: PressFeedback(
          onTap: onTap,
          deny: deny,
          builder: (context, tap) => GestureDetector(
            key: const ValueKey('press-target'),
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      ),
    );
  }

  // PressFeedback 안의 Transform들(juice, 거절 흔들림) 중 가장 큰 좌우 이동.
  double denyOffsetX(WidgetTester tester) => tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(PressFeedback),
          matching: find.byType(Transform),
        ),
      )
      .map((t) => t.transform.getTranslation().x)
      .reduce((a, b) => a.abs() >= b.abs() ? a : b);

  testWidgets('enabled press runs the action with a select haptic', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(pressTarget(onTap: () => taps++));
    await tester.tap(find.byKey(const ValueKey('press-target')));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(haptics, [HapticGrade.select]);
    expect(sfx, isEmpty);
  });

  testWidgets('disabled deny press shakes with error sound and haptic', (
    tester,
  ) async {
    await tester.pumpWidget(pressTarget(deny: true));
    await tester.tap(find.byKey(const ValueKey('press-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(sfx, [gameFeedbackCues[GameCue.deny]!.sfx]);
    expect(haptics, [HapticGrade.error]);
    expect(denyOffsetX(tester), isNot(0));

    await tester.pumpAndSettle();
    expect(denyOffsetX(tester), 0);
  });

  testWidgets('deny under reduce motion keeps sound but does not move', (
    tester,
  ) async {
    MotionPolicy.debugReduceMotionOverride = true;
    await tester.pumpWidget(pressTarget(deny: true));
    await tester.tap(find.byKey(const ValueKey('press-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(sfx, [gameFeedbackCues[GameCue.deny]!.sfx]);
    expect(denyOffsetX(tester), 0);
  });

  testWidgets('denyTrigger change shakes an enabled target after async check', (
    tester,
  ) async {
    Widget build(int trigger) => MaterialApp(
      home: Center(
        child: PressFeedback(
          onTap: () {},
          denyTrigger: trigger,
          builder: (context, tap) => GestureDetector(
            key: const ValueKey('press-target'),
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      ),
    );
    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 40));

    expect(sfx, [gameFeedbackCues[GameCue.deny]!.sfx]);
    expect(denyOffsetX(tester), isNot(0));
    await tester.pumpAndSettle();
    expect(denyOffsetX(tester), 0);
  });

  testWidgets('disabled press without deny stays silent', (tester) async {
    await tester.pumpWidget(pressTarget());
    await tester.tap(find.byKey(const ValueKey('press-target')));
    await tester.pumpAndSettle();

    expect(sfx, isEmpty);
    expect(haptics, isEmpty);
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showConfirmDialog(context, title: '확인 팝업', message: '본문'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  bool dialogScales(WidgetTester tester) => find
      .ancestor(of: find.text('확인 팝업'), matching: find.byType(ScaleTransition))
      .evaluate()
      .isNotEmpty;

  testWidgets('dialog pops in with scale and settles fully shown', (
    tester,
  ) async {
    await openDialog(tester);
    expect(dialogScales(tester), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsNothing);
  });

  testWidgets('dialog under reduce motion only fades', (tester) async {
    MotionPolicy.debugReduceMotionOverride = true;
    await openDialog(tester);
    expect(dialogScales(tester), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsOneWidget);
  });

  testWidgets('notices play their grade sound unless muted by caller', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    showTopNotice(ctx, 'top');
    showBottomNotice(ctx, 'bottom');
    showTopNotice(ctx, 'silent', cue: null);
    expect(sfx, [gameFeedbackCues[GameCue.noticeTop]!.sfx, gameFeedbackCues[GameCue.noticeBottom]!.sfx]);
    await tester.pump(const Duration(seconds: 3));
  });

  test('debug and auto routes skip the transition', () {
    expect(isInstantRouteTransition(Uri.parse('/title')), isFalse);
    expect(isInstantRouteTransition(Uri.parse('/game?seed=3')), isFalse);
    expect(isInstantRouteTransition(Uri.parse('/game?fixture=x')), isTrue);
    expect(
      isInstantRouteTransition(Uri.parse('/game?auto_cashout_loop=1')),
      isTrue,
    );
    expect(
      isInstantRouteTransition(Uri.parse('/game?debug_shop_tab=items')),
      isTrue,
    );
    MotionPolicy.debugReduceMotionOverride = true;
    expect(isInstantRouteTransition(Uri.parse('/title')), isTrue);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('route transition lands on the same page '
        '(reduceMotion: $reduceMotion)', (tester) async {
      MotionPolicy.debugReduceMotionOverride = reduceMotion;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                appTransitionPage(state: state, child: const Text('first')),
          ),
          GoRoute(
            path: '/next',
            pageBuilder: (context, state) =>
                appTransitionPage(state: state, child: const Text('second')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final midTransition = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('second'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((fade) => fade.opacity.value);
      if (reduceMotion) {
        expect(midTransition.every((opacity) => opacity == 1), isTrue);
      } else {
        expect(midTransition.any((opacity) => opacity < 1), isTrue);
      }
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });
  }
}
