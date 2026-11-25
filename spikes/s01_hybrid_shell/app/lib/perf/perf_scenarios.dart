/// Scenario names that `PerfRunner` reports in `S01_PERF` log lines.
/// Shared by the shell screen (which runs the scenarios) and the log
/// summariser (which checks that all of them were captured). Pure Dart.
const idleScenario = 'idle Flame scene';
const overlayScenario = 'overlay show/hide';
const stateScenario = 'Riverpod -> Flame state update';

/// The scenarios the §8.1 protocol expects for every device and bridge.
const expectedScenarios = [idleScenario, overlayScenario, stateScenario];
