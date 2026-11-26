import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../board_style.dart';
import '../intro/intro_timeline.dart' show easeOutCubic;
import 'celebration_timeline.dart';

/// What the celebration needs from a board.
abstract interface class CelebrationStage {
  /// Board rect (game coordinates) of the finished picture.
  Rect get celebrationBoard;

  /// The celebration finished: show the completion state.
  void celebrationFinished();
}

/// Plays a [CelebrationTimeline] over the board: a light sweep and a short
/// sparkle burst. Reusable for every puzzle; no rewards, no puzzle logic.
///
/// Time only advances in [update] (pauses with the game loop) and a frame
/// is capped at [maxStep] seconds; [CelebrationStage.celebrationFinished]
/// is called exactly once.
class CelebrationDirector extends PositionComponent {
  CelebrationDirector({
    required this.timeline,
    required this.stage,
    this.style = BoardStyle.sunlit,
  });

  static const maxStep = 0.1;
  static const _sparkCount = 26;

  final CelebrationTimeline timeline;
  final CelebrationStage stage;
  final BoardStyle style;

  double _elapsed = 0;
  bool _finished = false;
  late final List<_Spark> _sparks = _makeSparks();

  double get elapsed => _elapsed;
  bool get isFinished => _finished;

  List<_Spark> _makeSparks() {
    final rnd = math.Random(17);
    final colours = [
      style.selected, // sunflower
      const Color(0xFFFF7A6B), // coral
      const Color(0xFFFFFFFF),
      style.correctGlow, // leaf
      const Color(0xFFA98BE0), // lavender
    ];
    return [
      for (var i = 0; i < _sparkCount; i++)
        _Spark(
          angle: i * 2 * math.pi / _sparkCount + rnd.nextDouble() * 0.2,
          reach: 0.35 + rnd.nextDouble() * 0.35,
          size: 0.018 + rnd.nextDouble() * 0.02,
          delay: rnd.nextDouble() * 0.25,
          colour: colours[i % colours.length],
        ),
    ];
  }

  @override
  void update(double dt) {
    if (_finished) return;
    _elapsed += math.min(dt, maxStep);
    if (timeline.isFinishedAt(_elapsed)) {
      _finished = true;
      removeFromParent();
      stage.celebrationFinished();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_finished) return;
    final board = stage.celebrationBoard;
    _renderShine(
      canvas,
      board,
      timeline.progress(CelebrationTimeline.shine, _elapsed),
    );
    _renderSparkles(
      canvas,
      board,
      timeline.progress(CelebrationTimeline.sparkle, _elapsed),
    );
  }

  void _renderShine(Canvas canvas, Rect board, double p) {
    if (p <= 0 || p >= 1) return;
    final x = board.left - board.width * 0.5 + p * board.width * 2;
    canvas.save();
    canvas.clipRect(board);
    canvas.drawRect(
      board,
      Paint()
        ..shader = Gradient.linear(
          Offset(x - board.width * 0.25, board.top),
          Offset(x + board.width * 0.25, board.bottom),
          const [Color(0x00FFFFFF), Color(0x99FFFBF2), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
    canvas.restore();
  }

  void _renderSparkles(Canvas canvas, Rect board, double p) {
    if (p <= 0 || p >= 1) return;
    final c = board.center;
    final unit = board.shortestSide;
    for (final s in _sparks) {
      final q = ((p - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (q <= 0) continue;
      final d = easeOutCubic(q) * s.reach * unit;
      final pos = c + Offset(math.cos(s.angle), math.sin(s.angle)) * d;
      final alpha = (1 - q) * (q < 0.15 ? q / 0.15 : 1);
      _star(
        canvas,
        pos,
        s.size * unit * (1 - 0.4 * q),
        s.colour.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rad = i.isEven ? r : r * 0.4;
      final p = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = colour);
  }
}

class _Spark {
  const _Spark({
    required this.angle,
    required this.reach,
    required this.size,
    required this.delay,
    required this.colour,
  });

  final double angle;
  final double reach;
  final double size;
  final double delay;
  final Color colour;
}
