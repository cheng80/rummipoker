import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

const _frameBudget = Duration(microseconds: 16667);

/// 프레임이 이만큼 끊기면 직전 연속 구간(확정 1회 연출 등)을 한 번에 보고한다.
const _idleReportGap = Duration(seconds: 1);

class FrameTimingMetrics {
  FrameTimingMetrics._();

  static final FrameTimingMetrics instance = FrameTimingMetrics._();
  static const _maxSamples = 6000;

  final List<FrameTiming> _timings = <FrameTiming>[];
  bool _started = false;
  Timer? _idleReportTimer;

  void start() {
    if (kReleaseMode || _started) return;
    SchedulerBinding.instance.addTimingsCallback(_record);
    _started = true;
  }

  void _record(List<FrameTiming> timings) {
    _idleReportTimer?.cancel();
    _idleReportTimer = Timer(_idleReportGap, reportAndReset);
    _timings.addAll(timings);
    if (_timings.length > _maxSamples) {
      _timings.removeRange(0, _timings.length - _maxSamples);
    }
  }

  FrameTimingSummary snapshot() {
    return FrameTimingSummary.fromTimings(_timings);
  }

  void reportAndReset() {
    if (kReleaseMode || _timings.isEmpty) return;
    debugPrint('FrameTimingSummary ${snapshot().toJson()}');
    _timings.clear();
  }
}

class FrameTimingSummary {
  const FrameTimingSummary({
    required this.frameCount,
    required this.build,
    required this.raster,
    required this.total,
  });

  factory FrameTimingSummary.fromTimings(Iterable<FrameTiming> timings) {
    final samples = timings.toList(growable: false);
    if (samples.isEmpty) {
      return const FrameTimingSummary(
        frameCount: 0,
        build: FrameTimingStats.empty(),
        raster: FrameTimingStats.empty(),
        total: FrameTimingStats.empty(),
      );
    }
    return FrameTimingSummary(
      frameCount: samples.length,
      build: FrameTimingStats.fromDurations(
        samples.map((timing) => timing.buildDuration),
      ),
      raster: FrameTimingStats.fromDurations(
        samples.map((timing) => timing.rasterDuration),
      ),
      total: FrameTimingStats.fromDurations(
        samples.map((timing) => timing.totalSpan),
      ),
    );
  }

  final int frameCount;
  final FrameTimingStats build;
  final FrameTimingStats raster;
  final FrameTimingStats total;

  Map<String, Object> toJson() {
    return <String, Object>{
      'frameCount': frameCount,
      'build': build.toJson(),
      'raster': raster.toJson(),
      'total': total.toJson(),
    };
  }
}

class FrameTimingStats {
  const FrameTimingStats({
    required this.average,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.p99,
    required this.max,
    required this.overBudgetCount,
  });

  const FrameTimingStats.empty()
    : average = Duration.zero,
      p50 = Duration.zero,
      p90 = Duration.zero,
      p95 = Duration.zero,
      p99 = Duration.zero,
      max = Duration.zero,
      overBudgetCount = 0;

  factory FrameTimingStats.fromDurations(Iterable<Duration> durations) {
    final samples =
        durations.map((duration) => duration.inMicroseconds).toList()..sort();
    if (samples.isEmpty) return const FrameTimingStats.empty();

    final sum = samples.fold<int>(0, (total, sample) => total + sample);
    return FrameTimingStats(
      average: Duration(microseconds: sum ~/ samples.length),
      p50: Duration(microseconds: _percentile(samples, 0.50)),
      p90: Duration(microseconds: _percentile(samples, 0.90)),
      p95: Duration(microseconds: _percentile(samples, 0.95)),
      p99: Duration(microseconds: _percentile(samples, 0.99)),
      max: Duration(microseconds: samples.last),
      overBudgetCount: samples
          .where((sample) => sample > _frameBudget.inMicroseconds)
          .length,
    );
  }

  final Duration average;
  final Duration p50;
  final Duration p90;
  final Duration p95;
  final Duration p99;
  final Duration max;
  final int overBudgetCount;

  Map<String, Object> toJson() {
    return <String, Object>{
      'averageUs': average.inMicroseconds,
      'p50Us': p50.inMicroseconds,
      'p90Us': p90.inMicroseconds,
      'p95Us': p95.inMicroseconds,
      'p99Us': p99.inMicroseconds,
      'maxUs': max.inMicroseconds,
      'overBudgetCount': overBudgetCount,
    };
  }
}

int _percentile(List<int> sortedSamples, double percentile) {
  final index = ((sortedSamples.length - 1) * percentile).ceil();
  return sortedSamples[index];
}
