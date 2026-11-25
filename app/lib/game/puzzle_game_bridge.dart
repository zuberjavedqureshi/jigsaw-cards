import 'package:puzzle_domain/puzzle_domain.dart';

/// Manual Flame ↔ application bridge (ADR-0001). The game depends only on
/// this contract and the pure-Dart domain, never on Riverpod.

/// Flame → application intents. The game never changes puzzle state
/// itself; it asks, then renders the puzzle it is given.
class PuzzleGameIntents {
  const PuzzleGameIntents({
    required this.onSwapRequested,
    required this.onSwapSettled,
    required this.onCompletionShown,
  });

  /// A tile dragged from [from] was released over the tile in [to].
  final void Function(GridCell from, GridCell to) onSwapRequested;

  /// The exchange animation of the last swap finished.
  final void Function() onSwapSettled;

  /// The completion animation finished (show the completion state).
  final void Function() onCompletionShown;
}

/// Application → Flame. [syncPuzzle] is the only state input: the game
/// animates tiles to the cells of the puzzle it is given.
abstract interface class PuzzleGameView {
  void syncPuzzle(PicturePuzzle puzzle);
}
