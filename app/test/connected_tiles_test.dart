import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// M3.2 connected correct tiles, driven through real drag gestures on the
/// unchanged M3.1 game.
///
/// Seed 1000 starts with one L-shaped group: tiles 5, 9 and 10 in their
/// correct cells (1,1), (2,1) and (2,2).
const groupSeed = 1000;
final lCells = {GridCell(1, 1), GridCell(2, 1), GridCell(2, 2)};

void main() {
  test('seed $groupSeed starts with the L-shaped group', () {
    final p = PicturePuzzle.shuffled(
      GridSize(4, 4),
      SourceSize(1024, 1024),
      seed: groupSeed,
    );
    expect(p.connectedGroups, [lCells]);
  });

  /// [c] rests on the centre of [cell] (Flame positions are float32).
  void expectAt(Harness h, TileComponent c, GridCell cell) {
    final want = h.game.area.cellRect(cell).center;
    expect(c.position.x, closeTo(want.dx, 0.01));
    expect(c.position.y, closeTo(want.dy, 0.01));
  }

  /// Tiles by id → cell.
  Map<int, GridCell> where(PicturePuzzle p) => {
    for (final t in p.tiles) t.id: p.cellOf(t),
  };

  testWidgets('dragging any member lifts and moves the whole group', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    for (final grab in lCells) {
      final g = await h.dragTo(
        grab,
        h.globalOf(grab) + const Offset(-30, -40),
        release: false,
      );
      final unit = h.game.draggedUnit;
      expect(unit.map((c) => c.tile.id).toSet(), {5, 9, 10});
      expect(unit.first, h.componentAt(grab), reason: 'grabbed tile first');
      expect(unit.every((c) => c.lifted), isTrue);
      // Members keep their board geometry around the finger (scaled by the
      // lift, so the group stays seamless).
      final anchor = h.componentAt(grab).position;
      for (final c in unit) {
        final cell = h.puzzle.cellOf(c.tile);
        final rest =
            h.game.area.cellRect(cell).center -
            h.game.area.cellRect(grab).center;
        final now = (c.position - anchor).toOffset();
        expect(now.dx, closeTo(rest.dx * TileComponent.liftScale, 0.01));
        expect(now.dy, closeTo(rest.dy * TileComponent.liftScale, 0.01));
      }
      // Inner edges are not outlined while lifted.
      expect(
        h.componentAt(GridCell(2, 1)).joinedSides,
        TileComponent.sideTop | TileComponent.sideRight,
      );
      await g.up();
      await h.settle();
      expect(h.puzzle.connectedGroups, [lCells], reason: 'nothing moved');
      expect(h.game.tiles.values.every((c) => !c.lifted), isTrue);
      // At rest the group is drawn seamlessly; loose tiles keep full edges.
      expect(
        h.componentAt(GridCell(2, 1)).joinedSides,
        TileComponent.sideTop | TileComponent.sideRight,
      );
      expect(h.componentAt(GridCell(0, 0)).joinedSides, 0);
    }
  });

  testWidgets('a group drop moves every member by the same offset and the '
      'displaced tiles fill the cells it left', (tester) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    final before = h.puzzle;
    final expected = before.moveGroup(GridCell(2, 1), GridCell(1, 0));
    expect(expected, isA<GroupMoved>());
    final g = await h.dragTo(
      GridCell(2, 1),
      h.globalOf(GridCell(1, 0)),
      release: false,
    );
    // The destination of every member is marked; displaced tiles glow.
    expect(h.game.targetMarker.groupRects, hasLength(3));
    expect(h.game.displacedTiles.map((c) => c.tile.id).toSet(), {
      for (final c in (expected as GroupMoved).displaced.keys)
        before.tileAt(c).id,
    });
    expect(h.game.displacedTiles.every((c) => c.hovered), isTrue);
    await g.up();
    await h.settle();
    expect(h.puzzle.arrangement, expected.puzzle.arrangement);
    final a = where(before), b = where(h.puzzle);
    for (final id in [5, 9, 10]) {
      expect(b[id]!.row - a[id]!.row, -1);
      expect(b[id]!.column - a[id]!.column, -1);
    }
    // Not home any more, but still aligned: still one group, drawn
    // seamlessly in its new place.
    expect(h.puzzle.groupAt(GridCell(0, 0)), {
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(1, 1),
    });
    expect(
      h.componentAt(GridCell(1, 0)).joinedSides,
      TileComponent.sideTop | TileComponent.sideRight,
    );
    expect(h.state.swaps, 1);
    // Every tile rests exactly on its cell.
    for (final cell in h.puzzle.grid.cells) {
      final c = h.componentAt(cell);
      expectAt(h, c, cell);
      expect(c.lifted, isFalse);
    }
  });

  testWidgets('grabbing a different member gives the same group move', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    final expected =
        h.puzzle.moveGroup(GridCell(1, 1), GridCell(0, 0)) as GroupMoved;
    await h.swap(GridCell(1, 1), GridCell(0, 0));
    expect(h.puzzle.arrangement, expected.puzzle.arrangement);
  });

  testWidgets('loose tiles still move alone with the original swap', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    final before = h.puzzle;
    final g = await h.dragTo(
      GridCell(0, 0),
      h.globalOf(GridCell(3, 3)),
      release: false,
    );
    expect(h.game.draggedUnit, [h.componentAt(GridCell(0, 0))]);
    expect(h.game.targetMarker.groupRects, isEmpty);
    await g.up();
    await h.settle();
    final swapped = before.swap(GridCell(0, 0), GridCell(3, 3)) as TilesSwapped;
    expect(h.puzzle.arrangement, swapped.puzzle.arrangement);
  });

  testWidgets('a loose tile still swaps with any tile, as in M3.1', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    final before = h.puzzle;
    final g = await h.dragTo(
      GridCell(0, 0),
      h.globalOf(GridCell(2, 2)),
      release: false,
    );
    expect(h.game.targetMarker.rect, h.game.area.cellRect(GridCell(2, 2)));
    expect(h.game.hoveredTile, h.componentAt(GridCell(2, 2)));
    await g.up();
    await h.settle();
    final swapped = before.swap(GridCell(0, 0), GridCell(2, 2)) as TilesSwapped;
    expect(h.puzzle.arrangement, swapped.puzzle.arrangement);
    // Tile 10 left the L; the rest regroup by alignment.
    expect(h.puzzle.groupAt(GridCell(1, 1)), {GridCell(1, 1), GridCell(2, 1)});
  });

  testWidgets('two matching tiles join away from their final cells; then '
      'either one moves both', (tester) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    // Put tile 1 directly right of tile 0 (tile 0 is in cell (1,0)).
    final t0 = h.puzzle.cellOf(h.puzzle.tiles[0]);
    expect(t0, GridCell(1, 0));
    await h.swap(h.puzzle.cellOf(h.puzzle.tiles[1]), GridCell(1, 1));
    expect(h.puzzle.isTileCorrect(h.puzzle.tiles[0]), isFalse);
    final pair = h.puzzle.groupAt(GridCell(1, 0));
    expect(pair, containsAll([GridCell(1, 0), GridCell(1, 1)]));
    expect(
      h.componentAt(GridCell(1, 0)).joinedSides & TileComponent.sideRight,
      isNonZero,
    );
    // Grab either member: both lift.
    for (final grab in [GridCell(1, 0), GridCell(1, 1)]) {
      final g = await h.dragTo(
        grab,
        h.globalOf(grab) + const Offset(0, 30),
        release: false,
      );
      expect(
        h.game.draggedUnit.map((c) => c.tile.id).toSet(),
        containsAll([0, 1]),
      );
      await g.up();
      await h.settle();
    }
    // Move the pair home: (1,0) → (0,0).
    await h.swap(GridCell(1, 0), GridCell(0, 0));
    expect(h.puzzle.tileAt(GridCell(0, 0)).id, 0);
    expect(h.puzzle.tileAt(GridCell(0, 1)).id, 1);
  });

  testWidgets('a group that would leave the board glides back as a unit', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    final before = h.puzzle.arrangement;
    // Grabbing (1,1) and dropping on (3,3) would push (2,2) to row 4.
    await h.swap(GridCell(1, 1), GridCell(3, 3));
    expect(h.puzzle.arrangement, before);
    for (final cell in lCells) {
      expectAt(h, h.componentAt(cell), cell);
    }
    expect(h.game.inputEnabled, isTrue);
  });

  testWidgets('group-to-group: both groups keep their shape', (tester) async {
    // Find a seed whose start allows a group to displace a whole other
    // group (deterministic search with the domain).
    late int seed;
    late GridCell from, to;
    late Set<GridCell> other;
    search:
    for (var s = 0; s < 20000; s++) {
      final p = PicturePuzzle.shuffled(
        GridSize(4, 4),
        SourceSize(1024, 1024),
        seed: s,
      );
      final groups = p.connectedGroups;
      if (groups.length < 2) continue;
      for (final g in groups) {
        for (final a in g) {
          for (final b in p.grid.cells) {
            final o = p.moveGroup(a, b);
            if (o is! GroupMoved) continue;
            for (final x in groups) {
              if (x != g && x.every(o.displaced.containsKey)) {
                (seed, from, to, other) = (s, a, b, x);
                break search;
              }
            }
          }
        }
      }
    }
    final h = await pumpPuzzle(tester, seed: seed);
    final before = where(h.puzzle);
    final mover = h.puzzle.groupAt(from)!;
    final moverIds = [for (final c in mover) h.puzzle.tileAt(c).id];
    final otherIds = [for (final c in other) h.puzzle.tileAt(c).id];
    await h.swap(from, to);
    final after = where(h.puzzle);
    Set<(int, int)> shifts(List<int> ids) => {
      for (final id in ids)
        (
          after[id]!.row - before[id]!.row,
          after[id]!.column - before[id]!.column,
        ),
    };
    expect(shifts(moverIds), {(to.row - from.row, to.column - from.column)});
    expect(shifts(otherIds), hasLength(1), reason: 'other group kept shape');
    expect(shifts(otherIds).single, isNot((0, 0)));
  });

  testWidgets('placing a tile next to correct tiles creates a group that then '
      'moves together; completion is unchanged', (tester) async {
    final h = await pumpPuzzle(tester, seed: groupSeed);
    // Tile 6 belongs in (1,2), next to the L: placing it extends the group.
    final tile6 = h.puzzle.tiles[6];
    await h.swap(h.puzzle.cellOf(tile6), GridCell(1, 2));
    expect(h.puzzle.groupAt(GridCell(1, 2)), {...lCells, GridCell(1, 2)});
    final g = await h.dragTo(
      GridCell(1, 2),
      h.globalOf(GridCell(1, 2)) + const Offset(0, -20),
      release: false,
    );
    expect(h.game.draggedUnit.map((c) => c.tile.id).toSet(), {5, 6, 9, 10});
    await g.up();
    await h.settle();
    // Solve the rest with ordinary drags; completion works as before.
    final swaps = await h.solve();
    expect(swaps, greaterThan(0));
    expect(h.puzzle.isComplete, isTrue);
    await h.settle(frames: 40);
    expect(find.byKey(const Key('completion')), findsOneWidget);
  });
}
