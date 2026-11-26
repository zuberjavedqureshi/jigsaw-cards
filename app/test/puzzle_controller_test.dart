import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

void main() {
  ProviderContainer make(int seed, {List<int> nextSeeds = const [500]}) {
    var i = 0;
    final c = ProviderContainer(
      overrides: [
        initialSeedProvider.overrideWithValue(seed),
        puzzleSeedSourceProvider.overrideWithValue(
          _ListSeedSource(() => nextSeeds[i++ % nextSeeds.length]),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  PuzzleController ctl(ProviderContainer c) =>
      c.read(puzzleControllerProvider.notifier);
  PuzzleState st(ProviderContainer c) => c.read(puzzleControllerProvider);

  test('same seed gives the same shuffled board', () {
    expect(st(make(7)).puzzle.arrangement, st(make(7)).puzzle.arrangement);
    expect(st(make(7)).puzzle.isComplete, isFalse);
    expect(st(make(7)).puzzle.grid, GridSize(4, 4));
  });

  test('tiles are cut from the artwork source size', () {
    final p = st(make(1)).puzzle;
    expect(p.source, SourceSize(1024, 1024));
    expect(p.sourceRectOf(p.tiles.first), const SourceRect(0, 0, 256, 256));
  });

  test('swaps update the board and count; invalid swaps do not', () {
    final c = make(3);
    final a = st(c).puzzle.tileAt(GridCell(0, 0));
    expect(ctl(c).swap(GridCell(0, 0), GridCell(1, 1)), isA<TilesSwapped>());
    expect(st(c).puzzle.tileAt(GridCell(1, 1)), a);
    expect(st(c).swaps, 1);
    expect(ctl(c).swap(GridCell(0, 0), GridCell(0, 0)), isA<SwapRejected>());
    expect(ctl(c).swap(GridCell(0, 0), GridCell(9, 0)), isA<SwapRejected>());
    expect(st(c).swaps, 1);
  });

  test('completion is shown only after solving and the animation', () {
    final c = make(3);
    ctl(c).completionShown();
    expect(st(c).showCompletion, isFalse);
    final grid = st(c).puzzle.grid;
    for (final cell in grid.cells) {
      final p = st(c).puzzle;
      final want = p.tiles[cell.row * grid.columns + cell.column];
      final at = p.cellOf(want);
      if (at != cell) ctl(c).swap(at, cell);
    }
    expect(st(c).isComplete, isTrue);
    expect(st(c).showCompletion, isFalse);
    ctl(c).completionShown();
    expect(st(c).showCompletion, isTrue);
  });

  test('new puzzle takes its seed from the seed source and resets', () {
    final c = make(9);
    ctl(c).swap(GridCell(0, 0), GridCell(0, 1));
    ctl(c).newPuzzle();
    expect(st(c).seed, 500);
    expect(st(c).round, 1);
    expect(st(c).swaps, 0);
    expect(st(c).showCompletion, isFalse);
    expect(st(c).isComplete, isFalse);
  });
}

class _ListSeedSource implements PuzzleSeedSource {
  _ListSeedSource(this._next);
  final int Function() _next;

  @override
  int nextSeed() => _next();
}
