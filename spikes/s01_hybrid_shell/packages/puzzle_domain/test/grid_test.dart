import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GridSize', () {
    test('4x4 has 16 cells', () {
      expect(GridSize(4, 4).cellCount, 16);
    });

    test('rejects non-positive dimensions', () {
      expect(() => GridSize(0, 4), throwsArgumentError);
      expect(() => GridSize(4, -1), throwsArgumentError);
    });

    test('contains only in-bounds cells', () {
      final grid = GridSize(4, 4);
      expect(grid.contains(const GridCell(0, 0)), isTrue);
      expect(grid.contains(const GridCell(3, 3)), isTrue);
      expect(grid.contains(const GridCell(4, 0)), isFalse);
      expect(grid.contains(const GridCell(0, -1)), isFalse);
    });

    test('cellAt is row-major and range-checked', () {
      final grid = GridSize(4, 4);
      expect(grid.cellAt(0), const GridCell(0, 0));
      expect(grid.cellAt(5), const GridCell(1, 1));
      expect(grid.cellAt(15), const GridCell(3, 3));
      expect(() => grid.cellAt(16), throwsRangeError);
    });
  });

  test('GridCell has value equality', () {
    expect(const GridCell(1, 2), const GridCell(1, 2));
    expect(const GridCell(1, 2).hashCode, const GridCell(1, 2).hashCode);
  });
}
