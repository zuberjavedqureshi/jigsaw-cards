import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards_spike/perf/perf_log_summary.dart';

// Synthetic log lines in the exact format PerfRunner prints (via logcat).
// The numbers are made up for the test; they are not measurements.
const _json =
    '{"scenario":"idle Flame scene","budgetMs":16.666666666666668,'
    '"totalFrames":600,"missedFrames":3,"missedPercent":0.5,'
    '"buildMs":{"p50":1.0,"p90":2.0,"p99":5.0,"max":9.0},'
    '"rasterMs":{"p50":3.0,"p90":4.0,"p99":8.0,"max":20.0}}';

void main() {
  test('parses logcat-prefixed S01_PERF lines and ignores other lines', () {
    final log = [
      '11-24 10:00:00.000  1234  1250 I flutter : something else',
      '11-24 10:00:10.000  1234  1250 I flutter : S01_PERF $_json mode=profile',
      '11-24 10:00:20.000  1234  1250 I flutter : S01_PERF $_json mode=profile',
    ].join('\n');
    final runs = parsePerfLog(log);
    expect(runs, hasLength(2));
    expect(runs.first.scenario, 'idle Flame scene');
    expect(runs.first.refreshHz, closeTo(60, 0.01));
    expect(runs.first.missedFrames, 3);
  });

  test('summary lists each run and warns about too few runs', () {
    final s = summarize(parsePerfLog('S01_PERF $_json mode=profile'));
    expect(s, contains('| idle Flame scene | 1 | 600 | 3 (0.5%) '));
    expect(s, contains('1.0 / 2.0 / 5.0 / 9.0'));
    expect(s, contains('1 run(s); §8.1 requires at least 3'));
    expect(s, isNot(contains('INVALID')));
  });

  test('flags non-profile runs as invalid', () {
    final s = summarize(parsePerfLog('S01_PERF $_json mode=debug'));
    expect(s, contains('INVALID: non-profile runs present'));
  });

  test('three runs of a scenario produce no run-count warning', () {
    final log = List.filled(3, 'S01_PERF $_json mode=profile').join('\n');
    expect(summarize(parsePerfLog(log)), isNot(contains('WARNING')));
  });

  test('empty log is reported, not filled in', () {
    expect(
      summarize(parsePerfLog('nothing here')),
      'No S01_PERF lines found.\n',
    );
  });
}
