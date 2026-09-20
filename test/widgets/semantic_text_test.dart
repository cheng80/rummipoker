// Checks the space rule that SemanticText promises: it never needs more lines
// than plain space breaking would, it never breaks inside a word, and it steps
// aside when the text no longer fits.

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
}) async {
  clearSemanticTextCache();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Localizations(
          locale: locale,
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The text the widget actually handed to Flutter.
String _renderedText(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text));
  expect(texts.length, 1);
  return texts.single.data!;
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
      final rendered = _renderedText(tester);
      expect(
        _lineCount(rendered, width),
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
    final rendered = _renderedText(tester);
    expect(rendered, isNot(_sentence), reason: 'expected the widget to apply');
    for (final line in rendered.split('\n')) {
      expect(line.trim(), line, reason: 'line kept surrounding whitespace');
      expect(
        _sentence.contains(line),
        isTrue,
        reason: 'line "$line" is not a run of the original text',
      );
    }
    // Every inserted newline replaced a space, so removing them restores the
    // original sentence.
    expect(rendered.replaceAll('\n', ' '), _sentence);
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
    expect(_renderedText(tester), _sentence);
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
    expect(_renderedText(tester), _sentence);
  });

  testWidgets('renders a plain Text for maxLines: 1 without measuring', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 160,
        child: SemanticText(_sentence, style: _style, maxLines: 1),
      ),
    );
    expect(_renderedText(tester), _sentence);
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
      expect(_renderedText(tester), _sentence, reason: '$locale was rewrapped');
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
        text: TextSpan(text: _renderedText(tester), style: _style),
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
    final wide = _renderedText(tester);
    await _pump(
      tester,
      const SizedBox(width: 130, child: SemanticText(_sentence, style: _style)),
    );
    expect(_renderedText(tester), isNot(wide));
  });
}
