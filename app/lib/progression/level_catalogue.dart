import '../state/puzzle_difficulty.dart';
import 'level.dart';
import 'world.dart';

/// Hard (5×5) level numbers per world; every other level is Normal (4×4).
/// Approved World Journey distribution; level 10 is always Hard.
const hardLevels = <WorldId, Set<int>>{
  WorldId.sunnyMeadows: {4, 7, 10},
  WorldId.enchantedForest: {3, 5, 8, 10},
  WorldId.fantasyKingdom: {2, 4, 6, 8, 10},
  WorldId.oceanKingdom: {2, 4, 5, 7, 9, 10},
  WorldId.skyKingdom: {2, 3, 5, 6, 8, 9, 10},
};

/// Every level, in play order (world order, then level number). Built from
/// [hardLevels]; each level's picture id is its level key.
final List<LevelConfig> levelCatalogue = List.unmodifiable([
  for (final world in WorldId.values)
    for (var n = 1; n <= levelsPerWorld; n++)
      LevelConfig(
        id: LevelId(world, n),
        difficulty: (hardLevels[world] ?? const {}).contains(n)
            ? PuzzleDifficulty.hard
            : PuzzleDifficulty.normal,
        artworkId: ArtworkId(LevelId(world, n).key),
      ),
]);

final Map<LevelId, LevelConfig> _byId = {
  for (final c in levelCatalogue) c.id: c,
};

/// The configuration of [level] (every valid [LevelId] has one).
LevelConfig levelConfigFor(LevelId level) =>
    _byId[level] ?? (throw ArgumentError.value(level, 'level', 'Unknown'));

/// The levels of [world], in order.
List<LevelConfig> levelsOf(WorldId world) => [
  for (final c in levelCatalogue)
    if (c.id.world == world) c,
];
