import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/ui/play_area_layout.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// Layout and hit-testing of 4×4 and 5×5 boards on the real play area of
/// representative phones (W2). The board geometry is unchanged; only the
/// cell count differs.
void main() {
  const screens = [
    Size(320, 568),
    Size(360, 800),
    Size(393, 873),
    Size(412, 915),
    Size(800, 1280),
  ];
  const square = Size(1024, 1024);

  for (final screen in screens) {
    testWidgets('${screen.width.toInt()}×${screen.height.toInt()}: 4×4 and '
        '5×5 fit, centred, square, and hit-test exactly', (tester) async {
      final h = await pumpPuzzle(tester, size: screen);
      final area = h.gameSize;
      for (final n in [4, 5]) {
        final l = BoardLayout.compute(area, GridSize(n, n), square);
        // Inside the play area with the approved margins, centred.
        final left = l.frame.left, right = area.width - l.frame.right;
        expect(left, greaterThanOrEqualTo(20 - 1e-6));
        expect(left, closeTo(right, 1e-6));
        expect(l.frame.top, greaterThanOrEqualTo(16 - 1e-6));
        expect(l.frame.bottom, lessThanOrEqualTo(area.height - 24 + 1e-6));
        // Square cells that tile the board exactly (no clipping/overlap).
        expect(l.cellWidth, closeTo(l.cellHeight, 1e-9));
        expect(l.cellWidth * n, closeTo(l.board.width, 1e-9));
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < n; c++) {
            final rect = l.cellRect(GridCell(r, c));
            expect(l.board.contains(rect.center), isTrue);
            // Centre, and points 1 dp inside each edge, hit this cell.
            for (final p in [
              rect.center,
              rect.topLeft + const Offset(1, 1),
              rect.bottomRight - const Offset(1, 1),
            ]) {
              expect(l.cellAt(p), GridCell(r, c));
            }
          }
        }
        // Just outside the board: no cell (drops there cancel).
        for (final p in [
          l.board.topLeft - const Offset(1, 1),
          l.board.bottomRight + const Offset(1, 1),
          Offset(l.board.center.dx, l.board.bottom + 1),
          Offset(l.board.left - 1, l.board.center.dy),
        ]) {
          expect(l.cellAt(p), isNull);
        }
        // ignore: avoid_print
        print(
          'MEASURE ${screen.width.toInt()}x${screen.height.toInt()} '
          'play ${area.width.toStringAsFixed(0)}x'
          '${area.height.toStringAsFixed(0)} ${n}x$n: board '
          '${l.board.width.toStringAsFixed(1)} dp, tile '
          '${l.cellWidth.toStringAsFixed(1)} dp',
        );
      }
      // The board itself does not depend on the cell count.
      final four = BoardLayout.compute(area, GridSize(4, 4), square);
      final five = BoardLayout.compute(area, GridSize(5, 5), square);
      expect(five.board, four.board);
      expect(five.frame, four.frame);
    });
  }
}
