// The single translation entry point for screen code.
//
// Every visible string goes through `context.translate('key')` rather than
// easy_localization's own `'key'.tr()`. The difference matters in two places:
//
// 1. Language switching. `'key'.tr()` reads a global singleton and creates no
//    dependency on the widget tree, so a `const` widget that used it keeps its
//    old text when the player changes the language mid-run. Looking the
//    translation up through `Localizations` registers that dependency, so the
//    widget rebuilds.
// 2. Widget tests. Many tests pump a widget under a plain `MaterialApp` with no
//    easy_localization ancestor. easy_localization's own `context.tr()` throws
//    there, because it asserts the lookup succeeded. This one falls back to the
//    global instance, which test/flutter_test_config.dart preloads with Korean.
//
// The fallback branch is a test convenience only. The running app always builds
// its screens under the `EasyLocalization` widget in lib/app.dart, so in a
// release build the `Localizations` lookup always succeeds.

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/widgets.dart';

/// Translation lookups for screen code.
extension AppTranslation on BuildContext {
  /// Returns the translation of [key] for the current locale.
  ///
  /// [args] fills `{}` placeholders left to right, [namedArgs] fills `{name}`
  /// placeholders, and [gender] picks a branch of a gendered entry.
  String translate(
    String key, {
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
  }) {
    final localization = Localizations.of<Localization>(this, Localization);
    return localization == null
        ? key.tr(args: args, namedArgs: namedArgs, gender: gender)
        : localization.tr(
            key,
            args: args,
            namedArgs: namedArgs,
            gender: gender,
          );
  }

  /// Returns the translation of [key] for [value], picking the plural form the
  /// current locale needs.
  ///
  /// Korean has one form, but English distinguishes one from many, so a count
  /// sentence must go through this instead of being assembled from pieces.
  String translatePlural(
    String key,
    num value, {
    List<String>? args,
    Map<String, String>? namedArgs,
    String? name,
    NumberFormat? format,
  }) {
    final localization = Localizations.of<Localization>(this, Localization);
    return localization == null
        ? key.plural(
            value,
            args: args,
            namedArgs: namedArgs,
            name: name,
            format: format,
          )
        : localization.plural(
            key,
            value,
            args: args,
            namedArgs: namedArgs,
            name: name,
            format: format,
          );
  }
}
