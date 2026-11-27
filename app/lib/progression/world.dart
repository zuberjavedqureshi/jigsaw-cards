/// The worlds (homes) of the World Journey, in play order. Each world has
/// [levelsPerWorld] levels. Adding a world is a data change: a new value
/// here plus its Hard levels in the level catalogue.
enum WorldId {
  sunnyMeadows('sunnyMeadows', 'Sunny Meadows', 1000),
  enchantedForest('enchantedForest', 'Enchanted Forest', 2000),
  fantasyKingdom('fantasyKingdom', 'Fantasy Kingdom', 3000),
  oceanKingdom('oceanKingdom', 'Ocean Kingdom', 4000),
  skyKingdom('skyKingdom', 'Sky Kingdom', 5000);

  const WorldId(this.key, this.title, this.firstPlaySeedBase);

  /// Stable identifier (used in level keys and future saved progress).
  /// Never derived from the enum's name or position, so it survives
  /// renames and reordering.
  final String key;

  /// Display name.
  final String title;

  /// Base of the deterministic first-play seeds of this world's levels
  /// (see `firstPlaySeed`). Explicit, so seeds never depend on ordering.
  final int firstPlaySeedBase;

  /// Play order, 0-based.
  int get order => index;
}

/// Levels in every world.
const levelsPerWorld = 10;
