import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../resources/asset_paths.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/fx/entrance_in.dart';
import '../../../widgets/fx/fx_layer.dart';
import '../../../widgets/fx/motion_policy.dart';
import '../../../widgets/fx/screen_shake.dart';
import '../game_feedback_cues.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

/// 런 요약 수치 한 줄. 값은 이미 있는 run 기록에서만 가져온다.
class GameRunVictoryStat {
  const GameRunVictoryStat({required this.labelKey, required this.value});

  final String labelKey;
  final int value;
}

/// 마지막 Boss를 깨고 런을 끝낸 순간의 승리 장면.
///
/// 승리 cue·코인·불꽃 뒤 요약 수치가 차례로 count-up된다. [GamePresentationTimings.runVictoryHold]
/// 뒤 스스로 끝나고, 어디를 탭해도 바로 끝난다. 끝나면 [onDone]을 한 번만 부른다.
/// 기록 저장과 save 정리는 호출부가 이 장면 전에 끝낸다.
class GameRunVictoryOverlay extends StatefulWidget {
  const GameRunVictoryOverlay({
    super.key,
    required this.stats,
    required this.onDone,
  });

  final List<GameRunVictoryStat> stats;
  final VoidCallback onDone;

  @override
  State<GameRunVictoryOverlay> createState() => _GameRunVictoryOverlayState();
}

class _GameRunVictoryOverlayState extends State<GameRunVictoryOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _revealedStats = 0;
  bool _done = false;

  Duration get _tallyStart => GamePresentationTimings.flowEntranceIn;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: GamePresentationTimings.runVictoryHold,
          )
          ..addListener(_onTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _finish();
          });
    _controller.forward();
    GameFeedback.play(GameCue.victory);
    WidgetsBinding.instance.addPostFrameCallback((_) => _burst());
  }

  void _burst() {
    if (!mounted) return;
    ScreenShake.instance.add(0.4);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final size = box.size;
    final top = Offset(size.width / 2, size.height * 0.3);
    Fx.emit(context, FxPresets.coins.copyWith(count: 14), [top]);
    Fx.emit(context, FxPresets.sparks, [
      top,
      Offset(size.width * 0.2, size.height * 0.36),
      Offset(size.width * 0.8, size.height * 0.36),
    ]);
  }

  void _onTick() {
    final elapsed = GamePresentationTimings.runVictoryHold * _controller.value;
    if (elapsed < _tallyStart) return;
    final next =
        ((elapsed - _tallyStart).inMicroseconds /
                GamePresentationTimings.runVictoryTallyStagger.inMicroseconds)
            .floor() +
        1;
    final clamped = next.clamp(0, widget.stats.length);
    if (clamped != _revealedStats) setState(() => _revealedStats = clamped);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _controller.stop();
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('run-victory-overlay'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_done) return;
        playButtonSound();
        _finish();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0, 0.12, curve: Curves.easeOut),
            ),
            child: ColoredBox(color: GameUiPalette.ink.withValues(alpha: 0.88)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EntranceIn(
                      duration: GamePresentationTimings.flowEntranceIn,
                      offset: Offset.zero,
                      scaleFrom: 1.6,
                      curve: Curves.easeOutBack,
                      child: Text(
                        context.tr('flowVictoryTitle'),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          color: GameUiPalette.actionGoldBright,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: GameUiPalette.ink,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (var i = 0; i < widget.stats.length; i++)
                      _VictoryStatRow(
                        key: ValueKey('run-victory-stat-$i'),
                        stat: widget.stats[i],
                        revealed: i < _revealedStats,
                      ),
                    const SizedBox(height: 26),
                    Text(
                      context.tr('flowVictorySkipHint'),
                      style: TextStyle(
                        color: GameUiPalette.textPrimary.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryStatRow extends StatelessWidget {
  const _VictoryStatRow({
    super.key,
    required this.stat,
    required this.revealed,
  });

  final GameRunVictoryStat stat;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(stat.labelKey),
              softWrap: true,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GameCountUpInt(
            value: revealed ? stat.value : 0,
            builder: (context, shown) => Text(
              '$shown',
              style: const TextStyle(
                color: GameUiPalette.actionGoldBright,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    // 공개 전에는 자리만 잡고 보이지 않는다. 투명도는 한 번 바뀌는 정적 값이고,
    // 공개 순간 옆에서 미끄러져 들어오며 0부터 count-up한다.
    return Opacity(
      opacity: revealed ? 1 : 0,
      child: AnimatedSlide(
        offset: revealed || MotionPolicy.juiceScale <= 0
            ? Offset.zero
            : const Offset(0.08, 0),
        duration: GamePresentationTimings.flowEntranceIn,
        curve: Curves.easeOutCubic,
        child: row,
      ),
    );
  }
}
