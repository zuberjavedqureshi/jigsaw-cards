import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final grid = GridSize(4, 4);
  final source = SourceSize(1024, 1024);

  PicturePuzzle shuffled([int seed = 7]) =>
      PicturePuzzle.shuffled(grid, source, seed: seed);

  /// Every cell holds exactly one tile and every tile is in exactly one cell.
  void expectValidOccupancy(PicturePuzzle p) {
    expect(validateArrangement(p.grid, p.arrangement), isEmpty);
    final seen = <int>{};
    for (final cell in p.grid.cells) {
      expect(seen.add(p.tileAt(cell).id), isTrue, reason: '$cell');
    }
    expect(seen.length, p.tileCount);
    for (final t in p.tiles) {
      expect(p.tileAt(p.cellOf(t)), t);
    }
  }

  group('solved grid', () {
    test('every tile starts in its target cell', () {
      final p = PicturePuzzle.solved(grid, source);
      expect(p.tileCount, 16);
      expect(p.isComplete, isTrue);
      expect(p.correctCount, 16);
      expect(p.minimumSwapsToSolve, 0);
      for (final t in p.tiles) {
        expect(p.cellOf(t), t.target);
        expect(p.isTileCorrect(t), isTrue);
      }
      expectValidOccupancy(p);
    });

    test('tiles slice the source into equal, non-overlapping regions', () {
      final p = PicturePuzzle.solved(grid, source);
      var area = 0.0;
      for (final t in p.tiles) {
        final r = p.sourceRectOf(t);
        expect(r.width, 256);
        expect(r.height, 256);
        expect(r.left, t.target.column * 256);
        expect(r.top, t.target.row * 256);
        area += r.width * r.height;
      }
      expect(area, source.width * source.height);
    });

    test('non-square sources keep a consistent tile aspect', () {
      final p = PicturePuzzle.solved(GridSize(5, 4), SourceSize(800, 1200));
      final ratios = {
        for (final t in p.tiles)
          p.sourceRectOf(t).width / p.sourceRectOf(t).height,
      };
      expect(ratios, {200 / 240});
    });
  });

  group('shuffle', () {
    test('is deterministic per seed', () {
      expect(shuffled(3).arrangement, shuffled(3).arrangement);
      expect(shuffled(3).arrangement, isNot(shuffled(4).arrangement));
      expect(shuffled(3).seed, 3);
    });

    test('never starts solved, mostly misplaced, always valid', () {
      for (var seed = 0; seed < 1000; seed++) {
        final p = shuffled(seed);
        expectValidOccupancy(p);
        expect(p.isComplete, isFalse, reason: 'seed $seed');
        expect(p.tileCount - p.correctCount, greaterThanOrEqualTo(12));
      }
    });

    test('every shuffle is solvable through swaps', () {
      for (var seed = 0; seed < 300; seed++) {
        var p = shuffled(seed);
        final needed = p.minimumSwapsToSolve;
        var swaps = 0;
        // Greedy: put the right tile into each cell in turn.
        for (final cell in grid.cells) {
          final want = p.tiles[cell.row * grid.columns + cell.column];
          final at = p.cellOf(want);
          if (at != cell) {
            p = (p.swap(at, cell) as TilesSwapped).puzzle;
            swaps++;
            expectValidOccupancy(p);
          }
        }
        expect(p.isComplete, isTrue, reason: 'seed $seed');
        expect(swaps, needed, reason: 'greedy is optimal per cycle');
      }
    });

    test('tile identity and targets never change', () {
      final a = PicturePuzzle.solved(grid, source);
      final b = shuffled(11);
      expect(b.tiles, a.tiles);
      for (final t in b.tiles) {
        expect(
          b.sourceRectOf(t),
          a.sourceRectOf(t),
          reason: 'content follows id',
        );
      }
    });
  });

  group('swap', () {
    test('exchanges exactly two tiles and nothing else', () {
      final p = shuffled();
      final from = GridCell(0, 0);
      final to = GridCell(2, 3);
      final a = p.tileAt(from);
      final b = p.tileAt(to);
      final out = p.swap(from, to) as TilesSwapped;
      final q = out.puzzle;
      expect(q.tileAt(to), a);
      expect(q.tileAt(from), b);
      expect(out.movedTile, a);
      expect(out.displacedTile, b);
      var changed = 0;
      for (final c in grid.cells) {
        if (p.tileAt(c) != q.tileAt(c)) changed++;
      }
      expect(changed, 2);
      expectValidOccupancy(q);
      // Immutable.
      expect(p.tileAt(from), a);
    });

    test('incorrect swaps are accepted', () {
      final p = PicturePuzzle.solved(grid, source);
      // Break a solved board on purpose via fromArrangement.
      final broken = PicturePuzzle.fromArrangement(grid, source, [
        1,
        0,
        ...List.generate(14, (i) => i + 2),
      ]);
      final out = broken.swap(GridCell(3, 3), GridCell(3, 2)) as TilesSwapped;
      expect(out.nowCorrect, isEmpty);
      expect(out.puzzle.correctCount, 12);
      expect(p.isComplete, isTrue);
    });

    test('reports tiles that land correctly and completion', () {
      final p = PicturePuzzle.fromArrangement(grid, source, [
        1,
        0,
        ...List.generate(14, (i) => i + 2),
      ]);
      expect(p.isComplete, isFalse);
      expect(p.correctCount, 14);
      final out = p.swap(GridCell(0, 0), GridCell(0, 1)) as TilesSwapped;
      expect(out.nowCorrect.map((t) => t.id).toSet(), {0, 1});
      expect(out.completedPuzzle, isTrue);
      expect(out.puzzle.isComplete, isTrue);
    });

    test('completion only when every tile is correct', () {
      var p = shuffled(21);
      while (!p.isComplete) {
        final cell = grid.cells.firstWhere(
          (c) => !p.isTileCorrect(p.tileAt(c)),
        );
        final want = p.tiles[cell.row * grid.columns + cell.column];
        expect(p.isComplete, isFalse);
        p = (p.swap(p.cellOf(want), cell) as TilesSwapped).puzzle;
      }
      expect(p.correctCount, 16);
    });

    test('invalid requests are rejected and do not corrupt the board', () {
      final p = shuffled();
      final before = [...p.arrangement];
      expect(
        (p.swap(GridCell(0, 0), GridCell(4, 0)) as SwapRejected).reason,
        SwapRejection.outOfBounds,
      );
      expect(
        (p.swap(GridCell(-1, 0), GridCell(0, 0)) as SwapRejected).reason,
        SwapRejection.outOfBounds,
      );
      expect(
        (p.swap(GridCell(1, 1), GridCell(1, 1)) as SwapRejected).reason,
        SwapRejection.sameCell,
      );
      expect(
        (PicturePuzzle.solved(
          grid,
          source,
        ).swap(GridCell(0, 0), GridCell(0, 1)) as SwapRejected).reason,
        SwapRejection.complete,
      );
      expect(p.arrangement, before);
      expect(() => p.tileAt(GridCell(9, 9)), throwsRangeError);
    });

    test('repeated swaps preserve the invariants', () {
      var p = shuffled(5);
      final cells = grid.cells.toList();
      for (var i = 0; i < 500; i++) {
        final a = cells[(i * 7) % 16];
        final b = cells[(i * 11 + 3) % 16];
        final out = p.swap(a, b);
        if (out is TilesSwapped) {
          p = out.puzzle;
          if (p.isComplete) p = shuffled(i);
        }
        expectValidOccupancy(p);
      }
    });

    test('swapping the same pair twice restores the board', () {
      final p = shuffled();
      final q = (p.swap(GridCell(0, 1), GridCell(3, 0)) as TilesSwapped).puzzle;
      final r = (q.swap(GridCell(3, 0), GridCell(0, 1)) as TilesSwapped).puzzle;
      expect(r.arrangement, p.arrangement);
    });
  });

  group('occupancy validation', () {
    test('rejects duplicates, gaps, unknown tiles and wrong length', () {
      expect(
        validateArrangement(grid, [0, 0, ...List.generate(14, (i) => i + 2)]),
        isNotEmpty,
      );
      expect(
        validateArrangement(grid, List.generate(15, (i) => i)),
        isNotEmpty,
      );
      expect(
        validateArrangement(grid, [...List.generate(15, (i) => i), 99]),
        isNotEmpty,
      );
      expect(
        () => PicturePuzzle.fromArrangement(grid, source, List.filled(16, 0)),
        throwsArgumentError,
      );
    });

    test('a puzzle needs at least two tiles; sizes must be positive', () {
      expect(
        () => PicturePuzzle.shuffled(GridSize(1, 1), source, seed: 1),
        throwsArgumentError,
      );
      expect(() => SourceSize(0, 10), throwsArgumentError);
    });
  });
}
