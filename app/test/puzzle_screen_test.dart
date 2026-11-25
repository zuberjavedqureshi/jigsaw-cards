import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/ui/play_area_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'puzzle_test_harness.dart';

void main() {
  testWidgets('initial render: board, tray with all pieces, progress', (
    tester,
  ) async {
    final c = await pumpPuzzle(tester);
    final s = stateOf(c);
    expect(s.totalCount, inInclusiveRange(8, 12));
    expect(find.byKey(const Key('tray')), findsOneWidget);
    expect(find.text('0 / ${s.totalCount}'), findsOneWidget);
    expect(find.byKey(const Key('completion')), findsNothing);
    // The first tray piece is visible and laid out.
    final first = s.session.trayPieces.first;
    expect(find.byKey(Key('tray_${first.id}')), findsOneWidget);
    final game = gameOf(tester);
    expect(game.isLoaded, isTrue);
    expect(game.lockedById, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking up a piece enlarges it to board scale and empties '
      'its tray slot', (tester) async {
    final c = await pumpPuzzle(tester);
    final piece = stateOf(c).session.trayPieces.first;
    final wrong = wrongOriginFor(piece, prototypeGrid);
    await dragPieceTo(tester, piece, wrong, release: false);

    expect(stateOf(c).inFlightPieceId, piece.id);
    final f = gameOf(tester).floating!;
    final area = areaOf(tester, prototypeGrid);
    expect(f.size.x, closeTo(piece.size.columnSpan * area.cellSize, 0.5));
    expect(f.size.y, closeTo(piece.size.rowSpan * area.cellSize, 0.5));
    // Drop highlight is shown over the board.
    expect(gameOf(tester).board.hoverRect, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(Key('tray_${piece.id}')),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('correct drop snaps and locks the piece', (tester) async {
    final c = await pumpPuzzle(tester);
    final piece = stateOf(c).session.trayPieces.first;
    await dragPieceTo(tester, piece, piece.correctOrigin);

    final s = stateOf(c);
    expect(s.session.isLocked(piece.id), isTrue);
    expect(s.inFlightPieceId, isNull);
    expect(find.text('1 / ${s.totalCount}'), findsOneWidget);
    expect(find.byKey(Key('tray_${piece.id}')), findsNothing);
    final game = gameOf(tester);
    expect(game.floating, isNull);
    final locked = game.lockedById[piece.id]!;
    final expected = areaOf(
      tester,
      prototypeGrid,
    ).pieceRectAt(piece.correctOrigin, piece.size);
    expect(locked.position.x, closeTo(expected.center.dx, 0.5));
    expect(locked.position.y, closeTo(expected.center.dy, 0.5));
  });

  testWidgets('incorrect drop returns the piece to the tray', (tester) async {
    final c = await pumpPuzzle(tester);
    final piece = stateOf(c).session.trayPieces.first;
    await dragPieceTo(tester, piece, wrongOriginFor(piece, prototypeGrid));

    final s = stateOf(c);
    expect(s.session.isLocked(piece.id), isFalse);
    expect(s.inFlightPieceId, isNull);
    expect(s.placedCount, 0);
    expect(gameOf(tester).floating, isNull);
    expect(gameOf(tester).lockedById, isEmpty);
    expect(
      find.descendant(
        of: find.byKey(Key('tray_${piece.id}')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('drop off the board returns the piece', (tester) async {
    final c = await pumpPuzzle(tester);
    final piece = stateOf(c).session.trayPieces.first;
    final g = await tester.startGesture(trayPreviewCentre(tester, piece));
    await tester.pump();
    await g.moveBy(const Offset(0, -30));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveTo(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 50));
    await g.up();
    await settle(tester);
    expect(stateOf(c).placedCount, 0);
    expect(stateOf(c).inFlightPieceId, isNull);
    expect(gameOf(tester).floating, isNull);
  });

  testWidgets('locked pieces cannot be picked up or displaced', (tester) async {
    final c = await pumpPuzzle(tester);
    final pieces = stateOf(c).session.trayPieces;
    final first = pieces.first;
    await dragPieceTo(tester, first, first.correctOrigin);
    expect(stateOf(c).session.isLocked(first.id), isTrue);

    // Dragging on the locked piece on the board does nothing.
    final onBoard = boardTargetCentre(tester, first, first.correctOrigin);
    final g = await tester.startGesture(onBoard);
    await g.moveBy(const Offset(0, -60));
    await g.up();
    await settle(tester);
    expect(stateOf(c).inFlightPieceId, isNull);
    expect(gameOf(tester).floating, isNull);

    // Dropping another piece onto the locked piece's position is rejected
    // (no two pieces share an origin) and the locked piece stays put.
    final other = stateOf(c).session.trayPieces.first;
    await dragPieceTo(tester, other, first.correctOrigin);
    expect(stateOf(c).session.isLocked(other.id), isFalse);
    expect(stateOf(c).session.isLocked(first.id), isTrue);
    expect(gameOf(tester).floating, isNull);
    expect(gameOf(tester).lockedById.keys, contains(first.id));
  });

  testWidgets('placing every piece completes the puzzle; new puzzle resets', (
    tester,
  ) async {
    final c = await pumpPuzzle(tester);
    final total = stateOf(c).totalCount;
    while (stateOf(c).session.trayPieces.isNotEmpty) {
      final piece = stateOf(c).session.trayPieces.first;
      await dragPieceTo(tester, piece, piece.correctOrigin);
      expect(stateOf(c).session.isLocked(piece.id), isTrue, reason: piece.id);
    }
    expect(stateOf(c).isComplete, isTrue);
    expect(stateOf(c).showCompletion, isTrue);
    expect(find.byKey(const Key('completion')), findsOneWidget);
    expect(find.text('Puzzle complete!'), findsOneWidget);
    expect(find.text('All $total pieces placed'), findsOneWidget);
    expect(gameOf(tester).lockedById.length, total);

    await tester.tap(find.byKey(const Key('new_puzzle')));
    await settle(tester);
    expect(stateOf(c).seed, testSeed + 1);
    expect(stateOf(c).placedCount, 0);
    expect(find.byKey(const Key('completion')), findsNothing);
    expect(gameOf(tester).lockedById, isEmpty);
  });

  group('responsive layout', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(412, 915),
      Size(480, 1000),
      Size(600, 960),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpPuzzle(tester, size: size);
        expect(tester.takeException(), isNull);
        final area = areaOf(tester, prototypeGrid);
        final playSize = playArea(tester).size;
        // Board fits, is square-celled, and does not overlap the tray.
        expect(area.cellSize, greaterThan(40));
        expect(area.board.left, greaterThanOrEqualTo(0));
        expect(area.board.right, lessThanOrEqualTo(playSize.width));
        expect(area.board.bottom, lessThanOrEqualTo(area.tray.top));
        expect(area.board.width, closeTo(area.board.height, 0.01));
        // Tray tiles are comfortable touch targets (>= 48 dp).
        final tray = tester.getSize(find.byKey(const Key('tray')));
        expect(tray.height, closeTo(PlayAreaLayout.trayHeight, 0.01));
        final tileRects = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('tray_'),
        );
        expect(tileRects, findsWidgets);
        for (final e in tileRects.evaluate()) {
          final r = tester.getSize(find.byWidget(e.widget));
          expect(r.shortestSide, greaterThanOrEqualTo(48));
        }
      });
    }
  });
}
