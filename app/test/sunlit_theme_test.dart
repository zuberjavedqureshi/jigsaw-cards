import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/ui/sunlit_theme.dart';
import 'package:material_ui/material_ui.dart';

import 'puzzle_test_harness.dart';

void main() {
  group('palette tokens match the approved Sunlit Storybook values', () {
    test('values', () {
      expect(Sunlit.sky, const Color(0xFFBFE8FF));
      expect(Sunlit.cream, const Color(0xFFFFF4D6));
      expect(Sunlit.surface, const Color(0xFFFFFBF2));
      expect(Sunlit.parchment, const Color(0xFFF6EAD0));
      expect(Sunlit.ink, const Color(0xFF2B3A55));
      expect(Sunlit.primary, const Color(0xFF19B3D1));
      expect(Sunlit.deepTeal, const Color(0xFF0E7C93));
      expect(Sunlit.sunflower, const Color(0xFFFFC845));
      expect(Sunlit.coral, const Color(0xFFFF7A6B));
      expect(Sunlit.leaf, const Color(0xFF5CC27A));
      expect(Sunlit.lavender, const Color(0xFFA98BE0));
      expect(Sunlit.frame, const Color(0xFFE8C48A));
      expect(Sunlit.frameEdge, const Color(0xFFC8964F));
      expect(Sunlit.boardBed, const Color(0xFFEAF4FA));
    });
  });

  group('every text pairing in use meets WCAG AA (4.5:1)', () {
    final pairs = <String, (Color, Color)>{
      'ink on surface (cards, header chip)': (Sunlit.ink, Sunlit.surface),
      'header text on backdrop': (Sunlit.onBackdrop, Sunlit.backdrop),
      'header text over a lattice line': (
        Sunlit.onBackdrop,
        Sunlit.backdropLine,
      ),
      'ink on parchment': (Sunlit.ink, Sunlit.parchment),
      'deep teal on surface (progress)': (Sunlit.deepTeal, Sunlit.surface),
      'white on deep teal (filled buttons)': (Colors.white, Sunlit.deepTeal),
      'ink on sunflower': (Sunlit.ink, Sunlit.sunflower),
      'ink on primary turquoise': (Sunlit.ink, Sunlit.primary),
    };
    pairs.forEach((name, p) {
      test(name, () {
        expect(Sunlit.contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5));
      });
    });

    test('white text on turquoise or coral is (correctly) not allowed', () {
      expect(Sunlit.contrast(Colors.white, Sunlit.primary), lessThan(4.5));
      expect(Sunlit.contrast(Colors.white, Sunlit.coral), lessThan(4.5));
    });
  });

  test('theme: filled buttons are deep teal with white text', () {
    final t = Sunlit.theme();
    final style = t.filledButtonTheme.style!;
    expect(style.backgroundColor!.resolve({}), Sunlit.deepTeal);
    expect(style.foregroundColor!.resolve({}), Colors.white);
    expect(t.colorScheme.onSurface, Sunlit.ink);
  });

  test(
    'backdrop: rich violet, tone-on-tone pattern, board frame stands out',
    () {
      expect(Sunlit.backdrop, const Color(0xFF7543EE));
      expect(Sunlit.backdropLine, const Color(0xFF6531DE));
      expect(Sunlit.backdropMotif, const Color(0xFF6633DD));
      // Rich and saturated, not washed out.
      final hsl = HSLColor.fromColor(Sunlit.backdrop);
      expect(hsl.saturation, greaterThan(0.6));
      expect(hsl.hue, inInclusiveRange(250, 275), reason: 'violet');
      // Pattern: subtle but clearly visible, darker than the base.
      for (final c in [Sunlit.backdropLine, Sunlit.backdropMotif]) {
        final k = Sunlit.contrast(c, Sunlit.backdrop);
        expect(k, inInclusiveRange(1.1, 1.5));
        expect(
          c.computeLuminance(),
          lessThan(Sunlit.backdrop.computeLuminance()),
        );
      }
      // The light frame separates the board from the backdrop.
      expect(Sunlit.contrast(Sunlit.frame, Sunlit.backdrop), greaterThan(3));
    },
  );

  test('pattern geometry matches the reference scale', () {
    const p = BackdropPatternPainter();
    expect(p.diamondWidth, 122);
    expect(p.diamondHeight, 133);
    expect(p.lineWidth, closeTo(3.4, 1e-9));
  });

  testWidgets('the puzzle screen uses the patterned violet backdrop', (
    tester,
  ) async {
    await pumpPuzzle(tester);
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('sunlit_background')),
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, Sunlit.backdrop);
    expect(deco.gradient, isNull, reason: 'flat base, no gradient');
    final pattern = find.byKey(const Key('backdrop_pattern'));
    expect(
      tester.widget<CustomPaint>(pattern).painter,
      isA<BackdropPatternPainter>(),
    );
    // The pattern covers the whole screen, behind and around the board.
    expect(
      tester.getSize(pattern),
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    final title = tester.widget<Text>(find.byKey(const Key('title')));
    // World Journey (W1): the header names the world; the picture is
    // still Sunny Castle.
    expect(title.data, 'Sunny Meadows');
    expect(title.style!.color, Sunlit.onBackdrop);
    final hint = tester.widget<Text>(find.byKey(const Key('hint')));
    expect(hint.style!.color, Sunlit.onBackdrop);
  });
}
