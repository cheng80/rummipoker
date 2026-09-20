// Loads the Korean translations into easy_localization's global instance so a
// widget test sees real Korean text even when it pumps a widget without an
// `EasyLocalization` ancestor.
//
// test/flutter_test_config.dart calls this once per test file, so individual
// tests need no setup. See docs/core/I18N.md for why the app code reaches the
// translations through `context.translate` rather than the global instance.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';

const _koreanTranslationPath = 'assets/translations/ko.json';

/// Whether [loadKoreanTestTranslations] has already run in this isolate.
bool _loaded = false;

/// Preloads Korean translations for the current test file.
void loadKoreanTestTranslations() {
  if (_loaded) return;
  final entries =
      jsonDecode(File(_koreanTranslationPath).readAsStringSync())
          as Map<String, dynamic>;
  Localization.load(
    const Locale('ko'),
    translations: Translations(entries),
    fallbackTranslations: Translations(entries),
  );
  _loaded = true;
}

/// Reads the actual merged assets without isolate I/O inside testWidgets.
/// RootBundleAssetLoader delegates JSON over 50 KB to compute, which cannot
/// finish while a FakeAsync test directly awaits a locale change.
class TestTranslationAssetLoader extends AssetLoader {
  const TestTranslationAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File('$path/${locale.toLanguageTag()}.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
}
