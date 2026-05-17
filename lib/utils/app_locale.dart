import 'package:flutter/material.dart';

/// Flame 컴포넌트 등 BuildContext 없는 곳에서 locale 접근용.
Locale? appLocaleForInit;

/// 제출 스크린샷/locale 전용 QA처럼 명시적으로 locale을 고정하는 실행에서만 사용한다.
///
/// 일반 앱 진입은 시스템 locale을 따르며, 이 값이 비어 있으면 startLocale을 지정하지 않는다.
Locale? appStartLocaleFromEnvironment() {
  const raw = String.fromEnvironment('START_LOCALE');
  return switch (raw) {
    'ko' => const Locale('ko'),
    'en' => const Locale('en'),
    'ja' => const Locale('ja'),
    'zh-CN' || 'zh_CN' => const Locale('zh', 'CN'),
    'zh-TW' || 'zh_TW' => const Locale('zh', 'TW'),
    _ => null,
  };
}
