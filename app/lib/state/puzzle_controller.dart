import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

/// Board size for the prototype (GP-01).
final prototypeGrid = GridSize(4, 4);

/// Seed for the first puzzle. Seed source is an open technical question
/// (TD-02); provisionally a fixed `--dart-define=PUZZLE_SEED=<n>` or, if
/// unset, the launch time.
final initialSeedProvider = Provider<int>((ref) {
  const fromEnv = int.fromEnvironment('PUZZLE_SEED', defaultValue: -1);
  return fromEnv >= 0
      ? fromEnv
      : DateTime.now().millisecondsSinceEpoch % 1000000;
});

/// Layout generator behind the replaceable interface. Provisional
/// implementation: TD-02 remains Pending.
final layoutGeneratorProvider = Provider<LayoutGenerator>(
  (ref) => const ProvisionalRandomFillGenerator(),
);

@immutable
class PuzzleState {
  const PuzzleState({
    required this.seed,
    required this.session,
    this.inFlightPieceId,
    this.showCompletion = false,
  });

  final int seed;
  final PuzzleSession session;

  /// Piece currently being dragged, or animating to the board or back to
  /// the tray. Its tray slot shows an empty placeholder meanwhile.
  final String? inFlightPieceId;

  /// True once the last piece's lock animation has finished.
  final bool showCompletion;

  bool get isComplete => session.isComplete;
  int get placedCount => session.lockedPieceIds.length;
  int get totalCount => session.layout.pieces.length;

  PuzzleState copyWith({
    PuzzleSession? session,
    String? inFlightPieceId,
    bool clearInFlight = false,
    bool? showCompletion,
  }) => PuzzleState(
    seed: seed,
    session: session ?? this.session,
    inFlightPieceId: clearInFlight
        ? null
        : inFlightPieceId ?? this.inFlightPieceId,
    showCompletion: showCompletion ?? this.showCompletion,
  );
}

/// Application state for the current puzzle (hand-written Notifier,
/// ADR-0003). All placement decisions are made by the domain.
class PuzzleController extends Notifier<PuzzleState> {
  @override
  PuzzleState build() => _newState(ref.read(initialSeedProvider));

  PuzzleState _newState(int seed) {
    final layout = ref
        .read(layoutGeneratorProvider)
        .generate(
          grid: prototypeGrid,
          constraints: LayoutConstraints.prototype,
          seed: seed,
        );
    return PuzzleState(
      seed: seed,
      session: PuzzleSession.start(layout, trayShuffleSeed: seed),
    );
  }

  /// A piece was picked up from the tray.
  void pickUp(String pieceId) =>
      state = state.copyWith(inFlightPieceId: pieceId);

  /// A piece was dropped with its top-left at [target]. Returns the domain
  /// outcome so the caller can tell the game which animation to play.
  PlacementOutcome drop(String pieceId, GridCell target) {
    final outcome = state.session.attemptPlacement(pieceId, target);
    if (outcome case PlacementAccepted(:final session)) {
      state = state.copyWith(session: session);
    }
    return outcome;
  }

  /// The game finished animating a rejected piece back to the tray.
  void returnFinished(String pieceId) {
    if (state.inFlightPieceId == pieceId) {
      state = state.copyWith(clearInFlight: true);
    }
  }

  /// The game finished the snap-and-lock animation for [pieceId].
  /// Completion is reported here, once. Rewards and cards hook in here
  /// later (not implemented in this milestone).
  void lockFinished(String pieceId) {
    state = state.copyWith(
      clearInFlight: state.inFlightPieceId == pieceId,
      showCompletion: state.session.isComplete,
    );
  }

  /// Starts a new puzzle with the next seed.
  void newPuzzle() => state = _newState(state.seed + 1);
}

final puzzleControllerProvider =
    NotifierProvider<PuzzleController, PuzzleState>(PuzzleController.new);
