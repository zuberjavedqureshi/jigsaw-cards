import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  test('4x4 grid has 16 cells in row-major order', () {
    final grid = GridSize(4, 4);
    expect(grid.cellCount, 16);
    expect(grid.cells.first, const GridCell(0, 0));
    expect(grid.cells.last, const GridCell(3, 3));
    expect(grid.cellAt(5), const GridCell(1, 1));
  });

  test('rejects non-positive dimensions', () {
    expect(() => GridSize(0, 4), throwsArgumentError);
  });

  test('contains only in-bounds cells', () {
    final grid = GridSize(4, 4);
    expect(grid.contains(const GridCell(3, 3)), isTrue);
    expect(grid.contains(const GridCell(4, 0)), isFalse);
    expect(grid.contains(const GridCell(0, -1)), isFalse);
  });

  test('value equality', () {
    expect(const GridCell(1, 2), const GridCell(1, 2));
    expect(GridSize(4, 4), GridSize(4, 4));
  });
}
