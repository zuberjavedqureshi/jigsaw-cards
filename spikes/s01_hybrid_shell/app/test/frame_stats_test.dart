import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards_spike/perf/frame_stats.dart';

void main() {
  test('nearest-rank percentiles and missed frames against a 60 Hz budget', () {
    // 100 frames: build 1..100 ms, raster constant 5 ms.
    final build = [for (var i = 1; i <= 100; i++) i * 1000];
    final raster = List.filled(100, 5000);
    final s = FrameStats.from(
      scenario: 't',
      budgetMs: 1000 / 60,
      buildUs: build,
      rasterUs: raster,
    );
    expect(s.totalFrames, 100);
    expect(s.build.p50, 50);
    expect(s.build.p90, 90);
    expect(s.build.p99, 99);
    expect(s.build.max, 100);
    // Frames with build > 16.67 ms: 17..100 -> 84 frames.
    expect(s.missedFrames, 84);
    expect(s.missedPercent, 84);
  });

  test('raster over budget also counts as missed (120 Hz budget)', () {
    final s = FrameStats.from(
      scenario: 't',
      budgetMs: 1000 / 120,
      buildUs: const [1000, 1000],
      rasterUs: const [9000, 1000],
    );
    expect(s.missedFrames, 1);
  });

  test('empty input is safe', () {
    final s = FrameStats.from(
      scenario: 't',
      budgetMs: 16.7,
      buildUs: const [],
      rasterUs: const [],
    );
    expect(s.totalFrames, 0);
    expect(s.missedPercent, 0);
  });
}
