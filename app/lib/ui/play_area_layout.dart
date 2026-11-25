import 'dart:math' as math;
import 'dart:ui';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Maps board space (cell units, see [BoardPoint]) to screen space inside
/// the play area. The whole [PlayBounds] workspace is fitted into the
/// available size with a margin, keeping square cells, so every piece
/// position the domain allows is fully on screen at any aspect ratio.
class BoardLayout {
  const BoardLayout._({
    required this.workspace,
    required this.cellSize,
    required this.origin,
  });

  static const margin = 12.0;

  /// Workspace (play bounds) rect in play-area coordinates.
  final Rect workspace;
  final double cellSize;

  /// Screen position of board point (0, 0): the grid's top-left.
  final Offset origin;

  static BoardLayout compute(Size size, PlayBounds bounds) {
    final availW = math.max(0.0, size.width - 2 * margin);
    final availH = math.max(0.0, size.height - 2 * margin);
    final cell = math.min(availW / bounds.width, availH / bounds.height);
    final w = cell * bounds.width;
    final h = cell * bounds.height;
    final ws = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
    return BoardLayout._(
      workspace: ws,
      cellSize: cell,
      origin: ws.topLeft - Offset(bounds.left * cell, bounds.top * cell),
    );
  }

  Offset toScreen(BoardPoint p) =>
      origin + Offset(p.x * cellSize, p.y * cellSize);

  BoardPoint toBoard(Offset o) =>
      BoardPoint((o.dx - origin.dx) / cellSize, (o.dy - origin.dy) / cellSize);

  Size pieceSize(PieceSize s) =>
      Size(s.columnSpan * cellSize, s.rowSpan * cellSize);

  Rect pieceRect(BoardPoint topLeft, PieceSize s) =>
      toScreen(topLeft) & pieceSize(s);

  /// Screen rect of the logical grid (the target picture area).
  Rect gridRect(GridSize g) =>
      origin & Size(g.columns * cellSize, g.rows * cellSize);
}
