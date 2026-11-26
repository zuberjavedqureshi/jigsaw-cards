import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Pure timeline of the board-clearing exit before the next puzzle
/// (PRD GP-40). Keyed by board cell, like the introduction: cells leave
/// from the bottom-right, one after another, so the board empties quickly.
class ExitTimeline {
  ExitTimeline(this.cellCount, {this.stagger = 0.018, this.duration = 0.32})
    : order = [for (var i = cellCount - 1; i >= 0; i--) i];

  final int cellCount;
  final double stagger;
  final double duration;

  /// Cells in leaving order (bottom-right first).
  final List<int> order;

  double get totalDuration => (cellCount - 1) * stagger + duration;

  /// 0 = resting in its cell, 1 = gone below the play area.
  double progress(int cell, double t) {
    final rank = order.indexOf(cell);
    final p = (t - rank * stagger) / duration;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  bool isFinishedAt(double t) => t >= totalDuration;
}

/// What the exit needs from a board.
abstract interface class ExitStage {
  int get exitCellCount;
  Size get exitPlayArea;
  Rect exitCellRect(int cell);
  void poseExitTile(int cell, {required Offset centre, required double angle});
  void exitFinished();
}

/// Drives an [ExitTimeline]: tiles accelerate downward with a slight tilt
/// and leave the play area. Time only advances in [update], capped per
/// frame; [ExitStage.exitFinished] is called exactly once.
class ExitDirector extends Component {
  ExitDirector({required this.timeline, required this.stage});

  static const maxStep = 0.1;

  final ExitTimeline timeline;
  final ExitStage stage;

  double _elapsed = 0;
  bool _finished = false;

  double get elapsed => _elapsed;
  bool get isFinished => _finished;

  @override
  void update(double dt) {
    if (_finished) return;
    _elapsed += math.min(dt, maxStep);
    if (timeline.isFinishedAt(_elapsed)) {
      _finished = true;
      stage.exitFinished();
      return;
    }
    refresh();
  }

  /// Re-applies the current poses (e.g. after a resize).
  void refresh() {
    if (_finished) return;
    final area = stage.exitPlayArea;
    for (var cell = 0; cell < stage.exitCellCount; cell++) {
      final r = stage.exitCellRect(cell);
      final p = timeline.progress(cell, _elapsed);
      final fall = (area.height - r.top + r.height) * p * p; // ease-in
      final drift = (cell.isEven ? -1 : 1) * r.width * 0.15 * p;
      stage.poseExitTile(
        cell,
        centre: r.center + Offset(drift, fall),
        angle: (cell.isEven ? -0.25 : 0.25) * p,
      );
    }
  }
}
