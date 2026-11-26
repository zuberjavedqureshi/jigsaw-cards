import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/ui/puzzle_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

const testSeed = 42;

class Harness {
  Harness(this.tester, this.container);
  final WidgetTester tester;
  final ProviderContainer container;

  PuzzleState get state => container.read(puzzleControllerProvider);
  PicturePuzzle get puzzle => state.puzzle;

  PuzzleGame get game => tester
      .widget<GameWidget<PuzzleGame>>(find.byType(GameWidget<PuzzleGame>))
      .game!;

  RenderBox get _box =>
      tester.renderObject<RenderBox>(find.byType(GameWidget<PuzzleGame>));

  Size get gameSize => _box.size;

  Offset globalOf(GridCell c) =>
      _box.localToGlobal(game.area.cellRect(c).center);

  Offset globalLocal(Offset local) => _box.localToGlobal(local);

  TileComponent componentAt(GridCell c) => game.tiles[puzzle.tileAt(c).id]!;

  /// Pumps until the puzzle introduction has finished (bounded).
  Future<void> finishIntro() async {
    for (var i = 0; i < 200 && !game.intro.isFinished; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.intro.isFinished, isTrue, reason: 'intro did not finish');
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> settle({int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Presses [from] and drags to [to] (global) in small steps; releases
  /// and settles unless [release] is false.
  Future<TestGesture> dragTo(
    GridCell from,
    Offset to, {
    bool release = true,
  }) async {
    final a = globalOf(from);
    final g = await tester.startGesture(a);
    await tester.pump(const Duration(milliseconds: 16));
    const steps = 10;
    for (var i = 1; i <= steps; i++) {
      await g.moveTo(Offset.lerp(a, to, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (release) {
      await g.up();
      await settle();
    }
    return g;
  }

  Future<void> swap(GridCell from, GridCell to) => dragTo(from, globalOf(to));

  /// Solves the puzzle by dragging the right tile into each cell in turn.
  Future<int> solve() async {
    var swaps = 0;
    for (final cell in puzzle.grid.cells) {
      final want = puzzle.tiles[cell.row * puzzle.grid.columns + cell.column];
      final at = puzzle.cellOf(want);
      if (at != cell) {
        await swap(at, cell);
        swaps++;
      }
    }
    return swaps;
  }
}

Future<Harness> pumpPuzzle(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  int seed = testSeed,
  bool waitForIntro = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [initialSeedProvider.overrideWithValue(seed)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PuzzleScreen())),
    ),
  );
  final h = Harness(tester, container);
  await h.settle(frames: 2);
  if (waitForIntro) await h.finishIntro();
  return h;
}

/// A cell whose current tile belongs somewhere else, and that tile's target.
(GridCell, GridCell) misplacedTileAndTarget(PicturePuzzle p) {
  final from = p.grid.cells.firstWhere((c) => !p.isTileCorrect(p.tileAt(c)));
  return (from, p.tileAt(from).target);
}
