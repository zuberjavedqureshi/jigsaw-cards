import 'board_space.dart';
import 'layout.dart';
import 'piece.dart';
import 'scatter.dart';

/// Phases of a puzzle (PRD GP-20 to GP-23).
enum PuzzlePhase {
  /// Pieces are scattered face-down; no interaction.
  intro,

  /// Every piece is shown face-up for [PuzzleSession.previewDuration]; no
  /// interaction.
  preview,

  /// Memory mode: pieces are face-down unless revealed; the player reveals
  /// and arranges them.
  playing,

  /// Every piece is locked at its correct position.
  complete,
}

/// Runtime state of one piece. The current [position] is independent of the
/// piece's correct target ([PuzzlePiece.correctOrigin]).
final class PieceState {
  const PieceState({
    required this.piece,
    required this.position,
    this.revealed = false,
    this.locked = false,
  });

  final PuzzlePiece piece;

  /// Current top-left in board space (cell units).
  final BoardPoint position;

  /// Revealed by the player in memory mode (stays face-up afterwards).
  final bool revealed;

  /// Snapped to its correct position; cannot move again.
  final bool locked;

  String get id => piece.id;
  BoardPoint get target => BoardPoint.ofCell(piece.correctOrigin);

  /// True when the current position is exactly the correct position.
  bool get isAtTarget => position == target;

  bool contains(BoardPoint p) =>
      p.x >= position.x &&
      p.y >= position.y &&
      p.x < position.x + piece.size.columnSpan &&
      p.y < position.y + piece.size.rowSpan;

  PieceState copyWith({BoardPoint? position, bool? revealed, bool? locked}) =>
      PieceState(
        piece: piece,
        position: position ?? this.position,
        revealed: revealed ?? this.revealed,
        locked: locked ?? this.locked,
      );
}

/// Why an action was refused. Refusals are normal gameplay outcomes and
/// leave the session unchanged.
enum ActionRejection {
  unknownPiece,

  /// Not in memory mode (intro, preview or complete).
  notInteractive,

  /// The piece is locked at its correct position.
  locked,

  /// The piece is face-down; it must be revealed before it can move.
  faceDown,

  /// The piece is already face-up.
  alreadyRevealed,
}

sealed class RevealOutcome {
  const RevealOutcome();
}

final class PieceRevealed extends RevealOutcome {
  const PieceRevealed(this.session, this.pieceId);
  final PuzzleSession session;
  final String pieceId;
}

final class RevealRejected extends RevealOutcome {
  const RevealRejected(this.reason);
  final ActionRejection reason;
}

sealed class MoveOutcome {
  const MoveOutcome();
}

/// The piece moved. Wrong positions are accepted and kept ([snapped] false);
/// a position within the snap tolerance of the target snaps and locks.
final class PieceMoved extends MoveOutcome {
  const PieceMoved(this.session, this.pieceId, {required this.snapped});
  final PuzzleSession session;
  final String pieceId;
  final bool snapped;

  PieceState get piece => session.piece(pieceId)!;
  bool get completedPuzzle => snapped && session.isComplete;
}

final class MoveRejected extends MoveOutcome {
  const MoveRejected(this.reason);
  final ActionRejection reason;
}

/// Free-placement memory puzzle session (immutable).
///
/// Flow: [PuzzlePhase.intro] → [beginPreview] → [PuzzlePhase.preview]
/// (everything face-up for [previewDuration]) → [endPreview] →
/// [PuzzlePhase.playing] (tap to [reveal], [move] freely; a move within
/// [snapTolerance] of the correct position snaps and locks) →
/// [PuzzlePhase.complete] when every piece is locked.
final class PuzzleSession {
  PuzzleSession._({
    required this.layout,
    required this.bounds,
    required this.snapTolerance,
    required this.phase,
    required Map<String, PieceState> pieces,
    required List<String> stackOrder,
  }) : _pieces = Map.unmodifiable(pieces),
       stackOrder = List.unmodifiable(stackOrder);

  /// Starts a session in [PuzzlePhase.intro] with every piece face-down at
  /// a seeded scattered position inside [bounds].
  factory PuzzleSession.start(
    PuzzleLayout layout, {
    required PlayBounds bounds,
    int scatterSeed = 0,
    StartArranger arranger = const SeededScatterArranger(),
    double snapTolerance = defaultSnapTolerance,
  }) {
    if (snapTolerance < 0 || snapTolerance >= 0.5) {
      throw ArgumentError.value(
        snapTolerance,
        'snapTolerance',
        'must be in [0, 0.5) cell',
      );
    }
    final start = arranger.arrange(
      layout: layout,
      bounds: bounds,
      seed: scatterSeed,
    );
    return PuzzleSession._(
      layout: layout,
      bounds: bounds,
      snapTolerance: snapTolerance,
      phase: PuzzlePhase.intro,
      pieces: {
        for (final p in layout.pieces)
          p.id: PieceState(
            piece: p,
            position: bounds.clampOrigin(start.positions[p.id]!, p.size),
          ),
      },
      stackOrder: start.stackOrder,
    );
  }

  /// Approved preview duration: exactly 4 seconds (GP-21).
  static const previewDuration = Duration(seconds: 4);

  /// Provisional snap tolerance in cell units (Chebyshev distance between
  /// the drop position and the correct position). A feel parameter.
  static const defaultSnapTolerance = 0.3;

  final PuzzleLayout layout;
  final PlayBounds bounds;
  final double snapTolerance;
  final PuzzlePhase phase;
  final Map<String, PieceState> _pieces;

  /// Piece ids from bottom to top (render and hit-test order). Locked
  /// pieces are kept below unlocked ones.
  final List<String> stackOrder;

  Iterable<PieceState> get pieces => stackOrder.map((id) => _pieces[id]!);
  PieceState? piece(String id) => _pieces[id];

  bool get isInteractive => phase == PuzzlePhase.playing;
  bool get isComplete => phase == PuzzlePhase.complete;
  int get lockedCount => _pieces.values.where((p) => p.locked).length;
  int get pieceCount => _pieces.length;

  /// Whether [id] is currently shown face-up: during the preview, once
  /// revealed or locked, and when complete.
  bool isFaceUp(String id) {
    final p = _pieces[id];
    if (p == null) return false;
    return phase == PuzzlePhase.preview ||
        phase == PuzzlePhase.complete ||
        p.revealed ||
        p.locked;
  }

  PuzzleSession _copy({
    PuzzlePhase? phase,
    Map<String, PieceState>? pieces,
    List<String>? stackOrder,
  }) => PuzzleSession._(
    layout: layout,
    bounds: bounds,
    snapTolerance: snapTolerance,
    phase: phase ?? this.phase,
    pieces: pieces ?? _pieces,
    stackOrder: stackOrder ?? this.stackOrder,
  );

  /// intro → preview: every piece is shown face-up.
  PuzzleSession beginPreview() {
    _expectPhase(PuzzlePhase.intro, 'beginPreview');
    return _copy(phase: PuzzlePhase.preview);
  }

  /// preview → playing: every unrevealed piece is face-down again.
  PuzzleSession endPreview() {
    _expectPhase(PuzzlePhase.preview, 'endPreview');
    return _copy(phase: PuzzlePhase.playing);
  }

  void _expectPhase(PuzzlePhase expected, String op) {
    if (phase != expected) {
      throw StateError('$op requires phase $expected, was $phase');
    }
  }

  /// Reveals one face-down piece. Other pieces are unaffected.
  RevealOutcome reveal(String id) {
    final p = _pieces[id];
    if (p == null) return const RevealRejected(ActionRejection.unknownPiece);
    if (!isInteractive) {
      return const RevealRejected(ActionRejection.notInteractive);
    }
    if (p.locked) return const RevealRejected(ActionRejection.locked);
    if (p.revealed) {
      return const RevealRejected(ActionRejection.alreadyRevealed);
    }
    return PieceRevealed(
      _copy(pieces: {..._pieces, id: p.copyWith(revealed: true)}),
      id,
    );
  }

  /// Moves [id] to the top of the stack (selection). Locked pieces stay
  /// below; returns this session unchanged for locked or unknown pieces.
  PuzzleSession bringToFront(String id) {
    final p = _pieces[id];
    if (p == null || p.locked || stackOrder.last == id) return this;
    return _copy(stackOrder: [...stackOrder.where((s) => s != id), id]);
  }

  /// Whether [position] is close enough to [id]'s correct position to snap.
  bool isWithinSnap(String id, BoardPoint position) {
    final p = _pieces[id];
    return p != null && position.chebyshevTo(p.target) <= snapTolerance;
  }

  /// Moves a revealed, unlocked piece to [requested] (its new top-left),
  /// clamped inside [bounds]. Any position is accepted. Within
  /// [snapTolerance] of the correct position, the piece snaps exactly onto
  /// it and locks; when the last piece locks the puzzle is complete.
  MoveOutcome move(String id, BoardPoint requested) {
    final p = _pieces[id];
    if (p == null) return const MoveRejected(ActionRejection.unknownPiece);
    if (!isInteractive) {
      return const MoveRejected(ActionRejection.notInteractive);
    }
    if (p.locked) return const MoveRejected(ActionRejection.locked);
    if (!p.revealed) return const MoveRejected(ActionRejection.faceDown);

    final clamped = bounds.clampOrigin(requested, p.piece.size);
    if (isWithinSnap(id, clamped)) {
      final pieces = {
        ..._pieces,
        id: p.copyWith(position: p.target, locked: true),
      };
      final done = pieces.values.every((s) => s.locked);
      // Locked pieces go to the bottom of the stack, above earlier locks.
      final unlocked = stackOrder.where((s) => s != id && !pieces[s]!.locked);
      final locked = stackOrder.where((s) => s != id && pieces[s]!.locked);
      return PieceMoved(
        _copy(
          phase: done ? PuzzlePhase.complete : null,
          pieces: pieces,
          stackOrder: [...locked, id, ...unlocked],
        ),
        id,
        snapped: true,
      );
    }
    return PieceMoved(
      _copy(
        pieces: {
          ..._pieces,
          id: p.copyWith(position: clamped),
        },
        stackOrder: [...stackOrder.where((s) => s != id), id],
      ),
      id,
      snapped: false,
    );
  }

  /// Topmost piece containing [point], skipping locked pieces (they can
  /// never be selected, so a tap passes through them). Null if none.
  PieceState? topmostSelectableAt(BoardPoint point) {
    for (final id in stackOrder.reversed) {
      final p = _pieces[id]!;
      if (!p.locked && p.contains(point)) return p;
    }
    return null;
  }
}
