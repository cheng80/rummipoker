part of 'game_cashout_widgets.dart';

class _GameCashOutEndlessNotice extends StatelessWidget {
  const _GameCashOutEndlessNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceEndless,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameUiPalette.specialDanger, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.specialDangerHard.withValues(alpha: 0.22),
            blurRadius: 14,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: GameUiPalette.specialGold,
            size: 22,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'S8 이후는 무한 도전입니다. 보상은 받고, 다음 Station부터 목표 점수가 계속 상승합니다.',
              softWrap: true,
              style: TextStyle(
                color: GameUiPalette.specialEndlessText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutChallengeCarryoverNotice extends StatelessWidget {
  const _GameCashOutChallengeCarryoverNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDeckUpgrade,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.actionInfoBlueBorder,
          width: 1.2,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.upgrade_rounded,
            color: GameUiPalette.actionInfoBlueText,
            size: 21,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '도전 모드는 족보 레벨과 추가 덱 카드만 계승합니다. 골드, Jester, 아이템, 마켓 상태는 새 런에서 초기화됩니다.',
              softWrap: true,
              style: TextStyle(
                color: GameUiPalette.actionInfoBluePale,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutGoldSummary extends StatelessWidget {
  const _GameCashOutGoldSummary({
    required this.currentGold,
    required this.totalGold,
  });

  final int currentGold;
  final int totalGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: GameUiPalette.ink.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameUiPalette.actionGoldBright.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _GameCashOutGoldMetric(
              label: '보유 골드',
              value: '${currentGold}G',
              valueKey: const ValueKey('cashout-current-gold-value'),
              valueStyle: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _GameCashOutGoldMetric(
            label: '총 획득',
            value: '+${totalGold}G',
            valueKey: const ValueKey('cashout-total-gold-value'),
            alignEnd: true,
            valueStyle: const TextStyle(
              color: GameUiPalette.actionGoldBright,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutGoldMetric extends StatelessWidget {
  const _GameCashOutGoldMetric({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.valueStyle,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final TextStyle valueStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GameUiPalette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(value, key: valueKey, style: valueStyle),
      ],
    );
  }
}

class _GameCashOutTileRewardLine extends StatelessWidget {
  const _GameCashOutTileRewardLine({required this.entry});

  final RummiSettlementEntryView entry;

  @override
  Widget build(BuildContext context) {
    final tile = entry.tile;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-deck-tile-reward-line'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.cashOutLinePulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = (1 - value).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: GameUiPalette.actionInfoBlue.withValues(
                  alpha: 0.18 * pulse,
                ),
                blurRadius: 18 * pulse,
                spreadRadius: 1.5 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GameUiPalette.actionInfoBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GameUiPalette.actionInfoBlue.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: tile == null
                  ? const SizedBox.shrink()
                  : GameRummiTileCard(
                      key: const ValueKey('cashout-deck-tile-reward-face'),
                      tile: tile,
                      selected: false,
                      accent: false,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '덱 타일 보상',
                    style: TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: const TextStyle(
                      color: GameUiPalette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _bonusEntryDescription(
  BuildContext context,
  RummiSettlementEntryView entry,
) {
  final displayName = entry.displayName ?? '';
  final jesterId = entry.jesterId;
  if (jesterId != null) {
    return '${JesterTranslationScope.of(context).resolveDisplayName(jesterId, displayName)} 보너스';
  }
  final itemId = entry.itemId;
  if (itemId != null) {
    return '${ItemTranslationScope.of(context).resolveDisplayName(itemId, displayName)} 보너스';
  }
  return entry.description;
}

class _GameCashOutReveal extends StatelessWidget {
  const _GameCashOutReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: GamePresentationTimings.cashOutLineReveal,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

class _GameCashOutLine extends StatelessWidget {
  const _GameCashOutLine({
    required this.leading,
    required this.text,
    required this.gold,
    this.isEndless = false,
  });

  factory _GameCashOutLine.fromSettlementEntry(
    RummiSettlementEntryView entry, {
    bool isEndless = false,
  }) {
    return _GameCashOutLine(
      leading: entry.leadingLabel,
      text: entry.description,
      gold: entry.gold,
      isEndless: isEndless,
    );
  }

  final String leading;
  final String text;
  final int gold;
  final bool isEndless;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-line-pulse'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.cashOutLinePulse,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = (1 - value).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    (isEndless
                            ? GameUiPalette.specialDanger
                            : GameUiPalette.actionGoldBright)
                        .withValues(alpha: 0.18 * pulse),
                blurRadius: 18 * pulse,
                spreadRadius: 1.5 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isEndless
                    ? GameUiPalette.surfaceDanger
                    : GameUiPalette.cardEmptyFace,
                borderRadius: BorderRadius.circular(10),
                border: isEndless
                    ? Border.all(color: GameUiPalette.specialDanger, width: 1)
                    : null,
              ),
              child: Text(
                leading,
                style: TextStyle(
                  color: isEndless
                      ? GameUiPalette.specialEndlessText
                      : GameUiPalette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isEndless
                      ? GameUiPalette.specialEndlessTextMuted
                      : GameUiPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (gold > 0) _GameCashOutCollectBadge(gold: gold),
          ],
        ),
      ),
    );
  }
}

class _GameCashOutCollectBadge extends StatelessWidget {
  const _GameCashOutCollectBadge({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-collect-badge'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.cashOutCollectBadge,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final scale = lerpDouble(0.94, 1, value)!;
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _GameCashOutCoinBurst()),
          DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.specialGoldSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GameUiPalette.actionGoldBright,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                '+$gold',
                style: const TextStyle(
                  color: GameUiPalette.actionGoldBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCashOutCoinBurst extends StatelessWidget {
  const _GameCashOutCoinBurst();

  static const List<Offset> _targets = [
    Offset(-18, -16),
    Offset(0, -22),
    Offset(18, -14),
    Offset(24, 4),
  ];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('cashout-coin-burst'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.cashOutCoinBurst,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _targets.length; i++)
              Positioned(
                left: 18 + _targets[i].dx * value,
                top:
                    10 + _targets[i].dy * value + math.sin(value * math.pi) * 4,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.78 + 0.22 * (1 - value),
                    child: const _GameCashOutCoinSpark(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GameCashOutCoinSpark extends StatelessWidget {
  const _GameCashOutCoinSpark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GameUiPalette.actionGoldBright,
        border: Border.all(color: GameUiPalette.specialGoldBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.actionGoldBright.withValues(alpha: 0.32),
            blurRadius: 6,
          ),
        ],
      ),
      child: const SizedBox.square(dimension: 7),
    );
  }
}

class _GameOutlinedLabel extends StatelessWidget {
  const _GameOutlinedLabel(
    this.text, {
    this.textAlign,
    required this.fillColor,
    required this.strokeColor,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
    this.height,
  });

  final String text;
  final TextAlign? textAlign;
  final Color fillColor;
  final Color strokeColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = strokeColor;

    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            foreground: strokePaint,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            height: height,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            color: fillColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            height: height,
            shadows: [
              Shadow(
                color: GameUiPalette.ink.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
