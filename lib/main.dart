import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'resources/sound_manager.dart';
import 'services/in_app_review_service.dart';
import 'utils/app_locale.dart';
import 'utils/storage_helper.dart';

/// 앱 진입점.
/// main()은 초기화와 실행만 담당하고, 앱 설정(테마, 라우팅)은 App 위젯에 위임한다.
/// Wakelock 적용은 App → SettingsNotifier.applyInitialWakelock()에서 처리.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  await EasyLocalization.ensureInitialized();
  await StorageHelper.init();
  await InAppReviewService.saveFirstLaunchDateIfNeeded();
  await SoundManager.preload();
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
          Locale('ja'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        startLocale: appStartLocaleFromEnvironment(),
        saveLocale: false,
        child: const App(),
      ),
    ),
  );
}
