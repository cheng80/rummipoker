import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../resources/asset_paths.dart';
import 'game_word_wrap_text.dart';

class GameTutorialStep {
  const GameTutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.align = ContentAlign.bottom,
    this.keepBubbleAboveTarget = false,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final ContentAlign align;
  final bool keepBubbleAboveTarget;
}

List<TargetFocus> buildGameTutorialTargets({
  required BuildContext context,
  required List<GameTutorialStep> steps,
  required String nextLabel,
  required String doneLabel,
  required String skipLabel,
  ValueChanged<int>? onStepAdvanced,
}) {
  return [
    for (var i = 0; i < steps.length; i += 1)
      _buildGameTutorialTarget(
        context: context,
        step: steps[i],
        index: i,
        isLast: i == steps.length - 1,
        nextLabel: nextLabel,
        doneLabel: doneLabel,
        skipLabel: skipLabel,
        onStepAdvanced: onStepAdvanced,
      ),
  ];
}

TargetFocus _buildGameTutorialTarget({
  required BuildContext context,
  required GameTutorialStep step,
  required int index,
  required bool isLast,
  required String nextLabel,
  required String doneLabel,
  required String skipLabel,
  ValueChanged<int>? onStepAdvanced,
}) {
  final targetPosition = _tutorialTargetPosition(context, step.targetKey);
  final overlaySize = _tutorialOverlaySize(context);
  final contentAlign = step.keepBubbleAboveTarget
      ? ContentAlign.custom
      : step.align;

  return TargetFocus(
    identify: 'tutorial_step_$index',
    targetPosition: targetPosition,
    shape: ShapeLightFocus.RRect,
    radius: 12,
    paddingFocus: 6,
    enableOverlayTab: false,
    enableTargetTab: false,
    borderSide: const BorderSide(color: Color(0xFFF2C14E), width: 2),
    contents: [
      TargetContent(
        align: contentAlign,
        customPosition: step.keepBubbleAboveTarget
            ? _contentAboveTargetPosition(overlaySize, targetPosition)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        builder: (context, controller) => _TutorialBubble(
          step: step,
          isLast: isLast,
          nextLabel: nextLabel,
          doneLabel: doneLabel,
          skipLabel: skipLabel,
          onNext: () {
            onStepAdvanced?.call(index + 1);
            controller.next();
          },
          onSkip: controller.skip,
        ),
      ),
    ],
  );
}

CustomTargetContentPosition _contentAboveTargetPosition(
  Size overlaySize,
  TargetPosition targetPosition,
) {
  final bottom = (overlaySize.height - targetPosition.offset.dy + 18).clamp(
    128.0,
    overlaySize.height - 96,
  );
  return CustomTargetContentPosition(bottom: bottom);
}

Size _tutorialOverlaySize(BuildContext context) {
  final overlayBox = Overlay.of(context).context.findRenderObject();
  if (overlayBox is RenderBox && overlayBox.hasSize) {
    return overlayBox.size;
  }
  return MediaQuery.sizeOf(context);
}

TargetPosition _tutorialTargetPosition(BuildContext context, GlobalKey key) {
  final targetContext = key.currentContext;
  if (targetContext == null) {
    return TargetPosition(Size.zero, Offset.zero);
  }
  final renderObject = targetContext.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return TargetPosition(Size.zero, Offset.zero);
  }
  final overlayBox = Overlay.of(context).context.findRenderObject();
  final ancestor = overlayBox is RenderBox ? overlayBox : null;
  final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: ancestor);
  final bottomRight = renderObject.localToGlobal(
    Offset(renderObject.size.width, renderObject.size.height),
    ancestor: ancestor,
  );
  final size = Size(
    (bottomRight.dx - topLeft.dx).abs(),
    (bottomRight.dy - topLeft.dy).abs(),
  );
  return TargetPosition(size, topLeft);
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
                  maxLines: null,
                  softWrap: true,
                  overflow: TextOverflow.visible,
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
                GameWordWrapText(
                  step.description,
                  textAlign: TextAlign.left,
                  centerBlock: true,
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
