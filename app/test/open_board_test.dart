import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/board_style.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/ui/play_area_layout.dart';
import 'package:jigsaw_cards/ui/sunlit_theme.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// W3 open board: only what the board frame draws changed. The logical
/// board, cells and touch area still come from the unchanged BoardLayout.
void main() {
  const style = BoardStyle.sunlit;

  group('visual tokens', () {
    test('thin outline (~2 dp) with gently rounded corners (4–6 dp)', () {
      expect(style.outlineWidth, closeTo(2, 0.01));
      expect(style.cornerRadius, inInclusiveRange(4, 6));
    });

    test('the bed is translucent but nearly opaque (hides the backdrop)', () {
      expect(style.bed.a, inExclusiveRange(0.9, 1.0));
      // Same pale blue as the approved bed token.
      expect(style.bed.withValues(alpha: 1), Sunlit.boardBed);
    });

    test('the outline is a light surface tone, not honey wood', () {
      expect(style.outline.withValues(alpha: 1), Sunlit.surface);
      expect(Sunlit.contrast(Sunlit.surface, Sunlit.backdrop), greaterThan(3));
    });
  });

  group('frame geometry follows the unchanged layout', () {
    for (final size in const [Size(412, 915), Size(320, 568)]) {
      testWidgets('${size.width.toInt()}×${size.height.toInt()}: the bed is '
          'exactly the logical board; the outline adds 2 dp', (tester) async {
        final h = await pumpPuzzle(tester, size: size);
        final area = h.game.area;
        final frame = h.game.frame;
        // The component still spans the layout's frame rect.
        // (Flame vectors are float32.)
        expect(frame.position.x, closeTo(area.frame.left, 1e-3));
        expect(frame.position.y, closeTo(area.frame.top, 1e-3));
        expect(frame.size.x, closeTo(area.frame.width, 1e-3));
        expect(frame.size.y, closeTo(area.frame.height, 1e-3));
        final origin = frame.position.toOffset();
        Rect toGame(Rect r) => r.shift(origin);
        expect(toGame(frame.boardRect), _closeRect(area.board));
        expect(toGame(frame.bedRRect.outerRect), _closeRect(area.board));
        expect(
          toGame(frame.outlineRRect.outerRect),
          _closeRect(area.board.inflate(2)),
        );
        expect(frame.outlineRRect.tlRadiusX, style.cornerRadius);
        // The visible edge is inside the layout's frame band: the margins
        // to the screen edges only grow visually.
        expect(
          frame.outlineRRect.outerRect.left,
          greaterThan(0),
          reason: 'old band partly transparent now',
        );
      });
    }
  });

  group('logical board unchanged (fixtures from W2)', () {
    test('412 dp wide play area: board 344.43 dp, tiles 86.1 / 68.9 dp', () {
      const play = Size(412, 795);
      final four = BoardLayout.compute(
        play,
        GridSize(4, 4),
        const Size(1024, 1024),
      );
      final five = BoardLayout.compute(
        play,
        GridSize(5, 5),
        const Size(1024, 1024),
      );
      expect(four.board.width, closeTo(344.432, 1e-3));
      expect(four.board.left, closeTo(33.784, 1e-3));
      expect(four.cellWidth, closeTo(86.108, 1e-3));
      expect(five.cellWidth, closeTo(68.886, 1e-3));
      expect(five.board, four.board);
      expect(four.frameThickness, closeTo(9.064, 1e-3));
    });

    test('320 dp wide play area: board 266.0 dp, tiles 66.5 / 53.2 dp', () {
      const play = Size(320, 428);
      final four = BoardLayout.compute(
        play,
        GridSize(4, 4),
        const Size(1024, 1024),
      );
      final five = BoardLayout.compute(
        play,
        GridSize(5, 5),
        const Size(1024, 1024),
      );
      expect(four.board.width, closeTo(266.0, 1e-3));
      expect(four.cellWidth, closeTo(66.5, 1e-3));
      expect(five.cellWidth, closeTo(53.2, 1e-3));
    });

    testWidgets('touch: the old frame band and the new transparent margin '
        'are not interactive; cells end exactly at the board edge', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      final a = h.game.area;
      // Inside the (now transparent) band, between frame edge and outline.
      final band = Offset(a.frame.left + 2, a.board.center.dy);
      expect(a.cellAt(band), isNull);
      // On the visible outline (1 dp outside the board): not a cell.
      expect(a.cellAt(Offset(a.board.left - 1, a.board.center.dy)), isNull);
      // 1 dp inside the board: the edge cell, as before.
      expect(
        a.cellAt(Offset(a.board.left + 1, a.board.top + 1)),
        GridCell(0, 0),
      );
      expect(
        a.cellAt(Offset(a.board.right - 1, a.board.bottom - 1)),
        GridCell(3, 3),
      );
    });
  });

  group('drawn pixels', () {
    /// Renders a frame of [outer] × [outer] with [t] layout thickness.
    Future<(ui.Image, BoardFrame)> render(WidgetTester tester) async {
      const outer = 362.56, t = 9.064;
      final frame = BoardFrame(style)
        ..size = Vector2.all(outer)
        ..thickness = t;
      final rec = ui.PictureRecorder();
      frame.render(ui.Canvas(rec));
      final pic = rec.endRecording();
      final img = (await tester.runAsync(
        () => pic.toImage(outer.ceil(), outer.ceil()),
      ))!;
      return (img, frame);
    }

    Future<Color> pixel(WidgetTester tester, ui.Image img, int x, int y) async {
      final bytes = (await tester.runAsync(
        () => img.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
      ))!;
      final i = (y * img.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    testWidgets('no wooden band or highlight ring; thin light outline; bed', (
      tester,
    ) async {
      final (img, frame) = await render(tester);
      final b = frame.boardRect;
      final midY = b.center.dy.round();
      // Old wooden band (outside the outline, left side, away from the
      // shadow's offset): at most a faint shadow, never honey wood.
      final band = await pixel(tester, img, 1, midY);
      expect(band.a, lessThan(0.25), reason: 'transparent band: $band');
      // The old highlight ring sat at ~20 % of the band; nothing opaque
      // there now either.
      final ring = await pixel(tester, img, 2, midY);
      expect(ring.a, lessThan(0.25));
      // On the outline (1 dp outside the board): light surface colour.
      final rim = await pixel(tester, img, (b.left - 1).floor(), midY);
      expect(rim.a, greaterThan(0.8));
      expect(rim.r, greaterThan(0.9));
      expect(rim.g, greaterThan(0.9));
      // Board bed in the middle: pale blue, nearly opaque.
      final bed = await pixel(tester, img, b.center.dx.round(), midY);
      expect(bed.a, greaterThan(0.9));
      expect((bed.b - 0xFA / 255).abs(), lessThan(0.05));
      // A rounded outer corner: the very corner of the outline box is not
      // painted solid.
      final o = frame.outlineRRect.outerRect;
      final corner = await pixel(tester, img, o.left.ceil(), o.top.ceil());
      expect(corner.a, lessThan(0.8), reason: 'rounded corner');
    });
  });
}

Matcher _closeRect(Rect r) => predicate<Rect>(
  (x) =>
      (x.left - r.left).abs() < 1e-3 &&
      (x.top - r.top).abs() < 1e-3 &&
      (x.right - r.right).abs() < 1e-3 &&
      (x.bottom - r.bottom).abs() < 1e-3,
  'rect close to $r',
);
