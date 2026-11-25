import 'dart:ui';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Manual Flame ↔ application bridge (ADR-0001). The game depends only on
/// this contract and never on Riverpod.

/// Flame → application intents.
class PuzzleGameIntents {
  const PuzzleGameIntents({
    required this.onDropRequested,
    required this.onLockComplete,
    required this.onReturnComplete,
  });

  /// The player released [pieceId] with its top-left nearest to [target].
  /// The host asks the domain and then calls [PuzzleGameView.animateLock]
  /// or [PuzzleGameView.animateReturn].
  final void Function(String pieceId, GridCell target) onDropRequested;

  /// The snap-and-lock animation for [pieceId] finished.
  final void Function(String pieceId) onLockComplete;

  /// The return-to-tray animation for [pieceId] finished.
  final void Function(String pieceId) onReturnComplete;
}

/// Application → Flame commands. Positions are in game coordinates, which
/// equal the play area's local coordinates (the GameWidget fills it).
abstract interface class PuzzleGameView {
  /// A piece was picked up from its tray preview at [previewRect]; the
  /// pointer is at [pointer]. The game shows it enlarged to board scale.
  void beginDrag(PuzzlePiece piece, Offset pointer, Rect previewRect);

  void updateDrag(Offset pointer);

  /// The pointer was released at [pointer]; the game reports the snap
  /// candidate through [PuzzleGameIntents.onDropRequested].
  void endDrag(Offset pointer);

  /// Snap [pieceId] into its board position and lock it.
  void animateLock(String pieceId);

  /// Animate [pieceId] back to its tray preview.
  void animateReturn(String pieceId);
}
