import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'starry_background.dart';

const double kPhoneFrameRefW = 390.0;
const double kPhoneFrameRefH = 750.0;
const double kPhoneFrameRefAspect = kPhoneFrameRefW / kPhoneFrameRefH;
const double kPhoneFrameTabletShortSideThreshold = 500.0;
const double kPhoneFrameWebMinScale = 0.83;
const double kPhoneFrameWebMaxScale = 1.5;

class PhoneFrameScaffold extends StatelessWidget {
  const PhoneFrameScaffold({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  final Widget child;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final framedChild = Center(child: PhoneFrame(child: child));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: StarryBackground()),
          if (useSafeArea)
            SafeArea(child: framedChild)
          else
            Positioned.fill(child: framedChild),
        ],
      ),
    );
  }
}

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          final fittedScale = min(
            constraints.maxWidth / kPhoneFrameRefW,
            constraints.maxHeight / kPhoneFrameRefH,
          );
          final scale = fittedScale < kPhoneFrameWebMinScale
              ? fittedScale
              : fittedScale.clamp(
                  kPhoneFrameWebMinScale,
                  kPhoneFrameWebMaxScale,
                );
          return SizedBox(
            width: kPhoneFrameRefW * scale,
            height: kPhoneFrameRefH * scale,
            child: child,
          );
        }

        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final shortSide = min(maxW, maxH);
        final needsTabletFrame =
            shortSide > kPhoneFrameTabletShortSideThreshold;
        final frameH = maxH;
        final frameW = needsTabletFrame ? frameH * kPhoneFrameRefAspect : maxW;

        final framed = needsTabletFrame
            ? FittedBox(
                fit: BoxFit.contain,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(kPhoneFrameRefW, kPhoneFrameRefH),
                  ),
                  child: SizedBox(
                    width: kPhoneFrameRefW,
                    height: kPhoneFrameRefH,
                    child: child,
                  ),
                ),
              )
            : child;

        return SizedBox(width: frameW, height: frameH, child: framed);
      },
    );
  }
}
