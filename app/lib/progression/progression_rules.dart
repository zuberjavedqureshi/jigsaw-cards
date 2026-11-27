import 'level.dart';
import 'world.dart';

/// Pure World Journey progression rules (no Flutter, no Riverpod, no
/// persistence). `completed` is the set of levels the player has finished.

/// The level before [level] in play order: the previous level of the same
/// world, or the previous world's last level. Null for the very first
/// level.
LevelId? previousLevel(LevelId level) {
  if (level.number > 1) return LevelId(level.world, level.number - 1);
  final w = level.world.order;
  if (w == 0) return null;
  return LevelId(WorldId.values[w - 1], levelsPerWorld);
}

/// The level after [level] in play order, or null after the final world's
/// last level.
LevelId? nextLevel(LevelId level) {
  if (level.number < levelsPerWorld) {
    return LevelId(level.world, level.number + 1);
  }
  final w = level.world.order;
  if (w == WorldId.values.length - 1) return null;
  return LevelId(WorldId.values[w + 1], 1);
}

/// Whether [level] can be played: the first level always; any other level
/// once its predecessor is completed (so a world's first level needs the
/// previous world's level 10). A completed level stays playable (replay).
bool isUnlocked(LevelId level, Set<LevelId> completed) {
  if (completed.contains(level)) return true;
  final before = previousLevel(level);
  return before == null || completed.contains(before);
}

/// A world is complete once its last level is completed.
bool worldComplete(WorldId world, Set<LevelId> completed) =>
    completed.contains(LevelId(world, levelsPerWorld));

/// Deterministic seed for the first play of [level]: the world's explicit
/// [WorldId.firstPlaySeedBase] plus the level's position. Stable across
/// runs and devices (never Dart's `hashCode`). Sunny Meadows level 1 is
/// 1000, the seed of the approved M3.3 fixture. Replays use a fresh random
/// seed instead. Not a save system: it only fixes the first layout.
int firstPlaySeed(LevelId level) =>
    level.world.firstPlaySeedBase + (level.number - 1);
