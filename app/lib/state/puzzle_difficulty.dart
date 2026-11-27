import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';

/// Puzzle difficulty (M3.4): a square board size and a display label.
/// Product configuration, not a puzzle rule — the domain supports any
/// [GridSize].
enum PuzzleDifficulty {
  easy(4, 'Easy'),
  medium(5, 'Medium'),
  hard(6, 'Hard');

  const PuzzleDifficulty(this.size, this.label);

  /// Tiles per side (square boards only).
  final int size;

  /// Name shown to the player.
  final String label;

  /// The board: [size] × [size].
  GridSize get grid => GridSize(size, size);
}

/// Difficulties that can be played. Medium and Hard are activated
/// deliberately in later M3.4 stages, once their artwork and multi-grid
/// tuning are in place; until then only Easy may start.
const playableDifficulties = {PuzzleDifficulty.easy};

/// The picture for [difficulty], or null if it does not exist yet.
/// Easy uses the approved Sunny Castle placeholder; Enchanted Forest
/// (Medium) and Fantasy Kingdom (Hard) are added in a later stage.
PuzzleArtwork? artworkFor(PuzzleDifficulty difficulty) => switch (difficulty) {
  PuzzleDifficulty.easy => const PlaceholderDaytimeArtwork(),
  PuzzleDifficulty.medium => null,
  PuzzleDifficulty.hard => null,
};

/// The picture for a playable [difficulty]. Throws [ArgumentError] if the
/// difficulty is not in [playableDifficulties] or has no artwork, so an
/// unsupported difficulty can never start a puzzle.
PuzzleArtwork playableArtworkFor(PuzzleDifficulty difficulty) {
  final artwork = artworkFor(difficulty);
  if (!playableDifficulties.contains(difficulty) || artwork == null) {
    throw ArgumentError.value(
      difficulty,
      'difficulty',
      '${difficulty.label} is not playable yet',
    );
  }
  return artwork;
}

/// Difficulty of the first puzzle. Easy until difficulty selection exists;
/// overridable in tests. It is validated before any puzzle is created.
final initialDifficultyProvider = Provider<PuzzleDifficulty>(
  (ref) => PuzzleDifficulty.easy,
);
