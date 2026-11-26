import 'dart:math' as math;
import 'dart:ui';

/// The picture a puzzle is cut from. Pieces render their region of it by
/// clipping and translating, so implementations only paint the full scene.
abstract interface class PuzzleArtwork {
  /// Native size of the illustration. The board uses this aspect ratio so
  /// tiles are never stretched.
  Size get sourceSize;

  /// Display name of the picture (shown in the header).
  String get title;

  /// Paints the full scene into a canvas of [size]. Callers always pass
  /// [sourceSize] (scaled uniformly via the canvas transform).
  void paint(Canvas canvas, Size size);
}

/// **TEMPORARY PLACEHOLDER ARTWORK** (PRD VI-07). A bright, code-drawn
/// daytime storybook scene used until real puzzle art exists. Not final
/// art; not downloaded or AI-generated. Every one of the 16 tile regions
/// carries a distinguishing detail (sun, clouds, birds, rainbow, balloon,
/// castle towers and gate, trees, flowers, path, fence, pond) so the
/// puzzle stays solvable.
class PlaceholderDaytimeArtwork implements PuzzleArtwork {
  const PlaceholderDaytimeArtwork();

  /// Square: the scene is laid out on a 1:1 canvas.
  @override
  Size get sourceSize => const Size(1024, 1024);

  @override
  String get title => 'Sunny Castle';

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset at(double x, double y) => Offset(x * w, y * h);
    Paint fill(Color c) => Paint()..color = c;

    // Sky: clear blue to a warm, bright horizon.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.linear(
          at(0, 0),
          at(0, 0.64),
          const [Color(0xFF6CC4FF), Color(0xFFBFE8FF), Color(0xFFFFF1CF)],
          const [0, 0.6, 1],
        ),
    );

    // Sun (top-left) with soft halo and rays.
    final sun = at(0.15, 0.13);
    canvas.drawCircle(sun, 0.15 * w, fill(const Color(0x40FFE38A)));
    canvas.drawCircle(sun, 0.105 * w, fill(const Color(0x66FFD95A)));
    final ray = Paint()
      ..color = const Color(0xFFFFC845)
      ..strokeWidth = 0.012 * w
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        sun + Offset(math.cos(a), math.sin(a)) * (0.09 * w),
        sun + Offset(math.cos(a), math.sin(a)) * (0.125 * w),
        ray,
      );
    }
    canvas.drawCircle(sun, 0.07 * w, fill(const Color(0xFFFFD447)));
    canvas.drawCircle(
      sun.translate(-0.02 * w, -0.02 * w),
      0.03 * w,
      fill(const Color(0x66FFFFFF)),
    );

    // Rainbow (upper right).
    final rc = at(1.02, 0.58);
    const bands = [
      Color(0xBFFF7A6B),
      Color(0xBFFFC845),
      Color(0xBF5CC27A),
      Color(0xBF19B3D1),
      Color(0xBFA98BE0),
    ];
    for (var i = 0; i < bands.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: rc, radius: (0.36 - i * 0.022) * w),
        math.pi,
        math.pi / 2,
        false,
        Paint()
          ..color = bands[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.022 * w,
      );
    }

    // Clouds.
    void cloud(double x, double y, double r) {
      final c = at(x, y);
      final p = fill(const Color(0xFFFFFFFF));
      final s = fill(const Color(0x22839CB8));
      final rr = r * w;
      for (final (dx, dy, k) in const [
        (0.0, 0.0, 1.0),
        (0.9, 0.2, 0.8),
        (-0.9, 0.25, 0.72),
        (0.4, -0.35, 0.7),
      ]) {
        canvas.drawCircle(c.translate(dx * rr, dy * rr + rr * 0.12), rr * k, s);
      }
      for (final (dx, dy, k) in const [
        (0.0, 0.0, 1.0),
        (0.9, 0.2, 0.8),
        (-0.9, 0.25, 0.72),
        (0.4, -0.35, 0.7),
      ]) {
        canvas.drawCircle(c.translate(dx * rr, dy * rr), rr * k, p);
      }
    }

    cloud(0.40, 0.11, 0.06);
    cloud(0.72, 0.30, 0.035);
    cloud(0.28, 0.36, 0.03);

    // Birds (upper middle-right).
    final bird = Paint()
      ..color = const Color(0xFF2B3A55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.006 * w
      ..strokeCap = StrokeCap.round;
    for (final (x, y, k) in const [
      (0.60, 0.08, 1.0),
      (0.66, 0.13, 0.8),
      (0.56, 0.16, 0.7),
    ]) {
      final b = at(x, y);
      final s = 0.025 * w * k;
      canvas.drawPath(
        Path()
          ..moveTo(b.dx - s, b.dy)
          ..quadraticBezierTo(b.dx - s / 2, b.dy - s * 0.7, b.dx, b.dy)
          ..quadraticBezierTo(b.dx + s / 2, b.dy - s * 0.7, b.dx + s, b.dy),
        bird,
      );
    }

    // Kite with a ribbon tail (top right).
    final kite = at(0.87, 0.1);
    final ks = 0.05 * w;
    final kitePath = Path()
      ..moveTo(kite.dx, kite.dy - ks)
      ..lineTo(kite.dx + ks * 0.7, kite.dy)
      ..lineTo(kite.dx, kite.dy + ks * 1.1)
      ..lineTo(kite.dx - ks * 0.7, kite.dy)
      ..close();
    canvas.drawPath(kitePath, fill(const Color(0xFFA98BE0)));
    canvas.drawPath(
      Path()
        ..moveTo(kite.dx, kite.dy - ks)
        ..lineTo(kite.dx + ks * 0.7, kite.dy)
        ..lineTo(kite.dx, kite.dy)
        ..close(),
      fill(const Color(0xFFFFC845)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(kite.dx, kite.dy + ks * 1.1)
        ..lineTo(kite.dx - ks * 0.7, kite.dy)
        ..lineTo(kite.dx, kite.dy)
        ..close(),
      fill(const Color(0xFFFF7A6B)),
    );
    final tail = Paint()
      ..color = const Color(0xFF2B3A55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.004 * w;
    final tailPath = Path()
      ..moveTo(kite.dx, kite.dy + ks * 1.1)
      ..cubicTo(
        kite.dx - ks * 0.6,
        kite.dy + ks * 2,
        kite.dx + ks * 0.6,
        kite.dy + ks * 2.6,
        kite.dx - ks * 0.2,
        kite.dy + ks * 3.4,
      );
    canvas.drawPath(tailPath, tail);
    for (var i = 0; i < 3; i++) {
      final t = kite.translate(
        (i.isEven ? -0.25 : 0.2) * ks,
        ks * (1.8 + i * 0.55),
      );
      canvas.drawPath(
        Path()
          ..moveTo(t.dx - ks * 0.18, t.dy - ks * 0.1)
          ..lineTo(t.dx + ks * 0.18, t.dy + ks * 0.1)
          ..lineTo(t.dx + ks * 0.18, t.dy - ks * 0.1)
          ..lineTo(t.dx - ks * 0.18, t.dy + ks * 0.1)
          ..close(),
        fill(i.isEven ? const Color(0xFFFF7A6B) : const Color(0xFF19B3D1)),
      );
    }

    // Hot-air balloon (left, second row).
    final bc = at(0.12, 0.36);
    final br = 0.055 * w;
    final balloon = Rect.fromCircle(center: bc, radius: br);
    canvas.save();
    canvas.clipPath(Path()..addOval(balloon));
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          balloon.left + i * br * 0.4,
          balloon.top,
          br * 0.4,
          balloon.height,
        ),
        fill(i.isEven ? const Color(0xFFFF7A6B) : const Color(0xFFFFC845)),
      );
    }
    canvas.restore();
    final ropes = Paint()
      ..color = const Color(0xFF8A6A45)
      ..strokeWidth = 0.003 * w;
    canvas.drawLine(
      bc.translate(-br * 0.6, br * 0.75),
      bc.translate(-br * 0.25, br * 1.45),
      ropes,
    );
    canvas.drawLine(
      bc.translate(br * 0.6, br * 0.75),
      bc.translate(br * 0.25, br * 1.45),
      ropes,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: bc.translate(0, br * 1.55),
          width: br * 0.6,
          height: br * 0.4,
        ),
        Radius.circular(br * 0.08),
      ),
      fill(const Color(0xFFB5814A)),
    );

    // Distant mountains.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0.6 * h)
        ..lineTo(0.18 * w, 0.47 * h)
        ..lineTo(0.32 * w, 0.56 * h)
        ..lineTo(0.5 * w, 0.44 * h)
        ..lineTo(0.7 * w, 0.55 * h)
        ..lineTo(0.86 * w, 0.46 * h)
        ..lineTo(w, 0.54 * h)
        ..lineTo(w, 0.66 * h)
        ..lineTo(0, 0.66 * h)
        ..close(),
      fill(const Color(0xFFA9C4EC)),
    );
    for (final (x, y) in const [(0.18, 0.47), (0.5, 0.44), (0.86, 0.46)]) {
      canvas.drawPath(
        Path()
          ..moveTo((x - 0.035) * w, (y + 0.025) * h)
          ..lineTo(x * w, y * h)
          ..lineTo((x + 0.035) * w, (y + 0.025) * h)
          ..close(),
        fill(const Color(0xFFFFFFFF)),
      );
    }

    // Back hill.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0.64 * h)
        ..quadraticBezierTo(0.3 * w, 0.55 * h, 0.6 * w, 0.62 * h)
        ..quadraticBezierTo(0.85 * w, 0.68 * h, w, 0.6 * h)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      fill(const Color(0xFF9BE08F)),
    );

    // Castle (centre).
    const wall = Color(0xFFF6E7C8);
    const wallShade = Color(0xFFE6CFA3);
    const roofA = Color(0xFFFF7A6B);
    const roofB = Color(0xFFA98BE0);
    const window = Color(0xFF0E7C93);
    void tower(
      double cx,
      double top,
      double bottom,
      double tw,
      Color roof, {
      bool flag = false,
    }) {
      final r = Rect.fromLTRB(
        (cx - tw / 2) * w,
        top * h,
        (cx + tw / 2) * w,
        bottom * h,
      );
      canvas.drawRect(r, fill(wall));
      canvas.drawRect(
        Rect.fromLTRB(r.right - r.width * 0.25, r.top, r.right, r.bottom),
        fill(wallShade),
      );
      final roofTop = top - tw * 1.25;
      canvas.drawPath(
        Path()
          ..moveTo(r.left - tw * 0.12 * w, r.top)
          ..lineTo(cx * w, roofTop * h)
          ..lineTo(r.right + tw * 0.12 * w, r.top)
          ..close(),
        fill(roof),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx * w, (top + 0.05) * h),
            width: tw * 0.32 * w,
            height: 0.045 * h,
          ),
          Radius.circular(tw * 0.16 * w),
        ),
        fill(window),
      );
      if (flag) {
        final pole = Offset(cx * w, roofTop * h);
        canvas.drawLine(
          pole,
          pole.translate(0, -0.05 * h),
          Paint()
            ..color = const Color(0xFF8A6A45)
            ..strokeWidth = 0.004 * w,
        );
        canvas.drawPath(
          Path()
            ..moveTo(pole.dx, pole.dy - 0.05 * h)
            ..lineTo(pole.dx + 0.045 * w, pole.dy - 0.04 * h)
            ..lineTo(pole.dx, pole.dy - 0.03 * h)
            ..close(),
          fill(const Color(0xFFFFC845)),
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTRB(0.34 * w, 0.5 * h, 0.66 * w, 0.72 * h),
      fill(wall),
    );
    // Battlements.
    for (var i = 0; i < 8; i++) {
      canvas.drawRect(
        Rect.fromLTWH((0.34 + i * 0.04) * w, 0.48 * h, 0.022 * w, 0.025 * h),
        fill(wall),
      );
    }
    tower(0.34, 0.38, 0.72, 0.09, roofA, flag: true);
    tower(0.66, 0.38, 0.72, 0.09, roofB, flag: true);
    tower(0.5, 0.3, 0.52, 0.1, roofA, flag: true);
    // Gate.
    final gate = Rect.fromLTRB(0.46 * w, 0.6 * h, 0.54 * w, 0.72 * h);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        gate,
        topLeft: Radius.circular(0.04 * w),
        topRight: Radius.circular(0.04 * w),
      ),
      fill(const Color(0xFFB5814A)),
    );
    for (final x in const [0.4, 0.6]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: at(x, 0.58),
            width: 0.03 * w,
            height: 0.05 * h,
          ),
          Radius.circular(0.015 * w),
        ),
        fill(window),
      );
    }

    // Front hill.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0.74 * h)
        ..quadraticBezierTo(0.25 * w, 0.68 * h, 0.5 * w, 0.72 * h)
        ..quadraticBezierTo(0.8 * w, 0.76 * h, w, 0.7 * h)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      fill(const Color(0xFF6CC56E)),
    );

    // Winding path from the gate.
    canvas.drawPath(
      Path()
        ..moveTo(0.47 * w, 0.72 * h)
        ..cubicTo(0.44 * w, 0.8 * h, 0.6 * w, 0.84 * h, 0.5 * w, 0.92 * h)
        ..quadraticBezierTo(0.44 * w, 0.97 * h, 0.42 * w, h)
        ..lineTo(0.6 * w, h)
        ..quadraticBezierTo(0.62 * w, 0.95 * h, 0.66 * w, 0.9 * h)
        ..cubicTo(0.74 * w, 0.82 * h, 0.53 * w, 0.79 * h, 0.53 * w, 0.72 * h)
        ..close(),
      fill(const Color(0xFFF4DDA6)),
    );

    // Trees.
    void tree(double x, double y, double s, Color leaves) {
      canvas.drawRect(
        Rect.fromCenter(
          center: at(x, y + s * 0.9),
          width: s * 0.25 * w,
          height: s * 0.9 * h,
        ),
        fill(const Color(0xFF9A6B3F)),
      );
      canvas.drawCircle(at(x, y), s * 0.55 * w, fill(leaves));
      canvas.drawCircle(
        at(x - s * 0.3, y + s * 0.2),
        s * 0.4 * w,
        fill(leaves),
      );
      canvas.drawCircle(
        at(x + s * 0.3, y + s * 0.15),
        s * 0.42 * w,
        fill(leaves),
      );
      canvas.drawCircle(
        at(x - s * 0.12, y - s * 0.15),
        s * 0.18 * w,
        fill(const Color(0x40FFFFFF)),
      );
    }

    tree(0.12, 0.6, 0.13, const Color(0xFF3FA65A));
    tree(0.86, 0.6, 0.11, const Color(0xFF4DB86A));
    tree(0.95, 0.66, 0.08, const Color(0xFF3FA65A));

    // Pond (bottom right) with a lily pad.
    canvas.drawOval(
      Rect.fromCenter(center: at(0.84, 0.9), width: 0.26 * w, height: 0.1 * h),
      fill(const Color(0xFF6FD0F0)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: at(0.8, 0.885), width: 0.1 * w, height: 0.02 * h),
      fill(const Color(0x88FFFFFF)),
    );
    canvas.drawCircle(at(0.9, 0.91), 0.018 * w, fill(const Color(0xFF3FA65A)));
    canvas.drawCircle(at(0.9, 0.905), 0.007 * w, fill(const Color(0xFFFF9FB2)));

    // Fence (lower right, above the pond).
    final fence = fill(const Color(0xFFFFFBF2));
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH((0.74 + i * 0.05) * w, 0.74 * h, 0.014 * w, 0.07 * h),
        fence,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0.73 * w, 0.76 * h, 0.27 * w, 0.01 * h),
      fence,
    );
    canvas.drawRect(
      Rect.fromLTWH(0.73 * w, 0.79 * h, 0.27 * w, 0.01 * h),
      fence,
    );

    // Mushroom (lower left).
    canvas.drawRect(
      Rect.fromCenter(center: at(0.2, 0.92), width: 0.02 * w, height: 0.04 * h),
      fill(const Color(0xFFFFFBF2)),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: at(0.2, 0.905),
        width: 0.07 * w,
        height: 0.05 * h,
      ),
      math.pi,
      math.pi,
      true,
      fill(const Color(0xFFFF5A4E)),
    );
    canvas.drawCircle(
      at(0.19, 0.893),
      0.006 * w,
      fill(const Color(0xFFFFFFFF)),
    );
    canvas.drawCircle(
      at(0.21, 0.888),
      0.005 * w,
      fill(const Color(0xFFFFFFFF)),
    );

    // Flowers (deterministic), mostly in the bottom-left meadow.
    final rnd = math.Random(5);
    const petals = [
      Color(0xFFFF7A6B),
      Color(0xFFFFC845),
      Color(0xFFA98BE0),
      Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * 0.36 + 0.02;
      final y = 0.8 + rnd.nextDouble() * 0.18;
      final c = at(x, y);
      final r = (0.006 + rnd.nextDouble() * 0.004) * w;
      final col = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r,
          r * 0.8,
          fill(col),
        );
      }
      canvas.drawCircle(c, r * 0.6, fill(const Color(0xFFFFD447)));
    }

    // Butterflies (centre-left meadow and right of the castle).
    void butterfly(double x, double y, Color c) {
      final b = at(x, y);
      final s = 0.014 * w;
      canvas.drawOval(
        Rect.fromCenter(
          center: b.translate(-s, -s * 0.3),
          width: s * 1.6,
          height: s * 1.2,
        ),
        fill(c),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: b.translate(s, -s * 0.3),
          width: s * 1.6,
          height: s * 1.2,
        ),
        fill(c),
      );
      canvas.drawLine(
        b.translate(0, -s),
        b.translate(0, s),
        Paint()
          ..color = const Color(0xFF2B3A55)
          ..strokeWidth = s * 0.25,
      );
    }

    butterfly(0.3, 0.8, const Color(0xFFA98BE0));
    butterfly(0.78, 0.6, const Color(0xFFFF7A6B));
  }
}

/// Paints the [src] region of [artwork] (source units) into [dst] with a
/// uniform scale. [dst] must have the same aspect ratio as [src]; the board
/// layout guarantees this, so tiles are never stretched.
void paintTile(Canvas canvas, PuzzleArtwork artwork, Rect dst, Rect src) {
  final scale = dst.width / src.width;
  assert(
    (dst.height / src.height - scale).abs() < 1e-6 * scale + 1e-9,
    'tile would be stretched',
  );
  canvas.save();
  canvas.clipRect(dst);
  canvas.translate(dst.left - src.left * scale, dst.top - src.top * scale);
  canvas.scale(scale);
  artwork.paint(canvas, artwork.sourceSize);
  canvas.restore();
}
