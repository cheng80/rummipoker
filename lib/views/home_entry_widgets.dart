import 'package:flutter/material.dart';

import '../resources/asset_paths.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AssetPaths.fontAngduIpsul140,
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class HomeEntryCard extends StatelessWidget {
  const HomeEntryCard({
    super.key,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final baseColor = enabled ? accent : Colors.white24;
    final darkerColor = HSLColor.fromColor(baseColor)
        .withLightness(
          (HSLColor.fromColor(baseColor).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              baseColor.withValues(alpha: enabled ? 1 : 0.35),
              darkerColor.withValues(alpha: enabled ? 1 : 0.35),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkerColor.withValues(alpha: 0.6),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: darkerColor.withValues(alpha: 0.5),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontAngduIpsul140,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: enabled ? 1 : 0.72),
                      letterSpacing: 2.2,
                      shadows: [
                        Shadow(
                          color: darkerColor.withValues(alpha: 0.8),
                          offset: const Offset(1, 1),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: enabled ? 0.82 : 0.6,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              enabled ? Icons.arrow_forward_rounded : Icons.lock_clock_rounded,
              color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeSnapshotCard extends StatelessWidget {
  const HomeSnapshotCard({
    super.key,
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
