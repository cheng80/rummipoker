import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../utils/semantic_wrap/semantic_wrap.dart';

/// A [Text] that breaks Korean lines at phrase boundaries instead of in the
/// middle of a word.
///
/// Flutter's default line breaking may split a Korean word between two
/// syllables, because Unicode allows a break there. This widget instead asks a
/// small phrase model where the natural boundaries are, and breaks only at
/// spaces.
///
/// It subclasses [Text] on purpose. `data` stays the original string, so
/// `find.text('원문')` and `tester.widget<Text>(...)` keep working after a
/// screen swaps its `Text` for this. Only [build] is different, and the
/// rewrapped string never reaches the widget tree as another [Text].
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
/// 3. If even that layout does not fit the available height or `maxLines`, it
///    renders like a plain [Text] and lets Flutter break the line as before.
///
/// Step 3 is what keeps this widget from pushing text out of a panel that used
/// to hold it. Refusing to split a word can push a whole word onto the next
/// line, and in a panel tuned to the character that is exactly one line too many.
///
/// Other languages fall through to plain [Text] behaviour: English already
/// breaks at spaces, and Japanese and Chinese are expected to break between
/// characters.
///
/// ## Where it must not be used
///
/// Measuring needs the real width, so this widget uses a [LayoutBuilder]. A
/// [LayoutBuilder] asserts in debug builds when an ancestor asks it for an
/// intrinsic size. Keep a plain [Text] under [IntrinsicWidth], [IntrinsicHeight],
/// `AlertDialog` and `SimpleDialog` (Material's dialogs use [IntrinsicWidth]
/// internally), or move the screen onto this project's own `GameModalCard`.
/// `test/widgets/semantic_text_usage_test.dart` checks this per file.
class SemanticText extends Text {
  const SemanticText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    this.phraseModels,
  });

  /// Phrase model per language code. Injectable so another language can be
  /// added later without changing this widget. Null means
  /// [koreanOnlyPhraseModels].
  final Map<String, PhraseModel>? phraseModels;

  @override
  Widget build(BuildContext context) {
    final text = data!;
    final defaults = DefaultTextStyle.of(context);

    // A single line has nothing to break, and softWrap: false means the caller
    // wants one line no matter what, so skip the measuring entirely.
    if ((maxLines ?? defaults.maxLines) == 1 ||
        !(softWrap ?? defaults.softWrap) ||
        text.trim().isEmpty) {
      return super.build(context);
    }
    final uiLocale = locale ?? Localizations.maybeLocaleOf(context);
    final model =
        (phraseModels ?? koreanOnlyPhraseModels)[uiLocale?.languageCode];
    if (model == null || !_hasEnoughSpaces(text)) return super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth < 1) {
          return super.build(context);
        }
        final wrapped = _resolveWrappedText(
          text: text,
          model: model,
          metrics: _TextMetrics.of(context, this),
          // Round the available box down to whole logical pixels. During a size
          // animation the raw value moves by a fraction every frame, which would
          // miss the cache and remeasure on every one of them. Rounding down is
          // the safe direction: a layout that fits a narrower box also fits the
          // real one.
          // ponytail: whole pixels, go finer only if a screen shows visible slack.
          maxWidth: constraints.maxWidth.floorToDouble(),
          maxHeight: constraints.maxHeight.isFinite
              ? constraints.maxHeight.floorToDouble()
              : double.infinity,
        );
        if (wrapped == null) return super.build(context);
        // Build the rewrapped string through a throwaway Text so this widget
        // follows every DefaultTextStyle rule Text follows, then hand back that
        // widget's own output. No second Text reaches the tree, so
        // find.text(원문) still matches exactly one widget: this one.
        return Text(
          wrapped,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          // Screen readers and find.bySemanticsLabel keep seeing one sentence.
          semanticsLabel: semanticsLabel ?? text,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        ).build(context);
      },
    );
  }
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

/// Everything [Text.build] resolves from the surrounding context before it
/// hands the work to `RichText`.
///
/// Measuring has to use the very same values the rendering will use. If the two
/// drift apart, the promise that the text does not grow a line and does not
/// overflow stops holding.
class _TextMetrics {
  const _TextMetrics({
    required this.style,
    required this.strutStyle,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.locale,
    required this.maxLines,
    required this.textWidthBasis,
    required this.textHeightBehavior,
  });

  factory _TextMetrics.of(BuildContext context, Text widget) {
    final defaults = DefaultTextStyle.of(context);
    var effectiveStyle = widget.style;
    if (widget.style == null || widget.style!.inherit) {
      effectiveStyle = defaults.style.merge(widget.style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveStyle = effectiveStyle!.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return _TextMetrics(
      style: effectiveStyle!,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign ?? defaults.textAlign ?? TextAlign.start,
      textDirection: widget.textDirection ?? Directionality.of(context),
      textScaler: widget.textScaler ?? MediaQuery.textScalerOf(context),
      locale: widget.locale ?? Localizations.maybeLocaleOf(context),
      maxLines: widget.maxLines ?? defaults.maxLines,
      textWidthBasis: widget.textWidthBasis ?? defaults.textWidthBasis,
      textHeightBehavior:
          widget.textHeightBehavior ??
          defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
    );
  }

  final TextStyle style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final int? maxLines;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  TextPainter newPainter() => TextPainter(
    textAlign: textAlign,
    textDirection: textDirection,
    textScaler: textScaler,
    strutStyle: strutStyle,
    locale: locale,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
  );
}

/// Everything that can change the answer. The parts are compared by value, not
/// by hash, so a hash collision cannot hand back another style's layout.
typedef _CacheKey = ({
  String text,
  TextStyle style,
  StrutStyle? strutStyle,
  TextAlign textAlign,
  TextDirection textDirection,
  TextScaler textScaler,
  Locale? locale,
  int? maxLines,
  TextWidthBasis textWidthBasis,
  TextHeightBehavior? textHeightBehavior,
  double maxWidth,
  double maxHeight,
});

const int _cacheCapacity = 512;
final LinkedHashMap<_CacheKey, String?> _wrapCache =
    LinkedHashMap<_CacheKey, String?>();

/// Returns the text with newlines inserted, or null to keep Flutter's own
/// line breaking.
String? _resolveWrappedText({
  required String text,
  required PhraseModel model,
  required _TextMetrics metrics,
  required double maxWidth,
  required double maxHeight,
}) {
  final key = (
    text: text,
    style: metrics.style,
    strutStyle: metrics.strutStyle,
    textAlign: metrics.textAlign,
    textDirection: metrics.textDirection,
    textScaler: metrics.textScaler,
    locale: metrics.locale,
    maxLines: metrics.maxLines,
    textWidthBasis: metrics.textWidthBasis,
    textHeightBehavior: metrics.textHeightBehavior,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
  if (_wrapCache.containsKey(key)) {
    // Refresh the entry so the cap evicts the least recently used text.
    final cached = _wrapCache.remove(key);
    _wrapCache[key] = cached;
    return cached;
  }

  final painter = metrics.newPainter();
  String? result;
  try {
    double measure(String segment) {
      painter
        ..text = TextSpan(text: segment, style: metrics.style)
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
        ..text = TextSpan(text: candidate, style: metrics.style)
        ..maxLines = metrics.maxLines
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
