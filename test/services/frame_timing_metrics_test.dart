import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/services/frame_timing_metrics.dart';

FrameTiming _timing({
  required int build,
  required int raster,
  required int total,
}) {
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: build,
    rasterStart: total - raster,
    rasterFinish: total,
    rasterFinishWallTime: total,
  );
}

void main() {
  test('summarizes frame timing percentiles and missed frames', () {
    final summary = FrameTimingSummary.fromTimings([
      _timing(build: 100, raster: 100, total: 10000),
      _timing(build: 200, raster: 200, total: 12000),
      _timing(build: 300, raster: 300, total: 14000),
      _timing(build: 400, raster: 400, total: 16000),
      _timing(build: 500, raster: 500, total: 20000),
    ]);

    expect(summary.frameCount, 5);
    expect(summary.build.p50.inMicroseconds, 300);
    expect(summary.build.p95.inMicroseconds, 500);
    expect(summary.build.p99.inMicroseconds, 500);
    expect(summary.raster.average.inMicroseconds, 300);
    expect(summary.total.max.inMicroseconds, 20000);
    expect(summary.total.overBudgetCount, 1);
  });

  test('empty timing input returns an empty summary', () {
    final summary = FrameTimingSummary.fromTimings(const <FrameTiming>[]);

    expect(summary.frameCount, 0);
    expect(summary.build.average, Duration.zero);
    expect(summary.total.overBudgetCount, 0);
  });
}
