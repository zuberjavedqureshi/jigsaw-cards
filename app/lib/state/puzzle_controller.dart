import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/artwork_registry.dart';
import '../artwork/puzzle_artwork.dart';
import '../progression/level.dart';
import '../progression/level_catalogue.dart';
import '../progression/progression_rules.dart';
import 'puzzle_difficulty.dart';

/// Level of the first puzzle: Sunny Meadows level 1 until level selection
/// exists. Overridable in tests; validated before any puzzle is created.
final initialLevelProvider = Provider<LevelId>((ref) => LevelId.first);

/// Seed for the first puzzle's shuffle: the deterministic first-play seed
/// of the initial level ([firstPlaySeed]; 1000 for Sunny Meadows level 1),
/// unless a fixed `--dart-define=PUZZLE_SEED=<n>` is given.
final initialSeedProvider = Provider<int>((ref) {
  const fromEnv = int.fromEnvironment('PUZZLE_SEED', defaultValue: -1);
  return fromEnv >= 0
      ? fromEnv
      : firstPlaySeed(ref.watch(initialLevelProvider));
});

/// The illustration of the **current puzzle**, derived from its level.
/// Its source size drives both the domain's tile slicing and the board's
/// aspect ratio, so they cannot disagree. The controller never reads this
/// provider (it would be a circular dependency); it uses
/// [playableArtworkFor] directly.
final artworkProvider = Provider<PuzzleArtwork>(
  (ref) => playableArtworkFor(
    ref.watch(puzzleControllerProvider.select((s) => s.level)),
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
    this.level = LevelId.first,
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

  /// The level being played; kept by [PuzzleController.newPuzzle].
  final LevelId level;

  /// Board difficulty of [level], from the level catalogue (the only
  /// source of the board size).
  PuzzleDifficulty get difficulty => levelConfigFor(level).difficulty;

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
    level: level,
  );
}

SourceSize _sourceSize(PuzzleArtwork a) =>
    SourceSize(a.sourceSize.width, a.sourceSize.height);

/// Application state for the current picture-swap puzzle (hand-written
/// Notifier, ADR-0003). Every rule decision is made by the domain.
class PuzzleController extends Notifier<PuzzleState> {
  @override
  PuzzleState build() {
    final level = ref.read(initialLevelProvider);
    // Validate before anything else: an unplayable override fails here,
    // before a seed is read or a puzzle is created.
    playableArtworkFor(level);
    final seed = ref.read(initialSeedProvider);
    return PuzzleState(seed: seed, puzzle: _shuffle(seed, level), level: level);
  }

  /// The domain's seeded shuffle for [level]'s board and picture. Uses
  /// [playableArtworkFor], never [artworkProvider] (which depends on this
  /// controller).
  PicturePuzzle _shuffle(int seed, LevelId level) => PicturePuzzle.shuffled(
    levelConfigFor(level).difficulty.grid,
    _sourceSize(playableArtworkFor(level)),
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

  /// Replays the current level (PRD GP-40 "Next puzzle"): the same level
  /// and picture, freshly shuffled with a random seed from
  /// [puzzleSeedSourceProvider]. A seed that would repeat the current
  /// arrangement is skipped, so the new board always differs.
  void newPuzzle() {
    final level = state.level;
    final source = ref.read(puzzleSeedSourceProvider);
    final current = state.puzzle.arrangement;
    var seed = source.nextSeed();
    var puzzle = _shuffle(seed, level);
    for (var i = 0; i < 16 && listEquals(puzzle.arrangement, current); i++) {
      seed = source.nextSeed();
      puzzle = _shuffle(seed, level);
    }
    state = PuzzleState(
      seed: seed,
      round: state.round + 1,
      puzzle: puzzle,
      level: level,
    );
  }

  /// Starts [level] (entry point for future level selection; not called by
  /// the UI yet). A first play uses the level's deterministic
  /// [firstPlaySeed]; a [replay] uses a fresh random seed. A level that is
  /// not playable throws [ArgumentError] before any seed is taken or any
  /// state changes.
  void start(LevelId level, {bool replay = false}) {
    playableArtworkFor(level);
    final seed = replay
        ? ref.read(puzzleSeedSourceProvider).nextSeed()
        : firstPlaySeed(level);
    state = PuzzleState(
      seed: seed,
      round: state.round + 1,
      puzzle: _shuffle(seed, level),
      level: level,
    );
  }
}

final puzzleControllerProvider =
    NotifierProvider<PuzzleController, PuzzleState>(PuzzleController.new);
