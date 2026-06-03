part of 'game_shared_widgets.dart';

const Color kGameModalBarrierColor = GameUiPalette.modalBarrier;
const Color kGameFeedbackBarrierColor = GameUiPalette.feedbackBarrier;

class GameInputBarrier extends StatelessWidget {
  const GameInputBarrier.modal({super.key}) : color = kGameModalBarrierColor;

  const GameInputBarrier.feedback({super.key})
    : color = kGameFeedbackBarrierColor;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(dismissible: false, color: color);
  }
}

/// 게임·상점 다이얼로그 공통 카드 컨테이너.
class GameModalCard extends StatelessWidget {
  const GameModalCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceModal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: child,
      ),
    );
  }
}

/// 게임·상점 다이얼로그를 표시한다. barrierDismissible 기본 true.
Future<T?> showGameFramedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String semanticLabel = '게임 대화상자',
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: kGameModalBarrierColor,
    routeSettings: RouteSettings(name: semanticLabel),
    builder: (dialogContext) {
      final routeLabel = semanticLabel.trim().isEmpty
          ? '게임 대화상자'
          : semanticLabel;
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: routeLabel,
        child: Dialog(
          backgroundColor: GameUiPalette.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: builder(dialogContext),
          ),
        ),
      );
    },
  );
}
