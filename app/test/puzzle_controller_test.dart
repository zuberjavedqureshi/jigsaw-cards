import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

void main() {
  late ManualScheduler clock;

  ProviderContainer make(int seed) {
    clock = ManualScheduler();
    final c = ProviderContainer(
      overrides: [
        initialSeedProvider.overrideWithValue(seed),
        schedulerProvider.overrideWithValue(clock.scheduler),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  PuzzleController ctl(ProviderContainer c) =>
      c.read(puzzleControllerProvider.notifier);
  PuzzleState st(ProviderContainer c) => c.read(puzzleControllerProvider);

  void toPlaying(ProviderContainer c) {
    ctl(c).gameReady();
    clock.fireNext();
    ctl(c).previewShown();
    clock.fireNext();
  }

  test('same seed gives the same puzzle and the same scatter', () {
    final a = st(make(7)).session.pieces.map((p) => (p.id, p.position));
    final b = st(make(7)).session.pieces.map((p) => (p.id, p.position));
    expect(a.toList(), b.toList());
  });

  test('sequence: intro → preview (4 s after flip-up) → playing', () {
    final c = make(3);
    expect(st(c).phase, PuzzlePhase.intro);
    ctl(c).gameReady();
    ctl(c).gameReady(); // idempotent
    expect(clock.pending.map((p) => p.delay), [introDuration]);
    expect(clock.fireNext(), introDuration);
    expect(st(c).phase, PuzzlePhase.preview);
    expect(clock.pending, isEmpty);
    ctl(c).previewShown();
    expect(clock.pending.single.delay, const Duration(seconds: 4));
    expect(clock.fireNext(), const Duration(seconds: 4));
    expect(st(c).phase, PuzzlePhase.playing);
  });

  test('reveal shows one piece and raises it', () {
    final c = make(3);
    toPlaying(c);
    final id = st(c).session.stackOrder.first;
    expect(ctl(c).reveal(id), isA<PieceRevealed>());
    expect(st(c).session.isFaceUp(id), isTrue);
    expect(st(c).session.stackOrder.last, id);
    expect(
      st(c).session.pieces.where((p) => st(c).session.isFaceUp(p.id)).length,
      1,
    );
  });

  test(
    'wrong drop is kept; correct drop locks; completion after last lock',
    () {
      final c = make(3);
      toPlaying(c);
      final ids = [for (final p in st(c).session.pieces) p.id];
      for (final id in ids) {
        ctl(c).reveal(id);
      }
      final first = st(c).session.piece(ids.first)!;
      final wrong = st(c).session.bounds.clampOrigin(
        BoardPoint(first.target.x >= 2 ? 0 : 2.5, 6),
        first.piece.size,
      );
      final out = ctl(c).drop(first.id, wrong) as PieceMoved;
      expect(out.snapped, isFalse);
      expect(st(c).session.piece(first.id)!.position, wrong);
      for (final id in ids) {
        ctl(c).drop(id, st(c).session.piece(id)!.target);
        expect(st(c).showCompletion, isFalse);
      }
      expect(st(c).session.isComplete, isTrue);
      ctl(c).lockFinished(ids.last);
      expect(st(c).showCompletion, isTrue);
    },
  );

  test('new puzzle cancels pending timers and restarts at intro', () {
    final c = make(9);
    ctl(c).gameReady();
    expect(clock.pending, hasLength(1));
    ctl(c).newPuzzle();
    expect(clock.pending, isEmpty);
    expect(st(c).seed, 10);
    expect(st(c).phase, PuzzlePhase.intro);
    ctl(c).gameReady();
    expect(clock.pending.single.delay, introDuration);
  });

  test('preview cannot be skipped or re-entered out of order', () {
    final c = make(4);
    ctl(c).previewShown(); // ignored in intro
    expect(clock.pending, isEmpty);
    ctl(c).endPreview(); // ignored in intro
    expect(st(c).phase, PuzzlePhase.intro);
  });
}
