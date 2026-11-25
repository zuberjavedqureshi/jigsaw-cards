import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

void main() {
  ProviderContainer make(int seed) {
    final c = ProviderContainer(
      overrides: [initialSeedProvider.overrideWithValue(seed)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('same seed gives the same puzzle', () {
    final a = make(7).read(puzzleControllerProvider).session;
    final b = make(7).read(puzzleControllerProvider).session;
    expect(
      [for (final p in a.layout.pieces) (p.correctOrigin, p.size)],
      [for (final p in b.layout.pieces) (p.correctOrigin, p.size)],
    );
    expect(a.trayOrder, b.trayOrder);
  });

  test('accepted drop locks; completion is reported after lock animation', () {
    final c = make(3);
    final n = c.read(puzzleControllerProvider.notifier);
    for (final p in c.read(puzzleControllerProvider).session.layout.pieces) {
      n.pickUp(p.id);
      expect(n.drop(p.id, p.correctOrigin), isA<PlacementAccepted>());
      expect(c.read(puzzleControllerProvider).inFlightPieceId, p.id);
      n.lockFinished(p.id);
      expect(c.read(puzzleControllerProvider).inFlightPieceId, isNull);
    }
    final s = c.read(puzzleControllerProvider);
    expect(s.isComplete, isTrue);
    expect(s.showCompletion, isTrue);
  });

  test('completion not shown until the last lock animation finishes', () {
    final c = make(3);
    final n = c.read(puzzleControllerProvider.notifier);
    final pieces = c.read(puzzleControllerProvider).session.layout.pieces;
    for (final p in pieces) {
      n.drop(p.id, p.correctOrigin);
    }
    expect(c.read(puzzleControllerProvider).isComplete, isTrue);
    expect(c.read(puzzleControllerProvider).showCompletion, isFalse);
    n.lockFinished(pieces.last.id);
    expect(c.read(puzzleControllerProvider).showCompletion, isTrue);
  });

  test('rejected drop leaves state unchanged until return finishes', () {
    final c = make(5);
    final n = c.read(puzzleControllerProvider.notifier);
    final p = c.read(puzzleControllerProvider).session.trayPieces.first;
    n.pickUp(p.id);
    final wrong = GridCell(
      p.correctOrigin.row == 0 ? 1 : 0,
      p.correctOrigin.column,
    );
    final out = n.drop(p.id, wrong);
    expect(out, isA<PlacementRejected>());
    expect(c.read(puzzleControllerProvider).placedCount, 0);
    expect(c.read(puzzleControllerProvider).inFlightPieceId, p.id);
    n.returnFinished(p.id);
    expect(c.read(puzzleControllerProvider).inFlightPieceId, isNull);
  });

  test('locked piece cannot be placed again', () {
    final c = make(5);
    final n = c.read(puzzleControllerProvider.notifier);
    final p = c.read(puzzleControllerProvider).session.trayPieces.first;
    n.drop(p.id, p.correctOrigin);
    final again = n.drop(p.id, p.correctOrigin);
    expect(
      again,
      isA<PlacementRejected>().having(
        (r) => r.reason,
        'reason',
        PlacementRejection.alreadyLocked,
      ),
    );
  });

  test('new puzzle advances the seed and resets progress', () {
    final c = make(9);
    final n = c.read(puzzleControllerProvider.notifier);
    final p = c.read(puzzleControllerProvider).session.trayPieces.first;
    n.drop(p.id, p.correctOrigin);
    n.newPuzzle();
    final s = c.read(puzzleControllerProvider);
    expect(s.seed, 10);
    expect(s.placedCount, 0);
    expect(s.showCompletion, isFalse);
  });
}
