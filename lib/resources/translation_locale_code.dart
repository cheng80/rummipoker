import 'package:flutter/widgets.dart';

/// 번역 자산 폴더 이름을 EasyLocalization Locale에서 일관되게 만든다.
String translationLocaleCode(Locale locale) {
  final country = locale.countryCode?.toUpperCase();
  if (locale.languageCode == 'zh' && country == 'CN') return 'zh-CN';
  if (locale.languageCode == 'zh' && country == 'TW') return 'zh-TW';
  if (locale.languageCode == 'ko') return 'ko';
  if (locale.languageCode == 'ja') return 'ja';
  return 'en';
}
