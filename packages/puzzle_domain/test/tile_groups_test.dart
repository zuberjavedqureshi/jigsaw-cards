import 'dart:math';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

// 4×4 cell indices (row-major); tile i belongs in cell i.
//    0  1  2  3
//    4  5  6  7
//    8  9 10 11
//   12 13 14 15
void main() {
  final grid = GridSize(4, 4);
  final source = SourceSize(1024, 1024);
  GridCell cell(int i) => grid.cellAt(i);
  Set<GridCell> cells(Iterable<int> ids) => {for (final i in ids) cell(i)};

  /// Offset of the tile in cell [c] from its correct cell.
  (int, int) shiftAt(PicturePuzzle p, int c) {
    final t = p.tileAt(cell(c)).target;
    return (cell(c).row - t.row, cell(c).column - t.column);
  }

  /// A board with [fixed] tiles (`cell → tile`) and every other tile placed
  /// so that it is aligned with none of its board neighbours, so the only
  /// groups are the ones [fixed] forms.
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

  /// [tiles] in their own cells.
  Map<int, int> home(Iterable<int> tiles) => {for (final t in tiles) t: t};

  /// [tiles] placed shifted by ([dr], [dc]) from their correct cells.
  Map<int, int> shifted(Iterable<int> tiles, int dr, int dc) => {
    for (final t in tiles) t + dr * 4 + dc: t,
  };

  GroupMoved moved(GroupMoveOutcome o) {
    expect(o, isA<GroupMoved>());
    return o as GroupMoved;
  }

  GroupMoveRejection rejected(GroupMoveOutcome o) {
    expect(o, isA<GroupMoveRejected>());
    return (o as GroupMoveRejected).reason;
  }

  Map<int, GridCell> where(PicturePuzzle p) => {
    for (final t in p.tiles) t.id: p.cellOf(t),
  };

  (int, int) delta(GridCell a, GridCell b) =>
      (b.row - a.row, b.column - a.column);

  group('group detection (relative alignment)', () {
    test('1. two matching horizontal neighbours join, anywhere', () {
      expect(layout(home([5, 6])).connectedGroups, [
        cells([5, 6]),
      ]);
      // Tiles 0 and 1 side by side in cells 10, 11: not home, still joined.
      expect(layout({10: 0, 11: 1}).connectedGroups, [
        cells([10, 11]),
      ]);
    });

    test('2. two matching vertical neighbours join, anywhere', () {
      expect(layout(home([5, 9])).connectedGroups, [
        cells([5, 9]),
      ]);
      expect(layout({3: 4, 7: 8}).connectedGroups, [
        cells([3, 7]),
      ]);
    });

    test('3. three or more tiles form one group', () {
      expect(layout(shifted([0, 1, 2], 2, 1)).connectedGroups, [
        cells([9, 10, 11]),
      ]);
      expect(layout(shifted([0, 1, 4, 5], 1, 2)).connectedGroups, [
        cells([6, 7, 10, 11]),
      ]);
    });

    test('4. L-shaped groups are detected', () {
      expect(layout(shifted([0, 1, 5], 2, 2)).connectedGroups, [
        cells([10, 11, 15]),
      ]);
    });

    test('5. several groups are detected independently', () {
      final p = layout({
        ...shifted([0, 1], 3, 0),
        ...home([6, 10]),
      });
      expect(p.connectedGroups, [
        cells([6, 10]),
        cells([12, 13]),
      ]);
      expect(p.groupAt(cell(0)), isNull);
      expect(p.unitAt(cell(0)), {cell(0)});
    });

    test('touching tiles that are not picture neighbours do not join', () {
      // Tiles 1 and 0 side by side in the wrong order.
      expect(layout({5: 1, 6: 0}).connectedGroups, isEmpty);
      // Picture neighbours touching the wrong way (0 below 1).
      expect(layout({5: 1, 9: 0}).connectedGroups, isEmpty);
      // Diagonal only.
      expect(layout({5: 0, 10: 5}).connectedGroups, isEmpty);
      // Same row in the picture but two apart.
      expect(layout({5: 0, 6: 2}).connectedGroups, isEmpty);
    });

    test('correctly placed neighbours are the zero-offset case', () {
      expect(layout(home([0, 1, 4])).connectedGroups, [
        cells([0, 1, 4]),
      ]);
      final solved = PicturePuzzle.solved(grid, source);
      expect(solved.connectedGroups.single, hasLength(16));
    });

    test('members share one offset; aligned neighbours are always joined', () {
      for (var seed = 0; seed < 300; seed++) {
        final p = PicturePuzzle.shuffled(grid, source, seed: seed);
        for (final g in p.connectedGroups) {
          expect(g.length, greaterThan(1));
          final shifts = {for (final c in g) shiftAt(p, c.row * 4 + c.column)};
          expect(shifts, hasLength(1));
        }
        for (var c = 0; c < 16; c++) {
          for (final n in [c + 1, c + 4]) {
            if (n >= 16 || (n == c + 1 && n % 4 == 0)) continue;
            if (shiftAt(p, c) == shiftAt(p, n)) {
              expect(p.groupAt(cell(c)), isNotNull);
              expect(p.groupAt(cell(c)), p.groupAt(cell(n)));
            }
          }
        }
      }
    });
  });

  group('moving groups', () {
    test('6. dragging any member moves the entire group', () {
      final p = layout({10: 0, 11: 1});
      final viaLeft = moved(p.moveGroup(cell(10), cell(0)));
      final viaRight = moved(p.moveGroup(cell(11), cell(1)));
      expect(viaLeft.puzzle.arrangement, viaRight.puzzle.arrangement);
      expect(viaLeft.unit, cells([10, 11]));
      expect(viaLeft.destination, cells([0, 1]));
      // Dropped home: both tiles are now correct and still joined.
      expect(viaLeft.puzzle.tileAt(cell(0)).id, 0);
      expect(viaLeft.puzzle.tileAt(cell(1)).id, 1);
      expect(viaLeft.puzzle.groupAt(cell(0)), cells([0, 1]));
      expect(viaLeft.displaced, {cell(0): cell(10), cell(1): cell(11)});
    });

    test('7. a group move keeps the picture inside the group', () {
      final p = layout(shifted([0, 1, 5], 2, 2)); // L in 10, 11, 15
      final before = where(p);
      final r = moved(p.moveGroup(cell(11), cell(5))); // offset (-1, -2)
      final after = where(r.puzzle);
      for (final id in [0, 1, 5]) {
        expect(delta(before[id]!, after[id]!), (-1, -2));
      }
      // Still joined (one row below home), same shape.
      expect(
        r.puzzle.groupAt(r.puzzle.cellOf(r.puzzle.tiles[0])),
        containsAll(cells([4, 5, 9])),
      );
    });

    test('8. group-to-group: both groups keep their geometry', () {
      // A = tiles 0,1 in cells 8,9; B = tiles 14,15 in cells 2,3.
      final p = layout({8: 0, 9: 1, 2: 14, 3: 15});
      expect(p.connectedGroups, [
        cells([2, 3]),
        cells([8, 9]),
      ]);
      final before = where(p);
      final r = moved(p.moveGroup(cell(8), cell(2)));
      final after = where(r.puzzle);
      for (final id in [0, 1]) {
        expect(delta(before[id]!, after[id]!), (-2, 2));
      }
      for (final id in [14, 15]) {
        expect(delta(before[id]!, after[id]!), (2, -2));
      }
      expect(r.puzzle.groupAt(cell(2)), cells([2, 3]));
      expect(r.puzzle.groupAt(cell(8)), cells([8, 9]));
    });

    test('a loose tile swaps with any tile, even a group member (M3.1)', () {
      final p = layout({8: 0, 9: 1, 2: 14, 3: 15});
      final loose = [
        0,
        1,
        4,
        5,
        6,
        7,
      ].firstWhere((c) => p.groupAt(cell(c)) == null);
      final r = moved(p.moveGroup(cell(loose), cell(3)));
      final s = p.swap(cell(loose), cell(3)) as TilesSwapped;
      expect(r.puzzle.arrangement, s.puzzle.arrangement);
      expect(r.unit, {cell(loose)});
    });

    test('a group dropped over part of another group displaces only the '
        'covered tiles; the rest are regrouped by alignment', () {
      final p = layout({8: 0, 9: 1, 2: 14, 3: 15});
      final r = moved(p.moveGroup(cell(8), cell(1))); // A onto cells 1, 2
      expect(r.destination, cells([1, 2]));
      expect(r.displaced.keys.toSet(), cells([1, 2]));
      expect(r.puzzle.groupAt(cell(1)), cells([1, 2]));
      expect(r.puzzle.tileAt(cell(3)).id, 15);
      expect(r.puzzle.groupAt(cell(3)), isNull);
    });

    test('a group that would leave the board is refused', () {
      final p = layout({2: 0, 3: 1});
      expect(
        rejected(p.moveGroup(cell(2), cell(7))),
        GroupMoveRejection.outOfBounds,
      );
      expect(
        rejected(p.moveGroup(cell(2), const GridCell(4, 0))),
        GroupMoveRejection.outOfBounds,
      );
    });

    test('overlapping moves: displaced tiles hop past the group', () {
      final p = layout({4: 0, 5: 1});
      expect(
        rejected(p.moveGroup(cell(5), cell(5))),
        GroupMoveRejection.sameCell,
      );
      final r = moved(p.moveGroup(cell(4), cell(5))); // one cell right
      expect(r.destination, cells([5, 6]));
      expect(r.displaced, {cell(6): cell(4)});
      expect(r.puzzle.tileAt(cell(5)).id, 0);
      expect(r.puzzle.tileAt(cell(6)).id, 1);
      expect(r.puzzle.tileAt(cell(4)).id, p.tileAt(cell(6)).id);
    });

    test('a group with a notch moves around the tile in the notch', () {
      // Reference video 41 s: a large group one row too low, with a loose
      // tile in a notch, is dragged up one row.
      final p = layout(shifted([0, 1, 2, 4, 6, 8, 9, 10], 1, 0));
      expect(p.groupAt(cell(4)), cells([4, 5, 6, 8, 10, 12, 13, 14]));
      final r = moved(p.moveGroup(cell(4), cell(0)));
      expect(r.puzzle.groupAt(cell(0)), containsAll(cells([0, 1, 2, 4, 6])));
      for (final c in [0, 1, 2, 4, 6, 8, 9, 10]) {
        expect(r.puzzle.tileAt(cell(c)).id, c, reason: 'home now');
      }
      expect(validateArrangement(grid, r.puzzle.arrangement), isEmpty);
    });

    test('9. loose tiles move alone, exactly like a swap', () {
      for (var seed = 0; seed < 200; seed++) {
        final p = PicturePuzzle.shuffled(grid, source, seed: seed);
        final rng = Random(seed);
        final from = cell(rng.nextInt(16));
        final to = cell(rng.nextInt(16));
        if (from == to || p.groupAt(from) != null) continue;
        final r = moved(p.moveGroup(from, to));
        final s = p.swap(from, to) as TilesSwapped;
        expect(r.unit, {from});
        expect(r.puzzle.arrangement, s.puzzle.arrangement);
        expect(r.puzzle.seed, s.puzzle.seed);
      }
    });
  });

  group('recalculation', () {
    test('10. membership follows the board, never stale', () {
      final p = layout({10: 0, 11: 1});
      final r = moved(p.moveGroup(cell(10), cell(12)));
      expect(r.puzzle.groupAt(cell(12)), cells([12, 13]));
      expect(r.puzzle.groupAt(cell(10)), isNot(cells([10, 11])));
      // Knocking one tile out of the pair dissolves it.
      final q = moved(r.puzzle.moveGroup(cell(0), cell(13)));
      expect(q.puzzle.groupAt(cell(12)), isNull);
    });

    test('11. new adjacency creates, extends and merges groups', () {
      final p = layout({9: 0, 15: 1, 3: 2, 0: 4, 1: 5});
      expect(p.connectedGroups, [
        cells([0, 1]),
      ]);
      final a = moved(p.moveGroup(cell(15), cell(10)));
      expect(a.puzzle.groupAt(cell(9)), cells([9, 10]));
      final b = moved(a.puzzle.moveGroup(cell(3), cell(11)));
      expect(b.puzzle.groupAt(cell(9)), cells([9, 10, 11]));
      // The pair {4,5} moved under tiles 0 and 1 → one 5-tile group.
      final c = moved(b.puzzle.moveGroup(cell(0), cell(13)));
      expect(c.puzzle.groupAt(cell(9)), cells([9, 10, 11, 13, 14]));
    });

    test('two groups merge when they line up', () {
      final p = layout({4: 0, 5: 1, 14: 2, 15: 3});
      final r = moved(p.moveGroup(cell(14), cell(6)));
      expect(r.puzzle.groupAt(cell(4)), cells([4, 5, 6, 7]));
    });
  });

  group('completion and invariants', () {
    test('12. completion detection is unchanged', () {
      final p = PicturePuzzle.fromArrangement(grid, source, [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, //
      ]);
      final r = moved(p.moveGroup(cell(15), cell(14)));
      expect(r.completedPuzzle, isTrue);
      expect(r.puzzle.isComplete, isTrue);
      expect(
        rejected(r.puzzle.moveGroup(cell(0), cell(5))),
        GroupMoveRejection.complete,
      );
    });

    test('every board stays solvable: dragging any group home always '
        'works and only adds correct tiles', () {
      final rng = Random(5);
      for (var seed = 0; seed < 500; seed++) {
        var p = PicturePuzzle.shuffled(grid, source, seed: seed);
        for (var i = 0; i < 20; i++) {
          final o = p.moveGroup(cell(rng.nextInt(16)), cell(rng.nextInt(16)));
          if (o is GroupMoved && !o.puzzle.isComplete) p = o.puzzle;
        }
        while (!p.isComplete) {
          final t = p.tiles.firstWhere((t) => !p.isTileCorrect(t));
          final correctBefore = [
            for (final x in p.tiles)
              if (p.isTileCorrect(x)) x.id,
          ];
          final r = moved(p.moveGroup(p.cellOf(t), t.target));
          for (final id in correctBefore) {
            expect(r.puzzle.isTileCorrect(r.puzzle.tiles[id]), isTrue);
          }
          expect(r.puzzle.correctCount, greaterThan(p.correctCount));
          p = r.puzzle;
        }
      }
    });

    test('random moves: board stays full, the dragged unit moves rigidly, '
        'groups displaced whole stay joined', () {
      final rng = Random(99);
      for (var run = 0; run < 300; run++) {
        var p = PicturePuzzle.shuffled(grid, source, seed: run);
        for (var step = 0; step < 30 && !p.isComplete; step++) {
          final from = cell(rng.nextInt(16));
          final to = cell(rng.nextInt(16));
          final groupsBefore = p.connectedGroups;
          final before = where(p);
          final o = p.moveGroup(from, to);
          if (o is GroupMoveRejected) {
            expect(o.reason, isNot(GroupMoveRejection.complete));
            continue;
          }
          final r = o as GroupMoved;
          expect(validateArrangement(grid, r.puzzle.arrangement), isEmpty);
          final after = where(r.puzzle);
          final off = delta(from, to);
          for (final c in r.unit) {
            final id = p.tileAt(c).id;
            expect(delta(before[id]!, after[id]!), off);
          }
          for (final g in groupsBefore) {
            final ids = [for (final c in g) p.tileAt(c).id];
            final shifts = {
              for (final id in ids) delta(before[id]!, after[id]!),
            };
            if (shifts.length != 1) continue; // partly displaced
            final now = r.puzzle.groupAt(after[ids.first]!)!;
            expect(now.containsAll({for (final id in ids) after[id]!}), isTrue);
          }
          p = r.puzzle;
        }
      }
    });
  });
}
