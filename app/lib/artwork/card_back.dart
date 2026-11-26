import 'dart:math' as math;
import 'dart:ui';

/// The back of a puzzle card, shared by every puzzle. Replaceable: a real
/// branded design can implement this later.
abstract interface class CardBackDesign {
  void paint(Canvas canvas, Rect rect);
}

/// **TEMPORARY PLACEHOLDER** card back, drawn in code: turquoise with a
/// light border and a white central mark (a simple jigsaw-piece glyph), in
/// the spirit of the reference recording. Not final branding; no external
/// asset.
class PlaceholderCardBack implements CardBackDesign {
  const PlaceholderCardBack();

  @override
  void paint(Canvas canvas, Rect rect) {
    final s = math.min(rect.width, rect.height);
    final radius = Radius.circular(s * 0.06);
    final rr = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const [Color(0xFF2EC4E0), Color(0xFF14A3C7), Color(0xFF0E86B0)],
          const [0, 0.55, 1],
        ),
    );
    // Soft diagonal sheen.
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(rect.topLeft, rect.bottomCenter, const [
          Color(0x33FFFFFF),
          Color(0x00FFFFFF),
        ]),
    );
    canvas.restore();
    // Border: white outer line and a thin inner line.
    canvas.drawRRect(
      rr.deflate(s * 0.03),
      Paint()
        ..color = const Color(0xEEFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * 0.035),
    );
    canvas.drawRRect(
      rr.deflate(s * 0.09),
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, s * 0.012),
    );
    _paintMark(canvas, rect.center, s * 0.36);
  }

  /// White jigsaw-piece glyph: a square with one knob on the top and right.
  void _paintMark(Canvas canvas, Offset c, double size) {
    final h = size / 2;
    final k = size * 0.16; // knob radius
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: size, height: size),
          Radius.circular(size * 0.12),
        ),
      )
      ..addOval(Rect.fromCircle(center: c.translate(0, -h), radius: k))
      ..addOval(Rect.fromCircle(center: c.translate(h, 0), radius: k));
    final hole = Path()
      ..addOval(Rect.fromCircle(center: c.translate(-h, 0), radius: k))
      ..addOval(Rect.fromCircle(center: c.translate(0, h), radius: k));
    final mark = Path.combine(PathOperation.difference, body, hole);
    canvas.drawPath(
      mark.shift(Offset(0, size * 0.04)),
      Paint()..color = const Color(0x33003A50),
    );
    canvas.drawPath(
      mark,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, size * 0.09)
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
