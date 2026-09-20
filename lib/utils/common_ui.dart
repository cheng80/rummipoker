import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_translation.dart';
import '../resources/asset_paths.dart';
import '../resources/game_haptics.dart';
import '../resources/sound_manager.dart';
import '../views/game/game_feedback_cues.dart';
import '../views/game/game_presentation_timings.dart';
import '../views/game/widgets/game_ui_palette.dart';
import '../widgets/fx/juice.dart';
import '../widgets/fx/motion_policy.dart';
import '../widgets/phone_frame_scaffold.dart';
import '../widgets/semantic_text.dart';

enum _NoticeStyle { topBanner, bottomToast }

/// 기본 Flutter 버튼·닫기·뒤로 클릭도 공통 원음을 한 번 낸다.
VoidCallback? withButtonSound(VoidCallback? action) => action == null
    ? null
    : () {
        playButtonSound();
        action();
      };

void playButtonSound() {
  try {
    SoundManager.playSfx(AssetPaths.sfxBtnSnd, preserveOriginalPitch: true);
  } catch (error) {
    debugPrint('Button sound failed: $error');
  }
}

class GameDialogAction<T> {
  const GameDialogAction({
    required this.label,
    required this.value,
    this.accent = GameUiPalette.dialogDefaultAccent,
    this.textColor = GameUiPalette.textPrimary,
    this.cue,
  });

  final String label;
  final T value;
  final Color accent;
  final Color textColor;
  final GameCue? cue;
}

/// 공용 버튼. pointer-down에 살짝 찌그러지고, 뗄 때 juice와 가벼운 햅틱을 낸다.
///
/// 클릭음은 공통 입력이 한 번 재생한다. 호출부가 직접 클릭 cue를 내면 playSound를 끈다.
class GameChromeButton extends StatefulWidget {
  const GameChromeButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = GameUiPalette.textPrimary,
    this.onPressed,
    this.icon,
    this.height = 38,
    this.borderRadius = 16,
    this.padding,
    this.fontSize = 15,
    this.fontWeight,
    this.playSound = true,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final FontWeight? fontWeight;
  final bool playSound;

  @override
  State<GameChromeButton> createState() => _GameChromeButtonState();
}

class _GameChromeButtonState extends State<GameChromeButton> {
  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    final backgroundColor = widget.backgroundColor;
    final foregroundColor = widget.foregroundColor;
    final isEnabled = onPressed != null;
    final baseColor = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.34);
    final borderColor = _toneBorderColor(baseColor, enabled: isEnabled);
    final baseForeground = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.58);

    return PressFeedback(
      onTap: onPressed,
      playSound: widget.playSound,
      builder: (context, onTap) => _buildSurface(
        onTap: onTap,
        baseColor: baseColor,
        borderColor: borderColor,
        baseForeground: baseForeground,
        borderRadius: widget.borderRadius,
        icon: widget.icon,
      ),
    );
  }

  Widget _buildSurface({
    required VoidCallback? onTap,
    required Color baseColor,
    required Color borderColor,
    required Color baseForeground,
    required double borderRadius,
    required IconData? icon,
  }) {
    final height = widget.height;
    final padding = widget.padding;
    final label = widget.label;
    final fontSize = widget.fontSize;
    final fontWeight = widget.fontWeight;
    return Material(
      color: GameUiPalette.transparent,
      child: InkWell(
        onTap: onTap,
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
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
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

/// 입력 부품 공용 누름 반응.
///
/// pointer-down에 살짝 찌그러지고, tap에 juice와 [haptic]을 낸 뒤 [onTap]을 부른다.
/// [decision]은 런 시작·전투 시작처럼 무게가 있는 결정 버튼용으로 juice를 키운다.
/// [onTap]이 null이고 [deny]가 true면 탭에 좌우 흔들림·오류음·error 햅틱으로
/// 거절을 알린다. 거절은 게임 상태를 바꾸지 않는다. [denyTrigger]가 바뀔 때도
/// 같은 거절을 낸다(비동기 판정 뒤 거절할 때).
///
/// [builder]는 실제 탭 콜백을 받아 InkWell 등에 넘긴다. 비활성이면 null이다.
class PressFeedback extends StatefulWidget {
  const PressFeedback({
    super.key,
    required this.onTap,
    required this.builder,
    this.decision = false,
    this.deny = false,
    this.denyTrigger,
    this.haptic = HapticGrade.select,
    this.playSound = true,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, VoidCallback? onTap) builder;
  final bool decision;
  final bool deny;
  final Object? denyTrigger;

  /// 호출부가 햅틱을 포함한 [GameFeedback] cue를 직접 내면 null로 둔다.
  final HapticGrade? haptic;

  /// 전용 클릭 cue를 호출부가 소유할 때만 false로 둔다.
  final bool playSound;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback>
    with SingleTickerProviderStateMixin {
  static const double _denyAmplitude = 7;
  static const double _denyCycles = 3;

  late final AnimationController _denyController = AnimationController(
    vsync: this,
    duration: GamePresentationTimings.denyShake,
    value: 1,
  );
  bool _pressed = false;
  int _releaseTick = 0;

  @override
  void didUpdateWidget(covariant PressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.denyTrigger != oldWidget.denyTrigger) _playDeny();
    if (widget.onTap == null) _pressed = false;
  }

  @override
  void dispose() {
    _denyController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    setState(() => _releaseTick++);
    if (widget.playSound) playButtonSound();
    final haptic = widget.haptic;
    if (haptic != null) GameHaptics.play(haptic);
    onTap();
  }

  void _playDeny() {
    GameFeedback.play(GameCue.deny);
    if (MotionPolicy.juiceScale > 0) _denyController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final VoidCallback? tap = enabled
        ? _handleTap
        : (widget.deny ? _playDeny : null);
    final juiced = Juice(
      trigger: _releaseTick,
      strength: widget.decision ? 1.6 : 1,
      pressed: _pressed && enabled,
      child: Listener(
        onPointerDown: enabled ? (_) => _setPressed(true) : null,
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: widget.builder(context, tap),
      ),
    );
    return AnimatedBuilder(
      animation: _denyController,
      child: juiced,
      builder: (context, child) {
        final t = _denyController.value;
        final dx =
            _denyAmplitude *
            MotionPolicy.juiceScale *
            (1 - t) *
            math.sin(t * _denyCycles * 2 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

class GameIconButtonChip extends StatelessWidget {
  const GameIconButtonChip({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = GameUiPalette.marketNeutralButton,
    this.foregroundColor = GameUiPalette.textPrimary,
    this.size = 38,
    this.iconSize = 18,
    this.borderRadius = 14,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final double borderRadius;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = PressFeedback(
      onTap: onPressed,
      builder: (context, onTap) => Material(
        color: GameUiPalette.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onPressed != null
                  ? backgroundColor
                  : backgroundColor.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(borderRadius),
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
              size: iconSize,
              color: onPressed != null
                  ? foregroundColor
                  : foregroundColor.withValues(alpha: 0.58),
            ),
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

Color _toneBorderColor(Color color, {required bool enabled}) {
  final hsl = HSLColor.fromColor(color);
  final adjusted = hsl
      .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
      .toColor();
  return enabled
      ? adjusted.withValues(alpha: 0.88)
      : adjusted.withValues(alpha: 0.34);
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
        color: GameUiPalette.ink.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
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
    return PressFeedback(
      onTap: onTap,
      builder: (context, onTap) => Material(
        color: GameUiPalette.transparent,
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
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          color: GameUiPalette.textPrimary.withValues(
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
                            color: GameUiPalette.textPrimary.withValues(
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
                  color: GameUiPalette.textPrimary.withValues(
                    alpha: isEnabled ? 0.82 : 0.46,
                  ),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [cue]는 알림 등급 소리다. 호출부가 이미 거절음 등 다른 cue를 냈으면 null로 둔다.
void showTopNotice(
  BuildContext context,
  String message, {
  String Function(BuildContext)? messageBuilder,
  Duration duration = const Duration(milliseconds: 2200),
  GameCue? cue = GameCue.noticeTop,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  if (cue != null) GameFeedback.play(cue);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return IgnorePointer(
        child: SafeArea(
          child: Center(
            child: PhoneFrame(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _NoticeCard(
                    message: messageBuilder?.call(overlayContext) ?? message,
                    beginOffsetY: -18,
                    style: _NoticeStyle.topBanner,
                  ),
                ),
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
  String Function(BuildContext)? messageBuilder,
  Duration duration = const Duration(milliseconds: 1800),
  GameCue? cue = GameCue.noticeBottom,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  if (cue != null) GameFeedback.play(cue);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final bottomInset = MediaQuery.viewInsetsOf(overlayContext).bottom;
      return IgnorePointer(
        child: SafeArea(
          top: false,
          child: Center(
            child: PhoneFrame(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 12),
                  child: _NoticeCard(
                    message: messageBuilder?.call(overlayContext) ?? message,
                    beginOffsetY: 18,
                    style: _NoticeStyle.bottomToast,
                  ),
                ),
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
  String? routeName,
  required WidgetBuilder builder,
}) {
  final safeRouteName = routeName == null || routeName.trim().isEmpty
      ? context.translate('commonUiDialogLabel')
      : routeName;
  return pushGameDialog<T>(
    context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    barrierLabel: safeRouteName,
    settings: RouteSettings(name: safeRouteName),
    builder: builder,
  );
}

/// [showDialog]와 같은 dialog route를 scale-pop 등장·짧은 닫힘으로 연다.
///
/// barrier는 route 애니메이션을 따라 fade된다. 닫힘 뒤 route를 전환할 때의
/// `endOfFrame` 대기 규칙은 호출부가 그대로 따른다.
Future<T?> pushGameDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color? barrierColor,
  String? barrierLabel,
  RouteSettings? settings,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _GamePopDialogRoute<T>(
      context: context,
      builder: builder,
      barrierColor:
          barrierColor ??
          DialogTheme.of(context).barrierColor ??
          Colors.black54,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      settings: settings,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

class _GamePopDialogRoute<T> extends DialogRoute<T> {
  _GamePopDialogRoute({
    required super.context,
    required super.builder,
    super.barrierColor,
    super.barrierDismissible,
    super.barrierLabel,
    super.settings,
    super.themes,
  });

  static const double _popFromScale = 0.88;

  @override
  Duration get transitionDuration => GamePresentationTimings.dialogPopIn;

  @override
  Duration get reverseTransitionDuration =>
      GamePresentationTimings.dialogPopOut;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
    if (MotionPolicy.reduceMotion) return fade;
    return ScaleTransition(
      scale: Tween<double>(begin: _popFromScale, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      ),
      child: fade,
    );
  }
}

/// Builders run inside the dialog route so an open dialog follows locale changes.
/// A builder takes precedence over its legacy string/list/widget argument.
Future<T?> showGameChoiceDialog<T>(
  BuildContext context, {
  String title = '',
  String? message,
  String Function(BuildContext)? titleBuilder,
  String Function(BuildContext)? messageBuilder,
  Widget? content,
  WidgetBuilder? contentBuilder,
  List<GameDialogAction<T>> actions = const [],
  List<GameDialogAction<T>> Function(BuildContext)? actionsBuilder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  // The builders replaced the required title and actions, so the defaults let
  // a dialog with no heading and no way out compile.
  assert(
    title.isNotEmpty || titleBuilder != null,
    'showGameChoiceDialog needs a title or a titleBuilder.',
  );
  assert(
    actions.isNotEmpty || actionsBuilder != null,
    'showGameChoiceDialog needs actions or an actionsBuilder.',
  );
  return showAppDialog<T>(
    context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeName: title,
    builder: (dialogContext) {
      final resolvedTitle = titleBuilder?.call(dialogContext) ?? title;
      final resolvedMessage = messageBuilder?.call(dialogContext) ?? message;
      final resolvedContent = contentBuilder?.call(dialogContext) ?? content;
      final resolvedActions = actionsBuilder?.call(dialogContext) ?? actions;
      return _GameDialogFrame(
        semanticLabel: resolvedTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SemanticText(
              resolvedTitle,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 26,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                letterSpacing: 1.2,
              ),
            ),
            if (resolvedMessage != null) ...[
              const SizedBox(height: 14),
              SemanticText(
                resolvedMessage,
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ],
            if (resolvedContent != null) ...[
              const SizedBox(height: 14),
              Flexible(child: resolvedContent),
            ],
            const SizedBox(height: 18),
            _GameDialogActionBar<T>(actions: resolvedActions),
          ],
        ),
      );
    },
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  String title = '',
  String message = '',
  String Function(BuildContext)? titleBuilder,
  String Function(BuildContext)? messageBuilder,
  String? cancelLabel,
  String? confirmLabel,
  String Function(BuildContext)? cancelLabelBuilder,
  String Function(BuildContext)? confirmLabelBuilder,
  GameCue? confirmCue,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  assert(
    title.isNotEmpty || titleBuilder != null,
    'showConfirmDialog needs a title or a titleBuilder.',
  );
  final result = await showGameChoiceDialog<bool>(
    context,
    title: title,
    message: message,
    titleBuilder: titleBuilder,
    messageBuilder: messageBuilder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    actionsBuilder: (dialogContext) => [
      GameDialogAction<bool>(
        label:
            cancelLabelBuilder?.call(dialogContext) ??
            cancelLabel ??
            dialogContext.translate('cancel'),
        value: false,
        accent: GameUiPalette.disabledControl,
      ),
      GameDialogAction<bool>(
        label:
            confirmLabelBuilder?.call(dialogContext) ??
            confirmLabel ??
            dialogContext.translate('ok'),
        value: true,
        cue: confirmCue,
        accent: GameUiPalette.actionGold,
        textColor: GameUiPalette.ink,
      ),
    ],
  );
  return result ?? false;
}

class _GameDialogFrame extends StatelessWidget {
  const _GameDialogFrame({required this.child, this.semanticLabel});

  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel == null || semanticLabel!.trim().isEmpty
        ? context.translate('commonUiConfirmLabel')
        : semanticLabel!;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: Dialog(
        backgroundColor: GameUiPalette.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 348),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.chromePanelSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: GameUiPalette.cardFallback.withValues(alpha: 0.24),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: child,
            ),
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
      playSound: action.cue == null,
      backgroundColor: action.accent,
      foregroundColor: action.textColor,
      height: _buttonHeight,
      onPressed: () {
        try {
          if (action.cue case final cue?) GameFeedback.play(cue);
        } finally {
          Navigator.of(context).pop(action.value);
        }
      },
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
        ? GameUiPalette.noticeTopBannerSurface
        : GameUiPalette.noticeBottomSurface;
    final borderColor = isTopBanner
        ? GameUiPalette.actionGoldText
        : GameUiPalette.textPrimary.withValues(alpha: 0.12);
    final textColor = isTopBanner
        ? GameUiPalette.textOnGold
        : GameUiPalette.textPrimary.withValues(alpha: 0.94);
    final icon = isTopBanner ? Icons.campaign_rounded : Icons.info_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, value, _) {
        // 알파를 색에 직접 곱해 Opacity 오프스크린 합성을 피한다.
        Color fade(Color color) => color.withValues(alpha: color.a * value);
        return Transform.translate(
          offset: Offset(0, (1 - value) * beginOffsetY),
          child: ConstrainedBox(
            key: ValueKey(
              isTopBanner ? 'common-top-notice' : 'common-bottom-notice',
            ),
            constraints: BoxConstraints(maxWidth: isTopBanner ? 360 : 320),
            child: Material(
              color: GameUiPalette.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fade(backgroundColor),
                  borderRadius: BorderRadius.circular(isTopBanner ? 18 : 16),
                  border: Border.all(color: fade(borderColor)),
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
                        color: fade(textColor),
                        size: isTopBanner ? 20 : 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          textAlign: isTopBanner
                              ? TextAlign.left
                              : TextAlign.center,
                          style: TextStyle(
                            color: fade(textColor),
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
      },
    );
  }
}
