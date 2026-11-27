import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/progression/level.dart';
import 'package:jigsaw_cards/progression/level_catalogue.dart';
import 'package:jigsaw_cards/progression/progression_rules.dart';
import 'package:jigsaw_cards/progression/world.dart';

LevelId lv(WorldId w, int n) => LevelId(w, n);

/// Every level before [upTo] (exclusive), in play order.
Set<LevelId> completedBefore(LevelId upTo) => {
  for (final c in levelCatalogue.takeWhile((c) => c.id != upTo)) c.id,
};

void main() {
  const none = <LevelId>{};

  test('Sunny Meadows level 1 is always unlocked', () {
    expect(isUnlocked(LevelId.first, none), isTrue);
    expect(previousLevel(LevelId.first), isNull);
  });

  test('later levels are locked until their predecessor is completed', () {
    expect(isUnlocked(lv(WorldId.sunnyMeadows, 2), none), isFalse);
    expect(isUnlocked(lv(WorldId.sunnyMeadows, 5), none), isFalse);
    expect(isUnlocked(lv(WorldId.skyKingdom, 10), none), isFalse);
  });

  test('sequential unlocking within a world', () {
    final done = <LevelId>{};
    for (var n = 1; n < 10; n++) {
      expect(isUnlocked(lv(WorldId.sunnyMeadows, n + 1), done), isFalse);
      done.add(lv(WorldId.sunnyMeadows, n));
      expect(isUnlocked(lv(WorldId.sunnyMeadows, n + 1), done), isTrue);
      // Completing a level does not complete the next one.
      expect(done.contains(lv(WorldId.sunnyMeadows, n + 1)), isFalse);
    }
  });

  test('skipping is not possible: only the immediate predecessor counts', () {
    final done = {lv(WorldId.sunnyMeadows, 1), lv(WorldId.sunnyMeadows, 2)};
    expect(isUnlocked(lv(WorldId.sunnyMeadows, 3), done), isTrue);
    expect(isUnlocked(lv(WorldId.sunnyMeadows, 4), done), isFalse);
  });

  test('a world opens only after the previous world\'s level 10', () {
    final nine = completedBefore(lv(WorldId.sunnyMeadows, 10));
    expect(isUnlocked(lv(WorldId.enchantedForest, 1), nine), isFalse);
    final ten = {...nine, lv(WorldId.sunnyMeadows, 10)};
    expect(isUnlocked(lv(WorldId.enchantedForest, 1), ten), isTrue);
    expect(isUnlocked(lv(WorldId.enchantedForest, 2), ten), isFalse);
    expect(
      previousLevel(lv(WorldId.oceanKingdom, 1)),
      lv(WorldId.fantasyKingdom, 10),
    );
  });

  test('next level within and across worlds; none after the last', () {
    expect(nextLevel(LevelId.first), lv(WorldId.sunnyMeadows, 2));
    expect(
      nextLevel(lv(WorldId.sunnyMeadows, 10)),
      lv(WorldId.enchantedForest, 1),
    );
    expect(nextLevel(lv(WorldId.oceanKingdom, 10)), lv(WorldId.skyKingdom, 1));
    expect(nextLevel(lv(WorldId.skyKingdom, 10)), isNull);
    // Walking the whole journey visits the catalogue in order.
    final walk = <LevelId>[];
    for (LevelId? l = LevelId.first; l != null; l = nextLevel(l)) {
      walk.add(l);
    }
    expect(walk, [for (final c in levelCatalogue) c.id]);
  });

  test('world completion follows level 10', () {
    final nine = completedBefore(lv(WorldId.sunnyMeadows, 10));
    expect(worldComplete(WorldId.sunnyMeadows, nine), isFalse);
    expect(
      worldComplete(WorldId.sunnyMeadows, {
        ...nine,
        lv(WorldId.sunnyMeadows, 10),
      }),
      isTrue,
    );
    expect(worldComplete(WorldId.enchantedForest, none), isFalse);
  });

  test('the final level ends the journey', () {
    final all = {for (final c in levelCatalogue) c.id};
    expect(isUnlocked(lv(WorldId.skyKingdom, 10), all), isTrue);
    expect(nextLevel(lv(WorldId.skyKingdom, 10)), isNull);
    for (final w in WorldId.values) {
      expect(worldComplete(w, all), isTrue);
    }
  });

  test('completed levels stay replayable', () {
    final done = completedBefore(lv(WorldId.fantasyKingdom, 4));
    for (final l in done) {
      expect(isUnlocked(l, done), isTrue, reason: l.key);
    }
    expect(isUnlocked(lv(WorldId.fantasyKingdom, 4), done), isTrue);
    expect(isUnlocked(lv(WorldId.fantasyKingdom, 5), done), isFalse);
  });

  test('deterministic first-play seeds; Sunny Meadows 1 keeps seed 1000', () {
    expect(firstPlaySeed(LevelId.first), 1000);
    expect(firstPlaySeed(lv(WorldId.sunnyMeadows, 10)), 1009);
    expect(firstPlaySeed(lv(WorldId.skyKingdom, 1)), 5000);
    final seeds = {for (final c in levelCatalogue) firstPlaySeed(c.id)};
    expect(seeds, hasLength(50), reason: 'every level has its own layout');
    expect(
      firstPlaySeed(lv(WorldId.oceanKingdom, 3)),
      firstPlaySeed(LevelId(WorldId.oceanKingdom, 3)),
    );
  });
}
