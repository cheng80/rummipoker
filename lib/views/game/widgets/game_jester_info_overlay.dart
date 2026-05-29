part of 'game_jester_widgets.dart';

class GameJesterInfoOverlay extends StatelessWidget {
  const GameJesterInfoOverlay({
    super.key,
    required this.card,
    this.runtimeValueText,
    required this.sellGold,
    required this.onSell,
    required this.onClose,
  });

  final RummiJesterCard card;
  final String? runtimeValueText;
  final int sellGold;
  final VoidCallback onSell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final notes = JesterTranslationScope.of(context).notes(card.id);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final previewMaxHeight = (viewportHeight - 96).clamp(420.0, 620.0);
    return Material(
      color: GameUiPalette.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiPalette.surfaceModalInner.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: previewMaxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizedJesterName(context, card),
                          style: const TextStyle(
                            color: GameUiPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: GameUiPalette.textPrimary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Center(
                    child: SizedBox(
                      width: kJesterCardWidth * 3,
                      height: kJesterCardHeight * 3,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: kJesterCardWidth,
                          height: kJesterCardHeight,
                          child: GameJesterSlot(
                            card: card,
                            runtimeValueText: runtimeValueText,
                            extended: true,
                            activeEffect: null,
                            settlementSequenceTick: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizedJesterEffect(context, card),
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (runtimeValueText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GameUiPalette.ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        runtimeValueText!,
                        style: const TextStyle(
                          color: GameUiPalette.cardName,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: TextStyle(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.64,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GameActionButton(
                      label: '판매 +$sellGold 골드',
                      background: GameUiPalette.actionDanger,
                      onPressed: onSell,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
