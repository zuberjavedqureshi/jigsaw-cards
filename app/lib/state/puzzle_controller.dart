import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';

/// Board size for the prototype (GP-01): 4 × 4 equal tiles.
final prototypeGrid = GridSize(4, 4);

/// Seed for the first puzzle's shuffle. Seed source is an open technical
/// question (TD-02); provisionally a fixed `--dart-define=PUZZLE_SEED=<n>`
/// or, if unset, the launch time.
final initialSeedProvider = Provider<int>((ref) {
  const fromEnv = int.fromEnvironment('PUZZLE_SEED', defaultValue: -1);
  return fromEnv >= 0
      ? fromEnv
      : DateTime.now().millisecondsSinceEpoch % 1000000;
});

/// The illustration being played. Defaults to the code-drawn placeholder
/// (no final artwork exists). Its source size drives both the domain's tile
/// slicing and the board's aspect ratio, so they cannot disagree.
final artworkProvider = Provider<PuzzleArtwork>(
  (ref) => const PlaceholderStorybookArtwork(),
);

@immutable
class PuzzleState {
  const PuzzleState({
    required this.seed,
    required this.puzzle,
    this.swaps = 0,
    this.showCompletion = false,
  });

  final int seed;
  final PicturePuzzle puzzle;

  /// Swaps made in this puzzle (shown on completion only).
  final int swaps;

  /// True once the completion animation has finished.
  final bool showCompletion;

  int get correctCount => puzzle.correctCount;
  int get tileCount => puzzle.tileCount;
  bool get isComplete => puzzle.isComplete;

  PuzzleState copyWith({
    PicturePuzzle? puzzle,
    int? swaps,
    bool? showCompletion,
  }) => PuzzleState(
    seed: seed,
    puzzle: puzzle ?? this.puzzle,
    swaps: swaps ?? this.swaps,
    showCompletion: showCompletion ?? this.showCompletion,
  );
}

SourceSize _sourceSize(PuzzleArtwork a) =>
    SourceSize(a.sourceSize.width, a.sourceSize.height);

/// Application state for the current picture-swap puzzle (hand-written
/// Notifier, ADR-0003). Every rule decision is made by the domain.
class PuzzleController extends Notifier<PuzzleState> {
  @override
  PuzzleState build() => _newState(ref.read(initialSeedProvider));

  PuzzleState _newState(int seed) => PuzzleState(
    seed: seed,
    puzzle: PicturePuzzle.shuffled(
      prototypeGrid,
      _sourceSize(ref.read(artworkProvider)),
      seed: seed,
    ),
  );

  /// Exchange the tiles in [from] and [to]. Wrong swaps are accepted.
  SwapOutcome swap(GridCell from, GridCell to) {
    final outcome = state.puzzle.swap(from, to);
    if (outcome case TilesSwapped(:final puzzle)) {
      state = state.copyWith(puzzle: puzzle, swaps: state.swaps + 1);
    }
    return outcome;
  }

  /// The completion animation finished. Rewards and progression attach
  /// here later (not in this milestone).
  void completionShown() {
    if (state.isComplete && !state.showCompletion) {
      state = state.copyWith(showCompletion: true);
    }
  }

  /// Starts a new puzzle with the next seed.
  void newPuzzle() => state = _newState(state.seed + 1);
}

final puzzleControllerProvider =
    NotifierProvider<PuzzleController, PuzzleState>(PuzzleController.new);
