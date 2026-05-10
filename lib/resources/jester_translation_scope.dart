import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../logic/rummi_poker_grid/jester_translations.dart';
import 'translation_locale_code.dart';

class JesterTranslationScope extends StatefulWidget {
  const JesterTranslationScope({super.key, required this.child});

  final Widget child;

  static JesterTranslations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_JesterTranslationInheritedWidget>();
    return scope?.translations ?? JesterTranslations.empty();
  }

  @override
  State<JesterTranslationScope> createState() => _JesterTranslationScopeState();
}

class _JesterTranslationScopeState extends State<JesterTranslationScope> {
  JesterTranslations _translations = JesterTranslations.empty();
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.locale;
    if (_locale != loc) {
      _locale = loc;
      _reload(loc);
    }
  }

  Future<void> _reload(Locale loc) async {
    final code = translationLocaleCode(loc);
    final next = await _loadTranslations(code) ??
        (code == 'en' ? null : await _loadTranslations('en'));
    if (mounted) {
      setState(() => _translations = next ?? JesterTranslations.empty());
    }
  }

  Future<JesterTranslations?> _loadTranslations(String code) async {
    final path = 'assets/translations/data/$code/jesters.json';
    try {
      final raw = await rootBundle.loadString(path);
      return JesterTranslations.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _JesterTranslationInheritedWidget(
      translations: _translations,
      child: widget.child,
    );
  }
}

class _JesterTranslationInheritedWidget extends InheritedWidget {
  const _JesterTranslationInheritedWidget({
    required super.child,
    required this.translations,
  });

  final JesterTranslations translations;

  @override
  bool updateShouldNotify(_JesterTranslationInheritedWidget oldWidget) {
    return translations != oldWidget.translations;
  }
}
