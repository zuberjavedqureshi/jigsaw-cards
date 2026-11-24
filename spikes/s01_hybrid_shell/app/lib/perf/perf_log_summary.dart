import 'dart:convert';

/// One `S01_PERF` result parsed from a device log (pure Dart; no Flutter).
class PerfRun {
  PerfRun(this.json, this.mode);

  final Map<String, dynamic> json;
  final String mode;

  String get scenario => json['scenario'] as String;
  double get budgetMs => (json['budgetMs'] as num).toDouble();
  double get refreshHz => 1000 / budgetMs;
  int get totalFrames => json['totalFrames'] as int;
  int get missedFrames => json['missedFrames'] as int;
  num get missedPercent => json['missedPercent'] as num;
  Map<String, dynamic> get build => json['buildMs'] as Map<String, dynamic>;
  Map<String, dynamic> get raster => json['rasterMs'] as Map<String, dynamic>;
}

final _line = RegExp(r'S01_PERF (\{.*\}) mode=(\w+)');

/// Extracts every `S01_PERF` line from [log] (for example `adb logcat` output).
List<PerfRun> parsePerfLog(String log) => [
  for (final m in _line.allMatches(log))
    PerfRun(jsonDecode(m.group(1)!) as Map<String, dynamic>, m.group(2)!),
];

String _dist(Map<String, dynamic> d) =>
    '${d['p50']} / ${d['p90']} / ${d['p99']} / ${d['max']}';

/// Markdown summary: one table row per run, grouped by scenario, plus
/// warnings. Never fills in or averages missing data.
String summarize(List<PerfRun> runs, {int requiredRuns = 3}) {
  final out = StringBuffer();
  if (runs.isEmpty) return 'No S01_PERF lines found.\n';
  final warnings = <String>[];
  final modes = runs.map((r) => r.mode).toSet();
  if (modes.any((m) => m != 'profile')) {
    warnings.add(
      'INVALID: non-profile runs present ($modes). §8.1 requires profile mode.',
    );
  }
  final rates = runs.map((r) => r.refreshHz.toStringAsFixed(1)).toSet();
  out.writeln(
    'Refresh rate reported by the app: ${rates.join(', ')} Hz '
    '(budget ${runs.first.budgetMs.toStringAsFixed(2)} ms)',
  );
  out.writeln();
  out.writeln(
    '| Scenario | Run | Frames | Missed | Build p50 / p90 / p99 / max (ms) '
    '| Raster p50 / p90 / p99 / max (ms) | Mode |',
  );
  out.writeln('| --- | --- | --- | --- | --- | --- | --- |');
  final byScenario = <String, List<PerfRun>>{};
  for (final r in runs) {
    byScenario.putIfAbsent(r.scenario, () => []).add(r);
  }
  for (final entry in byScenario.entries) {
    var i = 0;
    for (final r in entry.value) {
      i++;
      out.writeln(
        '| ${entry.key} | $i | ${r.totalFrames} | ${r.missedFrames} '
        '(${r.missedPercent}%) | ${_dist(r.build)} | ${_dist(r.raster)} '
        '| ${r.mode} |',
      );
    }
    if (entry.value.length < requiredRuns) {
      warnings.add(
        '"${entry.key}": ${entry.value.length} run(s); '
        '§8.1 requires at least $requiredRuns.',
      );
    }
  }
  if (warnings.isNotEmpty) {
    out.writeln();
    for (final w in warnings) {
      out.writeln('- WARNING: $w');
    }
  }
  return out.toString();
}
