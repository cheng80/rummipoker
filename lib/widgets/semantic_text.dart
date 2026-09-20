import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../utils/semantic_wrap/semantic_wrap.dart';

/// A drop-in replacement for [Text] that breaks Korean lines at phrase
/// boundaries instead of in the middle of a word.
///
/// Flutter's default line breaking may split a Korean word between two
/// syllables, because Unicode allows a break there. This widget instead asks a
/// small phrase model where the natural boundaries are, and breaks only at
/// spaces.
///
/// ## The rule it follows
///
/// Game panels have a fixed height, so "at most N lines" is not something the
/// text itself can decide. The widget therefore works from the space it is
/// actually given:
///
/// 1. It finds the fewest lines the text needs at this width when it may break
///    only at spaces.
/// 2. Among the layouts that use exactly that many lines, it picks the one with
///    the most natural break positions. It never trades a line for a nicer
///    break.
/// 3. If even that layout does not fit the available height or [maxLines], it
///    renders a plain [Text] and lets Flutter break the line as before.
///
/// Step 3 is what keeps this widget from pushing text out of a panel that used
/// to hold it. Refusing to split a word can push a whole word onto the next
/// line, and in a panel tuned to the character is exactly one line too many.
///
/// Other languages fall through to a plain [Text]: English already breaks at
/// spaces, and Japanese and Chinese are expected to break between characters.
class SemanticText extends StatelessWidget {
  const SemanticText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
    this.phraseModels,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextScaler? textScaler;
  final String? semanticsLabel;

  /// Phrase model per language code. Injectable so another language can be
  /// added later without changing this widget. Null means [koreanOnlyPhraseModels].
  final Map<String, PhraseModel>? phraseModels;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    final effectiveMaxLines = maxLines ?? defaultTextStyle.maxLines;
    // A single line has nothing to break, so skip the measuring entirely.
    if (effectiveMaxLines == 1 || data.trim().isEmpty) return _plain(data);

    final locale = Localizations.maybeLocaleOf(context);
    final models = phraseModels ?? koreanOnlyPhraseModels;
    final model = models[locale?.languageCode];
    if (model == null) return _plain(data);
    if (!_hasEnoughSpaces(data)) return _plain(data);

    final effectiveStyle = style?.inherit ?? true
        ? defaultTextStyle.style.merge(style)
        : style!;
    final effectiveScaler = textScaler ?? MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth <= 0) {
          return _plain(data);
        }
        final wrapped = _resolveWrappedText(
          text: data,
          model: model,
          style: effectiveStyle,
          strutStyle: strutStyle,
          textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
          textDirection: Directionality.of(context),
          textScaler: effectiveScaler,
          locale: locale,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          maxLines: effectiveMaxLines,
        );
        return _plain(wrapped ?? data);
      },
    );
  }

  Widget _plain(String text) => Text(
    text,
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    textScaler: textScaler,
    semanticsLabel: semanticsLabel ?? (text == data ? null : data),
  );
}

/// The only model shipped today. Korean uses the phrase model; every other
/// language keeps Flutter's own line breaking.
final Map<String, PhraseModel> koreanOnlyPhraseModels = Map.unmodifiable({
  'ko': koTitlePhraseModel,
});

/// The layout search measures every segment between two break opportunities,
/// so its cost grows with the square of the number of spaces. Long paragraphs
/// are not what this widget is for, so they keep Flutter's line breaking.
// ponytail: fixed cap, raise it only if a real screen needs longer text.
const int _maxSpaceBoundaries = 24;

bool _hasEnoughSpaces(String text) {
  final spaces = spaceOffsets(text);
  return spaces.isNotEmpty && spaces.length <= _maxSpaceBoundaries;
}

/// Results are keyed by everything that can change the answer, so a cache hit
/// is always safe to reuse.
const int _cacheCapacity = 512;
final LinkedHashMap<String, String?> _wrapCache =
    LinkedHashMap<String, String?>();

/// Returns the text with newlines inserted, or null to keep Flutter's own
/// line breaking.
String? _resolveWrappedText({
  required String text,
  required PhraseModel model,
  required TextStyle style,
  required StrutStyle? strutStyle,
  required TextAlign textAlign,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale? locale,
  required double maxWidth,
  required double maxHeight,
  required int? maxLines,
}) {
  final key = [
    text,
    style.hashCode,
    strutStyle?.hashCode ?? 0,
    textAlign.index,
    textDirection.index,
    textScaler.hashCode,
    locale?.toString() ?? '',
    maxWidth,
    maxHeight,
    maxLines ?? -1,
  ].join('\u0000');
  if (_wrapCache.containsKey(key)) {
    // Refresh the entry so the cap evicts the least recently used text.
    final cached = _wrapCache.remove(key);
    _wrapCache[key] = cached;
    return cached;
  }

  final painter = TextPainter(
    textDirection: textDirection,
    textAlign: textAlign,
    textScaler: textScaler,
    strutStyle: strutStyle,
    locale: locale,
  );
  String? result;
  try {
    double measure(String segment) {
      painter
        ..text = TextSpan(text: segment, style: style)
        ..maxLines = null
        ..layout(maxWidth: double.infinity);
      return painter.width;
    }

    final selection = selectLineBreaks(
      text: text,
      model: model,
      maxWidth: maxWidth,
      measureText: measure,
    );
    if (selection.applied) {
      final candidate = selection.lines.join('\n');
      painter
        ..text = TextSpan(text: candidate, style: style)
        ..maxLines = maxLines
        ..layout(maxWidth: maxWidth);
      final fits =
          !painter.didExceedMaxLines &&
          (!maxHeight.isFinite || painter.height <= maxHeight + 0.01);
      if (fits) result = candidate;
    }
  } finally {
    painter.dispose();
  }

  _wrapCache[key] = result;
  if (_wrapCache.length > _cacheCapacity) {
    _wrapCache.remove(_wrapCache.keys.first);
  }
  return result;
}

/// Clears the layout cache. Tests use it to keep cases independent.
@visibleForTesting
void clearSemanticTextCache() => _wrapCache.clear();
