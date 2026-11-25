import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final grid = GridSize(4, 4);
  final layout = const ProvisionalRandomFillGenerator().generate(
    grid: grid,
    constraints: LayoutConstraints.prototype,
    seed: 7,
  );

  PuzzleSession placeAll(PuzzleSession s, Iterable<PuzzlePiece> pieces) {
    for (final p in pieces) {
      s = (s.attemptPlacement(
        p.id,
        p.correctOrigin,
      ) as PlacementAccepted).session;
    }
    return s;
  }

  test('starts with every piece in the tray and nothing locked', () {
    final s = PuzzleSession.start(layout);
    expect(s.trayPieces.toSet(), layout.pieces.toSet());
    expect(s.lockedPieces, isEmpty);
    expect(s.isComplete, isFalse);
  });

  test('correct placement is accepted and locks the piece', () {
    final s = PuzzleSession.start(layout);
    final piece = layout.pieces.first;
    final outcome = s.attemptPlacement(piece.id, piece.correctOrigin);
    expect(outcome, isA<PlacementAccepted>());
    final next = (outcome as PlacementAccepted).session;
    expect(next.isLocked(piece.id), isTrue);
    expect(next.trayPieces, isNot(contains(piece)));
    expect(s.isLocked(piece.id), isFalse, reason: 'sessions are immutable');
  });

  test('wrong position is rejected and leaves the state unchanged', () {
    final s = PuzzleSession.start(layout);
    final piece = layout.pieces.firstWhere(
      (p) =>
          p.correctOrigin != const GridCell(0, 0) &&
          p.size == PieceSize.oneByOne,
      orElse: () => layout.pieces.last,
    );
    final wrong = piece.correctOrigin == const GridCell(0, 0)
        ? const GridCell(1, 1)
        : const GridCell(0, 0);
    final outcome = s.attemptPlacement(piece.id, wrong);
    expect(outcome, isA<PlacementRejected>());
    expect(
      (outcome as PlacementRejected).reason,
      PlacementRejection.wrongPosition,
    );
    expect(s.lockedPieces, isEmpty);
  });

  test('a placement extending off the board is rejected as out of bounds', () {
    final s = PuzzleSession.start(layout);
    final piece = layout.pieces.first;
    final outcome = s.attemptPlacement(piece.id, const GridCell(3, 4));
    expect(
      (outcome as PlacementRejected).reason,
      PlacementRejection.outOfBounds,
    );
  });

  test('unknown piece is rejected', () {
    final outcome = PuzzleSession.start(layout)
        .attemptPlacement('nope', const GridCell(0, 0));
    expect(
      (outcome as PlacementRejected).reason,
      PlacementRejection.unknownPiece,
    );
  });

  test('locked pieces cannot be moved again, even to their own position', () {
    final piece = layout.pieces.first;
    final s = placeAll(PuzzleSession.start(layout), [piece]);
    for (final target in [piece.correctOrigin, const GridCell(0, 0)]) {
      final outcome = s.attemptPlacement(piece.id, target);
      expect(
        (outcome as PlacementRejected).reason,
        PlacementRejection.alreadyLocked,
      );
    }
  });

  test('completion is detected only when every piece is locked, once', () {
    var s = PuzzleSession.start(layout);
    final pieces = layout.pieces;
    s = placeAll(s, pieces.take(pieces.length - 1));
    expect(s.isComplete, isFalse);
    final last = pieces.last;
    final outcome =
        s.attemptPlacement(last.id, last.correctOrigin) as PlacementAccepted;
    expect(outcome.completedPuzzle, isTrue);
    expect(outcome.session.isComplete, isTrue);
    expect(outcome.session.trayPieces, isEmpty);
  });

  test('earlier accepted placements do not report completion', () {
    final outcome = PuzzleSession.start(layout).attemptPlacement(
      layout.pieces.first.id,
      layout.pieces.first.correctOrigin,
    ) as PlacementAccepted;
    expect(outcome.completedPuzzle, isFalse);
  });

  test('tray order is a deterministic shuffle per seed', () {
    final a = PuzzleSession.start(layout, trayShuffleSeed: 3).trayPieces;
    final b = PuzzleSession.start(layout, trayShuffleSeed: 3).trayPieces;
    expect(a, b);
    expect(a.toSet(), layout.pieces.toSet());
  });
}
