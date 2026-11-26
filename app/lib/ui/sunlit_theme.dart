import 'package:material_ui/material_ui.dart';

/// Sunlit Storybook design tokens (PRD VI-06; VISUAL_IDENTITY §2a,
/// approved 2026-11-26). Every screen and the board use these tokens
/// instead of ad-hoc colours.
///
/// Text pairings must meet WCAG AA (4.5:1). White text is only used on
/// [deepTeal]; [primary] and [coral] carry text only in [ink].
abstract final class Sunlit {
  // Backgrounds
  static const sky = Color(0xFFBFE8FF);
  static const cream = Color(0xFFFFF4D6);

  /// Gameplay backdrop (M3.1 refinement): a rich, flat storybook violet
  /// with a tone-on-tone diamond lattice and four-petal motifs.
  static const backdrop = Color(0xFF7543EE);

  /// Lattice lines: a slightly deeper violet (≈1.24:1 against [backdrop]),
  /// subtle but clearly visible.
  static const backdropLine = Color(0xFF6531DE);

  /// Four-petal motifs, same family as the lines.
  static const backdropMotif = Color(0xFF6633DD);

  /// Text drawn directly on the backdrop (5.36:1 on [backdrop]).
  static const onBackdrop = Color(0xFFFFFBF2);

  // Surfaces
  static const surface = Color(0xFFFFFBF2);
  static const parchment = Color(0xFFF6EAD0);

  // Text
  static const ink = Color(0xFF2B3A55);

  // Brand and accents
  static const primary = Color(0xFF19B3D1);
  static const deepTeal = Color(0xFF0E7C93);
  static const sunflower = Color(0xFFFFC845);
  static const coral = Color(0xFFFF7A6B);
  static const leaf = Color(0xFF5CC27A);
  static const lavender = Color(0xFFA98BE0);

  // Board
  static const frame = Color(0xFFE8C48A);
  static const frameEdge = Color(0xFFC8964F);
  static const boardBed = Color(0xFFEAF4FA);

  /// Soft shadow used under raised surfaces.
  static const shadow = Color(0x332B3A55);

  /// Light ink-tinted scrim behind dialogs (never black).
  static const scrim = Color(0x592B3A55);

  /// WCAG relative-luminance contrast ratio between two opaque colours.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: deepTeal,
      onPrimary: Colors.white,
      secondary: sunflower,
      onSecondary: ink,
      surface: surface,
      onSurface: ink,
      error: const Color(0xFFC2412F),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      fontFamily: 'serif',
      textTheme: const TextTheme().apply(bodyColor: ink, displayColor: ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(180, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Storybook backdrop: a flat, rich violet covered edge to edge by a
/// tone-on-tone diagonal diamond lattice with a small four-petal flower at
/// the centre of every diamond. Drawn in code (no image assets).
class SunlitBackground extends StatelessWidget {
  const SunlitBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('sunlit_background'),
      decoration: const BoxDecoration(color: Sunlit.backdrop),
      child: CustomPaint(
        key: const Key('backdrop_pattern'),
        painter: const BackdropPatternPainter(),
        child: child,
      ),
    );
  }
}

/// Diagonal diamond lattice with four-petal motifs at the diamond centres.
///
/// Geometry (logical pixels, the same on every screen): diamonds are
/// [diamondWidth] wide and [diamondHeight] tall, lines are [lineWidth]
/// thick, and the lattice is centred horizontally so the pattern is
/// symmetric. It covers the whole canvas, behind and around the board.
class BackdropPatternPainter extends CustomPainter {
  const BackdropPatternPainter({
    this.diamondWidth = 122,
    this.diamondHeight = 133,
    this.lineWidth = 3.4,
    this.line = Sunlit.backdropLine,
    this.motif = Sunlit.backdropMotif,
  });

  final double diamondWidth;
  final double diamondHeight;
  final double lineWidth;
  final Color line;
  final Color motif;

  @override
  void paint(Canvas canvas, Size size) {
    final w = diamondWidth;
    final h = diamondHeight;
    final cx = size.width / 2;
    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;
    // Each line rises w/2 horizontally per h/2 vertically. Lines of both
    // families pass through (cx + k·w, 0); extend them past the canvas.
    final slope = w / h; // dx per dy
    final yTop = -h;
    final yBottom = size.height + h;
    final kMin = ((-cx - size.height * slope) / w).floor() - 1;
    final kMax = ((size.width - cx + size.height * slope) / w).ceil() + 1;
    for (var k = kMin; k <= kMax; k++) {
      final x0 = cx + k * w;
      canvas.drawLine(
        Offset(x0 + yTop * slope, yTop),
        Offset(x0 + yBottom * slope, yBottom),
        linePaint,
      );
      canvas.drawLine(
        Offset(x0 - yTop * slope, yTop),
        Offset(x0 - yBottom * slope, yBottom),
        linePaint,
      );
    }
    // Motifs at diamond centres: (cx + k·w + w/2, j·h) and
    // (cx + k·w, j·h + h/2).
    final motifPaint = Paint()..color = motif;
    final rows = (size.height / h).ceil() + 1;
    final cols = (size.width / w).ceil() + 2;
    for (var j = -1; j <= rows; j++) {
      for (var k = -cols; k <= cols; k++) {
        _flower(canvas, Offset(cx + k * w + w / 2, j * h), motifPaint);
        _flower(canvas, Offset(cx + k * w, j * h + h / 2), motifPaint);
      }
    }
  }

  /// Four slim oval petals pointing up, down, left and right, with a small
  /// gap at the centre (about 34 × 34 logical pixels overall).
  void _flower(Canvas canvas, Offset c, Paint paint) {
    const length = 13.0;
    const width = 7.0;
    const offset = 10.5; // petal centre distance from the flower centre
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, -offset),
        width: width,
        height: length,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, offset),
        width: width,
        height: length,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-offset, 0),
        width: length,
        height: width,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(offset, 0),
        width: length,
        height: width,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(BackdropPatternPainter oldDelegate) =>
      oldDelegate.diamondWidth != diamondWidth ||
      oldDelegate.diamondHeight != diamondHeight ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.line != line ||
      oldDelegate.motif != motif;
}
