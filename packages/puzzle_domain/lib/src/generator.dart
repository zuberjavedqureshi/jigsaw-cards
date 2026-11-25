import 'dart:math';

import 'grid.dart';
import 'layout.dart';
import 'piece.dart';

/// Generates a valid rectangular layout for a grid from a seed.
///
/// The generation algorithm is **not decided** (TD-02 is Pending). Callers
/// depend only on this interface so the algorithm can be replaced without
/// changing the rest of the game. Implementations must be deterministic: the
/// same grid, constraints and seed give the same layout.
abstract interface class LayoutGenerator {
  PuzzleLayout generate({
    required GridSize grid,
    required LayoutConstraints constraints,
    required int seed,
  });
}

/// **Provisional** generator used to make the first playable prototype.
/// Not an approved algorithm: TD-02 remains Pending.
///
/// Method: fill the grid in row-major order; at each uncovered cell, choose
/// uniformly (seeded) among the allowed sizes that fit; reject and retry
/// (continuing the same seeded random sequence) until the piece count is
/// within the allowed range. The result is validated before being returned.
///
/// Determinism holds for a given seed on the same Dart SDK, because it uses
/// `dart:math` `Random(seed)`. The persisted-layout requirement (PS-23) is
/// handled by persisting the layout itself, not the seed (not yet
/// implemented: persistence is out of scope).
final class ProvisionalRandomFillGenerator implements LayoutGenerator {
  const ProvisionalRandomFillGenerator({this.maxAttempts = 10000});

  final int maxAttempts;

  @override
  PuzzleLayout generate({
    required GridSize grid,
    required LayoutConstraints constraints,
    required int seed,
  }) {
    final random = Random(seed);
    // Deterministic iteration order over the allowed sizes.
    final sizes = constraints.allowedSizes.toList()
      ..sort(
        (a, b) => a.rowSpan != b.rowSpan
            ? a.rowSpan - b.rowSpan
            : a.columnSpan - b.columnSpan,
      );

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final covered = <GridCell>{};
      final pieces = <PuzzlePiece>[];
      for (final cell in grid.cells) {
        if (covered.contains(cell)) continue;
        final fitting = [
          for (final size in sizes)
            if (_fits(grid, covered, cell, size)) size,
        ];
        if (fitting.isEmpty) break; // Cannot happen when 1×1 is allowed.
        final size = fitting[random.nextInt(fitting.length)];
        final piece = PuzzlePiece(
          id: 'p${pieces.length}',
          correctOrigin: cell,
          size: size,
        );
        pieces.add(piece);
        covered.addAll(piece.correctCells);
      }
      if (validateLayout(grid, pieces, constraints).isEmpty) {
        return PuzzleLayout.validated(
          grid: grid,
          pieces: pieces,
          constraints: constraints,
        );
      }
    }
    throw StateError(
      'No valid layout for $grid within $maxAttempts attempts (seed $seed)',
    );
  }

  static bool _fits(
    GridSize grid,
    Set<GridCell> covered,
    GridCell origin,
    PieceSize size,
  ) {
    for (var r = 0; r < size.rowSpan; r++) {
      for (var c = 0; c < size.columnSpan; c++) {
        final cell = GridCell(origin.row + r, origin.column + c);
        if (!grid.contains(cell) || covered.contains(cell)) return false;
      }
    }
    return true;
  }
}
