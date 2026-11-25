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

/// The size of a logical grid. Immutable, with no rendering or layout concerns.
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

  @override
  String toString() => '${rows}x$columns';
}
