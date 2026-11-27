import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import 'puzzle_difficulty.dart';

/// Seed for the first puzzle's shuffle. Seed source is an open technical
/// question (TD-02); provisionally a fixed `--dart-define=PUZZLE_SEED=<n>`
/// or, if unset, the launch time.
final initialSeedProvider = Provider<int>((ref) {
  const fromEnv = int.fromEnvironment('PUZZLE_SEED', defaultValue: -1);
  return fromEnv >= 0
      ? fromEnv
      : DateTime.now().millisecondsSinceEpoch % 1000000;
});

/// The illustration of the **current puzzle**, derived from its difficulty
/// (M3.4). Its source size drives both the domain's tile slicing and the
/// board's aspect ratio, so they cannot disagree. The controller never
/// reads this provider (it would be a circular dependency); it uses
/// [playableArtworkFor] directly.
final artworkProvider = Provider<PuzzleArtwork>(
  (ref) => playableArtworkFor(
    ref.watch(puzzleControllerProvider.select((s) => s.difficulty)),
  ),
);

/// Supplies shuffle seeds for new puzzles. The shuffle itself is the
/// domain's seeded `PicturePuzzle.shuffled`; this only decides which seed
/// to use next, so tests can inject a deterministic sequence. Seed policy
/// remains a technical choice (TD-02).
abstract interface class PuzzleSeedSource {
  int nextSeed();
}

/// Default: random seeds.
class RandomPuzzleSeedSource implements PuzzleSeedSource {
  RandomPuzzleSeedSource([math.Random? random])
    : _random = random ?? math.Random();

  final math.Random _random;

  @override
  int nextSeed() => _random.nextInt(1 << 31);
}

final puzzleSeedSourceProvider = Provider<PuzzleSeedSource>(
  (ref) => RandomPuzzleSeedSource(),
);

@immutable
class PuzzleState {
  const PuzzleState({
    required this.seed,
    required this.puzzle,
    this.round = 0,
    this.swaps = 0,
    this.showCompletion = false,
    this.difficulty = PuzzleDifficulty.easy,
  });

  final int seed;

  /// Increments for every new puzzle; identifies the puzzle instance (the
  /// game is rebuilt when it changes), independently of the seed value.
  final int round;
  final PicturePuzzle puzzle;

  /// Swaps made in this puzzle (shown on completion only).
  final int swaps;

  /// True once the completion animation has finished.
  final bool showCompletion;

  /// Difficulty of this puzzle (board size and picture); kept by
  /// [PuzzleController.newPuzzle].
  final PuzzleDifficulty difficulty;

  int get correctCount => puzzle.correctCount;
  int get tileCount => puzzle.tileCount;
  bool get isComplete => puzzle.isComplete;

  PuzzleState copyWith({
    PicturePuzzle? puzzle,
    int? swaps,
    bool? showCompletion,
  }) => PuzzleState(
    seed: seed,
    round: round,
    puzzle: puzzle ?? this.puzzle,
    swaps: swaps ?? this.swaps,
    showCompletion: showCompletion ?? this.showCompletion,
    difficulty: difficulty,
  );
}

SourceSize _sourceSize(PuzzleArtwork a) =>
    SourceSize(a.sourceSize.width, a.sourceSize.height);

/// Application state for the current picture-swap puzzle (hand-written
/// Notifier, ADR-0003). Every rule decision is made by the domain.
class PuzzleController extends Notifier<PuzzleState> {
  @override
  PuzzleState build() {
    final difficulty = ref.read(initialDifficultyProvider);
    // Validate before anything else: an unplayable override fails here,
    // before a seed is read or a puzzle is created.
    playableArtworkFor(difficulty);
    final seed = ref.read(initialSeedProvider);
    return PuzzleState(
      seed: seed,
      puzzle: _shuffle(seed, difficulty),
      difficulty: difficulty,
    );
  }

  /// The domain's seeded shuffle for [difficulty]'s board and picture.
  /// Uses [playableArtworkFor], never [artworkProvider] (which depends on
  /// this controller).
  PicturePuzzle _shuffle(int seed, PuzzleDifficulty difficulty) =>
      PicturePuzzle.shuffled(
        difficulty.grid,
        _sourceSize(playableArtworkFor(difficulty)),
        seed: seed,
      );

  /// Exchange the tiles in [from] and [to]. Wrong swaps are accepted.
  SwapOutcome swap(GridCell from, GridCell to) {
    final outcome = state.puzzle.swap(from, to);
    if (outcome case TilesSwapped(:final puzzle)) {
      state = state.copyWith(puzzle: puzzle, swaps: state.swaps + 1);
    }
    return outcome;
  }

  /// Drags the tile in [from] onto [to]. Correct, adjacent tiles form a
  /// connected group and move together; a loose tile moves alone, exactly
  /// like [swap] (M3.2). The domain decides what moves.
  GroupMoveOutcome moveTile(GridCell from, GridCell to) {
    final outcome = state.puzzle.moveGroup(from, to);
    if (outcome case GroupMoved(:final puzzle)) {
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

  /// Starts a new puzzle (PRD GP-40): the same difficulty and picture,
  /// freshly shuffled with a seed from [puzzleSeedSourceProvider]. A seed
  /// that would repeat the current arrangement is skipped, so the new board
  /// always differs.
  void newPuzzle() {
    final difficulty = state.difficulty;
    final source = ref.read(puzzleSeedSourceProvider);
    final current = state.puzzle.arrangement;
    var seed = source.nextSeed();
    var puzzle = _shuffle(seed, difficulty);
    for (var i = 0; i < 16 && listEquals(puzzle.arrangement, current); i++) {
      seed = source.nextSeed();
      puzzle = _shuffle(seed, difficulty);
    }
    state = PuzzleState(
      seed: seed,
      round: state.round + 1,
      puzzle: puzzle,
      difficulty: difficulty,
    );
  }

  /// Starts a puzzle at [difficulty] (entry point for the future difficulty
  /// selection; not called by the UI yet). An unplayable difficulty throws
  /// [ArgumentError] before any seed is taken or any state changes.
  void start(PuzzleDifficulty difficulty) {
    playableArtworkFor(difficulty);
    final seed = ref.read(puzzleSeedSourceProvider).nextSeed();
    state = PuzzleState(
      seed: seed,
      round: state.round + 1,
      puzzle: _shuffle(seed, difficulty),
      difficulty: difficulty,
    );
  }
}

final puzzleControllerProvider =
    NotifierProvider<PuzzleController, PuzzleState>(PuzzleController.new);
