import 'package:flutter/material.dart';

import 'game/widgets/game_ui_palette.dart';

import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../utils/common_ui.dart';
import 'game/game_feedback_cues.dart';

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
        color: GameUiPalette.ink.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AssetPaths.fontNexonLv2Gothic,
              fontSize: 20,
              color: GameUiPalette.textPrimary.withValues(alpha: 0.95),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.66),
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
    this.cue = GameCue.buttonTap,
    this.decision = false,
  });

  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  /// false면 잠긴 카드다. 눌러도 동작하지 않고 거절 흔들림·오류음을 낸다.
  final bool enabled;

  /// 탭 소리·햅틱 의미. 호출부가 직접 cue를 내면 null로 둔다.
  final GameCue? cue;

  /// 런 시작처럼 무게가 있는 결정 카드.
  final bool decision;

  @override
  Widget build(BuildContext context) {
    final baseColor = enabled
        ? accent
        : GameUiPalette.textPrimary.withValues(alpha: 0.24);
    final darkerColor = HSLColor.fromColor(baseColor)
        .withLightness(
          (HSLColor.fromColor(baseColor).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();
    return PressFeedback(
      onTap: enabled ? _handleTap : null,
      deny: true,
      decision: decision,
      haptic: null,
      builder: (context, onTap) => Material(
        color: GameUiPalette.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  baseColor.withValues(alpha: enabled ? 1 : 0.35),
                  darkerColor.withValues(alpha: enabled ? 1 : 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: darkerColor.withValues(alpha: 0.6),
                width: 1.8,
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
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: enabled ? 1 : 0.72,
                          ),
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(
                              color: darkerColor.withValues(alpha: 0.8),
                              offset: const Offset(1, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: enabled ? 0.82 : 0.6,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  enabled
                      ? Icons.arrow_forward_rounded
                      : Icons.lock_clock_rounded,
                  color: GameUiPalette.textPrimary.withValues(
                    alpha: enabled ? 0.92 : 0.65,
                  ),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    SoundManager.unlockForWeb();
    final cue = this.cue;
    if (cue != null) GameFeedback.play(cue);
    onTap();
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
        color: GameUiPalette.ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.9),
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
