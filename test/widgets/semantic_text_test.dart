// Checks the space rule that SemanticText promises: it never needs more lines
// than plain space breaking would, it never breaks inside a word, and it steps
// aside when the text no longer fits.
//
// It also checks that swapping a Text for a SemanticText does not break the
// tests of the screen around it. `find.text('원문')` and the accessibility
// label must keep seeing one whole sentence whether or not the widget rewrapped
// it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/utils/semantic_wrap/semantic_wrap.dart';
import 'package:rummipoker/widgets/semantic_text.dart';

const _sentence = '이 설정은 다음 런부터 적용되며 지금 진행 중인 런에는 영향을 주지 않습니다.';
const _shortSentence = '현재 선택으로 확정될 라인과 점수 변화를 확인합니다.';
const _style = TextStyle(fontSize: 14, height: 1.2);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ko'),
  MediaQueryData media = const MediaQueryData(),
  bool clearCache = true,
}) async {
  if (clearCache) clearSemanticTextCache();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: media,
        child: Localizations(
          locale: locale,
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The string the widget actually drew, newlines included.
String _paintedText(WidgetTester tester) {
  final painted = tester.widgetList<RichText>(
    find.descendant(
      of: find.byType(SemanticText),
      matching: find.byType(RichText),
    ),
  );
  expect(painted.length, 1);
  return painted.single.text.toPlainText();
}

/// How many lines Flutter draws for [text] at [width].
int _lineCount(String text, double width, {int? maxLines}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
  )..layout(maxWidth: width);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

/// The fewest lines the text can use when it may break only at spaces.
int _spaceOnlyMinimumLines(String text, double width) {
  final result = selectLineBreaks(
    text: text,
    model: koTitlePhraseModel,
    maxWidth: width,
    measureText: (segment) {
      final painter = TextPainter(
        text: TextSpan(text: segment, style: _style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: double.infinity);
      final measured = painter.width;
      painter.dispose();
      return measured;
    },
  );
  return result.lines.length;
}

void main() {
  group('spacing overrides use the same metrics as Text', () {
    for (final entry in {
      'letter spacing': const MediaQueryData(letterSpacingOverride: 2),
      'word spacing': const MediaQueryData(wordSpacingOverride: 8),
      'line height': const MediaQueryData(lineHeightScaleFactorOverride: 2),
    }.entries) {
      for (final strut in [
        null,
        const StrutStyle(fontSize: 14, height: 1.2, forceStrutHeight: true),
      ]) {
        testWidgets(
          '${entry.key} fits a box that holds plain Text (strut: ${strut != null})',
          (tester) async {
            final width = entry.key == 'line height' ? 160.0 : 120.0;
            // Derive the available height from Text's real output, including the
            // SDK's accessibility overrides, rather than duplicating that logic.
            await _pump(
              tester,
              SizedBox(
                width: width,
                child: Text(_sentence, style: _style, strutStyle: strut),
              ),
              media: entry.value,
            );
            final plain = tester.widget<RichText>(find.byType(RichText));
            double measureHeight(RichText rich) {
              final painter = TextPainter(
                text: rich.text,
                textDirection: TextDirection.ltr,
                textScaler: rich.textScaler,
                strutStyle: rich.strutStyle,
                locale: rich.locale,
                textHeightBehavior: rich.textHeightBehavior,
              )..layout(maxWidth: width);
              final height = painter.height;
              painter.dispose();
              return height;
            }

            final height = measureHeight(plain) + 0.1;
            final box = SizedBox(
              width: width,
              height: height,
              child: SemanticText(_sentence, style: _style, strutStyle: strut),
            );
            // Prime with different metrics, then change only MediaQuery. Neither
            // this transition nor the reverse may reuse the previous layout.
            await _pump(tester, box);
            await _pump(tester, box, media: entry.value, clearCache: false);
            final warm = tester.widget<RichText>(find.byType(RichText));
            final warmText = warm.text.toPlainText(
              includeSemanticsLabels: false,
            );
            expect(measureHeight(warm), lessThanOrEqualTo(height));
            await _pump(tester, box, media: entry.value);
            expect(
              tester
                  .widget<RichText>(find.byType(RichText))
                  .text
                  .toPlainText(includeSemanticsLabels: false),
              warmText,
            );
            await _pump(tester, box, clearCache: false);
            final reversed = tester
                .widget<RichText>(find.byType(RichText))
                .text
                .toPlainText(includeSemanticsLabels: false);
            await _pump(tester, box);
            expect(
              tester
                  .widget<RichText>(find.byType(RichText))
                  .text
                  .toPlainText(includeSemanticsLabels: false),
              reversed,
            );
          },
        );
      }
    }
  });

  testWidgets(
    'model replacement and mutable model inputs do not reuse layouts',
    (tester) async {
      final weights = <String, Map<String, int>>{
        'UW5': {'다': 10},
      };
      final levels = [
        PhraseLevel(name: 'custom', weights: weights, penalty: 0),
      ];
      final model = PhraseModel(levels: levels, fallbackPenalty: 1);
      final other = PhraseModel(
        levels: [
          PhraseLevel(
            name: 'other',
            weights: {
              'UW5': {'지': 10},
            },
            penalty: 0,
          ),
        ],
        fallbackPenalty: 1,
      );
      Future<String> render(PhraseModel value, {bool clear = false}) async {
        await _pump(
          tester,
          SizedBox(
            width: 170,
            child: SemanticText(
              _sentence,
              style: _style,
              phraseModels: {'ko': value},
            ),
          ),
          clearCache: clear,
        );
        return _paintedText(tester);
      }

      final original = await render(model, clear: true);
      final changed = await render(other);
      final fresh = await render(other, clear: true);
      expect(
        fresh,
        isNot(original),
        reason: 'fixture must distinguish the models',
      );
      expect(
        changed,
        fresh,
        reason: 'a different model must not hit the old cache',
      );
      await render(model, clear: true);
      // Keep the total weight fixed so the parser's precomputed base score is
      // unchanged; only the predicted boundary moves.
      weights['UW5'] = {'지': 10};
      expect(
        await render(model),
        fresh,
        reason: 'mutated weights must be measured',
      );
      levels[0] = PhraseLevel(
        name: 'replacement',
        weights: {
          'UW5': {'다': 10},
        },
        penalty: 0,
      );
      expect(
        await render(model),
        original,
        reason: 'mutated levels must be measured',
      );
    },
  );

  testWidgets('does not use more lines than space-only breaking needs', (
    tester,
  ) async {
    for (final width in [120.0, 160.0, 200.0, 260.0]) {
      await _pump(
        tester,
        SizedBox(
          width: width,
          child: const SemanticText(_sentence, style: _style),
        ),
      );
      expect(
        _lineCount(_paintedText(tester), width),
        lessThanOrEqualTo(_spaceOnlyMinimumLines(_sentence, width)),
        reason: 'width $width grew the line count',
      );
    }
  });

  testWidgets('never breaks inside a word when it wraps', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 160, child: SemanticText(_sentence, style: _style)),
    );
    final painted = _paintedText(tester);
    expect(painted, isNot(_sentence), reason: 'expected the widget to apply');
    for (final line in painted.split('\n')) {
      expect(line.trim(), line, reason: 'line kept surrounding whitespace');
      expect(
        _sentence.contains(line),
        isTrue,
        reason: 'line "$line" is not a run of the original text',
      );
    }
    // Every inserted newline replaced a space, so removing them restores the
    // original sentence.
    expect(painted.replaceAll('\n', ' '), _sentence);
  });

  group('screen tests keep finding the whole sentence', () {
    testWidgets('find.text matches once while the text is rewrapped', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 160,
          child: SemanticText(_sentence, style: _style),
        ),
      );
      expect(
        _paintedText(tester),
        contains('\n'),
        reason: 'this case is only meaningful once the widget has rewrapped',
      );
      expect(find.text(_sentence), findsOneWidget);
      expect(tester.widget<Text>(find.text(_sentence)).data, _sentence);
    });

    testWidgets('find.text matches once when the text fits on one line', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 900,
          child: SemanticText(_sentence, style: _style),
        ),
      );
      expect(_paintedText(tester), _sentence);
      expect(find.text(_sentence), findsOneWidget);
    });

    testWidgets('the accessibility label stays the whole sentence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final width in [160.0, 900.0]) {
        await _pump(
          tester,
          SizedBox(
            width: width,
            child: const SemanticText(_sentence, style: _style),
          ),
        );
        expect(
          find.bySemanticsLabel(_sentence),
          findsOneWidget,
          reason: 'width $width lost the sentence for screen readers',
        );
      }
      handle.dispose();
    });
  });

  testWidgets('falls back to Flutter line breaking when maxLines is too low', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 160,
        child: SemanticText(_sentence, style: _style, maxLines: 2),
      ),
    );
    expect(_paintedText(tester), _sentence);
  });

  testWidgets('follows a maxLines that comes from DefaultTextStyle', (
    tester,
  ) async {
    await _pump(
      tester,
      const DefaultTextStyle(
        style: _style,
        maxLines: 2,
        child: SizedBox(width: 160, child: SemanticText(_sentence)),
      ),
    );
    expect(
      _paintedText(tester),
      _sentence,
      reason:
          'an inherited maxLines must block the rewrap just like an '
          'explicit one',
    );
  });

  testWidgets('falls back when the bounded height cannot hold the lines', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 160,
        height: 20,
        child: SemanticText(_sentence, style: _style),
      ),
    );
    expect(_paintedText(tester), _sentence);
  });

  testWidgets('renders like a plain Text for maxLines: 1', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 160,
        child: SemanticText(_sentence, style: _style, maxLines: 1),
      ),
    );
    expect(_paintedText(tester), _sentence);
  });

  testWidgets('keeps Flutter line breaking when softWrap is off', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 160,
        child: SemanticText(_sentence, style: _style, softWrap: false),
      ),
    );
    expect(_paintedText(tester), _sentence);
  });

  testWidgets('keeps Flutter line breaking for non-Korean locales', (
    tester,
  ) async {
    for (final locale in [const Locale('en'), const Locale('ja')]) {
      await _pump(
        tester,
        const SizedBox(
          width: 160,
          child: SemanticText(_sentence, style: _style),
        ),
        locale: locale,
      );
      expect(_paintedText(tester), _sentence, reason: '$locale was rewrapped');
    }
  });

  testWidgets('does not overflow its box', (tester) async {
    for (final width in [120.0, 160.0, 200.0, 260.0]) {
      await _pump(
        tester,
        SizedBox(
          width: width,
          child: const SemanticText(_shortSentence, style: _style),
        ),
      );
      expect(tester.takeException(), isNull);
      final painter = TextPainter(
        text: TextSpan(text: _paintedText(tester), style: _style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      expect(painter.didExceedMaxLines, isFalse);
      for (final line in painter.computeLineMetrics()) {
        expect(line.width, lessThanOrEqualTo(width + 0.01));
      }
      painter.dispose();
    }
  });

  testWidgets('re-measures when the width changes', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 260, child: SemanticText(_sentence, style: _style)),
    );
    final wide = _paintedText(tester);
    await _pump(
      tester,
      const SizedBox(width: 130, child: SemanticText(_sentence, style: _style)),
    );
    expect(_paintedText(tester), isNot(wide));
  });
}
