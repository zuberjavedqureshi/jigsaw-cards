import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

/// Fraction of each piece's area not covered by pieces stacked above it,
/// sampled on a 0.05-cell grid.
Map<String, double> visibleFractions(PuzzleSession s) {
  final stack = s.pieces.toList();
  final result = <String, double>{};
  for (var i = 0; i < stack.length; i++) {
    final p = stack[i];
    var total = 0;
    var visible = 0;
    for (var y = 0.025; y < p.piece.size.rowSpan; y += 0.05) {
      for (var x = 0.025; x < p.piece.size.columnSpan; x += 0.05) {
        final pt = p.position + BoardPoint(x, y);
        total++;
        if (!stack.skip(i + 1).any((q) => q.contains(pt))) visible++;
      }
    }
    result[p.id] = visible / total;
  }
  return result;
}

void main() {
  final grid = GridSize(4, 4);
  final bounds = PlayBounds.prototype(grid);
  const gen = ProvisionalRandomFillGenerator();

  PuzzleSession sessionFor(int seed) => PuzzleSession.start(
    gen.generate(
      grid: grid,
      constraints: LayoutConstraints.prototype,
      seed: seed,
    ),
    bounds: bounds,
    scatterSeed: seed,
  );

  test('prototype bounds contain the grid with space around it', () {
    expect(bounds.left, lessThan(0));
    expect(bounds.top, lessThan(0));
    expect(bounds.right, greaterThan(4));
    expect(bounds.bottom, greaterThan(7));
  });

  test('scatter is deterministic per seed', () {
    final a = sessionFor(11).pieces.map((p) => (p.id, p.position)).toList();
    final b = sessionFor(11).pieces.map((p) => (p.id, p.position)).toList();
    expect(a, b);
    final c = sessionFor(12).pieces.map((p) => (p.id, p.position)).toList();
    expect(a, isNot(c));
  });

  test('different scatter seeds give different starts for one layout', () {
    final layout = gen.generate(
      grid: grid,
      constraints: LayoutConstraints.prototype,
      seed: 5,
    );
    final starts = {
      for (var seed = 0; seed < 10; seed++)
        PuzzleSession.start(
          layout,
          bounds: bounds,
          scatterSeed: seed,
        ).pieces.map((p) => p.position).join(),
    };
    expect(starts.length, 10);
  });

  for (var seed = 0; seed < 300; seed++) {
    test('seed $seed: valid, separated from targets, visible', () {
      final s = sessionFor(seed);
      final fractions = visibleFractions(s);
      for (final p in s.pieces) {
        expect(bounds.containsPiece(p.position, p.piece.size), isTrue);
        // Never at or next to its own correct position.
        expect(p.position.chebyshevTo(p.target), greaterThanOrEqualTo(1.0));
        // Every piece shows a substantial uncovered part.
        expect(fractions[p.id], greaterThanOrEqualTo(0.5), reason: p.id);
      }
      // Not the solved picture translated as a whole.
      final offsets = {for (final p in s.pieces) p.position - p.target};
      expect(offsets.length, greaterThan(1));
      // Stack: every id once.
      expect(s.stackOrder.toSet(), {for (final p in s.layout.pieces) p.id});
    }, skip: false);
  }
}
