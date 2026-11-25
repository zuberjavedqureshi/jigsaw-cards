/// A cell on a logical grid, addressed by row and column from the top-left.
final class GridCell {
  const GridCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'GridCell($row, $column)';
}

/// The size of a logical grid. Purely logical: no pixels or layout.
final class GridSize {
  GridSize(this.rows, this.columns) {
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Grid dimensions must be positive: ${rows}x$columns');
    }
  }

  final int rows;
  final int columns;

  int get cellCount => rows * columns;

  bool contains(GridCell cell) =>
      cell.row >= 0 &&
      cell.row < rows &&
      cell.column >= 0 &&
      cell.column < columns;

  /// Row-major cell for a 0-based [index].
  GridCell cellAt(int index) {
    RangeError.checkValidIndex(index, this, 'index', cellCount);
    return GridCell(index ~/ columns, index % columns);
  }

  /// All cells in row-major order.
  Iterable<GridCell> get cells sync* {
    for (var i = 0; i < cellCount; i++) {
      yield cellAt(i);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GridSize && other.rows == rows && other.columns == columns;

  @override
  int get hashCode => Object.hash(rows, columns);

  @override
  String toString() => '${rows}x$columns';
}
