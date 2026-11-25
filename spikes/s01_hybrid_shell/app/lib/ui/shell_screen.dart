import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../game/game_bridge.dart';
import '../game/riverpod_shell_game.dart';
import '../game/shell_game.dart';
import '../perf/frame_stats.dart';
import '../perf/perf_runner.dart';
import '../perf/perf_scenarios.dart';
import '../state/shell_state.dart';

/// Which TD-03 bridge to use. Selected at build time:
/// `--dart-define=S01_BRIDGE=flame_riverpod` (default: manual).
enum BridgeKind { manual, flameRiverpod }

const _bridgeDefine = String.fromEnvironment('S01_BRIDGE');
const defaultBridge = _bridgeDefine == 'flame_riverpod'
    ? BridgeKind.flameRiverpod
    : BridgeKind.manual;

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, this.bridge = defaultBridge});

  final BridgeKind bridge;

  @override
  ConsumerState<ShellScreen> createState() => ShellScreenState();
}

class ShellScreenState extends ConsumerState<ShellScreen> {
  // Created once per screen: the game stays mounted across rebuilds and
  // overlay changes.
  late final FlameGame game;
  final _riverpodGameKey = GlobalKey<RiverpodAwareGameWidgetState>();
  late final AppLifecycleListener _lifecycle;
  FrameStats? lastStats;
  PerfRunner? _perf;

  /// Exposed for tests: number of lifecycle listeners this screen created.
  static int lifecycleListenersCreated = 0;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(shellControllerProvider.notifier);
    game = switch (widget.bridge) {
      BridgeKind.manual => ShellGame(
        intents: ShellGameIntents(onOrbTapped: controller.recordGameTap),
        initialColor: ref.read(shellControllerProvider).colorIndex,
        initialLifecycle: ref.read(shellControllerProvider).lifecycle,
      ),
      BridgeKind.flameRiverpod => RiverpodShellGame(),
    };
    // Exactly one app-level lifecycle listener, created here and disposed in
    // dispose(). (Flame's GameWidget separately observes lifecycle to pause
    // the engine while backgrounded; see findings.)
    lifecycleListenersCreated++;
    _lifecycle = AppLifecycleListener(
      onStateChange: controller.lifecycleChanged,
      onPause: controller.paused,
      onResume: controller.resumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shellControllerProvider);
    final controller = ref.read(shellControllerProvider.notifier);

    // Manual bridge, inbound direction: Riverpod -> Flame. `ref.listen` in
    // build is tied to this widget's lifetime, so there are no manual
    // subscriptions to close.
    if (game case final ShellGameView view) {
      ref.listen(
        shellControllerProvider.select((s) => s.colorIndex),
        (_, next) => view.showColor(next),
      );
      ref.listen(
        shellControllerProvider.select((s) => s.lifecycle),
        (_, next) => view.showLifecycle(next),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12152B),
      body: SafeArea(
        child: Column(
          children: [
            _Header(state: state, bridge: widget.bridge),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: switch (game) {
                      final RiverpodShellGame g => RiverpodAwareGameWidget(
                        key: _riverpodGameKey,
                        game: g,
                      ),
                      _ => GameWidget(game: game),
                    },
                  ),
                  if (state.overlayVisible)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _ShellOverlay(
                        state: state,
                        onRunPerf: _runPerf,
                        lastStats: lastStats,
                      ),
                    ),
                ],
              ),
            ),
            _Controls(
              overlayVisible: state.overlayVisible,
              onChangeColor: controller.cycleColor,
              onToggleOverlay: controller.toggleOverlay,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runPerf(String scenario) async {
    final budgetMs = 1000 / View.of(context).display.refreshRate;
    final perf = _perf ??= PerfRunner(budgetMs: budgetMs);
    if (perf.running) return;
    final controller = ref.read(shellControllerProvider.notifier);
    const duration = Duration(seconds: 10);
    final stats = switch (scenario) {
      'overlay' => await perf.run(
        scenario: overlayScenario,
        duration: duration,
        tickEvery: const Duration(milliseconds: 500),
        tick: controller.toggleOverlay,
      ),
      'state' => await perf.run(
        scenario: stateScenario,
        duration: duration,
        tickEvery: const Duration(milliseconds: 250),
        tick: controller.cycleColor,
      ),
      _ => await perf.run(scenario: idleScenario, duration: duration),
    };
    controller.setOverlayVisible(true);
    if (mounted) setState(() => lastStats = stats);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.bridge});

  final ShellState state;
  final BridgeKind bridge;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 14);
    final cell = state.lastTapCell;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B3160),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'S-01 Hybrid Shell (spike)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Game taps (Flame → Flutter): ${state.gameTaps}'
            ' · domain cell ${cell.row},${cell.column}',
            key: const Key('gameTaps'),
            style: style,
          ),
          Text(
            'Colour (Flutter → Flame): ${state.colorIndex}',
            key: const Key('colorIndex'),
            style: style,
          ),
          Text(
            'Lifecycle: ${state.lifecycle?.name ?? '-'}'
            ' · pauses ${state.pauseEvents} · resumes ${state.resumeEvents}',
            key: const Key('lifecycle'),
            style: style,
          ),
          Text(
            'Bridge: ${bridge.name}'
            ' · ${kProfileMode
                ? 'profile'
                : kReleaseMode
                ? 'release'
                : 'debug'}',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.overlayVisible,
    required this.onChangeColor,
    required this.onToggleOverlay,
  });

  final bool overlayVisible;
  final VoidCallback onChangeColor;
  final VoidCallback onToggleOverlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              key: const Key('changeColor'),
              onPressed: onChangeColor,
              child: const Text('Change colour'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              key: const Key('toggleOverlay'),
              onPressed: onToggleOverlay,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: Text(overlayVisible ? 'Hide overlay' : 'Show overlay'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flutter overlay drawn above the game. It covers only the lower part of the
/// game area, so the game stays visible and tappable above it.
class _ShellOverlay extends ConsumerWidget {
  const _ShellOverlay({
    required this.state,
    required this.onRunPerf,
    required this.lastStats,
  });

  final ShellState state;
  final void Function(String scenario) onRunPerf;
  final FrameStats? lastStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shellControllerProvider.notifier);
    final stats = lastStats;
    const small = TextStyle(fontSize: 12);
    final compact = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return Card(
      key: const Key('overlay'),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flutter overlay · domain grid $spikeGrid '
              '(${spikeGrid.cellCount} cells)',
              style: small,
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  key: const Key('overlayChangeColor'),
                  style: compact,
                  onPressed: controller.cycleColor,
                  child: const Text('Colour'),
                ),
                TextButton(
                  key: const Key('overlayClose'),
                  style: compact,
                  onPressed: () => controller.setOverlayVisible(false),
                  child: const Text('Close'),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Measure (10 s):', style: small),
                for (final s in const ['idle', 'overlay', 'state'])
                  TextButton(
                    key: Key('perf_$s'),
                    style: compact,
                    onPressed: () => onRunPerf(s),
                    child: Text(s, style: small),
                  ),
              ],
            ),
            if (stats != null)
              Text(
                '${stats.scenario}: ${stats.totalFrames} frames, '
                '${stats.missedFrames} missed '
                '(${stats.missedPercent.toStringAsFixed(1)}%), '
                'build p90 ${stats.build.p90} ms, '
                'raster p90 ${stats.raster.p90} ms',
                style: small,
              ),
          ],
        ),
      ),
    );
  }
}
