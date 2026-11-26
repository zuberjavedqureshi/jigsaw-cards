import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight, Shadow;

import 'praise_rules.dart';
import 'praise_timeline.dart';

/// Colours of one praise level: a light-to-saturated text fill with a
/// contrasting outline (Sunlit Storybook accents; no assets).
class PraiseStyle {
  const PraiseStyle({
    required this.fillTop,
    required this.fillBottom,
    required this.outline,
  });

  final Color fillTop;
  final Color fillBottom;
  final Color outline;

  static const byLevel = {
    PraiseLevel.nice: PraiseStyle(
      fillTop: Color(0xFFE4FFC2),
      fillBottom: Color(0xFF5CC27A), // leaf
      outline: Color(0xFF1E6B3A),
    ),
    PraiseLevel.great: PraiseStyle(
      fillTop: Color(0xFFFFF6B0),
      fillBottom: Color(0xFFFFB31A), // sunflower-gold
      outline: Color(0xFF9A4300),
    ),
    PraiseLevel.amazing: PraiseStyle(
      fillTop: Color(0xFFFFD6F4),
      fillBottom: Color(0xFFE052C4), // pink
      outline: Color(0xFF64188A),
    ),
    PraiseLevel.fantastic: PraiseStyle(
      fillTop: Color(0xFFFFE1B8),
      fillBottom: Color(0xFFFF7A3C), // coral-orange
      outline: Color(0xFF8A2410),
    ),
    PraiseLevel.perfect: PraiseStyle(
      fillTop: Color(0xFFE6FCFF),
      fillBottom: Color(0xFF19B3D1), // primary turquoise
      outline: Color(0xFF0B3C8A),
    ),
  };
}

/// Shows praise bursts over the board (M3.3). Presentation only: it never
/// handles input and never touches puzzle state. At most one burst is
/// current; a newer admitted praise dismisses the visible one gracefully.
class PraiseDirector extends Component {
  PraiseDirector({
    required this.rules,
    this.timing = const PraiseTiming(),
    this.reduceMotion = false,
  }) : gate = PraiseGate(rules);

  final PraiseRules rules;
  final PraiseTiming timing;
  final bool reduceMotion;
  final PraiseGate gate;

  double _clock = 0;
  PraiseBurst? _current;

  /// The newest visible burst, if any.
  PraiseBurst? get current {
    final c = _current;
    return (c == null || c.isRemoved || c.isFinished) ? null : c;
  }

  /// All bursts still on screen (a dismissed one may still be fading).
  List<PraiseBurst> get bursts => children.whereType<PraiseBurst>().toList();

  @override
  void update(double dt) {
    super.update(dt);
    _clock += math.min(dt, 0.1);
  }

  /// Shows [praise] centred near [anchor], kept fully inside [area]. Returns
  /// false if the gate skipped it (too soon after an equal or higher one).
  bool show(Praise praise, Offset anchor, Rect area, {double fontSize = 28}) {
    if (!gate.admit(praise, _clock)) return false;
    _current?.dismiss();
    final burst = PraiseBurst(
      praise: praise,
      style: PraiseStyle.byLevel[praise.level]!,
      timeline: PraiseTimeline(timing: timing, reduceMotion: reduceMotion),
      fontSize: fontSize,
    );
    final half = burst.halfExtent;
    burst.position = Vector2(
      anchor.dx.clamp(area.left + half.width, area.right - half.width),
      anchor.dy.clamp(area.top + half.height, area.bottom - half.height),
    );
    _current = burst;
    add(burst);
    return true;
  }

  /// Removes every burst immediately (e.g. when the board is cleared).
  void clear() {
    for (final b in bursts) {
      b.removeFromParent();
    }
    _current = null;
  }
}

/// One praise: outlined gradient text with a soft glow and a few sparkles,
/// tilted slightly, that pops in, bounces, then fades. Positioned at its
/// centre.
class PraiseBurst extends PositionComponent {
  PraiseBurst({
    required this.praise,
    required this.style,
    required this.timeline,
    required this.fontSize,
  }) : super(anchor: Anchor.center, angle: -0.12) {
    _layout();
  }

  static const sparkleCount = 8;

  final Praise praise;
  final PraiseStyle style;
  final PraiseTimeline timeline;
  final double fontSize;

  double _t = 0;
  double? _dismissedAt;
  late final TextPainter _outline;
  late final TextPainter _fill;
  late final List<_Sparkle> _sparkles;

  double get elapsed => _t;
  bool get isDismissed => _dismissedAt != null;
  bool get isFinished => timeline.isFinishedAt(_t, dismissedAt: _dismissedAt);
  double get opacity => timeline.opacityAt(_t, dismissedAt: _dismissedAt);
  double get currentScale => timeline.scaleAt(_t);

  /// Half the area the burst needs at peak size (text and sparkles), used
  /// to keep it on screen.
  Size get halfExtent => Size(
    _fill.width / 2 * PraiseTimeline.peakScale + fontSize * 0.4,
    _fill.height / 2 * PraiseTimeline.peakScale + fontSize * 0.5,
  );

  void _layout() {
    TextStyle base(Paint? fg) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: fontSize * 0.02,
      height: 1.1,
      foreground: fg,
    );
    _outline = TextPainter(
      text: TextSpan(
        text: praise.text,
        style:
            base(
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.2
                ..strokeJoin = StrokeJoin.round
                ..color = style.outline,
            ).copyWith(
              shadows: [
                Shadow(
                  color: const Color(0x66000000),
                  offset: Offset(0, fontSize * 0.08),
                  blurRadius: fontSize * 0.12,
                ),
              ],
            ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final h = _outline.height;
    _fill = TextPainter(
      text: TextSpan(
        text: praise.text,
        style: base(
          Paint()
            ..shader = Gradient.linear(
              Offset(0, h * 0.15),
              Offset(0, h * 0.85),
              [style.fillTop, style.fillBottom],
            ),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_fill.width, _fill.height);
    final rnd = math.Random(praise.text.hashCode);
    _sparkles = [
      for (var i = 0; i < sparkleCount; i++)
        _Sparkle(
          angle: i * 2 * math.pi / sparkleCount + rnd.nextDouble() * 0.5,
          reach: 0.55 + rnd.nextDouble() * 0.3,
          size: fontSize * (0.14 + rnd.nextDouble() * 0.12),
          gold: i.isOdd,
        ),
    ];
  }

  /// A newer praise replaces this one: fade out quickly.
  void dismiss() => _dismissedAt ??= _t;

  @override
  void update(double dt) {
    super.update(dt);
    _t += math.min(dt, 0.1);
    if (isFinished) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final o = opacity;
    if (o <= 0) return;
    final w = size.x, h = size.y;
    final c = Offset(w / 2, h / 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final s = currentScale;
    canvas.scale(s);
    canvas.translate(-c.dx, -c.dy);
    canvas.saveLayer(
      Rect.fromCenter(center: c, width: w * 3, height: h * 4),
      Paint()..color = Color.fromARGB((o * 255).round(), 255, 255, 255),
    );
    // Soft glow behind the word.
    canvas.drawOval(
      Rect.fromCenter(center: c, width: w * 1.15, height: h * 1.5),
      Paint()
        ..color = const Color(0x55FFF3A0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fontSize * 0.35),
    );
    _outline.paint(canvas, Offset.zero);
    _fill.paint(canvas, Offset.zero);
    for (var i = 0; i < _sparkles.length; i++) {
      final v = timeline.sparkleAt(i, _sparkles.length, _t);
      if (v <= 0) continue;
      final sp = _sparkles[i];
      final at =
          c +
          Offset(
            math.cos(sp.angle) * w * sp.reach,
            math.sin(sp.angle) * h * sp.reach * 1.6,
          );
      _star(
        canvas,
        at,
        sp.size * v,
        sp.gold ? const Color(0xFFFFE27A) : const Color(0xFFFFFFFF),
      );
    }
    canvas.restore();
    canvas.restore();
  }

  /// A four-point sparkle.
  void _star(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..color = colour.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  void onRemove() {
    _outline.dispose();
    _fill.dispose();
    super.onRemove();
  }
}

class _Sparkle {
  const _Sparkle({
    required this.angle,
    required this.reach,
    required this.size,
    required this.gold,
  });

  final double angle;
  final double reach;
  final double size;
  final bool gold;
}
