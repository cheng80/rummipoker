import 'package:flutter/material.dart';

/// 긴 설명 문구를 공백 기준 단어 단위로 줄바꿈한다.
class GameWordWrapText extends StatelessWidget {
  const GameWordWrapText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
    this.spacing = 0,
    this.runSpacing = 0,
    this.centerBlock = false,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double spacing;
  final double runSpacing;
  final bool centerBlock;

  @override
  Widget build(BuildContext context) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) {
      return Align(
        alignment: centerBlock ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: null,
          softWrap: true,
          overflow: TextOverflow.visible,
          textAlign: textAlign,
          style: style,
        ),
      );
    }

    if (centerBlock) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          if (!maxWidth.isFinite) {
            return _wordWrap(words, textAlign);
          }
          final direction = Directionality.of(context);
          final textScaler = MediaQuery.textScalerOf(context);
          final lines = _buildLines(
            words: words,
            maxWidth: maxWidth,
            textDirection: direction,
            textScaler: textScaler,
          );
          final longestLineWidth = lines.fold<double>(0, (width, line) {
            final measured = _measure(
              line,
              textDirection: direction,
              textScaler: textScaler,
            );
            return measured > width ? measured : width;
          });
          // 실제 줄 폭보다 여유를 둬서 조사만 다음 줄로 밀리는 2차 wrap을 막고,
          // 전체 버블 폭까지 늘리지는 않아 텍스트 블록을 가운데에 둔다.
          final blockWidth = (longestLineWidth + 24).clamp(0.0, maxWidth);
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: blockWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < lines.length; i += 1)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == lines.length - 1 ? 0 : runSpacing,
                      ),
                      child: Text(
                        lines[i],
                        maxLines: null,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.left,
                        style: style,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return _wordWrap(words, textAlign);
  }

  Widget _wordWrap(List<String> words, TextAlign effectiveTextAlign) {
    return Wrap(
      alignment: switch (effectiveTextAlign) {
        TextAlign.left || TextAlign.start => WrapAlignment.start,
        TextAlign.right || TextAlign.end => WrapAlignment.end,
        TextAlign.justify => WrapAlignment.spaceBetween,
        TextAlign.center => WrapAlignment.center,
      },
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (var i = 0; i < words.length; i += 1)
          Text(
            i == words.length - 1 ? words[i] : '${words[i]} ',
            style: style,
            textAlign: effectiveTextAlign,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
      ],
    );
  }

  List<String> _buildLines({
    required List<String> words,
    required double maxWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      final candidateWidth = _measure(
        candidate,
        textDirection: textDirection,
        textScaler: textScaler,
      );
      if (current.isEmpty || candidateWidth <= maxWidth) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) {
      lines.add(current);
    }
    return lines;
  }

  double _measure(
    String value, {
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}
