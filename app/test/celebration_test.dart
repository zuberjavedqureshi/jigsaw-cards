import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/celebration/celebration_timeline.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// Solves all but the last swap, then performs the final swap and releases.
Future<void> solveUntilLastSwap(Harness h) async {
  final g = h.puzzle.grid;
  for (final cell in g.cells) {
    final p = h.puzzle;
    final want = p.tiles[cell.row * g.columns + cell.column];
    final at = p.cellOf(want);
    if (at == cell) continue;
    if (p.correctCount == p.tileCount - 2) return; // one swap left
    await h.swap(at, cell);
  }
}

(GridCell, GridCell) lastSwap(PicturePuzzle p) {
  final wrong = p.grid.cells.where((c) => !p.isTileCorrect(p.tileAt(c)));
  final a = wrong.first;
  return (a, p.tileAt(a).target);
}

void main() {
  group('CelebrationTimeline (pure)', () {
    final tl = CelebrationTimeline.standard();

    test('short: about a second, and under 1.5 s', () {
      expect(tl.totalDuration, closeTo(1.1, 1e-9));
      expect(tl.totalDuration, lessThan(1.5));
    });

    test('shine first, sparkle overlapping it', () {
      final shine = tl.step(CelebrationTimeline.shine)!;
      final sparkle = tl.step(CelebrationTimeline.sparkle)!;
      expect(shine.start, 0);
      expect(sparkle.start, greaterThan(shine.start));
      expect(sparkle.start, lessThan(shine.end));
      expect(tl.progress(CelebrationTimeline.sparkle, 0.1), 0);
      expect(tl.progress(CelebrationTimeline.shine, tl.totalDuration), 1);
      expect(tl.isFinishedAt(tl.totalDuration), isTrue);
      expect(tl.isFinishedAt(tl.totalDuration - 0.01), isFalse);
    });

    test('extensible: more steps can be appended later', () {
      final extended = CelebrationTimeline([
        ...tl.steps,
        const CelebrationStep('future-step', start: 1.1, duration: 0.5),
      ]);
      expect(extended.totalDuration, closeTo(1.6, 1e-9));
      expect(extended.progress('future-step', 1.35), closeTo(0.5, 1e-9));
    });

    test('rejects empty or duplicate steps', () {
      expect(() => CelebrationTimeline(const []), throwsArgumentError);
      expect(
        () => CelebrationTimeline(const [
          CelebrationStep('a', start: 0, duration: 1),
          CelebrationStep('a', start: 1, duration: 1),
        ]),
        throwsArgumentError,
      );
    });

    test('no reward steps in this milestone', () {
      for (final s in tl.steps) {
        expect(s.id, isNot(contains('coin')));
        expect(s.id, isNot(contains('reward')));
        expect(s.id, isNot(contains('card')));
      }
    });
  });

  group('celebration on the board', () {
    testWidgets('plays once after the last swap; input stays disabled; the '
        'card follows within 1.5 s', (tester) async {
      final h = await pumpPuzzle(tester);
      await solveUntilLastSwap(h);
      expect(h.game.celebration, isNull);
      final (a, b) = lastSwap(h.puzzle);
      final g = await h.dragTo(a, h.globalOf(b), release: false);
      await g.up();
      // Let the exchange animation settle (0.22 s).
      var t = 0;
      while (h.game.celebration == null && t < 1000) {
        await tester.pump(const Duration(milliseconds: 20));
        t += 20;
      }
      expect(h.puzzle.isComplete, isTrue);
      final first = h.game.celebration;
      expect(first, isNotNull);
      expect(h.game.inputEnabled, isFalse);
      expect(find.byKey(const Key('completion')), findsNothing);

      // A stray drag during the celebration does nothing.
      final before = [...h.puzzle.arrangement];
      await h.dragTo(GridCell(0, 0), h.globalOf(GridCell(1, 1)));
      expect(h.puzzle.arrangement, before);

      var waited = 0;
      while (find.byKey(const Key('completion')).evaluate().isEmpty &&
          waited < 3000) {
        await tester.pump(const Duration(milliseconds: 20));
        waited += 20;
      }
      expect(find.byKey(const Key('completion')), findsOneWidget);
      expect(waited, lessThanOrEqualTo(1500), reason: 'card after ${waited}ms');
      expect(h.game.celebration, same(first), reason: 'exactly once');
      expect(h.game.celebration!.isFinished, isTrue);
      expect(h.state.showCompletion, isTrue);
    });

    testWidgets('no coins, rewards or placeholder rewards are shown', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await h.solve();
      await h.settle(frames: 40);
      expect(find.byKey(const Key('completion')), findsOneWidget);
      for (final word in ['coin', 'Coin', 'reward', 'Reward', '+']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
      expect(find.byKey(const Key('completed_picture')), findsOneWidget);
    });

    testWidgets('pause and resume during the celebration finish cleanly', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester);
      await solveUntilLastSwap(h);
      final (a, b) = lastSwap(h.puzzle);
      final g = await h.dragTo(a, h.globalOf(b), release: false);
      await g.up();
      while (h.game.celebration == null) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pump(const Duration(milliseconds: 200));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 3));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await h.settle(frames: 40);
      expect(h.game.celebration!.isFinished, isTrue);
      expect(find.byKey(const Key('completion')), findsOneWidget);
      expect(find.byKey(const Key('next_puzzle')), findsOneWidget);
    });
  });
}
