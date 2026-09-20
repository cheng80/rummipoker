// A Dart port of the line-breaking core of semantic-wrap, version 0.4.0.
// https://github.com/woohyun-park/semantic-wrap
// Copyright 2026 Woohyun Park. Licensed under the Apache License, Version 2.0.
//
// The BudouX inference in `BudouxParser` is itself adapted from the BudouX
// Parser, Copyright 2021 Google LLC, Apache License 2.0.
// https://github.com/google/budoux
//
// Full license and notice texts: third_party/semantic_wrap/.
//
// What this port keeps, and what it drops, is described in docs/core/I18N.md.
// In short: the space-boundary path that the Korean preset uses is ported
// faithfully, and the paths that preset never reaches are not.

import 'dart:math' as math;

import 'ko_title_model.dart';

const double _epsilon = 1e-9;

final RegExp _whitespace = RegExp(r'\s');

bool _isWhitespaceAt(String text, int offset) {
  if (offset < 0 || offset >= text.length) return false;
  return _whitespace.hasMatch(text[offset]);
}

/// `String.prototype.substring` semantics: out-of-range indices are clamped
/// instead of throwing, which the BudouX feature extraction below relies on.
String _slice(String text, int start, int end) {
  final from = start.clamp(0, text.length);
  final to = end.clamp(0, text.length);
  return from >= to ? '' : text.substring(from, to);
}

/// Minimal, dependency-free inference for BudouX JSON models.
class BudouxParser {
  BudouxParser(this.model)
    : _baseScore =
          -0.5 *
          model.values
              .expand((group) => group.values)
              .fold<int>(0, (sum, value) => sum + value);

  final Map<String, Map<String, int>> model;
  final double _baseScore;

  int _score(String group, String feature) =>
      feature.isEmpty ? 0 : (model[group]?[feature] ?? 0);

  /// Returns the ascending UTF-16 offsets the model predicts as boundaries.
  List<int> parseBoundaries(String sentence) {
    final result = <int>[];
    for (var offset = 1; offset < sentence.length; offset += 1) {
      var total = _baseScore;
      total += _score('UW1', _slice(sentence, offset - 3, offset - 2));
      total += _score('UW2', _slice(sentence, offset - 2, offset - 1));
      total += _score('UW3', _slice(sentence, offset - 1, offset));
      total += _score('UW4', _slice(sentence, offset, offset + 1));
      total += _score('UW5', _slice(sentence, offset + 1, offset + 2));
      total += _score('UW6', _slice(sentence, offset + 2, offset + 3));
      total += _score('BW1', _slice(sentence, offset - 2, offset));
      total += _score('BW2', _slice(sentence, offset - 1, offset + 1));
      total += _score('BW3', _slice(sentence, offset, offset + 2));
      total += _score('TW1', _slice(sentence, offset - 3, offset));
      total += _score('TW2', _slice(sentence, offset - 2, offset + 1));
      total += _score('TW3', _slice(sentence, offset - 1, offset + 2));
      total += _score('TW4', _slice(sentence, offset, offset + 3));
      if (total > 0) result.add(offset);
    }
    return result;
  }
}

/// One level of a phrase model. Lower [penalty] means a more natural break.
class PhraseLevel {
  PhraseLevel({
    required this.name,
    required Map<String, Map<String, int>> weights,
    required this.penalty,
  }) : _parser = BudouxParser(weights);

  final String name;
  final double penalty;
  final BudouxParser _parser;

  List<int> predict(String text) => _parser.parseBoundaries(text);
}

/// A stack of levels plus the penalty for a space no level predicted.
///
/// Only the `spaces` boundary mode is ported. The Korean preset uses it, and
/// the `characters` mode needs grapheme segmentation this port does not have.
class PhraseModel {
  const PhraseModel({required this.levels, required this.fallbackPenalty});

  final List<PhraseLevel> levels;
  final double fallbackPenalty;
}

/// A break opportunity with the cost of using it.
class BreakCandidate {
  const BreakCandidate({
    required this.offset,
    required this.level,
    required this.penalty,
  });

  final int offset;

  /// Index of the level that predicted this boundary, or null for a space no
  /// level predicted.
  final int? level;
  final double penalty;
}

/// The result of laying a text out at a chosen set of break offsets.
class SemanticWrapLayout {
  const SemanticWrapLayout({
    required this.breaks,
    required this.lines,
    required this.widths,
    required this.lineCount,
    required this.balanceScore,
    required this.modelCost,
    required this.overflow,
  });

  final List<int> breaks;
  final List<String> lines;
  final List<double> widths;
  final int lineCount;

  /// Root mean square deviation of the line widths from the ideal width,
  /// normalised by the available width. Lower is more even.
  final double balanceScore;

  /// Sum of the penalties of the breaks used. Lower is more natural.
  final double modelCost;
  final bool overflow;
}

/// What [selectLineBreaks] decided.
class SemanticWrapResult {
  const SemanticWrapResult({
    required this.lines,
    required this.breaks,
    required this.applied,
    required this.overflow,
    required this.reason,
  });

  final List<String> lines;
  final List<int> breaks;

  /// True when the caller should render [lines] instead of the original text.
  final bool applied;
  final bool overflow;
  final String reason;
}

/// Offsets where a whitespace run starts, excluding leading and trailing runs.
List<int> spaceOffsets(String text) {
  final result = <int>[];
  var offset = 0;
  while (offset < text.length) {
    if (!_isWhitespaceAt(text, offset)) {
      offset += 1;
      continue;
    }
    final runStart = offset;
    while (offset < text.length && _isWhitespaceAt(text, offset)) {
      offset += 1;
    }
    if (runStart > 0 && offset < text.length) result.add(runStart);
  }
  return result;
}

int _nextTextOffset(String text, int breakOffset) {
  var offset = breakOffset;
  while (offset < text.length && _isWhitespaceAt(text, offset)) {
    offset += 1;
  }
  return offset;
}

/// Splits [text] into lines, dropping the whitespace run at each break.
List<String> splitAtOffsets(String text, List<int> offsets) {
  if (text.isEmpty) return const <String>[];
  final lines = <String>[];
  var start = 0;
  for (final offset in offsets) {
    lines.add(text.substring(start, offset));
    start = _nextTextOffset(text, offset);
  }
  lines.add(text.substring(start));
  return lines;
}

class _Prediction {
  const _Prediction(this.offset, this.level, this.penalty);

  final int offset;
  final int level;
  final double penalty;
}

/// Runs every model level and keeps each level's predictions separately.
List<_Prediction> _predictBreaks(
  String text,
  PhraseModel model,
  Set<int> allowed,
) {
  final predictions = <_Prediction>[];
  for (var levelIndex = 0; levelIndex < model.levels.length; levelIndex += 1) {
    final level = model.levels[levelIndex];
    final seen = <int>{};
    for (final offset in level.predict(text)) {
      if (!allowed.contains(offset)) continue;
      seen.add(offset);
    }
    for (final offset in seen) {
      predictions.add(_Prediction(offset, levelIndex, level.penalty));
    }
  }
  predictions.sort(
    (left, right) => left.offset == right.offset
        ? left.penalty.compareTo(right.penalty)
        : left.offset.compareTo(right.offset),
  );
  return predictions;
}

/// Keeps the lowest-penalty prediction at each allowed boundary.
List<BreakCandidate> _aggregateLowestPenalty(
  List<int> allowedOffsets,
  List<_Prediction> predictions,
  double fallbackPenalty,
) {
  final best = <int, _Prediction>{};
  for (final prediction in predictions) {
    final current = best[prediction.offset];
    if (current == null || prediction.penalty < current.penalty) {
      best[prediction.offset] = prediction;
    }
  }
  return [
    for (final offset in allowedOffsets)
      if (best[offset] case final _Prediction prediction)
        BreakCandidate(
          offset: offset,
          level: prediction.level,
          penalty: prediction.penalty,
        )
      else
        BreakCandidate(offset: offset, level: null, penalty: fallbackPenalty),
  ];
}

class _LayoutContext {
  _LayoutContext({
    required this.text,
    required this.candidates,
    required this.maxWidth,
    required this.measureText,
  });

  final String text;
  final List<BreakCandidate> candidates;
  final double maxWidth;
  final double Function(String) measureText;
}

/// The width every line would have if the text were divided evenly.
double _idealWidth(_LayoutContext context, int lineCount) {
  if (lineCount == 0) return 0;
  final breakCount = math.max(0, lineCount - 1);
  final spacesRemovedAtBreaks = context.candidates.every(
    (candidate) => _isWhitespaceAt(context.text, candidate.offset),
  );
  final removedWhitespaceWidth = spacesRemovedAtBreaks && breakCount > 0
      ? math.max(0.0, context.measureText(' ')) * breakCount
      : 0.0;
  return math.min(
    context.maxWidth,
    math.max(
      0.0,
      (context.measureText(context.text) - removedWhitespaceWidth) / lineCount,
    ),
  );
}

SemanticWrapLayout _layoutAtBreaks(
  _LayoutContext context,
  List<int> breakOffsets,
) {
  final lines = splitAtOffsets(context.text, breakOffsets);
  final widths = lines.map(context.measureText).toList(growable: false);
  final byOffset = {
    for (final candidate in context.candidates) candidate.offset: candidate,
  };
  final unmatchedPenalty = context.candidates.isEmpty
      ? 0.0
      : context.candidates
            .map((candidate) => candidate.penalty)
            .reduce(math.max);
  final breaks = [
    for (final offset in breakOffsets)
      byOffset[offset] ??
          BreakCandidate(
            offset: offset,
            level: null,
            penalty: unmatchedPenalty,
          ),
  ];
  final lineCount = lines.length;
  final targetWidth = _idealWidth(context, lineCount);
  final balanceScore = lineCount == 0
      ? 0.0
      : math.sqrt(
          widths.fold<double>(0, (total, width) {
                final deviation = (width - targetWidth) / context.maxWidth;
                return total + deviation * deviation;
              }) /
              lineCount,
        );
  return SemanticWrapLayout(
    breaks: breakOffsets,
    lines: lines,
    widths: widths,
    lineCount: lineCount,
    balanceScore: balanceScore,
    modelCost: breaks.fold<double>(
      0,
      (total, candidate) => total + candidate.penalty,
    ),
    overflow: widths.any(
      (width) => !width.isFinite || width > context.maxWidth + _epsilon,
    ),
  );
}

class _CandidateLayout {
  const _CandidateLayout({
    required this.breaks,
    required this.signature,
    required this.rawBalanceCost,
    required this.rawModelCost,
  });

  final List<BreakCandidate> breaks;
  final String signature;
  final double rawBalanceCost;
  final double rawModelCost;
}

int _compareCandidateLayouts(_CandidateLayout left, _CandidateLayout right) {
  final balance = left.rawBalanceCost - right.rawBalanceCost;
  if (balance.abs() > _epsilon) return balance < 0 ? -1 : 1;
  final model = left.rawModelCost - right.rawModelCost;
  if (model.abs() > _epsilon) return model < 0 ? -1 : 1;
  return left.signature.compareTo(right.signature);
}

/// Merges two cost-sorted lists, keeping only layouts no other layout beats on
/// both balance and model cost.
List<_CandidateLayout> _mergeParetoFrontiers(
  List<_CandidateLayout> left,
  List<_CandidateLayout> right,
) {
  final frontier = <_CandidateLayout>[];
  var leftIndex = 0;
  var rightIndex = 0;
  var bestModelCost = double.infinity;
  while (leftIndex < left.length || rightIndex < right.length) {
    final takeLeft =
        rightIndex >= right.length ||
        (leftIndex < left.length &&
            _compareCandidateLayouts(left[leftIndex], right[rightIndex]) <= 0);
    final layout = takeLeft ? left[leftIndex++] : right[rightIndex++];
    if (frontier.isNotEmpty &&
        bestModelCost <= layout.rawModelCost + _epsilon) {
      continue;
    }
    frontier.add(layout);
    bestModelCost = layout.rawModelCost;
  }
  return frontier;
}

/// The minimum number of lines the text needs at this width, and the
/// non-dominated layouts that reach it.
class _OptimalLayouts {
  const _OptimalLayouts(this.lineCount, this.layouts);

  /// Null when no layout fits, which happens when a single unbreakable run is
  /// wider than the available width.
  final int? lineCount;
  final List<List<int>> layouts;
}

_OptimalLayouts _calculateOptimalLayouts(_LayoutContext context) {
  if (context.text.isEmpty) {
    return const _OptimalLayouts(0, [<int>[]]);
  }
  final boundaries = context.candidates;
  final positions = <int>[
    0,
    for (final candidate in boundaries)
      _nextTextOffset(context.text, candidate.offset),
  ];

  String segmentText(int start, int end) => context.text.substring(
    positions[start],
    end < boundaries.length ? boundaries[end].offset : context.text.length,
  );

  // Row `start` holds the widths of the segments that begin at `positions[start]`
  // and end at boundaries `start`, `start + 1`, ... The row stops at the first
  // segment wider than the line, because every later one is wider still.
  final segmentWidths = <double>[];
  final segmentRowOffsets = List<int>.filled(positions.length + 1, 0);
  for (var start = 0; start < positions.length; start += 1) {
    segmentRowOffsets[start] = segmentWidths.length;
    for (var end = start; end < positions.length; end += 1) {
      final width = context.measureText(segmentText(start, end));
      segmentWidths.add(width);
      if (width > context.maxWidth + _epsilon) break;
    }
  }
  segmentRowOffsets[positions.length] = segmentWidths.length;

  final minimumLines = List<double>.filled(
    positions.length + 1,
    double.infinity,
  );
  minimumLines[positions.length] = 0;
  for (var start = positions.length - 1; start >= 0; start -= 1) {
    final rowStart = segmentRowOffsets[start];
    final rowEnd = segmentRowOffsets[start + 1];
    for (var index = rowStart; index < rowEnd; index += 1) {
      final end = start + index - rowStart;
      if (segmentWidths[index] > context.maxWidth + _epsilon) break;
      minimumLines[start] = math.min(
        minimumLines[start],
        1 + minimumLines[end + 1],
      );
    }
  }

  final lineCount = minimumLines[0];
  if (!lineCount.isFinite) return const _OptimalLayouts(null, [<int>[]]);
  final lines = lineCount.toInt();
  final targetWidth = _idealWidth(context, lines);

  final memo = <String, List<_CandidateLayout>>{};

  List<_CandidateLayout> solve(int start, int remainingLines) {
    final key = '$start:$remainingLines';
    final cached = memo[key];
    if (cached != null) return cached;
    if (start == positions.length) {
      final result = remainingLines == 0
          ? const [
              _CandidateLayout(
                breaks: [],
                signature: '',
                rawBalanceCost: 0,
                rawModelCost: 0,
              ),
            ]
          : const <_CandidateLayout>[];
      memo[key] = result;
      return result;
    }
    if (remainingLines <= 0 || positions.length - start < remainingLines) {
      return const <_CandidateLayout>[];
    }
    var frontier = <_CandidateLayout>[];
    final rowStart = segmentRowOffsets[start];
    final rowEnd = segmentRowOffsets[start + 1];
    for (var index = rowStart; index < rowEnd; index += 1) {
      final end = start + index - rowStart;
      final width = segmentWidths[index];
      if (width > context.maxWidth + _epsilon) break;
      final isLastLine = end == positions.length - 1;
      if (isLastLine != (remainingLines == 1)) continue;
      final nextStart = end + 1;
      final nextRemainingLines = remainingLines - 1;
      if (minimumLines[nextStart] > nextRemainingLines ||
          positions.length - nextStart < nextRemainingLines) {
        continue;
      }
      final rest = solve(nextStart, nextRemainingLines);
      final selectedBreak = isLastLine ? null : boundaries[end];
      final normalizedDeviation = (width - targetWidth) / context.maxWidth;
      final layouts = <_CandidateLayout>[];
      for (final suffix in rest) {
        layouts.add(
          _CandidateLayout(
            breaks: selectedBreak == null
                ? suffix.breaks
                : [selectedBreak, ...suffix.breaks],
            signature: selectedBreak == null
                ? suffix.signature
                : '${selectedBreak.offset}'
                      '${suffix.signature.isEmpty ? '' : ',${suffix.signature}'}',
            rawBalanceCost:
                normalizedDeviation * normalizedDeviation +
                suffix.rawBalanceCost,
            rawModelCost: (selectedBreak?.penalty ?? 0) + suffix.rawModelCost,
          ),
        );
      }
      frontier = _mergeParetoFrontiers(frontier, layouts);
    }
    memo[key] = frontier;
    return frontier;
  }

  final solved = solve(0, lines);
  if (solved.isEmpty) return _OptimalLayouts(lines, [<int>[]]);
  return _OptimalLayouts(lines, [
    for (final layout in solved)
      [for (final candidate in layout.breaks) candidate.offset],
  ]);
}

/// Picks the most even layout, then the most natural one among those.
///
/// [tolerance] is how much worse than the best balance a layout may be and
/// still be considered; within that band the lowest model cost wins.
int _selectByBalance(List<SemanticWrapLayout> layouts, double tolerance) {
  final minimumLineCount = layouts
      .map((layout) => layout.lineCount)
      .reduce(math.min);
  var eligible = <int>[
    for (var index = 0; index < layouts.length; index += 1)
      if (layouts[index].lineCount == minimumLineCount) index,
  ];
  final bestBalance = eligible
      .map((index) => layouts[index].balanceScore)
      .reduce(math.min);
  eligible = eligible
      .where(
        (index) =>
            layouts[index].balanceScore <= bestBalance + tolerance + _epsilon,
      )
      .toList();
  eligible.sort((left, right) {
    final modelCost = layouts[left].modelCost - layouts[right].modelCost;
    if (modelCost.abs() > _epsilon) return modelCost < 0 ? -1 : 1;
    final balanceScore =
        layouts[left].balanceScore - layouts[right].balanceScore;
    if (balanceScore.abs() > _epsilon) return balanceScore < 0 ? -1 : 1;
    return layouts[left].breaks
        .join(',')
        .compareTo(layouts[right].breaks.join(','));
  });
  return eligible.first;
}

/// Runs the whole prediction-to-selection pipeline for one text and width.
///
/// [measureText] must measure with the same font, size and scale the caller
/// renders with, otherwise the chosen lines can overflow.
///
/// The upstream library also compares against the browser's own layout. Flutter
/// does not expose its break offsets, so this port always takes the
/// "no native layout" branch of the selector.
SemanticWrapResult selectLineBreaks({
  required String text,
  required PhraseModel model,
  required double maxWidth,
  required double Function(String) measureText,
  double tolerance = 0.12,
}) {
  if (maxWidth <= 0 || !maxWidth.isFinite) {
    throw ArgumentError.value(maxWidth, 'maxWidth', 'must be positive finite');
  }
  final allowedOffsets = spaceOffsets(text);
  final predictions = _predictBreaks(text, model, allowedOffsets.toSet());
  final candidates = _aggregateLowestPenalty(
    allowedOffsets,
    predictions,
    model.fallbackPenalty,
  );
  final context = _LayoutContext(
    text: text,
    candidates: candidates,
    maxWidth: maxWidth,
    measureText: measureText,
  );
  final optimal = _calculateOptimalLayouts(context);
  final layouts = [
    for (final breaks in optimal.layouts) _layoutAtBreaks(context, breaks),
  ];
  final fitting = layouts.where((layout) => !layout.overflow).toList();
  final pool = fitting.isNotEmpty ? fitting : layouts;
  final selected = pool[_selectByBalance(pool, tolerance)];
  return SemanticWrapResult(
    lines: selected.lines,
    breaks: selected.breaks,
    applied: !selected.overflow && selected.breaks.isNotEmpty,
    overflow: selected.overflow,
    reason: 'calculated-selected',
  );
}

/// The bundled Korean preset from `@semantic-wrap/ko`, version 0.4.0.
///
/// Three cumulative levels: a break the coarse level predicts is free, the
/// medium and fine levels cost more, and a space no level predicted costs most.
/// The package calls this an experimental model trained on 100 Korean article
/// titles, so it suits short display text, not body copy.
final PhraseModel koTitlePhraseModel = PhraseModel(
  levels: [
    PhraseLevel(name: 'coarse', weights: koreanCoarseTitleWeights, penalty: 0),
    PhraseLevel(
      name: 'medium',
      weights: koreanMediumTitleWeights,
      penalty: 0.35,
    ),
    PhraseLevel(name: 'fine', weights: koreanFineTitleWeights, penalty: 0.7),
  ],
  fallbackPenalty: 1,
);
