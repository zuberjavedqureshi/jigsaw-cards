import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

/// Board size for the prototype (GP-01).
final prototypeGrid = GridSize(4, 4);

/// Seed for the first puzzle. Seed source is an open technical question
/// (TD-02); provisionally a fixed `--dart-define=PUZZLE_SEED=<n>` or, if
/// unset, the launch time. The same seed drives the layout and the scatter.
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

/// Cancels a scheduled callback.
typedef CancelScheduled = void Function();

/// Schedules [callback] after [delay]. Injectable so tests control time
/// explicitly instead of waiting on real timers.
typedef Scheduler = CancelScheduled Function(
  Duration delay,
  void Function() callback,
);

final schedulerProvider = Provider<Scheduler>(
  (ref) =>
      (delay, callback) => Timer(delay, callback).cancel,
);

/// Short face-down introduction before the preview (provisional; the
/// approved timing is only the 4 s preview itself).
const introDuration = Duration(milliseconds: 1200);

@immutable
class PuzzleState {
  const PuzzleState({
    required this.seed,
    required this.session,
    this.showCompletion = false,
  });

  final int seed;
  final PuzzleSession session;

  /// True once the last piece's lock animation has finished.
  final bool showCompletion;

  PuzzlePhase get phase => session.phase;
  int get placedCount => session.lockedCount;
  int get totalCount => session.pieceCount;

  /// The approved preview duration (GP-21).
  Duration get previewDuration => PuzzleSession.previewDuration;

  PuzzleState copyWith({PuzzleSession? session, bool? showCompletion}) =>
      PuzzleState(
        seed: seed,
        session: session ?? this.session,
        showCompletion: showCompletion ?? this.showCompletion,
      );
}

/// Application state for the current puzzle (hand-written Notifier,
/// ADR-0003). It sequences intro → preview → memory mode and forwards
/// player actions to the domain, which makes every rule decision.
class PuzzleController extends Notifier<PuzzleState> {
  CancelScheduled? _pending;
  int? _readySeed;

  @override
  PuzzleState build() {
    ref.onDispose(_cancelPending);
    return _newState(ref.read(initialSeedProvider));
  }

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
      session: PuzzleSession.start(
        layout,
        bounds: PlayBounds.prototype(prototypeGrid),
        scatterSeed: seed,
      ),
    );
  }

  void _cancelPending() {
    _pending?.call();
    _pending = null;
  }

  void _schedule(Duration d, void Function() f) {
    _cancelPending();
    _pending = ref.read(schedulerProvider)(d, () {
      _pending = null;
      f();
    });
  }

  /// The game is showing the face-down pieces: start the short intro, then
  /// the preview. Idempotent per puzzle.
  void gameReady() {
    if (_readySeed == state.seed || state.phase != PuzzlePhase.intro) return;
    _readySeed = state.seed;
    _schedule(introDuration, beginPreview);
  }

  /// intro → preview: every piece flips face-up.
  void beginPreview() {
    if (state.phase != PuzzlePhase.intro) return;
    state = state.copyWith(session: state.session.beginPreview());
  }

  /// The flip-up finished; the pieces stay visible for exactly
  /// [PuzzleSession.previewDuration].
  void previewShown() {
    if (state.phase != PuzzlePhase.preview) return;
    _schedule(PuzzleSession.previewDuration, endPreview);
  }

  /// preview → memory mode: every piece flips face-down.
  void endPreview() {
    if (state.phase != PuzzlePhase.preview) return;
    state = state.copyWith(session: state.session.endPreview());
  }

  /// Tap on a face-down piece: reveal only that piece and raise it.
  RevealOutcome reveal(String pieceId) {
    final outcome = state.session.reveal(pieceId);
    if (outcome case PieceRevealed(:final session)) {
      state = state.copyWith(session: session.bringToFront(pieceId));
    }
    return outcome;
  }

  /// A face-up piece was selected: raise it above the others.
  void select(String pieceId) {
    final next = state.session.bringToFront(pieceId);
    if (!identical(next, state.session)) {
      state = state.copyWith(session: next);
    }
  }

  /// A piece was dropped with its top-left at [position].
  MoveOutcome drop(String pieceId, BoardPoint position) {
    final outcome = state.session.move(pieceId, position);
    if (outcome case PieceMoved(:final session)) {
      state = state.copyWith(session: session);
    }
    return outcome;
  }

  /// The snap animation for [pieceId] finished. Completion is shown once,
  /// after the last lock. Rewards and cards attach here later (not in this
  /// milestone).
  void lockFinished(String pieceId) {
    if (state.session.isComplete && !state.showCompletion) {
      state = state.copyWith(showCompletion: true);
    }
  }

  /// Starts a new puzzle with the next seed.
  void newPuzzle() {
    _cancelPending();
    state = _newState(state.seed + 1);
  }
}

final puzzleControllerProvider =
    NotifierProvider<PuzzleController, PuzzleState>(PuzzleController.new);
