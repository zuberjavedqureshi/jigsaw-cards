import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/ui/play_area_layout.dart';
import 'package:jigsaw_cards/ui/puzzle_screen.dart';
import 'package:jigsaw_cards/ui/tray.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

const testSeed = 42;

/// Pumps the puzzle screen at [size] logical pixels with a fixed seed.
Future<ProviderContainer> pumpPuzzle(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  int seed = testSeed,
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
  await settle(tester);
  return container;
}

/// Advances frames so Flame loads and effects finish.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

PuzzleState stateOf(ProviderContainer c) => c.read(puzzleControllerProvider);

PuzzleGame gameOf(WidgetTester tester) => tester
    .widget<GameWidget<PuzzleGame>>(find.byType(GameWidget<PuzzleGame>))
    .game!;

/// The play-area stack (game coordinates = its local coordinates).
RenderBox playArea(WidgetTester tester) => tester.renderObject<RenderBox>(
  find
      .ancestor(
        of: find.byType(GameWidget<PuzzleGame>),
        matching: find.byType(Stack),
      )
      .first,
);

PlayAreaLayout areaOf(WidgetTester tester, GridSize grid) =>
    PlayAreaLayout.compute(playArea(tester).size, grid);

/// Global centre of where [piece] would sit with its top-left at [origin].
Offset boardTargetCentre(
  WidgetTester tester,
  PuzzlePiece piece,
  GridCell origin,
) {
  final area = areaOf(tester, prototypeGrid);
  return playArea(tester)
      .localToGlobal(area.pieceRectAt(origin, piece.size).center);
}

/// Global centre of [piece]'s preview in its tray tile.
Offset trayPreviewCentre(WidgetTester tester, PuzzlePiece piece) {
  final tile = tester.getRect(find.byKey(Key('tray_${piece.id}')));
  return previewRectInTile(
    tile.shortestSide,
    piece.size,
  ).shift(tile.topLeft).center;
}

/// Drags [piece] from the tray, grabbing its preview centre, and drops it so
/// its centre is over the board position with top-left [origin].
Future<void> dragPieceTo(
  WidgetTester tester,
  PuzzlePiece piece,
  GridCell origin, {
  bool release = true,
}) async {
  final g = await tester.startGesture(trayPreviewCentre(tester, piece));
  await tester.pump();
  await g.moveBy(const Offset(0, -30));
  await tester.pump(const Duration(milliseconds: 50));
  await g.moveTo(boardTargetCentre(tester, piece, origin));
  await tester.pump(const Duration(milliseconds: 50));
  await settle(tester, frames: 4);
  if (release) {
    await g.up();
    await settle(tester);
  }
}

/// An in-bounds origin for [piece] that is not its correct origin.
GridCell wrongOriginFor(PuzzlePiece piece, GridSize grid) {
  for (final cell in grid.cells) {
    if (cell != piece.correctOrigin &&
        piece.cellsAt(cell).every(grid.contains)) {
      return cell;
    }
  }
  throw StateError('no wrong origin');
}
