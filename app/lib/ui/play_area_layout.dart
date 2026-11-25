import 'dart:math' as math;
import 'dart:ui';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Screen geometry of the picture board inside the play area. The board
/// keeps the source illustration's aspect ratio and is as large as fits
/// with a margin, so tiles are never stretched or clipped.
class BoardLayout {
  const BoardLayout._(this.board, this.grid);

  static const margin = 16.0;

  /// Board rect in play-area (game) coordinates.
  final Rect board;
  final GridSize grid;

  double get cellWidth => board.width / grid.columns;
  double get cellHeight => board.height / grid.rows;

  static BoardLayout compute(Size size, GridSize grid, Size sourceSize) {
    final availW = math.max(0.0, size.width - 2 * margin);
    final availH = math.max(0.0, size.height - 2 * margin);
    final aspect = sourceSize.width / sourceSize.height;
    var w = availW;
    var h = w / aspect;
    if (h > availH) {
      h = availH;
      w = h * aspect;
    }
    return BoardLayout._(
      Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h),
      grid,
    );
  }

  Rect cellRect(GridCell c) => Rect.fromLTWH(
    board.left + c.column * cellWidth,
    board.top + c.row * cellHeight,
    cellWidth,
    cellHeight,
  );

  /// The cell under [p], or null outside the board.
  GridCell? cellAt(Offset p) {
    if (!board.contains(p)) return null;
    final col = ((p.dx - board.left) / cellWidth).floor();
    final row = ((p.dy - board.top) / cellHeight).floor();
    return GridCell(
      row.clamp(0, grid.rows - 1),
      col.clamp(0, grid.columns - 1),
    );
  }
}
