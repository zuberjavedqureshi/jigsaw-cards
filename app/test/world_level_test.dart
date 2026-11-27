import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/progression/level.dart';
import 'package:jigsaw_cards/progression/level_catalogue.dart';
import 'package:jigsaw_cards/progression/world.dart';
import 'package:jigsaw_cards/state/puzzle_difficulty.dart';

void main() {
  group('worlds', () {
    test('five worlds in journey order with stable keys and titles', () {
      expect(WorldId.values, [
        WorldId.sunnyMeadows,
        WorldId.enchantedForest,
        WorldId.fantasyKingdom,
        WorldId.oceanKingdom,
        WorldId.skyKingdom,
      ]);
      expect(
        [for (final w in WorldId.values) w.title],
        [
          'Sunny Meadows',
          'Enchanted Forest',
          'Fantasy Kingdom',
          'Ocean Kingdom',
          'Sky Kingdom',
        ],
      );
      expect(
        [for (final w in WorldId.values) w.key],
        [
          'sunnyMeadows',
          'enchantedForest',
          'fantasyKingdom',
          'oceanKingdom',
          'skyKingdom',
        ],
      );
      expect([for (final w in WorldId.values) w.order], [0, 1, 2, 3, 4]);
      expect(levelsPerWorld, 10);
    });

    test('first-play seed bases are explicit and distinct', () {
      final bases = {for (final w in WorldId.values) w.firstPlaySeedBase};
      expect(bases, hasLength(5));
      expect(WorldId.sunnyMeadows.firstPlaySeedBase, 1000);
    });
  });

  group('LevelId', () {
    test('valid numbers 1…10', () {
      for (var n = 1; n <= 10; n++) {
        final id = LevelId(WorldId.oceanKingdom, n);
        expect(id.world, WorldId.oceanKingdom);
        expect(id.number, n);
      }
    });

    test('invalid numbers are rejected', () {
      for (final n in [-1, 0, 11, 100]) {
        expect(
          () => LevelId(WorldId.sunnyMeadows, n),
          throwsArgumentError,
          reason: '$n',
        );
      }
    });

    test('value equality and hashing', () {
      final a = LevelId(WorldId.fantasyKingdom, 3);
      final b = LevelId(WorldId.fantasyKingdom, 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(LevelId(WorldId.fantasyKingdom, 4)));
      expect(a, isNot(LevelId(WorldId.oceanKingdom, 3)));
      expect({a, b}, hasLength(1));
      expect(LevelId.first, LevelId(WorldId.sunnyMeadows, 1));
    });

    test('stable keys', () {
      expect(LevelId.first.key, 'sunnyMeadows-01');
      expect(LevelId(WorldId.skyKingdom, 10).key, 'skyKingdom-10');
      expect(LevelId(WorldId.enchantedForest, 7).key, 'enchantedForest-07');
      final keys = {for (final c in levelCatalogue) c.id.key};
      expect(keys, hasLength(50));
    });
  });

  group('catalogue', () {
    test('50 unique levels, 10 per world, numbered 1…10 in order', () {
      expect(levelCatalogue, hasLength(50));
      expect({for (final c in levelCatalogue) c.id}, hasLength(50));
      var i = 0;
      for (final w in WorldId.values) {
        final levels = levelsOf(w);
        expect(levels, hasLength(10));
        expect(
          [for (final c in levels) c.id.number],
          [for (var n = 1; n <= 10; n++) n],
        );
        for (final c in levels) {
          expect(levelCatalogue[i++], same(c), reason: 'deterministic order');
        }
      }
    });

    test('exact approved Hard distribution', () {
      const expected = {
        WorldId.sunnyMeadows: (normal: 7, hard: [4, 7, 10]),
        WorldId.enchantedForest: (normal: 6, hard: [3, 5, 8, 10]),
        WorldId.fantasyKingdom: (normal: 5, hard: [2, 4, 6, 8, 10]),
        WorldId.oceanKingdom: (normal: 4, hard: [2, 4, 5, 7, 9, 10]),
        WorldId.skyKingdom: (normal: 3, hard: [2, 3, 5, 6, 8, 9, 10]),
      };
      expected.forEach((world, want) {
        final levels = levelsOf(world);
        final hard = [
          for (final c in levels)
            if (c.difficulty == PuzzleDifficulty.hard) c.id.number,
        ];
        final normal = levels
            .where((c) => c.difficulty == PuzzleDifficulty.normal)
            .length;
        expect(hard, want.hard, reason: world.title);
        expect(normal, want.normal, reason: world.title);
      });
      final totalHard = levelCatalogue
          .where((c) => c.difficulty == PuzzleDifficulty.hard)
          .length;
      expect(totalHard, 25);
    });

    test('every level 10 is Hard; only Normal and Hard exist', () {
      for (final w in WorldId.values) {
        expect(
          levelConfigFor(LevelId(w, 10)).difficulty,
          PuzzleDifficulty.hard,
        );
      }
      for (final c in levelCatalogue) {
        expect(c.difficulty.size, anyOf(4, 5));
      }
    });

    test('Sunny Meadows level 1 is Normal 4×4', () {
      final c = levelConfigFor(LevelId.first);
      expect(c.difficulty, PuzzleDifficulty.normal);
      expect(c.difficulty.grid.rows, 4);
    });

    test('each level refers to its own picture id', () {
      final ids = {for (final c in levelCatalogue) c.artworkId};
      expect(ids, hasLength(50));
      expect(
        levelConfigFor(LevelId.first).artworkId,
        const ArtworkId('sunnyMeadows-01'),
      );
    });
  });
}
