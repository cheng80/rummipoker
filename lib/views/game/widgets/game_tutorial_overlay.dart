import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../resources/asset_paths.dart';

class GameTutorialStep {
  const GameTutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.align = ContentAlign.bottom,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final ContentAlign align;
}

List<TargetFocus> buildGameTutorialTargets({
  required List<GameTutorialStep> steps,
  required String nextLabel,
  required String doneLabel,
  required String skipLabel,
}) {
  return [
    for (var i = 0; i < steps.length; i += 1)
      TargetFocus(
        identify: 'tutorial_step_$i',
        keyTarget: steps[i].targetKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        paddingFocus: 6,
        enableOverlayTab: false,
        enableTargetTab: false,
        borderSide: const BorderSide(color: Color(0xFFF2C14E), width: 2),
        contents: [
          TargetContent(
            align: steps[i].align,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            builder: (context, controller) => _TutorialBubble(
              step: steps[i],
              isLast: i == steps.length - 1,
              nextLabel: nextLabel,
              doneLabel: doneLabel,
              skipLabel: skipLabel,
              onNext: controller.next,
              onSkip: controller.skip,
            ),
          ),
        ],
      ),
  ];
}

Widget buildGameTutorialSkipButton(String label) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF343241),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: const Color(0xFFF2C14E).withValues(alpha: 0.9),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.38),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.step,
    required this.isLast,
    required this.nextLabel,
    required this.doneLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  final GameTutorialStep step;
  final bool isLast;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF343241),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFF2C14E).withValues(alpha: 0.94),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontNexonLv2Gothic,
                    color: Color(0xFFF2C14E),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontNexonLv2Gothic,
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.82),
                        textStyle: const TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      child: Text(skipLabel),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF2C14E),
                        foregroundColor: const Color(0xFF241B10),
                        minimumSize: const Size(72, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: const TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      child: Text(isLast ? doneLabel : nextLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
