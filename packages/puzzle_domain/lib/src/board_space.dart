import 'grid.dart';
import 'piece.dart';

/// A point in board space, in **cell units**, relative to the top-left of
/// the logical grid. `x` runs along columns and `y` along rows. Used for a
/// piece's free (continuous) position, which is independent of its correct
/// target cell.
final class BoardPoint {
  const BoardPoint(this.x, this.y);

  /// The board point of a grid cell's top-left corner.
  BoardPoint.ofCell(GridCell cell)
    : x = cell.column.toDouble(),
      y = cell.row.toDouble();

  static const zero = BoardPoint(0, 0);

  final double x;
  final double y;

  BoardPoint operator +(BoardPoint o) => BoardPoint(x + o.x, y + o.y);
  BoardPoint operator -(BoardPoint o) => BoardPoint(x - o.x, y - o.y);

  /// Largest of the horizontal and vertical distances (Chebyshev distance).
  double chebyshevTo(BoardPoint o) {
    final dx = (x - o.x).abs();
    final dy = (y - o.y).abs();
    return dx > dy ? dx : dy;
  }

  @override
  bool operator ==(Object other) =>
      other is BoardPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'BoardPoint($x, $y)';
}

/// The playable workspace in board space (cell units). It contains the
/// logical grid and extends around it, so pieces can be scattered and
/// arranged freely. Pieces always stay fully inside these bounds.
final class PlayBounds {
  PlayBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  }) {
    if (!(right > left && bottom > top)) {
      throw ArgumentError('PlayBounds must have positive size');
    }
  }

  /// Bounds around [grid]: [margin] cells on every side plus [extraBelow]
  /// cells under the grid.
  factory PlayBounds.around(
    GridSize grid, {
    double margin = 0.3,
    double extraBelow = 3.4,
  }) => PlayBounds(
    left: -margin,
    top: -margin,
    right: grid.columns + margin,
    bottom: grid.rows + margin + extraBelow,
  );

  /// Provisional prototype workspace for the 4×4 board: 4.6 × 8.0 cells,
  /// grid at the top, open space below (a presentation choice, not a
  /// product decision).
  static PlayBounds prototype(GridSize grid) => PlayBounds.around(grid);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  /// Clamps a piece's top-left so the whole piece stays inside the bounds.
  BoardPoint clampOrigin(BoardPoint origin, PieceSize size) {
    final maxX = right - size.columnSpan;
    final maxY = bottom - size.rowSpan;
    return BoardPoint(
      origin.x < left ? left : (origin.x > maxX ? maxX : origin.x),
      origin.y < top ? top : (origin.y > maxY ? maxY : origin.y),
    );
  }

  bool containsPiece(BoardPoint origin, PieceSize size) =>
      origin.x >= left &&
      origin.y >= top &&
      origin.x + size.columnSpan <= right &&
      origin.y + size.rowSpan <= bottom;

  @override
  bool operator ==(Object other) =>
      other is PlayBounds &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

/// Area of overlap between two pieces at the given origins (cell units²).
double overlapArea(BoardPoint a, PieceSize sa, BoardPoint b, PieceSize sb) {
  final w = _min(a.x + sa.columnSpan, b.x + sb.columnSpan) - _max(a.x, b.x);
  final h = _min(a.y + sa.rowSpan, b.y + sb.rowSpan) - _max(a.y, b.y);
  return (w > 0 && h > 0) ? w * h : 0;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
