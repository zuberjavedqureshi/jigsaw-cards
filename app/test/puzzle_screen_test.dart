import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

void main() {
  testWidgets('renders the shuffled board: one tile per cell, face-up', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    expect(h.puzzle.isComplete, isFalse);
    expect(h.game.tiles, hasLength(16));
    expect(find.text('${h.puzzle.correctCount} / 16'), findsOneWidget);
    expect(find.text('Drag a tile onto another to swap them'), findsOneWidget);
    expect(find.byKey(const Key('completion')), findsNothing);
    // Each tile component sits exactly on the cell the domain says.
    for (final cell in h.puzzle.grid.cells) {
      final c = h.componentAt(cell);
      final r = h.game.area.cellRect(cell);
      expect(c.position.x, closeTo(r.center.dx, 0.01));
      expect(c.position.y, closeTo(r.center.dy, 0.01));
      expect(c.size.x, closeTo(r.width, 0.01));
      expect(c.size.y, closeTo(r.height, 0.01));
    }
    // Square source → square, equal tiles: no stretching.
    expect(h.game.area.cellWidth, closeTo(h.game.area.cellHeight, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing a tile gives immediate selection feedback', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final cell = GridCell(1, 1);
    final g = await tester.startGesture(h.globalOf(cell));
    await tester.pump(const Duration(milliseconds: 120));
    expect(h.componentAt(cell).pressed, isTrue);
    await g.up();
    await h.settle(frames: 2);
    expect(h.componentAt(cell).pressed, isFalse);
    // A tap alone never swaps anything.
    expect(h.state.swaps, 0);
  });

  testWidgets('dragging lifts the tile and highlights the target tile', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final from = GridCell(0, 0);
    final to = GridCell(2, 3);
    final dragged = h.componentAt(from);
    final target = h.componentAt(to);
    final g = await h.dragTo(from, h.globalOf(to), release: false);
    expect(h.game.draggedTile, dragged);
    expect(dragged.lifted, isTrue);
    expect(h.game.hoveredTile, target);
    expect(target.hovered, isTrue);
    // The dragged tile follows the finger.
    final r = h.game.area.cellRect(to);
    expect(dragged.position.x, closeTo(r.center.dx, 1));
    await g.up();
    await h.settle();
  });

  testWidgets('dropping a tile on another exchanges them, animated', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final from = GridCell(0, 0);
    final to = GridCell(3, 2);
    final a = h.puzzle.tileAt(from);
    final b = h.puzzle.tileAt(to);
    final g = await h.dragTo(from, h.globalOf(to), release: false);
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
    // Logical state changes at once; tiles are still travelling.
    expect(h.puzzle.tileAt(to), a);
    expect(h.puzzle.tileAt(from), b);
    expect(h.game.isAnimating, isTrue);
    expect(h.game.inputEnabled, isFalse);
    await h.settle();
    expect(h.game.isAnimating, isFalse);
    expect(h.game.inputEnabled, isTrue);
    // Rendered positions match the logical board.
    final ra = h.game.area.cellRect(to).center;
    final rb = h.game.area.cellRect(from).center;
    expect(h.game.tiles[a.id]!.position.x, closeTo(ra.dx, 0.01));
    expect(h.game.tiles[a.id]!.position.y, closeTo(ra.dy, 0.01));
    expect(h.game.tiles[b.id]!.position.x, closeTo(rb.dx, 0.01));
    expect(h.game.tiles[b.id]!.position.y, closeTo(rb.dy, 0.01));
    expect(h.game.tiles[a.id]!.lifted, isFalse);
    expect(h.state.swaps, 1);
  });

  testWidgets('no second swap can start while tiles are animating', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final g = await h.dragTo(
      GridCell(0, 0),
      h.globalOf(GridCell(0, 1)),
      release: false,
    );
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
    final before = [...h.puzzle.arrangement];
    // Immediately try another drag while the exchange is running.
    final g2 = await tester.startGesture(h.globalOf(GridCell(2, 2)));
    for (var i = 1; i <= 6; i++) {
      await g2.moveTo(
        Offset.lerp(
          h.globalOf(GridCell(2, 2)),
          h.globalOf(GridCell(3, 3)),
          i / 6,
        )!,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g2.up();
    await h.settle();
    expect(h.puzzle.arrangement, before);
    expect(h.state.swaps, 1);
  });

  testWidgets('a real resize mid-swap still settles on the logical cells', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final g = await h.dragTo(
      GridCell(0, 0),
      h.globalOf(GridCell(3, 3)),
      release: false,
    );
    await g.up();
    await tester.pump(const Duration(milliseconds: 40));
    expect(h.game.isAnimating, isTrue);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump(const Duration(milliseconds: 16));
    await h.settle();
    expect(h.game.isAnimating, isFalse);
    expect(h.game.inputEnabled, isTrue);
    for (final t in h.puzzle.tiles) {
      final r = h.game.area.cellRect(h.puzzle.cellOf(t)).center;
      expect(h.game.tiles[t.id]!.position.x, closeTo(r.dx, 0.01));
      expect(h.game.tiles[t.id]!.position.y, closeTo(r.dy, 0.01));
    }
  });

  testWidgets('a drop outside the board cancels and returns the tile', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final from = GridCell(1, 2);
    final tile = h.puzzle.tileAt(from);
    final before = [...h.puzzle.arrangement];
    // Far above the board (into the header area of the play surface).
    await h.dragTo(from, h.globalLocal(const Offset(5, 3)));
    expect(h.puzzle.arrangement, before);
    expect(h.state.swaps, 0);
    final r = h.game.area.cellRect(from).center;
    expect(h.game.tiles[tile.id]!.position.x, closeTo(r.dx, 0.01));
    expect(h.game.tiles[tile.id]!.position.y, closeTo(r.dy, 0.01));
    expect(h.game.tiles[tile.id]!.lifted, isFalse);
    expect(h.game.inputEnabled, isTrue);
  });

  testWidgets('a drop back on its own cell does nothing', (tester) async {
    final h = await pumpPuzzle(tester);
    final from = GridCell(2, 1);
    final before = [...h.puzzle.arrangement];
    final g = await h.dragTo(from, h.globalOf(GridCell(2, 2)), release: false);
    await g.moveTo(h.globalOf(from));
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.game.hoveredTile, isNull);
    await g.up();
    await h.settle();
    expect(h.puzzle.arrangement, before);
    expect(h.state.swaps, 0);
  });

  testWidgets('a tile swapped into its correct cell glows and counts', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final (from, target) = misplacedTileAndTarget(h.puzzle);
    final tile = h.puzzle.tileAt(from);
    final before = h.puzzle.correctCount;
    final g = await h.dragTo(from, h.globalOf(target), release: false);
    await g.up();
    await h.settle(frames: 6); // 300 ms: swap done, glow still fading
    final c = h.game.tiles[tile.id]!;
    expect(h.puzzle.isTileCorrect(tile), isTrue);
    expect(c.correct, isTrue);
    expect(c.isGlowing, isTrue);
    expect(h.puzzle.correctCount, greaterThan(before));
    expect(find.text('${h.puzzle.correctCount} / 16'), findsOneWidget);
    await h.settle();
    expect(c.isGlowing, isFalse);
  });

  testWidgets('incorrect swaps are accepted', (tester) async {
    final h = await pumpPuzzle(tester);
    // Find two tiles neither of which belongs in the other's cell.
    final cells = h.puzzle.grid.cells.toList();
    late GridCell a, b;
    outer:
    for (final x in cells) {
      for (final y in cells) {
        if (x == y) continue;
        if (h.puzzle.tileAt(x).target != y && h.puzzle.tileAt(y).target != x) {
          a = x;
          b = y;
          break outer;
        }
      }
    }
    final correctBefore = h.puzzle.correctCount;
    final ta = h.puzzle.tileAt(a);
    await h.swap(a, b);
    expect(h.puzzle.tileAt(b), ta);
    expect(h.state.swaps, 1);
    expect(h.puzzle.correctCount, lessThanOrEqualTo(correctBefore));
  });

  testWidgets('solving shows the completed picture; New puzzle resets', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final swaps = await h.solve();
    expect(swaps, greaterThan(0));
    expect(h.puzzle.isComplete, isTrue);
    expect(find.text('16 / 16'), findsOneWidget);
    await h.settle(frames: 30);
    expect(find.byKey(const Key('completion')), findsOneWidget);
    expect(find.text('Puzzle complete!'), findsOneWidget);
    expect(find.byKey(const Key('completed_picture')), findsOneWidget);
    expect(find.text('Solved in $swaps swaps'), findsOneWidget);
    expect(h.game.inputEnabled, isFalse);
    // Every tile rests in its correct cell.
    for (final t in h.puzzle.tiles) {
      final r = h.game.area.cellRect(t.target).center;
      expect(h.game.tiles[t.id]!.position.x, closeTo(r.dx, 0.01));
    }

    await tester.tap(find.byKey(const Key('new_puzzle')));
    await h.settle();
    expect(h.state.seed, testSeed + 1);
    expect(h.puzzle.isComplete, isFalse);
    expect(h.state.swaps, 0);
    expect(find.byKey(const Key('completion')), findsNothing);
    expect(h.game.inputEnabled, isTrue);
  });

  group('responsive layout', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(480, 1000),
      Size(600, 960),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        final h = await pumpPuzzle(tester, size: size);
        expect(tester.takeException(), isNull);
        final b = h.game.area.board;
        final g = h.gameSize;
        expect(b.left, greaterThanOrEqualTo(0));
        expect(b.top, greaterThanOrEqualTo(0));
        expect(b.right, lessThanOrEqualTo(g.width + 0.01));
        expect(b.bottom, lessThanOrEqualTo(g.height + 0.01));
        expect(b.width / b.height, closeTo(1, 0.001), reason: 'no stretch');
        // Comfortable touch targets.
        expect(h.game.area.cellWidth, greaterThanOrEqualTo(64));
      });
    }

    testWidgets('touch swap works on a small screen (320x568)', (tester) async {
      final h = await pumpPuzzle(tester, size: const Size(320, 568));
      final a = h.puzzle.tileAt(GridCell(3, 0));
      await h.swap(GridCell(3, 0), GridCell(0, 3));
      expect(h.puzzle.tileAt(GridCell(0, 3)), a);
    });
  });
}
