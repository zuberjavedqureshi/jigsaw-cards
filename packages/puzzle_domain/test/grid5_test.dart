import 'dart:math';

import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

// W2: the unchanged domain on the 5×5 Hard board. Cell indices (row-major);
// tile i belongs in cell i.
//    0  1  2  3  4
//    5  6  7  8  9
//   10 11 12 13 14
//   15 16 17 18 19
//   20 21 22 23 24
void main() {
  const n = 5;
  final grid = GridSize(n, n);
  final source = SourceSize(1024, 1024);
  GridCell cell(int i) => grid.cellAt(i);
  Set<GridCell> cells(Iterable<int> ids) => {for (final i in ids) cell(i)};

  (int, int) shiftAt(PicturePuzzle p, int c) {
    final t = p.tileAt(cell(c)).target;
    return (cell(c).row - t.row, cell(c).column - t.column);
  }

  bool adjacent(int a, int b) =>
      (a ~/ n == b ~/ n && (a - b).abs() == 1) || (a - b).abs() == n;

  /// A board with [fixed] tiles (`cell → tile`); every other tile is aligned
  /// with none of its board neighbours.
  PicturePuzzle layout(Map<int, int> fixed) {
    final freeCells = [
      for (var c = 0; c < n * n; c++)
        if (!fixed.containsKey(c)) c,
    ];
    final freeTiles = [
      for (var t = 0; t < n * n; t++)
        if (!fixed.containsValue(t)) t,
    ];
    for (var seed = 0; seed < 100000; seed++) {
      final tiles = [...freeTiles]..shuffle(Random(seed));
      final a = List.filled(n * n, -1);
      fixed.forEach((c, t) => a[c] = t);
      for (var i = 0; i < freeCells.length; i++) {
        a[freeCells[i]] = tiles[i];
      }
      final p = PicturePuzzle.fromArrangement(grid, source, a);
      if (p.isComplete) continue;
      var ok = true;
      for (var c = 0; c < n * n && ok; c++) {
        for (final m in [c + 1, c + n]) {
          if (m >= n * n || !adjacent(c, m)) continue;
          if (fixed.containsKey(c) && fixed.containsKey(m)) continue;
          if (shiftAt(p, c) == shiftAt(p, m)) ok = false;
        }
      }
      if (ok) return p;
    }
    throw StateError('no layout for $fixed');
  }

  GroupMoved moved(GroupMoveOutcome o) {
    expect(o, isA<GroupMoved>());
    return o as GroupMoved;
  }

  group('5×5 board model', () {
    test('25 unique tiles, each with a valid, distinct target', () {
      final p = PicturePuzzle.solved(grid, source);
      expect(p.tileCount, 25);
      expect({for (final t in p.tiles) t.id}, {for (var i = 0; i < 25; i++) i});
      expect({for (final t in p.tiles) t.target}, hasLength(25));
      for (final t in p.tiles) {
        expect(grid.contains(t.target), isTrue);
        expect(t.target, cell(t.id));
      }
    });

    test('indexing round-trips; out-of-range cells are rejected', () {
      for (var i = 0; i < 25; i++) {
        final c = cell(i);
        expect(c.row * n + c.column, i);
        expect(grid.contains(c), isTrue);
      }
      for (final c in [
        GridCell(-1, 0),
        GridCell(0, -1),
        GridCell(5, 0),
        GridCell(0, 5),
      ]) {
        expect(grid.contains(c), isFalse);
      }
      expect(() => grid.cellAt(25), throwsRangeError);
      final p = PicturePuzzle.solved(grid, source);
      expect(() => p.tileAt(GridCell(5, 5)), throwsRangeError);
    });

    test('tile picture regions tile the 1024×1024 source exactly', () {
      final p = PicturePuzzle.solved(grid, source);
      for (final t in p.tiles) {
        final r = p.sourceRectOf(t);
        expect(r.width, closeTo(1024 / 5, 1e-9));
        expect(r.height, closeTo(1024 / 5, 1e-9));
        expect(r.left, closeTo(t.target.column * 1024 / 5, 1e-9));
        expect(r.top, closeTo(t.target.row * 1024 / 5, 1e-9));
      }
      final last = p.sourceRectOf(p.tiles.last);
      expect(last.left + last.width, closeTo(1024, 1e-9));
      expect(last.top + last.height, closeTo(1024, 1e-9));
    });

    test('shuffles are valid permutations, never solved, ≥ 19 misplaced', () {
      for (var seed = 0; seed < 500; seed++) {
        final p = PicturePuzzle.shuffled(grid, source, seed: seed);
        expect(validateArrangement(grid, p.arrangement), isEmpty);
        expect(p.isComplete, isFalse);
        expect(25 - p.correctCount, greaterThanOrEqualTo(19));
        expect(
          PicturePuzzle.shuffled(grid, source, seed: seed).arrangement,
          p.arrangement,
          reason: 'deterministic',
        );
      }
    });
  });

  group('5×5 connected groups', () {
    test('pairs join in every corner and along every edge', () {
      // Horizontal pairs placed home in the four corners.
      for (final (a, b) in [(0, 1), (3, 4), (20, 21), (23, 24)]) {
        expect(layout({a: a, b: b}).connectedGroups, [
          cells([a, b]),
        ]);
      }
      // Vertical pairs on the left and right edges, shifted away from home.
      expect(layout({5: 0, 10: 5}).connectedGroups, [
        cells([5, 10]),
      ]);
      expect(layout({9: 4, 14: 9}).connectedGroups, [
        cells([9, 14]),
      ]);
    });

    test('an L across rows and a 2×2 block are single groups', () {
      expect(layout({16: 0, 17: 1, 22: 6}).connectedGroups, [
        cells([16, 17, 22]),
      ]);
      expect(layout({13: 0, 14: 1, 18: 5, 19: 6}).connectedGroups, [
        cells([13, 14, 18, 19]),
      ]);
    });

    test('row-end and row-start tiles never join across the edge', () {
      // Tile 4 (end of row 0) in cell 9 next to tile 5 (start of row 1) in
      // cell 10 would be "consecutive" but are not picture neighbours.
      expect(layout({9: 4, 10: 5}).connectedGroups, isEmpty);
    });

    test('dragging any member moves the group rigidly', () {
      final p = layout({16: 0, 17: 1, 22: 6}); // L
      final viaA = moved(p.moveGroup(cell(16), cell(0)));
      final viaB = moved(p.moveGroup(cell(22), cell(6)));
      expect(viaA.puzzle.arrangement, viaB.puzzle.arrangement);
      for (final id in [0, 1, 6]) {
        expect(
          viaA.puzzle.cellOf(viaA.puzzle.tiles[id]),
          cell(id),
          reason: 'home',
        );
      }
      expect(viaA.puzzle.groupAt(cell(0)), cells([0, 1, 6]));
    });

    test('groups at the edges are refused when they would leave the board', () {
      final right = layout({3: 0, 4: 1});
      final o = right.moveGroup(cell(4), cell(9));
      expect(o, isA<GroupMoved>(), reason: 'down one row fits');
      expect(
        (right.moveGroup(cell(3), cell(4)) as GroupMoveRejected).reason,
        GroupMoveRejection.outOfBounds,
      );
      final bottom = layout({15: 0, 20: 5});
      expect(
        (bottom.moveGroup(cell(15), cell(20)) as GroupMoveRejected).reason,
        GroupMoveRejection.outOfBounds,
      );
    });

    test('groups merge when they line up', () {
      final p = layout({10: 0, 11: 1, 22: 2, 23: 3});
      final r = moved(p.moveGroup(cell(22), cell(12)));
      expect(r.puzzle.groupAt(cell(10)), cells([10, 11, 12, 13]));
      final e = connectionEvents(p, r.puzzle).single;
      expect(e.kind, ConnectionKind.merged);
      expect(e.size, 4);
    });

    test('a group can grow from 9 to 10 tiles (Fantastic! threshold)', () {
      // Tiles 0–8 except 4 make 9 home tiles in rows 0–1 (0,1,2,3,5,6,7,8 +
      // 10); tile 4 completes the top row and joins all into 10.
      final home = [0, 1, 2, 3, 5, 6, 7, 8, 10];
      final p = layout({for (final t in home) t: t, 24: 4});
      expect(p.groupAt(cell(0)), hasLength(9));
      final r = moved(p.moveGroup(cell(24), cell(4)));
      final e = connectionEvents(p, r.puzzle).single;
      expect(e.kind, ConnectionKind.grew);
      expect(e.size, 10);
    });
  });

  group('5×5 completion and invariants', () {
    test('the final swap at the board corner completes the puzzle', () {
      final a = [for (var i = 0; i < 25; i++) i];
      a[23] = 24;
      a[24] = 23;
      final p = PicturePuzzle.fromArrangement(grid, source, a);
      expect(p.connectedGroups.single, hasLength(23));
      final r = moved(p.moveGroup(cell(24), cell(23)));
      expect(r.puzzle.isComplete, isTrue);
      expect(connectionEvents(p, r.puzzle).single.size, 25);
      expect(
        (r.puzzle.moveGroup(cell(0), cell(1)) as GroupMoveRejected).reason,
        GroupMoveRejection.complete,
      );
    });

    test('every shuffled 5×5 board is solvable by moving groups home', () {
      for (var seed = 0; seed < 300; seed++) {
        var p = PicturePuzzle.shuffled(grid, source, seed: seed);
        var guard = 0;
        while (!p.isComplete && guard++ < 60) {
          final t = p.tiles.firstWhere((t) => !p.isTileCorrect(t));
          final r = moved(p.moveGroup(p.cellOf(t), t.target));
          expect(r.puzzle.correctCount, greaterThan(p.correctCount));
          p = r.puzzle;
        }
        expect(p.isComplete, isTrue, reason: 'seed $seed');
      }
    });

    test('random play keeps the board full and valid', () {
      final rng = Random(55);
      for (var run = 0; run < 300; run++) {
        var p = PicturePuzzle.shuffled(grid, source, seed: run);
        for (var step = 0; step < 30 && !p.isComplete; step++) {
          final from = cell(rng.nextInt(25));
          final to = cell(rng.nextInt(25));
          final o = p.moveGroup(from, to);
          if (o is! GroupMoved) continue;
          expect(validateArrangement(grid, o.puzzle.arrangement), isEmpty);
          for (final c in o.destination) {
            expect(grid.contains(c), isTrue);
          }
          for (final e in o.displaced.entries) {
            expect(grid.contains(e.key) && grid.contains(e.value), isTrue);
          }
          p = o.puzzle;
        }
      }
    });
  });
}
