import 'dart:async';

import 'package:flutter/material.dart';

void showTopNotice(
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
    builder: (context) {
      return IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _NoticeCard(
                message: message,
                beginOffsetY: -18,
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
  });

  final String message;
  final double beginOffsetY;

  @override
  Widget build(BuildContext context) {
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
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEE102D25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
