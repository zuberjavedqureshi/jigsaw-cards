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
    this.onIntroFinished,
  });

  /// A tile dragged from [from] (with its connected group, if any) was
  /// released over the tile in [to].
  final void Function(GridCell from, GridCell to) onSwapRequested;

  /// The exchange animation of the last swap finished.
  final void Function() onSwapSettled;

  /// The completion animation finished (show the completion state).
  final void Function() onCompletionShown;

  /// The introduction (entrance and reveal) finished; input is enabled.
  final void Function()? onIntroFinished;
}

/// Application → Flame. [syncPuzzle] is the only state input: the game
/// animates tiles to the cells of the puzzle it is given.
abstract interface class PuzzleGameView {
  void syncPuzzle(PicturePuzzle puzzle);

  /// Clears the board with the exit animation, then calls [onDone] once.
  /// Returns false (and does nothing) if an exit is already running or the
  /// puzzle is not complete, so a transition can never start twice.
  bool playExit(void Function() onDone);
}
