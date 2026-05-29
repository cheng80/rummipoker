part of 'game_shop_screen.dart';

class _MarketActionPane extends StatelessWidget {
  const _MarketActionPane({
    required this.priceLabel,
    required this.buttonLabel,
    required this.buttonColor,
    this.foreground = GameUiPalette.textPrimary,
    this.onPressed,
    this.onDeniedPressed,
    this.disabledReason,
    this.denyActive = false,
    this.denyTick = 0,
    this.denyReason,
  });

  final String priceLabel;
  final String buttonLabel;
  final Color buttonColor;
  final Color foreground;
  final VoidCallback? onPressed;
  final VoidCallback? onDeniedPressed;
  final String? disabledReason;
  final bool denyActive;
  final int denyTick;
  final String? denyReason;

  @override
  Widget build(BuildContext context) {
    final pane = Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            priceLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameUiPalette.actionGoldBright,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          GameActionButton(
            label: buttonLabel,
            background: buttonColor,
            foreground: foreground,
            compact: true,
            onPressed: onPressed,
          ),
          if (disabledReason != null) ...[
            const SizedBox(height: 4),
            Text(
              disabledReason!,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameUiPalette.specialDangerBright,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
    final animatedPane = TweenAnimationBuilder<double>(
      key: ValueKey<int>(denyTick),
      tween: Tween<double>(begin: 0, end: denyActive ? 1 : 0),
      duration: GamePresentationTimings.marketActionDenyShake,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shake = denyActive
            ? math.sin(value * math.pi * 5) * 5 * (1 - value)
            : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: pane,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed == null ? onDeniedPressed : null,
      child: SizedBox(
        width: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            animatedPane,
            if (denyActive)
              Positioned(
                key: const ValueKey('market-deny-feedback'),
                top: -10,
                right: 0,
                child: MarketDenyBadge(
                  label: denyReason == null || denyReason!.isEmpty
                      ? '불가'
                      : denyReason!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketUseSellActionPane extends StatelessWidget {
  const _MarketUseSellActionPane({
    required this.count,
    required this.sellPrice,
    required this.onUse,
    required this.onSell,
    required this.denyActive,
    required this.denyTick,
    required this.denyReason,
  });

  final int count;
  final int sellPrice;
  final VoidCallback onUse;
  final VoidCallback onSell;
  final bool denyActive;
  final int denyTick;
  final String? denyReason;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'x$count',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameUiPalette.actionGoldBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              GameActionButton(
                label: '사용',
                background: GameUiPalette.primaryButtonBlue,
                compact: true,
                onPressed: onUse,
              ),
              const SizedBox(height: 3),
              Text(
                '+$sellPrice',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameUiPalette.actionGoldBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              GameActionButton(
                label: '판매',
                background: GameUiPalette.actionDanger,
                compact: true,
                onPressed: onSell,
              ),
            ],
          ),
          if (denyActive)
            Positioned(
              key: const ValueKey('market-deny-feedback'),
              top: -10,
              right: 0,
              child: MarketDenyBadge(
                label: denyReason == null || denyReason!.isEmpty
                    ? '불가'
                    : denyReason!,
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketDescriptionText extends StatelessWidget {
  const _MarketDescriptionText(
    this.text, {
    this.color = GameUiPalette.textSecondary,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('market-description-box'),
      constraints: const BoxConstraints(minHeight: kMarketDescriptionMinHeight),
      child: SingleChildScrollView(
        child: Text(
          text,
          key: const ValueKey('market-description-text'),
          maxLines: null,
          softWrap: true,
          style: _marketDescriptionTextStyle.copyWith(color: color),
        ),
      ),
    );
  }
}

class _MarketOfferDetailBody extends StatelessWidget {
  const _MarketOfferDetailBody({required this.effectText, required this.tags});

  final String effectText;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarketDescriptionText(effectText),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 3),
            _MarketDetailTagWrap(tags: tags),
          ],
        ],
      ),
    );
  }
}

class _MarketDetailTagWrap extends StatelessWidget {
  const _MarketDetailTagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(4).toList(growable: false);
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final tag in visibleTags)
          _MarketSynergyChip(label: tag, dense: true),
      ],
    );
  }
}

class _OwnedMarketItemBody extends StatelessWidget {
  const _OwnedMarketItemBody({required this.slot});

  final RummiMarketItemSlotView slot;

  @override
  Widget build(BuildContext context) {
    final effect = localizedItemSlotEffect(context, slot);
    final notice = _ownedItemSlotNotice(slot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketDescriptionText(effect),
        if (notice != null) ...[
          const SizedBox(height: 4),
          Text(
            notice,
            maxLines: 1,
            style: const TextStyle(
              color: GameUiPalette.actionGoldBright,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}
