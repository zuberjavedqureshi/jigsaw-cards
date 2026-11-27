import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';
import 'package:jigsaw_cards/game/praise/praise_rules.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/state/puzzle_difficulty.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// The M3.3 seed-1000 arrangement (verified against the domain shuffle).
const seed1000 = [11, 8, 7, 2, 0, 5, 3, 15, 12, 9, 10, 4, 13, 1, 6, 14];

void main() {
  final easyGrid = GridSize(4, 4);
  final easySource = SourceSize(1024, 1024);

  ({ProviderContainer c, SequenceSeedSource seeds}) make(
    int seed, {
    PuzzleDifficulty? initial,
  }) {
    final seeds = SequenceSeedSource();
    final c = ProviderContainer(
      overrides: [
        initialSeedProvider.overrideWithValue(seed),
        puzzleSeedSourceProvider.overrideWithValue(seeds),
        if (initial != null)
          initialDifficultyProvider.overrideWithValue(initial),
      ],
    );
    addTearDown(c.dispose);
    return (c: c, seeds: seeds);
  }

  PuzzleController ctl(ProviderContainer c) =>
      c.read(puzzleControllerProvider.notifier);
  PuzzleState st(ProviderContainer c) => c.read(puzzleControllerProvider);

  group('initial state', () {
    test('defaults to Easy on a 4×4 board', () {
      final s = st(make(7).c);
      expect(s.difficulty, PuzzleDifficulty.easy);
      expect(s.puzzle.grid, easyGrid);
      expect(s.round, 0);
    });

    for (final d in [PuzzleDifficulty.medium, PuzzleDifficulty.hard]) {
      test('an initial ${d.label} override fails before any puzzle exists', () {
        final m = make(7, initial: d);
        // Riverpod may wrap the error; either way it names the difficulty.
        final clear = throwsA(
          predicate(
            (e) => e.toString().contains('${d.label} is not playable yet'),
          ),
        );
        expect(() => st(m.c), clear);
        expect(m.seeds.calls, 0);
        // Still failing on a second read: no invalid state was exposed.
        expect(() => st(m.c), clear);
      });
    }
  });

  group('Easy is identical to M3.3', () {
    for (final seed in [7, 42, 1000]) {
      test('seed $seed: same 4×4 shuffle from a 1024×1024 source', () {
        final s = st(make(seed).c);
        final expected = PicturePuzzle.shuffled(
          easyGrid,
          easySource,
          seed: seed,
        );
        expect(s.puzzle.arrangement, expected.arrangement);
        expect(s.puzzle.source, easySource);
        expect(s.puzzle.grid, easyGrid);
        expect(s.seed, seed);
      });
    }

    test('seed 1000 matches the M3.3 fixture', () {
      expect(
        PicturePuzzle.shuffled(easyGrid, easySource, seed: 1000).arrangement,
        seed1000,
      );
      expect(st(make(1000).c).puzzle.arrangement, seed1000);
    });

    test('newPuzzle uses the same domain shuffle for the next seed', () {
      final m = make(42);
      ctl(m.c).newPuzzle();
      final s = st(m.c);
      expect(
        s.puzzle.arrangement,
        PicturePuzzle.shuffled(easyGrid, easySource, seed: s.seed).arrangement,
      );
      expect(s.seed, 1000, reason: 'first seed from the sequence source');
    });

    test('the Fantastic! threshold is still 10', () {
      expect(const PraiseRules().largeGroupSize, 10);
    });
  });

  group('start()', () {
    test('start(Easy) begins a new round with the next seed', () {
      final m = make(7);
      final before = st(m.c);
      ctl(m.c).start(PuzzleDifficulty.easy);
      final s = st(m.c);
      expect(s.round, before.round + 1);
      expect(m.seeds.calls, 1);
      expect(s.seed, 1000);
      expect(s.difficulty, PuzzleDifficulty.easy);
      expect(
        s.puzzle.arrangement,
        PicturePuzzle.shuffled(easyGrid, easySource, seed: 1000).arrangement,
      );
    });

    for (final d in [PuzzleDifficulty.medium, PuzzleDifficulty.hard]) {
      test('start(${d.label}) is rejected and changes nothing', () {
        final m = make(7);
        ctl(m.c).moveTile(GridCell(0, 0), GridCell(1, 1));
        final before = st(m.c);
        final arrangement = [...before.puzzle.arrangement];
        expect(() => ctl(m.c).start(d), throwsArgumentError);
        final after = st(m.c);
        expect(after, same(before));
        expect(after.round, before.round);
        expect(after.seed, before.seed);
        expect(after.swaps, before.swaps);
        expect(after.difficulty, PuzzleDifficulty.easy);
        expect(after.puzzle.arrangement, arrangement);
        expect(m.seeds.calls, 0, reason: 'no seed consumed');
      });
    }
  });

  group('difficulty is kept', () {
    test('newPuzzle keeps Easy and 4×4 over three rounds', () {
      final m = make(7);
      for (var i = 1; i <= 3; i++) {
        ctl(m.c).newPuzzle();
        final s = st(m.c);
        expect(s.round, i);
        expect(s.difficulty, PuzzleDifficulty.easy);
        expect(s.puzzle.grid, easyGrid);
      }
    });

    test('through moves, a full solve and completion', () {
      final m = make(7);
      ctl(m.c).moveTile(GridCell(0, 0), GridCell(3, 3));
      expect(st(m.c).difficulty, PuzzleDifficulty.easy);
      var guard = 0;
      while (!st(m.c).isComplete && guard++ < 32) {
        final p = st(m.c).puzzle;
        final t = p.tiles.firstWhere((t) => !p.isTileCorrect(t));
        ctl(m.c).moveTile(p.cellOf(t), t.target);
        expect(st(m.c).difficulty, PuzzleDifficulty.easy);
      }
      expect(st(m.c).isComplete, isTrue);
      ctl(m.c).completionShown();
      expect(st(m.c).showCompletion, isTrue);
      expect(st(m.c).difficulty, PuzzleDifficulty.easy);
    });
  });

  group('artworkProvider', () {
    test('is the current puzzle\'s picture: Sunny Castle', () {
      final m = make(7);
      expect(m.c.read(artworkProvider), isA<PlaceholderDaytimeArtwork>());
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
      ctl(m.c).newPuzzle();
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
      ctl(m.c).start(PuzzleDifficulty.easy);
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
    });

    test('artwork first, then controller: no circular dependency', () {
      final c = make(7).c;
      expect(c.read(artworkProvider).title, 'Sunny Castle');
      expect(st(c).difficulty, PuzzleDifficulty.easy);
    });

    test('controller first, then artwork: no circular dependency', () {
      final c = make(7).c;
      expect(st(c).difficulty, PuzzleDifficulty.easy);
      expect(c.read(artworkProvider).title, 'Sunny Castle');
    });
  });

  group('screen (Easy unchanged)', () {
    testWidgets('header, 16 tiles, M3.3 starting group and Nice! praise', (
      tester,
    ) async {
      final h = await pumpPuzzle(tester, seed: 1000);
      expect(find.text('Sunny Castle'), findsOneWidget);
      expect(h.state.difficulty, PuzzleDifficulty.easy);
      expect(h.game.tiles, hasLength(16));
      expect(h.puzzle.arrangement, seed1000);
      expect(h.puzzle.connectedGroups, [
        {GridCell(1, 1), GridCell(2, 1), GridCell(2, 2)},
      ]);
      // The M3.3 pair move still earns Nice!.
      final g = await h.dragTo(
        GridCell(3, 3),
        h.globalOf(GridCell(1, 2)),
        release: false,
      );
      await g.up();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(h.game.praise.current?.praise.text, 'Nice!');
    });

    testWidgets('after solving and Next puzzle: still Easy, Sunny Castle, '
        '4×4', (tester) async {
      final h = await pumpPuzzle(tester, seed: 1000);
      await h.solve();
      await h.settle(frames: 40);
      expect(find.byKey(const Key('completion')), findsOneWidget);
      await h.tapNextPuzzle();
      expect(h.state.round, 1);
      expect(h.state.difficulty, PuzzleDifficulty.easy);
      expect(h.puzzle.grid, easyGrid);
      expect(h.game.tiles, hasLength(16));
      expect(find.text('Sunny Castle'), findsOneWidget);
    });
  });
}
