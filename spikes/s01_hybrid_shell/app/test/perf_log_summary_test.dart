import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards_spike/perf/perf_log_summary.dart';
import 'package:jigsaw_cards_spike/perf/perf_scenarios.dart';

// Synthetic S01_PERF lines in the exact format PerfRunner prints (via
// logcat). The numbers are made up for the tests; they are not measurements.
String _line(String scenario, {String mode = 'profile'}) =>
    'S01_PERF {"scenario":"$scenario","budgetMs":16.666666666666668,'
    '"totalFrames":600,"missedFrames":3,"missedPercent":0.5,'
    '"buildMs":{"p50":1.0,"p90":2.0,"p99":5.0,"max":9.0},'
    '"rasterMs":{"p50":3.0,"p90":4.0,"p99":8.0,"max":20.0}} mode=$mode';

String _runs(String scenario, int n) =>
    List.filled(n, _line(scenario)).join('\n');

void main() {
  test('expected scenarios are the three names the app reports', () {
    expect(expectedScenarios, [
      'idle Flame scene',
      'overlay show/hide',
      'Riverpod -> Flame state update',
    ]);
  });

  test('parses logcat-prefixed S01_PERF lines and ignores other lines', () {
    final log = [
      '11-24 10:00:00.000  1234  1250 I flutter : something else',
      '11-24 10:00:10.000  1234  1250 I flutter : ${_line(idleScenario)}',
      '11-24 10:00:20.000  1234  1250 I flutter : ${_line(idleScenario)}',
    ].join('\n');
    final runs = parsePerfLog(log);
    expect(runs, hasLength(2));
    expect(runs.first.scenario, idleScenario);
    expect(runs.first.refreshHz, closeTo(60, 0.01));
    expect(runs.first.missedFrames, 3);
  });

  test('summary lists each run with its distribution', () {
    final s = summarize(parsePerfLog(_line(idleScenario)));
    expect(s, contains('| $idleScenario | 1 | 600 | 3 (0.5%) '));
    expect(s, contains('1.0 / 2.0 / 5.0 / 9.0'));
  });

  test('complete set (3 runs of each scenario) produces no warnings', () {
    final log = [for (final e in expectedScenarios) _runs(e, 3)].join('\n');
    expect(summarize(parsePerfLog(log)), isNot(contains('WARNING')));
  });

  test('a completely missing scenario is reported explicitly', () {
    // idle and overlay complete; state never run.
    final log = [_runs(idleScenario, 3), _runs(overlayScenario, 3)].join('\n');
    final s = summarize(parsePerfLog(log));
    expect(
      s,
      contains('missing scenario(s), no runs captured: "$stateScenario"'),
    );
    expect(s, isNot(contains('"$idleScenario"')));
    expect(s, isNot(contains('run(s); §8.1')));
  });

  test(
    'partially completed set: short and missing scenarios both reported',
    () {
      // idle 3 runs (complete), overlay 2 runs (short), state 0 runs (missing).
      final log = [
        _runs(idleScenario, 3),
        _runs(overlayScenario, 2),
      ].join('\n');
      final s = summarize(parsePerfLog(log));
      expect(
        s,
        contains('"$overlayScenario": 2 run(s); §8.1 requires at least 3'),
      );
      expect(
        s,
        contains('missing scenario(s), no runs captured: "$stateScenario"'),
      );
      expect(s, isNot(contains('"$idleScenario": 3 run(s)')));
      expect('WARNING'.allMatches(s), hasLength(2));
    },
  );

  test('flags non-profile runs as invalid', () {
    final s = summarize(parsePerfLog(_line(idleScenario, mode: 'debug')));
    expect(s, contains('INVALID: non-profile runs present'));
  });

  test('empty log reports no data and every scenario as missing', () {
    final s = summarize(parsePerfLog('nothing here'));
    expect(s, startsWith('No S01_PERF lines found.'));
    for (final e in expectedScenarios) {
      expect(s, contains('"$e"'));
    }
  });
}
