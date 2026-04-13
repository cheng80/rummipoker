import 'dart:async';

import 'package:flutter/material.dart';

enum _NoticeStyle {
  topBanner,
  bottomToast,
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
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                bottomInset + 12,
              ),
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
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
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
    final borderColor = isTopBanner
        ? const Color(0xFFFFE08A)
        : Colors.white12;
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
        constraints: BoxConstraints(
          maxWidth: isTopBanner ? 360 : 320,
        ),
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
                  Icon(
                    icon,
                    color: textColor,
                    size: isTopBanner ? 20 : 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: isTopBanner ? TextAlign.left : TextAlign.center,
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
