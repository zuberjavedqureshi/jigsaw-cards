import 'package:puzzle_domain/puzzle_domain.dart';

/// Manual Flame ↔ application bridge (ADR-0001). The game depends only on
/// this contract and the pure-Dart domain, never on Riverpod.

/// Flame → application intents. The game never changes puzzle state
/// itself; it asks, and then renders the session it is given.
class PuzzleGameIntents {
  const PuzzleGameIntents({
    required this.onReady,
    required this.onPreviewShown,
    required this.onRevealRequested,
    required this.onSelected,
    required this.onDropRequested,
    required this.onLockComplete,
  });

  /// The game has loaded and shows the face-down pieces.
  final void Function() onReady;

  /// The preview flip-up finished: every piece is fully face-up. The 4 s
  /// preview timer starts here.
  final void Function() onPreviewShown;

  /// A face-down piece was tapped.
  final void Function(String pieceId) onRevealRequested;

  /// A face-up piece was picked up or tapped (bring to front).
  final void Function(String pieceId) onSelected;

  /// A dragged piece was released with its top-left at [position] (board
  /// space, already clamped to the workspace).
  final void Function(String pieceId, BoardPoint position) onDropRequested;

  /// The snap-and-lock animation for [pieceId] finished.
  final void Function(String pieceId) onLockComplete;
}

/// Application → Flame. [syncSession] is the only state input: the game
/// diffs the new session against the one it last rendered and animates the
/// differences (flips, moves, snaps, stacking).
abstract interface class PuzzleGameView {
  void syncSession(PuzzleSession session);
}
