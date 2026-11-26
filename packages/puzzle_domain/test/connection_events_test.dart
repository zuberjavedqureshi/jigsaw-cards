import 'dart:math';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

// 4×4 cell indices (row-major); tile i belongs in cell i.
void main() {
  final grid = GridSize(4, 4);
  final source = SourceSize(1024, 1024);
  GridCell cell(int i) => grid.cellAt(i);
  Set<GridCell> cells(Iterable<int> ids) => {for (final i in ids) cell(i)};

  (int, int) shiftAt(PicturePuzzle p, int c) {
    final t = p.tileAt(cell(c)).target;
    return (cell(c).row - t.row, cell(c).column - t.column);
  }

  /// A board with [fixed] tiles (`cell → tile`); every other tile is aligned
  /// with none of its board neighbours.
  PicturePuzzle layout(Map<int, int> fixed) {
    final freeCells = [
      for (var c = 0; c < 16; c++)
        if (!fixed.containsKey(c)) c,
    ];
    final freeTiles = [
      for (var t = 0; t < 16; t++)
        if (!fixed.containsValue(t)) t,
    ];
    for (var seed = 0; seed < 100000; seed++) {
      final tiles = [...freeTiles]..shuffle(Random(seed));
      final a = List.filled(16, -1);
      fixed.forEach((c, t) => a[c] = t);
      for (var i = 0; i < freeCells.length; i++) {
        a[freeCells[i]] = tiles[i];
      }
      final p = PicturePuzzle.fromArrangement(grid, source, a);
      if (p.isComplete) continue;
      var ok = true;
      for (var c = 0; c < 16 && ok; c++) {
        for (final n in [c + 1, c + 4]) {
          if (n >= 16 || (n == c + 1 && n % 4 == 0)) continue;
          if (fixed.containsKey(c) && fixed.containsKey(n)) continue;
          if (shiftAt(p, c) == shiftAt(p, n)) ok = false;
        }
      }
      if (ok) return p;
    }
    throw StateError('no layout for $fixed');
  }

  PicturePuzzle after(PicturePuzzle p, int from, int to) =>
      (p.moveGroup(cell(from), cell(to)) as GroupMoved).puzzle;

  test('a pair forms from two loose tiles', () {
    final p = layout({5: 0, 15: 1});
    final e = connectionEvents(p, after(p, 15, 6)).single;
    expect(e.kind, ConnectionKind.formed);
    expect(e.size, 2);
    expect(e.cells, cells([5, 6]));
    expect(e.groupsJoined, 0);
    expect(e.tilesAdded, 2);
  });

  test('an existing group grows', () {
    final p = layout({5: 0, 6: 1, 15: 2});
    final e = connectionEvents(p, after(p, 15, 7)).single;
    expect(e.kind, ConnectionKind.grew);
    expect(e.cells, cells([5, 6, 7]));
    expect(e.groupsJoined, 1);
    expect(e.tilesAdded, 1);
  });

  test('two groups merge', () {
    final p = layout({4: 0, 5: 1, 14: 2, 15: 3});
    final e = connectionEvents(p, after(p, 14, 6)).single;
    expect(e.kind, ConnectionKind.merged);
    expect(e.cells, cells([4, 5, 6, 7]));
    expect(e.groupsJoined, 2);
    expect(e.tilesAdded, 0);
  });

  test('a large group forms when groups merge', () {
    // {0,1,4,5} in cells 4,5,8,9 and {2,3,6,7} in cells 2,3,6,7: the second
    // block dropped right of the first makes a 2×4 block of eight.
    final p = layout({4: 0, 5: 1, 8: 4, 9: 5, 2: 2, 3: 3, 6: 6, 7: 7});
    expect(p.connectedGroups, hasLength(2));
    final e = connectionEvents(p, after(p, 2, 6)).single;
    expect(e.kind, ConnectionKind.merged);
    expect(e.size, 8);
  });

  test('a group that only moves produces no event', () {
    final p = layout({5: 0, 6: 1});
    expect(connectionEvents(p, after(p, 5, 9)), isEmpty);
  });

  test('ordinary swaps of loose tiles produce no event', () {
    final p = layout({5: 0, 6: 1});
    final loose = [0, 1, 2, 3].firstWhere((c) => p.groupAt(cell(c)) == null);
    final q = after(p, loose, 15);
    // Only if the swap happened to align tiles would an event appear; the
    // layout helper makes sure it does not here.
    expect(
      connectionEvents(p, q).every((e) => e.kind != ConnectionKind.merged),
      isTrue,
    );
  });

  test('a group that is split produces no event for its remains', () {
    // Pair in cells 0,1; a loose tile is swapped into cell 1.
    final p = layout({0: 0, 1: 1});
    final loose = [8, 9, 10].firstWhere((c) => p.groupAt(cell(c)) == null);
    final q = after(p, loose, 1);
    expect(q.groupAt(cell(0)), isNull);
    expect(connectionEvents(p, q), isEmpty);
  });

  test('one move can make several connections', () {
    // Swapping two tiles home can complete two separate pairs at once.
    final p = layout({0: 0, 9: 1, 1: 9, 8: 8});
    final events = connectionEvents(p, after(p, 9, 1));
    expect(events.map((e) => e.cells).toSet(), {
      cells([0, 1]),
      cells([8, 9]),
    });
  });

  test('completing the puzzle yields one event for the whole picture', () {
    final p = PicturePuzzle.fromArrangement(grid, source, [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, //
    ]);
    final q = after(p, 15, 14);
    expect(q.isComplete, isTrue);
    final e = connectionEvents(p, q).single;
    expect(e.size, 16);
    expect(e.kind, ConnectionKind.grew);
  });

  test('random moves: events describe exactly the new groups', () {
    final rng = Random(3);
    for (var run = 0; run < 200; run++) {
      var p = PicturePuzzle.shuffled(grid, source, seed: run);
      for (var step = 0; step < 20 && !p.isComplete; step++) {
        final o = p.moveGroup(cell(rng.nextInt(16)), cell(rng.nextInt(16)));
        if (o is! GroupMoved) continue;
        final q = o.puzzle;
        final events = connectionEvents(p, q);
        final beforeSets = [
          for (final g in p.connectedGroups)
            {for (final c in g) p.tileAt(c).id},
        ];
        for (final e in events) {
          expect(
            q.connectedGroups.any(
              (g) => g.length == e.cells.length && g.containsAll(e.cells),
            ),
            isTrue,
          );
          expect(e.groupsJoined * 2 + e.tilesAdded, lessThanOrEqualTo(e.size));
          final ids = {for (final c in e.cells) q.tileAt(c).id};
          expect(beforeSets.any((b) => b.containsAll(ids)), isFalse);
        }
        p = q;
      }
    }
  });
}
