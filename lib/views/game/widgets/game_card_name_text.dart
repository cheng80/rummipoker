import 'package:flutter/material.dart';

/// 카드/아이템 이름은 공백 기준 자연 줄바꿈을 기본으로 맞춘다.
class GameCardNameText extends StatelessWidget {
  const GameCardNameText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: null,
      softWrap: true,
      overflow: TextOverflow.visible,
      textAlign: textAlign,
      style: style,
    );
  }
}
