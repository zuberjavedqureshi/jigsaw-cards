// Usage (from spikes/s01_hybrid_shell/app):
//   dart run tool/summarize_perf_log.dart path/to/logcat.txt
// Prints a Markdown table of every S01_PERF result in the log.
import 'dart:io';

import 'package:jigsaw_cards_spike/perf/perf_log_summary.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/summarize_perf_log.dart <log file>');
    exit(64);
  }
  stdout.write(summarize(parsePerfLog(File(args.single).readAsStringSync())));
}
