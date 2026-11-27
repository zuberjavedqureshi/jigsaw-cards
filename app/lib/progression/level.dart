import '../state/puzzle_difficulty.dart';
import 'world.dart';

/// Identity of one level: a world and a level number 1…[levelsPerWorld].
/// Immutable, with value equality and a stable [key] for future local
/// persistence.
final class LevelId {
  /// Validated constructor: throws [ArgumentError] for a number outside
  /// 1…[levelsPerWorld].
  factory LevelId(WorldId world, int number) {
    if (number < 1 || number > levelsPerWorld) {
      throw ArgumentError.value(
        number,
        'number',
        'A level number must be between 1 and $levelsPerWorld',
      );
    }
    return LevelId._(world, number);
  }

  const LevelId._(this.world, this.number);

  /// Sunny Meadows, Level 1: where the journey starts.
  static const first = LevelId._(WorldId.sunnyMeadows, 1);

  final WorldId world;
  final int number;

  /// Stable key, e.g. `sunnyMeadows-01`.
  String get key => '${world.key}-${number.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is LevelId && other.world == world && other.number == number;

  @override
  int get hashCode => Object.hash(world, number);

  @override
  String toString() => 'LevelId($key)';
}

/// Identity of a puzzle picture. Levels refer to pictures by id; the
/// artwork registry decides which pictures actually exist.
final class ArtworkId {
  const ArtworkId(this.key);

  final String key;

  @override
  bool operator ==(Object other) => other is ArtworkId && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ArtworkId($key)';
}

/// Configuration of one level: its identity, board difficulty and picture.
final class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.difficulty,
    required this.artworkId,
  });

  final LevelId id;
  final PuzzleDifficulty difficulty;
  final ArtworkId artworkId;

  @override
  String toString() => 'LevelConfig(${id.key}, ${difficulty.label})';
}
