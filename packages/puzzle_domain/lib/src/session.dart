import 'dart:math';

import 'grid.dart';
import 'layout.dart';
import 'piece.dart';

/// Why a placement was rejected. Rejections are normal gameplay, not errors.
enum PlacementRejection {
  /// No piece with that id exists in the puzzle.
  unknownPiece,

  /// The piece is already locked on the board (GP-15).
  alreadyLocked,

  /// The piece would extend outside the board.
  outOfBounds,

  /// The target is not the piece's correct position (GP-14).
  wrongPosition,
}

/// Result of [PuzzleSession.attemptPlacement].
sealed class PlacementOutcome {
  const PlacementOutcome();
}

/// The piece was placed at its correct position and is now locked.
final class PlacementAccepted extends PlacementOutcome {
  const PlacementAccepted(this.session, this.piece);

  /// The session after placement.
  final PuzzleSession session;
  final PuzzlePiece piece;

  /// True if this placement completed the puzzle (reported once).
  bool get completedPuzzle => session.isComplete;
}

/// The placement was rejected; the session is unchanged.
final class PlacementRejected extends PlacementOutcome {
  const PlacementRejected(this.reason);

  final PlacementRejection reason;
}

/// Immutable state of one puzzle being played.
///
/// Rules (PRD GP-06, GP-14, GP-15; PUZZLE_ENGINE §7): only a piece's correct
/// origin accepts it; accepted pieces are permanently locked; rejected
/// placements leave the state unchanged.
final class PuzzleSession {
  PuzzleSession._(this.layout, Set<String> locked, List<String> trayOrder)
    : lockedPieceIds = Set.unmodifiable(locked),
      _trayOrder = List.unmodifiable(trayOrder);

  /// Starts a session with every piece in the tray. The tray order is a
  /// deterministic shuffle of [trayShuffleSeed] (presentation order only;
  /// the tray-ordering rule is not a product decision and is provisional).
  factory PuzzleSession.start(PuzzleLayout layout, {int trayShuffleSeed = 0}) {
    final order = [for (final p in layout.pieces) p.id]
      ..shuffle(Random(trayShuffleSeed));
    return PuzzleSession._(layout, const {}, order);
  }

  final PuzzleLayout layout;
  final Set<String> lockedPieceIds;
  final List<String> _trayOrder;

  /// Tray presentation order of every piece id, including locked ones.
  List<String> get trayOrder => _trayOrder;

  /// Pieces still in the tray, in tray order.
  List<PuzzlePiece> get trayPieces => [
    for (final id in _trayOrder)
      if (!lockedPieceIds.contains(id)) layout.pieceById(id)!,
  ];

  /// Pieces locked on the board.
  List<PuzzlePiece> get lockedPieces => [
    for (final p in layout.pieces)
      if (lockedPieceIds.contains(p.id)) p,
  ];

  bool isLocked(String pieceId) => lockedPieceIds.contains(pieceId);

  /// The puzzle is complete when every piece is locked at its correct
  /// origin; under the strict rule that is "all pieces placed".
  bool get isComplete => lockedPieceIds.length == layout.pieces.length;

  /// Attempts to place [pieceId] with its top-left cell at [target].
  PlacementOutcome attemptPlacement(String pieceId, GridCell target) {
    final piece = layout.pieceById(pieceId);
    if (piece == null) {
      return const PlacementRejected(PlacementRejection.unknownPiece);
    }
    if (isLocked(pieceId)) {
      return const PlacementRejected(PlacementRejection.alreadyLocked);
    }
    if (!piece.cellsAt(target).every(layout.grid.contains)) {
      return const PlacementRejected(PlacementRejection.outOfBounds);
    }
    if (target != piece.correctOrigin) {
      return const PlacementRejected(PlacementRejection.wrongPosition);
    }
    return PlacementAccepted(
      PuzzleSession._(layout, {...lockedPieceIds, pieceId}, _trayOrder),
      piece,
    );
  }
}
