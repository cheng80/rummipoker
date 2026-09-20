import 'package:flutter/material.dart';

import 'game/widgets/game_ui_palette.dart';

import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../utils/common_ui.dart';
import 'game/game_feedback_cues.dart';

/// 메뉴 화면 공통 색. 전투·Market 패널과 같은 어두운 초록 + 금색 테두리다.
abstract final class MenuSurface {
  static const Color panel = GameUiPalette.titlePanelSurface;
  static const Color gold = GameUiPalette.actionGold;
  static const Color goldBright = GameUiPalette.actionGoldBright;
  static const Color goldText = GameUiPalette.actionGoldText;
  static const Color onGold = GameUiPalette.textOnGold;

  static Color border({double alpha = 0.42}) => gold.withValues(alpha: alpha);

  /// 구획 제목 아래 가는 구분선.
  static Color divider() => gold.withValues(alpha: 0.28);

  /// 패널 바탕. 밤하늘 배경이 비치도록 반투명이다.
  static Color panelFill({double alpha = 0.72}) =>
      panel.withValues(alpha: alpha);
}

/// 제목과 가는 구분선만으로 구획을 나눈다. 카드 테두리를 겹치지 않는다.
class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return SizedBox(
      width: 332,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AssetPaths.fontNexonLv2Gothic,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MenuSurface.goldText.withValues(alpha: 0.92),
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(height: 1, color: MenuSurface.divider()),
              ),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// 메뉴 진입 버튼. [primary]는 금색 강조, 나머지는 어두운 패널에 금색 테두리다.
class HomeEntryCard extends StatelessWidget {
  const HomeEntryCard({
    super.key,
    required this.title,
    this.description,
    this.accent,
    required this.onTap,
    this.enabled = true,
    this.cue = GameCue.buttonTap,
    this.decision = false,
    this.primary = false,
    this.compact = false,
  });

  final String title;

  /// 한 줄 보조 설명. 비우면 제목만 나온다.
  final String? description;

  /// 보조 버튼의 테두리·아이콘 색조. 비우면 금색을 쓴다.
  final Color? accent;
  final VoidCallback onTap;

  /// false면 잠긴 카드다. 눌러도 동작하지 않고 거절 흔들림·오류음을 낸다.
  final bool enabled;

  /// 탭 소리·햅틱 의미. 호출부가 직접 cue를 내면 null로 둔다.
  final GameCue? cue;

  /// 런 시작처럼 무게가 있는 결정 카드.
  final bool decision;

  /// 계속하기·새 런처럼 화면의 주 동작.
  final bool primary;

  /// 한 줄에 둘씩 놓는 좁은 버튼. 설명을 표시하지 않는다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? MenuSurface.gold;
    final description = compact ? null : this.description;
    final showDescription = description != null && description.isNotEmpty;

    final Color fill;
    final Color borderColor;
    final Color titleColor;
    final Color bodyColor;
    if (!enabled) {
      fill = MenuSurface.panelFill(alpha: 0.42);
      borderColor = GameUiPalette.disabledControl.withValues(alpha: 0.7);
      titleColor = GameUiPalette.textPrimary.withValues(alpha: 0.52);
      bodyColor = GameUiPalette.textPrimary.withValues(alpha: 0.4);
    } else if (primary) {
      fill = MenuSurface.gold;
      borderColor = MenuSurface.goldBright;
      titleColor = MenuSurface.onGold;
      bodyColor = MenuSurface.onGold.withValues(alpha: 0.78);
    } else {
      fill = MenuSurface.panelFill();
      borderColor = accent.withValues(alpha: 0.5);
      titleColor = GameUiPalette.textPrimary.withValues(alpha: 0.94);
      bodyColor = GameUiPalette.textPrimary.withValues(alpha: 0.62);
    }

    final minHeight = compact ? 46.0 : (showDescription ? 54.0 : 48.0);

    return PressFeedback(
      onTap: enabled ? _handleTap : null,
      deny: true,
      decision: decision,
      haptic: null,
      builder: (context, onTap) => Material(
        color: GameUiPalette.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(compact ? 10 : 14, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: AssetPaths.fontNexonLv2Gothic,
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                          if (showDescription) ...[
                            const SizedBox(height: 3),
                            Text(
                              description,
                              maxLines: 2,
                              style: TextStyle(
                                color: bodyColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      enabled
                          ? Icons.chevron_right_rounded
                          : Icons.lock_rounded,
                      color: enabled
                          ? (primary
                                ? MenuSurface.onGold.withValues(alpha: 0.72)
                                : accent.withValues(alpha: 0.82))
                          : GameUiPalette.disabledControl,
                      size: compact ? 18 : 20,
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
        color: MenuSurface.panelFill(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MenuSurface.border(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: MenuSurface.goldText.withValues(alpha: 0.82),
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
