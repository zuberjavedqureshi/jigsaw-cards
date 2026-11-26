import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'intro_timeline.dart';

/// What the introduction needs from a board: how many cells there are,
/// where each cell is, and a way to pose whatever tile is in a cell. The
/// director never sees puzzle rules, images or the solution.
abstract interface class IntroStage {
  int get introCellCount;

  /// Size of the play area (game coordinates).
  Size get introPlayArea;

  /// Rect of board cell [cell] (row-major index), in game coordinates.
  Rect introCellRect(int cell);

  /// Pose the tile currently in [cell]. [face] is 0 (back) … 1 (picture).
  void poseIntroTile(
    int cell, {
    required Offset centre,
    required double angle,
    required double scale,
    required double face,
    required bool inFlight,
  });

  /// The introduction finished: tiles must rest exactly in their cells,
  /// face-up, and input may be enabled.
  void introFinished();
}

/// Position, tilt and scale of a tile flying into [target].
typedef IntroPose = ({Offset centre, double angle, double scale});

/// Flight path of the reference: a card starts below the play area,
/// slightly towards the centre, tilted clockwise; it rises on a gentle
/// curve, straightens with a small overshoot and settles in its cell.
IntroPose introPose(Rect target, Size playArea, double progress) {
  final t = progress.clamp(0.0, 1.0);
  final end = target.center;
  final start = Offset(
    end.dx + (playArea.width / 2 - end.dx) * 0.45 - target.width * 0.3,
    playArea.height + target.height * 0.9,
  );
  // Quadratic Bézier: rise mostly vertically, then curve into the cell.
  final control = Offset(start.dx, end.dy + (start.dy - end.dy) * 0.3);
  final p = easeOutCubic(t);
  final a = 1 - p;
  final centre = Offset(
    a * a * start.dx + 2 * a * p * control.dx + p * p * end.dx,
    a * a * start.dy + 2 * a * p * control.dy + p * p * end.dy,
  );
  const startAngle = 0.32; // ≈ 18°, clockwise
  final angle = startAngle * (1 - easeOutBack(t, 1.6));
  final scale = 0.9 + 0.1 * easeOutCubic(t);
  return (centre: centre, angle: angle, scale: scale);
}

/// Drives the puzzle introduction on any [IntroStage] following an
/// [IntroTimeline]. Reusable for every puzzle; contains no puzzle logic.
///
/// Time only advances in [update], so the sequence pauses with the game
/// loop (app backgrounded) and continues where it was after resizes and
/// rebuilds. A single frame is capped at [maxStep] seconds so a long stall
/// cannot skip the whole sequence, and the finish callback always runs.
class IntroDirector extends Component {
  IntroDirector({required this.timeline, required this.stage});

  static const maxStep = 0.1;

  final IntroTimeline timeline;
  final IntroStage stage;

  double _elapsed = 0;
  IntroPhase _phase = IntroPhase.idle;
  bool _finished = false;

  double get elapsed => _elapsed;
  IntroPhase get phase => _phase;
  bool get isFinished => _finished;

  @override
  void onMount() {
    super.onMount();
    if (!_finished) _apply();
  }

  @override
  void update(double dt) {
    if (_finished) return;
    _elapsed += math.min(dt, maxStep);
    _apply();
  }

  /// Re-applies the current poses (e.g. after the play area was resized).
  void refresh() {
    if (!_finished) _apply();
  }

  void _apply() {
    _phase = timeline.phaseAt(_elapsed);
    if (_phase == IntroPhase.ready) {
      _finished = true;
      stage.introFinished();
      return;
    }
    final area = stage.introPlayArea;
    for (var cell = 0; cell < stage.introCellCount; cell++) {
      final enter = timeline.entranceProgress(cell, _elapsed);
      final pose = introPose(stage.introCellRect(cell), area, enter);
      stage.poseIntroTile(
        cell,
        centre: pose.centre,
        angle: pose.angle,
        scale: pose.scale,
        face: timeline.faceProgress(cell, _elapsed),
        inFlight: enter < 1,
      );
    }
  }
}
