import 'dart:convert';
import 'dart:math' as math;

/// Frame-time statistics per the feasibility review §8.1 protocol.
/// Pure Dart (durations in microseconds) so it can be unit-tested.
class FrameStats {
  FrameStats._({
    required this.scenario,
    required this.budgetMs,
    required this.totalFrames,
    required this.missedFrames,
    required this.build,
    required this.raster,
  });

  /// [buildUs] and [rasterUs] are per-frame durations in microseconds.
  /// A frame is "missed" if build OR raster exceeds [budgetMs].
  factory FrameStats.from({
    required String scenario,
    required double budgetMs,
    required List<int> buildUs,
    required List<int> rasterUs,
  }) {
    assert(buildUs.length == rasterUs.length);
    final budgetUs = budgetMs * 1000;
    var missed = 0;
    for (var i = 0; i < buildUs.length; i++) {
      if (buildUs[i] > budgetUs || rasterUs[i] > budgetUs) missed++;
    }
    return FrameStats._(
      scenario: scenario,
      budgetMs: budgetMs,
      totalFrames: buildUs.length,
      missedFrames: missed,
      build: Distribution.of(buildUs),
      raster: Distribution.of(rasterUs),
    );
  }

  final String scenario;
  final double budgetMs;
  final int totalFrames;
  final int missedFrames;
  final Distribution build;
  final Distribution raster;

  double get missedPercent =>
      totalFrames == 0 ? 0 : missedFrames * 100 / totalFrames;

  Map<String, Object> toJson() => {
    'scenario': scenario,
    'budgetMs': budgetMs,
    'totalFrames': totalFrames,
    'missedFrames': missedFrames,
    'missedPercent': double.parse(missedPercent.toStringAsFixed(2)),
    'buildMs': build.toJson(),
    'rasterMs': raster.toJson(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

class Distribution {
  const Distribution(this.p50, this.p90, this.p99, this.max);

  /// Nearest-rank percentiles, reported in milliseconds.
  factory Distribution.of(List<int> microseconds) {
    if (microseconds.isEmpty) return const Distribution(0, 0, 0, 0);
    final sorted = [...microseconds]..sort();
    double pct(double p) {
      final rank = math.max(1, (p / 100 * sorted.length).ceil());
      return sorted[rank - 1] / 1000;
    }

    return Distribution(pct(50), pct(90), pct(99), sorted.last / 1000);
  }

  final double p50, p90, p99, max;

  Map<String, double> toJson() => {
    'p50': p50,
    'p90': p90,
    'p99': p99,
    'max': max,
  };
}
