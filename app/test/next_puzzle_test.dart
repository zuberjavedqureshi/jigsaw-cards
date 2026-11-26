import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/intro/intro_timeline.dart';
import 'package:jigsaw_cards/game/transition/exit_sequence.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'puzzle_test_harness.dart';

class _ListSeedSource implements PuzzleSeedSource {
  _ListSeedSource(this.seeds);
  final List<int> seeds;
  int calls = 0;

  @override
  int nextSeed() => seeds[calls++ % seeds.length];
}

Future<Harness> solvedPuzzle(WidgetTester tester) async {
  final h = await pumpPuzzle(tester);
  await h.solve();
  await h.settle(frames: 40);
  expect(find.byKey(const Key('next_puzzle')), findsOneWidget);
  return h;
}

void main() {
  group('controller (uses the shuffle architecture, no seed arithmetic)', () {
    test('the next seed comes from the seed source; same picture', () {
      final source = _ListSeedSource([777]);
      final c = ProviderContainer(
        overrides: [
          initialSeedProvider.overrideWithValue(42),
          puzzleSeedSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(c.dispose);
      final before = c.read(puzzleControllerProvider).puzzle;
      c.read(puzzleControllerProvider.notifier).newPuzzle();
      final s = c.read(puzzleControllerProvider);
      expect(s.seed, 777);
      expect(s.round, 1);
      expect(source.calls, 1);
      expect(s.puzzle.source, before.source, reason: 'same picture');
      expect(s.puzzle.grid, before.grid);
      expect(s.puzzle.isComplete, isFalse);
    });

    test('a seed that would repeat the current arrangement is skipped', () {
      // The first seed equals the current one (identical arrangement).
      final source = _ListSeedSource([42, 4242]);
      final c = ProviderContainer(
        overrides: [
          initialSeedProvider.overrideWithValue(42),
          puzzleSeedSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(c.dispose);
      final before = [...c.read(puzzleControllerProvider).puzzle.arrangement];
      c.read(puzzleControllerProvider.notifier).newPuzzle();
      final s = c.read(puzzleControllerProvider);
      expect(s.seed, 4242);
      expect(s.puzzle.arrangement, isNot(before));
      expect(source.calls, 2);
    });

    test('the default source is random (not seed arithmetic)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(puzzleSeedSourceProvider), isA<RandomPuzzleSeedSource>());
    });
  });

  test('exit timeline is short and leaves bottom-right first', () {
    final tl = ExitTimeline(16);
    expect(tl.totalDuration, lessThanOrEqualTo(0.6));
    expect(tl.order.first, 15);
    expect(tl.order.last, 0);
    expect(tl.progress(15, 0.1), greaterThan(tl.progress(0, 0.1)));
  });

  testWidgets('Next puzzle: card hides, board clears, the same picture is '
      'reshuffled and the full introduction runs again', (tester) async {
    final h = await solvedPuzzle(tester);
    final oldGame = h.game;
    final title = h.container.read(artworkProvider).title;
    await tester.tap(find.byKey(const Key('next_puzzle')));
    await tester.pump(const Duration(milliseconds: 16));
    // Card gone at once; board clearing.
    expect(find.byKey(const Key('completion')), findsNothing);
    expect(oldGame.isExiting, isTrue);
    expect(h.state.round, 0);
    final startY = {
      for (final e in oldGame.tiles.entries) e.key: e.value.position.y,
    };
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      oldGame.tiles.entries.any((e) => e.value.position.y > startY[e.key]! + 1),
      isTrue,
      reason: 'tiles fall away',
    );
    var waited = 166;
    while (h.state.round == 0 && waited < 2000) {
      await tester.pump(const Duration(milliseconds: 20));
      waited += 20;
    }
    expect(h.state.round, 1);
    expect(waited, lessThanOrEqualTo(700), reason: 'exit took ${waited}ms');
    await tester.pump(const Duration(milliseconds: 16));
    // A new game, starting with card backs and the introduction.
    expect(h.game, isNot(same(oldGame)));
    expect(h.game.introPhase, isNot(IntroPhase.ready));
    expect(h.game.tiles.values.every((c) => c.face == 0), isTrue);
    expect(h.game.inputEnabled, isFalse);
    expect(h.state.seed, 1000, reason: 'seed from the seed source');
    expect(h.puzzle.isComplete, isFalse);
    expect(h.container.read(artworkProvider).title, title);
    await h.finishIntro();
    expect(h.game.inputEnabled, isTrue);
    expect(h.game.tiles.values.every((c) => c.face == 1), isTrue);
    // Still playable.
    final a = h.puzzle.tileAt(h.puzzle.grid.cellAt(0));
    await h.swap(h.puzzle.grid.cellAt(0), h.puzzle.grid.cellAt(5));
    expect(h.puzzle.tileAt(h.puzzle.grid.cellAt(5)), a);
  });

  testWidgets('rapid repeated taps start exactly one new puzzle', (
    tester,
  ) async {
    final h = await solvedPuzzle(tester);
    final button = find.byKey(const Key('next_puzzle'));
    // Three taps before any frame is rendered, then more while exiting.
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.game.playExit(() {}), isFalse, reason: 'already exiting');
    // The card (and its button) is gone while the board clears.
    expect(button, findsNothing);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await h.finishIntro();
    expect(h.state.round, 1);
    expect(h.seeds.calls, 1);
    // No exit can start on an unsolved puzzle, and no card is showing.
    expect(h.game.playExit(() {}), isFalse);
    expect(find.byKey(const Key('completion')), findsNothing);
  });

  testWidgets('pause, resume and resize during the transition still end '
      'in a playable new puzzle', (tester) async {
    final h = await solvedPuzzle(tester);
    await tester.tap(find.byKey(const Key('next_puzzle')));
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(360, 700);
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 60 && h.state.round == 0; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(h.state.round, 1);
    await tester.pump(const Duration(milliseconds: 16));
    await h.finishIntro();
    expect(h.game.inputEnabled, isTrue);
    for (final t in h.puzzle.tiles) {
      final r = h.game.area.cellRect(h.puzzle.cellOf(t)).center;
      expect(h.game.tiles[t.id]!.position.x, closeTo(r.dx, 0.01));
      expect(h.game.tiles[t.id]!.position.y, closeTo(r.dy, 0.01));
    }
  });
}
