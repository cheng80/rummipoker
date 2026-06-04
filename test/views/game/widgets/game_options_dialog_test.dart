import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/views/game/widgets/game_options_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    GameSettings.bgmMuted = true;
    GameSettings.sfxMuted = true;
  });

  testWidgets('Game options dialog stays open when dim barrier is tapped', (
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
                          showGameOptionsDialog(
                            context: context,
                            runSeed: 123,
                            onRestartRun: () async => false,
                            onExitToTitle: () async => false,
                            isDebugFixtureRun: false,
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

    expect(find.text('옵션'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('튜토리얼 다시 보기'), findsOneWidget);
    expect(find.text('전투 기본 조작 안내를 다시 봅니다.'), findsOneWidget);
    expect(find.text('북마크하기'), findsOneWidget);
    expect(find.text('북마크 불러오기'), findsOneWidget);
    expect(find.text('현재 전투 재시작'), findsOneWidget);
    expect(find.text('현재 Station 재시작'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('옵션'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('옵션'), findsNothing);
  });
}
