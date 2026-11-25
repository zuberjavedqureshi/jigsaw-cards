import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

void main() {
  group('reveal sequence', () {
    testWidgets('starts face-down with an intro and no interaction', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      expect(h.state.phase, PuzzlePhase.intro);
      expect(h.state.totalCount, inInclusiveRange(8, 12));
      expect(find.byKey(const Key('intro')), findsOneWidget);
      expect(find.text('0 / ${h.state.totalCount}'), findsOneWidget);
      expect(h.game.pieces.values.every((p) => !p.showsFront), isTrue);
      expect(h.game.inputEnabled, isFalse);
      // Only the intro is scheduled so far.
      expect(h.clock.pending.map((c) => c.delay), [introDuration]);
      // Tapping does nothing.
      final id = h.session.stackOrder.last;
      await h.tapPiece(id);
      expect(h.session.isFaceUp(id), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('preview flips every piece up and holds exactly 4 s', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      expect(h.clock.fireNext(), introDuration);
      await tester.pump(const Duration(milliseconds: 16));
      expect(h.state.phase, PuzzlePhase.preview);
      // The 4 s hold starts only once the flip-up has finished.
      expect(h.clock.pending, isEmpty);
      expect(h.game.isAnimating, isTrue);
      await h.settle();
      expect(h.game.pieces.values.every((p) => p.showsFront), isTrue);
      expect(h.clock.pending.single.delay, const Duration(seconds: 4));
      expect(h.state.previewDuration, const Duration(seconds: 4));
      expect(find.text('Memorise the pieces!'), findsOneWidget);
      // No interaction during the preview.
      expect(h.game.inputEnabled, isFalse);
      final id = h.session.stackOrder.last;
      final before = h.session.piece(id)!.position;
      await h.dragBoard(
        h.visiblePointOf(id),
        h.visiblePointOf(id) + const BoardPoint(1, 1),
      );
      expect(h.session.piece(id)!.position, before);
    });

    testWidgets('after the preview every piece flips face-down and play '
        'starts', (tester) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      expect(h.state.phase, PuzzlePhase.playing);
      expect(h.game.pieces.values.every((p) => !p.showsFront), isTrue);
      expect(find.byKey(const Key('intro')), findsNothing);
      expect(
        find.text('Tap a card to reveal it · drag to place it'),
        findsOneWidget,
      );
    });

    testWidgets('tapping reveals only that piece; it stays revealed', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final ids = h.session.stackOrder.toList();
      final a = ids[ids.length - 1];
      await h.tapPiece(a);
      expect(h.game.pieces[a]!.showsFront, isTrue);
      for (final id in ids.where((id) => id != a)) {
        expect(h.game.pieces[id]!.showsFront, isFalse, reason: id);
        expect(h.session.isFaceUp(id), isFalse);
      }
      // Revealing a second piece leaves the first face-up.
      final b = ids.first;
      await h.tapPiece(b);
      expect(h.game.pieces[a]!.showsFront, isTrue);
      expect(h.game.pieces[b]!.showsFront, isTrue);
      // A revealed piece is raised to the top.
      expect(h.session.stackOrder.last, b);
    });

    testWidgets('flip animation: back, edge-on, then front', (tester) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final id = h.session.stackOrder.last;
      final c = h.game.pieces[id]!;
      await tester.tapAt(h.global(h.visiblePointOf(id)));
      await tester.pump(const Duration(milliseconds: 16));
      expect(c.isFlipping, isTrue);
      expect(c.showsFront, isFalse);
      await tester.pump(const Duration(milliseconds: 250));
      expect(c.showsFront, isTrue);
      await h.settle();
      expect(c.isFlipping, isFalse);
      expect(c.showsFront, isTrue);
    });
  });

  group('free placement', () {
    testWidgets('face-down pieces cannot be dragged', (tester) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final id = h.session.stackOrder.last;
      final before = h.session.piece(id)!.position;
      await h.dragBoard(
        h.visiblePointOf(id),
        h.visiblePointOf(id) + const BoardPoint(-1.5, -1.5),
      );
      expect(h.session.piece(id)!.position, before);
      expect(h.session.isFaceUp(id), isFalse);
    });

    testWidgets('wrong drops stay where dropped and can be moved again', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final id = h.session.stackOrder.last;
      await h.reveal(id);
      final p = h.session.piece(id)!;
      final wrong = h.session.bounds.clampOrigin(
        BoardPoint(p.target.x >= 2 ? 0.1 : 2.4, 5.5),
        p.piece.size,
      );
      await h.dragPieceTo(id, wrong);
      final s1 = h.session.piece(id)!;
      expect(s1.locked, isFalse);
      expect(s1.position.chebyshevTo(wrong), lessThan(0.05));
      expect(s1.isAtTarget, isFalse);
      expect(h.session.isFaceUp(id), isTrue, reason: 'stays face-up');
      // Component rests at the dropped position.
      final r = h.game.area.pieceRect(s1.position, s1.piece.size);
      expect(h.game.pieces[id]!.position.x, closeTo(r.center.dx, 0.5));
      // Move it again.
      final again = h.session.bounds.clampOrigin(
        const BoardPoint(1.0, 6.0),
        p.piece.size,
      );
      await h.dragPieceTo(id, again);
      expect(h.session.piece(id)!.position.chebyshevTo(again), lessThan(0.05));
      expect(h.state.placedCount, 0);
    });

    testWidgets('overlap is allowed and the topmost piece is selected', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final ids = h.session.stackOrder.toList();
      final a = ids[ids.length - 1];
      final b = ids[ids.length - 2];
      await h.reveal(a);
      await h.reveal(b);
      // Put both at the same free spot (away from both targets).
      const spot = BoardPoint(1.3, 5.6);
      await h.dragPieceTo(
        a,
        h.session.bounds.clampOrigin(spot, h.session.piece(a)!.piece.size),
      );
      await h.dragPieceTo(
        b,
        h.session.bounds.clampOrigin(spot, h.session.piece(b)!.piece.size),
      );
      expect(h.session.stackOrder.last, b);
      final overlapPoint =
          h.session.piece(b)!.position + const BoardPoint(0.3, 0.3);
      expect(h.session.piece(a)!.contains(overlapPoint), isTrue);
      // A drag at the overlap moves the topmost piece (b), not a.
      final aBefore = h.session.piece(a)!.position;
      await h.dragBoard(overlapPoint, overlapPoint + const BoardPoint(0, -1.2));
      expect(h.session.piece(a)!.position, aBefore);
      expect(h.session.piece(b)!.position.y, lessThan(aBefore.y));
      // Tapping a's visible part selects it and raises it.
      await h.tapPiece(a);
      expect(h.session.stackOrder.last, a);
    });

    testWidgets('correct alignment snaps, locks and cannot move again', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final id = h.session.stackOrder.last;
      await h.reveal(id);
      final p = h.session.piece(id)!;
      // Drop slightly off target, within tolerance.
      await h.dragPieceTo(id, p.target + const BoardPoint(0.2, -0.15));
      final s = h.session.piece(id)!;
      expect(s.locked, isTrue);
      expect(s.position, s.target);
      expect(find.text('1 / ${h.state.totalCount}'), findsOneWidget);
      final c = h.game.pieces[id]!;
      final r = h.game.area.pieceRect(s.target, s.piece.size);
      expect(c.position.x, closeTo(r.center.dx, 0.5));
      expect(c.position.y, closeTo(r.center.dy, 0.5));
      expect(c.locked, isTrue);
      // Dragging on it does not move it.
      final centre =
          s.target +
          BoardPoint(s.piece.size.columnSpan / 2, s.piece.size.rowSpan / 2);
      // Hit testing never selects the locked piece.
      expect(h.session.topmostSelectableAt(centre)?.id, isNot(id));
      await h.dragBoard(centre, centre + const BoardPoint(0, 2));
      expect(h.session.piece(id)!.position, s.target);
      expect(h.session.piece(id)!.locked, isTrue);
      expect(c.position.y, closeTo(r.center.dy, 0.5));
    });

    testWidgets('dragging past the edges keeps the piece fully on the board', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final id = h.session.stackOrder.last;
      await h.reveal(id);
      final grab = h.visiblePointOf(id);
      // Far beyond the bottom-right and then the top-left.
      for (final dest in const [BoardPoint(40, 60), BoardPoint(-40, -60)]) {
        final from = h.visiblePointOf(id);
        await h.dragBoard(from, dest);
        final s = h.session.piece(id)!;
        expect(
          h.session.bounds.containsPiece(s.position, s.piece.size),
          isTrue,
        );
        final r = h.game.area.pieceRect(s.position, s.piece.size);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(h.gameSize.width));
        expect(r.bottom, lessThanOrEqualTo(h.gameSize.height));
      }
      expect(grab, isNotNull);
    });

    testWidgets('assembling every piece completes the puzzle', (tester) async {
      final h = await pumpPuzzle(tester);
      await h.toPlaying();
      final total = h.state.totalCount;
      var guard = 0;
      while (!h.session.isComplete && guard++ < 40) {
        final next = h.session.stackOrder.lastWhere(
          (id) => !h.session.piece(id)!.locked,
        );
        if (!h.session.isFaceUp(next)) await h.reveal(next);
        final p = h.session.piece(next)!;
        await h.dragPieceTo(next, p.target);
        expect(h.session.piece(next)!.locked, isTrue, reason: next);
        if (!h.session.isComplete) {
          expect(find.byKey(const Key('completion')), findsNothing);
        }
      }
      expect(h.session.isComplete, isTrue);
      await h.settle();
      expect(find.byKey(const Key('completion')), findsOneWidget);
      expect(find.text('All $total pieces placed'), findsOneWidget);
      expect(
        h.game.pieces.values.every((p) => p.locked && p.showsFront),
        isTrue,
      );

      await tester.tap(find.byKey(const Key('new_puzzle')));
      await h.settle();
      expect(h.state.seed, testSeed + 1);
      expect(h.state.phase, PuzzlePhase.intro);
      expect(find.byKey(const Key('completion')), findsNothing);
      expect(h.game.pieces.values.every((p) => !p.showsFront), isTrue);
    });
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
        final area = h.game.area;
        final g = h.gameSize;
        // Whole workspace on screen, square cells, comfortable targets.
        expect(area.workspace.left, greaterThanOrEqualTo(0));
        expect(area.workspace.top, greaterThanOrEqualTo(0));
        expect(area.workspace.right, lessThanOrEqualTo(g.width + 0.01));
        expect(area.workspace.bottom, lessThanOrEqualTo(g.height + 0.01));
        expect(area.cellSize, greaterThanOrEqualTo(48));
        // Every scattered piece is fully visible and individually hittable.
        for (final p in h.session.pieces) {
          final r = area.pieceRect(p.position, p.piece.size);
          expect(area.workspace.inflate(0.01).contains(r.topLeft), isTrue);
          expect(area.workspace.inflate(0.01).contains(r.bottomRight), isTrue);
          expect(h.visiblePointOf(p.id), isNotNull);
        }
      });
    }
  });
}
