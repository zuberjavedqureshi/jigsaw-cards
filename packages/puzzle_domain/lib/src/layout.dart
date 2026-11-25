import 'grid.dart';
import 'piece.dart';

/// Constraints a rectangular layout must satisfy.
final class LayoutConstraints {
  LayoutConstraints({
    required Set<PieceSize> allowedSizes,
    required this.minPieces,
    required this.maxPieces,
  }) : assert(minPieces <= maxPieces),
       allowedSizes = Set.unmodifiable(allowedSizes);

  /// Approved prototype constraints (Q-009; PRD PS-20, PS-21): pieces 1×1,
  /// 1×2, 2×1, 2×2; between 8 and 12 pieces, inclusive.
  static final prototype = LayoutConstraints(
    allowedSizes: {
      PieceSize.oneByOne,
      PieceSize.oneByTwo,
      PieceSize.twoByOne,
      PieceSize.twoByTwo,
    },
    minPieces: 8,
    maxPieces: 12,
  );

  final Set<PieceSize> allowedSizes;
  final int minPieces;
  final int maxPieces;
}

/// Why a layout is invalid.
enum LayoutViolationKind {
  /// A grid cell is not covered by any piece.
  gap,

  /// A grid cell is covered by more than one piece.
  overlap,

  /// A piece extends outside the grid.
  outOfBounds,

  /// A piece's size is not in [LayoutConstraints.allowedSizes].
  invalidSize,

  /// The number of pieces is outside the allowed range.
  invalidPieceCount,

  /// Two pieces share an id.
  duplicateId,
}

final class LayoutViolation {
  const LayoutViolation(this.kind, this.detail);

  final LayoutViolationKind kind;
  final String detail;

  @override
  String toString() => '${kind.name}: $detail';
}

/// Thrown when constructing a layout that violates its constraints.
final class InvalidLayoutException implements Exception {
  const InvalidLayoutException(this.violations);

  final List<LayoutViolation> violations;

  @override
  String toString() => 'InvalidLayoutException($violations)';
}

/// A rectangular-tile puzzle layout: a grid and the pieces that tile it.
///
/// A [PuzzleLayout] can only be constructed through [PuzzleLayout.validated],
/// so every instance satisfies the tiling invariant (PUZZLE_ENGINE §4) and
/// the constraints it was validated against.
final class PuzzleLayout {
  PuzzleLayout._(this.grid, List<PuzzlePiece> pieces)
    : pieces = List.unmodifiable(pieces);

  /// Validates [pieces] against [grid] and [constraints]; throws
  /// [InvalidLayoutException] listing every violation if invalid.
  factory PuzzleLayout.validated({
    required GridSize grid,
    required List<PuzzlePiece> pieces,
    LayoutConstraints? constraints,
  }) {
    final violations = validateLayout(
      grid,
      pieces,
      constraints ?? LayoutConstraints.prototype,
    );
    if (violations.isNotEmpty) throw InvalidLayoutException(violations);
    return PuzzleLayout._(grid, pieces);
  }

  final GridSize grid;
  final List<PuzzlePiece> pieces;

  PuzzlePiece? pieceById(String id) {
    for (final p in pieces) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Returns every way [pieces] fail to form a valid layout of [grid] under
/// [constraints]. An empty list means the layout is valid.
List<LayoutViolation> validateLayout(
  GridSize grid,
  List<PuzzlePiece> pieces,
  LayoutConstraints constraints,
) {
  final violations = <LayoutViolation>[];

  if (pieces.length < constraints.minPieces ||
      pieces.length > constraints.maxPieces) {
    violations.add(
      LayoutViolation(
        LayoutViolationKind.invalidPieceCount,
        '${pieces.length} pieces; allowed '
        '${constraints.minPieces}–${constraints.maxPieces}',
      ),
    );
  }

  final ids = <String>{};
  final coverage = <GridCell, int>{};
  for (final piece in pieces) {
    if (!ids.add(piece.id)) {
      violations.add(
        LayoutViolation(LayoutViolationKind.duplicateId, piece.id),
      );
    }
    if (!constraints.allowedSizes.contains(piece.size)) {
      violations.add(
        LayoutViolation(
          LayoutViolationKind.invalidSize,
          '${piece.id} is ${piece.size}',
        ),
      );
    }
    for (final cell in piece.correctCells) {
      if (!grid.contains(cell)) {
        violations.add(
          LayoutViolation(
            LayoutViolationKind.outOfBounds,
            '${piece.id} covers $cell',
          ),
        );
        continue;
      }
      coverage[cell] = (coverage[cell] ?? 0) + 1;
    }
  }

  for (final cell in grid.cells) {
    final count = coverage[cell] ?? 0;
    if (count == 0) {
      violations.add(
        LayoutViolation(LayoutViolationKind.gap, '$cell is not covered'),
      );
    } else if (count > 1) {
      violations.add(
        LayoutViolation(
          LayoutViolationKind.overlap,
          '$cell is covered $count times',
        ),
      );
    }
  }
  return violations;
}
