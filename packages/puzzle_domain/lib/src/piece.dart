import 'grid.dart';

/// Size of a rectangular piece in cells. No rotation: a 1×2 piece and a
/// 2×1 piece are different sizes.
final class PieceSize {
  const PieceSize(this.rowSpan, this.columnSpan);

  final int rowSpan;
  final int columnSpan;

  int get cellCount => rowSpan * columnSpan;

  static const oneByOne = PieceSize(1, 1);
  static const oneByTwo = PieceSize(1, 2);
  static const twoByOne = PieceSize(2, 1);
  static const twoByTwo = PieceSize(2, 2);

  @override
  bool operator ==(Object other) =>
      other is PieceSize &&
      other.rowSpan == rowSpan &&
      other.columnSpan == columnSpan;

  @override
  int get hashCode => Object.hash(rowSpan, columnSpan);

  @override
  String toString() => '$rowSpan×$columnSpan';
}

/// A rectangular puzzle piece and its correct position on the board.
///
/// The image region a piece shows is derived from [correctOrigin] and [size]
/// (PUZZLE_ENGINE §4), so no separate image coordinates are stored.
final class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.correctOrigin,
    required this.size,
  });

  final String id;

  /// Top-left cell of the piece's correct position.
  final GridCell correctOrigin;
  final PieceSize size;

  /// Cells this piece covers when its top-left cell is at [origin].
  Iterable<GridCell> cellsAt(GridCell origin) sync* {
    for (var r = 0; r < size.rowSpan; r++) {
      for (var c = 0; c < size.columnSpan; c++) {
        yield GridCell(origin.row + r, origin.column + c);
      }
    }
  }

  /// Cells covered at the correct position.
  Iterable<GridCell> get correctCells => cellsAt(correctOrigin);

  @override
  bool operator ==(Object other) =>
      other is PuzzlePiece &&
      other.id == id &&
      other.correctOrigin == correctOrigin &&
      other.size == size;

  @override
  int get hashCode => Object.hash(id, correctOrigin, size);

  @override
  String toString() => 'PuzzlePiece($id, $correctOrigin, $size)';
}
