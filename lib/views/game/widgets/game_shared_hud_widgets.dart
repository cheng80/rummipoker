part of 'game_shared_widgets.dart';

class _GameGoldHudChip extends StatefulWidget {
  const _GameGoldHudChip({
    required this.gold,
    required this.onOptionsTap,
    this.onTutorialTap,
  });

  final int gold;
  final VoidCallback onOptionsTap;
  final VoidCallback? onTutorialTap;

  @override
  State<_GameGoldHudChip> createState() => _GameGoldHudChipState();
}

class _GameGoldHudChipState extends State<_GameGoldHudChip> {
  late int _previousGold;
  int _pulseTick = 0;

  @override
  void initState() {
    super.initState();
    _previousGold = widget.gold;
  }

  @override
  void didUpdateWidget(covariant _GameGoldHudChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previousGold == widget.gold) return;
    _previousGold = widget.gold;
    setState(() => _pulseTick++);
  }

  @override
  Widget build(BuildContext context) {
    final goldDisplayValue = '${widget.gold}';
    return TweenAnimationBuilder<double>(
      key: ValueKey('game-gold-pulse-$_pulseTick'),
      tween: Tween<double>(begin: 0, end: _pulseTick > 0 ? 1 : 0),
      duration: GamePresentationTimings.hudGoldPulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final glow = _pulseTick > 0 ? sin(value * pi) : 0.0;
        return DecoratedBox(
          key: _pulseTick > 0 ? const ValueKey('game-gold-pulse') : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kGameHudRadius),
            boxShadow: [
              if (glow > 0)
                BoxShadow(
                  color: GameUiPalette.actionGoldBright.withValues(
                    alpha: 0.26 * glow,
                  ),
                  blurRadius: 14,
                  spreadRadius: 1.4,
                ),
            ],
          ),
          child: child,
        );
      },
      child: GameHudChip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'GOLD',
                    style: gameHudLabelStyle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.onTutorialTap != null)
                  Tooltip(
                    message: context.tr('tutorialBattleReplayTitle'),
                    child: GestureDetector(
                      onTap: widget.onTutorialTap,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 20,
                        height: 18,
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: GameUiPalette.specialGold.withValues(
                            alpha: 0.95,
                          ),
                          size: 16,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Gold',
                      value: goldDisplayValue,
                      child: ExcludeSemantics(
                        child: Image.asset(
                          AssetPaths.uiGreed,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const _GoldAssetFallbackIcon(size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          goldDisplayValue,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: gameHudValueStyle.copyWith(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: widget.onOptionsTap,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 18,
                        height: 22,
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.88,
                          ),
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldAssetFallbackIcon extends StatelessWidget {
  const _GoldAssetFallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: GameUiPalette.actionGoldBright,
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          color: GameUiPalette.surfaceDeepGreen,
          height: 1,
        ),
      ),
    );
  }
}

class _StationGoalClearBadge extends StatelessWidget {
  const _StationGoalClearBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.stationClearSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: GameUiPalette.settlementActive.withValues(alpha: 0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.settlementActive.withValues(alpha: 0.24),
            blurRadius: 8,
            spreadRadius: 0.7,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          'CLEAR',
          style: TextStyle(
            color: GameUiPalette.specialSuccessText,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BossModifierHudLabel extends StatelessWidget {
  const _BossModifierHudLabel({required this.modifier});

  final RummiBossModifier modifier;

  @override
  Widget build(BuildContext context) {
    final compactLabel = _bossModifierCompactHudLabel(modifier);
    return SizedBox(
      height: 13,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 12,
            constraints: const BoxConstraints(minWidth: 18),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GameUiPalette.actionWarning.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.45),
                width: 0.7,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                modifier.markerText,
                maxLines: 1,
                style: const TextStyle(
                  color: GameUiPalette.textOnWarm,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                compactLabel,
                maxLines: 1,
                style: gameHudSubStyle.copyWith(
                  color: GameUiPalette.actionWarningText,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _bossModifierCompactHudLabel(RummiBossModifier modifier) {
  return switch (modifier.category) {
    RummiBossModifierCategory.tileColorWeaken => '타일',
    RummiBossModifierCategory.lineKindWeaken => '라인',
    RummiBossModifierCategory.faceTileWeaken => '그림',
    RummiBossModifierCategory.allScoreWeaken => '전체',
    RummiBossModifierCategory.firstConfirmWeaken => '첫 확정',
    RummiBossModifierCategory.confirmCountWeaken => '확정',
    RummiBossModifierCategory.repeatHandRankWeaken => '반복',
    RummiBossModifierCategory.singleHandRankPressure => '첫 족보',
  };
}
