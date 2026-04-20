import 'dart:async';

import 'package:flutter/material.dart';

import '../resources/asset_paths.dart';

enum _NoticeStyle { topBanner, bottomToast }

class GameDialogAction<T> {
  const GameDialogAction({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF3CAEE0),
    this.textColor = Colors.white,
  });

  final String label;
  final T value;
  final Color accent;
  final Color textColor;
}

class GameChromeButton extends StatelessWidget {
  const GameChromeButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.onPressed,
    this.icon,
    this.height = 38,
    this.borderRadius = 16,
    this.padding,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final baseColor = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.34);
    final borderColor = _toneBorderColor(baseColor, enabled: isEnabled);
    final baseForeground = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.58);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: baseForeground),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AssetPaths.fontAngduIpsul140,
                        fontSize: 15,
                        color: baseForeground,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameIconButtonChip extends StatelessWidget {
  const GameIconButtonChip({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF29453A),
    this.foregroundColor = Colors.white,
    this.size = 38,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onPressed != null
                ? backgroundColor
                : backgroundColor.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _toneBorderColor(
                backgroundColor,
                enabled: onPressed != null,
              ),
              width: 1.4,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? foregroundColor
                : foregroundColor.withValues(alpha: 0.58),
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return child;
    }
    return Tooltip(message: tooltip!, child: child);
  }
}

class GameDialogSection extends StatelessWidget {
  const GameDialogSection({
    super.key,
    this.title,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final String? title;
  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontFamily: AssetPaths.fontAngduIpsul140,
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class GameMenuActionTile extends StatelessWidget {
  const GameMenuActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF173126,
            ).withValues(alpha: isEnabled ? 1 : 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: isEnabled ? 0.55 : 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.42),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AssetPaths.fontAngduIpsul140,
                        color: Colors.white.withValues(
                          alpha: isEnabled ? 0.94 : 0.7,
                        ),
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: isEnabled ? 0.7 : 0.46,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: isEnabled ? 0.82 : 0.46),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showTopNotice(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _NoticeCard(
                message: message,
                beginOffsetY: -18,
                style: _NoticeStyle.topBanner,
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Timer(duration + const Duration(milliseconds: 260), entry.remove);
}

void showBottomNotice(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final bottomInset = MediaQuery.viewInsetsOf(overlayContext).bottom;
      return IgnorePointer(
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 12),
              child: _NoticeCard(
                message: message,
                beginOffsetY: 18,
                style: _NoticeStyle.bottomToast,
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Timer(duration + const Duration(milliseconds: 260), entry.remove);
}

Future<T?> showAppDialog<T>(
  BuildContext context, {
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

Future<T?> showGameChoiceDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required List<GameDialogAction<T>> actions,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showAppDialog<T>(
    context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => _GameDialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AssetPaths.fontAngduIpsul140,
              fontSize: 26,
              color: Colors.white.withValues(alpha: 0.96),
              letterSpacing: 1.2,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
          if (content != null) ...[const SizedBox(height: 14), content],
          const SizedBox(height: 18),
          _GameDialogActionBar<T>(actions: actions),
        ],
      ),
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = '취소',
  String confirmLabel = '확인',
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final result = await showAppDialog<bool>(
    context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => _GameDialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AssetPaths.fontAngduIpsul140,
              fontSize: 26,
              color: Colors.white.withValues(alpha: 0.96),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _GameDialogActionBar<bool>(
            actions: [
              GameDialogAction<bool>(
                label: cancelLabel,
                value: false,
                accent: const Color(0xFF55615F),
              ),
              GameDialogAction<bool>(
                label: confirmLabel,
                value: true,
                accent: const Color(0xFFF4A81D),
                textColor: Colors.black,
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

class _GameDialogFrame extends StatelessWidget {
  const _GameDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 348),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF13251E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFE6D4A1).withValues(alpha: 0.24),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GameDialogActionBar<T> extends StatelessWidget {
  const _GameDialogActionBar({required this.actions});

  final List<GameDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _GameDialogActionButton<T>(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _GameDialogActionButton<T> extends StatelessWidget {
  const _GameDialogActionButton({required this.action});

  static const double _buttonHeight = 40;

  final GameDialogAction<T> action;

  @override
  Widget build(BuildContext context) {
    return GameChromeButton(
      label: action.label,
      backgroundColor: action.accent,
      foregroundColor: action.textColor,
      height: _buttonHeight,
      onPressed: () => Navigator.of(context).pop(action.value),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.message,
    required this.beginOffsetY,
    required this.style,
  });

  final String message;
  final double beginOffsetY;
  final _NoticeStyle style;

  @override
  Widget build(BuildContext context) {
    final isTopBanner = style == _NoticeStyle.topBanner;
    final backgroundColor = isTopBanner
        ? const Color(0xFFF4B326)
        : const Color(0xEE102D25);
    final borderColor = isTopBanner ? const Color(0xFFFFE08A) : Colors.white12;
    final textColor = isTopBanner
        ? const Color(0xFF1F1600)
        : Colors.white.withValues(alpha: 0.94);
    final icon = isTopBanner ? Icons.campaign_rounded : Icons.info_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * beginOffsetY),
            child: child,
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTopBanner ? 360 : 320),
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(isTopBanner ? 18 : 16),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTopBanner ? 16 : 14,
                vertical: isTopBanner ? 12 : 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: isTopBanner ? 20 : 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: isTopBanner
                          ? TextAlign.left
                          : TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isTopBanner ? 14 : 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
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

Color _toneBorderColor(Color color, {required bool enabled}) {
  final hsl = HSLColor.fromColor(color);
  final adjusted = hsl
      .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
      .toColor();
  return enabled
      ? adjusted.withValues(alpha: 0.88)
      : adjusted.withValues(alpha: 0.34);
}
