import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';
import 'package:jigsaw_cards/game/praise/praise_rules.dart';
import 'package:jigsaw_cards/progression/level.dart';
import 'package:jigsaw_cards/progression/progression_rules.dart';
import 'package:jigsaw_cards/progression/world.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/state/puzzle_difficulty.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// The M3.3 seed-1000 arrangement (verified against the domain shuffle).
/// Seed 1000 is also Sunny Meadows level 1's first-play seed.
const seed1000 = [11, 8, 7, 2, 0, 5, 3, 15, 12, 9, 10, 4, 13, 1, 6, 14];

void main() {
  final normalGrid = GridSize(4, 4);
  final sunnySource = SourceSize(1024, 1024);
  final unavailable = [
    LevelId(WorldId.sunnyMeadows, 2),
    LevelId(WorldId.sunnyMeadows, 4), // Hard
    LevelId(WorldId.skyKingdom, 10),
  ];

  /// A container; [seed] overrides the initial seed (as the existing tests
  /// do) unless null, in which case the real first-play seed is used.
  ({ProviderContainer c, SequenceSeedSource seeds}) make({
    int? seed = 7,
    LevelId? initial,
  }) {
    final seeds = SequenceSeedSource();
    final c = ProviderContainer(
      overrides: [
        if (seed != null) initialSeedProvider.overrideWithValue(seed),
        puzzleSeedSourceProvider.overrideWithValue(seeds),
        if (initial != null) initialLevelProvider.overrideWithValue(initial),
      ],
    );
    addTearDown(c.dispose);
    return (c: c, seeds: seeds);
  }

  PuzzleController ctl(ProviderContainer c) =>
      c.read(puzzleControllerProvider.notifier);
  PuzzleState st(ProviderContainer c) => c.read(puzzleControllerProvider);

  group('initial state', () {
    test('starts at Sunny Meadows level 1, Normal 4×4', () {
      final s = st(make().c);
      expect(s.level, LevelId.first);
      expect(s.difficulty, PuzzleDifficulty.normal);
      expect(s.puzzle.grid, normalGrid);
      expect(s.round, 0);
    });

    test('first launch uses the deterministic first-play seed (1000): the '
        'M3.3 seed-1000 layout', () {
      final s = st(make(seed: null).c);
      expect(s.seed, 1000);
      expect(s.seed, firstPlaySeed(LevelId.first));
      expect(s.puzzle.arrangement, seed1000);
    });

    for (final l in unavailable) {
      test('an initial ${l.key} override fails before any puzzle exists', () {
        final m = make(initial: l);
        final clear = throwsA(
          predicate(
            (e) =>
                e.toString().contains('level ${l.number} is not playable yet'),
          ),
        );
        expect(() => st(m.c), clear);
        expect(m.seeds.calls, 0);
        expect(() => st(m.c), clear, reason: 'no invalid state exposed');
      });
    }
  });

  group('Sunny Meadows level 1 is identical to M3.3', () {
    for (final seed in [7, 42, 1000]) {
      test('seed $seed: same 4×4 shuffle from a 1024×1024 source', () {
        final s = st(make(seed: seed).c);
        expect(
          s.puzzle.arrangement,
          PicturePuzzle.shuffled(
            normalGrid,
            sunnySource,
            seed: seed,
          ).arrangement,
        );
        expect(s.puzzle.source, sunnySource);
        expect(s.puzzle.grid, normalGrid);
        expect(s.seed, seed);
      });
    }

    test('seed 1000 matches the M3.3 fixture', () {
      expect(
        PicturePuzzle.shuffled(normalGrid, sunnySource, seed: 1000).arrangement,
        seed1000,
      );
      expect(st(make(seed: 1000).c).puzzle.arrangement, seed1000);
    });

    test('the Fantastic! threshold is still 10', () {
      expect(const PraiseRules().largeGroupSize, 10);
    });
  });

  group('start()', () {
    test('first play: deterministic seed, no random seed consumed', () {
      final m = make();
      ctl(m.c).start(LevelId.first);
      final s = st(m.c);
      expect(s.round, 1);
      expect(s.level, LevelId.first);
      expect(s.seed, 1000);
      expect(s.puzzle.arrangement, seed1000);
      expect(m.seeds.calls, 0);
      // The same level always starts with the same layout.
      ctl(m.c).start(LevelId.first);
      expect(st(m.c).puzzle.arrangement, seed1000);
      expect(st(m.c).round, 2);
    });

    test('replay: fresh random seed', () {
      final m = make();
      ctl(m.c).start(LevelId.first, replay: true);
      final s = st(m.c);
      expect(s.round, 1);
      expect(m.seeds.calls, 1);
      expect(s.seed, 1000, reason: 'first value of the test seed sequence');
      ctl(m.c).start(LevelId.first, replay: true);
      expect(st(m.c).seed, 1001);
      expect(
        st(m.c).puzzle.arrangement,
        PicturePuzzle.shuffled(normalGrid, sunnySource, seed: 1001).arrangement,
      );
    });

    for (final l in unavailable) {
      for (final replay in [false, true]) {
        test('start(${l.key}, replay: $replay) is rejected atomically', () {
          final m = make();
          ctl(m.c).moveTile(GridCell(0, 0), GridCell(1, 1));
          final before = st(m.c);
          final arrangement = [...before.puzzle.arrangement];
          expect(() => ctl(m.c).start(l, replay: replay), throwsArgumentError);
          final after = st(m.c);
          expect(after, same(before));
          expect(after.round, before.round);
          expect(after.seed, before.seed);
          expect(after.swaps, before.swaps);
          expect(after.level, LevelId.first);
          expect(after.puzzle.arrangement, arrangement);
          expect(m.seeds.calls, 0, reason: 'no seed consumed');
        });
      }
    }
  });

  group('the level is kept', () {
    test('newPuzzle replays the level with fresh random seeds', () {
      final m = make();
      for (var i = 1; i <= 3; i++) {
        ctl(m.c).newPuzzle();
        final s = st(m.c);
        expect(s.round, i);
        expect(s.level, LevelId.first);
        expect(s.puzzle.grid, normalGrid);
        expect(
          s.puzzle.arrangement,
          PicturePuzzle.shuffled(
            normalGrid,
            sunnySource,
            seed: s.seed,
          ).arrangement,
        );
      }
      expect(m.seeds.calls, greaterThanOrEqualTo(3));
    });

    test('through moves, a full solve and completion', () {
      final m = make();
      ctl(m.c).moveTile(GridCell(0, 0), GridCell(3, 3));
      expect(st(m.c).level, LevelId.first);
      var guard = 0;
      while (!st(m.c).isComplete && guard++ < 32) {
        final p = st(m.c).puzzle;
        final t = p.tiles.firstWhere((t) => !p.isTileCorrect(t));
        ctl(m.c).moveTile(p.cellOf(t), t.target);
        expect(st(m.c).level, LevelId.first);
      }
      expect(st(m.c).isComplete, isTrue);
      ctl(m.c).completionShown();
      expect(st(m.c).showCompletion, isTrue);
      expect(st(m.c).level, LevelId.first);
    });
  });

  group('artworkProvider', () {
    test('is the current level\'s picture: Sunny Castle', () {
      final m = make();
      expect(m.c.read(artworkProvider), isA<PlaceholderDaytimeArtwork>());
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
      ctl(m.c).newPuzzle();
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
      ctl(m.c).start(LevelId.first);
      expect(m.c.read(artworkProvider).title, 'Sunny Castle');
    });

    test('artwork first, then controller: no circular dependency', () {
      final c = make().c;
      expect(c.read(artworkProvider).title, 'Sunny Castle');
      expect(st(c).level, LevelId.first);
    });

    test('controller first, then artwork: no circular dependency', () {
      final c = make().c;
      expect(st(c).level, LevelId.first);
      expect(c.read(artworkProvider).title, 'Sunny Castle');
    });
  });

  group('screen (unchanged gameplay)', () {
    testWidgets('header names the world; 16 tiles; M3.3 starting group and '
        'Nice! praise', (tester) async {
      final h = await pumpPuzzle(tester, seed: 1000);
      expect(find.text('Sunny Meadows'), findsOneWidget);
      expect(h.state.level, LevelId.first);
      expect(h.game.tiles, hasLength(16));
      expect(h.game.artwork.title, 'Sunny Castle');
      expect(h.puzzle.arrangement, seed1000);
      expect(h.puzzle.connectedGroups, [
        {GridCell(1, 1), GridCell(2, 1), GridCell(2, 2)},
      ]);
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

    testWidgets('after solving and Next puzzle: same level, Sunny Castle, '
        '4×4', (tester) async {
      final h = await pumpPuzzle(tester, seed: 1000);
      await h.solve();
      await h.settle(frames: 40);
      expect(find.byKey(const Key('completion')), findsOneWidget);
      await h.tapNextPuzzle();
      expect(h.state.round, 1);
      expect(h.state.level, LevelId.first);
      expect(h.puzzle.grid, normalGrid);
      expect(h.game.tiles, hasLength(16));
      expect(h.game.artwork.title, 'Sunny Castle');
      expect(find.text('Sunny Meadows'), findsOneWidget);
    });
  });
}
