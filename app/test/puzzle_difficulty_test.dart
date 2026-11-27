import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_difficulty.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

void main() {
  test('exactly two difficulties: Normal 4×4 and Hard 5×5', () {
    expect(PuzzleDifficulty.values, [
      PuzzleDifficulty.normal,
      PuzzleDifficulty.hard,
    ]);
    expect(PuzzleDifficulty.normal.grid, GridSize(4, 4));
    expect(PuzzleDifficulty.hard.grid, GridSize(5, 5));
  });

  test('labels', () {
    expect(PuzzleDifficulty.normal.label, 'Normal');
    expect(PuzzleDifficulty.hard.label, 'Hard');
  });

  test('grids are square and derived from the size', () {
    for (final d in PuzzleDifficulty.values) {
      expect(d.grid.rows, d.size);
      expect(d.grid.columns, d.size);
    }
    expect(PuzzleDifficulty.values.map((d) => d.size), isNot(contains(6)));
  });
}
