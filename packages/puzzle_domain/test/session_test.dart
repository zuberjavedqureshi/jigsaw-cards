import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final grid = GridSize(4, 4);
  final bounds = PlayBounds.prototype(grid);
  final layout = const ProvisionalRandomFillGenerator().generate(
    grid: grid,
    constraints: LayoutConstraints.prototype,
    seed: 7,
  );

  PuzzleSession start({int seed = 3}) =>
      PuzzleSession.start(layout, bounds: bounds, scatterSeed: seed);

  PuzzleSession playing() => start().beginPreview().endPreview();

  PuzzleSession revealed(PuzzleSession s, String id) =>
      (s.reveal(id) as PieceRevealed).session;

  PuzzleSession moved(PuzzleSession s, String id, BoardPoint to) =>
      (s.move(id, to) as PieceMoved).session;

  /// A wrong position for [p], far from its target, inside the bounds.
  BoardPoint wrongFor(PieceState p) => bounds.clampOrigin(
    BoardPoint(p.target.x >= 2 ? 0 : 2.5, 5),
    p.piece.size,
  );

  group('reveal sequence', () {
    test('initial pieces are face-down in intro and not interactive', () {
      final s = start();
      expect(s.phase, PuzzlePhase.intro);
      expect(s.isInteractive, isFalse);
      for (final p in s.pieces) {
        expect(s.isFaceUp(p.id), isFalse, reason: p.id);
        expect(p.revealed, isFalse);
        expect(p.locked, isFalse);
      }
    });

    test('preview reveals every piece and is not interactive', () {
      final s = start().beginPreview();
      expect(s.phase, PuzzlePhase.preview);
      expect(s.pieces.every((p) => s.isFaceUp(p.id)), isTrue);
      expect(s.isInteractive, isFalse);
      final p = s.pieces.first;
      expect(
        (s.reveal(p.id) as RevealRejected).reason,
        ActionRejection.notInteractive,
      );
      expect(
        (s.move(p.id, p.target) as MoveRejected).reason,
        ActionRejection.notInteractive,
      );
    });

    test('preview duration is exactly 4 seconds', () {
      expect(PuzzleSession.previewDuration, const Duration(seconds: 4));
    });

    test('ending the preview flips every piece face-down and enables play', () {
      final s = playing();
      expect(s.phase, PuzzlePhase.playing);
      expect(s.isInteractive, isTrue);
      expect(s.pieces.any((p) => s.isFaceUp(p.id)), isFalse);
    });

    test('phase transitions are enforced', () {
      expect(() => start().endPreview(), throwsStateError);
      expect(() => playing().beginPreview(), throwsStateError);
      expect(() => start().beginPreview().beginPreview(), throwsStateError);
    });

    test('tapping a piece reveals only that piece, and it stays revealed', () {
      final s0 = playing();
      final a = s0.pieces.first.id;
      final s1 = revealed(s0, a);
      expect(s1.isFaceUp(a), isTrue);
      for (final p in s1.pieces.where((p) => p.id != a)) {
        expect(s1.isFaceUp(p.id), isFalse, reason: p.id);
      }
      // Stays revealed after it is moved.
      final s2 = moved(s1, a, wrongFor(s1.piece(a)!));
      expect(s2.isFaceUp(a), isTrue);
      expect(
        (s2.reveal(a) as RevealRejected).reason,
        ActionRejection.alreadyRevealed,
      );
    });

    test('face-down pieces can be revealed independently, in any order', () {
      var s = playing();
      final ids = [for (final p in s.pieces) p.id].reversed.toList();
      for (var i = 0; i < ids.length; i++) {
        s = revealed(s, ids[i]);
        expect(s.pieces.where((p) => s.isFaceUp(p.id)).length, i + 1);
      }
    });

    test('unknown piece is rejected', () {
      expect(
        (playing().reveal('nope') as RevealRejected).reason,
        ActionRejection.unknownPiece,
      );
      expect(
        (playing().move('nope', BoardPoint.zero) as MoveRejected).reason,
        ActionRejection.unknownPiece,
      );
    });
  });

  group('free placement', () {
    test('face-down pieces cannot move', () {
      final s = playing();
      final p = s.pieces.first;
      expect(
        (s.move(p.id, p.target) as MoveRejected).reason,
        ActionRejection.faceDown,
      );
    });

    test('incorrect positions are accepted and kept where dropped', () {
      final s0 = playing();
      final p = s0.pieces.first;
      final s1 = revealed(s0, p.id);
      final to = wrongFor(p);
      final out = s1.move(p.id, to) as PieceMoved;
      expect(out.snapped, isFalse);
      expect(out.piece.position, to);
      expect(out.piece.locked, isFalse);
      expect(out.piece.isAtTarget, isFalse);
      expect(out.session.lockedCount, 0);
    });

    test('incorrect pieces can be moved again, repeatedly', () {
      var s = playing();
      final p = s.pieces.first;
      s = revealed(s, p.id);
      for (final to in [
        wrongFor(p),
        const BoardPoint(1.37, 6.2),
        const BoardPoint(-0.1, 4.9),
      ]) {
        s = moved(s, p.id, bounds.clampOrigin(to, p.piece.size));
        expect(s.piece(p.id)!.position, bounds.clampOrigin(to, p.piece.size));
      }
      s = moved(s, p.id, p.target);
      expect(s.piece(p.id)!.locked, isTrue);
    });

    test('overlapping pieces are allowed', () {
      var s = playing();
      final [a, b, ...] = s.pieces.toList();
      s = revealed(revealed(s, a.id), b.id);
      const spot = BoardPoint(1.2, 5.2);
      s = moved(s, a.id, spot);
      s = moved(s, b.id, spot);
      expect(s.piece(a.id)!.position, spot);
      expect(s.piece(b.id)!.position, spot);
      expect(s.stackOrder.last, b.id);
    });

    test('current position is separate from the correct target', () {
      final s0 = playing();
      for (final p in s0.pieces) {
        expect(p.target, BoardPoint.ofCell(p.piece.correctOrigin));
        expect(p.isAtTarget, isFalse, reason: 'starts away from target');
      }
      final p = s0.pieces.first;
      final s1 = moved(revealed(s0, p.id), p.id, wrongFor(p));
      expect(s1.piece(p.id)!.piece.correctOrigin, p.piece.correctOrigin);
      expect(s1.piece(p.id)!.position, isNot(p.target));
    });

    test('positions are clamped so pieces stay inside the bounds', () {
      var s = playing();
      final p = s.pieces.first;
      s = revealed(s, p.id);
      s = moved(s, p.id, const BoardPoint(-50, 99));
      final at = s.piece(p.id)!.position;
      expect(bounds.containsPiece(at, p.piece.size), isTrue);
      expect(at.x, bounds.left);
      expect(at.y, bounds.bottom - p.piece.size.rowSpan);
    });

    test('a drop within the snap tolerance snaps exactly and locks', () {
      var s = playing();
      final p = s.pieces.first;
      s = revealed(s, p.id);
      final near = p.target + const BoardPoint(0.25, -0.2);
      final out = s.move(p.id, near) as PieceMoved;
      expect(out.snapped, isTrue);
      expect(out.piece.position, p.target);
      expect(out.piece.locked, isTrue);
      expect(out.session.lockedCount, 1);
      expect(out.session.stackOrder.first, p.id, reason: 'locked go below');
    });

    test('a drop just outside the tolerance does not snap', () {
      var s = playing();
      final p = s.pieces.first;
      s = revealed(s, p.id);
      final out =
          s.move(p.id, p.target + const BoardPoint(0.31, 0)) as PieceMoved;
      expect(out.snapped, isFalse);
      expect(out.piece.locked, isFalse);
    });

    test('snap tolerance is configurable and validated', () {
      final strict = PuzzleSession.start(
        layout,
        bounds: bounds,
        scatterSeed: 3,
        snapTolerance: 0.05,
      ).beginPreview().endPreview();
      final p = strict.pieces.first;
      final s = revealed(strict, p.id);
      expect(
        (s.move(
          p.id,
          p.target + const BoardPoint(0.1, 0),
        ) as PieceMoved).snapped,
        isFalse,
      );
      expect(
        () => PuzzleSession.start(layout, bounds: bounds, snapTolerance: 0.5),
        throwsArgumentError,
      );
    });

    test('locked pieces cannot move, be revealed again or be selected', () {
      var s = playing();
      final p = s.pieces.first;
      s = moved(revealed(s, p.id), p.id, p.target);
      expect(
        (s.move(p.id, wrongFor(p)) as MoveRejected).reason,
        ActionRejection.locked,
      );
      expect((s.reveal(p.id) as RevealRejected).reason, ActionRejection.locked);
      expect(s.bringToFront(p.id), same(s));
      final centre =
          p.target +
          BoardPoint(p.piece.size.columnSpan / 2, p.piece.size.rowSpan / 2);
      expect(s.topmostSelectableAt(centre)?.id, isNot(p.id));
    });

    test('completion only when every piece is locked at its target', () {
      var s = playing();
      final ids = [for (final p in s.pieces) p.id];
      for (final id in ids) {
        s = revealed(s, id);
      }
      for (var i = 0; i < ids.length; i++) {
        final p = s.piece(ids[i])!;
        // A wrong move first never completes anything.
        s = moved(s, p.id, wrongFor(p));
        expect(s.isComplete, isFalse);
        final out = s.move(p.id, p.target) as PieceMoved;
        s = out.session;
        expect(out.completedPuzzle, i == ids.length - 1);
        expect(s.isComplete, i == ids.length - 1);
      }
      expect(s.phase, PuzzlePhase.complete);
      expect(s.pieces.every((p) => p.isAtTarget && p.locked), isTrue);
      expect(s.pieces.every((p) => s.isFaceUp(p.id)), isTrue);
      expect(s.isInteractive, isFalse);
    });

    test('sessions are immutable', () {
      final s0 = playing();
      final p = s0.pieces.first;
      final s1 = revealed(s0, p.id);
      moved(s1, p.id, wrongFor(p));
      expect(s0.isFaceUp(p.id), isFalse);
      expect(s1.piece(p.id)!.position, p.position);
    });
  });

  group('selection and stacking', () {
    test('topmost selectable piece wins when pieces overlap', () {
      var s = playing();
      final [a, b, c, ...] = s.pieces.toList();
      for (final id in [a.id, b.id, c.id]) {
        s = revealed(s, id);
      }
      const spot = BoardPoint(0.5, 5.0);
      s = moved(s, a.id, spot);
      s = moved(s, b.id, spot);
      const inside = BoardPoint(0.75, 5.25);
      expect(s.topmostSelectableAt(inside)!.id, b.id);
      s = s.bringToFront(a.id);
      expect(s.topmostSelectableAt(inside)!.id, a.id);
    });

    test('face-down pieces are selectable', () {
      final s = playing();
      for (final p in s.pieces) {
        // Some point of each piece must hit it (visible part); check its
        // own centre when it is the top piece there.
        final centre =
            p.position +
            BoardPoint(p.piece.size.columnSpan / 2, p.piece.size.rowSpan / 2);
        final hit = s.topmostSelectableAt(centre)!;
        expect(s.isFaceUp(hit.id), isFalse);
      }
    });

    test('a locked piece on top passes the hit through', () {
      var s = playing();
      final pieces = s.pieces.toList();
      final locked = pieces.first;
      final other = pieces[1];
      s = revealed(revealed(s, locked.id), other.id);
      s = moved(s, other.id, locked.target);
      // other may have snapped only if its target coincides; ensure not.
      expect(s.piece(other.id)!.locked, isFalse);
      s = moved(s, locked.id, locked.target);
      final centre = locked.target + const BoardPoint(0.5, 0.5);
      expect(s.topmostSelectableAt(centre)?.id, other.id);
    });

    test('empty space selects nothing', () {
      final s = playing();
      expect(s.topmostSelectableAt(const BoardPoint(-5, -5)), isNull);
    });
  });
}
