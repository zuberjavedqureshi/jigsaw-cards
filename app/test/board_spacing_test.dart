import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/ui/play_area_layout.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

void main() {
  final grid = GridSize(4, 4);
  const square = Size(1024, 1024);

  group('BoardLayout (pure)', () {
    test('side margin scales 20–32 dp with width', () {
      expect(BoardLayout.sideMarginFor(300), 20);
      expect(BoardLayout.sideMarginFor(412), closeTo(24.72, 1e-9));
      expect(BoardLayout.sideMarginFor(700), 32);
    });

    test('width-limited phone: margins 20–32 to the frame outer edge', () {
      final l = BoardLayout.compute(const Size(412, 760), grid, square);
      expect(l.frame.left, closeTo(24.72, 1e-6));
      expect(412 - l.frame.right, closeTo(24.72, 1e-6));
      expect(l.frame.top, greaterThanOrEqualTo(BoardLayout.minTopGap));
      expect(760 - l.frame.bottom, greaterThanOrEqualTo(24));
      // Board sits inside the frame by its thickness; square tiles.
      expect(l.board.left - l.frame.left, closeTo(l.frameThickness, 1e-9));
      expect(l.cellWidth, closeTo(l.cellHeight, 1e-9));
    });

    test('large screens cap the frame width and centre it', () {
      final l = BoardLayout.compute(const Size(900, 1400), grid, square);
      expect(l.frame.width, closeTo(BoardLayout.maxFrameWidth, 1e-6));
      expect(l.frame.left, closeTo((900 - 560) / 2, 1e-6));
    });

    test('height-limited: margins only grow, never below 20', () {
      final l = BoardLayout.compute(const Size(412, 300), grid, square);
      expect(l.frame.left, greaterThanOrEqualTo(20));
      expect(l.frame.top, greaterThanOrEqualTo(16 - 1e-9));
      expect(300 - l.frame.bottom, greaterThanOrEqualTo(24 - 1e-9));
      expect(l.cellWidth, closeTo(l.cellHeight, 1e-9));
    });

    test('frame thickness stays in a sensible range', () {
      expect(BoardLayout.frameThicknessFor(200), 6);
      expect(BoardLayout.frameThicknessFor(560), 12);
    });
  });

  group('board spacing on screen (GP-38)', () {
    const cases = <(String, Size, EdgeInsets)>[
      ('320x568', Size(320, 568), EdgeInsets.zero),
      ('360x640 status+nav', Size(360, 640), EdgeInsets.fromLTRB(0, 24, 0, 48)),
      (
        '360x800 gesture nav',
        Size(360, 800),
        EdgeInsets.fromLTRB(0, 32, 0, 24),
      ),
      ('412x915 cutout', Size(412, 915), EdgeInsets.fromLTRB(0, 48, 0, 34)),
      (
        '412x915 side cutout',
        Size(412, 915),
        EdgeInsets.fromLTRB(28, 24, 0, 24),
      ),
      ('480x1000', Size(480, 1000), EdgeInsets.zero),
      ('600x960 tablet', Size(600, 960), EdgeInsets.fromLTRB(0, 24, 0, 24)),
      (
        '800x1280 large tablet',
        Size(800, 1280),
        EdgeInsets.fromLTRB(0, 24, 0, 24),
      ),
    ];
    for (final (name, size, insets) in cases) {
      testWidgets(name, (tester) async {
        tester.view
          ..padding = FakeViewPadding(
            left: insets.left,
            top: insets.top,
            right: insets.right,
            bottom: insets.bottom,
          )
          ..viewPadding = FakeViewPadding(
            left: insets.left,
            top: insets.top,
            right: insets.right,
            bottom: insets.bottom,
          );
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        final h = await pumpPuzzle(tester, size: size);
        expect(tester.takeException(), isNull);
        final box = tester.renderObject<RenderBox>(
          find.byType(GameWidget<PuzzleGame>),
        );
        final area = h.game.area;
        final frame = Rect.fromPoints(
          box.localToGlobal(area.frame.topLeft),
          box.localToGlobal(area.frame.bottomRight),
        );
        final safe = Rect.fromLTRB(
          insets.left,
          insets.top,
          size.width - insets.right,
          size.height - insets.bottom,
        );
        // Never touches or crosses a screen edge or safe-area inset.
        final leftGap = frame.left - safe.left;
        final rightGap = safe.right - frame.right;
        expect(leftGap, greaterThanOrEqualTo(20 - 1e-6));
        expect(rightGap, greaterThanOrEqualTo(20 - 1e-6));
        expect(leftGap, closeTo(rightGap, 1e-6), reason: 'centred');
        final widthLimited =
            area.frame.width < BoardLayout.maxFrameWidth - 1e-6 &&
            area.frame.height <
                box.size.height -
                    BoardLayout.minTopGap -
                    BoardLayout.minBottomGap -
                    1e-6;
        if (widthLimited) {
          expect(leftGap, lessThanOrEqualTo(32 + 1e-6));
        }
        // Vertical breathing room inside the play area.
        expect(area.frame.top, greaterThanOrEqualTo(16 - 1e-6));
        expect(
          box.size.height - area.frame.bottom,
          greaterThanOrEqualTo(24 - 1e-6),
        );
        expect(frame.bottom, lessThanOrEqualTo(safe.bottom));
        expect(frame.top, greaterThanOrEqualTo(safe.top));
        // Comfortable, square, unclipped tiles; 4x4 unchanged.
        expect(area.cellWidth, greaterThanOrEqualTo(64));
        expect(area.cellWidth, closeTo(area.cellHeight, 1e-6));
        expect(h.puzzle.grid, GridSize(4, 4));
      });
    }
  });
}
