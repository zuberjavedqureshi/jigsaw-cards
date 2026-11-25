import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

/// Application state for the S-01 shell. Owned by Riverpod; rendered by
/// Flutter widgets and (through a bridge) by the Flame scene.
@immutable
class ShellState {
  const ShellState({
    this.colorIndex = 0,
    this.gameTaps = 0,
    this.overlayVisible = false,
    this.lifecycle,
    this.pauseEvents = 0,
    this.resumeEvents = 0,
  });

  /// Flutter -> Riverpod -> Flame: selected placeholder colour.
  final int colorIndex;

  /// Flame -> Riverpod -> Flutter: number of taps emitted by the game.
  final int gameTaps;

  final bool overlayVisible;
  final AppLifecycleState? lifecycle;
  final int pauseEvents;
  final int resumeEvents;

  /// Pure-Dart domain call from the application layer: map the tap count onto
  /// a 4x4 logical grid. Demonstrates the domain package in use; not gameplay.
  GridCell get lastTapCell => spikeGrid.cellAt(gameTaps % spikeGrid.cellCount);

  ShellState copyWith({
    int? colorIndex,
    int? gameTaps,
    bool? overlayVisible,
    AppLifecycleState? lifecycle,
    int? pauseEvents,
    int? resumeEvents,
  }) => ShellState(
    colorIndex: colorIndex ?? this.colorIndex,
    gameTaps: gameTaps ?? this.gameTaps,
    overlayVisible: overlayVisible ?? this.overlayVisible,
    lifecycle: lifecycle ?? this.lifecycle,
    pauseEvents: pauseEvents ?? this.pauseEvents,
    resumeEvents: resumeEvents ?? this.resumeEvents,
  );
}

final spikeGrid = GridSize(4, 4);

/// Number of placeholder colours the game cycles through.
const paletteSize = 4;

/// Hand-written Riverpod notifier (TD-05 experiment: no code generation).
class ShellController extends Notifier<ShellState> {
  @override
  ShellState build() =>
      // Seed with the current state; AppLifecycleListener only reports changes.
      ShellState(lifecycle: WidgetsBinding.instance.lifecycleState);

  void cycleColor() =>
      state = state.copyWith(colorIndex: (state.colorIndex + 1) % paletteSize);

  /// Intent emitted by the Flame scene.
  void recordGameTap() => state = state.copyWith(gameTaps: state.gameTaps + 1);

  void setOverlayVisible(bool visible) =>
      state = state.copyWith(overlayVisible: visible);

  void toggleOverlay() => setOverlayVisible(!state.overlayVisible);

  void lifecycleChanged(AppLifecycleState value) =>
      state = state.copyWith(lifecycle: value);

  void paused() => state = state.copyWith(pauseEvents: state.pauseEvents + 1);

  void resumed() =>
      state = state.copyWith(resumeEvents: state.resumeEvents + 1);
}

final shellControllerProvider = NotifierProvider<ShellController, ShellState>(
  ShellController.new,
);
