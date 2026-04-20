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
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF152820), Color(0xFF102019)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFE6D4A1).withValues(alpha: 0.24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.46),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
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
    final darkerColor = HSLColor.fromColor(action.accent)
        .withLightness(
          (HSLColor.fromColor(action.accent).lightness - 0.16).clamp(0.0, 1.0),
        )
        .toColor();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(action.value),
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [action.accent, darkerColor],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: darkerColor.withValues(alpha: 0.62),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: darkerColor.withValues(alpha: 0.58),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            height: _buttonHeight,
            child: Center(
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  fontSize: 16,
                  color: action.textColor,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(
                        alpha: action.textColor == Colors.black ? 0.10 : 0.24,
                      ),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
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
    final shadowColor = isTopBanner
        ? const Color(0xAA000000)
        : Colors.black.withValues(alpha: 0.22);
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
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: isTopBanner ? 18 : 14,
                  offset: Offset(0, isTopBanner ? 8 : 6),
                ),
              ],
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
