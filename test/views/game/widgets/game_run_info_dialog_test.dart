import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/widgets/game_run_info_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('run info dialog shows level, count, current and next score', (
    tester,
  ) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showGameRunInfoDialog(
                            context: context,
                            playedHandCounts: const {
                              RummiHandRank.flush: 2,
                              RummiHandRank.fiveOfAKind: 1,
                            },
                          );
                        },
                        child: const Text('open'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('런 정보'), findsOneWidget);
    expect(find.text('기본 덱 52장'), findsOneWidget);
    expect(find.text('타일 기준 칩'), findsOneWidget);
    expect(find.text('1=칩 1'), findsOneWidget);
    expect(find.text('13=칩 13'), findsOneWidget);
    expect(find.text('플러시'), findsOneWidget);
    expect(find.text('파이브 카드'), findsOneWidget);
    expect(find.text('Lv.3'), findsOneWidget);
    expect(find.textContaining('완성 2회'), findsOneWidget);
    expect(find.text('칩 70'), findsWidgets);
    expect(find.text('다음 칩 80'), findsOneWidget);

    await tester.tap(find.byTooltip('게임 용어'));
    await tester.pumpAndSettle();

    expect(find.text('게임 용어'), findsOneWidget);
    expect(find.text('칩'), findsWidgets);
    expect(find.text('점수 +%'), findsOneWidget);
    expect(find.text('점수 xN'), findsOneWidget);
    expect(find.text('골드'), findsOneWidget);

    await tester.tap(find.byTooltip('취소').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('취소'));
    await tester.pumpAndSettle();

    expect(find.text('런 정보'), findsNothing);
  });
}
