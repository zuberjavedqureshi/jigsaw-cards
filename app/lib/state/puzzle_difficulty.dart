import 'package:puzzle_domain/puzzle_domain.dart';

/// Puzzle difficulty (World Journey): a square board size and a display
/// label. Product configuration, not a puzzle rule — the domain supports any
/// [GridSize]. The board size of every level comes only from here.
///
/// 6×6 is reserved for possible future special challenges and deliberately
/// not defined.
enum PuzzleDifficulty {
  normal(4, 'Normal'),
  hard(5, 'Hard');

  const PuzzleDifficulty(this.size, this.label);

  /// Tiles per side (square boards only).
  final int size;

  /// Name shown to the player.
  final String label;

  /// The board: [size] × [size].
  GridSize get grid => GridSize(size, size);
}
