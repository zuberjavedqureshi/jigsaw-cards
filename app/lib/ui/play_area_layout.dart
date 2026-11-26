import 'dart:math' as math;
import 'dart:ui';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Screen geometry of the picture board inside the play area (PRD GP-35,
/// GP-38). All spacing is measured to the **outer edge of the board
/// frame**:
///
/// * horizontal margin of [minSideMargin]–[maxSideMargin] dp, scaling with
///   the width ([sideMarginFraction]);
/// * at least [minTopGap] dp below the header and [minBottomGap] dp above
///   the bottom of the (safe-area) play area, with the frame centred
///   vertically between them;
/// * the frame is at most [maxFrameWidth] dp wide on large screens.
///
/// Margins are wider than [maxSideMargin] only when the board is capped by
/// [maxFrameWidth] or limited by the available height; they are never below
/// [minSideMargin]. The board keeps the source illustration's aspect ratio,
/// so tiles are never stretched or clipped.
class BoardLayout {
  const BoardLayout._(this.frame, this.board, this.grid);

  static const minSideMargin = 20.0;
  static const maxSideMargin = 32.0;
  static const sideMarginFraction = 0.06;
  static const minTopGap = 16.0;
  static const minBottomGap = 24.0;
  static const maxFrameWidth = 560.0;

  /// Frame thickness for a frame of outer width [outerWidth].
  static double frameThicknessFor(double outerWidth) =>
      (outerWidth * 0.025).clamp(6.0, 12.0);

  /// Horizontal margin for a play area of [width].
  static double sideMarginFor(double width) =>
      (width * sideMarginFraction).clamp(minSideMargin, maxSideMargin);

  /// Outer rect of the board frame, in play-area (game) coordinates.
  final Rect frame;

  /// Rect of the tiles (inside the frame), in play-area coordinates.
  final Rect board;
  final GridSize grid;

  double get frameThickness => board.left - frame.left;
  double get cellWidth => board.width / grid.columns;
  double get cellHeight => board.height / grid.rows;

  static BoardLayout compute(Size size, GridSize grid, Size sourceSize) {
    final aspect = sourceSize.width / sourceSize.height;
    final side = sideMarginFor(size.width);
    final availW = math.max(
      0.0,
      math.min(size.width - 2 * side, maxFrameWidth),
    );
    final availH = math.max(0.0, size.height - minTopGap - minBottomGap);

    // Width-limited first; fall back to height-limited.
    var outerW = availW;
    var t = frameThicknessFor(outerW);
    var boardW = math.max(0.0, outerW - 2 * t);
    var boardH = boardW / aspect;
    if (boardH + 2 * t > availH) {
      // Solve for the height (thickness depends on width; iterate twice).
      for (var i = 0; i < 2; i++) {
        boardH = math.max(0.0, availH - 2 * t);
        boardW = boardH * aspect;
        outerW = boardW + 2 * t;
        t = frameThicknessFor(outerW);
      }
      boardH = math.max(0.0, availH - 2 * t);
      boardW = boardH * aspect;
      outerW = boardW + 2 * t;
    }
    final outerH = boardH + 2 * t;
    final left = (size.width - outerW) / 2;
    final top = minTopGap + (availH - outerH) / 2;
    final frame = Rect.fromLTWH(left, top, outerW, outerH);
    return BoardLayout._(frame, frame.deflate(t), grid);
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
