// Porting fidelity check for lib/utils/semantic_wrap/.
//
// The reference data in test/fixtures/semantic_wrap_breaks.json comes from
// running the original JavaScript library. Regenerate it with:
//   node tools/semantic_wrap/generate_semantic_wrap_fixture.mjs --lib <node_modules dir>
//
// Widths are measured per UTF-16 code unit so the comparison does not depend on
// a font. The JavaScript generator measures the same way.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/utils/semantic_wrap/semantic_wrap.dart';

void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/semantic_wrap_breaks.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final charWidth = (fixture['charWidth'] as num).toDouble();
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  double measure(String text) => text.length * charWidth;

  test('fixture covers at least 30 sentences across 3 widths each', () {
    final sentences = cases.map((entry) => entry['text'] as String).toSet();
    expect(sentences.length, greaterThanOrEqualTo(30));
    expect(cases.length, sentences.length * 3);
  });

  group('matches the JavaScript reference', () {
    for (final (index, entry) in cases.indexed) {
      final text = entry['text'] as String;
      final maxWidth = (entry['maxWidth'] as num).toDouble();
      test('case $index: "$text" at $maxWidth', () {
        final result = selectLineBreaks(
          text: text,
          model: koTitlePhraseModel,
          maxWidth: maxWidth,
          measureText: measure,
        );
        expect(
          result.breaks,
          (entry['breaks'] as List).cast<int>(),
          reason: 'break offsets differ',
        );
        expect(
          result.lines,
          (entry['lines'] as List).cast<String>(),
          reason: 'lines differ',
        );
        expect(result.applied, entry['applied'] as bool);
        expect(result.overflow, entry['overflow'] as bool);
      });
    }
  });

  test('never breaks inside a word', () {
    for (final entry in cases) {
      final text = entry['text'] as String;
      final result = selectLineBreaks(
        text: text,
        model: koTitlePhraseModel,
        maxWidth: (entry['maxWidth'] as num).toDouble(),
        measureText: measure,
      );
      for (final offset in result.breaks) {
        expect(
          spaceOffsets(text),
          contains(offset),
          reason: 'break at $offset in "$text" is not a space boundary',
        );
      }
    }
  });
}
