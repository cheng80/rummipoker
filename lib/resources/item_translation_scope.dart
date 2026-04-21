import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../logic/rummi_poker_grid/item_translations.dart';

class ItemTranslationScope extends StatefulWidget {
  const ItemTranslationScope({super.key, required this.child});

  final Widget child;

  static ItemTranslations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ItemTranslationInheritedWidget>();
    return scope?.translations ?? ItemTranslations.empty();
  }

  @override
  State<ItemTranslationScope> createState() => _ItemTranslationScopeState();
}

class _ItemTranslationScopeState extends State<ItemTranslationScope> {
  ItemTranslations _translations = ItemTranslations.empty();
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
    final code = loc.languageCode == 'ko' ? 'ko' : 'en';
    final path = 'assets/translations/data/$code/items.json';
    try {
      final raw = await rootBundle.loadString(path);
      final next = ItemTranslations.fromJsonString(raw);
      if (mounted) {
        setState(() => _translations = next);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _translations = ItemTranslations.empty());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ItemTranslationInheritedWidget(
      translations: _translations,
      child: widget.child,
    );
  }
}

class _ItemTranslationInheritedWidget extends InheritedWidget {
  const _ItemTranslationInheritedWidget({
    required super.child,
    required this.translations,
  });

  final ItemTranslations translations;

  @override
  bool updateShouldNotify(_ItemTranslationInheritedWidget oldWidget) {
    return translations != oldWidget.translations;
  }
}
