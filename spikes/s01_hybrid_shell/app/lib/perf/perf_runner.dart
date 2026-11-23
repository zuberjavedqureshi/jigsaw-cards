import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'frame_stats.dart';

/// Scripted measurement scenarios (feasibility review §8.1). Each scenario
/// runs for a fixed duration while [tick] drives the interaction, and frame
/// timings are collected from Flutter's FrameTiming callback.
/// Results are printed with the `S01_PERF` prefix (readable via logcat or
/// `flutter run --profile` output). Valid only in profile mode on a device.
class PerfRunner {
  PerfRunner({required this.budgetMs});

  final double budgetMs;
  bool _running = false;
  bool get running => _running;

  Future<FrameStats> run({
    required String scenario,
    required Duration duration,
    Duration? tickEvery,
    void Function()? tick,
  }) async {
    if (_running) throw StateError('A scenario is already running');
    _running = true;
    final build = <int>[];
    final raster = <int>[];
    void collect(List<FrameTiming> timings) {
      for (final t in timings) {
        build.add(t.buildDuration.inMicroseconds);
        raster.add(t.rasterDuration.inMicroseconds);
      }
    }

    SchedulerBinding.instance.addTimingsCallback(collect);
    Timer? ticker;
    if (tick != null && tickEvery != null) {
      ticker = Timer.periodic(tickEvery, (_) => tick());
    }
    try {
      await Future<void>.delayed(duration);
      // Timings are reported in batches; wait briefly for the last batch.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      ticker?.cancel();
      SchedulerBinding.instance.removeTimingsCallback(collect);
      _running = false;
    }
    final stats = FrameStats.from(
      scenario: scenario,
      budgetMs: budgetMs,
      buildUs: build,
      rasterUs: raster,
    );
    debugPrint(
      'S01_PERF ${stats.toString()} mode=${kProfileMode
          ? 'profile'
          : kReleaseMode
          ? 'release'
          : 'debug'}',
    );
    return stats;
  }
}
