import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final grid = GridSize(4, 4);
  const generator = ProvisionalRandomFillGenerator();
  final constraints = LayoutConstraints.prototype;

  PuzzleLayout gen(int seed) =>
      generator.generate(grid: grid, constraints: constraints, seed: seed);

  test('500 seeds: every layout tiles the board exactly with valid pieces', () {
    for (var seed = 0; seed < 500; seed++) {
      final layout = gen(seed);
      expect(
        validateLayout(grid, layout.pieces, constraints),
        isEmpty,
        reason: 'seed $seed',
      );
      expect(
        layout.pieces.length,
        inInclusiveRange(8, 12),
        reason: 'seed $seed',
      );
      final covered = [for (final p in layout.pieces) ...p.correctCells];
      expect(covered.toSet(), grid.cells.toSet(), reason: 'seed $seed');
      expect(covered, hasLength(16), reason: 'no overlaps, seed $seed');
      for (final p in layout.pieces) {
        expect(constraints.allowedSizes, contains(p.size));
      }
    }
  });

  test('same seed produces the same layout', () {
    for (final seed in [0, 1, 42, 2026, -7]) {
      expect(gen(seed).pieces, gen(seed).pieces, reason: 'seed $seed');
    }
  });

  test('different seeds produce varied layouts using every allowed size', () {
    final distinct = <String>{};
    final sizes = <PieceSize>{};
    for (var seed = 0; seed < 100; seed++) {
      final pieces = gen(seed).pieces;
      distinct.add(pieces.map((p) => '${p.correctOrigin}${p.size}').join());
      sizes.addAll(pieces.map((p) => p.size));
    }
    expect(distinct.length, greaterThan(50));
    expect(sizes, constraints.allowedSizes);
  });

  test(
    'impossible constraints fail loudly instead of returning a bad layout',
    () {
      final impossible = LayoutConstraints(
        allowedSizes: {PieceSize.oneByOne, PieceSize.twoByTwo},
        minPieces: 17,
        maxPieces: 20,
      );
      expect(
        () =>
            const ProvisionalRandomFillGenerator(maxAttempts: 50)
                .generate(grid: grid, constraints: impossible, seed: 1),
        throwsStateError,
      );
    },
  );
}
